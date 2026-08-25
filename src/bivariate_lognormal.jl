# bivariate_lognormal.jl — bivariate lognormal residual-correlation model, the
# Julia twin of drmTMB's `biv_lognormal()`.
#
# Two positive responses that are jointly lognormal: log(Y) is bivariate normal.
# The likelihood is therefore CLOSED FORM — no integration, no rectangle
# probabilities, no quadrature — which makes this the easy member of the
# bivariate non-Gaussian family (Gustavsson's MLLN; see
# `docs/dev-log/design/2026-08-14-a3-rescope-bivariate-nongaussian.md`).
#
#     f_Y(y) = phi_2(log y; mu, Sigma) * prod(1 / y_k)
#     log f_Y(y) = log phi_2(log y; mu, Sigma) - sum(log y_k)
#
# The Jacobian `- sum(log y_k)` does **not** depend on any parameter, so the MLE
# and its covariance are *identical* to fitting the bivariate Gaussian model to
# `log y`. Only the likelihood value shifts. That is why this route delegates to
# the verified `_fit_bivariate_residual` Gaussian kernel rather than duplicating
# it: one kernel, one set of guards (`RHO_GUARD`, per-cell missingness, finite
# seeding), no second copy to drift.
#
# Scale contract (drmTMB parity): `biv_lognormal()`'s dpars are
# `mu1, mu2, sigma1, sigma2, rho12` with links
# `identity, identity, log, log, atanh_guarded` — the SAME structure as
# `biv_gaussian()`. The identity links on `mu1`/`mu2` mean the location
# parameters live on the **log-response** scale, and `rho12` is the
# **log-residual** correlation, *not* the raw-scale Pearson correlation of the
# two response columns. drmTMB's vignette makes that scale part of the
# scientific interpretation; so does this docstring.

"""
    drm(f::BivariateDrmFormula, ::LogNormal; data, g_tol = 1e-8, method = :ML)

Fit a bivariate **lognormal** residual-correlation model — drmTMB's
`biv_lognormal()`.

Both responses must be strictly positive. `log(y1), log(y2)` are modelled as
bivariate normal, so `mu1`/`mu2` are means **on the log scale** (identity link)
and `rho12` is the **log-residual** correlation — not the Pearson correlation of
the raw responses. `sigma1`/`sigma2` are log-scale SDs (log link).

Matching drmTMB's first slice, this route is residual-only: no random effects,
no structured (`phylo`/`relmat`/`animal`/`spatial`) markers, and no REML.

```julia
d = (; y1 = exp.(0.4 .+ randn(200)), y2 = exp.(0.1 .+ randn(200)), x = randn(200))
fit = drm(bf(@formula(y1 ~ x), @formula(y2 ~ x),
             @formula(sigma1 ~ 1), @formula(sigma2 ~ 1), @formula(rho12 ~ 1)),
          LogNormal(); data = d)
coef(fit)      # mu1/mu2 on the log scale
corpairs(fit)  # log-residual rho12
```
"""
function drm(f::BivariateDrmFormula, fam::LogNormal; data, g_tol::Real = 1e-8,
             method::Symbol = :ML)
    method === :ML ||
        throw(ArgumentError("drm: the bivariate lognormal route implements ML only " *
            "(got method = :$method). drmTMB's `biv_lognormal()` first slice has no " *
            "random effects, so there is nothing for REML to integrate out."))
    rhs = Dict(f.forms)
    _, structured_marker = _bivariate_q4_marker(rhs)
    structured_marker === nothing ||
        throw(ArgumentError("drm: the bivariate lognormal route is residual-only — " *
            "`phylo`/`relmat`/`animal`/`spatial` markers are not implemented for " *
            "`LogNormal`, matching drmTMB's `biv_lognormal()` first slice. Use " *
            "`Gaussian()` for the structured bivariate engines."))
    return _fit_bivariate_residual(f, fam, data, rhs, g_tol)
end

function _fit_bivariate_residual(f::BivariateDrmFormula, fam::LogNormal, data, rhs,
                                 g_tol::Real)
    cols = NamedTuple(pairs(data))
    y1 = Vector{Float64}(getproperty(cols, f.response1))
    y2 = Vector{Float64}(getproperty(cols, f.response2))
    obs1 = _observed_response_mask(y1)
    obs2 = _observed_response_mask(y2)

    # Positivity is a modelling precondition, not a numerical accident: log(y)
    # of a non-positive observation is not a smaller likelihood, it is undefined.
    # Check only the OBSERVED cells — a missing cell in one response is legal
    # here exactly as in the Gaussian route.
    _check_positive_response(y1, obs1, f.response1)
    _check_positive_response(y2, obs2, f.response2)

    logdata = _with_logged_responses(data, f.response1, f.response2, y1, y2, obs1, obs2)
    gfit = _fit_bivariate_residual(f, Gaussian(), logdata, rhs, g_tol)

    # log f_Y(y) = log phi_2(log y; .) - sum over OBSERVED cells of log y.
    # Parameter-free, so theta-hat and vcov carry over untouched; only the
    # likelihood shifts (and with it aic/bic/deviance, which derive from it).
    jac = zero(Float64)
    @inbounds for i in eachindex(y1)
        obs1[i] && (jac += log(y1[i]))
        obs2[i] && (jac += log(y2[i]))
    end

    gnll = gfit.nll
    lnll = θ -> gnll(θ) + jac          # nll = -loglik, so the Jacobian ADDS here

    out = DrmFit(fam, gfit.blocks, gfit.coefnames, gfit.theta, gfit.vcov,
                 gfit.loglik - jac, gfit.nobs, gfit.converged,
                 gfit.means, Dict(:mu1 => Vector{Float64}(y1),
                                  :mu2 => Vector{Float64}(y2)),
                 gfit.scales, gfit.formula, lnll, gfit.nllgrad, gfit.ranef,
                 gfit.estim_method, gfit.reml_loglik, gfit.ml_loglik - jac,
                 gfit.marginal)
    # The 19-arg constructor above defaults `iterations` to -1 ("not recorded");
    # this route borrows the Gaussian bivariate fit's optimiser run wholesale
    # (only the reported likelihood is Jacobian-shifted), so its iteration count
    # is the honest count for THIS fit too — carry it through rather than
    # dropping it back to -1.
    return _withiterations(out, gfit.iterations)
end

# Strictly-positive check on the observed cells of a bivariate lognormal response.
function _check_positive_response(y, obs, name::Symbol)
    @inbounds for i in eachindex(y)
        obs[i] || continue
        y[i] > 0 ||
            throw(ArgumentError("drm: the bivariate lognormal route requires strictly " *
                "positive responses; `$name` has a non-positive observed value at row $i " *
                "(got $(y[i])). Use `Gaussian()` on pre-logged data if a zero is a " *
                "genuine measurement rather than a lognormal draw."))
    end
    return nothing
end

# A copy of `data` with the two response columns replaced by their logs.
# Unobserved cells are carried through untouched so the Gaussian kernel's
# per-cell missingness mask still sees them as missing.
function _with_logged_responses(data, r1::Symbol, r2::Symbol, y1, y2, obs1, obs2)
    nt = NamedTuple(pairs(data))
    l1 = [obs1[i] ? log(y1[i]) : y1[i] for i in eachindex(y1)]
    l2 = [obs2[i] ? log(y2[i]) : y2[i] for i in eachindex(y2)]
    return merge(nt, NamedTuple{(r1, r2)}((l1, l2)))
end
