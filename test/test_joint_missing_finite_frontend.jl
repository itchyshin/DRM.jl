using DRM
using Test
using LinearAlgebra
using TOML

struct _FiniteFrontendCategory
    label::String
end

# Root owns all Julia invocations.  This file exercises the public formula
# admission against the generated native payload, rather than including a
# source file or inventing a second numerical fixture.
const _finite_frontend_reference = TOML.parsefile(joinpath(@__DIR__, "..", "docs", "dev-log", "evidence",
    "julia-r-parity", "finite-state", "finite-reference-003.toml"))

function _finite_frontend_data(reference)
    levels = String.(reference["levels"])
    y = Union{Missing,Float64}[reference["observed_y"][i] ? Float64(reference["y"][i]) : missing
                               for i in eachindex(reference["y"])]
    x = Union{Missing,String}[reference["observed_x"][i] ? levels[reference["x"][i]] : missing
                               for i in eachindex(reference["x"])]
    return (; y, x, z = Float64.(reference["z"])), levels
end

function _finite_frontend_state_design(reference)
    n, K = reference["n"], reference["K"]
    rows = reduce(vcat, [permutedims(Float64.(row)) for row in reference["state_design"]])
    p = size(rows, 2)
    state = Array{Float64}(undef, n, K, p)
    for i in 1:n, k in 1:K
        state[i, k, :] .= rows[(i - 1) * K + k, :]
    end
    return state
end

@testset "finite-state direct formula frontend API and ordinal payload design" begin
    BLAS.set_num_threads(1)
    @test BLAS.get_num_threads() == 1
    @test isdefined(DRM, :JointFiniteDrmFit)
    @test isdefined(DRM, :CategoricalLogit)

    reference = _finite_frontend_reference["ordinal"]
    data, levels = _finite_frontend_data(reference)
    @test Set(zip(reference["observed_y"], reference["observed_x"])) ==
          Set((y, x) for y in (false, true) for x in (false, true))
    ctl = DRM.miss_control(response = "include", predictor = "model")
    form = DRM.bf(@formula(y ~ z + mi(x)), @formula(sigma ~ 1))
    specification = (x = DRM.impute_model(@formula(x ~ z);
        family = DRM.CumulativeLogit(), levels = levels),)

    fit = drm(form, DRM.Gaussian(); data = data, impute = specification,
              missing = ctl, g_tol = 1e-8)
    @test fit isa DRM.JointFiniteDrmFit
    @test fit.variable === :x
    @test fit.prepared.prepared.predictor === :ordinal
    @test fit.prepared.prepared.levels == levels
    @test fit.prepared.prepared.original_row == reference["original_row"]
    @test fit.prepared.prepared.observed_y == BitVector(reference["observed_y"])
    @test fit.prepared.prepared.observed_x == BitVector(reference["observed_x"])
    @test fit.prepared.prepared.X_mu_state ≈ _finite_frontend_state_design(reference) atol = 2e-14
    @test fit.prepared.prepared.Xpredictor ≈ reshape(data.z, :, 1) atol = 0
    @test DRM.nobs(fit) == count(identity, reference["observed_y"])
    @test DRM.family(fit) isa DRM.Gaussian
    @test DRM.niterations(fit) >= 0
    @test isfinite(DRM.loglik(fit))
    @test length(DRM.coef(fit)) == 8
    @test length(DRM.coef(fit, :mu)) == 4
    @test length(DRM.coef(fit, :mi_x)) == 1
    @test length(DRM.coef(fit, :rawcut_x)) == 2
    cuts = DRM.cutpoints(fit)
    @test cuts[1] == DRM.coef(fit, :rawcut_x)[1]
    @test cuts[2] > cuts[1]
    @test size(DRM.vcov(fit)) == (8, 8) # raw alpha/cut coordinates
    @test DRM.vcov(fit) == DRM.vcov(fit.prepared.fit)
    @test length(DRM.fitted(fit)) == reference["n"]
    @test DRM.joint_missing_summary(fit).conditional_probabilities ≈
          DRM.joint_missing_summary(fit.prepared).conditional_probabilities

    imp = DRM.imputed(fit; variable = "x", rows = :all)
    @test imp.variable == fill("x", reference["n"])
    @test imp.original_row == reference["original_row"]
    @test imp.observed == BitVector(reference["observed_x"])
    @test all(ismissing, imp.std_error[imp.observed])
    @test all(==("conditional_expected_score"), imp.source[.!imp.observed])
    @test_throws ArgumentError DRM.imputed(fit; variable = :other)
end

@testset "finite-state contrast construction and marker ordering" begin
    K5 = DRM._joint_finite_polynomials(5)
    @test K5' * K5 ≈ Matrix{Float64}(I, 4, 4) atol = 2e-14
    @test vec(sum(K5; dims = 1)) ≈ zeros(4) atol = 2e-14
    @test all(>(0), K5[end, :])
    high = DRM._joint_finite_polynomials(12)
    @test high' * high ≈ Matrix{Float64}(I, 11, 11) atol = 2e-12

    fixed = [1.0 0.25; 1.0 -0.5]
    state, names = DRM._joint_finite_state_design(fixed, :x,
        ["one", "two", "three", "four", "five"], :ordinal; insertion = 1)
    @test names == ["mi(x).L", "mi(x).Q", "mi(x).C", "mi(x)^4"]
    @test state[1, 1, 1] == fixed[1, 1]
    @test state[1, 1, end] == fixed[1, 2]
    for predictor in (:ordinal, :categorical)
        nointercept, full_names = DRM._joint_finite_state_design(zeros(2, 0), :x,
            ["one", "two", "three"], predictor; full_states = true)
        @test size(nointercept) == (2, 3, 3)
        @test nointercept[1, :, :] == Matrix{Float64}(I, 3, 3)
        @test full_names == ["mi(x)one", "mi(x)two", "mi(x)three"]
    end

    reference = _finite_frontend_reference["ordinal"]
    data, _ = _finite_frontend_data(reference)
    marker_first = DRM.bf(@formula(y ~ mi(x) + z), @formula(sigma ~ 1))
    marker_last = DRM.bf(@formula(y ~ z + mi(x)), @formula(sigma ~ 1))
    @test DRM._joint_finite_mean_insertion(marker_first, data) == 1
    @test DRM._joint_finite_mean_insertion(marker_last, data) == 2
    nointercept_marker = DRM.bf(@formula(y ~ 0 + z + mi(x)), @formula(sigma ~ 1))
    @test DRM._joint_finite_mean_insertion(nointercept_marker, data) == 1
end

@testset "finite-state categorical direct formula frontend" begin
    reference = _finite_frontend_reference["categorical"]
    data, levels = _finite_frontend_data(reference)
    ctl = DRM.miss_control(response = "include", predictor = "model")
    form = DRM.bf(@formula(y ~ z + mi(x)), @formula(sigma ~ 1))
    fit = drm(form, DRM.Gaussian(); data = data,
        impute = (x = DRM.impute_model(@formula(x ~ 1);
            family = DRM.CategoricalLogit(), levels = levels),),
        missing = ctl, g_tol = 1e-8)

    @test fit isa DRM.JointFiniteDrmFit
    @test fit.prepared.prepared.predictor === :categorical
    @test fit.prepared.prepared.levels == levels
    @test size(fit.prepared.prepared.Xpredictor, 2) == 1 # categorical intercept is valid
    @test length(DRM.coef(fit, :mi_x)) == length(levels) - 1
    @test_throws ArgumentError DRM.coef(fit, :rawcut_x)
    @test_throws ArgumentError DRM.cutpoints(fit)
    @test DRM.fitted(fit) == DRM.fitted(fit.prepared.fit)
    imp = DRM.imputed(fit; rows = :all)
    @test all(ismissing, imp.std_error[.!imp.observed])
    @test all(==("conditional_modal_category"), imp.source[.!imp.observed])

    nointercept = DRM.bf(@formula(y ~ 0 + z + mi(x)), @formula(sigma ~ 1))
    nointercept_fit = drm(nointercept, DRM.Gaussian(); data = data,
        impute = (x = DRM.impute_model(@formula(x ~ 1);
            family = DRM.CategoricalLogit(), levels = levels),),
        missing = ctl, g_tol = 1e-8)
    @test size(nointercept_fit.prepared.prepared.X_mu_state, 3) == 4
    @test nointercept_fit.prepared.prepared.X_mu_state[1, :, 2:4] == Matrix{Float64}(I, 3, 3)
end

@testset "finite-state direct frontend admission guards" begin
    reference = _finite_frontend_reference["ordinal"]
    data, levels = _finite_frontend_data(reference)
    ctl = DRM.miss_control(response = "include", predictor = "model")
    form = DRM.bf(@formula(y ~ z + mi(x)), @formula(sigma ~ 1))
    ordinal = DRM.impute_model(@formula(x ~ z); family = DRM.CumulativeLogit(), levels = levels)
    categorical = DRM.impute_model(@formula(x ~ 1); family = DRM.CategoricalLogit(), levels = levels)

    # Bare, additive marker only; all fixed designs must be exogenous and complete.
    @test_throws ArgumentError drm(DRM.bf(@formula(y ~ z * mi(x)), @formula(sigma ~ 1)), DRM.Gaussian();
        data = data, impute = (x = ordinal,), missing = ctl)
    @test_throws ArgumentError drm(DRM.bf(@formula(y ~ z + mi(x)), @formula(sigma ~ mi(x))), DRM.Gaussian();
        data = data, impute = (x = ordinal,), missing = ctl)
    @test_throws ArgumentError drm(DRM.bf(@formula(y ~ x + mi(x)), @formula(sigma ~ 1)), DRM.Gaussian();
        data = data, impute = (x = ordinal,), missing = ctl)
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = data,
        impute = (x = DRM.impute_model(@formula(x ~ y); family = DRM.CumulativeLogit(), levels = levels),), missing = ctl)
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = data,
        impute = (x = DRM.impute_model(@formula(x ~ z); family = DRM.CumulativeLogit()),), missing = ctl)
    inferred_categorical = DRM.impute_model(@formula(x ~ z); family = DRM.CategoricalLogit())
    @test inferred_categorical.levels === nothing # sorted deterministically at direct admission
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = data,
        impute = (x = DRM.impute_model(@formula(x ~ z); family = DRM.Binomial()),), missing = ctl)
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = data,
        impute = (x = categorical,), missing = DRM.miss_control(predictor = "fail"))
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = data,
        impute = (x = ordinal,), missing = ctl, method = :REML)

    # A finite state model is intentional missing-predictor admission: unlike
    # the older fully-observed Gaussian/Bernoulli formula routes, it requires a
    # real missing x row and every declared level among observed x rows.
    complete = (; y = Float64.(coalesce.(data.y, 0.0)),
                 x = String.(coalesce.(data.x, levels[1])), z = data.z)
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = complete,
        impute = (x = ordinal,), missing = ctl)
    missing_level = (; y = data.y, x = Union{Missing,String}[v === "high" ? "medium" : v for v in data.x], z = data.z)
    @test_throws ArgumentError drm(form, DRM.Gaussian(); data = missing_level,
        impute = (x = ordinal,), missing = ctl)

    # Ordered numeric codes need no label declaration; the ordinary predictor
    # intercept is removed for ordinal models, so `x ~ 1` is q = 0.
    numeric = (; y = data.y, x = Union{Missing,Int}[ismissing(v) ? missing : findfirst(==(v), levels) for v in data.x], z = data.z)
    q0 = drm(form, DRM.Gaussian(); data = numeric,
        impute = (x = DRM.impute_model(@formula(x ~ 1); family = DRM.CumulativeLogit()),), missing = ctl,
        g_tol = 1e-8)
    @test q0 isa DRM.JointFiniteDrmFit
    @test size(q0.prepared.prepared.Xpredictor, 2) == 0
    @test DRM.impute_model(@formula(x ~ z); family = DRM.CumulativeLogit(), levels = [1, 2, 3]).levels == ["1", "2", "3"]
    @test DRM._joint_finite_levels(DRM.impute_model(@formula(x ~ 1); family = DRM.CumulativeLogit()),
        Union{Missing,Float64}[1.0, 2.0, missing, 3.0], :x) == ["1", "2", "3"]
    inferred_numeric_categorical = DRM.impute_model(@formula(x ~ 1); family = DRM.CategoricalLogit())
    @test DRM._joint_finite_levels(inferred_numeric_categorical,
        Union{Missing,Float64}[Float64(i) for i in 1:12], :x) == string.(1:12)
    @test_throws ArgumentError DRM._joint_finite_levels(inferred_numeric_categorical,
        Union{Missing,Float64}[1.0, 2.0, 4.0], :x)
    @test_throws ArgumentError DRM._joint_finite_levels(inferred_numeric_categorical,
        Union{Missing,Float64}[1.0, 2.0, 2.5], :x)
    @test_throws ArgumentError DRM._joint_finite_levels(inferred_numeric_categorical,
        Union{Missing,Float64}[1.0, 2.0, Inf], :x)
    @test_throws ArgumentError DRM._joint_finite_levels(inferred_numeric_categorical,
        Union{Missing,Float64}[1.0, 2.0, 1.0e9], :x)
    @test_throws ArgumentError DRM._joint_finite_levels(DRM.impute_model(@formula(x ~ 1);
        family = DRM.CumulativeLogit()), Union{Missing,Float64}[1.0, 2.0, 4.0], :x)

    # No mean intercept changes the finite state design to K full indicators.
    nointercept = DRM.bf(@formula(y ~ 0 + z + mi(x)), @formula(sigma ~ 1))
    nointercept_fit = drm(nointercept, DRM.Gaussian(); data = data,
        impute = (x = DRM.impute_model(@formula(x ~ z); family = DRM.CumulativeLogit(), levels = levels),),
        missing = ctl, g_tol = 1e-8)
    @test size(nointercept_fit.prepared.prepared.X_mu_state, 3) == 4
    @test nointercept_fit.prepared.prepared.X_mu_state[1, :, 2:4] == Matrix{Float64}(I, 3, 3)

    factor_data = merge(data, (; habitat = repeat(["dry", "wet", "bog"], 60)))
    nointercept_factor = DRM.bf(@formula(y ~ 0 + habitat + mi(x)), @formula(sigma ~ 1))
    nointercept_factor_first = DRM.bf(@formula(y ~ 0 + mi(x) + habitat), @formula(sigma ~ 1))
    # Native no-intercept coding gives the first categorical term its full
    # indicators and later factors treatment contrasts. Thus habitat-first has
    # mi(x) treatment columns, while marker-first has full mi(x) indicators.
    factor_fit = drm(nointercept_factor, DRM.Gaussian(); data = factor_data,
        impute = (x = ordinal,), missing = ctl, g_tol = 1e-8)
    factor_first_fit = drm(nointercept_factor_first, DRM.Gaussian(); data = factor_data,
        impute = (x = ordinal,), missing = ctl, g_tol = 1e-8)
    @test size(factor_fit.prepared.prepared.X_mu_state, 3) == 5
    @test size(factor_first_fit.prepared.prepared.X_mu_state, 3) == 5
end

println("FINITE_JOINT_FRONTEND_TEST_READY")
