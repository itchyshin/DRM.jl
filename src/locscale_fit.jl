# locscale_fit.jl — end-to-end fit for the non-Gaussian phylogenetic
# LOCATION–SCALE model (#202). Groundwork: not yet wired into `drm()`.
#
# Outer optimisation of the Laplace marginal (`_ls_marginal_nll`) over the
# fixed effects (βμ on the mean, βψ on the log-dispersion) and the 2×2
# group-level covariance Λ (log-Cholesky), driven by the exact O(p) outer
# gradient (`_ls_marginal_grad`) with LBFGS — fast and accurate enough for
# variance-component recovery. A derivative-free Nelder–Mead fallback guards the
# rare line-search stall on tiny / weakly-identified fixtures.
#
# The fitter is agnostic to where the group structure comes from: pass
#   Q = I_G                      → independent groups (crossed/i.i.d.), or
#   Q = root-conditioned tree precision (one latent per non-root node, data at
#       leaves) → the PHYLOGENETIC location–scale model.
# In the phylogenetic case `gidx`/`G` come from `_poisson_phylo_setup`, exactly
# as for the mean-only phylo routes.

using LinearAlgebra: cholesky, Symmetric

# Packed marginal NLL at θ = [βμ; βψ; λ(3)]. Each call solves the inner mode from
# a cold start, so the objective is deterministic — required by the optimiser.
function _ls_fit_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ = @view θ[1:pμ]
    βψ = @view θ[pμ+1:pμ+pψ]
    λv = @view θ[pμ+pψ+1:pμ+pψ+3]
    Λ = _ls_lc_to_Λ(λv)
    P = prior_precision(Q, _ls_inv2x2(Λ))
    val, _, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P)
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
                       g_tol = 1e-6, iterations = 1000, se::Bool = false)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ0 === nothing && (βμ0 = _poisson_fixed_start(y, Xμ))
    βψ0 === nothing && (βψ0 = zeros(pψ))
    θ0 = vcat(βμ0, βψ0, λ0)

    # Gradient-based fit using the exact O(p) outer gradient (`_ls_marginal_grad`).
    # Two robustness levers, both essential on tree (phylogenetic) problems:
    #  * WARM-START the inner mode across outer iterations (`warm` Ref). The outer
    #    gradient is exact (not finite-differenced), so the converged mode — and
    #    thus the gradient — is unchanged by the start point; warm-starting only
    #    makes each inner solve cheap (1–2 Newton steps instead of a cold solve).
    #  * a TRUST-REGION NEWTON outer optimiser (exact gradient + observed
    #    information as Hessian), which converges quadratically and tolerates the
    #    ill-conditioning/indefiniteness that makes LBFGS stall on trees. LBFGS
    #    then Nelder–Mead are kept as fallbacks.
    warm = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    function nll(θ)
        βμ = @view θ[1:pμ]; βψ = @view θ[pμ+1:pμ+pψ]
        Λ = _ls_lc_to_Λ(θ[pμ+pψ+1:pμ+pψ+3])
        P = prior_precision(Q, _ls_inv2x2(Λ))
        val, a, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P; a0 = warm[])
        ok && (warm[] = copy(a))
        return ok ? val : 1e18
    end
    g!(grad, θ) = (grad .= _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ; a0 = warm[]); grad)
    h!(H, θ) = (H .= _ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, θ; a0 = warm[]); H)
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    nm() = (warm[] = nothing; Optim.optimize(nll, θ0, Optim.NelderMead(),
                          Optim.Options(iterations = max(iterations, 2000))))
    res = try
        Optim.optimize(nll, g!, h!, θ0, Optim.NewtonTrustRegion(), opts)
    catch err
        err isa InterruptException && rethrow(err)
        warm[] = nothing
        try
            Optim.optimize(nll, g!, θ0, Optim.LBFGS(), opts)
        catch err2
            err2 isa InterruptException && rethrow(err2)
            nm()
        end
    end
    θ̂ = Optim.minimizer(res)
    # Feasibility guard. On weakly-identified fixtures a variance MLE can sit on
    # the boundary; LBFGS may then chase λ until Λ underflows to singular, where
    # the gradient is forced to zero and LBFGS falsely "converges" to an
    # infeasible (non-finite) θ̂. A feasible point (finite mode solve) provably has
    # a PD Λ (Λ = LLᵀ, det>0), so if the result is infeasible, fall back to the
    # conservative derivative-free solve.
    if any(!isfinite, θ̂) || !(nll(θ̂) < 1e17)
        res = nm()
        θ̂ = Optim.minimizer(res)
    end
    Λ̂ = _ls_lc_to_Λ(θ̂[pμ+pψ+1:pμ+pψ+3])
    nll(θ̂)                       # ensure warm[] holds the mode at θ̂ for the SE solve
    # Wald inference (opt-in): observed information = Hessian of the exact gradient.
    V = se ? _ls_vcov(kind, y, Xμ, Xψ, gidx, G, Q, θ̂; a0 = warm[]) : nothing
    return (θ = θ̂,
            beta_mu = θ̂[1:pμ],
            beta_psi = θ̂[pμ+1:pμ+pψ],
            Lambda = Λ̂,
            components = _ls_components(Λ̂),
            vcov = V,
            se = _ls_se(V),
            nll = nll(θ̂),
            converged = Optim.converged(res))
end

# Convenience: derive (Q, gidx, G) for the PHYLOGENETIC case from a tree and the
# per-observation species labels (reuses the verified phylo precision assembly).
function _locscale_phylo_setup(tree, labels)
    Q, leaf_node, _ = _poisson_phylo_setup(tree, labels)
    return Q, leaf_node, size(Q, 1)
end
