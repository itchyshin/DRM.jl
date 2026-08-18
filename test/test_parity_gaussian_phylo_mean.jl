# test_parity_gaussian_phylo_mean.jl — standalone same-target fixture for
# gaussian_phylo_mean (Route A: ML, univariate, sigma ~ 1).
#
# Wired into test/runtests.jl by Option A (#445) after #423+#428 landed.
#
#   julia --project=. -e 'using DRM, Test; include("test/test_parity_gaussian_phylo_mean.jl")'
#
# Claim fence: this PR adds a same-target fixture for gaussian_phylo_mean
# within the row's declared tolerance. claim_status stays partial. Not
# parity complete. Not last fixture-gap. Not sigma-phylo. Not interval
# coverage. Not R-via-Julia bridge admission.
# Workflow G fixtures stay 0.6.0 / ML / no tree; this cell is 0.7.0 ML + tree
# outside test/parity/fixtures/.

using DRM
using Test
using TOML
using DelimitedFiles: readdlm

const FIXTURE = joinpath(@__DIR__, "parity", "phylo-mean", "gaussian-phylo-mean")

function _load_data(dir)
    raw, header = readdlm(joinpath(dir, "data.csv"), ','; header = true)
    cols = Symbol.(strip.(string.(vec(header))))
    numeric = Set((:y, :x))
    pairs = map(enumerate(cols)) do (j, name)
        col = raw[:, j]
        if name in numeric
            name => Float64[parse(Float64, string(v)) for v in col]
        else
            name => string.(col)
        end
    end
    return NamedTuple(pairs)
end

function _coef_named(fit)
    θ = coef(fit)
    namemap = Dict(p => ns for (p, ns) in fit.coefnames)
    out = Dict{String,Float64}()
    for (param, r) in fit.blocks
        param === :phylocov && continue
        param === :resd && continue
        haskey(namemap, param) || continue
        names = namemap[param]
        slice = θ[r]
        length(names) == length(slice) || error("name/coef mismatch for $param")
        for (nm, est) in zip(names, slice)
            out["$(param)_$(nm)"] = est
        end
    end
    return out
end

_within(a, b, rtol, atol) = abs(a - b) <= max(atol, rtol * max(abs(a), abs(b)))

@testset "gaussian_phylo_mean same-target fixture (Route A)" begin
    @test isfile(joinpath(FIXTURE, "data.csv"))
    @test isfile(joinpath(FIXTURE, "tree.newick"))
    @test isfile(joinpath(FIXTURE, "expected.toml"))
    @test isfile(joinpath(FIXTURE, "expected.meta.toml"))

    expected = TOML.parsefile(joinpath(FIXTURE, "expected.toml"))
    meta = TOML.parsefile(joinpath(FIXTURE, "expected.meta.toml"))
    @test meta["drmtmb_version"] == "0.7.0"
    @test haskey(meta, "r_call")
    @test haskey(meta, "seed")
    @test meta["seed"] == 111
    @test meta["n_tip"] == 18
    @test expected["fit"]["method"] == "ML"
    @test expected["fit"]["engine"] == "tmb"
    @test expected["fit"]["family"] == "gaussian"
    @test haskey(expected, "status")
    @test expected["status"]["converged"] == true
    @test haskey(expected["status"], "pdHess")
    @test haskey(expected["status"], "interval_status")
    @test expected["status"]["interval_status"] != "coverage_claimed"

    dat = _load_data(FIXTURE)
    tree = read(joinpath(FIXTURE, "tree.newick"), String)
    form = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1))
    fit = drm(form, Gaussian(); data = dat, tree = tree)

    @test estimation_method(fit) === :ML
    @test is_converged(fit)
    @test isfinite(loglik(fit))

    atol_ll = Float64(get(expected["tol"], "atol_loglik", 1e-6))
    atol_c = Float64(get(expected["tol"], "atol_coef", 1e-5))
    rtol_c = Float64(get(expected["tol"], "rtol_coef", 1e-5))
    ref_ll = Float64(expected["fit"]["loglik"])
    @test _within(loglik(fit), ref_ll, 0.0, atol_ll)

    got = _coef_named(fit)
    for (name, ref) in expected["coef"]
        @test haskey(got, name)
        @test _within(got[name], Float64(ref), rtol_c, atol_c)
    end
end
