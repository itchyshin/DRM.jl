using DRM, Test, LinearAlgebra
@assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_whitened.jl")

println("REGRESSION_BUNDLE_PASS")
