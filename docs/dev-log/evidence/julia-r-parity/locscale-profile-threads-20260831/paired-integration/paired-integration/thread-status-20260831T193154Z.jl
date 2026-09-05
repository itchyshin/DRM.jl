using DRM, Test, LinearAlgebra
@assert Threads.nthreads()==4 && BLAS.get_num_threads()==1
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_profile_status.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_profile_nuisance_status.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_inference_blas_pinning.jl")

println("REGRESSION_BUNDLE_PASS")
