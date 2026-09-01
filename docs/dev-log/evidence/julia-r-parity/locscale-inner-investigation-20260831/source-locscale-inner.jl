# locscale_inner.jl — q=2 augmented-state inner solver for the non-Gaussian
# phylogenetic LOCATION–SCALE model (#202).
#
# Groundwork only: not wired into `drm()`. Builds on the two-axis kernels
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
using SparseArrays: sparse, SparseMatrixCSC

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
function _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P,
                        Zη = _ls_canonical_Zeta(length(y)),
                        Zψ = _ls_canonical_Zpsi(length(y)); a0 = nothing,
                        maxiter::Int = 200, tol::Real = 1e-9)
    a = a0 === nothing ? zeros(2G) : copy(a0)
    for _ in 1:maxiter
        grad = _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        if norm(grad) <= tol * (1 + norm(a))
            ch = _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
            return a, ch, issuccess(ch)
        end
        H = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
        f0 = _ls_joint(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        λ = 0.0
        stepped = false
        while true
            F = cholesky(Symmetric(H + λ * I); check = false)
            if issuccess(F)
                step = F \ grad
                α = 1.0
                while α >= 1e-10
                    trial = a .- α .* step
                    ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)
                    if isfinite(ft) && ft <= f0
                        a = trial; stepped = true; break
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
    ch = _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
    return a, ch, issuccess(ch)
end
