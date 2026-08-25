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
#
# re_sd now a compared quantity (promotion-gap fix): the row's DEFINING
# parameter -- the phylogenetic SD -- is compared against drmTMB below, not
# just coefficients/logLik. THE TRAP: DRM.jl's `re_sd(fit)[:species]` is on
# the RAW branch-length scale (tip variance = tree height h); drmTMB's is on
# the CORRELATION scale (`ape::vcv(tree, corr = TRUE)`, tip variance 1
# regardless of h). The two agree only when h == 1 -- this fixture's tree has
# h ~= 1.684, so the raw comparison would silently be wrong by sqrt(h) ~= 1.30
# without the conversion applied below.
#
# 3-HEIGHT ROUND TRIP (verified 2026-08-24, not shipped as a fixture -- see
# below for why): the seed-111 tree was rescaled to heights 0.5 / 1.0 / 3.0
# (same data, same topology) and refit in both engines.
#
#   height   drmTMB sd_phylo (corr)   DRM.jl re_sd (raw)   raw*sqrt(h)
#   0.5      6.666539e-06             1.834230e-05         1.296997e-05
#   1.0      6.666539e-06             1.175157e-05         1.175157e-05
#   3.0      6.666539e-06             7.342258e-06          1.271716e-05
#
# drmTMB's value is EXACTLY height-invariant (confirmed to ~1e-8), as expected
# since it standardises internally -- this validates the scale-CONVENTION
# claim directly. DRM.jl's raw*sqrt(h) does NOT converge tightly to drmTMB's
# 6.67e-6 at any height, because at seed 111 the phylo variance component is
# boundary-adjacent: a direct nll sweep (fixing log_sd_phylo at the fitted
# sigma) showed the profiled negative log-likelihood changes by < 1e-4 over
# log_sd_phylo in [-30, -10] -- i.e. the likelihood is flat there, so the
# exact reported value is dominated by each engine's own optimiser stopping
# tolerance (TMB's nlminb vs. DRM.jl's L-BFGS g_tol), not a tightly
# recoverable quantity. This is why the comparison below uses a generous,
# EXPLICITLY documented tolerance (`atol_re_sd`) rather than the coefficient
# tolerance, and why claim_status stays partial: this fixture evidences the
# SCALE CONVENTION (drmTMB height-invariance, confirmed) but not a tight
# numeric match on the phylo SD itself (not achievable at this seed's
# near-zero estimate).

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

    # The row's DEFINING quantity: the fitted phylogenetic SD (see the SCALE
    # TRAP note above the testset). Compare on drmTMB's CORRELATION scale by
    # multiplying DRM.jl's RAW-scale re_sd by sqrt(tree_height).
    @test haskey(expected, "re_sd")
    @test haskey(expected["re_sd"], "species_corr_scale")
    @test haskey(meta, "tree_height")

    phy = augmented_phy(tree)
    h = phylo_tree_height(phy)
    ref_h = Float64(meta["tree_height"])
    @test _within(h, ref_h, 1e-6, 1e-6)   # Julia's and R's tree-height readings agree

    sds = re_sd(fit)
    @test haskey(sds, :species)
    sd_phylo_raw = Float64(sds[:species])
    sd_phylo_corr = sd_phylo_raw * sqrt(h)

    ref_sd_phylo = Float64(expected["re_sd"]["species_corr_scale"])
    atol_re_sd = Float64(get(expected["tol"], "atol_re_sd", 1e-4))
    @test _within(sd_phylo_corr, ref_sd_phylo, 0.0, atol_re_sd)
end
