#!/usr/bin/env julia
# tools/warm_timing_compare.jl — S12 (#563), root gate G5.
#
# Joins a Julia warm-timing TSV (tools/warm_timing.jl) and an R warm-timing
# TSV (tools/warm_timing.R) on workflow x leg x threads, computes the
# R/Julia wall-time ratio, prints a Markdown table, and a G5 verdict line per
# workflow:
#   WIN  -- ratio > 1 (Julia faster) on every leg BOTH engines support
#   LOSS -- named leg where ratio <= 1 (R faster or tied), ratio given
#   N/A  -- a leg neither/either engine could not run (missing row) --
#           reported, never silently dropped (a leg drmTMB does not support
#           at all is "n/a", per the registry doc; a leg that FAILED to fit
#           at all is reported as a loss-shaped gap, not hidden as n/a)
#
# Usage:
#   julia --project=. tools/warm_timing_compare.jl \
#       --julia docs/dev-log/evidence/julia-r-parity/warm-timing-julia-t1.tsv \
#       --r     docs/dev-log/evidence/julia-r-parity/warm-timing-r-t1.tsv

function parse_args(argv)
    jpath = nothing; rpath = nothing
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--julia"
            jpath = argv[i + 1]; i += 2
        elseif a == "--r"
            rpath = argv[i + 1]; i += 2
        else
            error("warm_timing_compare.jl: unknown arg $a")
        end
    end
    (jpath === nothing || rpath === nothing) &&
        error("warm_timing_compare.jl: --julia FILE and --r FILE are both required")
    return jpath, rpath
end

function read_tsv(path)
    lines = readlines(path)
    header = split(lines[1], "\t")
    rows = Dict{String,String}[]
    for l in lines[2:end]
        isempty(l) && continue
        vals = split(l, "\t")
        push!(rows, Dict(String(h) => String(v) for (h, v) in zip(header, vals)))
    end
    return rows
end

key(r) = (r["workflow"], r["leg"], r["threads"])

function main()
    jpath, rpath = parse_args(ARGS)
    jrows = read_tsv(jpath)
    rrows = read_tsv(rpath)

    jmap = Dict(key(r) => r for r in jrows)
    rmap = Dict(key(r) => r for r in rrows)
    all_keys = sort(collect(union(keys(jmap), keys(rmap))))

    println("| workflow | leg | threads | R median (s) | Julia median (s) | ratio (R/Julia) | verdict |")
    println("|---|---|---|---|---|---|---|")

    workflow_leg_ratio = Dict{String,Vector{Tuple{String,Union{Float64,Nothing}}}}()

    for k in all_keys
        wf, leg, thr = k
        jr = get(jmap, k, nothing)
        rr = get(rmap, k, nothing)
        if jr === nothing || rr === nothing
            note = jr === nothing && rr === nothing ? "NEITHER ENGINE" :
                   jr === nothing ? "JULIA MISSING" : "R MISSING (n/a or not run)"
            println("| $wf | $leg | $thr | - | - | - | N/A ($note) |")
            push!(get!(workflow_leg_ratio, wf, Tuple{String,Union{Float64,Nothing}}[]), (leg, nothing))
            continue
        end
        rmed = parse(Float64, rr["median_s"])
        jmed = parse(Float64, jr["median_s"])
        ratio = jmed > 0 ? rmed / jmed : Inf
        verdict = ratio > 1 ? "julia faster" : "R faster/tied"
        println("| $wf | $leg | $thr | $(round(rmed, digits=4)) | $(round(jmed, digits=4)) | $(round(ratio, digits=2))x | $verdict |")
        push!(get!(workflow_leg_ratio, wf, Tuple{String,Union{Float64,Nothing}}[]), (leg, ratio))
    end

    println()
    println("## G5 verdict per workflow")
    println()
    for wf in sort(collect(keys(workflow_leg_ratio)))
        legs = workflow_leg_ratio[wf]
        missing_legs = [l for (l, r) in legs if r === nothing]
        losses = [(l, r) for (l, r) in legs if r !== nothing && r <= 1]
        if !isempty(losses)
            desc = join(["$l (ratio=$(round(r, digits=2))x)" for (l, r) in losses], ", ")
            println("- **$wf**: LOSS -- $desc")
        elseif !isempty(missing_legs) && length(missing_legs) == length(legs)
            println("- **$wf**: N/A -- no comparable legs run on both engines")
        else
            note = isempty(missing_legs) ? "" : " (legs not compared: $(join(missing_legs, ", ")) -- see registry doc for whether n/a or not-yet-run)"
            println("- **$wf**: WIN -- Julia faster on every compared leg$note")
        end
    end
end

main()
