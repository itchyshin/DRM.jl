using DRM, Test, LinearAlgebra
@assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_kernels.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_inner.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_inner_status.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_marginal.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_grad.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_compensated_gradient.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_precision_derivatives.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_whitened.jl")

println("REGRESSION_BUNDLE_PASS")
