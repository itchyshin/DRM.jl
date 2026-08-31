# First red for the canonical coupled location--scale marginal bootstrap.
#
# No fit occurs here.  The public-shaped DrmFit is assembled from known engine
# parameters so the failure identifies the missing simulator route, rather than
# a fitter, convergence, or formula-parser problem.  The helper is intentionally
# small and reusable for the later four-family distribution contract.
using DRM
using Test, LinearAlgebra, SparseArrays

function _locscale_bootstrap_public_fixture(; structured::Bool)
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
    Xpsi = hcat(ones(n), x)

    # The relmat path uses a non-diagonal precision.  Its explicit-permutation
    # oracle belongs to the later private-draw test: AMD may legitimately choose
    # identity after this small dense covariance is inverted.
    Qstar = [4.0 1.0 1.0 1.0;
             1.0 2.0 0.0 0.0;
             1.0 0.0 2.0 0.0;
             1.0 0.0 0.0 2.0]
    K = if structured
        Craw = inv(Qstar)
        d = sqrt.(diag(Craw))
        Craw ./ (d * d')
    else
        nothing
    end
    Q, gidx, Gfound = structured ? DRM._locscale_relmat_setup(K, g) :
                                     (sparse(1.0I, G, G), DRM._group_index(g)...)
    @assert Gfound == G
    theta_engine = [0.25, 0.35, -0.15, 0.20, log(0.55), 0.31, log(0.42)]
    fitres = (; θ = theta_engine, beta_mu = theta_engine[1:2],
              beta_psi = theta_engine[3:4],
              vcov = Matrix{Float64}(I, length(theta_engine), length(theta_engine)),
              nll = 0.0, converged = true)
    formula = structured ?
        bf(@formula(y ~ x + (1 | bootstrap_pair | relmat(g))),
           @formula(sigma ~ x + (1 | bootstrap_pair | relmat(g)))) :
        bf(@formula(y ~ x + (1 | bootstrap_pair | g)),
           @formula(sigma ~ x + (1 | bootstrap_pair | g)))
    base = DRM._build_locscale_drmfit(Val(:gamma), Gamma(), fitres, y, Xmu, Xpsi,
        ["(Intercept)", "x"], ["(Intercept)", "x"], "g")
    objective = DRM.LocScaleObjective(Val(:gamma), y, Xmu, Xpsi, gidx, G, Q;
                                      whitened = true)
    fit = DRM._withformula(DRM._withnll(base, objective), formula)
    return (; fit, data = (; y, x, g), Q, K, structured)
end

@testset "canonical location-scale marginal bootstrap simulator" begin
    for structured in (false, true)
        label = structured ? "relmat" : "i.i.d."
        @testset "$label coupled public fit" begin
            fx = _locscale_bootstrap_public_fixture(; structured)
            @test fx.fit.nll isa DRM.LocScaleObjective
            @test coef(fx.fit, :recov) == [log(0.55), log(0.42), 0.31]
            if structured
                Qcheck, gidxcheck, Gcheck = DRM._locscale_relmat_setup(fx.K, fx.data.g)
                @test Gcheck == 4
                @test gidxcheck == (fx.fit.nll::DRM.LocScaleObjective).gidx
                @test Qcheck ≈ fx.Q
                @test fx.K ≈ inv(Matrix(fx.Q))
            else
                @test fx.Q == sparse(1.0I, 4, 4)
            end

            # The current generic route is unsupported in both forms: i.i.d.
            # returns no callable through `re_sd`, and relmat currently throws
            # while parsing the coupled structured group.  Catching that error
            # as a value keeps this a capability red, not a test support error.
            simulator = try
                structured ? DRM._marginal_simulator(fx.fit, fx.data; K = fx.K) :
                             DRM._marginal_simulator(fx.fit, fx.data)
            catch err
                err
            end
            @test simulator isa Function
        end
    end
end
