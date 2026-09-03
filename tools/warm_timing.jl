#!/usr/bin/env julia
# tools/warm_timing.jl — S12 (#563), root gate G5.
#
# Native-Julia warm-workflow timing harness. Reads the fixtures written by
# tools/warm_timing_fixtures.jl and, for each registered workflow, fits it via
# DRM.jl's own public front end (`drm(...)`), never through the R bridge --
# this is a pure Julia process, timed independently of tools/warm_timing.R.
#
# Registry: docs/dev-log/evidence/julia-r-parity/warm-workflow-registry.md
# (the workflow list, fixture sizes, and the drmTMB call each is paired
# against are defined there; this script and warm_timing.R must both match
# it, not redefine it).
#
# Threading:
#   - Threads.nthreads() is fixed at Julia STARTUP, not by a CLI flag here --
#     start Julia with `-t N` matching --threads N (documented in the
#     registry doc's usage section; this script errors if they disagree).
#   - BLAS threads ARE settable at runtime: `LinearAlgebra.BLAS.set_num_threads(N)`
#     -- OMP_NUM_THREADS alone does not reliably change Julia's active BLAS
#     thread count (see docs/dev-log root-gate note referenced in the scout).
#
# Usage (run once per thread count, host idle, same Julia minor version both
# times against R, see registry doc "Usage"):
#   julia --project=. -t N tools/warm_timing.jl --threads N --reps 3 \
#       --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures \
#       --out docs/dev-log/evidence/julia-r-parity/warm-timing-julia-tN.tsv
#   (add --workflow NAME to run a single workflow, e.g. for the smoke pre-run)

using DRM
using LinearAlgebra
using Printf

# ---- CLI ----------------------------------------------------------------

function parse_args(argv)
    threads = nothing
    reps = 3
    out = nothing
    fixtures = "docs/dev-log/evidence/julia-r-parity/warm-fixtures"
    workflow = nothing
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--threads"
            threads = parse(Int, argv[i + 1]); i += 2
        elseif a == "--reps"
            reps = parse(Int, argv[i + 1]); i += 2
        elseif a == "--out"
            out = argv[i + 1]; i += 2
        elseif a == "--fixtures"
            fixtures = argv[i + 1]; i += 2
        elseif a == "--workflow"
            workflow = argv[i + 1]; i += 2
        else
            error("warm_timing.jl: unknown arg $a")
        end
    end
    threads === nothing && error("warm_timing.jl: --threads N is required")
    out === nothing && error("warm_timing.jl: --out FILE is required")
    return (; threads, reps, out, fixtures, workflow)
end

# ---- CSV / Newick readers (manual -- main Project.toml has no CSV.jl) -----

function read_csv(path)
    lines = readlines(path)
    header = split(lines[1], ",")
    ncol = length(header)
    cols = [String[] for _ in 1:ncol]
    for l in lines[2:end]
        isempty(l) && continue
        parts = split(l, ",")
        for k in 1:ncol
            push!(cols[k], parts[k])
        end
    end
    return Dict(String(h) => c for (h, c) in zip(header, cols))
end

num(v) = parse.(Float64, v)
ints(v) = parse.(Int, v)

read_tree(path) = DRM.augmented_phy(read(path, String))

# ---- per-workflow definitions ---------------------------------------------
# Each entry: fit() -> DrmFit, uncertainty(fit) -> CI, predict_leg(fit) -> preds.

struct Workflow
    name::String
    fit::Function
    uncertainty::Function
    predict_leg::Function
end

function build_workflows(fixdir)
    W = Workflow[]

    # 1. Gaussian mixed + phylo mean
    let d = read_csv(joinpath(fixdir, "gauss_mixed_phylo_mean.csv")),
        phy = read_tree(joinpath(fixdir, "gauss_mixed_phylo_mean.nwk"))
        dat = (y = num(d["y"]), x = num(d["x"]), species = d["species"], study = ints(d["study"]))
        f = bf(@formula(y ~ x + (1 | study) + phylo(1 | species)), @formula(sigma ~ 1))
        push!(W, Workflow("gauss_mixed_phylo_mean",
            () -> drm(f, Gaussian(); data = dat, tree = phy),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 2. Gaussian LSS sd(g)
    let d = read_csv(joinpath(fixdir, "gauss_lss_sd_group.csv"))
        dat = (y = num(d["y"]), x = num(d["x"]), z = num(d["z"]), g = ints(d["g"]))
        f = bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ z), @formula(sd(g) ~ z))
        push!(W, Workflow("gauss_lss_sd_group",
            () -> drm(f, Gaussian(); data = dat),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 3. Gaussian LSS sd_phylo
    let d = read_csv(joinpath(fixdir, "gauss_lss_sd_phylo.csv")),
        phy = read_tree(joinpath(fixdir, "gauss_lss_sd_phylo.nwk"))
        dat = (y = num(d["y"]), x = num(d["x"]), species = d["species"])
        f = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
               @formula(sd(species, phylogenetic) ~ x))
        push!(W, Workflow("gauss_lss_sd_phylo",
            () -> drm(f, Gaussian(); data = dat, tree = phy),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 4/5. Bivariate q4 phylo, ML and REML (same fixture)
    let d = read_csv(joinpath(fixdir, "biv_q4_phylo.csv")),
        phy = read_tree(joinpath(fixdir, "biv_q4_phylo.nwk"))
        dat = (species = d["species"], x = num(d["x"]), y1 = num(d["y1"]), y2 = num(d["y2"]))
        f = bf(mu1 = @formula(y1 ~ x + phylo(1 | p | species)),
               mu2 = @formula(y2 ~ x + phylo(1 | p | species)),
               sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
               rho12 = @formula(rho12 ~ 1))
        push!(W, Workflow("biv_q4_phylo_ml",
            () -> drm(f, Gaussian(); data = dat, tree = phy, method = :ML),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
        push!(W, Workflow("biv_q4_phylo_reml",
            () -> drm(f, Gaussian(); data = dat, tree = phy, method = :REML),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 6. Bernoulli mixed
    let d = read_csv(joinpath(fixdir, "bernoulli_mixed.csv"))
        dat = (y = num(d["y"]), x = num(d["x"]), g = ints(d["g"]))
        f = bf(@formula(y ~ x + (1 | g)))
        push!(W, Workflow("bernoulli_mixed",
            () -> drm(f, Binomial(); data = dat),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 7. Poisson mixed
    let d = read_csv(joinpath(fixdir, "poisson_mixed.csv"))
        dat = (y = ints(d["y"]), x = num(d["x"]), g = ints(d["g"]))
        f = bf(@formula(y ~ x + (1 | g)))
        push!(W, Workflow("poisson_mixed",
            () -> drm(f, Poisson(); data = dat),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 8. LogNormal location-scale
    let d = read_csv(joinpath(fixdir, "lognormal_locscale.csv"))
        dat = (y = num(d["y"]), x = num(d["x"]), z = num(d["z"]))
        f = bf(@formula(y ~ x), @formula(sigma ~ z))
        push!(W, Workflow("lognormal_locscale",
            () -> drm(f, LogNormal(); data = dat),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 9. Meta-analysis meta_V
    let d = read_csv(joinpath(fixdir, "meta_analysis.csv"))
        dat = (y = num(d["y"]), x = num(d["x"]), v = num(d["v"]))
        f = bf(@formula(y ~ x + meta_V(v)), @formula(sigma ~ 1))
        push!(W, Workflow("meta_analysis_meta_V",
            () -> drm(f, Gaussian(); data = dat),
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    # 10. Large sparse LSS, p ~ 2000
    let d = read_csv(joinpath(fixdir, "large_sparse_lss_p2000.csv")),
        phy = read_tree(joinpath(fixdir, "large_sparse_lss_p2000.nwk"))
        dat = (y = num(d["y"]), x = num(d["x"]), species = d["species"])
        f = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
               @formula(sd(species, phylogenetic) ~ x))
        push!(W, Workflow("large_sparse_lss_p2000",
            () -> drm(f, Gaussian(); data = dat, tree = phy),   # algorithm=:auto -> sparse route (G>500)
            fit -> confint(fit),
            fit -> predict(fit, dat)))
    end

    return W
end

# ---- timing --------------------------------------------------------------

function time_reps(f, k::Int)
    times = Float64[]
    local val
    for _ in 1:k
        t0 = time_ns()
        val = f()
        push!(times, (time_ns() - t0) / 1e9)
    end
    return val, times
end

fit_converged(fit) = try
    is_converged(fit)
catch
    NA
end
fit_loglik(fit) = try
    Float64(loglik(fit))
catch
    NaN
end

const NA = "NA"

function main()
    args = parse_args(ARGS)
    if Threads.nthreads() != args.threads
        error("warm_timing.jl: Julia was started with -t $(Threads.nthreads()) but --threads $(args.threads) was requested. Start Julia with `-t $(args.threads)` to match.")
    end
    BLAS.set_num_threads(args.threads)

    commit = try
        strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String))
    catch
        "unknown"
    end

    workflows = build_workflows(args.fixtures)
    if args.workflow !== nothing
        workflows = filter(w -> w.name == args.workflow, workflows)
        isempty(workflows) && error("warm_timing.jl: unknown --workflow $(args.workflow)")
    end

    rows = String[]
    header = "engine\tworkflow\tleg\tthreads\treps\tmedian_s\tmin_s\tconverged\tloglik\tjulia_version\tblas_threads\tcommit"
    push!(rows, header)

    for w in workflows
        println("== $(w.name) ==")
        print("  warm-up (untimed) ... ")
        fit0 = w.fit()
        w.uncertainty(fit0)
        w.predict_leg(fit0)
        println("done")

        conv = fit_converged(fit0)
        ll = fit_loglik(fit0)

        fitref, fit_times = time_reps(w.fit, args.reps)
        conv = fit_converged(fitref); ll = fit_loglik(fitref)
        @printf("  fit:         median=%.4fs min=%.4fs conv=%s loglik=%.4f\n",
                median_(fit_times), minimum(fit_times), conv, ll)
        push!(rows, join(["julia", w.name, "fit", args.threads, args.reps,
                           @sprintf("%.6f", median_(fit_times)), @sprintf("%.6f", minimum(fit_times)),
                           conv, @sprintf("%.6f", ll), string(VERSION), BLAS.get_num_threads(), commit], "\t"))

        _, unc_times = time_reps(() -> w.uncertainty(fitref), args.reps)
        @printf("  uncertainty: median=%.4fs min=%.4fs\n", median_(unc_times), minimum(unc_times))
        push!(rows, join(["julia", w.name, "uncertainty", args.threads, args.reps,
                           @sprintf("%.6f", median_(unc_times)), @sprintf("%.6f", minimum(unc_times)),
                           conv, @sprintf("%.6f", ll), string(VERSION), BLAS.get_num_threads(), commit], "\t"))

        _, pred_times = time_reps(() -> w.predict_leg(fitref), args.reps)
        @printf("  predict:     median=%.4fs min=%.4fs\n", median_(pred_times), minimum(pred_times))
        push!(rows, join(["julia", w.name, "predict", args.threads, args.reps,
                           @sprintf("%.6f", median_(pred_times)), @sprintf("%.6f", minimum(pred_times)),
                           conv, @sprintf("%.6f", ll), string(VERSION), BLAS.get_num_threads(), commit], "\t"))
    end

    mkpath(dirname(args.out))
    open(args.out, "w") do io
        for r in rows
            println(io, r)
        end
    end
    println("wrote ", args.out)
end

function median_(xs)
    s = sort(xs); n = length(s)
    isodd(n) ? s[(n + 1) ÷ 2] : (s[n ÷ 2] + s[n ÷ 2 + 1]) / 2
end

main()
