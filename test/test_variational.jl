# VA scaffold (#136): the method-selection surface exists and the unimplemented
# kernel errors clearly. Numerical anchor gates are @test_skip until the kernels land.
using DRM
using Test

@testset "VA marginal scaffold (#136)" begin
    @test DRM.Laplace() isa DRM.MarginalMethod
    @test DRM.Variational() isa DRM.MarginalMethod
    @test DRM._marginal_method(:LA) == DRM.Laplace()
    @test DRM._marginal_method(:va) == DRM.Variational()   # case-insensitive
    @test_throws ArgumentError DRM._marginal_method(:nope)
    # the VA kernel is not implemented yet — must error, mentioning #136
    err = try; DRM._fit_va(); catch e; e; end
    @test err isa ErrorException && occursin("136", err.msg)

    # Deterministic anchor gates (from GLLVM.jl) — enable when kernels land:
    @test_skip "RE variance -> 0 : ELBO equals the independent log-likelihood"
    @test_skip "ELBO <= dense-quadrature marginal at low latent dimension"
    @test_skip "family limit: NB r -> Inf reproduces Poisson-VA"
end
