# fit_phylo_family.jl -- Julia side of the non-Gaussian phylo benchmark.
#
# Run from repo root after `Rscript bench/R/gen_phylo_family.R`:
#   julia --project=bench bench/fit_phylo_family.jl

import Pkg
Pkg.activate(dirname(@__DIR__))

using DRM
using DelimitedFiles, LinearAlgebra, Printf, Statistics

BLAS.set_num_threads(1)

const FIXDIR = joinpath(@__DIR__, "fixtures", "phylo_family")
const OUTDIR = joinpath(@__DIR__, "results", "phylo_family")
mkpath(OUTDIR)

const CELLS = [
    (id = "small", p = 16, n_each = 20, reps = 3),
    (id = "medium", p = 64, n_each = 20, reps = 3),
]

const FAMILIES = ["nb2", "gamma", "beta"]

json_str(x::AbstractString) = "\"" * replace(x, "\\" => "\\\\", "\"" => "\\\"") * "\""
json_val(x::Bool) = x ? "true" : "false"
json_val(x::Integer) = string(x)
json_val(x::Real) = isfinite(x) ? @sprintf("%.17g", x) : "null"
json_val(x::AbstractString) = json_str(x)
json_val(x::AbstractVector) = "[" * join(json_val.(x), ",") * "]"
json_val(::Nothing) = "null"
function json_obj(pairs)
    "{" * join([json_str(String(k)) * ":" * json_val(v) for (k, v) in pairs], ",") * "}"
end

function read_fixture(id)
    raw = readdlm(joinpath(FIXDIR, "$id.csv"), ',', String; header = true)[1]
    species = raw[:, 1]
    x = parse.(Float64, raw[:, 2])
    y_nb = Float64.(parse.(Int, raw[:, 3]))
    y_gamma = parse.(Float64, raw[:, 4])
    y_beta = parse.(Float64, raw[:, 5])
    K = Matrix{Float64}(readdlm(joinpath(FIXDIR, "$(id)_K.csv"), ','))
    return (; species, x, y_nb, y_gamma, y_beta, K)
end

function design_parts(dat)
    n = length(dat.x)
    X = hcat(ones(n), dat.x)
    Xσ = ones(n, 1)
    gidx, G = DRM._group_index(dat.species)
    return X, Xσ, gidx, G
end

function fit_family(family, dat)
    X, Xσ, gidx, G = design_parts(dat)
    nmμ = ["(Intercept)", "x"]
    nmσ = ["(Intercept)"]
    label = "phylo(1 | species)"
    if family == "nb2"
        return DRM._fit_nb2_phylo_laplace(
            DRM.NegBinomial2(), dat.y_nb, X, Xσ, gidx, G, dat.K, nmμ, nmσ, label, 1e-7
        )
    elseif family == "gamma"
        return DRM._fit_gamma_phylo_laplace(
            DRM.Gamma(), dat.y_gamma, X, Xσ, gidx, G, dat.K, nmμ, nmσ, label, 1e-7
        )
    elseif family == "beta"
        return DRM._fit_beta_phylo_laplace(
            DRM.Beta(), dat.y_beta, X, Xσ, gidx, G, dat.K, nmμ, nmσ, label, 1e-7
        )
    end
    error("unknown family: $family")
end

function nuisance_value(family, fit)
    if family == "nb2"
        return exp(coef(fit, :sigma)[1])
    elseif family == "gamma" || family == "beta"
        return exp(-2 * coef(fit, :sigma)[1])
    end
    return NaN
end

function run_one(cell, family)
    dat = read_fixture(cell.id)
    fit_family(family, dat)
    times = Float64[]
    fits = Any[]
    for _ in 1:cell.reps
        fit = nothing
        t = @elapsed fit = fit_family(family, dat)
        push!(times, t)
        push!(fits, fit)
    end
    fit = fits[end]
    row = [
        :cell_id => cell.id,
        :family => family,
        :engine => "julia_structured_laplace_internal",
        :n => length(dat.x),
        :p => cell.p,
        :time_s => mean(times),
        :time_s_med => median(times),
        :times_all => times,
        :logLik => loglik(fit),
        :converged => fit.converged,
        :beta_mu => collect(coef(fit, :mu)),
        :nuisance => nuisance_value(family, fit),
        :sd_phylo => exp(coef(fit, :resd)[1]),
        :julia_threads => Threads.nthreads(),
        :blas_threads => BLAS.get_num_threads(),
    ]
    @printf("[Julia %-5s %-6s] p=%d n=%d med=%.4fs conv=%s beta1=%.3f sd=%.3f nuis=%.3f\n",
            family, cell.id, cell.p, length(dat.x), row[7][2], row[10][2],
            row[11][2][2], row[13][2], row[12][2])
    return row
end

results = Any[]
for cell in CELLS, family in FAMILIES
    push!(results, run_one(cell, family))
end

open(joinpath(OUTDIR, "julia_phylo_family.json"), "w") do io
    println(io, "[")
    for (i, row) in enumerate(results)
        comma = i == length(results) ? "" : ","
        println(io, "  ", json_obj(row), comma)
    end
    println(io, "]")
end
