using DRM, Test, LinearAlgebra, SparseArrays, Random
println("RHO_GUARD = ", DRM.RHO_GUARD); flush(stdout)
_say(m)=(println(stdout,m);flush(stdout))
for f in ["test_gaussian_bivariate.jl","test_gaussian_bivariate_phylo.jl"]
    t0=time()
    try; _say(">>> "*f); include(f); _say(">>> ok  "*f*"  $(round(time()-t0;digits=1))s")
    catch e; _say(">>> FAILED "*f*" :: "*sprint(showerror,e)); end
end
_say(">>> RHO12 DONE")
