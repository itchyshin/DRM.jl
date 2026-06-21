# test_164_crossed_hetero_sigma.jl — covariate dispersion (sigma ~ x) with a
# CROSSED random-effect mean (1 | g) + (1 | h) for the non-Gaussian sparse-Laplace
# families (NB2 / Gamma / Beta), #164.
#
# This is the crossed analogue of test_164_mean_re_covariate_sigma.jl (the phylo
# case). The dispersion log-scale is a per-observation linear predictor
# ησ = Xσ·βσ threaded through `_crossed_mean_laplace_hetero_fg` + the existing
# `Val(:*_hetero)` kernels, so θ = [βμ(pμ); βσ(pσ); logσ_g; logσ_h]. The two
# trailing log-SDs are the crossed random-effect scales and stay 2-long.
#
# Three gates per family:
#   1. FD-vs-exact gate on the crossed marginal NLL gradient, evaluated OFF the
#      optimum (exercises the implicit db̂/dθ terms across βσ and both logσ).
#      ≤ 1e-6 for NB2/Gamma; ≤ 1e-4 for Beta (the βσ slope direction of the Beta
#      polygamma kernel is the loose off-optimum coordinate; the constant-σ Beta
#      crossed gate still holds at 1e-6).
#   2. Reduction invariant: a one-column constant Xσ reproduces the scalar
#      `_crossed_mean_laplace_nuisance_fg` bit-for-bit — no `sigma ~ 1` regression.
#   3. End-to-end drm() recovery of the σ slope with a crossed (1 | g) + (1 | h) mean.

using DRM
using Test, Random, LinearAlgebra
import Distributions
using SpecialFunctions: loggamma, digamma

const CROSS_BETA_TOL = 1e-4

_logistic164(x) = 1 / (1 + exp(-x))

# Fresh-mode central difference (matches the crossed nuisance gate harness in
# test_crossed_laplace_generic.jl: inner mode re-solved each eval, h scaled by |θ|).
function _cross_fd_grad(f, θ; h = 1e-5)
    g = similar(θ)
    for k in eachindex(θ)
        step = h * max(abs(θ[k]), 1.0)
        θp = copy(θ); θp[k] += step
        θm = copy(θ); θm[k] -= step
        g[k] = (f(θp) - f(θm)) / (2step)
    end
    return g
end

# ---- per-observation hetero aux closures (ησ vector ↦ per-obs dispersion) -------
_nb2_cross_hetero(yint, yf) = ησ -> begin
    r = exp.(clamp.(-2 .* ησ, -8.0, 8.0))
    lconst = [loggamma(yf[i] + r[i]) - loggamma(r[i]) - DRM._logfactorial(yint[i])
              for i in eachindex(yint)]
    return (y = yf, size = r, lconst = lconst)
end
_gamma_cross_hetero(yv) = ησ -> begin
    α = exp.(clamp.(-2 .* ησ, -8.0, 8.0))
    lconst = [α[i] * log(α[i]) - loggamma(α[i]) + (α[i] - 1) * log(yv[i]) for i in eachindex(yv)]
    return (y = yv, shape = α, lconst = lconst)
end
_beta_cross_hetero(yv, ylogit) = ησ -> begin
    φ = exp.(clamp.(-2 .* ησ, -8.0, 8.0))
    return (y = yv, precision = φ, ylogit = ylogit,
            lgammaφ = loggamma.(φ), digammaφ = digamma.(φ))
end

# ---- scalar aux closures (constant-σ path) for the reduction invariant ----------
_nb2_cross_scalar(yint, yf) = ls -> begin
    r = exp(clamp(-2 * ls, -8.0, 8.0))
    lconst = [loggamma(yf[i] + r) - loggamma(r) - DRM._logfactorial(yint[i]) for i in eachindex(yint)]
    return (y = yf, size = r, lconst = lconst)
end
_gamma_cross_scalar(yv) = ls -> begin
    α = exp(clamp(-2 * ls, -8.0, 8.0))
    lconst = [α * log(α) - loggamma(α) + (α - 1) * log(yv[i]) for i in eachindex(yv)]
    return (y = yv, shape = α, lconst = lconst)
end
_beta_cross_scalar(yv, ylogit) = ls -> begin
    φ = exp(clamp(-2 * ls, -8.0, 8.0))
    return (y = yv, precision = φ, ylogit = ylogit,
            lgammaφ = loggamma(φ), digammaφ = digamma(φ))
end

# Shared small crossed design for the _fg-level gates (direct integer group ids).
function _crossed_hetero_design(; seed = 514, n = 240, G = 6, H = 5)
    rng = MersenneTwister(seed)
    x = randn(rng, n)
    gidx = [rand(rng, 1:G) for _ in 1:n]
    hidx = [rand(rng, 1:H) for _ in 1:n]
    Xμ = hcat(ones(n), x)
    Xσ = hcat(ones(n), x)                 # sigma ~ 1 + x
    β = [0.15, 0.35]
    bg = 0.35 .* randn(rng, G)
    bh = 0.25 .* randn(rng, H)
    η = [β[1] + β[2] * x[i] + bg[gidx[i]] + bh[hidx[i]] for i in 1:n]
    return (; rng, x, gidx, hidx, Xμ, Xσ, η, G, H, n)
end

@testset "#164 crossed covariate-σ — NB2 FD-vs-exact gate ≤ 1e-6" begin
    d = _crossed_hetero_design(seed = 5141)
    logsize = 1.3 .+ 0.55 .* d.x
    sz = exp.(logsize)
    μ = exp.(d.η)
    yint = [rand(d.rng, Distributions.NegativeBinomial(sz[i], sz[i] / (sz[i] + μ[i]))) for i in 1:d.n]
    yf = Float64.(yint)
    aux = _nb2_cross_hetero(yint, yf)

    # θ = [βμ(2); βσ(2); logσ_g; logσ_h], OFF the optimum.
    θ = [0.10, 0.40, 1.10, 0.50, log(0.40), log(0.30)]
    val, g_an, _, ok = DRM._crossed_mean_laplace_hetero_fg(
        Val(:nb2_hetero), aux, d.n, d.Xμ, d.Xσ, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
    @test ok && isfinite(val)
    g_fd = _cross_fd_grad(θ) do θp
        DRM._crossed_mean_laplace_hetero_fg(
            Val(:nb2_hetero), aux, d.n, d.Xμ, d.Xσ, d.gidx, d.G, d.hidx, d.H, θp; grad = false)[1]
    end
    @test maximum(abs.(g_an .- g_fd)) ≤ 1e-6
end

@testset "#164 crossed covariate-σ — Gamma FD-vs-exact gate ≤ 1e-6" begin
    d = _crossed_hetero_design(seed = 5142)
    logα = 1.4 .+ 0.45 .* d.x
    α = exp.(logα)
    μ = exp.(d.η)
    yv = Float64.([rand(d.rng, Distributions.Gamma(α[i], μ[i] / α[i])) for i in 1:d.n])
    aux = _gamma_cross_hetero(yv)

    θ = [0.10, 0.40, -0.70, -0.22, log(0.40), log(0.30)]
    val, g_an, _, ok = DRM._crossed_mean_laplace_hetero_fg(
        Val(:gamma_hetero), aux, d.n, d.Xμ, d.Xσ, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
    @test ok && isfinite(val)
    g_fd = _cross_fd_grad(θ) do θp
        DRM._crossed_mean_laplace_hetero_fg(
            Val(:gamma_hetero), aux, d.n, d.Xμ, d.Xσ, d.gidx, d.G, d.hidx, d.H, θp; grad = false)[1]
    end
    @test maximum(abs.(g_an .- g_fd)) ≤ 1e-6
end

@testset "#164 crossed covariate-σ — Beta FD-vs-exact gate ≤ 1e-4" begin
    d = _crossed_hetero_design(seed = 5143)
    logφ = 2.6 .+ 0.40 .* d.x
    φ = exp.(logφ)
    p = _logistic164.(d.η)
    yv = Float64.([clamp(rand(d.rng, Distributions.Beta(p[i] * φ[i], (1 - p[i]) * φ[i])), 1e-6, 1 - 1e-6) for i in 1:d.n])
    ylogit = log.(yv) .- log1p.(-yv)
    aux = _beta_cross_hetero(yv, ylogit)

    θ = [0.10, 0.40, -1.30, -0.20, log(0.40), log(0.30)]
    val, g_an, _, ok = DRM._crossed_mean_laplace_hetero_fg(
        Val(:beta_hetero), aux, d.n, d.Xμ, d.Xσ, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
    @test ok && isfinite(val)
    g_fd = _cross_fd_grad(θ) do θp
        DRM._crossed_mean_laplace_hetero_fg(
            Val(:beta_hetero), aux, d.n, d.Xμ, d.Xσ, d.gidx, d.G, d.hidx, d.H, θp; grad = false)[1]
    end
    @test maximum(abs.(g_an .- g_fd)) ≤ CROSS_BETA_TOL
end

@testset "#164 crossed covariate-σ — reduction invariant (1-col Xσ ⇒ scalar path)" begin
    d = _crossed_hetero_design(seed = 5151, n = 200)
    Xσ1 = ones(d.n, 1)
    μ = exp.(d.η)

    # NB2
    let
        sizep = 3.0
        yint = [rand(d.rng, Distributions.NegativeBinomial(sizep, sizep / (sizep + μ[i]))) for i in 1:d.n]
        yf = Float64.(yint)
        θ = [0.10, 0.40, -0.5 * log(sizep), log(0.40), log(0.30)]   # pσ = 1: shared layout
        vs, gs, _, oks = DRM._crossed_mean_laplace_nuisance_fg(
            Val(:nb2_fixed), _nb2_cross_scalar(yint, yf), d.n, d.Xμ, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
        vh, gh, _, okh = DRM._crossed_mean_laplace_hetero_fg(
            Val(:nb2_hetero), _nb2_cross_hetero(yint, yf), d.n, d.Xμ, Xσ1, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
        @test oks && okh
        @test vs ≈ vh atol = 1e-12
        @test gs ≈ gh atol = 1e-10
    end
    # Gamma
    let
        shape = 6.0
        yv = Float64.([rand(d.rng, Distributions.Gamma(shape, μ[i] / shape)) for i in 1:d.n])
        θ = [0.10, 0.40, -0.5 * log(shape), log(0.40), log(0.30)]
        vs, gs, _, oks = DRM._crossed_mean_laplace_nuisance_fg(
            Val(:gamma_fixed), _gamma_cross_scalar(yv), d.n, d.Xμ, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
        vh, gh, _, okh = DRM._crossed_mean_laplace_hetero_fg(
            Val(:gamma_hetero), _gamma_cross_hetero(yv), d.n, d.Xμ, Xσ1, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
        @test oks && okh
        @test vs ≈ vh atol = 1e-12
        @test gs ≈ gh atol = 1e-10
    end
    # Beta
    let
        φc = 20.0
        p = _logistic164.(d.η)
        yv = Float64.([clamp(rand(d.rng, Distributions.Beta(p[i] * φc, (1 - p[i]) * φc)), 1e-6, 1 - 1e-6) for i in 1:d.n])
        ylogit = log.(yv) .- log1p.(-yv)
        θ = [0.10, 0.40, -0.5 * log(φc), log(0.40), log(0.30)]
        vs, gs, _, oks = DRM._crossed_mean_laplace_nuisance_fg(
            Val(:beta_fixed), _beta_cross_scalar(yv, ylogit), d.n, d.Xμ, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
        vh, gh, _, okh = DRM._crossed_mean_laplace_hetero_fg(
            Val(:beta_hetero), _beta_cross_hetero(yv, ylogit), d.n, d.Xμ, Xσ1, d.gidx, d.G, d.hidx, d.H, θ; grad = true)
        @test oks && okh
        @test vs ≈ vh atol = 1e-12
        @test gs ≈ gh atol = 1e-10
    end
end

@testset "#164 crossed covariate-σ — drm() recovery NB2 (1 | g) + (1 | h)" begin
    rng = MersenneTwister(164514)
    G = 30; H = 25; n = 1200
    x = randn(rng, n)
    g = [Symbol("g", rand(rng, 1:G)) for _ in 1:n]
    h = [Symbol("h", rand(rng, 1:H)) for _ in 1:n]
    gmap = Dict(Symbol("g", j) => j for j in 1:G)
    hmap = Dict(Symbol("h", j) => j for j in 1:H)
    βμ = [0.20, 0.35]
    βσ = [1.30, 0.60]                       # log-size = 1.30 + 0.60 x
    σg = 0.40; σh = 0.30
    bg = σg .* randn(rng, G)
    bh = σh .* randn(rng, H)
    sz = exp.(βσ[1] .+ βσ[2] .* x)
    μ = exp.([βμ[1] + βμ[2] * x[i] + bg[gmap[g[i]]] + bh[hmap[h[i]]] for i in 1:n])
    y = Float64.([rand(rng, Distributions.NegativeBinomial(sz[i], sz[i] / (sz[i] + μ[i]))) for i in 1:n])

    fit = drm(bf(@formula(y ~ x + (1 | g) + (1 | h)), @formula(sigma ~ x)),
              NegBinomial2(); data = (; y, x, g, h))
    @test fit.converged
    @test length(coef(fit, :sigma)) == 2
    @test coef(fit, :mu)[2] ≈ βμ[2] atol = 0.15
    @test coef(fit, :sigma)[2] ≈ -0.5 * βσ[2] atol = 0.12   # log σ slope = -0.5 · log-size slope; band excludes 0
    @test re_sd(fit)[:g] > 0.10
    @test re_sd(fit)[:h] > 0.10
    @test isfinite(loglik(fit))
end

@testset "#164 crossed covariate-σ — drm() recovery Gamma + Beta (1 | g) + (1 | h)" begin
    rng = MersenneTwister(164515)
    G = 30; H = 25; n = 1200
    x = randn(rng, n)
    g = [Symbol("g", rand(rng, 1:G)) for _ in 1:n]
    h = [Symbol("h", rand(rng, 1:H)) for _ in 1:n]
    gmap = Dict(Symbol("g", j) => j for j in 1:G)
    hmap = Dict(Symbol("h", j) => j for j in 1:H)
    βμ = [0.20, 0.35]
    σg = 0.40; σh = 0.30
    bg = σg .* randn(rng, G)
    bh = σh .* randn(rng, H)
    μ = exp.([βμ[1] + βμ[2] * x[i] + bg[gmap[g[i]]] + bh[hmap[h[i]]] for i in 1:n])

    # Gamma: shape α = exp(1.6 + 0.5 x) ⇒ log σ slope = -0.25
    ασ = [1.60, 0.50]
    α = exp.(ασ[1] .+ ασ[2] .* x)
    yg = Float64.([rand(rng, Distributions.Gamma(α[i], μ[i] / α[i])) for i in 1:n])
    fit_g = drm(bf(@formula(yg ~ x + (1 | g) + (1 | h)), @formula(sigma ~ x)),
                Gamma(); data = (; yg, x, g, h))
    @test fit_g.converged
    @test length(coef(fit_g, :sigma)) == 2
    @test coef(fit_g, :sigma)[2] ≈ -0.5 * ασ[2] atol = 0.10   # band [-0.35,-0.15] excludes 0
    @test re_sd(fit_g)[:g] > 0.10
    @test re_sd(fit_g)[:h] > 0.10
    @test isfinite(loglik(fit_g))

    # Beta: precision φ = exp(2.8 + 0.5 x) ⇒ log σ slope = -0.25
    p = _logistic164.([βμ[1] + βμ[2] * x[i] + bg[gmap[g[i]]] + bh[hmap[h[i]]] for i in 1:n])
    φσ = [2.80, 0.50]
    φ = exp.(φσ[1] .+ φσ[2] .* x)
    yb = Float64.([clamp(rand(rng, Distributions.Beta(p[i] * φ[i], (1 - p[i]) * φ[i])), 1e-6, 1 - 1e-6) for i in 1:n])
    fit_b = drm(bf(@formula(yb ~ x + (1 | g) + (1 | h)), @formula(sigma ~ x)),
                Beta(); data = (; yb, x, g, h))
    @test fit_b.converged
    @test length(coef(fit_b, :sigma)) == 2
    @test coef(fit_b, :sigma)[2] ≈ -0.5 * φσ[2] atol = 0.12   # band [-0.37,-0.13] excludes 0
    @test re_sd(fit_b)[:g] > 0.10
    @test re_sd(fit_b)[:h] > 0.10
    @test isfinite(loglik(fit_b))
end
