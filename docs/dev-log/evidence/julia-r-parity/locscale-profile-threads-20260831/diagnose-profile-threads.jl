using SHA
using DRM

fixture_path = joinpath(@__DIR__, "..", "integration", "DRM.jl", "test", "test_locscale_profile_threads.jl")
fixture_text = read(fixture_path, String)
marker = "@testset \"canonical location-scale profile coefficient threading\""
marker_range = findfirst(marker, fixture_text)
marker_range === nothing && error("S11 fixture testset marker not found")
fixture_prefix = fixture_text[1:first(marker_range)-1]
println("S11_EXTRACTED_PREFIX_SHA256=", bytes2hex(sha256(fixture_prefix)))
Base.include_string(Main, fixture_prefix, fixture_path)

fit = _locscale_profile_threads_fixture()
println("S11_FIT_CONVERGED=", fit.converged)
println("S11_FIT_LOGLIK=", repr(fit.loglik))
println("S11_FIT_THETA=", repr(fit.theta))
println("S11_FIT_BLOCKS=", repr(fit.blocks))
println("S11_FIT_COEFNAMES=", repr(fit.coefnames))

result = profile_result(fit; parm=:mu, threads=false)
println("S11_PROFILE_CI=", repr(result.ci))
println("S11_PROFILE_STATS=", repr(result.stats))
println("S11_ENDPOINT_DIAGNOSTICS=", repr(result.endpoint_diagnostics))
println("S11_PROFILE_METADATA=", repr((attempted=result.attempted, used=result.used,
    failed=result.failed, threaded=result.threaded, worker_threads=result.worker_threads,
    julia_threads=result.julia_threads, blas_threads=result.blas_threads,
    blas_oversubscribed=result.blas_oversubscribed, elapsed=result.elapsed,
    autodiff=result.autodiff, level=result.level)))
println("S11_DIAGNOSTIC_COMPLETE")
