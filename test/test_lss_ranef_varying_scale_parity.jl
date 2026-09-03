# test_lss_ranef_varying_scale_parity.jl — #563 S10 (#609 item 2): the
# varying-scale Gaussian random-intercept cell (`bf(y ~ x + (1 | g), sigma ~ x)`,
# routed through `_fit_ranef_gaussian` in src/gaussian_ranef.jl) converges to an
# MLE that agrees with drmTMB's native TMB fit to ~1e-6 in coefficient space —
# invisible at the training rows, but amplifying past the `tools/
# parity_conditional_prediction.R` `varying_scale` cell's 4e-6 tolerance at the
# extrapolated newdata point x = 0.8 (max_abs_diff 1.086e-05, measured
# 2026-09-02; sizing note scratchpad/s10-varying-scale.md). This is an
# optimizer-stopping-rule gap, not a formula/estimand bug: `_fit_ranef_gaussian`'s
# own header comment ("WHY THIS ROUTE NEEDS NO n-SCALED CONVERGENCE FALLBACK")
# establishes this exact-Woodbury-marginal family has no inner-solve noise floor
# and, at this fixture's n = 144, enormous headroom below the default
# `g_tol = 1e-8` absolute gradient-norm stopping rule.
#
# Fixture: test/parity/lss-ranef-varying-scale/data.csv is the exact data.frame
# `tools/parity_conditional_prediction.R` builds from `set.seed(202608302L)`
# (same seed, same generator, same row-shuffle), exported once via:
#
#   Rscript -e '
#     library(drmTMB)
#     set.seed(202608302L)
#     labels <- c("z","a","m","b","x","c","w","d","v","e","u","f")
#     g <- factor(rep(labels, each = 12L), levels = c("unused", rev(sort(labels))))
#     n <- length(g); x <- runif(n, -1, 1)
#     b <- setNames(rnorm(length(labels), sd = 0.8), labels)
#     y <- 0.3 + 0.6*x + b[as.character(g)] + rnorm(n, sd = exp(-0.5 + 0.15*x))
#     dat <- data.frame(y, x, g)[sample.int(n), , drop = FALSE]
#     rownames(dat) <- NULL
#     write.csv(dat, "data.csv", row.names = FALSE)
#     fr <- drmTMB(bf(y ~ x + (1 | g), sigma ~ x), data = dat, engine = "tmb")
#     predict(fr, newdata = data.frame(x = c(-0.7, 0, 0.8)), dpar = "mu", type = "link")
#   '
#
# The R oracle newdata `mu` (link == response; identity link) below was obtained
# by exactly that run (drmTMB 0.7.0, TMB engine, `nlminb`), reproduced
# 2026-09-02 and cross-checked against the independent scout receipt
# scratchpad/s10-varying-scale.md's case `varying_scale` (identical to 17
# significant figures): [0.16722601256427541, 0.54702828036229934,
# 0.98108801498861242].
#
#   julia --project=. -e 'using DRM, Test; include("test/test_lss_ranef_varying_scale_parity.jl")'

module TestLssRanefVaryingScaleParity

using DRM
using Test
using LinearAlgebra
using ForwardDiff
using DelimitedFiles: readdlm

const FIXTURE = joinpath(@__DIR__, "parity", "lss-ranef-varying-scale", "data.csv")

function _load_fixture()
    raw, header = readdlm(FIXTURE, ','; header = true)
    cols = Symbol.(strip.(string.(vec(header))))
    j = Dict(cols[k] => k for k in eachindex(cols))
    y = Float64[parse(Float64, string(v)) for v in raw[:, j[:y]]]
    x = Float64[parse(Float64, string(v)) for v in raw[:, j[:x]]]
    g = String[strip(string(v), '"') for v in raw[:, j[:g]]]
    return (y = y, x = x, g = g)
end

const DAT = _load_fixture()
const GRID_X = [-0.7, 0.0, 0.8]

# drmTMB 0.7.0, engine = "tmb" (nlminb), obtained via the R command in the
# header comment above.
const R_ORACLE_NEWDATA_MU = [0.16722601256427541, 0.54702828036229934, 0.98108801498861242]
const PARITY_TOL = 4e-6

@testset "issue #563 S10 (#609): varying-scale ranef LSS parity at extrapolated newdata" begin
    @test length(DAT.y) == 144

    fit = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ x)), Gaussian(); data = DAT)
    @test fit.converged

    # The sharper, R-free statement: the returned optimum's true gradient norm
    # (not just Optim's internal g_tol-based `converged` flag) must be far
    # inside this exact-marginal family's measured headroom.
    g = ForwardDiff.gradient(fit.nll, fit.theta)
    @test norm(g) ≤ 1e-10

    βμ = coef(fit, :mu)
    @test length(βμ) == 2
    mu_newdata = βμ[1] .+ βμ[2] .* GRID_X   # identity link

    @test maximum(abs.(mu_newdata .- R_ORACLE_NEWDATA_MU)) < PARITY_TOL
end

end # module
