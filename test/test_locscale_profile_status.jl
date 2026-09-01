# Failure disclosure for canonical location-scale profile roots. These controls
# are deliberately pure: the root finder must not turn an iteration limit or a
# failed trial into a plausible finite confidence-limit coordinate.
using DRM
using Test, SparseArrays, LinearAlgebra, Random
import Distributions

function _ls_profile_status_smoke_fit()
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
    return drm(
        bf(@formula(y ~ x + (1 | status_smoke | species)),
           @formula(sigma ~ 1 + (1 | status_smoke | species))),
        Gamma(); data=(; y, x, species),
    )
end

@testset "location-scale profile endpoint status" begin
    @testset "legacy and structured CI helpers retain doc bindings" begin
        docs = Base.Docs.meta(DRM)
        @test haskey(docs, Base.Docs.Binding(DRM, :_ls_profile_ci))
        @test haskey(docs, Base.Docs.Binding(DRM, :_ls_profile_ci_result))
    end

    quadratic(t) = (t^2 - 1.0, 2.0 * t, true)

    @testset "iteration limits are not certified endpoints" begin
        # Thirty Newton updates from 1e20 still leave t around 9e10. The old
        # scalar helper returned that unevaluated/non-root value as an endpoint.
        exhausted = DRM._ls_profile_root_result(quadratic, 0.0; dir=1.0, init=1e20)
        @test !exhausted.accepted
        @test exhausted.endpoint_failed
        @test !exhausted.unbounded
        @test exhausted.reason == :max_iterations
        @test exhausted.value == Inf
        @test exhausted.candidate > 1e9
        @test exhausted.residual > 1e18

        # A forced zero-iteration refinement preserves the last *evaluated*
        # bracket candidate and its residual for diagnostics rather than calling
        # it a root.
        stuck(t) = (3.0, NaN, true)
        forced = DRM._ls_profile_root_result(
            stuck, 0.0; dir=1.0, init=2.0, maxnewton=0,
        )
        @test !forced.accepted
        @test forced.endpoint_failed
        @test !forced.unbounded
        @test forced.reason == :max_iterations
        @test forced.value == Inf
        @test forced.candidate == 2.0
        @test forced.residual == 3.0
    end

    @testset "valid roots and no-crossing remain distinct" begin
        accepted = DRM._ls_profile_root_result(quadratic, 0.0; dir=1.0, init=2.0)
        @test accepted.accepted
        @test !accepted.endpoint_failed
        @test !accepted.unbounded
        @test accepted.reason == :accepted
        @test abs(accepted.residual) < 1e-7
        @test DRM._ls_profile_root(quadratic, 0.0; dir=1.0, init=2.0) == accepted.value

        # Diagnostics expose the evaluated parameter coordinate, rather than the
        # internal positive displacement from the fitted value.
        centered(x) = ((x - 3.0)^2 - 1.0, 2.0 * (x - 3.0), true)
        shifted = DRM._ls_profile_root_result(centered, 3.0; dir=-1.0, init=2.0)
        @test shifted.accepted
        @test isapprox(shifted.value, 2.0; atol=1e-7, rtol=0)
        @test shifted.candidate == shifted.value
        @test abs(shifted.residual) < 1e-7

        # A callback may provide no usable slope; guarded bisection remains a
        # valid route to a certified evaluated root.
        no_slope(t) = (t^2 - 1.0, NaN, true)
        bisection = DRM._ls_profile_root_result(no_slope, 0.0; dir=1.0, init=2.0)
        @test bisection.accepted
        @test !bisection.endpoint_failed

        flat(t) = (-1.0, 0.0, true)
        nocross = DRM._ls_profile_root_result(flat, 0.0; dir=1.0, init=1.0)
        @test !nocross.accepted
        @test !nocross.endpoint_failed
        @test nocross.unbounded
        @test nocross.reason == :no_crossing
        @test nocross.value == Inf

        invalid_budget = DRM._ls_profile_root_result(flat, 0.0; dir=1.0, init=1.0,
                                                      maxexpand=0)
        @test invalid_budget.endpoint_failed
        @test !invalid_budget.unbounded
        @test invalid_budget.reason == :invalid_search_budget

        failed_trial(t) = (NaN, NaN, false)
        failed = DRM._ls_profile_root_result(failed_trial, 0.0; dir=1.0, init=1.0)
        @test !failed.accepted
        @test failed.endpoint_failed
        @test !failed.unbounded
        @test failed.reason == :evaluation_failed
        @test failed.reason != :max_iterations

        # The first bracket point is valid; a later refinement trial fails.
        refinement_failure(t) = t == 1.0 ? (NaN, NaN, false) : (t^2 - 1.0, NaN, true)
        refined = DRM._ls_profile_root_result(refinement_failure, 0.0; dir=1.0, init=2.0)
        @test refined.endpoint_failed
        @test !refined.unbounded
        @test refined.reason == :evaluation_failed
        @test refined.root_iterations == 1
        @test refined.bracket_expansions == 0
        @test refined.evaluations == 2

        interrupted(t) = throw(InterruptException())
        @test_throws InterruptException DRM._ls_profile_root_result(
            interrupted, 0.0; dir=1.0, init=1.0,
        )

        callback_error(t) = throw(DomainError(t, "test evaluation failure"))
        ordinary_error = DRM._ls_profile_root_result(callback_error, 0.0; dir=1.0, init=1.0)
        @test ordinary_error.endpoint_failed
        @test !ordinary_error.unbounded
        @test ordinary_error.reason == :exception

        zero_gap(t) = (0.0, 0.0, true)
        nonfinite_init = DRM._ls_profile_root_result(zero_gap, 0.0; dir=1.0, init=Inf)
        @test nonfinite_init.endpoint_failed
        @test !nonfinite_init.accepted
        @test !nonfinite_init.unbounded
        @test nonfinite_init.reason == :nonfinite_initialization
        nonfinite_origin = DRM._ls_profile_root_result(zero_gap, Inf; dir=1.0, init=1.0)
        @test nonfinite_origin.endpoint_failed
        @test !nonfinite_origin.accepted
        @test nonfinite_origin.reason == :nonfinite_initialization
        overflow = DRM._ls_profile_root_result(zero_gap, floatmax(Float64);
                                                dir=1.0, init=floatmax(Float64))
        @test overflow.endpoint_failed
        @test !overflow.accepted
        @test overflow.reason == :nonfinite_candidate
    end

    @testset "absolute-NLL cancellation cannot certify a root" begin
        shift = 1e16
        half = 1.920729410347062
        rounded(t) = begin
            reference = DRM._profile_reference_difference(shift + t^2, shift)
            (gap=reference.difference - half, slope=2.0 * t,
             ok=reference.status === :accepted, cancellation=reference.cancellation)
        end
        reference = DRM._profile_reference_difference(shift + 1.6^2, shift)
        @test reference.status == :accepted
        @test reference.cancellation > 0
        cancellation = DRM._ls_profile_root_result(
            rounded, 0.0; dir=1.0, init=1.6, cancellation=reference.cancellation,
        )
        @test cancellation.endpoint_failed
        @test !cancellation.accepted
        @test !cancellation.unbounded
        @test cancellation.reason == :insufficient_precision

        # The CI path must compare the two represented NLL values before
        # subtracting the LR half-threshold, rather than subtracting huge NLLs
        # inside the callback.
        difference = DRM._profile_reference_difference(shift + 1.6^2, shift)
        @test difference.difference - half != 0.0
    end

    @testset "finite exhausted nuisance solution is rejected" begin
        # Optim's termination flag alone is insufficient: the profiler checks the
        # same 1e-7 free-gradient target on a fresh candidate evaluation.
        stationary_check = DRM._ls_profile_candidate_status(
            u -> sum(abs2, u),
            (g, u) -> (g .= 1.0; g),
            [0.0],
            true,
        )
        @test !stationary_check.accepted
        @test stationary_check.converged
        @test stationary_check.reason == :not_stationary
        @test stationary_check.gradient_maxabs == 1.0

        kind = Val(:gamma)
        y = [1.0, 1.2, 0.9, 1.1]
        Xmu = [ones(4) [-1.0, -0.3, 0.4, 1.0]]
        Xsigma = ones(4, 1)
        gidx = [1, 1, 2, 2]
        Q = sparse(1.0I, 2, 2)
        # [beta_mu(2), beta_sigma(1), log L11, L21, log L22]
        theta = [0.0, 0.1, 0.0, 0.0, 0.0, 0.0]
        result = DRM._ls_profile_nll_result(
            kind, y, Xmu, Xsigma, gidx, 2, Q, theta, 1, 0.1;
            iterations=0,
        )
        @test isfinite(result.value)
        @test !result.accepted
        @test result.reason == :not_converged
        _, _, accepted = DRM._ls_profile_nll(
            kind, y, Xmu, Xsigma, gidx, 2, Q, theta, 1, 0.1;
            iterations=0,
        )
        @test !accepted
    end

    @testset "whitened canonical retry is reported and raw route is untouched" begin
        fit = _ls_profile_status_smoke_fit()
        obj = fit.nll::DRM.LocScaleObjective
        base = size(obj.Xμ, 2) + size(obj.Xψ, 2)
        perm = vcat(collect(1:base), [base + 1, base + 3, base + 2])
        theta = fit.theta[perm]
        idx = 2
        value = theta[idx] + 0.1
        damaged_warm_start = fill(10.0, length(theta) - 1)

        recovered = DRM._ls_profile_nll_result(
            obj.kind, obj.y, obj.Xμ, obj.Xψ, obj.gidx, obj.G, obj.Q,
            theta, idx, value;
            x0=damaged_warm_start,
            whitened=true,
        )
        @test recovered.accepted
        @test recovered.reason == :accepted
        @test recovered.fallback
        @test recovered.converged
        @test recovered.gradient_maxabs <= 1e-7

        raw = DRM._ls_profile_nll_result(
            obj.kind, obj.y, obj.Xμ, obj.Xψ, obj.gidx, obj.G, obj.Q,
            theta, idx, value;
            x0=damaged_warm_start,
            whitened=false,
            iterations=0,
        )
        @test !raw.accepted
        @test !raw.fallback
    end

    @testset "public canonical result propagates failed-arm diagnostics" begin
        fit = _ls_profile_status_smoke_fit()
        result = profile_result(fit; parm=:mu => "x")
        @info "canonical location-scale profile status fixture" attempted=result.attempted failed=result.failed lower_reason=only(result.endpoint_diagnostics).lower.reason upper_reason=only(result.endpoint_diagnostics).upper.reason
        @test length(result.ci) == length(result.stats) ==
              length(result.endpoint_diagnostics) == 1
        expected_failed = count(diag -> diag.lower.endpoint_failed ||
                                          diag.upper.endpoint_failed,
                                result.endpoint_diagnostics)
        @test result.failed == expected_failed
        @test count(stat -> stat.lower_endpoint_failed || stat.upper_endpoint_failed,
                    result.stats) == expected_failed
        stat = only(result.stats)
        diag = only(result.endpoint_diagnostics)
        @test (stat.param, stat.coef) == (diag.param, diag.coef)
        @test stat.evaluations == diag.lower.evaluations + diag.upper.evaluations
        @test stat.gradient_evaluations == diag.lower.gradient_evaluations +
                                          diag.upper.gradient_evaluations
        @test stat.bracket_expansions == diag.lower.bracket_expansions +
                                          diag.upper.bracket_expansions
        @test stat.root_iterations == diag.lower.root_iterations +
                                     diag.upper.root_iterations
        @test stat.lower_endpoint_failed == diag.lower.endpoint_failed
        @test stat.upper_endpoint_failed == diag.upper.endpoint_failed
        @test stat.lower_nuisance_reason == (diag.lower.nuisance === nothing ?
                                             :not_checked : diag.lower.nuisance.reason)
        @test stat.upper_nuisance_reason == (diag.upper.nuisance === nothing ?
                                             :not_checked : diag.upper.nuisance.reason)
        @test any(arm.endpoint_failed for arm in (diag.lower, diag.upper)) ==
              (expected_failed > 0)
        if expected_failed > 0
            @test_logs (:warn, r"profile confidence interval has failed endpoint") begin
                confint(fit; method=:profile, parm=:mu => "x")
            end
        else
            @test_logs begin
                confint(fit; method=:profile, parm=:mu => "x")
            end
        end
    end
end
