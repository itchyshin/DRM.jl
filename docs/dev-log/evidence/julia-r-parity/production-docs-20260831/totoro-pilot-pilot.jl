using DRM, Test, LinearAlgebra
BLAS.set_num_threads(1)
@assert realpath(pathof(DRM)) == joinpath(pwd(),"src","DRM.jl")
println("RUNTIME julia=",VERSION," threads=",Threads.nthreads()," blas=",BLAS.get_num_threads()," source=",pathof(DRM));flush(stdout)
println("DRM_PARITY_TESTS=",get(ENV,"DRM_PARITY_TESTS","unset"));flush(stdout)
include("test/runtests.jl")
println("DEFAULT_JULIA_SUITE_PASS");flush(stdout)
