# Canonical location-scale profile jobs are independent across coefficients, but
# each coefficient retains its serial lower/upper warm-start chain.  This small
# public fit keeps the test below the slow full-vector profile fixture.
using DRM
using Test, Random, LinearAlgebra
import Distributions

function _locscale_profile_threads_fixture()
    Random.seed!(20_260_831)
    # Gamma has a smooth positive-response likelihood and the deliberately
    # separated fixed and group effects make both mean coefficients identifiable
    # in this compact profile fixture.
    G, m = 4, 8
    n = G * m
    species = repeat(1:G, inner=m)
    x = repeat(range(-1.0, 1.0; length=m), G)
    re_mu = 0.16 .* randn(G)
    re_sigma = 0.10 .* randn(G)
    eta = 0.70 .+ 0.55 .* x .+ re_mu[species]
    psi = 1.05 .+ re_sigma[species]
    y = [begin
        shape = exp(psi[i])
        mu = exp(eta[i])
        Float64(rand(Distributions.Gamma(shape, mu / shape)))
    end for i in 1:n]
    fit = drm(
        bf(
            @formula(y ~ x + (1 | profile_thread | species)),
            @formula(sigma ~ 1 + (1 | profile_thread | species)),
        ),
        Gamma();
        data=(; y, x, species),
    )
    @test fit.nll isa DRM.LocScaleObjective
    return fit
end



@assert Threads.nthreads()==4 && BLAS.get_num_threads()==1
fit = _locscale_profile_threads_fixture()
o=fit.nll
data=(; y=copy(o.y), x=copy(o.Xμ[:,2]), species=copy(o.gidx))
seed=first(rand(MersenneTwister(4001),UInt,2))
yb=DRM._marginal_simulator(fit,data)(MersenneTwister(seed))
datab=DRM._bootstrap_data(fit.formula,data,yb)
f = drm(fit.formula,fit.family;data=datab)
println("FAILED_REPLAY seed=",seed," raw_converged=",f.converged," nondegenerate=",DRM._nondegenerate_fit(f)," theta=",repr(f.theta));flush(stdout)
o=f.nll;p=size(o.Xμ,2)+size(o.Xψ,2)
t=vcat(f.theta[1:p],f.theta[p+1],f.theta[p+3],f.theta[p+2])
e=DRM._ls_whitened_eval(o.kind,o.y,o.Xμ,o.Xψ,o.gidx,o.G,o.Q,t,DRM._ls_canonical_Zeta(length(o.y)),DRM._ls_canonical_Zpsi(length(o.y)))
println("FAILED_DIAGNOSTICS value=",e.value," gradient=",repr(e.gradient)," status=",repr(e.status));flush(stdout)
println("LOCSCALE_FAILED_REFIT_DIAGNOSED")
