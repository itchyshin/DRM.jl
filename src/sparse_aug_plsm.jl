# sparse_aug_plsm.jl — SPARSE AUGMENTED-STATE Laplace-EM for the q=4 PLSM.
#
# Why: the dense routes failed on BOTH speed (400-dim ForwardDiff Hessian /
# repeated dense E-steps) and stability (dense inv(Σ_phy) of an ultrametric
# tree covariance is ill-conditioned → NaN). The augmented-state sparse
# precision Q_topology (Hadfield–Nakagawa, O(p) nnz, well-conditioned) fixes
# both: never forms dense Σ_phy⁻¹, and sparse Cholesky is O(p).
#
# Latent: node-major over the 2p-1 augmented nodes × 4 axes (mu1,mu2,
# log σ1, log σ2). u[(t-1)*4 + a] = axis a at augmented node t.
# Prior precision: P = kron(Q_topology, Λ_phy⁻¹)  [node outer, axis inner],
#   sparse, O(p) nnz. Data (bivariate, nonlinear scale) attaches only at the
#   p LEAF nodes. H_uu = P + blockdiag(4×4 data Hessian at each leaf node).
#
# Run the p=8 checkpoint:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. sparse_aug_plsm.jl

using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf
include(joinpath(@__DIR__, "sparse_phy.jl"))
include(joinpath(@__DIR__, "takahashi_selinv.jl"))

const RHO_GUARD = 0.99999999

# --- per-leaf bivariate-Gaussian data NLL as a function of the 4-vector u ----
# η_* carry the fixed-effect part (Xβ); u shifts mean (axes 1,2) and log-σ
# (axes 3,4). ρ has no random effect (rho12 ~ 1).
# Per-cell observed flags o1, o2 (Bool) support missing responses (issue #19): both
# observed ⇒ the bivariate term; exactly one observed ⇒ that response's univariate
# Gaussian marginal (the correct observed-data likelihood — drop the missing dim, ρ
# and the other σ leave the term); neither ⇒ 0 (the tip still couples through the
# tree prior, which is y-independent). The flags are CONSTANTS w.r.t. u, so leaf_grad
# / leaf_hess (and the exact gradient's ForwardDiff of leaf_hess) auto-propagate the
# mask. Defaulting o1=o2=true reproduces the original term BIT-FOR-BIT (all-observed
# reduction). The missing response value is NEVER touched in its dropped branch, so a
# NaN placeholder there is safe.
function leaf_nll(u, y1, y2, η1, η2, ηs1, ηs2, ηr, o1::Bool = true, o2::Bool = true)
    if o1 & o2
        mu1 = η1 + u[1]; mu2 = η2 + u[2]
        s1 = exp(ηs1 + u[3]); s2 = exp(ηs2 + u[4])
        ρ = RHO_GUARD * tanh(ηr)
        e1 = y1 - mu1; e2 = y2 - mu2
        omr2 = 1 - ρ^2
        quad = (e1^2 / s1^2 - 2ρ * e1 * e2 / (s1 * s2) + e2^2 / s2^2) / omr2
        return 0.5 * (log(s1^2 * s2^2 * omr2) + quad) + log(2π)
    elseif o1
        ls1 = ηs1 + u[3]; e1 = y1 - (η1 + u[1])      # univariate N(mu1, σ1²) marginal
        return 0.5 * (2 * ls1 + e1^2 / exp(2 * ls1)) + 0.5 * log(2π)
    elseif o2
        ls2 = ηs2 + u[4]; e2 = y2 - (η2 + u[2])      # univariate N(mu2, σ2²) marginal
        return 0.5 * (2 * ls2 + e2^2 / exp(2 * ls2)) + 0.5 * log(2π)
    else
        return zero(eltype(u))                        # neither observed
    end
end
leaf_grad(u, a...) = ForwardDiff.gradient(z -> leaf_nll(z, a...), u)
leaf_hess(u, a...) = ForwardDiff.hessian(z -> leaf_nll(z, a...), u)

# --- problem container -------------------------------------------------------
struct AugProblem
    phy::AugmentedPhy{Float64}
    n_total::Int                 # 2p-1
    p::Int                       # leaves
    leaf_node::Vector{Int}       # data row i -> augmented node index
    y1::Vector{Float64}; y2::Vector{Float64}
    X1::Matrix{Float64}; X2::Matrix{Float64}     # mu1, mu2 design (n×k)
    Xs1::Matrix{Float64}; Xs2::Matrix{Float64}; Xr::Matrix{Float64}
    obs1::Vector{Bool}; obs2::Vector{Bool}       # #19: per-row observed-response masks
end

# Backward-compatible constructor: no masks ⇒ all responses observed (the original
# all-leaf bivariate behaviour, bit-for-bit). Keeps every existing make_problem /
# AugProblem(...) caller working unchanged.
AugProblem(phy, n_total, p, leaf_node, y1, y2, X1, X2, Xs1, Xs2, Xr) =
    AugProblem(phy, n_total, p, leaf_node, y1, y2, X1, X2, Xs1, Xs2, Xr,
               trues(length(y1)), trues(length(y2)))

# Build the sparse prior precision P = kron(Q_topology, Λ⁻¹) (node-major).
prior_precision(Q::SparseMatrixCSC, Λinv::AbstractMatrix) = kron(Q, sparse(Λinv))

# η's from β (Float64) for the p leaves.
function leaf_etas(prob::AugProblem, β)
    (prob.X1 * β.mu1, prob.X2 * β.mu2, prob.Xs1 * β.s1, prob.Xs2 * β.s2, prob.Xr * β.rho)
end

# Assemble H_uu = P + blockdiag(leaf 4×4 data Hessians) at a given u (sparse).
function build_Huu(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    H = copy(P)
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; base = 4(t - 1)
        ublk = (u[base+1], u[base+2], u[base+3], u[base+4])
        Hb = leaf_hess([ublk...], prob.y1[i], prob.y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i],
                       prob.obs1[i], prob.obs2[i])
        for a in 1:4, b in 1:4
            H[base+a, base+b] += Hb[a, b]
        end
    end
    return H
end

# Zero-allocation prior-coupling gradient term: g .= P*u via an in-place sparse
# matvec (no temporary). This is the pure-Julia arithmetic the inner Newton loop
# repeats every iteration; the engine-quality gate (#15) asserts it allocates
# nothing and stays flat across p (the CHOLMOD factor/solve is excluded from that
# gate as out-of-Julia-control). `g` must be a length-4·n_total preallocated buffer.
@inline function aug_prior_grad!(g::Vector{Float64}, P::SparseMatrixCSC, u::Vector{Float64})
    mul!(g, P, u)
    return g
end

# Gradient of the joint nll wrt u at u: P*u + leaf data gradients (at leaves).
function joint_grad(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    g = similar(u)
    aug_prior_grad!(g, P, u)                        # g .= P*u (zero-alloc matvec)
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; base = 4(t - 1)
        ublk = [u[base+1], u[base+2], u[base+3], u[base+4]]
        gb = leaf_grad(ublk, prob.y1[i], prob.y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i],
                       prob.obs1[i], prob.obs2[i])
        for a in 1:4
            g[base+a] += gb[a]
        end
    end
    return g
end

# joint nll value at u (data at leaves + 0.5 u'Pu).
function joint_nll(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    val = 0.5 * dot(u, P * u)
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; base = 4(t - 1)
        val += leaf_nll((u[base+1], u[base+2], u[base+3], u[base+4]),
                        prob.y1[i], prob.y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i],
                        prob.obs1[i], prob.obs2[i])
    end
    return val
end

# Sparse PD-safe Cholesky: escalate a ridge until CHOLMOD succeeds. (H_uu is
# PD at the mode, but indefinite far from it — the log-σ axes have negative
# curvature when residuals are small, and Q_topology is rank-deficient.)
function sparse_pd_chol(H::SparseMatrixCSC)
    Hs = Symmetric(H)
    ch = cholesky(Hs; check = false)
    issuccess(ch) && return ch, 0.0
    λ = 1e-10
    for _ in 1:40                      # escalate up to ~1e30 — always succeeds
        ch = cholesky(Hs + λ * I; check = false)
        issuccess(ch) && return ch, λ
        λ *= 10
    end
    # guaranteed-PD last resort: diagonally dominant ridge
    d = maximum(abs, diag(H)) + 1.0
    return cholesky(Hs + d * I; check = false), d
end

# --- EXPECTED-information (Fisher) leaf 4×4 block (merged from the workflow's
# estep_lm). E[leaf_hess] over e ~ N(0,Σ(u)); leaf_hess is degree-≤2 in e so the
# 4-point symmetric sigma rule is EXACT. PD always (unlike the OBSERVED Hessian,
# whose log-σ curvature collapses at small residual → indefinite far from mode).
@inline function leaf_fisher(ublk, η1, η2, ηs1, ηs2, ηr)
    s1 = exp(ηs1 + ublk[3]); s2 = exp(ηs2 + ublk[4]); ρ = RHO_GUARD * tanh(ηr)
    L11 = s1; L21 = ρ * s2; L22 = s2 * sqrt(max(1 - ρ^2, 0.0)); c = sqrt(2.0)
    mu1 = η1 + ublk[1]; mu2 = η2 + ublk[2]
    HF = zeros(4, 4)
    for (a1, a2) in ((c*L11, c*L21), (-c*L11, -c*L21), (0.0, c*L22), (0.0, -c*L22))
        Hb = leaf_hess([ublk...], mu1 + a1, mu2 + a2, η1, η2, ηs1, ηs2, ηr)
        @inbounds for j in 1:4, i in 1:4; HF[i, j] += Hb[i, j]; end
    end
    HF ./= 4; return HF
end

# Expected-information joint Hessian H_E = P + blockdiag(Fisher leaf blocks); PD
# everywhere, used to STEER far from the mode. Fixed point unchanged (the step
# uses the TRUE gradient ∇J, so ∇J=0 at any solution — the same mode).
function build_Huu_expected(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    H = copy(P)
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; base = 4(t - 1)
        ublk = (u[base+1], u[base+2], u[base+3], u[base+4])
        Hb = leaf_fisher(ublk, η1[i], η2[i], ηs1[i], ηs2[i], ηr[i])
        for a in 1:4, b in 1:4; H[base+a, base+b] += Hb[a, b]; end
    end
    return H
end

# --- FAST PATH: cheap damped OBSERVED-Newton from a WARM start ----------------
# The old (pre-robust) mode-finder. For a warm u0 already near the mode this
# converges in 1–2 steps with NO Fisher overhead (observed build_Huu only) —
# the bulk of a fit's E-steps. Step = sparse_pd_chol(H)\g (the PD ridge guards
# the occasional indefinite observed H); backtracking line search on joint_nll.
#
# Acceptance (ok=true): the observed-Newton step direction hits a curvature floor
# near the mode and the line search can no longer strictly decrease joint_nll
# while ‖∇J‖ is still ~1e-4–1e-6 (MEASURED: 90% of warm stalls have ‖∇J‖<1e-3,
# median 1e-5). A mode that accurate is exact enough for the FROZEN-mode Laplace
# marginal (the outer optimiser only needs g_tol=1e-3 on θ), so we ACCEPT a clean
# convergence (‖∇J‖<ftol) OR a line-search stall once ‖∇J‖<stall_tol. We FALL
# BACK only on a genuine failure: non-finite f, a non-finite step, a |u| blow-up,
# or a stall while still far from the mode (‖∇J‖≥stall_tol) — the hard surface the
# robust LM exists for.
function _estep_fast(prob::AugProblem, P::SparseMatrixCSC, β, u0::Vector{Float64};
                     n_newton=40, ftol=1e-6, stall_tol=1e-3, ucap=1e3)
    u = copy(u0)
    f = joint_nll(prob, P, u, β)
    isfinite(f) || return u, false
    g = joint_grad(prob, P, u, β); ng = norm(g)
    for _ in 1:n_newton
        ng < ftol && return u, true
        H = build_Huu(prob, P, u, β)
        ch, _ = sparse_pd_chol(H)
        step = ch \ g
        all(isfinite, step) || return u, false       # bad step → fall back
        α = 1.0
        unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 30
            α *= 0.5; unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt += 1
        end
        if !(isfinite(fnew) && fnew < f)             # line search stalled
            return u, ng < stall_tol                 # accept if at the curvature floor
        end
        u = unew; f = fnew
        maximum(abs, u) > ucap && return u, false          # |u| blew up
        g = joint_grad(prob, P, u, β); ng = norm(g)
    end
    return u, ng < stall_tol       # ran out of iters: accept only if near the mode
end

# --- ROBUST PATH: trust-region Levenberg–Marquardt on a HYBRID Hessian (merged
# from the workflow winner estep_lm — strictly dominates the old damped Newton:
# no NaN, no false convergence, robust to the indefinite observed Hessian far
# from the mode). EXPECTED-info Hessian steers while far (‖∇J‖≥gswitch, PD-
# everywhere, anti-runaway); OBSERVED build_Huu once close (<gswitch) for
# quadratic convergence. Trust region caps step ‖·‖∞ (anti σ→0 cascade);
# convergence on ‖∇J‖ ONLY (the old norm(α·step)<tol test masked the drift).
# `u0` warm-starts (converges in 1-2 steps); cold starts get ≥200 iters.
function _estep_robust(prob::AugProblem, P::SparseMatrixCSC, β;
                       u0=nothing, n_newton=40, tol=1e-8, trust=5.0, gswitch=1.0)
    nu = 4 * prob.n_total
    u = u0 === nothing ? zeros(nu) : copy(u0)
    nit = u0 === nothing ? max(n_newton, 200) : n_newton    # cold needs more iters
    f = joint_nll(prob, P, u, β)
    g = joint_grad(prob, P, u, β); ng = norm(g)
    H = ng < gswitch ? build_Huu(prob, P, u, β) : build_Huu_expected(prob, P, u, β)
    λ = 1e-2 * mean(abs.(diag(H))); λ = (isfinite(λ) && λ > 0) ? λ : 1.0
    λmax = 1e14
    for _ in 1:nit
        ng < tol && break
        ch_try, extra = sparse_pd_chol(H + λ * I)
        if extra > 0; λ = min(λmax, max(λ, λ + extra)); ch_try, _ = sparse_pd_chol(H + λ * I); end
        step = ch_try \ g
        sc = min(1.0, trust / max(maximum(abs, step), eps())); α = sc
        unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 60
            α *= 0.5; unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt += 1
        end
        if isfinite(fnew) && fnew < f
            u = unew; f = fnew
            g = joint_grad(prob, P, u, β); ng = norm(g)
            H = ng < gswitch ? build_Huu(prob, P, u, β) : build_Huu_expected(prob, P, u, β)
            λ = max(1e-12, λ * 0.5)
        else
            λ *= 4.0; λ > λmax && break
        end
    end
    Hobs = build_Huu(prob, P, u, β)
    ch, _ = sparse_pd_chol(Hobs)
    return u, ch, Hobs
end

# E-step dispatcher. WARM start (u0 given): try the cheap fast path first; only
# if it stalls/diverges fall back to the robust LM (warm-started from u0). COLD
# start (u0 === nothing): straight to the robust LM. SAME return contract
# (û, factor, H) with factor/H = OBSERVED Hessian at û (Laplace needs it).
function estep_mode(prob::AugProblem, P::SparseMatrixCSC, β;
                    u0=nothing, n_newton=40, tol=1e-8, trust=5.0, gswitch=1.0)
    if u0 !== nothing
        u, ok = _estep_fast(prob, P, β, Vector{Float64}(u0); n_newton=n_newton)
        if ok
            Hobs = build_Huu(prob, P, u, β)
            ch, _ = sparse_pd_chol(Hobs)
            return u, ch, Hobs
        end
    end
    return _estep_robust(prob, P, β; u0=u0, n_newton=n_newton, tol=tol,
                         trust=trust, gswitch=gswitch)
end

# Laplace marginal log-likelihood. Prior precision P has logdet via its OWN
# Cholesky (P is PSD with a root null space — we use the conditioned form by
# adding the data, so logdet(P) is taken on P + tiny ridge for the constant).
function laplace_ll(prob::AugProblem, P::SparseMatrixCSC, β, u, ch_H)
    nu = 4 * prob.n_total
    jn = joint_nll(prob, P, u, β)
    logdetH = logdet(ch_H)
    # logdet of prior precision (PSD; ridge to make the additive constant finite)
    chP = cholesky(Symmetric(P) + 1e-10I; check=false)
    logdetP = logdet(chP)
    # Laplace: ll = -jn - 0.5 logdetH + 0.5 logdetP + 0.5*nu*log(2π) - 0.5*nu*log(2π)
    #            = -jn - 0.5 logdetH + 0.5 logdetP
    return -jn - 0.5 * logdetH + 0.5 * logdetP
end
