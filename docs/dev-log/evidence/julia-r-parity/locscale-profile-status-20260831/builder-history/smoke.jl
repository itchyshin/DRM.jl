using DRM, Test, Random
import Distributions

Random.seed!(20_260_831)
G, m = 4, 8
n = G * m
species = repeat(1:G, inner=m)
x = repeat(range(-1.0, 1.0; length=m), G)
eta = 0.70 .+ 0.55 .* x .+ (0.16 .* randn(G))[species]
psi = 1.05 .+ (0.10 .* randn(G))[species]
y = [begin
    shape = exp(psi[i]); mu = exp(eta[i])
    Float64(rand(Distributions.Gamma(shape, mu / shape)))
end for i in 1:n]
fit = drm(
    bf(@formula(y ~ x + (1 | status_smoke | species)),
       @formula(sigma ~ 1 + (1 | status_smoke | species))),
    Gamma(); data=(; y, x, species),
)

@testset "canonical location-scale profile status smoke" begin
    result = profile_result(fit; parm=:mu => "x")
    @info "canonical location-scale profile smoke status" failed=result.failed
    @test length(result.ci) == length(result.stats) == length(result.endpoint_diagnostics) == 1
    stat = only(result.stats)
    diag = only(result.endpoint_diagnostics)
    @test (stat.param, stat.coef) == (diag.param, diag.coef)
    @test stat.lower_unbounded == diag.lower.unbounded
    @test stat.upper_unbounded == diag.upper.unbounded
    @test stat.lower_endpoint_failed == diag.lower.endpoint_failed
    @test stat.upper_endpoint_failed == diag.upper.endpoint_failed
    @test stat.evaluations == diag.lower.evaluations + diag.upper.evaluations
    @test stat.gradient_evaluations == diag.lower.gradient_evaluations +
                                      diag.upper.gradient_evaluations
    @test stat.bracket_expansions == diag.lower.bracket_expansions +
                                      diag.upper.bracket_expansions
    @test stat.root_iterations == diag.lower.root_iterations + diag.upper.root_iterations
    @test diag.lower.nuisance === nothing || diag.lower.nuisance.method == :lbfgs
    @test diag.upper.nuisance === nothing || diag.upper.nuisance.method == :lbfgs
    @test result.failed == Int(stat.lower_endpoint_failed || stat.upper_endpoint_failed)
    @test !isnan(diag.lower.residual) || diag.lower.endpoint_failed
    @test !isnan(diag.upper.residual) || diag.upper.endpoint_failed
end
