# fit_q4_sparse_tmb.jl — SPARSE "TMB-like" exact-gradient fit of the q=4 PLSM.
#
# Combines two ALREADY-VALIDATED ingredients (do not modify either):
#   (A) the DENSE exact implicit-function-theorem gradient of the Laplace
#       marginal (fit_q4_tmbgrad.jl `marginal_and_exact_grad`, Check C = 6.5e-9);
#   (B) the SPARSE augmented-state Laplace foundation (sparse_aug_plsm.jl /
#       sparse_em_fit.jl, Checkpoint 3 == dense oracle to 1e-10).
#
# The marginal NLL we minimise (drmTMB's ML objective; see laplace_ll):
#     L(θ) = jn(û,θ) + 0.5·logdet H_uu(û,θ) − 0.5·logdet P(θ)
# with logLik = −L. û = inner Newton mode (frozen). The gradient is
#     dL/dθ = ∇_θ[ jn + 0.5 logdetH − 0.5 logdetP ]|_{û frozen}   (cheap)
#           − ∇_θ[ (∇_u jn)' · w ]|_{û, w frozen}                  (implicit)
# where v = 0.5·∇_u logdet H, w = H⁻¹ v (implicit term = (dû/dθ)'·v with
# dû/dθ = −H⁻¹ ∂²jn/∂u∂θ). This mirrors fit_q4_tmbgrad.jl exactly.
#
# Sparse subtleties (H_uu is CHOLMOD — ForwardDiff.Dual does NOT flow through it):
#   • the cheap logdet-H θ-derivative is computed ANALYTICALLY via
#     ∂logdetH/∂θ_k = tr(H⁻¹ ∂H/∂θ_k), using Takahashi selected-inverse entries
#     of H⁻¹ (O(p)); NOT dense ForwardDiff over a dense H (the 229 s mistake).
#   • the cheap logdet-P θ-derivative is analytic: logdetP = const − N·logdet Λ,
#     so −0.5 logdetP contributes via a dense 4×4 logdet (AD-friendly).
#   • everything else (∇_θ jn, the step-5 correction, ∇_u logdetH via Takahashi)
#     is single-level AD or a Takahashi trace — no CHOLMOD in any AD path.
#
# θ layout = [β(7); lc(10)] = 17, lc = log-Cholesky of the 4×4 Λ (lc_to_Λ /
# Λ_to_lc from fit_ml_q4.jl). β = (mu1[k1], mu2[k2], s1[ks1], s2[ks2], rho[kr]).
#
# Run the verification + fit drivers from check_sparse_tmb.jl / run_*.jl.

using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, Optim
include(joinpath(@__DIR__, "fit_ml_q4.jl"))   # pulls sparse_em_fit -> sparse_aug_plsm; lc_to_Λ, Λ_to_lc, make_problem

# -----------------------------------------------------------------------------
# θ pack / unpack against an AugProblem's design widths.
# -----------------------------------------------------------------------------

"Column widths (k1,k2,ks1,ks2,kr) of the five design matrices."
beta_widths(prob::AugProblem) =
    (size(prob.X1, 2), size(prob.X2, 2), size(prob.Xs1, 2), size(prob.Xs2, 2), size(prob.Xr, 2))

"Total θ length = sum(beta widths) + 10 (log-Cholesky Λ)."
function theta_len(prob::AugProblem)
    k1, k2, ks1, ks2, kr = beta_widths(prob)
    return k1 + k2 + ks1 + ks2 + kr + 10
end

"Slice θ into a β NamedTuple and the 10-vector lc (eltype follows θ)."
function unpack_theta(prob::AugProblem, θ::AbstractVector{T}) where {T}
    k1, k2, ks1, ks2, kr = beta_widths(prob)
    o1 = 0; o2 = k1; o3 = o2 + k2; o4 = o3 + ks1; o5 = o4 + ks2; o6 = o5 + kr
    β = (mu1 = θ[o1+1:o1+k1], mu2 = θ[o2+1:o2+k2], s1 = θ[o3+1:o3+ks1],
         s2 = θ[o4+1:o4+ks2], rho = θ[o5+1:o5+kr])
    lc = θ[o6+1:o6+10]
    return β, lc
end

"Build a Float64 θ from a β NamedTuple and a Λ matrix."
pack_theta(β, Λ) = vcat(β.mu1, β.mu2, β.s1, β.s2, β.rho, Λ_to_lc(Λ))

# -----------------------------------------------------------------------------
# TRUE sparse Laplace marginal NLL at a Float64 θ (== −laplace_ll). Used by the
# finite-difference verification and as the line-search objective.
# -----------------------------------------------------------------------------

"""
    marginal_nll(prob, Q_cond, θ; u0, n_newton) -> (nll, û, ch_H, P)

Fresh inner Newton mode + the TRUE sparse Laplace NLL `L(θ)`. `u0` warm-starts
the Newton (the optimiser reuses the previous mode). Returns the CHOLMOD factor
`ch_H` and the sparse prior `P` so callers can reuse them for the gradient.
"""
function marginal_nll(prob::AugProblem, Q_cond::SparseMatrixCSC, θ::Vector{Float64};
                      u0 = nothing, n_newton::Int = 40)
    β, lc = unpack_theta(prob, θ)
    Λ = lc_to_Λ(lc)
    P = prior_precision(Q_cond, inv(Λ))
    u, ch, _ = estep_mode(prob, P, β; u0 = u0, n_newton = n_newton)
    nll = -laplace_ll(prob, P, β, u, ch)
    return nll, u, ch, P
end

# -----------------------------------------------------------------------------
# Per-leaf 4×4×4 third-derivative tensor  T[a,b,c] = ∂(leaf_hess[a,b])/∂u_c.
# ForwardDiff.jacobian of vec(leaf_hess) over the 4-vector u_block (cheap, 4D).
# -----------------------------------------------------------------------------

function leaf_hess_du(ublk::AbstractVector{Float64}, y1, y2, η1, η2, ηs1, ηs2, ηr,
                      o1::Bool = true, o2::Bool = true)
    J = ForwardDiff.jacobian(z -> vec(leaf_hess(z, y1, y2, η1, η2, ηs1, ηs2, ηr, o1, o2)), ublk)
    return reshape(J, 4, 4, 4)            # T[a,b,c]: column c = ∂vec(H)/∂u_c
end

# -----------------------------------------------------------------------------
# ∂(leaf 4×4 data Hessian)/∂β  — jacobian of vec(leaf_hess) wrt the β-subvector
# that enters this leaf's η's. Returns a Dict-free per-leaf closure handled in
# the trace assembly below.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# EXACT sparse gradient of L(θ).
# -----------------------------------------------------------------------------

"""
    marginal_and_exact_grad(prob, Q_cond, θ; u0, n_newton) -> (nll, grad, û, ch_H)

TRUE sparse Laplace NLL and its EXACT 17-dim gradient (cheap + implicit), with
the inner mode `û` FROZEN. All CHOLMOD-blocked logdet θ-derivatives use the
Takahashi selected inverse of H (O(p)); all other pieces are single-level AD.
Returns `û` and the factor so the caller can warm-start the next evaluation.
"""
function marginal_and_exact_grad(prob::AugProblem, Q_cond::SparseMatrixCSC,
                                 θ::Vector{Float64}; u0 = nothing, n_newton::Int = 40)
    nθ = length(θ)
    k1, k2, ks1, ks2, kr = beta_widths(prob)
    o1 = 0; o2 = k1; o3 = o2 + k2; o4 = o3 + ks1; o5 = o4 + ks2; o6 = o5 + kr

    β, lc = unpack_theta(prob, θ)
    Λ  = lc_to_Λ(lc)
    Λi = inv(Λ)

    # ---- Step 1: inner Newton mode û (FROZEN) ------------------------------
    P = prior_precision(Q_cond, Λi)
    u_hat, chH, H = estep_mode(prob, P, β; u0 = u0, n_newton = n_newton)
    u_hat = Vector{Float64}(u_hat)
    nll = -laplace_ll(prob, P, β, u_hat, chH)

    grad = zeros(nθ)

    # ---- Selected inverse of H (Takahashi, O(p)) ----------------------------
    # Provides H⁻¹ at H's (and Q_cond's) sparsity pattern: diagonal 4×4 leaf
    # blocks (for β & u logdet traces) and Q-pattern node-pair blocks (for the
    # Λ logdet trace). Same object mstep_Lambda uses.
    Vsel = takahashi_selinv(chH)

    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)

    # =======================================================================
    # CHEAP gradient: ∇_θ[ jn + 0.5 logdetH − 0.5 logdetP ]|_{û frozen}.
    # =======================================================================

    # --- (2a) ∇_θ jn(û,θ): single-level AD over θ (no CHOLMOD). ------------
    jn_of_θ = function (t::AbstractVector)
        βt, lct = unpack_theta(prob, t)
        Λt = lc_to_Λ(lct)
        Pt = prior_precision(Q_cond, inv(Λt))
        return joint_nll_T(prob, Pt, u_hat, βt)
    end
    grad .+= ForwardDiff.gradient(jn_of_θ, θ)

    # --- (2b) −0.5 ∇_θ logdetP: analytic. logdetP = const − N·logdet Λ, so
    #          −0.5 logdetP = const + 0.5 N logdet Λ(lc). AD over the dense 4×4
    #          logdet (CHOLMOD-free). Only the 10 lc entries are nonzero. ----
    N = prob.n_total
    glogdetΛ = ForwardDiff.gradient(v -> logdet(Symmetric(lc_to_Λ(v))), lc)
    grad[o6+1:o6+10] .+= 0.5 * N .* glogdetΛ

    # --- (2c) 0.5 ∇_θ logdetH via tr(H⁻¹ ∂H/∂θ_k), Takahashi. --------------
    # β-block: ∂H/∂β_k = blockdiag_leaves( ∂(leaf_hess_i)/∂β_k ). Trace picks
    # only the diagonal 4×4 H⁻¹ block at each leaf node.
    #   tr(H⁻¹ ∂H/∂β_k) = Σ_i Σ_{a,b} Vsel[bt+a, bt+b] · dHb_i[a,b]/dβ_k.
    # We get the per-leaf ∂vec(Hb)/∂(its β inputs) once via ForwardDiff over the
    # 5 η-scalars, then chain to β through the design rows.
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; bt = 4(t - 1)
        # Vsel diagonal 4×4 block at this leaf node.
        Vblk = @view Vsel[bt+1:bt+4, bt+1:bt+4]
        # ∂vec(leaf_hess)/∂(η1,η2,ηs1,ηs2,ηr) at this leaf (16×5).
        Jη = ForwardDiff.jacobian(
            e -> vec(leaf_hess([u_hat[bt+1], u_hat[bt+2], u_hat[bt+3], u_hat[bt+4]],
                               prob.y1[i], prob.y2[i], e[1], e[2], e[3], e[4], e[5],
                               prob.obs1[i], prob.obs2[i])),
            [η1[i], η2[i], ηs1[i], ηs2[i], ηr[i]])
        # contraction tr(Vblk · dHb/dη_m) for each η_m (m=1..5):
        #   s_m = Σ_{a,b} Vblk[a,b] · dHb[a,b]/dη_m  (Hb symmetric ⇒ Vblk too).
        sη = zeros(5)
        for m in 1:5
            acc = 0.0
            col = @view Jη[:, m]                 # ∂vec(Hb)/∂η_m, length 16
            for b in 1:4, a in 1:4
                acc += Vblk[a, b] * col[(b-1)*4 + a]
            end
            sη[m] = acc
        end
        # chain η_m = x_row · β_block to β via the design rows. 0.5 factor here.
        for c in 1:k1;  grad[o1+c] += 0.5 * sη[1] * prob.X1[i, c];  end
        for c in 1:k2;  grad[o2+c] += 0.5 * sη[2] * prob.X2[i, c];  end
        for c in 1:ks1; grad[o3+c] += 0.5 * sη[3] * prob.Xs1[i, c]; end
        for c in 1:ks2; grad[o4+c] += 0.5 * sη[4] * prob.Xs2[i, c]; end
        for c in 1:kr;  grad[o5+c] += 0.5 * sη[5] * prob.Xr[i, c];  end
    end

    # lc-block: ∂H/∂lc_k = kron(Q_cond, ∂Λ⁻¹/∂lc_k). With node-major kron,
    #   tr(H⁻¹ ∂H/∂lc_k) = Σ_{(s,t)∈Q} Q[s,t] Σ_{a,b} Vsel[bt+a, bs+b]·Mk[b,a],
    # Mk = ∂Λ⁻¹/∂lc_k (4×4). Build the per-(s,t) accumulator G_st[b,a] =
    # Σ_{(s,t)} Q[s,t]·Vsel[bt+a, bs+b] ONCE, then contract with each Mk → the
    # whole lc logdet trace costs one O(nnz Q) pass + 10 cheap 4×4 contractions.
    Gst = zeros(4, 4)   # Gst[b,a] = Σ_{s,t} Q[s,t]·Vsel[4(t-1)+a, 4(s-1)+b]
    rows = rowvals(Q_cond); vals = nonzeros(Q_cond)
    @inbounds for tcol in 1:N
        for idx in nzrange(Q_cond, tcol)
            s = rows[idx]; q = vals[idx]
            bs = 4(s - 1); bt = 4(tcol - 1)
            for a in 1:4, b in 1:4
                Gst[b, a] += q * Vsel[bt + a, bs + b]
            end
        end
    end
    # ∂Λ⁻¹/∂lc_k = −Λ⁻¹ (∂Λ/∂lc_k) Λ⁻¹. Get ∂Λ/∂lc_k (4×4) per k via AD, then
    # Mk = −Λi*dΛk*Λi; trace contribution 0.5·Σ_{a,b} Gst[b,a]·Mk[b,a].
    dΛ = ForwardDiff.jacobian(lc_to_Λ, lc)        # 16×10, column k = vec(∂Λ/∂lc_k)
    for k in 1:10
        dΛk = reshape(@view(dΛ[:, k]), 4, 4)
        Mk = -Λi * dΛk * Λi
        acc = 0.0
        for a in 1:4, b in 1:4
            acc += Gst[b, a] * Mk[b, a]
        end
        grad[o6 + k] += 0.5 * acc
    end

    # =======================================================================
    # IMPLICIT correction: −∇_θ[ (∇_u jn)' w ],  v = 0.5 ∇_u logdetH, w = H⁻¹ v.
    # =======================================================================

    # --- Step 3: v_k = 0.5·tr(H⁻¹ ∂H/∂u_k). Only leaf blocks depend on u. ---
    nu = 4 * prob.n_total
    v = zeros(nu)
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; bt = 4(t - 1)
        Vblk = @view Vsel[bt+1:bt+4, bt+1:bt+4]
        T = leaf_hess_du([u_hat[bt+1], u_hat[bt+2], u_hat[bt+3], u_hat[bt+4]],
                         prob.y1[i], prob.y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i],
                         prob.obs1[i], prob.obs2[i])
        for c in 1:4
            acc = 0.0
            for b in 1:4, a in 1:4
                acc += Vblk[a, b] * T[a, b, c]   # tr(Vblk · T[:,:,c])
            end
            v[bt + c] += 0.5 * acc      # += : sum over a node's replicate obs
        end
    end

    # --- Step 4: w = H⁻¹ v (one sparse Cholesky solve). --------------------
    w = chH \ v

    # --- Step 5: correction = −∇_θ[ dot(∇_u jn(û,θ), w) ]|_{û,w frozen}. ----
    scalar_of_θ = function (t::AbstractVector)
        βt, lct = unpack_theta(prob, t)
        Λt = lc_to_Λ(lct)
        Pt = prior_precision(Q_cond, inv(Λt))
        gu = joint_grad_T(prob, Pt, u_hat, βt)   # ∇_u jn at frozen û, θ-dependent
        return dot(gu, w)
    end
    grad .-= ForwardDiff.gradient(scalar_of_θ, θ)

    return nll, grad, u_hat, chH
end

# -----------------------------------------------------------------------------
# Type-generic joint nll / joint grad (sparse P with Dual nzval; û Float64).
# Mirror joint_nll / joint_grad from sparse_aug_plsm.jl but accept a Dual θ via
# a Dual-valued P and β. û stays Float64 (frozen).
# -----------------------------------------------------------------------------

function joint_nll_T(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
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

function joint_grad_T(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    g = P * u                                   # eltype follows P (Dual ok)
    @inbounds for i in eachindex(prob.leaf_node)   # over DATA ROWS (≥1 per leaf)
        t = prob.leaf_node[i]; base = 4(t - 1)
        ublk = [u[base+1], u[base+2], u[base+3], u[base+4]]
        gb = leaf_grad(ublk, prob.y1[i], prob.y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i],
                       prob.obs1[i], prob.obs2[i])
        for a in 1:4
            g[base + a] += gb[a]
        end
    end
    return g
end

# -----------------------------------------------------------------------------
# Fit driver: Optim only_fg! + LBFGS(BackTracking), warm-started inner Newton.
# -----------------------------------------------------------------------------

function fit_q4_sparse_tmb(prob::AugProblem, Q_cond::SparseMatrixCSC;
                           θ0 = nothing, β0 = nothing, Λ0 = nothing,
                           g_tol::Float64 = 1e-3, iterations::Int = 200,
                           n_newton::Int = 40, show_trace::Bool = false,
                           # `lc_zero`: log-Cholesky indices (1..10) pinned to 0 so
                           # the optimiser never moves them — an OUTER constraint on
                           # Σ_a, leaving marginal_and_exact_grad untouched. Zeroing
                           # the cross-block entries {3,4,6,7} (L31,L41,L32,L42) makes
                           # the Cholesky factor block-lower-triangular ⇒ an EXACTLY
                           # block-diagonal Σ_a (spec D: mu↔sigma cov fixed at 0).
                           lc_zero::AbstractVector{<:Integer} = Int[],
                           # MoreThuente (Wolfe) converges in ~94 iters / 1.36 s at
                           # p=100 vs BackTracking's 120 / 2.55 s — 1.82× over drmTMB.
                           # The Inf barrier in fg! keeps it robust to bad trial steps.
                           linesearch = Optim.LineSearches.MoreThuente())
    if θ0 === nothing
        β0 === nothing && error("supply θ0 or (β0, Λ0)")
        Λ0 === nothing && (Λ0 = Matrix(0.3 * I(4)))
        θ0 = pack_theta(β0, Matrix(Λ0))
    end
    # Map pinned lc indices to absolute θ positions and pin θ0 to 0 there. The
    # cross-block off-diagonals are 0 in a block-diagonal Σ_a Cholesky, so this is
    # the only point the constrained start must touch.
    k1, k2, ks1, ks2, kr = beta_widths(prob)
    o6 = k1 + k2 + ks1 + ks2 + kr
    lc_zero_idx = sort(unique(Int.(lc_zero)))
    all(1 .<= lc_zero_idx .<= 10) ||
        error("lc_zero indices must be in 1:10 (got $lc_zero_idx)")
    θ_zero = o6 .+ lc_zero_idx          # absolute θ positions pinned to 0
    θ0 = copy(Vector{Float64}(θ0)); θ0[θ_zero] .= 0.0

    # Warm-start cache: reuse the previous mode across f/g evaluations. Cleared
    # to `nothing` if an evaluation throws (defensive — estep is PD-guarded).
    u_cache = Ref{Union{Nothing, Vector{Float64}}}(nothing)

    fg! = function (F, G, θ)
        local nll, g, û
        try
            nll, g, û, _ = marginal_and_exact_grad(prob, Q_cond, Vector{Float64}(θ);
                                                   u0 = u_cache[], n_newton = n_newton)
        catch e
            # Implicit-constraint barrier: a trial step that breaks PD-ness or the
            # ρ guard makes the marginal undefined. Return Inf (no gradient) so the
            # BackTracking line search rejects it and shrinks the step.
            (e isa DomainError || e isa LinearAlgebra.PosDefException ||
             e isa LinearAlgebra.SingularException) || rethrow(e)
            return Inf
        end
        any(!isfinite, g) && return Inf
        # Pin the constrained lc directions: zero their gradient so LBFGS never
        # steps along them. With θ0 already 0 there, those θ stay 0 throughout ⇒
        # the fit runs on the active (block-diagonal) subspace only.
        isempty(θ_zero) || (g[θ_zero] .= 0.0)
        u_cache[] = û
        # Optimise the MEAN (per-observation) objective, not the SUM: gradient &
        # Hessian scale ∝ p, so a sum-objective's step scale is p-dependent and
        # fits stall/blow up as p grows. The mean objective is scale-INVARIANT —
        # identical argmax (MLE), p-independent landscape → robust across p.
        G !== nothing && copyto!(G, g ./ length(prob.leaf_node))
        return nll / length(prob.leaf_node)   # mean over OBSERVATIONS (= #data rows)
    end
    od = Optim.NLSolversBase.only_fg!(fg!)

    res = Optim.optimize(
        od, θ0,
        # alphaguess scaled=true: the FIRST step is α/‖g‖ (gradient-normalised),
        # so a huge init gradient (fresh/poorly-scaled data) can't make the first
        # step overshoot → fixes the 1-iter quit AND the at-scale Λ→NaN blow-up.
        LBFGS(alphaguess = Optim.LineSearches.InitialStatic(scaled = true),
              linesearch = linesearch),
        # Singular-model stopping: near the variance boundary the Fisher info is
        # degenerate, so ‖g‖ plateaus (~0.2-0.4) and never reaches g_tol — both
        # this engine and drmTMB hit it (drmTMB: "false convergence (8)"). The
        # correct criterion is RELATIVE OBJECTIVE CHANGE (info-geometry-scout.md,
        # pain #3). Require 2 successive sub-tol steps to avoid a premature stop.
        Optim.Options(g_tol = g_tol, f_reltol = 1e-7, successive_f_tol = 3,
                      iterations = iterations,
                      show_trace = show_trace, show_every = 1),
    )

    θ_hat = Optim.minimizer(res)
    β_hat, lc_hat = unpack_theta(prob, θ_hat)
    return (
        θ = θ_hat,
        β = β_hat,
        Λ = lc_to_Λ(lc_hat),
        nll = Optim.minimum(res) * length(prob.leaf_node),   # un-normalise (mean obj)
        loglik = -Optim.minimum(res) * length(prob.leaf_node),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
        g_residual = Optim.g_residual(res),
        f_calls = Optim.f_calls(res),
        g_calls = Optim.g_calls(res),
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    println("fit_q4_sparse_tmb.jl loaded: marginal_nll, marginal_and_exact_grad, " *
            "fit_q4_sparse_tmb available.")
end
