using DRM,LinearAlgebra; @assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
include("/private/tmp/drm-parity-20260830/integration/DRM.jl/test/test_simulate_scale_conventions.jl")
println("BOOTSTRAP_SLICE_PASS")
