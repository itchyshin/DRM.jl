# gen_crossed_poisson.jl — deterministic fixtures for #70 crossed Poisson GLMM.
#
# Writes bench/fixtures/crossed_poisson/*.csv plus truth.json. The same fixtures
# are consumed by the Julia and R/drmTMB benchmark runners.

using Random, Printf

const OUTDIR = joinpath(@__DIR__, "fixtures", "crossed_poisson")
mkpath(OUTDIR)

const CELLS = [
    (id = "single_control", kind = "single", G = 50, H = 0, n = 1500, reps = 5),
    (id = "crossed_small", kind = "crossed", G = 20, H = 20, n = 1000, reps = 5),
    (id = "crossed_medium", kind = "crossed", G = 50, H = 50, n = 5000, reps = 5),
    (id = "crossed_large", kind = "crossed", G = 100, H = 100, n = 20000, reps = 3),
    (id = "fixedq_n1000", kind = "crossed", G = 50, H = 50, n = 1000, reps = 5),
    (id = "fixedq_n20000", kind = "crossed", G = 50, H = 50, n = 20000, reps = 3),
]

const β0 = 0.25
const β1 = 0.45
const σg = 0.45
const σh = 0.35

function poisson_knuth(rng, λ)
    λ <= 30 || return max(0, round(Int, λ + sqrt(λ) * randn(rng)))
    L = exp(-λ)
    k = 0
    p = 1.0
    while p > L
        k += 1
        p *= rand(rng)
    end
    return k - 1
end

function write_csv(path, y, x, g, h)
    open(path, "w") do io
        println(io, "y,x,g,h")
        for i in eachindex(y)
            @printf(io, "%d,%.17g,g%d,h%d\n", y[i], x[i], g[i], h[i])
        end
    end
end

function fixture!(cell, seed)
    rng = MersenneTwister(seed)
    n = cell.n
    G = cell.G
    H = cell.kind == "single" ? 1 : cell.H
    g = cell.kind == "single" ? repeat(1:G, inner = div(n, G)) : rand(rng, 1:G, n)
    if length(g) < n
        append!(g, rand(rng, 1:G, n - length(g)))
    end
    h = cell.kind == "single" ? ones(Int, n) : rand(rng, 1:H, n)
    x = randn(rng, n)
    bg = σg .* randn(rng, G)
    bh = cell.kind == "single" ? zeros(H) : σh .* randn(rng, H)
    η = β0 .+ β1 .* x .+ bg[g] .+ bh[h]
    y = [poisson_knuth(rng, exp(ηi)) for ηi in η]
    write_csv(joinpath(OUTDIR, "$(cell.id).csv"), y, x, g, h)
end

for (i, cell) in enumerate(CELLS)
    fixture!(cell, 20260710 + i)
    @printf("wrote %s n=%d G=%d H=%d\n", cell.id, cell.n, cell.G, cell.H)
end

open(joinpath(OUTDIR, "truth.json"), "w") do io
    println(io, "{")
    println(io, "  \"beta\": [$β0, $β1],")
    println(io, "  \"sigma_g\": $σg,")
    println(io, "  \"sigma_h\": $σh,")
    println(io, "  \"cells\": [")
    for (i, cell) in enumerate(CELLS)
        comma = i == length(CELLS) ? "" : ","
        println(io, "    {\"cell_id\":\"$(cell.id)\",\"kind\":\"$(cell.kind)\",\"G\":$(cell.G),\"H\":$(cell.H),\"n\":$(cell.n),\"reps\":$(cell.reps)}$comma")
    end
    println(io, "  ]")
    println(io, "}")
end
