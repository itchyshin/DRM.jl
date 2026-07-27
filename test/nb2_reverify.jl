using DRM, Test, LinearAlgebra, SparseArrays, Random
println("DRM loaded for NB2 re-verify"); flush(stdout)
_say(m)=(println(stdout,m);flush(stdout))
for f in ["test_nb2_phylo_laplace.jl","test_relmat_counts_nb2.jl",
          "test_164_mean_re_covariate_sigma.jl","test_variational_nb2.jl",
          "test_quantile_residuals.jl"]
    t0=time()
    try; _say(">>> "*f); include(f); _say(">>> ok  "*f*"  $(round(time()-t0;digits=1))s")
    catch e; _say(">>> FAILED "*f*" :: "*sprint(showerror,e)); end
end
_say(">>> NB2 REVERIFY DONE")
