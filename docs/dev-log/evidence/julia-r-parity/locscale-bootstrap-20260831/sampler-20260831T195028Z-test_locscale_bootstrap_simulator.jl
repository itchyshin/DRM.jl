# First red for the canonical coupled location--scale marginal bootstrap.
#
# No fit occurs here.  The public-shaped DrmFit is assembled from known engine
# parameters so the failure identifies the missing simulator route, rather than
# a fitter, convergence, or formula-parser problem.  The helper is intentionally
# small and reusable for the later four-family distribution contract.
using DRM
using Test, LinearAlgebra, SparseArrays

function _locscale_bootstrap_public_fixture()
    G = 4
    # Repeated, deliberately shuffled labels exercise the objective's stored
    # row map rather than a presumed sorted group order.
    g = [40, 10, 30, 20, 10, 40, 20, 30,
         30, 20, 40, 10, 20, 30, 10, 40,
         40, 20, 30, 10, 10, 30, 20, 40]
    n = length(g)
    x = repeat([-0.8, -0.3, 0.2, 0.7], 6)
    y = [1.2 + 0.05 * i for i in 1:n]
    Xmu = hcat(ones(n), x)
    Xpsi = hcat(ones(n), -x)
    gidx, Gfound = DRM._group_index(g)
    @assert Gfound == G

    # Sparse star precision: CHOLMOD's AMD ordering is non-identity, so a later
    # sampler must preserve its permutation while solving Q^-1/2 E.
    Q = sparse([4.0 1.0 1.0 1.0;
                1.0 2.0 0.0 0.0;
                1.0 0.0 2.0 0.0;
                1.0 0.0 0.0 2.0])
    theta_engine = [0.25, 0.35, -0.15, 0.20, log(0.55), 0.31, log(0.42)]
    fitres = (; theta = theta_engine, beta_mu = theta_engine[1:2],
              beta_psi = theta_engine[3:4],
              vcov = Matrix{Float64}(I, length(theta_engine), length(theta_engine)),
              nll = 0.0, converged = true)
    formula = bf(@formula(y ~ x + (1 | bootstrap_pair | g)),
                 @formula(sigma ~ x + (1 | bootstrap_pair | g)))
    base = DRM._build_locscale_drmfit(Val(:gamma), Gamma(), fitres, y, Xmu, Xpsi,
        ["(Intercept)", "x"], ["(Intercept)", "x"], "g")
    objective = DRM.LocScaleObjective(Val(:gamma), y, Xmu, Xpsi, gidx, G, Q;
                                      whitened = true)
    fit = DRM._withformula(DRM._withnll(base, objective), formula)
    return (; fit, data = (; y, x, g), Q)
end

@testset "canonical location-scale marginal bootstrap simulator" begin
    fx = _locscale_bootstrap_public_fixture()
    @test fx.fit.nll isa DRM.LocScaleObjective
    @test coef(fx.fit, :recov) == [log(0.55), log(0.42), 0.31]
    Fq = cholesky(Symmetric(fx.Q))
    @test sort(collect(Fq.p)) == collect(1:4)
    @test collect(Fq.p) != collect(1:4)

    # Red against the current generic route: it looks for re_sd, finds none on
    # this coupled public DrmFit, and returns `nothing`.  The expected result is
    # a callable that will later draw both axes from objective.Q and :recov.
    simulator = DRM._marginal_simulator(fx.fit, fx.data)
    @test simulator isa Function
end
