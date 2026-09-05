using DRM,Test,LinearAlgebra; @assert Threads.nthreads()==4 && BLAS.get_num_threads()==1
@testset "bounded bootstrap regression" begin
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_locscale_bootstrap_simulator.jl")
end
println("BOOTSTRAP_SLICE_PASS")
