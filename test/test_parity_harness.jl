# test_parity_harness.jl — ALWAYS-ON smoke test for the R-parity MACHINERY.
#
# This is the CI verification that compare.jl + loadfixture.jl actually work: no
# R, no committed drmTMB fixtures, fast. It does NOT claim drmTMB parity — it
# proves the harness round-trips a DRM.jl fit against itself (self-consistency)
# and, critically, that it DETECTS a deliberate mismatch. Real drmTMB parity is
# the gated `runparity.jl` suite (DRM_PARITY_TESTS=1), fed by maintainer-
# generated fixtures (GENERATING.md).

using DRM
using Test, Random
using TOML

include("parity/compare.jl")
include("parity/loadfixture.jl")

@testset "parity harness (self-consistency, no R)" begin
    # --- tiny Gaussian location–scale fit (mirrors test_family_accessor.jl) ----
    Random.seed!(20260603)
    n = 400
    x = randn(n)
    y = 0.5 .- 0.8 .* x .+ exp.(-0.3 .+ 0.4 .* x) .* randn(n)
    data = (; y, x)

    fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = data)

    # --- drm_coef_named bridge: block layout → flat names --------------------
    named = drm_coef_named(fit)
    @test Set(keys(named)) ==
        Set(["mu_(Intercept)", "mu_x", "sigma_(Intercept)", "sigma_x"])

    # --- self-consistency expected (round-trips against itself) --------------
    self_expected = ParityExpected(;
        family = "gaussian",
        coef = named,
        loglik = loglik(fit),
        aic = -2 * loglik(fit) + 2 * dof(fit),
        df = dof(fit),
        n = nobs(fit))

    res_ok = compare_fit(fit, self_expected)
    @test res_ok.passed == true
    @test isempty(res_ok.failures)

    # --- perturbed expected: harness MUST detect the mismatch ----------------
    bad_coef = copy(named)
    bad_coef["mu_x"] += 1.0                       # bump one coefficient
    perturbed = ParityExpected(;
        family = "gaussian",
        coef = bad_coef,
        loglik = loglik(fit) + 10.0,              # bump loglik
        aic = -2 * loglik(fit) + 2 * dof(fit),    # leave aic at the true value
        df = dof(fit),
        n = nobs(fit))

    res_bad = compare_fit(fit, perturbed)
    @test res_bad.passed == false
    @test !isempty(res_bad.failures)
    # The offending quantities are named in the failure strings.
    @test any(f -> occursin("coef[mu_x]", f), res_bad.failures)
    @test any(f -> occursin("loglik", f), res_bad.failures)

    # --- round-trip the loaders (covers loadfixture.jl) ----------------------
    mktempdir() do dir
        # Write expected.toml in the README format.
        open(joinpath(dir, "expected.toml"), "w") do io
            println(io, "[fit]")
            println(io, "family = \"gaussian\"")
            println(io, "formula = \"y ~ 1 + x; sigma ~ 1 + x\"")
            println(io, "loglik = ", loglik(fit))
            println(io, "aic = ", -2 * loglik(fit) + 2 * dof(fit))
            println(io, "df = ", dof(fit))
            println(io, "n = ", nobs(fit))
            println(io)
            println(io, "[coef]")
            for k in sort!(collect(keys(named)))
                println(io, "\"", k, "\" = ", named[k])
            end
        end
        # Write data.csv with a header row.
        open(joinpath(dir, "data.csv"), "w") do io
            println(io, "y,x")
            for i in 1:n
                println(io, y[i], ",", x[i])
            end
        end

        loaded_exp = load_expected(dir)
        @test loaded_exp.family == "gaussian"
        @test loaded_exp.df == dof(fit)
        @test loaded_exp.n == nobs(fit)

        loaded_data = load_data(dir)
        @test Set(keys(loaded_data)) == Set((:y, :x))
        @test length(loaded_data.y) == n

        # Re-fit from the loaded data and compare against the loaded expected.
        refit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian();
            data = loaded_data)
        res_rt = compare_fit(refit, loaded_exp)
        @test res_rt.passed == true
    end
end
