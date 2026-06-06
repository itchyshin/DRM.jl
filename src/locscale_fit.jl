# locscale_fit.jl — end-to-end fit for the non-Gaussian phylogenetic
# LOCATION–SCALE model (#202). Groundwork: not yet wired into `drm()`.
#
# Outer optimisation of the Laplace marginal (`_ls_marginal_nll`) over the
# fixed effects (βμ on the mean, βψ on the log-dispersion) and the 2×2
# group-level covariance Λ (log-Cholesky). This is the correctness-first engine:
# the outer gradient is finite-differenced by Optim's L-BFGS; the exact O(p)
# outer gradient (Takahashi) is a later optimisation slice.
#
# The fitter is agnostic to where the group structure comes from: pass
#   Q = I_G                      → independent groups (crossed/i.i.d.), or
#   Q = root-conditioned tree precision (one latent per non-root node, data at
#       leaves) → the PHYLOGENETIC location–scale model.
# In the phylogenetic case `gidx`/`G` come from `_poisson_phylo_setup`, exactly
# as for the mean-only phylo routes.

using LinearAlgebra: cholesky, Symmetric

# Packed marginal NLL at θ = [βμ; βψ; λ(3)].
function _ls_fit_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ = @view θ[1:pμ]
    βψ = @view θ[pμ+1:pμ+pψ]
    λv = @view θ[pμ+pψ+1:pμ+pψ+3]
    Λ = _ls_lc_to_Λ(λv)
    P = prior_precision(Q, inv(Λ))
    η0 = Xμ * βμ
    ψ0 = Xψ * βψ
    val, _, ok = _ls_marginal_nll(kind, y, η0, ψ0, gidx, G, P)
    return ok ? val : 1e18
end

"""
    _fit_locscale(kind, y, Xμ, Xψ, gidx, G, Q; ...)

Fit the q=2 non-Gaussian location–scale model. Returns a named tuple with the
packed estimate `θ`, the fixed effects `beta_mu` / `beta_psi`, the 2×2
group-level covariance `Lambda`, the marginal `nll`, and a `converged` flag.
"""
function _fit_locscale(kind, y, Xμ, Xψ, gidx, G, Q;
                       βμ0 = nothing, βψ0 = nothing,
                       λ0 = [log(0.3), 0.0, log(0.3)],
                       g_tol = 1e-6, iterations = 500)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ0 === nothing && (βμ0 = _poisson_fixed_start(y, Xμ))
    βψ0 === nothing && (βψ0 = zeros(pψ))
    θ0 = vcat(βμ0, βψ0, λ0)

    nll(θ) = _ls_fit_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(),
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    Λ̂ = _ls_lc_to_Λ(θ̂[pμ+pψ+1:pμ+pψ+3])
    return (θ = θ̂,
            beta_mu = θ̂[1:pμ],
            beta_psi = θ̂[pμ+1:pμ+pψ],
            Lambda = Λ̂,
            nll = nll(θ̂),
            converged = Optim.converged(res))
end

# Convenience: derive (Q, gidx, G) for the PHYLOGENETIC case from a tree and the
# per-observation species labels (reuses the verified phylo precision assembly).
function _locscale_phylo_setup(tree, labels)
    Q, leaf_node, _ = _poisson_phylo_setup(tree, labels)
    return Q, leaf_node, size(Q, 1)
end
