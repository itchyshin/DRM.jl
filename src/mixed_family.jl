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

# Which families carry a (log-native) dispersion parameter in the θ vector. The
# dispersionless families (Poisson, Binomial) are fully pinned by η alone; every
# other family adds one slot per axis: log σ for Gaussian/Beta/Gamma, log θ for
# NB2. The natural dispersion value `d = exp(slot)` is what `_mf_obs_ll` receives.
_mf_has_disp(fam) = !(fam isa Poisson || fam isa Binomial)

# Per-observation conditional log-density at a latent node, dispatched on family.
# `d` is the family's NATURAL dispersion (Gaussian/Beta/Gamma: σ; NB2: size θ);
# dispersionless families ignore it (it is passed as 1).
_mf_obs_ll(::Gaussian, η, y, trials, d) =
    -0.5 * ((y - η) / d)^2 - log(d) - 0.9189385332046727  # 0.5*log(2π)
function _mf_obs_ll(::Poisson, η, y, trials, d)
    ηc = clamp(η, -30.0, 30.0)
    return y * ηc - exp(ηc) - loggamma(y + 1)
end
function _mf_obs_ll(::Binomial, η, y, trials, d)
    p = _logistic(clamp(η, -30.0, 30.0))
    return y * log(p) + (trials - y) * log1p(-p) +
           loggamma(trials + 1) - loggamma(y + 1) - loggamma(trials - y + 1)
end
# NB2 (mean μ=exp(η), size θ=d): hand-coded log-pmf with loggamma (ForwardDiff-safe
# in θ; no Distributions.NegativeBinomial domain checks). Var = μ + μ²/θ. θ is
# clamped to a finite positive range (cf. negbinomial.jl's ησ∈[-20,20]) so wild
# line-search steps cannot push the size to 0/∞.
function _mf_obs_ll(::NegBinomial2, η, y, trials, d)
    μ = exp(clamp(η, -30.0, 30.0)); θ = clamp(d, 2.0e-9, 4.9e8)   # exp(∓20)
    return loggamma(y + θ) - loggamma(θ) - loggamma(y + 1) +
           θ * (log(θ) - log(θ + μ)) + y * (log(μ) - log(θ + μ))
end
# Beta (mean μ=logistic(η), precision φ=1/σ², σ=d): Beta(μφ, (1-μ)φ). The
# existing beta.jl uses exactly this Distributions.logpdf path under ForwardDiff;
# σ is clamped to beta.jl's range (ησ∈[-15,15]) to keep φ finite & positive.
function _mf_obs_ll(::Beta, η, y, trials, d)
    μ = _logistic(clamp(η, -30.0, 30.0)); φ = inv(clamp(d, 3.1e-7, 3.3e6)^2)
    return Distributions.logpdf(Distributions.Beta(μ * φ, (1 - μ) * φ), y)
end
# Gamma (mean μ=exp(η), shape α=1/σ², σ=d): Gamma(α, μ/α). Matches gamma.jl,
# including the σ clamp (ησ∈[-15,15]) that guards the shape/scale positivity.
function _mf_obs_ll(::Gamma, η, y, trials, d)
    μ = exp(clamp(η, -30.0, 30.0)); α = inv(clamp(d, 3.1e-7, 3.3e6)^2)
    return Distributions.logpdf(Distributions.Gamma(α, μ / α), y)
end

# Fitted mean on the response scale, for the link-residual evaluation.
_mf_mean(::Gaussian, η) = η
_mf_mean(::Poisson, η) = exp(η)
_mf_mean(::Binomial, η) = _logistic(η)
_mf_mean(::NegBinomial2, η) = exp(η)
_mf_mean(::Beta, η) = _logistic(η)
_mf_mean(::Gamma, η) = exp(η)

# Sensible fixed-effect starting values per family (link scale).
_mf_init(::Gaussian, X, y) = X \ y
_mf_init(::Poisson, X, y) = X \ log.(max.(y, 0.5))
_mf_init(::Binomial, X, y) = zeros(size(X, 2))  # logit scale; 0 → p = 0.5
_mf_init(::NegBinomial2, X, y) = X \ log.(max.(y, 0.5))            # log link
_mf_init(::Beta, X, y) = X \ (log.(clamp.(y, 1e-3, 1 - 1e-3)) .-   # logit link
                              log1p.(-clamp.(y, 1e-3, 1 - 1e-3)))
_mf_init(::Gamma, X, y) = X \ log.(max.(y, 1e-3))                  # log link

# Starting value for the (log-native) dispersion slot, per disp-carrying family.
function _mf_disp_init(::Gaussian, y)
    log(max(Statistics.std(y) / 2, 1e-2))                          # log σ
end
function _mf_disp_init(::NegBinomial2, y)                          # log θ (MoM)
    m = Statistics.mean(y); v = Statistics.var(y)
    log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
end
function _mf_disp_init(::Beta, y)                                  # log σ = -½ log φ
    ȳ = Statistics.mean(y); v = Statistics.var(y)
    φ0 = max(ȳ * (1 - ȳ) / max(v, eps()) - 1, 0.5)
    -0.5 * log(φ0)
end
function _mf_disp_init(::Gamma, y)                                 # log σ = -½ log α
    ȳ = Statistics.mean(y); v = Statistics.var(y)
    α0 = max(ȳ^2 / max(v, eps()), 0.5)
    -0.5 * log(α0)
end

# Link-scale residual variance v_k for the latent correlation, given the raw
# dispersion slot value (or `nothing` for dispersionless families) and a
# representative fitted mean. Maps the log-native slot to each family's own
# dispersion convention before calling `link_residual`.
_mf_disp_v(fam::Gaussian, slot, μ̂) = link_residual(fam; dispersion = exp(2 * slot))      # σ²
_mf_disp_v(fam::Gamma, slot, μ̂) = link_residual(fam; dispersion = exp(2 * slot))         # σ² → trigamma(1/σ²)
_mf_disp_v(fam::Beta, slot, μ̂) = link_residual(fam, μ̂; dispersion = exp(-2 * slot))      # φ = 1/σ²
_mf_disp_v(fam::NegBinomial2, slot, μ̂) = link_residual(fam; dispersion = exp(slot))      # θ
_mf_disp_v(fam::Poisson, slot, μ̂) = link_residual(fam, μ̂)
_mf_disp_v(fam::Binomial, slot, μ̂) = link_residual(fam, μ̂)

# Per-observation response sampler (for the parametric bootstrap CI). `d` is the
# natural dispersion as in `_mf_obs_ll`.
_mf_rand(::Gaussian, η, trials, d, rng) = η + d * randn(rng)
function _mf_rand(::Poisson, η, trials, d, rng)
    λ = exp(clamp(η, -20.0, 20.0))
    L = exp(-λ); k = 0; p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return Float64(k - 1)
    end
end
function _mf_rand(::Binomial, η, trials, d, rng)
    p = _logistic(clamp(η, -30.0, 30.0))
    s = 0
    for _ in 1:Int(trials)
        s += rand(rng) < p
    end
    return Float64(s)
end
function _mf_rand(::NegBinomial2, η, trials, d, rng)
    μ = exp(clamp(η, -20.0, 20.0)); θ = d; p = θ / (θ + μ)
    return Float64(rand(rng, Distributions.NegativeBinomial(θ, p)))
end
function _mf_rand(::Beta, η, trials, d, rng)
    μ = _logistic(clamp(η, -30.0, 30.0)); φ = inv(d^2)
    return rand(rng, Distributions.Beta(μ * φ, (1 - μ) * φ))
end
function _mf_rand(::Gamma, η, trials, d, rng)
    μ = exp(clamp(η, -20.0, 20.0)); α = inv(d^2)
    return rand(rng, Distributions.Gamma(α, μ / α))
end

"""
    fit_mixed_family(; y1, X1, fam1, y2, X2, fam2,
                       trials1=ones(n), trials2=ones(n), K=32, g_tol=1e-6)

Fit the cross-family bivariate model (shared per-observation latent) and return a
`NamedTuple` with fixed effects `β1`/`β2`, loadings `λ1`/`λ2`, per-axis dispersion
`σ1`/`σ2` on the natural scale (`NaN` for dispersionless axes), link-scale
variances `v1`/`v2`, the latent-scale correlation `rho_latent`, `loglik`,
`converged`, and `iterations`.

`fam1`/`fam2` are DRM family instances. Supported: `Gaussian`, `Poisson`,
`Binomial`, `NegBinomial2`, `Beta`, `Gamma`. Dispersion-carrying families
(Gaussian/Beta/Gamma → `σ`; NB2 → size `θ`) add one log-native slot per axis;
`Poisson`/`Binomial` are dispersionless. For those families `σ1`/`σ2` returns the
natural dispersion (`σ` for Gaussian/Beta/Gamma, `θ` for NB2). `trials*` are
Binomial denominators (ignored otherwise).
"""
function fit_mixed_family(; y1, X1, fam1, y2, X2, fam2,
        trials1 = ones(length(y1)), trials2 = ones(length(y2)),
        K::Int = 32, g_tol::Float64 = 1e-6,
        confint::Bool = true, level::Float64 = 0.95,
        profile::Bool = false, B::Int = 0, rng = Random.default_rng())
    n = length(y1)
    n == length(y2) || throw(ArgumentError("y1 and y2 must have equal length"))
    p1 = size(X1, 2); p2 = size(X2, 2)
    # s1/s2: does each axis carry a (log-native) dispersion slot? log σ for
    # Gaussian/Beta/Gamma, log θ for NB2; none for Poisson/Binomial.
    s1 = _mf_has_disp(fam1); s2 = _mf_has_disp(fam2)
    iλ1 = p1 + p2 + 1
    iλ2 = p1 + p2 + 2
    is1 = s1 ? p1 + p2 + 3 : 0
    is2 = s2 ? (s1 ? p1 + p2 + 4 : p1 + p2 + 3) : 0
    ntheta = p1 + p2 + 2 + (s1 ? 1 : 0) + (s2 ? 1 : 0)

    z, w = _gauss_hermite(K)
    rt2 = sqrt(2.0)
    logw = log.(w)
    half_log_pi = 0.5 * log(π)

    # NB: nll's locals are deliberately NOT named β1/λ1/σ1 etc. Sharing names with
    # the post-fit outer variables would box them (closure capture), and the
    # ForwardDiff.hessian below would then write Duals into the returned β1/λ1/σ1.
    function nll(θ)
        bb1 = θ[1:p1]
        bb2 = θ[p1+1:p1+p2]
        ll1 = exp(θ[iλ1]); ll2 = θ[iλ2]
        sd1 = s1 ? exp(θ[is1]) : one(eltype(θ))   # natural dispersion (σ or θ) per axis
        sd2 = s2 ? exp(θ[is2]) : one(eltype(θ))
        η1f = X1 * bb1
        η2f = X2 * bb2
        T = eltype(θ)
        acc = Vector{T}(undef, K)
        total = zero(T)
        @inbounds for i in 1:n
            for k in 1:K
                u = rt2 * z[k]
                ll = _mf_obs_ll(fam1, η1f[i] + ll1 * u, y1[i], trials1[i], sd1) +
                     _mf_obs_ll(fam2, η2f[i] + ll2 * u, y2[i], trials2[i], sd2)
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
    s1 && (θ0[is1] = _mf_disp_init(fam1, y1))   # log-native dispersion slot, per family
    s2 && (θ0[is2] = _mf_disp_init(fam2, y2))

    res = Optim.optimize(nll, θ0, Optim.LBFGS(),
                         Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Float64.(Optim.minimizer(res))   # concrete Float64; the ForwardDiff calls below get copies
    β1 = θ̂[1:p1]; β2 = θ̂[p1+1:p1+p2]
    λ1 = exp(θ̂[iλ1]); λ2 = θ̂[iλ2]
    σ1 = s1 ? exp(θ̂[is1]) : NaN
    σ2 = s2 ? exp(θ̂[is2]) : NaN

    # ρ(θ): loadings + link-scale residual variances. Reused by the point estimate
    # and the Fisher-z delta-method CI.
    function rho_of(θ)
        b1 = @view θ[1:p1]
        b2 = @view θ[p1+1:p1+p2]
        l1 = exp(θ[iλ1]); l2 = θ[iλ2]
        μ̄1 = mean(_mf_mean.(Ref(fam1), X1 * b1))
        μ̄2 = mean(_mf_mean.(Ref(fam2), X2 * b2))
        vv1 = _mf_disp_v(fam1, s1 ? θ[is1] : nothing, μ̄1)
        vv2 = _mf_disp_v(fam2, s2 ? θ[is2] : nothing, μ̄2)
        return l1 * l2 / sqrt((l1^2 + vv1) * (l2^2 + vv2))
    end
    ρ = rho_of(θ̂)
    v1 = _mf_disp_v(fam1, s1 ? θ̂[is1] : nothing, mean(_mf_mean.(Ref(fam1), X1 * β1)))
    v2 = _mf_disp_v(fam2, s2 ? θ̂[is2] : nothing, mean(_mf_mean.(Ref(fam2), X2 * β2)))

    # Fisher-z Wald CI: delta method on atanh(ρ(θ)) with the observed-information
    # vcov. NaN interval if the Hessian is not invertible / variance non-positive.
    rho_ci_wald = (NaN, NaN)
    if confint
        H = ForwardDiff.hessian(nll, copy(θ̂))
        V = try
            inv(H)
        catch
            fill(NaN, size(H))
        end
        g = ForwardDiff.gradient(t -> atanh(clamp(rho_of(t), -0.999999, 0.999999)), copy(θ̂))
        var_z = dot(g, V * g)
        if isfinite(var_z) && var_z > 0
            zc = Distributions.quantile(Distributions.Normal(), 1 - (1 - level) / 2)
            zr = atanh(clamp(ρ, -0.999999, 0.999999))
            se = sqrt(var_z)
            rho_ci_wald = (tanh(zr - zc * se), tanh(zr + zc * se))
        end
    end

    # Profile-likelihood CI on ρ (the recommended interval): penalty-constrained
    # re-optimisation fixing ρ(θ)=ρ0 on the atanh scale, bisected to a χ²(1, level)
    # deviance drop. Better-calibrated than Wald near the boundary, cheaper than the
    # bootstrap. (nll/rho_of are reused; nll's locals are renamed so no Dual leaks.)
    rho_ci_profile = (NaN, NaN)
    if profile
        nllhat = nll(θ̂)
        q = Distributions.quantile(Distributions.Chisq(1), level)
        prof_dev = function (ρ0)
            zr0 = atanh(clamp(ρ0, -0.999999, 0.999999))
            obj(θ) = nll(θ) + 1.0e4 * (atanh(clamp(rho_of(θ), -0.999999, 0.999999)) - zr0)^2
            r = Optim.optimize(obj, copy(θ̂), Optim.LBFGS(),
                               Optim.Options(g_tol = 1e-9); autodiff = :forward)
            return 2 * (nll(Optim.minimizer(r)) - nllhat)
        end
        endpoint = function (a, b)   # dev(a), dev(b) straddle q → bisect for dev = q
            fa = prof_dev(a) - q
            for _ in 1:40
                mid = (a + b) / 2
                fm = prof_dev(mid) - q
                if fa * fm <= 0
                    b = mid
                else
                    a = mid; fa = fm
                end
                abs(b - a) < 1e-3 && break
            end
            (a + b) / 2
        end
        lobnd = prof_dev(-0.999) >= q ? endpoint(-0.999, ρ) : -0.999
        hibnd = prof_dev(0.999) >= q ? endpoint(ρ, 0.999) : 0.999
        rho_ci_profile = (lobnd, hibnd)
    end

    # Parametric bootstrap CI: resample the shared latent + per-family draws at θ̂,
    # refit, take percentile interval. (β1/λ1/σ1 are concrete Float64 — see the nll
    # local-naming note — so the resampled data is clean and the refits converge.)
    rho_ci_boot = (NaN, NaN)
    if B > 0
        η1f = X1 * β1; η2f = X2 * β2
        ρs = Float64[]
        for _ in 1:B
            ub = randn(rng, n)
            y1b = [_mf_rand(fam1, η1f[i] + λ1 * ub[i], trials1[i], σ1, rng) for i in 1:n]
            y2b = [_mf_rand(fam2, η2f[i] + λ2 * ub[i], trials2[i], σ2, rng) for i in 1:n]
            fb = try
                fit_mixed_family(; y1 = y1b, X1 = X1, fam1 = fam1, y2 = y2b, X2 = X2,
                                 fam2 = fam2, trials1 = trials1, trials2 = trials2,
                                 K = K, g_tol = g_tol, confint = false)
            catch
                nothing
            end
            fb === nothing || push!(ρs, fb.rho_latent)
        end
        filter!(isfinite, ρs)
        if length(ρs) >= max(10, B ÷ 2)
            α = (1 - level) / 2
            rho_ci_boot = (Statistics.quantile(ρs, α), Statistics.quantile(ρs, 1 - α))
        end
    end

    return (; β1, β2, λ1, λ2, σ1, σ2, v1, v2, rho_latent = ρ,
            rho_ci_wald = rho_ci_wald, rho_ci_profile = rho_ci_profile,
            rho_ci_boot = rho_ci_boot,
            loglik = -nll(θ̂), converged = Optim.converged(res),
            iterations = res.iterations)
end
