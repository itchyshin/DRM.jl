using DRM, Test, LinearAlgebra
BLAS.set_num_threads(1)
expected = "/home/snakagaw/drm_parity_integration_567fec06_001/src/DRM.jl"
realpath(pathof(DRM)) == realpath(expected) || error("wrong DRM checkout")
println("RUNTIME julia=", VERSION, " threads=", Threads.nthreads(), " BLAS=", BLAS.get_num_threads(), " DRM=", pathof(DRM)); flush(stdout)
println("START_FILE test_reml_newton_sigma_phylo.jl"); flush(stdout)
include("/home/snakagaw/drm_parity_integration_567fec06_001/test/test_reml_newton_sigma_phylo.jl")
println("COMPLETE_FILE test_reml_newton_sigma_phylo.jl"); flush(stdout)
println("NEWTON_REML_COMPLETE"); flush(stdout)
