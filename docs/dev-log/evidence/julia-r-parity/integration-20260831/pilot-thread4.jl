using DRM,Test,LinearAlgebra
BLAS.set_num_threads(1)
@assert Threads.nthreads()==4 && BLAS.get_num_threads()==1
@assert realpath(pathof(DRM))==joinpath(pwd(),"src","DRM.jl")
println("RUNTIME julia=",VERSION," threads=",Threads.nthreads()," blas=",BLAS.get_num_threads()," source=",pathof(DRM))
include("test/test_lss_bootstrap_contract.jl")
include("test/test_bootstrap_thread_flags.jl")
println("TOTORO_THREAD4_PASS")
