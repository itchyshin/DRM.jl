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

# Joint negative log-likelihood at latent a.
function _ls_joint(kind, y, η0, ψ0, gidx, a, P)
    s = zero(eltype(a))
    @inbounds for i in eachindex(y)
        g = gidx[i]
        s += _ls_nll(kind, y[i], η0[i] + a[2g-1], ψ0[i] + a[2g])
    end
    return s + 0.5 * dot(a, P * a)
end

# Gradient of the joint in a (length 2G).
function _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P)
    grad = Vector{eltype(a)}(undef, length(a))
    Pa = P * a
    @inbounds for k in eachindex(grad)
        grad[k] = Pa[k]
    end
    @inbounds for i in eachindex(y)
        g = gidx[i]
        gη, gψ = _ls_grad(kind, y[i], η0[i] + a[2g-1], ψ0[i] + a[2g])
        grad[2g-1] += gη
        grad[2g] += gψ
    end
    return grad
end

# Hessian of the joint: P + block-diagonal data part (a 2×2 block per group).
function _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P)
    rows = Int[]; cols = Int[]; vals = Float64[]
    dηη = zeros(G); dηψ = zeros(G); dψψ = zeros(G)
    @inbounds for i in eachindex(y)
        g = gidx[i]
        hηη, hηψ, hψψ = _ls_hess(kind, y[i], η0[i] + a[2g-1], ψ0[i] + a[2g])
        dηη[g] += hηη; dηψ[g] += hηψ; dψψ[g] += hψψ
    end
    @inbounds for g in 1:G
        mu = 2g - 1; sc = 2g
        push!(rows, mu); push!(cols, mu); push!(vals, dηη[g])
        push!(rows, mu); push!(cols, sc); push!(vals, dηψ[g])
        push!(rows, sc); push!(cols, mu); push!(vals, dηψ[g])
        push!(rows, sc); push!(cols, sc); push!(vals, dψψ[g])
    end
    D = sparse(rows, cols, vals, 2G, 2G)
    return P + D
end

# Clean Hessian factor at `a` (λ = 0) — used for the marginal's logdet term.
_ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P) =
    cholesky(Symmetric(_ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P)); check = false)

# Inner mode: Levenberg–Marquardt-damped Newton with a backtracking line search
# on jn(a). The observed two-axis Hessian can go indefinite far from the mode
# (the scale axis is non-convex), so when the Cholesky fails or a step is
# rejected we ridge H by λI and retry with growing λ — the robustness lever the
# q=4 engine also relies on. At convergence we return the clean (λ=0) Hessian
# factor so the Laplace marginal logdet is exact.
function _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P; a0 = nothing,
                        maxiter::Int = 200, tol::Real = 1e-9)
    a = a0 === nothing ? zeros(2G) : copy(a0)
    for _ in 1:maxiter
        grad = _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P)
        if norm(grad) <= tol * (1 + norm(a))
            ch = _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P)
            return a, ch, issuccess(ch)
        end
        H = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P)
        f0 = _ls_joint(kind, y, η0, ψ0, gidx, a, P)
        λ = 0.0
        stepped = false
        while true
            F = cholesky(Symmetric(H + λ * I); check = false)
            if issuccess(F)
                step = F \ grad
                α = 1.0
                while α >= 1e-10
                    trial = a .- α .* step
                    ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P)
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
        stepped || return a, _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P), false
    end
    ch = _ls_hess_chol(kind, y, η0, ψ0, gidx, G, a, P)
    return a, ch, issuccess(ch)
end
