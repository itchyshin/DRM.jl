# Canonical coupled location--scale marginal bootstrap contract.
# All fixtures are no-fit public-shaped DrmFits.  They isolate sampler mechanics
# from optimisation and keep the dense inverse below as a small independent
# test oracle only, never a production construction.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

function _locscale_bootstrap_public_fixture(kind::Symbol; structured::Bool)
    G = 4
    g = [40, 10, 30, 20, 10, 40, 20, 30,
         30, 20, 40, 10, 20, 30, 10, 40,
         40, 20, 30, 10, 10, 30, 20, 40]
    n = length(g)
    x = repeat([-0.8, -0.3, 0.2, 0.7], 6)
    Xmu = hcat(ones(n), x)
    Xpsi = hcat(ones(n), x)
    y, family, formula, data, obs_prop, trials = if kind === :gamma
        yy = [1.2 + 0.05 * i for i in 1:n]
        (yy, Gamma(),
         structured ? bf(@formula(y ~ x + (1 | bootstrap_pair | relmat(g))),
                         @formula(sigma ~ x + (1 | bootstrap_pair | relmat(g)))) :
                      bf(@formula(y ~ x + (1 | bootstrap_pair | g)),
                         @formula(sigma ~ x + (1 | bootstrap_pair | g))),
         (; y = yy, x, g), nothing, nothing)
    elseif kind === :nb2
        yy = Float64.([mod(i, 5) for i in 1:n])
        (yy, NegBinomial2(),
         structured ? bf(@formula(y ~ x + (1 | bootstrap_pair | relmat(g))),
                         @formula(sigma ~ x + (1 | bootstrap_pair | relmat(g)))) :
                      bf(@formula(y ~ x + (1 | bootstrap_pair | g)),
                         @formula(sigma ~ x + (1 | bootstrap_pair | g))),
         (; y = yy, x, g), nothing, nothing)
    elseif kind === :beta
        yy = [0.15 + 0.7 * ((i - 1) % 5) / 4 for i in 1:n]
        (yy, Beta(),
         structured ? bf(@formula(y ~ x + (1 | bootstrap_pair | relmat(g))),
                         @formula(sigma ~ x + (1 | bootstrap_pair | relmat(g)))) :
                      bf(@formula(y ~ x + (1 | bootstrap_pair | g)),
                         @formula(sigma ~ x + (1 | bootstrap_pair | g))),
         (; y = yy, x, g), nothing, nothing)
    elseif kind === :betabinomial
        ntr = fill(12.0, n)
        successes = Float64.([mod(3i, 11) + 1 for i in 1:n])
        failures = ntr .- successes
        yy = [(successes[i], ntr[i]) for i in 1:n]
        (yy, BetaBinomial(),
         structured ? bf(@formula(cbind(successes, failures) ~ x + (1 | bootstrap_pair | relmat(g))),
                         @formula(sigma ~ x + (1 | bootstrap_pair | relmat(g)))) :
                      bf(@formula(cbind(successes, failures) ~ x + (1 | bootstrap_pair | g)),
                         @formula(sigma ~ x + (1 | bootstrap_pair | g))),
         (; successes, failures, x, g), successes ./ ntr, ntr)
    else
        error("unsupported test family: $kind")
    end

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

    # Engine: [beta_mu; beta_psi; logL11, L21, logL22].
    theta = [0.25, 0.35, -0.15, 0.20, log(0.55), 0.31, log(0.42)]
    fitres = (; θ = theta, beta_mu = theta[1:2], beta_psi = theta[3:4],
              vcov = Matrix{Float64}(I, length(theta), length(theta)),
              nll = 0.0, converged = true)
    base = DRM._build_locscale_drmfit(Val(kind), family, fitres, y, Xmu, Xpsi,
        ["(Intercept)", "x"], ["(Intercept)", "x"], "g";
        obs_prop, trials)
    objective = DRM.LocScaleObjective(Val(kind), y, Xmu, Xpsi, gidx, G, Q;
                                      whitened = true)
    fit = DRM._withformula(DRM._withnll(base, objective), formula)
    return (; kind, fit, data, Q, K, structured, trials)
end

function _bootstrap_reference_effect(U, p, L, E)
    Bperm = UpperTriangular(U) \ E
    B = zeros(Float64, length(p), 2)
    B[p, :] = Bperm
    return B * transpose(L)
end

function _bootstrap_effect_map(U, p, L)
    G = length(p)
    out = zeros(Float64, 2G, 2G)
    for j in axes(out, 2)
        E = zeros(Float64, G, 2)
        E[j] = 1.0
        out[:, j] = vec(permutedims(_bootstrap_reference_effect(U, p, L, E)))
    end
    return out
end

function _bootstrap_reference_response(fx, state, rng)
    E = randn(rng, length(state.perm), 2)
    effects = _bootstrap_reference_effect(state.U, state.perm, state.L, E)
    eta = state.Xmu * state.beta_mu .+ effects[state.gidx, 1]
    psi = state.Xpsi * state.beta_psi .+ effects[state.gidx, 2]
    mu = fx.kind in (:gamma, :nb2) ? exp.(clamp.(eta, -30.0, 30.0)) :
                                      DRM._logistic.(clamp.(eta, -30.0, 30.0))
    sigma = exp.(clamp.(psi, fx.kind === :gamma ? -30.0 : -15.0,
                              fx.kind === :gamma ? 30.0 : 15.0))
    if fx.kind === :gamma
        return Float64[rand(rng, Distributions.Gamma(sigma[i], mu[i] / sigma[i]))
                       for i in eachindex(mu)]
    elseif fx.kind === :nb2
        r = @. 1 / (sigma * sigma)
        return Float64[rand(rng, Distributions.NegativeBinomial(r[i], r[i] / (r[i] + mu[i])))
                       for i in eachindex(mu)]
    elseif fx.kind === :beta
        phi = @. 1 / (sigma * sigma)
        return Float64[rand(rng, Distributions.Beta(clamp(mu[i], eps(), 1 - eps()) * phi[i],
            (1 - clamp(mu[i], eps(), 1 - eps())) * phi[i])) for i in eachindex(mu)]
    else
        phi = @. 1 / (sigma * sigma)
        ntr = round.(Int, fx.trials)
        return Float64[rand(rng, Distributions.BetaBinomial(ntr[i],
            clamp(mu[i], eps(), 1 - eps()) * phi[i],
            (1 - clamp(mu[i], eps(), 1 - eps())) * phi[i])) for i in eachindex(mu)]
    end
end

@testset "canonical location-scale marginal bootstrap simulator" begin
    # Both existing public forms were a retained red: i.i.d. returned nothing
    # through re_sd, while relmat raised during generic parsing.  Both now need a
    # callable before the bootstrap fallback can reach conditional simulate().
    for structured in (false, true)
        fx = _locscale_bootstrap_public_fixture(:gamma; structured)
        sim = structured ? DRM._marginal_simulator(fx.fit, fx.data; K = fx.K) :
                           DRM._marginal_simulator(fx.fit, fx.data)
        @test sim isa Function
    end

    # Force a nonidentity permutation independently of CHOLMOD's AMD choice on
    # the small public relmat covariance.  The dense target is test-only.
    fxp = _locscale_bootstrap_public_fixture(:gamma; structured = true)
    statep = DRM._ls_bootstrap_prepared_state(fxp.fit, fxp.data; K = fxp.K)
    p = [4, 3, 2, 1]
    @test p != collect(1:4)
    U = sparse(cholesky(Symmetric(Matrix(fxp.Q)[p, p])).U)
    forced = DRM._LSMarginalBootstrapState(statep.kind, statep.Xmu, statep.Xpsi,
        statep.gidx, U, p, statep.L, statep.beta_mu, statep.beta_psi)
    E = randn(MersenneTwister(20260914), 4, 2)
    @test DRM._ls_bootstrap_effect(forced, MersenneTwister(20260914)) ==
          _bootstrap_reference_effect(U, p, statep.L, E)
    target = kron(inv(Matrix(fxp.Q)), statep.L * transpose(statep.L))
    good = _bootstrap_effect_map(U, p, statep.L)
    @test good * transpose(good) ≈ target atol = 1e-12 rtol = 1e-12
    wrong_qsolve = _bootstrap_effect_map(sparse(Matrix(fxp.Q)[p, p]), p, statep.L)
    @test norm(wrong_qsolve * transpose(wrong_qsolve) - target) > 1e-6
    wrong_unpermuted = _bootstrap_effect_map(U, collect(1:4), statep.L)
    @test norm(wrong_unpermuted * transpose(wrong_unpermuted) - target) > 1e-6

    for (offset, kind) in enumerate((:gamma, :nb2, :beta, :betabinomial))
        @testset "$kind relmat draw" begin
            fx = _locscale_bootstrap_public_fixture(kind; structured = true)
            @test coef(fx.fit, :recov) == [log(0.55), log(0.42), 0.31]
            state = DRM._ls_bootstrap_prepared_state(fx.fit, fx.data; K = fx.K)
            sim = DRM._marginal_simulator(fx.fit, fx.data; K = fx.K)
            seed = 20_260_900 + offset
            expected = _bootstrap_reference_response(fx, state, MersenneTwister(seed))
            actual = sim(MersenneTwister(seed))
            @test actual == expected

            # Fresh closures and callers' RNGs own their own state.  Mutating a
            # returned response cannot alter a subsequent replicated draw.
            @test DRM._marginal_simulator(fx.fit, fx.data; K = fx.K)(MersenneTwister(seed)) == expected
            actual[1] = -999.0
            @test sim(MersenneTwister(seed)) == expected

            effects = DRM._ls_bootstrap_effect(state, MersenneTwister(seed))
            eta = state.Xmu * state.beta_mu .+ effects[state.gidx, 1]
            psi = state.Xpsi * state.beta_psi .+ effects[state.gidx, 2]
            eta_zero = state.Xmu * state.beta_mu
            psi_zero = state.Xpsi * state.beta_psi
            @test maximum(abs, eta .- state.Xmu * state.beta_mu) > 0
            @test maximum(abs, psi .- state.Xpsi * state.beta_psi) > 0
            @test maximum(abs, psi .- state.Xpsi * state.beta_psi .- effects[state.gidx, 2]) < 1e-13
            if kind in (:gamma, :nb2)
                @test maximum(abs, exp.(eta) .- exp.(eta_zero)) > 0
            else
                @test maximum(abs, DRM._logistic.(eta) .- DRM._logistic.(eta_zero)) > 0
            end
            @test maximum(abs, exp.(psi) .- exp.(psi_zero)) > 0

            if kind === :gamma
                @test all(>(0), expected)
            elseif kind === :nb2
                @test all(>=(0), expected) && all(isinteger, expected)
            elseif kind === :beta
                @test all(0 .< expected .< 1)
            else
                @test all(0 .<= expected .<= fx.trials) && all(isinteger, expected)
            end

            short = NamedTuple{keys(fx.data)}(map(v -> v[1:end-1], values(fx.data)))
            @test_throws ArgumentError DRM._ls_marginal_simulator(fx.fit, short; K = fx.K)
            if kind === :betabinomial
                changed = merge(fx.data, (; failures = fx.data.failures .+ 1.0))
                @test_throws ArgumentError DRM._ls_marginal_simulator(fx.fit, changed; K = fx.K)
            end
        end
    end
end
