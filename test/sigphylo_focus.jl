using DRM, Test, LinearAlgebra, SparseArrays, Random
println("DRM loaded; _ls_grad(:gaussian_mean) defined = ",
        hasmethod(DRM._ls_grad, (Val{:gaussian_mean}, Float64, Float64, Float64))); flush(stdout)
_say(m)=(println(stdout,m);flush(stdout))
for f in ["test_gaussian_locscale_phylo.jl","test_locscale_frontend.jl",
          "test_corr_locscale_equiv.jl","test_sigma_axis_re.jl"]
    t0=time()
    try; _say(">>> "*f); include(f); _say(">>> ok  "*f*"  $(round(time()-t0;digits=1))s")
    catch e; _say(">>> FAILED "*f*" :: "*sprint(showerror,e)); end
end
_say(">>> FOCUS DONE")
