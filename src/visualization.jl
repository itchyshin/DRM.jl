# visualization.jl — plotting *data* providers, mirroring drmTMB's visualization
# helpers (plot_parameter_surface, plot_corpairs). DRM.jl keeps the base package
# plotting-dependency-free: these return the numbers a plot needs (grids, levels,
# correlations) so any backend (Makie/Plots/…) can render them with a few lines.
# The drmTMB-named plot_* wrappers are documented to call these.

"""
    profile_curve(fit, k; npoints = 41, span = 3.0, level = 0.95) -> NamedTuple

1-D profile-likelihood curve for coefficient index `k`, the data needed for a
profile diagnostic plot. At each grid value of `θ[k]`, all nuisance parameters
are re-optimised, so the returned curve is a likelihood-ratio profile rather
than a Wald/quadratic approximation.

Returns `(x, deviance, estimate, cutoff, k, param, coef, level)`:
- `x` — grid values for `θ[k]`, spanning `θ̂[k] ± span·se[k]` and including the
  MLE exactly;
- `deviance` — `2(ℓ̂ - ℓ_profile)` at each `x` value;
- `cutoff` — the `χ²₁(level)` reference line used by profile intervals.

Requires the fitted objective (`fit.nll`); the model must be fit through `drm`.
"""
function profile_curve(
    fit::DrmFit, k::Int; npoints::Int=41, span::Real=3.0, level::Real=0.95
)
    fit.nll === nothing && throw(
        ArgumentError(
            "profile_curve requires the fitted objective; this model was not built with one",
        ),
    )
    p = length(fit.theta)
    1 <= k <= p || throw(ArgumentError("k must be an index in 1:$p"))
    npoints >= 3 || throw(ArgumentError("npoints must be at least 3"))
    θ̂ = copy(fit.theta)
    nll = fit.nll
    nllhat = nll(θ̂)
    autodiff = _profile_autodiff_mode(nll, θ̂)
    se = stderror(fit)
    s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(θ̂[k]), 1.0)
    offsets = collect(range(-span, span; length=npoints))
    offsets[argmin(abs.(offsets))] = 0.0
    sort!(offsets)
    x = θ̂[k] .+ s .* offsets
    dev = Vector{Float64}(undef, npoints)
    mid = findfirst(==(θ̂[k]), x)
    mid === nothing && (mid = argmin(abs.(x .- θ̂[k])))
    u0 = θ̂[[i for i in 1:p if i != k]]
    dev[mid] = 0.0
    for idx in (mid + 1):npoints
        f, u0 = _profiled_nll(nll, θ̂, k, x[idx], u0; autodiff)
        dev[idx] = max(0.0, 2 * (f - nllhat))
    end
    u0 = θ̂[[i for i in 1:p if i != k]]
    for idx in (mid - 1):-1:1
        f, u0 = _profiled_nll(nll, θ̂, k, x[idx], u0; autodiff)
        dev[idx] = max(0.0, 2 * (f - nllhat))
    end
    param, cname = _coef_metadata(fit, k)
    return (
        x=x,
        deviance=dev,
        estimate=θ̂[k],
        cutoff=quantile(Chisq(1), level),
        k=k,
        param=param,
        coef=cname,
        level=float(level),
    )
end

"""
    parameter_surface(fit, k1, k2; npoints = 25, span = 3.0) -> NamedTuple

2-D profile-likelihood surface over two coefficients (global indices `k1`, `k2`
into `coef(fit)`), the data behind drmTMB's `plot_parameter_surface`. At each
grid node the remaining parameters are profiled out (re-optimised), so the
surface is the genuine profile deviance `2(ℓ̂ − ℓ_profile(θ_{k1}, θ_{k2}))`, not
a quadratic approximation.

Returns `(x, y, z, k1, k2)`:
- `x`, `y` — the grid coordinate vectors for `θ[k1]`, `θ[k2]` (length `npoints`),
  spanning `θ̂[k] ± span·se[k]`.
- `z` — `npoints × npoints` matrix of profile deviance (`z[i,j]` at `x[i], y[j]`);
  `0` at the MLE, rising away from it. `χ²₂` contours give joint confidence regions.

Requires the fitted objective (`fit.nll`); the model must be fit through `drm`.
"""
function parameter_surface(fit::DrmFit, k1::Int, k2::Int; npoints::Int=25, span::Real=3.0)
    fit.nll === nothing && throw(
        ArgumentError(
            "parameter_surface requires the fitted objective; this model was not built with one",
        ),
    )
    p = length(fit.theta)
    (1 <= k1 <= p && 1 <= k2 <= p && k1 != k2) ||
        throw(ArgumentError("k1, k2 must be distinct indices in 1:$p"))
    npoints >= 2 || throw(ArgumentError("npoints must be at least 2"))
    nll = fit.nll
    θ̂ = copy(fit.theta)
    nllhat = nll(θ̂)
    autodiff = _profile_autodiff_mode(nll, θ̂)
    se = stderror(fit)
    s1 = (isfinite(se[k1]) && se[k1] > 0) ? se[k1] : max(abs(θ̂[k1]), 1.0)
    s2 = (isfinite(se[k2]) && se[k2] > 0) ? se[k2] : max(abs(θ̂[k2]), 1.0)
    x = range(θ̂[k1] - span * s1, θ̂[k1] + span * s1; length=npoints)
    y = range(θ̂[k2] - span * s2, θ̂[k2] + span * s2; length=npoints)
    rest = [i for i in 1:p if i != k1 && i != k2]
    z = Matrix{Float64}(undef, npoints, npoints)
    ustart = θ̂[rest]
    for i in 1:npoints
        js = isodd(i) ? (1:npoints) : (npoints:-1:1)
        for j in js
            if isempty(rest)
                θ = copy(θ̂)
                θ[k1] = x[i]
                θ[k2] = y[j]
                z[i, j] = max(0.0, 2 * (nll(θ) - nllhat))
            else
                function obj(u)
                    θ = Vector{eltype(u)}(undef, p)
                    θ[k1] = convert(eltype(u), x[i])
                    θ[k2] = convert(eltype(u), y[j])
                    @inbounds for (t, r) in enumerate(rest)
                        θ[r] = u[t]
                    end
                    return nll(θ)
                end
                res = _profile_optimize(obj, ustart, autodiff)
                ustart = Optim.minimizer(res)
                z[i, j] = max(0.0, 2 * (Optim.minimum(res) - nllhat))
            end
        end
    end
    return (x=collect(x), y=collect(y), z=z, k1=k1, k2=k2)
end

function _coef_metadata(fit::DrmFit, k::Int)
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        if k in r
            return pp, nms[k - first(r) + 1]
        end
    end
    return error("coefficient index $k is not present in fit metadata")
end

"""
    corpairs_data(fit) -> NamedTuple

Summary of the fitted between-response residual correlation for plotting — the
data behind drmTMB's `plot_corpairs`. Returns `(rho = …, constant = …)`:
- `rho` — the per-observation `ρ12 = tanh(Xρ·β̂_ρ)` vector for bivariate models;
  empty for univariate models (no between-response correlation).
- `constant` — `true` when `ρ12` does not vary across observations (`rho12 ~ 1`),
  in which case a single number `rho[1]` summarises it; `false` when it varies
  (`rho12 ~ x`) and the full vector / a covariate scatter is the right plot.
"""
function corpairs_data(fit::DrmFit)
    haskey(fit.scales, :rho12) || return (rho=Float64[], constant=true)
    ρ = fit.scales[:rho12]
    isempty(ρ) && return (rho=Float64[], constant=true)
    constant = all(≈(ρ[1]), ρ)
    return (rho=ρ, constant=constant)
end
