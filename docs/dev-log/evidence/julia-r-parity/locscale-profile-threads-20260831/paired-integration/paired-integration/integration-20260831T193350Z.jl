using DRM, Test, LinearAlgebra
@assert Threads.nthreads()==4 && BLAS.get_num_threads()==1
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_fit.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_profile_acceptance_oracles.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_bridge_profile_status.jl")

println("REGRESSION_BUNDLE_PASS")
