using SHA
using DRM
using Optim

fixture_path = joinpath(@__DIR__, "..", "integration", "DRM.jl", "test", "test_locscale_profile_threads.jl")
fixture_text = read(fixture_path, String)
marker = "@testset \"canonical location-scale profile coefficient threading\""
marker_range = findfirst(marker, fixture_text)
marker_range === nothing && error("S11 fixture testset marker not found")
fixture_prefix = fixture_text[1:first(marker_range)-1]
println("S11_REPLAY_EXTRACTED_PREFIX_SHA256=", bytes2hex(sha256(fixture_prefix)))
Base.include_string(Main, fixture_prefix, fixture_path)

fit = _locscale_profile_threads_fixture()
obj = fit.nll::DRM.LocScaleObjective
base = size(obj.Xμ, 2) + size(obj.Xψ, 2)
perm = vcat(collect(1:base), [base + 1, base + 3, base + 2])
theta_engine = fit.theta[perm]
candidates = [
    (label=:intercept_lower, job_k=1, value=0.3869272019658678),
    (label=:intercept_upper, job_k=1, value=0.8871415640524969),
    (label=:slope_lower, job_k=2, value=-0.012284045959579132),
    (label=:slope_upper, job_k=2, value=0.5004841913001536),
]

println("S11_REPLAY_FIT_CONVERGED=", fit.converged)
println("S11_REPLAY_STATE=(y=", repr(obj.y), ", Xmu=", repr(obj.Xμ), ", Xpsi=", repr(obj.Xψ),
        ", gidx=", repr(obj.gidx), ", G=", repr(obj.G), ", Q=", repr(obj.Q),
        ", theta_engine=", repr(theta_engine), ", candidates=", repr(candidates), ")")
println("S11_REPLAY_STATE_SHA256=", bytes2hex(sha256(repr((obj.y, obj.Xμ, obj.Xψ, obj.gidx,
    obj.G, obj.Q, theta_engine, candidates)))))
println("S11_REPLAY_OPTIONS=(algorithm=:LBFGS_BackTracking, g_tol=1e-7, iterations=200, init=:theta_engine_free, mwarm=:fresh_nothing)")

function termination_flags(result)
    names = (:f_converged, :g_converged, :x_converged, :iteration_converged,
             :f_limit_reached, :g_limit_reached, :x_limit_reached, :time_limit)
    return NamedTuple{names}(Tuple(hasproperty(result, name) ? getproperty(result, name) : :unavailable
                                   for name in names))
end

function replay_candidate(obj, theta_engine, target)
    p = length(theta_engine)
    p_mu = size(obj.Xμ, 2)
    p_psi = size(obj.Xψ, 2)
    # The four diagnostic candidates are the two mean coefficients. Their engine and DrmFit
    # indices agree; `perm` only changes the covariance block after `base`.
    idx = target.job_k
    free = [k for k in 1:p if k != idx]
    warm = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    f_calls = Ref(0); inner_ok = Ref(0); inner_refusal = Ref(0); f_exceptions = Ref(0)
    g_calls = Ref(0); g_finite = Ref(0); g_nonfinite = Ref(0); g_exceptions = Ref(0)
    build(theta_free) = (theta = collect(float.(theta_engine)); theta[free] .= theta_free; theta[idx] = target.value; theta)
    function f(theta_free)
        f_calls[] += 1
        try
            theta = build(theta_free)
            beta_mu = @view theta[1:p_mu]
            beta_psi = @view theta[p_mu+1:p_mu+p_psi]
            lambda = theta[p_mu+p_psi+1:p_mu+p_psi+3]
            precision = DRM.prior_precision(obj.Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
            value, mode, ok = DRM._ls_marginal_nll(obj.kind, obj.y, obj.Xμ * beta_mu,
                obj.Xψ * beta_psi, obj.gidx, obj.G, precision; a0=warm[])
            if ok
                inner_ok[] += 1
                warm[] = copy(mode)
                return value
            end
            inner_refusal[] += 1
            return DRM._LS_PROFILE_INFEASIBLE
        catch
            f_exceptions[] += 1
            rethrow()
        end
    end
    function g!(gradient_free, theta_free)
        g_calls[] += 1
        try
            gradient_full = DRM._ls_marginal_grad(obj.kind, obj.y, obj.Xμ, obj.Xψ, obj.gidx,
                obj.G, obj.Q, build(theta_free); a0=warm[])
            all(isfinite, gradient_full) ? (g_finite[] += 1) : (g_nonfinite[] += 1)
            gradient_free .= gradient_full[free]
            return gradient_free
        catch
            g_exceptions[] += 1
            rethrow()
        end
    end
    init = float.(theta_engine[free])
    result = Optim.optimize(f, g!, init,
        Optim.LBFGS(linesearch=Optim.LineSearches.BackTracking()),
        Optim.Options(g_tol=1e-7, iterations=200))
    minimizer = Optim.minimizer(result)
    final_value = f(minimizer)
    final_gradient = similar(minimizer)
    g!(final_gradient, minimizer)
    return (
        label=target.label,
        index=idx,
        value=target.value,
        result_type=string(typeof(result)),
        converged=Optim.converged(result),
        iterations=Optim.iterations(result),
        f_calls=Optim.f_calls(result),
        g_calls=Optim.g_calls(result),
        flags=termination_flags(result),
        reported_minimum=Optim.minimum(result),
        minimizer=minimizer,
        fresh_final_value=final_value,
        fresh_final_gradient_finite=all(isfinite, final_gradient),
        fresh_final_gradient_maxabs=isempty(final_gradient) ? 0.0 : maximum(abs, final_gradient),
        closure_counts=(f_calls=f_calls[], inner_ok=inner_ok[], inner_refusal=inner_refusal[],
                        f_exceptions=f_exceptions[], g_calls=g_calls[], g_finite=g_finite[],
                        g_nonfinite=g_nonfinite[], g_exceptions=g_exceptions[]),
    )
end

for target in candidates
    println("S11_REPLAY_RESULT=", repr(replay_candidate(obj, theta_engine, target)))
end
println("S11_REPLAY_COMPLETE")
