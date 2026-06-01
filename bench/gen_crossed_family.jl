# gen_crossed_family.jl -- deterministic #80 crossed-family benchmark fixtures.
#
# Writes bench/fixtures/crossed_family/*.csv. The same rows feed Julia and
# drmTMB so coefficient, likelihood/objective, and timing comparisons are paired.

import Pkg
Pkg.activate(dirname(@__DIR__))

using Random, Printf
import Distributions

const OUTDIR = joinpath(@__DIR__, "fixtures", "crossed_family")
mkpath(OUTDIR)

const CELLS = [
    (id = "small", G = 20, H = 20, n = 1000, reps = 3),
    (id = "medium", G = 50, H = 50, n = 5000, reps = 3),
    (id = "fixedq_n20000", G = 50, H = 50, n = 20000, reps = 2),
]

const β0 = 0.25
const β1 = 0.45
const σg = 0.45
const σh = 0.35
const nb_size = 3.0
const gamma_shape = 7.0
const beta_precision = 25.0
const binomial_trials = 8

logistic(x) = 1 / (1 + exp(-x))

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

function write_csv(path, x, g, h, y_pois, y_nb, s, fail, y_gamma, y_beta)
    open(path, "w") do io
        println(io, "x,g,h,y_pois,y_nb,s,fail,y_gamma,y_beta")
        for i in eachindex(x)
            @printf(io, "%.17g,g%d,h%d,%d,%d,%d,%d,%.17g,%.17g\n",
                    x[i], g[i], h[i], y_pois[i], y_nb[i], s[i], fail[i],
                    y_gamma[i], y_beta[i])
        end
    end
end

function fixture!(cell, seed)
    rng = MersenneTwister(seed)
    n = cell.n
    g = rand(rng, 1:cell.G, n)
    h = rand(rng, 1:cell.H, n)
    x = randn(rng, n)
    bg = σg .* randn(rng, cell.G)
    bh = σh .* randn(rng, cell.H)
    η = β0 .+ β1 .* x .+ bg[g] .+ bh[h]
    μ = exp.(η)
    p = logistic.(η)
    y_pois = [poisson_knuth(rng, μi) for μi in μ]
    y_nb = [rand(rng, Distributions.NegativeBinomial(nb_size, nb_size / (nb_size + μ[i]))) for i in 1:n]
    s = [rand(rng, Distributions.Binomial(binomial_trials, p[i])) for i in 1:n]
    fail = binomial_trials .- s
    y_gamma = [rand(rng, Distributions.Gamma(gamma_shape, μ[i] / gamma_shape)) for i in 1:n]
    y_beta = [rand(rng, Distributions.Beta(p[i] * beta_precision, (1 - p[i]) * beta_precision)) for i in 1:n]
    write_csv(joinpath(OUTDIR, "$(cell.id).csv"), x, g, h, y_pois, y_nb, s, fail, y_gamma, y_beta)
end

for (i, cell) in enumerate(CELLS)
    fixture!(cell, 20260820 + i)
    @printf("wrote %s n=%d G=%d H=%d\n", cell.id, cell.n, cell.G, cell.H)
end

open(joinpath(OUTDIR, "truth.json"), "w") do io
    println(io, "{")
    println(io, "  \"beta\": [$β0, $β1],")
    println(io, "  \"sigma_g\": $σg,")
    println(io, "  \"sigma_h\": $σh,")
    println(io, "  \"nb_size\": $nb_size,")
    println(io, "  \"gamma_shape\": $gamma_shape,")
    println(io, "  \"beta_precision\": $beta_precision,")
    println(io, "  \"binomial_trials\": $binomial_trials,")
    println(io, "  \"cells\": [")
    for (i, cell) in enumerate(CELLS)
        comma = i == length(CELLS) ? "" : ","
        println(io, "    {\"cell_id\":\"$(cell.id)\",\"G\":$(cell.G),\"H\":$(cell.H),\"n\":$(cell.n),\"reps\":$(cell.reps)}$comma")
    end
    println(io, "  ]")
    println(io, "}")
end
