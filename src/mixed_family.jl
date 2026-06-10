# mixed_family.jl — CROSS-FAMILY bivariate via a shared per-observation latent.
#
#   y1_i ~ fam1(η1_i),  y2_i ~ fam2(η2_i),   η_k = X_k β_k + λ_k u_i,  u_i ~ N(0,1)
#
# The shared scalar latent u_i induces dependence between two responses that may be
# from DIFFERENT families (e.g. Gaussian × Poisson). The 1-D integral over u is done
# by Gauss–Hermite quadrature (K nodes), so the marginal is smooth and
# ForwardDiff-friendly (LBFGS, autodiff=:forward). The dependence is reported on the
# link/latent scale via `link_residual` (Nakagawa & Schielzeth 2010):
#     ρ = λ1 λ2 / sqrt((λ1² + v1) (λ2² + v2)).
# For Gaussian × Gaussian the marginal is exactly bivariate normal, so logLik and ρ
# reduce to the residual-correlation (rho12) model (identifiability note below).
#
# Identifiability: λ1 is fixed positive (λ1 = exp(lλ1)) to remove the u → -u sign
# flip. When BOTH axes are Gaussian the individual loadings are not separately
# identified (a flat λ1 ridge), but the marginal covariance — hence logLik and ρ —
# are; for Gaussian × non-Gaussian (no free residual variance on the non-Gaussian
# axis) all parameters are identified.

# Per-observation conditional log-density at a latent node, dispatched on family.
_mf_obs_ll(::Gaussian, η, y, trials, σ) =
    -0.5 * ((y - η) / σ)^2 - log(σ) - 0.9189385332046727  # 0.5*log(2π)
function _mf_obs_ll(::Poisson, η, y, trials, σ)
    ηc = clamp(η, -30.0, 30.0)
    return y * ηc - exp(ηc) - loggamma(y + 1)
end
function _mf_obs_ll(::Binomial, η, y, trials, σ)
    p = logistic(η)
    return y * log(p) + (trials - y) * log1p(-p) +
           loggamma(trials + 1) - loggamma(y + 1) - loggamma(trials - y + 1)
end

# Fitted mean on the response scale, for the link-residual evaluation.
_mf_mean(::Gaussian, η) = η
_mf_mean(::Poisson, η) = exp(η)
_mf_mean(::Binomial, η) = logistic(η)

# Sensible fixed-effect starting values per family.
_mf_init(::Gaussian, X, y) = X \ y
_mf_init(::Poisson, X, y) = X \ log.(max.(y, 0.5))
_mf_init(::Binomial, X, y) = zeros(size(X, 2))  # logit scale; 0 → p = 0.5

"""
    fit_mixed_family(; y1, X1, fam1, y2, X2, fam2,
                       trials1=ones(n), trials2=ones(n), K=32, g_tol=1e-6)

Fit the cross-family bivariate model (shared per-observation latent) and return a
`NamedTuple` with fixed effects `β1`/`β2`, loadings `λ1`/`λ2`, Gaussian residual
SDs `σ1`/`σ2` (`NaN` for non-Gaussian axes), link-scale variances `v1`/`v2`, the
latent-scale correlation `rho_latent`, `loglik`, `converged`, and `iterations`.

`fam1`/`fam2` are DRM family instances; `:gaussian`, `:poisson`, `:binomial` are
supported in this first slice. `trials*` are Binomial denominators (ignored
otherwise).
"""
function fit_mixed_family(; y1, X1, fam1, y2, X2, fam2,
        trials1 = ones(length(y1)), trials2 = ones(length(y2)),
        K::Int = 32, g_tol::Float64 = 1e-6)
    n = length(y1)
    n == length(y2) || throw(ArgumentError("y1 and y2 must have equal length"))
    p1 = size(X1, 2); p2 = size(X2, 2)
    s1 = fam1 isa Gaussian; s2 = fam2 isa Gaussian
    iλ1 = p1 + p2 + 1
    iλ2 = p1 + p2 + 2
    is1 = s1 ? p1 + p2 + 3 : 0
    is2 = s2 ? (s1 ? p1 + p2 + 4 : p1 + p2 + 3) : 0
    ntheta = p1 + p2 + 2 + (s1 ? 1 : 0) + (s2 ? 1 : 0)

    z, w = _gauss_hermite(K)
    rt2 = sqrt(2.0)
    logw = log.(w)
    half_log_pi = 0.5 * log(π)

    function nll(θ)
        β1 = θ[1:p1]
        β2 = θ[p1+1:p1+p2]
        λ1 = exp(θ[iλ1]); λ2 = θ[iλ2]
        σ1 = s1 ? exp(θ[is1]) : one(eltype(θ))
        σ2 = s2 ? exp(θ[is2]) : one(eltype(θ))
        η1f = X1 * β1
        η2f = X2 * β2
        T = eltype(θ)
        acc = Vector{T}(undef, K)
        total = zero(T)
        @inbounds for i in 1:n
            for k in 1:K
                u = rt2 * z[k]
                ll = _mf_obs_ll(fam1, η1f[i] + λ1 * u, y1[i], trials1[i], σ1) +
                     _mf_obs_ll(fam2, η2f[i] + λ2 * u, y2[i], trials2[i], σ2)
                acc[k] = logw[k] + ll
            end
            mx = maximum(acc)
            total -= mx + log(sum(exp.(acc .- mx))) - half_log_pi
        end
        return total
    end

    θ0 = zeros(ntheta)
    θ0[1:p1] = _mf_init(fam1, X1, y1)
    θ0[p1+1:p1+p2] = _mf_init(fam2, X2, y2)
    θ0[iλ1] = log(0.3)
    θ0[iλ2] = 0.1
    s1 && (θ0[is1] = log(std(y1) / 2 + eps()))
    s2 && (θ0[is2] = log(std(y2) / 2 + eps()))

    res = Optim.optimize(nll, θ0, Optim.LBFGS(),
                         Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    β1 = θ̂[1:p1]; β2 = θ̂[p1+1:p1+p2]
    λ1 = exp(θ̂[iλ1]); λ2 = θ̂[iλ2]
    σ1 = s1 ? exp(θ̂[is1]) : NaN
    σ2 = s2 ? exp(θ̂[is2]) : NaN
    v1 = s1 ? σ1^2 : link_residual(fam1, mean(_mf_mean.(Ref(fam1), X1 * β1)))
    v2 = s2 ? σ2^2 : link_residual(fam2, mean(_mf_mean.(Ref(fam2), X2 * β2)))
    ρ = λ1 * λ2 / sqrt((λ1^2 + v1) * (λ2^2 + v2))
    return (; β1, β2, λ1, λ2, σ1, σ2, v1, v2, rho_latent = ρ,
            loglik = -nll(θ̂), converged = Optim.converged(res),
            iterations = res.iterations)
end
