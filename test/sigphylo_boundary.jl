using DRM, Test, LinearAlgebra, SparseArrays, Random
println("boundary check — _ls_grad(:gaussian_mean) defined = ",
        hasmethod(DRM._ls_grad, (Val{:gaussian_mean}, Float64, Float64, Float64))); flush(stdout)
t0=time()
try; include("test_gaussian_locscale_phylo_boundary.jl"); println(">>> ok boundary $(round(time()-t0;digits=1))s")
catch e; println(">>> FAILED boundary :: "*sprint(showerror,e)); end
flush(stdout); println(">>> BOUNDARY DONE")
