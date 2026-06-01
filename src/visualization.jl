# visualization.jl — plotting *data* providers, mirroring drmTMB's visualization
# helpers (plot_parameter_surface, plot_corpairs). DRM.jl keeps the base package
# plotting-dependency-free: these return the numbers a plot needs (grids, levels,
# correlations) so any backend (Makie/Plots/…) can render them with a few lines.
# The drmTMB-named plot_* wrappers are documented to call these.

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
function parameter_surface(fit::DrmFit, k1::Int, k2::Int; npoints::Int = 25, span::Real = 3.0)
    fit.nll === nothing &&
        throw(ArgumentError("parameter_surface requires the fitted objective; this model was not built with one"))
    p = length(fit.theta)
    (1 <= k1 <= p && 1 <= k2 <= p && k1 != k2) ||
        throw(ArgumentError("k1, k2 must be distinct indices in 1:$p"))
    nll = fit.nll
    θ̂ = copy(fit.theta)
    nllhat = nll(θ̂)
    se = stderror(fit)
    s1 = (isfinite(se[k1]) && se[k1] > 0) ? se[k1] : max(abs(θ̂[k1]), 1.0)
    s2 = (isfinite(se[k2]) && se[k2] > 0) ? se[k2] : max(abs(θ̂[k2]), 1.0)
    x = range(θ̂[k1] - span * s1, θ̂[k1] + span * s1; length = npoints)
    y = range(θ̂[k2] - span * s2, θ̂[k2] + span * s2; length = npoints)
    rest = [i for i in 1:p if i != k1 && i != k2]
    z = Matrix{Float64}(undef, npoints, npoints)
    for i in 1:npoints, j in 1:npoints
        if isempty(rest)
            θ = copy(θ̂); θ[k1] = x[i]; θ[k2] = y[j]
            z[i, j] = 2 * (nll(θ) - nllhat)
        else
            function obj(u)
                θ = Vector{eltype(u)}(undef, p)
                θ[k1] = convert(eltype(u), x[i]); θ[k2] = convert(eltype(u), y[j])
                @inbounds for (t, r) in enumerate(rest)
                    θ[r] = u[t]
                end
                return nll(θ)
            end
            res = Optim.optimize(obj, θ̂[rest], Optim.LBFGS(); autodiff = :forward)
            z[i, j] = 2 * (Optim.minimum(res) - nllhat)
        end
    end
    return (x = collect(x), y = collect(y), z = z, k1 = k1, k2 = k2)
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
    haskey(fit.scales, :rho12) || return (rho = Float64[], constant = true)
    ρ = fit.scales[:rho12]
    isempty(ρ) && return (rho = Float64[], constant = true)
    constant = all(≈(ρ[1]), ρ)
    return (rho = ρ, constant = constant)
end
