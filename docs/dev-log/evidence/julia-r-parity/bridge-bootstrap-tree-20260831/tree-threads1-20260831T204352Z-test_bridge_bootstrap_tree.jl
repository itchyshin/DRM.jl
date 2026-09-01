# A non-unit-height tree makes accidental covariance rescaling visible.
# B=2 is a deterministic integration check, not interval-coverage evidence.
using DRM, Test, Random, LinearAlgebra
import Distributions

@testset "non-Gaussian phylogenetic bootstrap bridge" begin
    rng = MersenneTwister(20_260_831)
    G, m = 4, 8
    species = repeat(["s$i" for i in 1:G], inner=m)
    idx = repeat(1:G, inner=m)
    x = collect(repeat(range(-1.0, 1.0; length=m), G))
    re_mu = 0.16 .* randn(rng, G)
    re_sigma = 0.10 .* randn(rng, G)
    eta = 0.70 .+ 0.55 .* x .+ re_mu[idx]
    psi = 1.05 .+ re_sigma[idx]
    y = [rand(rng, Distributions.Gamma(exp(psi[i]), exp(eta[i]-psi[i])))
         for i in eachindex(x)]
    data = (; y, x, species)
    newick = "((s1:0.8,s2:0.8):0.9,(s3:0.8,s4:0.8):0.9);"
    tree = augmented_phy(newick)
    formula = bf(@formula(y ~ x + (1 | tree_boot | phylo(species))),
                 @formula(sigma ~ 1 + (1 | tree_boot | phylo(species))))
    fit = drm(formula, Gamma(); data, tree)
    @test fit.nll isa DRM.LocScaleObjective
    @test is_converged(fit)
    direct = bootstrap_result(fit; data, tree, B=2, rng=MersenneTwister(4001),
                              failures=:skip, check_converged=true)
    println("DIRECT_TREE_BOOTSTRAP ", (direct.attempted, direct.used, direct.failed),
            " failures=", repr(direct.failures)); flush(stdout)
    # Save exactly the same input for the actual R API integration run.
    fixture_dir = get(ENV, "DRM_TREE_BOOTSTRAP_FIXTURE_DIR", "")
    if !isempty(fixture_dir)
        mkpath(fixture_dir)
        open(joinpath(fixture_dir, "data.csv"), "w") do io
            println(io, "y,x,species")
            for i in eachindex(y)
                println(io, join((y[i], x[i], species[i]), ','))
            end
        end
        write(joinpath(fixture_dir, "tree.newick"), newick * "\n")
    end
    row = only(filter(r -> r.param == :mu && r.coef == "x", direct.summary))
    for threaded in (false, true)
        bridged = drm_bridge_inference(;
            formula="y ~ x + (1 | tree_boot | phylo(species)); sigma ~ 1 + (1 | tree_boot | phylo(species))",
            family="gamma", data, tree=newick, method="bootstrap", B=2,
            seed=4001, threads=threaded, parm="fixef:mu:x")
        @test (bridged["attempted"], bridged["used"], bridged["failed"]) ==
              (direct.attempted, direct.used, direct.failed)
        @test bridged["threaded"] == (threaded && Threads.nthreads() > 1)
        @test bridged["status"] == (direct.used >= 2 ? "bootstrap" : "bootstrap_unavailable")
        for key in ("estimate", "lower", "upper")
            @test isequal(bridged[key], getproperty(row, Symbol(key)))
        end
        println("BRIDGE_TREE_BOOTSTRAP ", repr(bridged)); flush(stdout)
    end
end
