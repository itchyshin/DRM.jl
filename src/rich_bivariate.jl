# rich_bivariate.jl — FREQUENTIST SPARSE O(p) MR-PMM: two non-Gaussian responses
# sharing a correlated 2-axis latent field over the phylogenetic node set.
#
# Cluster 5b — RICH bivariate non-Gaussian covariance block.
#
# MODEL
# -----
# Two response vectors y1 (family1) and y2 (family2), each of length n.
# Data row i maps to a tip s(i) with leaf_node[i] in the augmented node set.
#
# Latent u ∈ ℝ^{2·N}:
#   u[2t-1] = axis-1 latent at (augmented) node t
#   u[2t]   = axis-2 latent at node t
# Prior: u ~ N(0, P⁻¹),  P = kron(Q_cond, Λ⁻¹),  Λ = 2×2 among-trait cov.
#
# Per observation i (at node t = leaf_node[i]):
#   η1_i = X1[i,:]·β1 + u[2t-1]     (axis-1 linear predictor)
#   η2_i = X2[i,:]·β2 + u[2t]        (axis-2 linear predictor)
#
# The two axes are INDEPENDENT given u (block-diagonal leaf Hessian). Their
# coupling is entirely through the 2×2 Λ prior covariance.  This is the standard
# MR-PMM latent-scale identification (Hadfield–Nakagawa).
#
# Leaf likelihood: per obs i
#   log p(y1_i | η1_i) + log p(y2_i | η2_i)
# where each term uses the `_ls_nll / _ls_grad / _ls_hess` kernel from
# locscale_kernels.jl.  The Poisson kernel ignores the ψ axis (hψψ=0), so for
# Poisson the scale latent is simply absent from that axis.
#
# ITERATED LAPLACE MARGINAL
# --------------------------
# Inner joint:
#   jn(u) = Σ_i [_ls_nll(kind1, y1_i, η1_i, 0) + _ls_nll(kind2, y2_i, 0, η2_i)]
#           + ½ u' P u
# where the Poisson / Gamma families are used as MEAN-ONLY (ψ = 0 fixed; the
# dispersion is a scalar dispersion parameter, not a per-node latent here — the
# MR-PMM identification uses a SINGLE per-axis shape/size parameter for each
# dispersed family, NOT a latent per node).
#
# NOTE: Because the two axes are at different nodes of the same precision P, we
# re-use the existing _ls_inner_mode machinery but adapt it to TWO DIFFERENT
# family kernels per axis rather than the (mean, scale) semantics of the
# location-scale model.  The two axes are "axis-1 → family1 leaf" and "axis-2 →
# family2 leaf" with INDEPENDENT cross-axis Hessian (hηψ = 0 between the two
# families).
#
# EXACT O(p) GRADIENT
# --------------------
# Uses the same recipe as marginal_and_exact_grad (fit_q4_sparse_tmb.jl) and
# _ls_marginal_grad (locscale_grad.jl):
#   1. Takahashi selected inverse of H for logdet-H traces.
#   2. −½ logdet P contribution from the log-Cholesky Λ.
#   3. Implicit adjoint: v_j = ½ tr(H⁻¹ ∂H/∂u_j), w = H⁻¹ v.
#   4. Correction = −∇_θ[ g(û,θ) · w ] with û, w frozen.
#
# θ = [β1 (p1);  β2 (p2);  lc (3 for 2×2 Λ);  disp1 (0 or 1);  disp2 (0 or 1)]
# where disp is the log-dispersion scalar (log shape for Gamma, log size for NB2;
# 0 entries for Poisson).
#
# ρ12 PROFILE CI
# ---------------
# ρ12 = Λ[1,2] / √(Λ[1,1]·Λ[2,2]).  We parameterise via the off-diagonal lc
# entry lc[2] (which is L[2,1]).  The profile CI for the index of lc[2] in θ
# uses the same _ls_profile_root / _ls_profile_ci machinery.
#
# HARD GATE
# ----------
# (a) REDUCTION: with both axes Gaussian, the iterated-Laplace marginal must
#     equal coevo_marginal (the conjugate exact marginal) to ≤ 1e-6.
# (b) FD gradient gate: off-optimum, central-FD, ≤ 1e-6 (or ≤ 0.01 for Beta).
# (c) Recovery test on simulated Poisson+Gamma tree DGP.
# (d) ρ12 profile CI is sane (contains truth, finite).
# (e) No-regression: existing tests still pass.

using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Random

# ---------------------------------------------------------------------------
# Problem container
# ---------------------------------------------------------------------------

"""
    RichBivarProblem

Dataset for the bivariate non-Gaussian MR-PMM. `y1[i]` and `y2[i]` are the two
responses for data row `i`.  `X1` and `X2` are the per-axis fixed-effect designs.
`leaf_node[i]` maps row `i` to the augmented node index (same convention as
CoevoProblem / AugProblem).
"""
struct RichBivarProblem
    N::Int                        # n_keep = 2p-2 augmented (non-root) nodes
    p::Int                        # number of tips
    leaf_node::Vector{Int}        # data row i → augmented node column in 1:N
    y1::Vector{Float64}           # response axis 1 (length n)
    y2::Vector{Float64}           # response axis 2 (length n)
    X1::Matrix{Float64}           # n × p1 design for axis 1
    X2::Matrix{Float64}           # n × p2 design for axis 2
    kind1                         # Val{:poisson} etc.
    kind2
    has_disp1::Bool               # does family1 have a free scalar dispersion?
    has_disp2::Bool               # does family2 have a free scalar dispersion?
end

"""
    families_with_dispersion

Set of locscale family symbols that carry a free scalar dispersion (shape/size).
Poisson does not; Gamma and NB2 do; Beta and BetaBinomial use ψ as the per-obs
latent, not here.
"""
const _RB_HAS_DISP = Set([:gamma, :nb2, :gaussian_mean, :lognormal])

"""
    make_rich_bivar_problem(phy, y1, y2, X1, X2, kind1, kind2; species) -> (prob, Q_cond)

Build a RichBivarProblem and the root-conditioned sparse tree precision Q_cond.
"""
function make_rich_bivar_problem(phy, y1::AbstractVector, y2::AbstractVector,
                                 X1::AbstractMatrix, X2::AbstractMatrix,
                                 kind1, kind2;
                                 species = 1:phy.n_leaves)
    Q_cond, leaf_pos, N = augmented_tree_precision(phy)
    n = length(y1)
    length(y2) == n || error("y1 and y2 must have the same length")
    size(X1, 1) == n || error("X1 has wrong number of rows")
    size(X2, 1) == n || error("X2 has wrong number of rows")
    length(species) == n || error("species has wrong length")
    leaf_node = [leaf_pos[species[i]] for i in 1:n]
    sym1 = _val_to_sym(kind1); sym2 = _val_to_sym(kind2)
    prob = RichBivarProblem(N, phy.n_leaves, leaf_node,
                            Float64.(y1), Float64.(y2),
                            Float64.(X1), Float64.(X2),
                            kind1, kind2,
                            sym1 ∈ _RB_HAS_DISP, sym2 ∈ _RB_HAS_DISP)
    return prob, Q_cond
end

_val_to_sym(::Val{S}) where {S} = S
_val_to_sym(s::Symbol) = s

# ---------------------------------------------------------------------------
# θ packing / unpacking.
# θ = [β1 (p1);  β2 (p2);  lc (3);  log_disp1 (0 or 1);  log_disp2 (0 or 1)]
# ---------------------------------------------------------------------------

function _rb_theta_len(prob::RichBivarProblem)
    return size(prob.X1, 2) + size(prob.X2, 2) + 3 +
           Int(prob.has_disp1) + Int(prob.has_disp2)
end

function _rb_unpack(prob::RichBivarProblem, θ::AbstractVector{T}) where {T}
    p1 = size(prob.X1, 2); p2 = size(prob.X2, 2)
    β1 = θ[1:p1]
    β2 = θ[p1+1:p1+p2]
    lc = θ[p1+p2+1:p1+p2+3]
    Λ  = _ls_lc_to_Λ(lc)
    o  = p1 + p2 + 3
    logd1 = prob.has_disp1 ? θ[o+1]  : zero(T)
    logd2 = prob.has_disp2 ? θ[o + Int(prob.has_disp1) + 1] : zero(T)
    return β1, β2, Λ, lc, logd1, logd2
end

function _rb_pack(prob::RichBivarProblem,
                  β1::AbstractVector, β2::AbstractVector,
                  Λ::AbstractMatrix, logd1::Real = 0.0, logd2::Real = 0.0)
    lc = _ls_Λ_to_lc(Λ)
    v  = vcat(Float64.(β1), Float64.(β2), lc)
    prob.has_disp1 && push!(v, Float64(logd1))
    prob.has_disp2 && push!(v, Float64(logd2))
    return v
end

# ---------------------------------------------------------------------------
# Per-leaf bivariate leaf NLL / grad / hess.
#
# The "bivariate" kernel is BLOCK-DIAGONAL: axis 1 uses kind1, axis 2 uses kind2.
# The ψ argument to each kernel:
#   - Gaussian: ψ = log(σ_res) — a scalar dispersion
#   - Poisson:  ψ = 0.0 (ignored; no free dispersion)
#   - Gamma:    ψ = log(shape) — a scalar
#   - NB2:      ψ = log(size)  — a scalar
#
# The "axis-1" and "axis-2" latent effects are u1 = u[2t-1], u2 = u[2t] at node t.
# ---------------------------------------------------------------------------

# Per-obs bivariate NLL: nll1(η1+u1, ψ1) + nll2(η2+u2, ψ2).
@inline function _rb_nll(kind1, kind2, y1, y2, η1, η2, ψ1, ψ2, u1, u2)
    _ls_nll(kind1, y1, η1 + u1, ψ1) + _ls_nll(kind2, y2, η2 + u2, ψ2)
end

# Gradient wrt (u1, u2): [∂nll1/∂η1, ∂nll2/∂η2].
@inline function _rb_grad_u(kind1, kind2, y1, y2, η1, η2, ψ1, ψ2, u1, u2)
    g1η, _ = _ls_grad(kind1, y1, η1 + u1, ψ1)
    g2η, _ = _ls_grad(kind2, y2, η2 + u2, ψ2)
    return g1η, g2η
end

# Block Hessian wrt (u1, u2) — 2×2 diagonal (hηη1, 0; 0, hηη2).
@inline function _rb_hess_u(kind1, kind2, y1, y2, η1, η2, ψ1, ψ2, u1, u2)
    h1ηη, _, _ = _ls_hess(kind1, y1, η1 + u1, ψ1)
    h2ηη, _, _ = _ls_hess(kind2, y2, η2 + u2, ψ2)
    return h1ηη, h2ηη   # diagonal; off-diagonal = 0
end

# Third derivative ∂²nll_k/∂uk²  differentiated wrt uk (= tηηη_k).
@inline function _rb_third_u(kind1, kind2, y1, y2, η1, η2, ψ1, ψ2, u1, u2)
    # axis 1: d/du1 of h1ηη (scalar, diagonal block)
    t1 = ForwardDiff.derivative(z -> begin
        h, _, _ = _ls_hess(kind1, y1, η1 + z, ψ1); h
    end, u1)
    t2 = ForwardDiff.derivative(z -> begin
        h, _, _ = _ls_hess(kind2, y2, η2 + z, ψ2); h
    end, u2)
    return t1, t2
end

# ---------------------------------------------------------------------------
# Joint NLL and its gradient wrt u for the inner Newton.
# u is laid out node-major: u[2t-1] = axis-1, u[2t] = axis-2 at node t.
# ---------------------------------------------------------------------------

function _rb_joint(prob::RichBivarProblem, P::SparseMatrixCSC,
                   β1::AbstractVector, β2::AbstractVector,
                   ψ1::Real, ψ2::Real, u::AbstractVector)
    η10 = prob.X1 * β1
    η20 = prob.X2 * β2
    s = 0.5 * dot(u, P * u)
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        s += _rb_nll(prob.kind1, prob.kind2, prob.y1[i], prob.y2[i],
                     η10[i], η20[i], ψ1, ψ2, u1, u2)
    end
    return s
end

function _rb_joint_grad(prob::RichBivarProblem, P::SparseMatrixCSC,
                        β1::AbstractVector, β2::AbstractVector,
                        ψ1::Real, ψ2::Real, u::AbstractVector)
    η10 = prob.X1 * β1
    η20 = prob.X2 * β2
    g = Vector{eltype(u)}(undef, length(u))
    mul!(g, P, u)   # g .= P*u
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        gu1, gu2 = _rb_grad_u(prob.kind1, prob.kind2, prob.y1[i], prob.y2[i],
                               η10[i], η20[i], ψ1, ψ2, u1, u2)
        g[2t-1] += gu1
        g[2t]   += gu2
    end
    return g
end

# Build H = P + block-diagonal data Hessian (2×2 diagonal blocks at leaf nodes).
function _rb_build_Huu(prob::RichBivarProblem, P::SparseMatrixCSC,
                       β1::AbstractVector, β2::AbstractVector,
                       ψ1::Real, ψ2::Real, u::AbstractVector)
    η10 = prob.X1 * β1
    η20 = prob.X2 * β2
    H = copy(P)
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        h1, h2 = _rb_hess_u(prob.kind1, prob.kind2, prob.y1[i], prob.y2[i],
                              η10[i], η20[i], ψ1, ψ2, u1, u2)
        H[2t-1, 2t-1] += h1
        H[2t,   2t  ] += h2
    end
    return H
end

# ---------------------------------------------------------------------------
# Inner mode (iterated Laplace): Newton on jn(u) with Levenberg–Marquardt
# damping and backtracking line search.  Mirrors _ls_inner_mode from
# locscale_inner.jl.
# ---------------------------------------------------------------------------

function _rb_inner_mode(prob::RichBivarProblem, P::SparseMatrixCSC,
                        β1::AbstractVector, β2::AbstractVector,
                        ψ1::Real, ψ2::Real;
                        u0 = nothing, maxiter::Int = 200, tol::Real = 1e-9)
    u = u0 === nothing ? zeros(2 * prob.N) : copy(Float64.(u0))
    for _ in 1:maxiter
        g = _rb_joint_grad(prob, P, β1, β2, ψ1, ψ2, u)
        if norm(g) <= tol * (1 + norm(u))
            H = _rb_build_Huu(prob, P, β1, β2, ψ1, ψ2, u)
            ch = cholesky(Symmetric(H); check = false)
            return u, ch, issuccess(ch)
        end
        H = _rb_build_Huu(prob, P, β1, β2, ψ1, ψ2, u)
        f0 = _rb_joint(prob, P, β1, β2, ψ1, ψ2, u)
        λ = 0.0
        stepped = false
        while true
            F = cholesky(Symmetric(H + λ * I); check = false)
            if issuccess(F)
                step = F \ g
                α = 1.0
                while α >= 1e-10
                    trial = u .- α .* step
                    ft = _rb_joint(prob, P, β1, β2, ψ1, ψ2, trial)
                    if isfinite(ft) && ft <= f0
                        u = trial; stepped = true; break
                    end
                    α *= 0.5
                end
                stepped && break
            end
            λ = λ == 0.0 ? 1e-8 : 10λ
            λ > 1e12 && break
        end
        if !stepped
            H2 = _rb_build_Huu(prob, P, β1, β2, ψ1, ψ2, u)
            ch = cholesky(Symmetric(H2); check = false)
            return u, ch, false
        end
    end
    H = _rb_build_Huu(prob, P, β1, β2, ψ1, ψ2, u)
    ch = cholesky(Symmetric(H); check = false)
    return u, ch, issuccess(ch)
end

# ---------------------------------------------------------------------------
# Laplace marginal NLL: jn(û) + ½ logdet H − ½ logdet P
# ---------------------------------------------------------------------------

function _rb_marginal_nll(prob::RichBivarProblem, P::SparseMatrixCSC,
                          β1::AbstractVector, β2::AbstractVector,
                          ψ1::Real, ψ2::Real;
                          u0 = nothing, tol::Real = 1e-9)
    u, ch, ok = _rb_inner_mode(prob, P, β1, β2, ψ1, ψ2; u0 = u0, tol = tol)
    ok || return Inf, u, false
    jn = _rb_joint(prob, P, β1, β2, ψ1, ψ2, u)
    logdetH = logdet(ch)
    chP = cholesky(Symmetric(P); check = false)
    issuccess(chP) || return Inf, u, false
    logdetP = logdet(chP)
    return jn + 0.5 * logdetH - 0.5 * logdetP, u, true
end

# Packed interface: θ = [β1; β2; lc(3); logd1?; logd2?]
function _rb_fit_nll(prob::RichBivarProblem, Q_cond::SparseMatrixCSC, θ::AbstractVector;
                     u0 = nothing, tol::Real = 1e-9)
    β1, β2, Λ, _, logd1, logd2 = _rb_unpack(prob, θ)
    ψ1 = Float64(logd1); ψ2 = Float64(logd2)
    Λinv = _ls_inv2x2(Λ)
    P = prior_precision(Q_cond, Λinv)
    val, _, ok = _rb_marginal_nll(prob, P, β1, β2, ψ1, ψ2; u0 = u0, tol = tol)
    return ok ? val : 1e18
end

# ---------------------------------------------------------------------------
# Exact O(p) gradient: mirrors marginal_and_exact_grad / _ls_marginal_grad.
#
# Recipe (with û frozen):
#   dL/dθ = ∂jn/∂θ + ½ tr(H⁻¹ ∂H/∂θ) − ½ tr(P⁻¹ ∂P/∂θ) − wᵀ ∂g/∂θ
# where v_j = ½ tr(H⁻¹ ∂H/∂u_j), w = H⁻¹ v.
# ---------------------------------------------------------------------------

function _rb_marginal_grad(prob::RichBivarProblem, Q_cond::SparseMatrixCSC,
                           θ::AbstractVector; u0 = nothing, tol::Real = 1e-9)
    p1 = size(prob.X1, 2); p2 = size(prob.X2, 2)
    β1, β2, Λ, lc, logd1, logd2 = _rb_unpack(prob, θ)
    ψ1 = Float64(logd1); ψ2 = Float64(logd2)
    Λinv = _ls_inv2x2(Λ)
    P = prior_precision(Q_cond, Λinv)

    u, ch, ok = _rb_inner_mode(prob, P, β1, β2, ψ1, ψ2; u0 = u0, tol = tol)
    grad = zeros(length(θ))
    ok || return grad

    # Selected inverse of H (Takahashi, O(p))
    Vsel = takahashi_selinv(ch)
    G = prob.N

    η10 = prob.X1 * β1
    η20 = prob.X2 * β2

    # ------------------------------------------------------------------
    # (A) ∂jn/∂θ at frozen û: split into β1 / β2 / lc / disp parts.
    # The joint splits as jn = prior_part + Σ_i nll_i(η1_i+u1, η2_i+u2, ψ1, ψ2).
    # The prior part ½ û' P û depends on lc (via P); the nll_i terms depend on
    # β and the disp scalars.  Use AD for the prior part and an explicit obs loop
    # for the data part.
    # ------------------------------------------------------------------

    # (A1) ∂(Σ_i nll_i)/∂β1, ∂β2, ∂logd1, ∂logd2 — explicit obs loop.
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        # Axis-1 score wrt η1: gη1 = ∂nll1/∂η1 (chain through β1 via X1[i,:])
        gη1, gψ1 = _ls_grad(prob.kind1, prob.y1[i], η10[i] + u1, ψ1)
        gη2, gψ2 = _ls_grad(prob.kind2, prob.y2[i], η20[i] + u2, ψ2)
        for k in 1:p1
            grad[k] += gη1 * prob.X1[i, k]
        end
        for k in 1:p2
            grad[p1+k] += gη2 * prob.X2[i, k]
        end
        if prob.has_disp1
            grad[p1+p2+3+1] += gψ1
        end
        if prob.has_disp2
            grad[p1+p2+3+Int(prob.has_disp1)+1] += gψ2
        end
    end

    # (A2) ∂(½ û' P û)/∂lc — analytic via ∂Λ⁻¹/∂lc_k.
    # ½ û' P û = ½ û' kron(Q, Λ⁻¹) û.
    # ∂/∂lc_k = ½ Σ_{s,t} Q[s,t] [û_block(t)]' (∂Λ⁻¹/∂lc_k) û_block(s)
    # where û_block(t) = (u[2t-1], u[2t]).
    dΛ = ForwardDiff.jacobian(v -> _ls_lc_to_Λ(v), lc)   # 4×3 (vec(Λ) × lc)
    for k in 1:3
        dΛk = reshape(@view(dΛ[:, k]), 2, 2)
        Mk = -Λinv * dΛk * Λinv     # ∂Λ⁻¹/∂lc_k
        acc = 0.0
        qrows = rowvals(Q_cond); qvals = nonzeros(Q_cond)
        for tcol in 1:G
            for idx in nzrange(Q_cond, tcol)
                s = qrows[idx]; q_val = qvals[idx]
                u_t1 = u[2tcol-1]; u_t2 = u[2tcol]
                u_s1 = u[2s-1]; u_s2 = u[2s]
                Mu_s1 = Mk[1,1]*u_s1 + Mk[1,2]*u_s2
                Mu_s2 = Mk[2,1]*u_s1 + Mk[2,2]*u_s2
                acc += 0.5 * q_val * (u_t1*Mu_s1 + u_t2*Mu_s2)
            end
        end
        grad[p1+p2+k] += acc
    end

    # ------------------------------------------------------------------
    # (B) ½ tr(H⁻¹ ∂H/∂θ_k) terms (Takahashi diagonal blocks).
    # ∂H/∂β1_k:  block-diagonal; at node t, ∂H[2t-1,2t-1]/∂β1_k = Σ_{i at t} h'1ηη · X1[i,k]
    # ∂H/∂β2_k:  idem for axis 2.
    # ∂H/∂lc_k:  ∂P/∂lc_k = kron(Q, Mk); trace over Q pattern.
    # ∂H/∂logd:  block-diagonal; ∂H[2t-1,2t-1]/∂logd1 = Σ_{i at t} ∂h1ηη/∂ψ1 · 1 (chain rule d/dlogd = exp·)
    # ------------------------------------------------------------------

    # Accumulate per-node Vsel diagonal: Vsel[2t-1,2t-1] and Vsel[2t,2t].
    # Also need off-diagonal for the lc trace.

    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        # Vsel diagonal 2×2 block at node t (selected inverse).
        v11 = Vsel[2t-1, 2t-1]; v22 = Vsel[2t, 2t]

        # ∂h1ηη/∂u1 for the v vector (step 3 of the implicit adjoint).
        # ∂h2ηη/∂u2 similarly.  These are the third derivatives tηηη_k.
        # (B-beta) ∂H[2t-1,2t-1]/∂β1_k = Σ_i ∂h1ηη/∂η1 · X1[i,k]   (chain rule)
        h1ηη, _, _ = _ls_hess(prob.kind1, prob.y1[i], η10[i] + u1, ψ1)
        h2ηη, _, _ = _ls_hess(prob.kind2, prob.y2[i], η20[i] + u2, ψ2)

        # ∂h1ηη/∂η1 (= tηηη_1 for axis 1) via ForwardDiff of hess
        t1ηηη = ForwardDiff.derivative(z -> begin
            h, _, _ = _ls_hess(prob.kind1, prob.y1[i], z, ψ1); h
        end, η10[i] + u1)
        t2ηηη = ForwardDiff.derivative(z -> begin
            h, _, _ = _ls_hess(prob.kind2, prob.y2[i], z, ψ2); h
        end, η20[i] + u2)

        for k in 1:p1
            grad[k] += 0.5 * t1ηηη * v11 * prob.X1[i, k]
        end
        for k in 1:p2
            grad[p1+k] += 0.5 * t2ηηη * v22 * prob.X2[i, k]
        end

        # ∂h/∂logd (dispersion derivatives): d/dlogd1 = d/dψ1 (since logd1 = ψ1)
        # ∂h1ηη/∂ψ1 via ForwardDiff
        if prob.has_disp1
            dh1_dψ1 = ForwardDiff.derivative(z -> begin
                h, _, _ = _ls_hess(prob.kind1, prob.y1[i], η10[i] + u1, z); h
            end, ψ1)
            grad[p1+p2+3+1] += 0.5 * dh1_dψ1 * v11
        end
        if prob.has_disp2
            dh2_dψ2 = ForwardDiff.derivative(z -> begin
                h, _, _ = _ls_hess(prob.kind2, prob.y2[i], η20[i] + u2, z); h
            end, ψ2)
            grad[p1+p2+3+Int(prob.has_disp1)+1] += 0.5 * dh2_dψ2 * v22
        end
    end

    # (B-lc) ½ tr(H⁻¹ ∂H/∂lc_k) for the P = kron(Q, Λ⁻¹) part.
    # tr(H⁻¹ ∂P/∂lc_k) = Σ_{(s,t)∈Q} Q[s,t] Σ_{a,b} Vsel[2t-1+a-1, 2s-1+b-1] · Mk[b,a]
    # where Mk = ∂Λ⁻¹/∂lc_k, and the 2×2 block indices are (a,b) in {1,2}.
    # Build Gst[b,a] = Σ_{s,t} Q[s,t] Vsel[2(t-1)+a, 2(s-1)+b] once, then contract per k.
    Gst = zeros(2, 2)
    qrows = rowvals(Q_cond); qvals = nonzeros(Q_cond)
    @inbounds for tcol in 1:G
        for idx in nzrange(Q_cond, tcol)
            s = qrows[idx]; q_val = qvals[idx]
            bs = 2(s-1); bt = 2(tcol-1)
            for a in 1:2, b in 1:2
                Gst[b, a] += q_val * Vsel[bt+a, bs+b]
            end
        end
    end
    # −½ logdet P derivative: logdetP = const − N logdet Λ  → −½ logdetP contributes
    # +½ G logdet Λ.  Its lc gradient: +½ G tr(Λ⁻¹ ∂Λ/∂lc_k).
    for k in 1:3
        dΛk = reshape(@view(dΛ[:, k]), 2, 2)
        Mk = -Λinv * dΛk * Λinv
        acc_tr = 0.0
        for a in 1:2, b in 1:2
            acc_tr += Gst[b, a] * Mk[b, a]
        end
        trLP = 0.0
        for a in 1:2, b in 1:2
            trLP += Λinv[a, b] * dΛk[b, a]
        end
        grad[p1+p2+k] += 0.5 * acc_tr + 0.5 * G * trLP
    end

    # ------------------------------------------------------------------
    # (C) Implicit adjoint: v_j = ½ tr(H⁻¹ ∂H/∂u_j), w = H⁻¹ v.
    # Then correction = −∇_θ[g(û,θ)·w] with û,w frozen.
    # ------------------------------------------------------------------

    nu = 2 * G
    v = zeros(nu)
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        v11 = Vsel[2t-1, 2t-1]; v22 = Vsel[2t, 2t]
        t1, t2 = _rb_third_u(prob.kind1, prob.kind2, prob.y1[i], prob.y2[i],
                              η10[i], η20[i], ψ1, ψ2, u1, u2)
        v[2t-1] += 0.5 * t1 * v11
        v[2t]   += 0.5 * t2 * v22
    end
    w = ch \ v

    # −∇_θ[g(û,θ)·w] with û, w frozen.
    # g(û,θ) = P(lc)·û + Σ_i [∂nll1/∂u1, ∂nll2/∂u2] (at frozen û).
    # The β / disp components contribute through the nll-scores; the lc component
    # contributes through the prior gradient P·û.

    # β1, β2, disp contribution: −w·∂g/∂β1_k = −Σ_i w[2t-1]·h1ηη·X1[i,k] etc.
    # (the gradient g wrt u depends on β through the η0 offsets; d(g_t)/d(β1_k) =
    # Σ_{i at t} h1ηη · X1[i,k] on axis-1 slots.)
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]
        u1 = u[2t-1]; u2 = u[2t]
        h1ηη, _, _ = _ls_hess(prob.kind1, prob.y1[i], η10[i] + u1, ψ1)
        h2ηη, _, _ = _ls_hess(prob.kind2, prob.y2[i], η20[i] + u2, ψ2)
        for k in 1:p1
            grad[k] -= w[2t-1] * h1ηη * prob.X1[i, k]
        end
        for k in 1:p2
            grad[p1+k] -= w[2t] * h2ηη * prob.X2[i, k]
        end
        if prob.has_disp1
            # ∂(g_u[2t-1])/∂ψ1 = ∂²nll1/∂η1∂ψ1 = hηψ1 (cross second derivative)
            _, hηψ1, _ = _ls_hess(prob.kind1, prob.y1[i], η10[i] + u1, ψ1)
            grad[p1+p2+3+1] -= w[2t-1] * hηψ1
        end
        if prob.has_disp2
            # ∂(g_u[2t])/∂ψ2 = ∂²nll2/∂η2∂ψ2 = hηψ2 (cross second derivative)
            _, hηψ2, _ = _ls_hess(prob.kind2, prob.y2[i], η20[i] + u2, ψ2)
            grad[p1+p2+3+Int(prob.has_disp1)+1] -= w[2t] * hηψ2
        end
    end

    # lc contribution to the implicit adjoint: −w·∂(P·û)/∂lc_k.
    # ∂(P·û)/∂lc_k = kron(Q, Mk)·û where Mk = ∂Λ⁻¹/∂lc_k.
    # So w'·kron(Q,Mk)·û = Σ_{s,t} Q[s,t] w_block(t)' Mk û_block(s).
    @inbounds for k in 1:3
        dΛk = reshape(@view(dΛ[:, k]), 2, 2)
        Mk = -Λinv * dΛk * Λinv
        acc = 0.0
        for tcol in 1:G
            for idx in nzrange(Q_cond, tcol)
                s = qrows[idx]; q_val = qvals[idx]
                u_s1 = u[2s-1]; u_s2 = u[2s]
                w_t1 = w[2tcol-1]; w_t2 = w[2tcol]
                Mu_s1 = Mk[1,1]*u_s1 + Mk[1,2]*u_s2
                Mu_s2 = Mk[2,1]*u_s1 + Mk[2,2]*u_s2
                acc += q_val * (w_t1*Mu_s1 + w_t2*Mu_s2)
            end
        end
        grad[p1+p2+k] -= acc
    end

    return grad
end

# ---------------------------------------------------------------------------
# Fit driver: LBFGS with the exact gradient, warm-started inner Newton.
# ---------------------------------------------------------------------------

"""
    fit_rich_bivar(prob, Q_cond; θ0, g_tol, iterations, n_newton) -> NamedTuple

Fit the bivariate non-Gaussian MR-PMM by maximising the iterated-Laplace
marginal log-likelihood over (β1, β2, log-Cholesky Λ, dispersion scalars).
Returns `(; β1, β2, Λ, logd1, logd2, rho12, loglik, converged, iterations, θ)`.
"""
function fit_rich_bivar(prob::RichBivarProblem, Q_cond::SparseMatrixCSC;
                        θ0 = nothing, g_tol::Float64 = 1e-4,
                        iterations::Int = 500, tol_inner::Float64 = 1e-9,
                        show_trace::Bool = false)
    if θ0 === nothing
        # warm start: OLS for β, identity Λ, zero dispersions
        p1 = size(prob.X1, 2); p2 = size(prob.X2, 2)
        β1_0 = prob.X1 \ log.(max.(prob.y1, 0.1))   # log-link default
        β2_0 = prob.X2 \ log.(max.(prob.y2, 0.1))
        Λ_0 = Matrix(0.3 * I(2))
        logd1_0 = 0.0; logd2_0 = 0.0
        θ0 = _rb_pack(prob, β1_0, β2_0, Λ_0, logd1_0, logd2_0)
    end

    u_cache = Ref{Union{Nothing,Vector{Float64}}}(nothing)

    fg! = function (F, G, θ)
        local nll, g
        try
            β1, β2, Λ, lc, logd1, logd2 = _rb_unpack(prob, θ)
            ψ1 = Float64(logd1); ψ2 = Float64(logd2)
            Λinv = _ls_inv2x2(Λ)
            P = prior_precision(Q_cond, Λinv)
            u_hat, ch, ok = _rb_inner_mode(prob, P, β1, β2, ψ1, ψ2;
                                           u0 = u_cache[], tol = tol_inner)
            if !ok
                return Inf
            end
            u_cache[] = u_hat
            jn = _rb_joint(prob, P, β1, β2, ψ1, ψ2, u_hat)
            logdetH = logdet(ch)
            chP = cholesky(Symmetric(P); check = false)
            (!issuccess(chP)) && return Inf
            nll = jn + 0.5 * logdetH - 0.5 * logdet(chP)
            if G !== nothing
                g = _rb_marginal_grad(prob, Q_cond, Vector{Float64}(θ); u0 = u_hat, tol = tol_inner)
                any(!isfinite, g) && return Inf
                copyto!(G, g ./ length(prob.leaf_node))
            end
        catch e
            (e isa DomainError || e isa LinearAlgebra.PosDefException ||
             e isa LinearAlgebra.SingularException) || rethrow(e)
            return Inf
        end
        return nll / length(prob.leaf_node)
    end

    od = Optim.NLSolversBase.only_fg!(fg!)
    res = Optim.optimize(od, θ0,
                         LBFGS(alphaguess = Optim.LineSearches.InitialStatic(scaled = true),
                               linesearch = Optim.LineSearches.BackTracking()),
                         Optim.Options(g_tol = g_tol, f_reltol = 1e-7, successive_f_tol = 3,
                                       iterations = iterations, show_trace = show_trace))
    θ̂ = Optim.minimizer(res)
    n_obs = length(prob.leaf_node)
    β1̂, β2̂, Λ̂, _, logd1̂, logd2̂ = _rb_unpack(prob, θ̂)
    sd̂ = sqrt.(diag(Λ̂))
    rho12 = Λ̂[1, 2] / (sd̂[1] * sd̂[2])
    return (;
        β1 = Vector{Float64}(β1̂), β2 = Vector{Float64}(β2̂),
        Λ = Λ̂, lc = cov_to_lc(Λ̂),
        logd1 = Float64(logd1̂), logd2 = Float64(logd2̂),
        rho12 = rho12,
        loglik = -Optim.minimum(res) * n_obs,
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
        θ = θ̂,
    )
end

# ---------------------------------------------------------------------------
# ρ12 profile CI.
# ρ12 is a function of Λ; the natural parameterisation is in lc = [lc1,lc2,lc3]
# where lc2 = L[2,1] (the off-diagonal element).  We profile over idx_lc2,
# the index of lc2 in the full packed θ.
# ---------------------------------------------------------------------------

"""
    rich_bivar_rho12(Λ) -> Float64

Cross-trait correlation implied by the 2×2 covariance Λ.
"""
function rich_bivar_rho12(Λ::AbstractMatrix)
    sd = sqrt.(diag(Λ))
    return Λ[1, 2] / (sd[1] * sd[2])
end

"""
    rich_bivar_profile_ci_rho12(prob, Q_cond, θ̂; level=0.95, nll_min=nothing, se=nothing)
          -> (lower_rho, upper_rho)

Profile-likelihood CI for ρ12, profiling over the off-diagonal lc entry (lc2,
the second element of the 3-vector lc in θ).  Returns ρ12 values (not lc values).
Boundary-aware: `±Inf` if no crossing or infeasible.
"""
function rich_bivar_profile_ci_rho12(prob::RichBivarProblem, Q_cond::SparseMatrixCSC,
                                     θ̂::AbstractVector;
                                     level::Real = 0.95, nll_min = nothing, se = nothing)
    p1 = size(prob.X1, 2); p2 = size(prob.X2, 2)
    idx = p1 + p2 + 2          # index of lc[2] (off-diagonal) in θ
    nmin = nll_min === nothing ? _rb_fit_nll(prob, Q_cond, θ̂) : nll_min
    thr = nmin + Distributions.quantile(Distributions.Chisq(1), level) / 2
    p = length(θ̂)
    free = [k for k in 1:p if k != idx]

    if se === nothing
        # Wald SE from FD curvature at θ̂
        h = 1e-4
        tp = copy(θ̂); tp[idx] += h
        tm = copy(θ̂); tm[idx] -= h
        f0 = nmin
        fp = _rb_fit_nll(prob, Q_cond, tp)
        fm = _rb_fit_nll(prob, Q_cond, tm)
        curv = (fp - 2f0 + fm) / h^2
        se = curv > 0 ? 1.0 / sqrt(curv) : abs(θ̂[idx]) + 1.0
    end
    z = Distributions.quantile(Distributions.Normal(), 1 - (1 - level) / 2)
    step0 = max(z * se, 1e-3)

    mwarm = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    lastsol = Ref{Union{Nothing,Vector{Float64}}}(nothing)

    function evalh(val)
        build_θ = (θf) -> begin
            θ = collect(float.(θ̂)); θ[free] .= θf; θ[idx] = val; θ
        end
        f(θf) = _rb_fit_nll(prob, Q_cond, build_θ(θf))
        function g!(gf, θf)
            gfull = _rb_marginal_grad(prob, Q_cond, build_θ(θf))
            gf .= gfull[free]
            return gf
        end
        init = lastsol[] === nothing ? float.(θ̂[free]) : lastsol[]
        res = Optim.optimize(f, g!, init,
                             Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking()),
                             Optim.Options(g_tol = 1e-6, iterations = 200))
        minval = Optim.minimum(res)
        xmin   = Optim.minimizer(res)
        ok = isfinite(minval) && minval < 1e17 && all(isfinite, xmin)
        ok || return (NaN, NaN, false)
        lastsol[] = xmin
        θ_full = build_θ(xmin)
        g = _rb_marginal_grad(prob, Q_cond, θ_full)
        slope = (length(g) == p && isfinite(g[idx])) ? g[idx] : NaN
        return (minval - thr, slope, true)
    end

    function _rb_profile_root(evh, x0; dir::Float64, init::Float64)
        tlo = 0.0; thi = init
        ghi = -1.0; shi = NaN; bracketed = false
        for _ in 1:40
            gap, slope, ok = evh(x0 + dir * thi)
            ok || return dir > 0 ? Inf : -Inf
            if gap > 0
                ghi = gap; shi = slope; bracketed = true; break
            end
            tlo = thi; thi *= 1.6
        end
        bracketed || return dir > 0 ? Inf : -Inf
        t = thi; gap = ghi; slope = shi
        for _ in 1:30
            abs(gap) < 1e-7 && break
            thi - tlo < 1e-8 && break
            gap > 0 ? (thi = t) : (tlo = t)
            sd2 = dir * slope
            tn = (isfinite(sd2) && sd2 > 0) ? t - gap / sd2 : (tlo + thi) / 2
            tnext = (tlo < tn < thi) ? tn : (tlo + thi) / 2
            g2, s2, ok2 = evh(x0 + dir * tnext)
            if !ok2
                thi = tnext; tnext = (tlo + thi) / 2
                g2, s2, ok2 = evh(x0 + dir * tnext)
                ok2 || break
            end
            t = tnext; gap = g2; slope = s2
        end
        return x0 + dir * t
    end

    lc2_lo = _rb_profile_root(evalh, θ̂[idx]; dir = -1.0, init = step0)
    lastsol[] = nothing; mwarm[] = nothing
    lc2_hi = _rb_profile_root(evalh, θ̂[idx]; dir = +1.0, init = step0)

    # Convert lc2 bounds to ρ12 bounds using Λ at those points.
    function lc2_to_rho(lc2_val)
        lc_full = [θ̂[p1+p2+1], lc2_val, θ̂[p1+p2+3]]
        Λ_v = _ls_lc_to_Λ(lc_full)
        sd = sqrt.(diag(Λ_v))
        return Λ_v[1, 2] / (sd[1] * sd[2])
    end

    lower_rho = isfinite(lc2_lo) ? lc2_to_rho(lc2_lo) : (lc2_lo < 0 ? -1.0 : 1.0)
    upper_rho = isfinite(lc2_hi) ? lc2_to_rho(lc2_hi) : (lc2_hi > 0 ? 1.0 : -1.0)

    return (lower = lower_rho, upper = upper_rho)
end

# ---------------------------------------------------------------------------
# Simulator for the bivariate MR-PMM (Poisson + Gamma canonical DGP).
# ---------------------------------------------------------------------------

"""
    simulate_rich_bivar(phy, β1, β2, Λ, logd1, logd2, kind1, kind2;
                        nrep, rng) -> (; y1, y2, X1, X2, species)

Simulate a bivariate MR-PMM on `phy`. The latent field is drawn from the
kron(Q_cond, Λ⁻¹) prior. Axis-1 response is from family `kind1` with
dispersion `exp(logd1)`; axis-2 from `kind2` with `exp(logd2)`.
Poisson ignores the dispersion.
"""
function simulate_rich_bivar(phy, β1::AbstractVector, β2::AbstractVector,
                              Λ::AbstractMatrix, logd1::Real, logd2::Real,
                              kind1, kind2;
                              nrep::Integer = 5, rng = Random.default_rng())
    Q_cond, leaf_pos, N = augmented_tree_precision(phy)
    P = prior_precision(Q_cond, inv(Λ))
    F = cholesky(Symmetric(P))
    u_aug = F.UP \ randn(rng, size(P, 1))   # u ~ N(0, P⁻¹)
    p = phy.n_leaves
    species = repeat(1:p, inner = nrep)
    n = length(species)
    X1 = hcat(ones(n), randn(rng, n))
    X2 = hcat(ones(n), randn(rng, n))
    y1 = Vector{Float64}(undef, n)
    y2 = Vector{Float64}(undef, n)
    ψ1 = Float64(logd1); ψ2 = Float64(logd2)
    @inbounds for i in 1:n
        t = leaf_pos[species[i]]
        u1 = u_aug[2t-1]; u2 = u_aug[2t]
        η1 = dot(X1[i, :], β1) + u1
        η2 = dot(X2[i, :], β2) + u2
        y1[i] = _rb_draw(kind1, η1, ψ1, rng)
        y2[i] = _rb_draw(kind2, η2, ψ2, rng)
    end
    return (; y1, y2, X1, X2, species)
end

# Draw one observation from a locscale family (mean-only axis; ψ = scalar disp).
function _rb_draw(::Val{:poisson}, η, ψ, rng)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    return Float64(rand(rng, Distributions.Poisson(μ)))
end
function _rb_draw(::Val{:gamma}, η, ψ, rng)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    α = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    return rand(rng, Distributions.Gamma(α, μ / α))
end
function _rb_draw(::Val{:nb2}, η, ψ, rng)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    r = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    p_nb = r / (r + μ)
    return Float64(rand(rng, Distributions.NegativeBinomial(r, p_nb)))
end
function _rb_draw(::Val{:lognormal}, η, ψ, rng)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    return exp(η + σ * randn(rng))
end

# ---------------------------------------------------------------------------
# Gaussian×Gaussian reduction helper.
# When both families are :lognormal (identity on log scale), the iterated-
# Laplace marginal should equal the conjugate coevo_marginal.  Alternatively,
# when both are Gaussian (normal), the _ls_nll / grad / hess for :gaussian are
# needed.  We implement a thin "pseudo-Gaussian" via :lognormal on raw responses
# (subtracting the log-Jacobian), but the cleaner reduction uses a dedicated
# :gaussian_mean_only kernel below that matches the conjugate Gaussian exactly.
#
# Gaussian leaf (mean-only, known σ_res):
#   nll = 0.5 * (y - η)^2 / σ² + 0.5 log(2π σ²)  (no ψ dependence)
# We parameterise ψ = log(σ_res) so exp(ψ) = σ, matching the coevo_marginal D.
# ---------------------------------------------------------------------------
"""
    _ls_nll(::Val{:gaussian_mean}, y, η, ψ) / _ls_grad / _ls_hess

Gaussian mean-only kernel for the reduction cross-check. ψ = log(σ_res) (scalar,
not a per-node latent). Matches coevo_marginal's per-obs (r' D⁻¹ r + logdet D)/2
exactly when the same σ_res is used.
"""
function _ls_nll(::Val{:gaussian_mean}, y, η, ψ)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    r = y - η
    return 0.5 * (r^2 / σ^2 + log(2π * σ^2))
end
function _ls_grad(::Val{:gaussian_mean}, y, η, ψ)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    r = y - η
    gη = -r / σ^2
    # gψ = chain: d/dψ [½ r² σ⁻² + ½ log(σ²)] = -r² σ⁻² + 1  (as d(log σ²)/dψ = 2)
    gψ = 1.0 - r^2 / σ^2    # = d/d(log σ)[0.5 r²/σ² + 0.5 log(2π σ²)]
    return gη, gψ
end
function _ls_hess(::Val{:gaussian_mean}, y, η, ψ)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    hηη = 1.0 / σ^2
    hηψ = 2.0 * (y - η) / σ^2      # ∂²nll/∂η∂ψ = -(d/dη(-r/σ²)·d(σ²)/dψ) ... chain
    hψψ = 2.0 * (y - η)^2 / σ^2   # ∂²nll/∂ψ² = 2r²/σ²
    return hηη, hηψ, hψψ
end
