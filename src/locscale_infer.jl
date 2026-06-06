# locscale_infer.jl — Wald inference + group-level summaries for the q=2
# location–scale fit (#202). Builds on the exact outer gradient
# (`_ls_marginal_grad`): the observed information is the symmetric
# finite-difference Jacobian of that gradient at θ̂. Because the gradient is exact
# and O(p), and the number of packed parameters is fixed, the whole Hessian costs
# O(p) — no dense p×p Hessian of the latent field is ever formed.

using LinearAlgebra: Symmetric, diag, SingularException

"""
    _ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, θ; h=1e-5) -> Symmetric

Observed information ∂²M/∂θ² of the Laplace marginal at θ, as the symmetrised
central finite-difference Jacobian of the exact gradient `_ls_marginal_grad`.
"""
function _ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, θ; h = 1e-5)
    p = length(θ)
    H = zeros(p, p)
    @inbounds for k in 1:p
        θp = copy(θ); θp[k] += h
        θm = copy(θ); θm[k] -= h
        gp = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θp)
        gm = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θm)
        H[:, k] = (gp .- gm) ./ (2h)
    end
    return Symmetric((H + H') ./ 2)
end

# Wald covariance V = (observed information)⁻¹. Returns `nothing` if the
# information is singular (e.g. a variance pinned at the boundary).
function _ls_vcov(kind, y, Xμ, Xψ, gidx, G, Q, θ; h = 1e-5)
    H = _ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, θ; h = h)
    return try
        inv(Matrix(H))
    catch err
        err isa SingularException ? nothing : rethrow(err)
    end
end

# Standard errors from a covariance matrix; NaN where the variance is non-positive.
_ls_se(V) = V === nothing ? nothing : [d > 0 ? sqrt(d) : NaN for d in diag(V)]

"""
    _ls_components(Λ) -> NamedTuple

Named group-level summaries of the 2×2 covariance Λ: the mean-axis SD, the
scale-axis SD, and the mean↔scale correlation ρ_a.
"""
function _ls_components(Λ)
    sμ = sqrt(Λ[1, 1]); sψ = sqrt(Λ[2, 2])
    return (sd_mu = sμ, sd_psi = sψ, cor_mu_psi = Λ[1, 2] / (sμ * sψ))
end
