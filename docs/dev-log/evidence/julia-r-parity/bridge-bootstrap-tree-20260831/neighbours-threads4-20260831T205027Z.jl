using DRM,Test,LinearAlgebra; @assert Threads.nthreads()==4 && BLAS.get_num_threads()==1
@testset "bounded bootstrap regression" begin
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_bridge_formula_labels.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_bridge_lss_labels.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_bridge_profile_status.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_bootstrap_refit.jl")
end
println("BOOTSTRAP_SLICE_PASS")
