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

using LinearAlgebra: Symmetric, cholesky, issuccess, norm, dot
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

# Inner mode: damped Newton with a backtracking line search on jn(a).
function _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P; a0 = nothing,
                        maxiter::Int = 100, tol::Real = 1e-9)
    a = a0 === nothing ? zeros(2G) : copy(a0)
    ch = nothing
    for _ in 1:maxiter
        grad = _ls_joint_grad(kind, y, η0, ψ0, gidx, a, P)
        norm(grad) <= tol * (1 + norm(a)) && return a, ch, true
        H = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P)
        ch = cholesky(Symmetric(H); check = false)
        issuccess(ch) || return a, ch, false
        step = ch \ grad
        f0 = _ls_joint(kind, y, η0, ψ0, gidx, a, P)
        α = 1.0; accepted = false
        while α >= 1e-6
            trial = a .- α .* step
            if _ls_joint(kind, y, η0, ψ0, gidx, trial, P) <= f0
                a = trial; accepted = true; break
            end
            α *= 0.5
        end
        accepted || return a, ch, false
    end
    return a, ch, ch !== nothing
end
