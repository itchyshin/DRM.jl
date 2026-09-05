# locscale_inner.jl — q=2 augmented-state inner solver for the non-Gaussian
# phylogenetic LOCATION–SCALE model (#202).
#
# The canonical location-scale fitting routes use this solver. It builds on the
# two-axis kernels
# (`locscale_kernels.jl`). The latent state is two effects per group g — a
# mean-axis effect aᵍ_μ and a scale-axis effect aᵍ_ψ — laid out group-major:
#
#   a[2g-1] = aᵍ_μ ,  a[2g] = aᵍ_ψ ,   length 2G.
#
# Per observation i in group g(i):  η_i = η0_i + a[2g-1],  ψ_i = ψ0_i + a[2g],
# where η0 = Xβ and ψ0 = Zγ are the fixed-effect parts (passed in). The latent
# prior is  a ~ N(0, P⁻¹),  P = kron(Q, Λ⁻¹)  with Λ the 2×2 group-level
# covariance (mean/scale). For an i.i.d. grouping Q = I_G; for a tree Q is the
# root-conditioned phylogenetic precision (reuses `prior_precision`).
#
# The inner problem minimises the joint
#   jn(a) = Σ_i nllᵢ(η_i, ψ_i) + ½ aᵀ P a
# whose Hessian is P plus a block-diagonal data part (one 2×2 block per group).
# `test/test_locscale_inner.jl` gates the joint gradient/Hessian against
# ForwardDiff and checks the mode-finder reaches a stationary point.

using LinearAlgebra: Symmetric, cholesky, issuccess, norm, dot, I
using SparseArrays: sparse, SparseMatrixCSC, nonzeros, findnz

# 2×2 log-Cholesky parameterisation of the group-level covariance Λ.
# v = [log L₁₁, L₂₁, log L₂₂];  Λ = L Lᵀ  with L lower-triangular, +ve diagonal.
function _ls_lc_to_Λ(v)
    L11 = exp(v[1]); L21 = v[2]; L22 = exp(v[3])
    a = L11^2
    b = L11 * L21
    d = L21^2 + L22^2
    return [a b; b d]
end

function _ls_Λ_to_lc(Λ)
    L = cholesky(Symmetric(Λ)).L
    return [log(L[1, 1]), L[2, 1], log(L[2, 2])]
end

# Explicit 2×2 inverse. Unlike `inv(::Matrix)` (which calls `lu` and THROWS a
# SingularException on a zero pivot), this yields Inf/NaN when Λ degenerates —
# so an optimiser that transiently pushes λ to an extreme (Λ ≈ singular) sees a
# non-finite marginal and backtracks instead of crashing. Equals `inv(Λ)` for
# any non-singular 2×2.
function _ls_inv2x2(M)
    a = M[1, 1]; b = M[1, 2]; c = M[2, 1]; d = M[2, 2]
    det = a * d - b * c
    return [d -b; -c a] ./ det
end

# ---------------------------------------------------------------------------
# Latent loadings (Z_lat generalisation, cluster 1 / #202).
#
# Each of the q=2 latent axes per group g (a[2g-1], a[2g]) feeds the mean
# predictor η and/or the scale predictor ψ via a per-OBSERVATION loading row:
#
#   η_i = η0_i + Zη[i,1]·a[2g-1] + Zη[i,2]·a[2g]   (= η0_i + zη_i · a_g)
#   ψ_i = ψ0_i + Zψ[i,1]·a[2g-1] + Zψ[i,2]·a[2g]   (= ψ0_i + zψ_i · a_g)
#
# `Zη`/`Zψ` are n×2. The original location–scale model is the canonical loading
#   Zη = [1 0]  (axis-1 → mean),   Zψ = [0 1]  (axis-2 → scale)
# for every row; the correlated random-slope `(1 + x | g)` promotion is
#   Zη = [1 xᵢ] (both axes → mean), Zψ = [0 0]  (scale fixed-only);
# the independent slope `(0 + x | g)` is the q=1 special case carried here as
#   Zη = [xᵢ 0], Zψ = [0 0] with Λ a 2×2 whose second axis is pinned (variance→0).
# All three reduce the per-group data block to Σ_i (hηη·zη zηᵀ + hηψ·(zη zψᵀ+
# zψ zηᵀ) + hψψ·zψ zψᵀ); the sparse kron prior P and the q=2 layout are
# unchanged. Helpers below build the canonical loadings so existing callers stay
# byte-identical.
_ls_canonical_Zeta(n) = (z = zeros(n, 2); @views z[:, 1] .= 1.0; z)   # [1 0]
_ls_canonical_Zpsi(n) = (z = zeros(n, 2); @views z[:, 2] .= 1.0; z)   # [0 1]

# Joint negative log-likelihood at latent a (general loadings Zη, Zψ).
function _ls_joint(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    s = zero(eltype(a))
    @inbounds for i in eachindex(y)
        g = gidx[i]
        a1 = a[2g-1]; a2 = a[2g]
        ηi = η0[i] + Zη[i, 1] * a1 + Zη[i, 2] * a2
        ψi = ψ0[i] + Zψ[i, 1] * a1 + Zψ[i, 2] * a2
        s += _ls_nll(kind, y[i], ηi, ψi)
    end
    return s + 0.5 * dot(a, P * a)
end

# Gradient of the joint in a (length 2G), general loadings.
function _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    grad = Vector{eltype(a)}(undef, length(a))
    Pa = P * a
    @inbounds for k in eachindex(grad)
        grad[k] = Pa[k]
    end
    @inbounds for i in eachindex(y)
        g = gidx[i]
        a1 = a[2g-1]; a2 = a[2g]
        ηi = η0[i] + Zη[i, 1] * a1 + Zη[i, 2] * a2
        ψi = ψ0[i] + Zψ[i, 1] * a1 + Zψ[i, 2] * a2
        gη, gψ = _ls_grad(kind, y[i], ηi, ψi)
        grad[2g-1] += gη * Zη[i, 1] + gψ * Zψ[i, 1]
        grad[2g]   += gη * Zη[i, 2] + gψ * Zψ[i, 2]
    end
    return grad
end

# Hessian of the joint: P + block-diagonal data part (a 2×2 block per group),
# general loadings. Per obs the block accrues hηη·zη zηᵀ + hηψ·(zη zψᵀ+zψ zηᵀ)
# + hψψ·zψ zψᵀ; the canonical loadings recover the (ηη, ηψ, ψψ) layout.
function _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
    rows = Int[]; cols = Int[]; vals = Float64[]
    b11 = zeros(G); b12 = zeros(G); b22 = zeros(G)
    @inbounds for i in eachindex(y)
        g = gidx[i]
        a1 = a[2g-1]; a2 = a[2g]
        ηi = η0[i] + Zη[i, 1] * a1 + Zη[i, 2] * a2
        ψi = ψ0[i] + Zψ[i, 1] * a1 + Zψ[i, 2] * a2
        hηη, hηψ, hψψ = _ls_hess(kind, y[i], ηi, ψi)
        z1 = Zη[i, 1]; z2 = Zη[i, 2]; w1 = Zψ[i, 1]; w2 = Zψ[i, 2]
        b11[g] += hηη * z1 * z1 + 2hηψ * z1 * w1 + hψψ * w1 * w1
        b12[g] += hηη * z1 * z2 + hηψ * (z1 * w2 + w1 * z2) + hψψ * w1 * w2
        b22[g] += hηη * z2 * z2 + 2hηψ * z2 * w2 + hψψ * w2 * w2
    end
    @inbounds for g in 1:G
        mu = 2g - 1; sc = 2g
        push!(rows, mu); push!(cols, mu); push!(vals, b11[g])
        push!(rows, mu); push!(cols, sc); push!(vals, b12[g])
        push!(rows, sc); push!(cols, mu); push!(vals, b12[g])
        push!(rows, sc); push!(cols, sc); push!(vals, b22[g])
    end
    D = sparse(rows, cols, vals, 2G, 2G)
    return P + D
end

# Clean Hessian factor at `a` (λ = 0) — used for the marginal's logdet term.
_ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) =
    cholesky(Symmetric(_ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)); check = false)

# --- canonical-loading wrappers (byte-identical to the original location–scale
# model): axis-1 → mean, axis-2 → scale. Existing callers reach these. ---
_ls_joint(kind, y, η0, ψ0, gidx, a, P) =
    _ls_joint(kind, y, η0, ψ0, gidx, a, P,
              _ls_canonical_Zeta(length(y)), _ls_canonical_Zpsi(length(y)))
_ls_joint_grad(kind, y, η0, ψ0, gidx, a, P) =
    _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P,
                   _ls_canonical_Zeta(length(y)), _ls_canonical_Zpsi(length(y)))
_ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P) =
    _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P,
                   _ls_canonical_Zeta(length(y)), _ls_canonical_Zpsi(length(y)))
_ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P) =
    _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P,
                  _ls_canonical_Zeta(length(y)), _ls_canonical_Zpsi(length(y)))

# Inner mode: Levenberg–Marquardt-damped Newton with a backtracking line search
# on jn(a). The observed two-axis Hessian can go indefinite far from the mode
# (the scale axis is non-convex), so when the Cholesky fails or a step is
# rejected we ridge H by λI and retry with growing λ — the robustness lever the
# q=4 engine also relies on. At convergence we return the clean (λ=0) Hessian
# factor so the Laplace marginal logdet is exact.
_ls_allfinite(H::SparseMatrixCSC) = all(isfinite, nonzeros(H))
_ls_allfinite(H) = all(isfinite, H)

function _ls_inner_certificate(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, tol)
    all(isfinite, a) || return nothing, false
    H = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
    _ls_allfinite(H) || return nothing, false
    ch = cholesky(Symmetric(H); check = false)
    grad = _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    all(isfinite, grad) || return ch, false
    anorm = norm(a)
    gnorm = norm(grad)
    bound = tol * (1 + anorm)
    (isfinite(anorm) && isfinite(gnorm) && isfinite(bound)) || return ch, false
    stationary = gnorm <= bound
    return ch, stationary && issuccess(ch)
end

# A Newton step can lower the mathematical joint objective while its two nearby
# Float64 evaluations differ by a few ULPs in the opposite direction. This
# narrow terminal polish is intentionally separate from normal line-search
# descent: it admits only a full, undamped, representably changed local step
# whose fresh gradient already satisfies the ordinary certificate.
function _ls_inner_rounding_polish(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ,
                                   a, grad, step, f0, trial, ft, tol)
    all(isfinite, trial) && isfinite(f0) && isfinite(ft) || return nothing, false
    any(trial .!= a) || return nothing, false
    anorm = norm(a)
    displacement = norm(trial .- a)
    local_bound = sqrt(eps(Float64)) * (1 + anorm)
    (isfinite(anorm) && isfinite(displacement) && isfinite(local_bound) &&
     0 < displacement <= local_bound) || return nothing, false
    predicted_descent = dot(grad, step)
    isfinite(predicted_descent) && predicted_descent > 0 || return nothing, false
    increase = ft - f0
    allowance = 4 * max(eps(abs(f0)), eps(abs(ft)))
    (isfinite(increase) && isfinite(allowance) && increase > 0) || return nothing, false
    trial_grad = _ls_joint_grad(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)
    all(isfinite, trial_grad) || return nothing, false
    gnorm = norm(grad)
    trial_gnorm = norm(trial_grad)
    trial_bound = tol * (1 + norm(trial))
    (isfinite(gnorm) && isfinite(trial_gnorm) && isfinite(trial_bound) &&
     trial_gnorm < gnorm && trial_gnorm <= trial_bound) || return nothing, false
    ch, certified = _ls_inner_certificate(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ,
                                           trial, tol)
    certified || return nothing, false
    increase <= allowance && return ch, true

    # This is deliberately not a descent proof: raw objective subtraction has
    # already proved unreliable beyond the fast four-ULP path above.  Eligible
    # kernels may supply a finite estimated error for the same smooth
    # Taylor identity; every geometric and stationarity guard remains required.
    estimated = _ls_inner_estimated_change(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ,
                                            a, trial)
    estimated !== nothing && estimated.margin < 0 && return ch, true
    return nothing, false
end

# Fixed increasing-order Gauss--Legendre rules on [0, 1].  They are tuples so
# every invocation has only thread-private scalar accumulators.
const _LS_GL2 = ((0.21132486540518713, 0.5),
                 (0.7886751345948129, 0.5))
const _LS_GL4 = ((0.06943184420297371, 0.17392742256872693),
                 (0.33000947820757187, 0.32607257743127307),
                 (0.6699905217924281, 0.32607257743127307),
                 (0.9305681557970262, 0.17392742256872693))
const _LS_GL8 = ((0.019855071751231856, 0.05061426814518815),
                 (0.10166676129318664, 0.11119051722668726),
                 (0.2372337950418355, 0.15685332293894365),
                 (0.4082826787521751, 0.181341891689181),
                 (0.5917173212478249, 0.181341891689181),
                 (0.7627662049581645, 0.15685332293894365),
                 (0.8983332387068134, 0.11119051722668726),
                 (0.9801449282487682, 0.05061426814518815))

@inline function _ls_neumaier_add(sum_, correction, x)
    total = sum_ + x
    correction += abs(sum_) >= abs(x) ? (sum_ - total) + x : (x - total) + sum_
    return total, correction
end

_ls_inner_estimated_family(::Val{:nb2}) = true
_ls_inner_estimated_family(::Val{:gamma}) = true
_ls_inner_estimated_family(_) = false

function _ls_inner_gradient_envelope(::Val{:gamma}, y, η, ψ)
    μ = exp(η)
    α = exp(ψ)
    t = y / μ
    Gη = abs(α) + abs(α * t)
    Gψ = abs(α) * (abs(log(α)) + 1 + abs(digamma(α)) + abs(log(y)) +
                    abs(log(μ)) + abs(t))
    all(isfinite, (Gη, Gψ)) || return nothing
    return Gη, Gψ
end

function _ls_inner_gradient_envelope(::Val{:nb2}, y, η, ψ)
    μ = exp(η)
    r = exp(-2 * ψ)
    den = r + μ
    Gη = abs((y + r) * μ / den) + abs(y)
    Gψ = 2 * abs(r) * (abs(digamma(y + r)) + abs(digamma(r)) + abs(log(r)) +
                         1 + abs(log(den)) + abs((y + r) / den))
    all(isfinite, (Gη, Gψ)) || return nothing
    return Gη, Gψ
end
_ls_inner_gradient_envelope(_, y, η, ψ) = nothing

function _ls_inner_smooth_endpoints(kind, η0, ψ0, gidx, a, trial, Zη, Zψ)
    kind isa Val{:nb2} || kind isa Val{:gamma} || return false
    for state in (a, trial), i in eachindex(gidx)
        g = gidx[i]
        η = η0[i] + Zη[i, 1] * state[2g-1] + Zη[i, 2] * state[2g]
        ψ = ψ0[i] + Zψ[i, 1] * state[2g-1] + Zψ[i, 2] * state[2g]
        (isfinite(η) && isfinite(ψ) && -LS_CLAMP < η < LS_CLAMP) || return false
        if kind isa Val{:nb2}
            -LS_CLAMP < -2ψ < LS_CLAMP || return false
        else
            -LS_CLAMP < ψ < LS_CLAMP || return false
        end
    end
    return true
end

function _ls_inner_prior_components(P::SparseMatrixCSC, a, d)
    rows, cols, vals = findnz(P)
    directional = directional_scale = quadratic = quadratic_scale = 0.0
    dc = qc = 0.0
    @inbounds for k in eachindex(vals)
        i, j, p = rows[k], cols[k], vals[k]
        x = d[i] * p * a[j]
        q = 0.5 * d[i] * p * d[j]
        (isfinite(x) && isfinite(q)) || return nothing
        directional, dc = _ls_neumaier_add(directional, dc, x)
        quadratic, qc = _ls_neumaier_add(quadratic, qc, q)
        directional_scale += abs(x)
        quadratic_scale += abs(q)
    end
    all(isfinite, (directional, dc, quadratic, qc, directional_scale, quadratic_scale)) ||
        return nothing
    return directional + dc, quadratic + qc, directional_scale, quadratic_scale
end

function _ls_inner_prior_components(P, a, d)
    directional = directional_scale = quadratic = quadratic_scale = 0.0
    dc = qc = 0.0
    @inbounds for j in axes(P, 2), i in axes(P, 1)
        x = d[i] * P[i, j] * a[j]
        q = 0.5 * d[i] * P[i, j] * d[j]
        (isfinite(x) && isfinite(q)) || return nothing
        directional, dc = _ls_neumaier_add(directional, dc, x)
        quadratic, qc = _ls_neumaier_add(quadratic, qc, q)
        directional_scale += abs(x)
        quadratic_scale += abs(q)
    end
    all(isfinite, (directional, dc, quadratic, qc, directional_scale, quadratic_scale)) ||
        return nothing
    return directional + dc, quadratic + qc, directional_scale, quadratic_scale
end

function _ls_inner_data_direction(kind, y, η0, ψ0, gidx, a, d, Zη, Zψ)
    sum_ = correction = scale = 0.0
    @inbounds for i in eachindex(y)
        g = gidx[i]
        u, v = 2g - 1, 2g
        δη = Zη[i, 1] * d[u] + Zη[i, 2] * d[v]
        δψ = Zψ[i, 1] * d[u] + Zψ[i, 2] * d[v]
        η = η0[i] + Zη[i, 1] * a[u] + Zη[i, 2] * a[v]
        ψ = ψ0[i] + Zψ[i, 1] * a[u] + Zψ[i, 2] * a[v]
        bη = abs(η0[i]) + abs(Zη[i, 1] * a[u]) + abs(Zη[i, 2] * a[v])
        bψ = abs(ψ0[i]) + abs(Zψ[i, 1] * a[u]) + abs(Zψ[i, 2] * a[v])
        rη = abs(Zη[i, 1] * d[u]) + abs(Zη[i, 2] * d[v])
        rψ = abs(Zψ[i, 1] * d[u]) + abs(Zψ[i, 2] * d[v])
        gη, gψ = _ls_grad(kind, y[i], η, ψ)
        envelope = _ls_inner_gradient_envelope(kind, y[i], η, ψ)
        envelope === nothing && return nothing
        Gη, Gψ = envelope
        hηη, hηψ, hψψ = _ls_hess(kind, y[i], η, ψ)
        xη, xψ = δη * gη, δψ * gψ
        predictor_scale = rη * (abs(hηη) * bη + abs(hηψ) * bψ) +
                          rψ * (abs(hηψ) * bη + abs(hψψ) * bψ)
        gradient_scale = rη * Gη + rψ * Gψ
        (isfinite(δη) && isfinite(δψ) && isfinite(xη) && isfinite(xψ) &&
         isfinite(bη) && isfinite(bψ) && isfinite(rη) && isfinite(rψ) &&
         isfinite(gradient_scale) && isfinite(predictor_scale)) || return nothing
        sum_, correction = _ls_neumaier_add(sum_, correction, xη)
        sum_, correction = _ls_neumaier_add(sum_, correction, xψ)
        scale += abs(xη) + abs(xψ) + gradient_scale + predictor_scale
    end
    all(isfinite, (sum_, correction, scale)) || return nothing
    return sum_ + correction, scale
end

function _ls_inner_data_quadrature(kind, y, η0, ψ0, gidx, a, d, Zη, Zψ, nodes)
    sum_ = correction = scale = 0.0
    @inbounds for (t, w) in nodes, i in eachindex(y)
        g = gidx[i]
        u, v = 2g - 1, 2g
        δη = Zη[i, 1] * d[u] + Zη[i, 2] * d[v]
        δψ = Zψ[i, 1] * d[u] + Zψ[i, 2] * d[v]
        η = η0[i] + Zη[i, 1] * (a[u] + t * d[u]) + Zη[i, 2] * (a[v] + t * d[v])
        ψ = ψ0[i] + Zψ[i, 1] * (a[u] + t * d[u]) + Zψ[i, 2] * (a[v] + t * d[v])
        hηη, hηψ, hψψ = _ls_hess(kind, y[i], η, ψ)
        weight = w * (1 - t)
        qη = weight * hηη * δη * δη
        qηψ = weight * 2 * hηψ * δη * δψ
        qψ = weight * hψψ * δψ * δψ
        (isfinite(weight) && isfinite(qη) && isfinite(qηψ) && isfinite(qψ)) ||
            return nothing
        sum_, correction = _ls_neumaier_add(sum_, correction, qη)
        sum_, correction = _ls_neumaier_add(sum_, correction, qηψ)
        sum_, correction = _ls_neumaier_add(sum_, correction, qψ)
        scale += abs(qη) + abs(qηψ) + abs(qψ)
    end
    all(isfinite, (sum_, correction, scale)) || return nothing
    return sum_ + correction, scale
end

"""
    _ls_inner_estimated_change(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, trial)

Estimate the local joint-objective change for an otherwise certified Newton
trial when direct `Float64` subtraction is unreliable.  This is a guarded
numerical estimate, not a proof of descent: unsupported families, clamp-boundary
segments, and non-finite arithmetic return `nothing`.  `margin = Q8 + E` must
be negative before the caller may use the estimate.
"""
function _ls_inner_estimated_change(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, trial)
    _ls_inner_estimated_family(kind) || return nothing
    (all(isfinite, a) && all(isfinite, trial) && _ls_allfinite(P)) || return nothing
    _ls_inner_smooth_endpoints(kind, η0, ψ0, gidx, a, trial, Zη, Zψ) || return nothing
    d = trial .- a
    any(d .!= 0) || return nothing
    prior = _ls_inner_prior_components(P, a, d)
    direction = _ls_inner_data_direction(kind, y, η0, ψ0, gidx, a, d, Zη, Zψ)
    (prior === nothing || direction === nothing) && return nothing
    _, prior_quadratic, prior_direction_scale, prior_quadratic_scale = prior
    _, data_direction_scale = direction
    # Keep the signed first-order term in the engine's established coordinate
    # order: the smooth identity is g(a)'d.  The decomposed contractions below
    # feed only S, where their pre-cancellation magnitudes are required.
    gradient = _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    all(isfinite, gradient) || return nothing
    directional = dot(gradient, d)
    directional_scale = prior_direction_scale + data_direction_scale
    (isfinite(directional) && isfinite(directional_scale)) || return nothing
    q2data = _ls_inner_data_quadrature(kind, y, η0, ψ0, gidx, a, d, Zη, Zψ, _LS_GL2)
    q4data = _ls_inner_data_quadrature(kind, y, η0, ψ0, gidx, a, d, Zη, Zψ, _LS_GL4)
    q8data = _ls_inner_data_quadrature(kind, y, η0, ψ0, gidx, a, d, Zη, Zψ, _LS_GL8)
    (q2data === nothing || q4data === nothing || q8data === nothing) && return nothing
    q2, q2scale = q2data; q4, q4scale = q4data; q8, q8scale = q8data
    Q2 = directional + prior_quadratic + q2
    Q4 = directional + prior_quadratic + q4
    Q8 = directional + prior_quadratic + q8
    quadrature_scale = max(q2scale, q4scale, q8scale)
    S = directional_scale + prior_quadratic_scale + quadrature_scale
    E = 8 * max(abs(Q8 - Q4), abs(Q4 - Q2)) + 64 * eps(Float64) * S
    margin = Q8 + E
    all(isfinite, (Q2, Q4, Q8, S, E, margin)) || return nothing
    return (estimate = Q8, margin = margin, error = E,
            q2 = Q2, q4 = Q4, q8 = Q8,
            directional_scale = directional_scale,
            prior_scale = prior_quadratic_scale,
            quadrature_scale = quadrature_scale)
end

function _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P,
                        Zη = _ls_canonical_Zeta(length(y)),
                        Zψ = _ls_canonical_Zpsi(length(y)); a0 = nothing,
                        maxiter::Int = 200, tol::Real = 1e-9)
    a = a0 === nothing ? zeros(2G) : copy(a0)
    for _ in 1:maxiter
        grad = _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        anorm = norm(a)
        gnorm = norm(grad)
        bound = tol * (1 + anorm)
        if all(isfinite, a) && all(isfinite, grad) && isfinite(anorm) &&
           isfinite(gnorm) && isfinite(bound) && gnorm <= bound
            ch, certified = _ls_inner_certificate(kind, y, η0, ψ0, gidx, G, P,
                                                    Zη, Zψ, a, tol)
            return a, ch, certified
        end
        H = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
        _ls_allfinite(H) || return a, nothing, false
        f0 = _ls_joint(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        λ = 0.0
        stepped = false
        while true
            stagnated = false
            F = cholesky(Symmetric(H + λ * I); check = false)
            if issuccess(F)
                step = F \ grad
                α = 1.0
                while α >= 1e-10
                    trial = a .- α .* step
                    ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)
                    if all(trial .== a)
                        stagnated = true
                        break
                    end
                    if all(isfinite, trial) && isfinite(ft) && ft <= f0 &&
                       any(trial .!= a)
                        a = trial; stepped = true; break
                    end
                    if λ == 0.0 && α == 1.0
                        polish_ch, polished = _ls_inner_rounding_polish(
                            kind, y, η0, ψ0, gidx, G, P, Zη, Zψ,
                            a, grad, step, f0, trial, ft, tol,
                        )
                        polished && return trial, polish_ch, true
                    end
                    α *= 0.5
                end
                stepped && break
            end
            λ = λ == 0.0 ? 1e-8 : 10λ          # increase damping; retry
            λ > 1e12 && break
        end
        stepped || return a, _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ), false
    end
    ch, ok = _ls_inner_certificate(kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, tol)
    return a, ch, ok
end
