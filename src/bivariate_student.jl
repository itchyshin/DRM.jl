# bivariate_student.jl — bivariate Student-t residual/scatter model, the Julia
# twin of drmTMB's `biv_student()`.
#
# Two heavy-tailed real-valued responses sharing one scale-mixture:
#
#     Y = mu + diag(sigma) * Z * sqrt(nu / chisq_nu),   Z ~ N(0, R)
#
# which is exactly the multivariate-t with location `mu`, SCALE matrix
# Sigma = diag(sigma) R diag(sigma), and degrees of freedom `nu`. drmTMB's own
# `simulate()` for this family writes precisely that draw, which is what pins the
# parameterisation here (methods.R): `sigma1`/`sigma2` are **scale** parameters,
# not marginal SDs (the marginal SD is sigma * sqrt(nu/(nu-2))), and `rho12` is
# the **scatter** correlation.
#
# NU IS STRUCTURALLY SHARED. The scale mixture uses a single scalar mixing
# variable, so one `nu` governs both margins simultaneously — there is no
# per-margin `nu1`/`nu2` under the exact density. Per-margin tail heaviness would
# require a normal-variance-mixture copula, which gives up the exact density
# altogether. (Deep-research note dr19; drmTMB's own table says
# "shared-Student-t" for the same reason.)
#
# ZERO CORRELATION IS NOT INDEPENDENCE. For any finite `nu` the two components
# remain dependent even at rho12 = 0 — independence only appears in the Gaussian
# limit. That is a documentation obligation, not a numerical detail.
#
# The likelihood is CLOSED FORM: the bivariate-t density is analytic, so
# ForwardDiff + LBFGS is appropriate. dr19 documents an RQMC/derivative-free
# failure mode, but that concerns multivariate-t *probabilities* (rectangle
# integrals), not the density this likelihood evaluates — do not import that
# workaround here.

using SpecialFunctions: loggamma

"""
    drm(f::BivariateDrmFormula, ::Student; data, g_tol = 1e-8, method = :ML)

Fit a bivariate **Student-t** scatter-correlation model — drmTMB's
`biv_student()`.

`mu1`/`mu2` are locations (identity link), `sigma1`/`sigma2` are **scale**
parameters (log link) — not standard deviations; for `ν > 2` the marginal
`SD = σ·sqrt(ν/(ν−2))` — `rho12` is the **scatter** correlation (guarded
`atanh` link), and `nu` is the shared degrees of freedom on the `logm2` scale
`ν = 2 + exp(η)`, so `ν > 2` and the variance is finite.

`nu` is shared across both responses by construction, and **zero `rho12` does
not mean independent margins** at finite `ν`.

Matching drmTMB's first slice, this route is residual-only: no random effects,
no structured markers, and no REML.

```julia
f = bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
       sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
       nu = @formula(nu ~ 1), rho12 = @formula(rho12 ~ 1))
fit = drm(f, Student(); data = dat)
2 + exp(coef(fit, :nu)[1])   # estimated shared degrees of freedom
```
"""
function drm(f::BivariateDrmFormula, fam::Student; data, g_tol::Real = 1e-8,
             method::Symbol = :ML)
    method === :ML ||
        throw(ArgumentError("drm: the bivariate Student-t route implements ML only " *
            "(got method = :$method). drmTMB's `biv_student()` first slice has no " *
            "random effects, so there is nothing for REML to integrate out."))
    rhs = Dict(f.forms)
    _, structured_marker = _bivariate_q4_marker(rhs)
    structured_marker === nothing ||
        throw(ArgumentError("drm: the bivariate Student-t route is residual-only — " *
            "`phylo`/`relmat`/`animal`/`spatial` markers are not implemented for the " *
            "bivariate `Student`, matching drmTMB's `biv_student()` first slice. Use " *
            "`Gaussian()` for the structured bivariate engines."))
    return _fit_bivariate_residual(f, fam, data, rhs, g_tol)
end

function _fit_bivariate_residual(f::BivariateDrmFormula, fam::Student, data, rhs,
                                 g_tol::Real)
    y1, X1, nm1 = _design(f.response1, rhs[:mu1], data)
    y2, X2, nm2 = _design(f.response2, rhs[:mu2], data)
    _, Xs1, nms1 = _design(f.response1, rhs[:sigma1], data)
    _, Xs2, nms2 = _design(f.response1, rhs[:sigma2], data)
    _, Xν, nmν = _design(f.response1, get(rhs, :nu, ConstantTerm(1)), data)
    _, Xr, nmr = _design(f.response1, rhs[:rho12], data)

    n = length(y1)
    obs1 = _observed_response_mask(y1)
    obs2 = _observed_response_mask(y2)
    n_like = count(obs1 .| obs2)
    n_like > 0 ||
        throw(ArgumentError("drm: at least one bivariate Student-t response cell must be observed"))
    count(obs1 .& obs2) > 0 ||
        throw(ArgumentError("drm: at least one row must observe both bivariate Student-t " *
            "responses to estimate rho12"))

    # Parameter order mirrors drmTMB's dpar order for `biv_student()`:
    # mu1, mu2, sigma1, sigma2, NU, rho12 — nu before rho12.
    ps = (size(X1, 2), size(X2, 2), size(Xs1, 2), size(Xs2, 2), size(Xν, 2), size(Xr, 2))
    offs = cumsum([0, ps...])
    rng(k) = (offs[k]+1):offs[k+1]

    function nll(θ)
        b1 = θ[rng(1)]; b2 = θ[rng(2)]; bs1 = θ[rng(3)]
        bs2 = θ[rng(4)]; bν = θ[rng(5)]; br = θ[rng(6)]
        η1 = X1 * b1; η2 = X2 * b2
        ls1 = Xs1 * bs1; ls2 = Xs2 * bs2
        ην = Xν * bν; ηr = Xr * br
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            ν = 2 + exp(ην[i])                 # logm2 link ⇒ ν > 2, finite variance
            if obs1[i] && obs2[i]
                ρ = RHO_GUARD * tanh(ηr[i])
                om = 1 - ρ * ρ
                z1 = (y1[i] - η1[i]) * exp(-ls1[i])
                z2 = (y2[i] - η2[i]) * exp(-ls2[i])
                d2 = (z1 * z1 - 2ρ * z1 * z2 + z2 * z2) / om   # Mahalanobis on the scatter
                # −log f₂(y) for the bivariate (p = 2) Student-t
                s += -(loggamma((ν + 2) / 2) - loggamma(ν / 2)) + log(ν) + log(π) +
                     ls1[i] + ls2[i] + 0.5 * log(om) +
                     ((ν + 2) / 2) * log1p(d2 / ν)
            elseif obs1[i]
                # A margin of a bivariate-t is a univariate t with the SAME ν.
                z1 = (y1[i] - η1[i]) * exp(-ls1[i])
                s += -(loggamma((ν + 1) / 2) - loggamma(ν / 2)) + 0.5 * log(ν) +
                     0.5 * log(π) + ls1[i] + ((ν + 1) / 2) * log1p(z1 * z1 / ν)
            elseif obs2[i]
                z2 = (y2[i] - η2[i]) * exp(-ls2[i])
                s += -(loggamma((ν + 1) / 2) - loggamma(ν / 2)) + 0.5 * log(ν) +
                     0.5 * log(π) + ls2[i] + ((ν + 1) / 2) * log1p(z2 * z2 / ν)
            end
        end
        return s
    end

    θ0 = zeros(offs[end])
    X1_obs = Matrix{Float64}(X1[obs1, :]); y1_obs = Vector{Float64}(y1[obs1])
    X2_obs = Matrix{Float64}(X2[obs2, :]); y2_obs = Vector{Float64}(y2[obs2])
    β1 = X1_obs \ y1_obs
    β2 = X2_obs \ y2_obs
    θ0[rng(1)] .= β1
    θ0[rng(2)] .= β2
    θ0[rng(3)][1] = _seed_ls(y1_obs - X1_obs * β1, y1_obs)
    θ0[rng(4)][1] = _seed_ls(y2_obs - X2_obs * β2, y2_obs)
    θ0[rng(5)][1] = log(6.0)     # ν ≈ 8: heavy-tailed but comfortably finite-variance
    # rho12 block stays at 0 ⇒ ρ = 0.

    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol);
                         autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = _vcov_from_hessian(ForwardDiff.hessian(nll, θ̂); context = "bivariate Student-t")

    blocks = [:mu1 => rng(1), :mu2 => rng(2), :sigma1 => rng(3), :sigma2 => rng(4),
              :nu => rng(5), :rho12 => rng(6)]
    names = [:mu1 => nm1, :mu2 => nm2, :sigma1 => nms1, :sigma2 => nms2,
             :nu => nmν, :rho12 => nmr]
    means = Dict(:mu1 => X1 * θ̂[rng(1)], :mu2 => X2 * θ̂[rng(2)])
    obs = Dict(:mu1 => Vector{Float64}(y1), :mu2 => Vector{Float64}(y2))
    scales = Dict(:sigma1 => exp.(Xs1 * θ̂[rng(3)]),
                  :sigma2 => exp.(Xs2 * θ̂[rng(4)]),
                  :nu => 2 .+ exp.(Xν * θ̂[rng(5)]),
                  :rho12 => RHO_GUARD .* tanh.(Xr * θ̂[rng(6)]))
    return _withformula(
        _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n_like,
                        Optim.converged(res), means, obs, scales), nll), f)
end
