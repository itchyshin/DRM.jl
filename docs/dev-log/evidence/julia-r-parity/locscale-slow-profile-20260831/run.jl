using DRM, Test, LinearAlgebra
BLAS.set_num_threads(1)
@assert realpath(pathof(DRM)) == realpath("/home/snakagaw/drm_parity_blas_c0675b16_001/src/DRM.jl")
@assert ENV["DRM_SLOW_TESTS"] == "1"
println("RUNTIME julia=",VERSION," JuliaThreads=",Threads.nthreads()," BLAS=",BLAS.get_num_threads()," DRM_SLOW_TESTS=",ENV["DRM_SLOW_TESTS"]); flush(stdout)
println("START_FILE test_locscale_profile.jl"); flush(stdout)
include("/home/snakagaw/drm_parity_blas_c0675b16_001/test/test_locscale_profile.jl")
println("COMPLETE_FILE test_locscale_profile.jl"); flush(stdout)
println("SLOW_PROFILE_COMPLETE"); flush(stdout)
