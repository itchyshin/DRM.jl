using DRM,Test,LinearAlgebra; @assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
@testset "bounded bootstrap regression" begin
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_simulate.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_simulate_scale_conventions.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_bootstrap_simulator.jl")
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_bootstrap_refit.jl")
end
println("BOOTSTRAP_SLICE_PASS")
