# Targeted verify after bringing the σ-phylo locscale subsystem onto merged main.
# Runs: (a) the whole reworked locscale spine (no-regression), (b) the new
# cluster ① tests, (c) #164 + #202 paths that ride the spine, (d) the B1 σ-phylo
# route + boundary. Run from the test/ dir so the relative includes resolve.
using DRM
using Test, LinearAlgebra, SparseArrays, Random

println(stdout, "DRM loaded — _SIGMA_RE_EPS = $(DRM._SIGMA_RE_EPS); _fit_gaussian_locscale_phylo defined = $(isdefined(DRM, :_fit_gaussian_locscale_phylo))"); flush(stdout)

const SUBSET = [
    # reworked spine — no-regression
    "test_locscale_kernels.jl", "test_locscale_inner.jl", "test_locscale_marginal.jl",
    "test_locscale_fit.jl", "test_locscale_grad.jl", "test_locscale_infer.jl",
    "test_locscale_profile.jl", "test_locscale_gamma_e2e.jl", "test_locscale_phylo_e2e.jl",
    "test_locscale_frontend.jl",
    # new cluster ① (corr/indep slope reroute) + cross-engine equivalence + structured
    "test_locscale_structured.jl", "test_corr_locscale_equiv.jl",
    # cluster ② standalone σ-axis RE (grad! keyword-contract fix + Gamma recovery)
    "test_sigma_axis_re.jl",
    # #164 covariate-dispersion + #202 non-Gaussian phylo locscale (ride the spine)
    "test_nonconst_sigma_re.jl", "test_phylo_locscale.jl",
    # B1 σ-phylo (Ayumi) + boundary
    "test_gaussian_locscale_phylo.jl", "test_gaussian_locscale_phylo_boundary.jl",
]

_say(msg) = (println(stdout, msg); flush(stdout))
failed = String[]
for f in SUBSET
    if !isfile(f)
        _say("MISSING test file: $f"); push!(failed, "$f (missing)"); continue
    end
    t0 = time()
    try
        _say(">>> running $f")
        include(f)
        _say(">>> ok  $f  ($(round(time()-t0; digits=1))s)")
    catch e
        _say(">>> FAILED $f :: $(sprint(showerror, e))")
        push!(failed, f)
    end
end

println("\n>>> SIGPHYLO VERIFY3 DONE")
println(isempty(failed) ? ">>> ALL SUBSET TESTS PASSED" : ">>> FAILURES: $(join(failed, ", "))")
