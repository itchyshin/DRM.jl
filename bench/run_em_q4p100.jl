# run_em_q4p100.jl — fit the REAL q4_p100 fixture with the dense Laplace-EM and
# compare to drmTMB's reference (logLik = -513.99, wall-clock 2.585 s).
#
# Alignment (per test_step1_sparse.jl): the R side wrote
#   Σ_phy = vcv(tree)[tip.label, tip.label]   and   species = tip.label,
# so data row i ↔ Σ_phy row i ↔ df.species[i]. With one observation per
# species and the rows already in df order, species_idx is the identity and
# Σ_phy is used directly (no permutation).
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. run_em_q4p100.jl

using LinearAlgebra, Statistics, Printf
using CSV, DataFrames
include("q4_em_dense.jl")

const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))

# --- load fixture ----------------------------------------------------------
df = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame)
p = nrow(df)
@assert p == 100 "expected 100 rows, got $p"

Σ_phy = Matrix{Float64}(CSV.read(joinpath(FIX, "q4_p100_sigma_phy.csv"), DataFrame))
@assert size(Σ_phy) == (p, p) "Σ_phy not $(p)×$(p)"
Σ_phy = (Σ_phy + Σ_phy') / 2

# data row i ↔ Σ_phy row i (both in df.species order); confirm one row/species
@assert length(unique(df.species)) == p "expected one observation per species"

y1 = Vector{Float64}(df.y1)
y2 = Vector{Float64}(df.y2)
n  = p

# Designs match the drmTMB bf() spec: mu ~ 1 + x1, sigma ~ 1, rho ~ 1.
Xmu = hcat(ones(n), Vector{Float64}(df.x1))
X1  = reshape(ones(n), n, 1)
D   = Q4Design(Xmu, Xmu, X1, X1, X1)

const DRMTMB_LOGLIK = -513.99
const DRMTMB_TIME_S = 2.585

println("=== dense Laplace-EM, real q4_p100 fixture (p=$p) ===")
# warm-up (compile) — short
fit_q4_em(y1, y2, D, Σ_phy; max_em = 3, verbose = false)
t = @elapsed res = fit_q4_em(y1, y2, D, Σ_phy; max_em = 300, tol = 1e-6, verbose = true)

println("\n=== RESULT (q4_p100) ===")
@printf "wall-clock: %.3f s   iters: %d   converged: %s   logLik: %.4f\n" t res.iters res.converged res.loglik
@printf "monotone non-decreasing: %s\n" all(diff(res.ll_hist) .>= -1e-8)

pr = res.par
upk_cor = pr.Λ ./ sqrt.(diag(pr.Λ) * diag(pr.Λ)')
@printf "β_mu1     -> %s   (truth [1.0, 0.4])\n" round.(pr.β_mu1; digits=3)
@printf "β_mu2     -> %s   (truth [-0.5, 0.6])\n" round.(pr.β_mu2; digits=3)
@printf "β_sigma1  -> %s   (truth 0.1)\n" round.(pr.β_s1; digits=3)
@printf "β_sigma2  -> %s   (truth -0.05)\n" round.(pr.β_s2; digits=3)
@printf "β_rho12   -> %s   (truth 0.4)\n" round.(pr.β_rho; digits=3)
println("sd_phy    -> ", round.(sqrt.(diag(pr.Λ)); digits=3), "   (truth [0.7, 0.7, 0.3, 0.3])")
println("Λ =")
show(stdout, "text/plain", round.(pr.Λ; digits=4)); println()

println("\n=== vs drmTMB ===")
@printf "logLik:  EM %.4f   drmTMB %.4f   |Δ| = %.4f   gate(<1e-2): %s\n" res.loglik DRMTMB_LOGLIK abs(res.loglik - DRMTMB_LOGLIK) (abs(res.loglik - DRMTMB_LOGLIK) < 1e-2 ? "PASS" : "FAIL")
@printf "time:    EM %.3f s   drmTMB %.3f s   ratio %.2fx\n" t DRMTMB_TIME_S (t / DRMTMB_TIME_S)
println("\n=== q4_p100 EM complete ===")
