# location_only.jl — CONJUGATE Gaussian phylogenetic mixed model (location-only).
#
# Promoted from src/experimental/location_only.jl (issue #12). This is the
# opt-in `algorithm = :em` path for the Gaussian phylo-MEAN model — a single
# structured random intercept on the mean μ with a CONSTANT residual scale σ.
# It is the same MLE as the default GLS/LBFGS structured-Gaussian fitter
# (`_fit_structured_gaussian`), reached by a closed-form conjugate EM with
# EXACT O(p) Takahashi traces (report/comparison-grid.md §4: ~3.1× faster than
# LBFGS at p=200/1000, previously measured — not re-measured here).
#
# Model:  y_i = X_i β + u_{s(i)} + ε_i
#         u  ~ N(0, σ²_phy · Σ_phy)   via the sparse augmented precision
#         ε  ~ N(0, σ² I)
#
# Augmented-state representation (Hadfield / sparse_phy.jl pattern):
#   Root-conditioned prior precision:  P = (1/σ²_phy) · Q_cond  (n_keep × n_keep, PD)
#   Leaf-observation map: S ∈ R^{n × n_keep}  (one entry per obs per kept node)
#
# The marginal p(y | β, σ²_phy, σ²) is CLOSED-FORM Gaussian:
#     y | β, θ  ~  N( X β,  V )    V = S P^{-1} S'  +  σ² I_n
#
# Woodbury on V^{-1}:
#     M    = P + (1/σ²) S'S         (n_keep × n_keep, sparse, PD)
#     V^{-1} z  = (z - S (M^{-1} (1/σ²) S' z)) / σ²
#     logdetV   = n log σ²  +  logdet M  −  logdet P
#
# EXACT O(p) TRACES via Takahashi selected inverse:
#     Tr(Q_cond M^{-1})  — needed for σ²_phy M-step
#     Tr(S M^{-1} S')    — needed for σ² M-step
# Both lie within the Takahashi pattern of M (same sparsity as Q_cond plus the
# leaf diagonal from S'S — but leaves ARE in Q_cond's pattern), so they are exact.
#
# Depends on `AugmentedPhy` / `sparse_phy.jl` and `takahashi_selinv` (already
# loaded by the verified core engine include chain in DRM.jl — do NOT re-include).

using LinearAlgebra, SparseArrays, Statistics

# ─────────────────────────────────────────────────────────────────────────────
# Problem struct (location-only)
# ─────────────────────────────────────────────────────────────────────────────

struct LocOnlyProblem
    phy::AugmentedPhy{Float64}
    n_keep::Int                           # 2p-2 root-conditioned nodes
    p::Int                                # species (leaves)
    n::Int                                # total observations
    Q_cond::SparseMatrixCSC{Float64,Int}  # (n_keep × n_keep) root-conditioned Q
    leaf_pos::Vector{Int}                 # leaf k -> index in kept nodes (1:n_keep)
    species::Vector{Int}                  # data row i -> species index (1:p)
    y::Vector{Float64}                    # responses (n,)
    X::Matrix{Float64}                    # design matrix (n × k)
    k::Int                                # number of fixed effects
    S::SparseMatrixCSC{Float64,Int}       # observation-node selection (n × n_keep)
    STS_diag::Vector{Float64}             # diagonal of S'S (n_keep,), sparse = at leaf_pos
end

function make_loc_problem(phy::AugmentedPhy, y, X; species=1:phy.n_leaves)
    n_total = phy.n_total
    keep    = setdiff(1:n_total, [phy.root_index])
    Q_cond  = phy.Q_topology[keep, keep]
    pos     = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [pos[phy.leaf_indices[k]] for k in 1:phy.n_leaves]
    n  = length(y)
    sp = collect(Int, species)
    k  = size(X, 2)

    # Build S (n × n_keep): obs i → node leaf_pos[species[i]]
    SI = collect(1:n)
    SJ = [leaf_pos[sp[i]] for i in 1:n]
    SV = ones(n)
    S  = sparse(SI, SJ, SV, n, length(keep))

    # STS diagonal (= count of obs per kept-node position)
    STS_d = zeros(length(keep))
    for i in 1:n
        STS_d[leaf_pos[sp[i]]] += 1.0
    end

    return LocOnlyProblem(phy, length(keep), phy.n_leaves, n,
                         Q_cond, leaf_pos, sp,
                         Float64.(y), Float64.(X), k, S, STS_d)
end

# ─────────────────────────────────────────────────────────────────────────────
# Core Woodbury helpers — all O(p) via sparse Cholesky
# ─────────────────────────────────────────────────────────────────────────────

"""
Build M = P + (1/σ²) S'S.  Return (P, M, chM, chP).
chP = chol(P + ridge) for logdet P; chM = chol(M) for the Woodbury solves.
"""
function build_M(prob::LocOnlyProblem, σ²_phy::Float64, σ²::Float64)
    n_keep = prob.n_keep
    P = (1/σ²_phy) * prob.Q_cond
    M = copy(P)
    @inbounds for j in 1:n_keep
        if prob.STS_diag[j] > 0
            M[j, j] += prob.STS_diag[j] / σ²
        end
    end
    chM = cholesky(Symmetric(M); check=false)
    issuccess(chM) || (M += 1e-8*I; chM = cholesky(Symmetric(M)))
    chP = cholesky(Symmetric(P + 1e-10*I); check=false)
    issuccess(chP) || (chP = cholesky(Symmetric(P + 1e-6*I)))
    return P, M, chM, chP
end

" V^{-1} z via Woodbury: (z - S (M^{-1} (1/σ²) S' z)) / σ² "
@inline function Vinv_mul(prob::LocOnlyProblem, chM, σ²::Float64, z)
    STz = prob.S' * z
    return (z .- prob.S * (chM \ (STz / σ²))) / σ²
end

" logdet V = n log σ² + logdet M − logdet P "
@inline function logdetV_val(prob::LocOnlyProblem, σ²::Float64, chM, chP)
    return prob.n * log(σ²) + logdet(chM) - logdet(chP)
end

# ─────────────────────────────────────────────────────────────────────────────
# Marginal log-likelihood
# ─────────────────────────────────────────────────────────────────────────────

function marginal_loglik(prob::LocOnlyProblem, β::AbstractVector,
                         σ²_phy::Float64, σ²::Float64)
    (σ²_phy <= 0 || σ² <= 0) && return -Inf
    P, M, chM, chP = build_M(prob, σ²_phy, σ²)
    e    = prob.y .- prob.X * β
    Ve   = Vinv_mul(prob, chM, σ², e)
    quad = dot(e, Ve)
    ldV  = logdetV_val(prob, σ², chM, chP)
    return -0.5 * (prob.n * log(2π) + ldV + quad)
end

# ─────────────────────────────────────────────────────────────────────────────
# EXACT TAKAHASHI TRACES for the EM M-step
#
# Tr(Q_cond M^{-1}): sum Q_cond[i,j] × M^{-1}[i,j] over the Q_cond pattern.
# Tr(S M^{-1} S') = Σ_j STS_diag[j] × M^{-1}[j, j]  (diagonal always in pattern).
# ─────────────────────────────────────────────────────────────────────────────

"""
EXACT Tr(Q_cond M^{-1}) and Tr(S M^{-1} S') via Takahashi selected inverse.
Returns (tr_QM, tr_SMS).
"""
function exact_traces(prob::LocOnlyProblem, chM)
    V_sel = takahashi_selinv(chM)

    rows = rowvals(prob.Q_cond)
    vals = nonzeros(prob.Q_cond)
    tr_QM = 0.0
    @inbounds for tcol in 1:prob.n_keep
        for idx in nzrange(prob.Q_cond, tcol)
            s = rows[idx]; q = vals[idx]
            tr_QM += q * V_sel[s, tcol]
        end
    end

    tr_SMS = 0.0
    @inbounds for j in 1:prob.n_keep
        if prob.STS_diag[j] > 0
            tr_SMS += prob.STS_diag[j] * V_sel[j, j]
        end
    end

    return tr_QM, tr_SMS
end

# ─────────────────────────────────────────────────────────────────────────────
# EM FITTER — closed-form E-step + M-step with exact Takahashi traces
#
# E-step: μ_post = M^{-1} (1/σ²) S' (y - Xβ)  [posterior mean of u]
# M-step (β):      GLS = (X' V^{-1} X)^{-1} X' V^{-1} y
# M-step (σ²_phy): [μ' Q_cond μ + Tr(Q_cond M^{-1})] / n_keep
# M-step (σ²):     [||y - Xβ - Sμ||² + Tr(S M^{-1} S')] / n
# ─────────────────────────────────────────────────────────────────────────────

function em_fit(prob::LocOnlyProblem;
                β0=nothing, σ²_phy0=0.5, σ²0=0.5,
                max_iter=200, reltol=1e-8)
    n = prob.n; k = prob.k; n_keep = prob.n_keep

    β      = β0 === nothing ? zeros(k) : copy(Float64.(β0))
    σ²_phy = σ²_phy0
    σ²     = σ²0

    ll_prev = -Inf
    iter    = 0

    for it in 1:max_iter
        iter = it
        P, M, chM, chP = build_M(prob, σ²_phy, σ²)

        # E-step: posterior mean
        e      = prob.y .- prob.X * β
        μ_post = chM \ (prob.S' * e / σ²)

        # Exact traces (Takahashi)
        tr_QM, tr_SMS = exact_traces(prob, chM)

        # M-step (β): GLS
        VX  = Vinv_mul(prob, chM, σ², prob.X)
        Vy  = Vinv_mul(prob, chM, σ², prob.y)
        β_new = (prob.X' * VX) \ (prob.X' * Vy)

        # M-step (σ²_phy): closed form
        qquad = dot(μ_post, prob.Q_cond * μ_post)
        σ²_phy_new = max(1e-8, (qquad + tr_QM) / n_keep)

        # M-step (σ²): closed form
        e2 = prob.y .- prob.X * β_new .- prob.S * μ_post
        σ²_new = max(1e-8, (dot(e2, e2) + tr_SMS) / n)

        β      = β_new
        σ²_phy = σ²_phy_new
        σ²     = σ²_new

        ll = marginal_loglik(prob, β, σ²_phy, σ²)
        if abs(ll - ll_prev) < reltol * (1 + abs(ll_prev))
            break
        end
        ll_prev = ll
    end

    ll_final = marginal_loglik(prob, β, σ²_phy, σ²)
    return (β=β, σ²_phy=σ²_phy, σ²=σ², loglik=ll_final, iterations=iter)
end

# ─────────────────────────────────────────────────────────────────────────────
# Front-end adapter — build a DrmFit matching the structured-Gaussian shape.
#
# This is the `algorithm = :em` path for the Gaussian phylo-MEAN cell. It fits
# the SAME marginal as `_fit_structured_gaussian` (single structured mean RE,
# constant σ) but via conjugate EM. The structured-Gaussian fit parametrizes the
# phylo random effect as σ_s² · K with K the leaf CORRELATION matrix; the EM uses
# σ²_phy · Σ_phy with Σ_phy the (root-conditioned) Brownian covariance whose
# diagonal is not 1. The two therefore agree on β, the residual σ, and the
# marginal logLik, but their phylo-variance parameters live on different scales —
# so `re_sd` here reports the EM's σ_phy (documented), and the correctness anchor
# is logLik + β + residual σ.
#
# EM does not produce a coefficient vcov (the M-steps are closed-form, no outer
# Hessian); like other boundary cases we store NaNs in the vcov (documented).
# ─────────────────────────────────────────────────────────────────────────────

function _fit_structured_gaussian_em(fam::Gaussian, y, Xμ, Xσ, gidx, G, phy::AugmentedPhy,
                                     nmμ, nmσ, grp, g_tol)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    pσ == 1 || error("algorithm = :em supports a CONSTANT residual scale only " *
        "(`sigma ~ 1`); got a $(pσ)-column `sigma` design")
    G == phy.n_leaves ||
        error("algorithm = :em: the number of `$grp` levels ($G) must equal the tree's " *
              "leaf count ($(phy.n_leaves))")
    n = length(y)

    prob = make_loc_problem(phy, y, Xμ; species = gidx)

    # Conjugate-EM init mirrors the structured fitter's OLS-residual heuristic.
    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    s0 = std(res0) + eps()
    r = em_fit(prob; β0 = βμ0, σ²_phy0 = (s0/2)^2, σ²0 = s0^2,
               max_iter = 500, reltol = max(1e-12, g_tol^2))

    # θ matches the structured shape: [βμ; log σ (constant); log σ_phy].
    # σ here is the residual SD √σ²; σ_phy is √σ²_phy (the EM's phylo SD).
    θ̂ = vcat(r.β, log(sqrt(r.σ²)), log(sqrt(r.σ²_phy)))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names  = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    # EM yields no coefficient vcov → NaNs (documented), as for other boundary cases.
    V = fill(NaN, length(θ̂), length(θ̂))
    means  = Dict(:mu => Xμ * r.β)
    obs    = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => fill(sqrt(r.σ²), n))
    converged = r.iterations < 500
    return DrmFit(fam, blocks, names, θ̂, V, r.loglik, n, converged, means, obs, scales)
end
