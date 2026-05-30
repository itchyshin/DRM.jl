# run_sparse_tmb_q4p100.jl — fit the REAL q4_p100 fixture with the SPARSE
# TMB-like exact-gradient LBFGS (fit_q4_sparse_tmb.jl), verified to <1e-4 vs FD
# at p=8/p=20 by check_sparse_tmb.jl. Compares to drmTMB (logLik −256.52, 2.48 s).
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. run_sparse_tmb_q4p100.jl

using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LL = -256.52      # results/r_results.json (the −513.99 in old scripts was a wrong constant)
const DRMTMB_T  = 2.48

df = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame)
p = nrow(df); n = p
newick = read(joinpath(FIX, "q4_p100_tree.nwk"), String)
phy = augmented_phy(newick)
@assert phy.n_leaves == p

# Align data rows to phy.leaf_names (Newick) order (data leaf k == phy leaf k).
name2row = Dict(String(s) => i for (i, s) in enumerate(df.species))
perm = [name2row[phy.leaf_names[k]] for k in 1:p]
y1 = Vector{Float64}(df.y1)[perm]; y2 = Vector{Float64}(df.y2)[perm]
x1 = Vector{Float64}(df.x1)[perm]
X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)

prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
β0 = (mu1 = X1 \ y1, mu2 = X2 \ y2,
      s1 = [log(std(y1 .- X1 * (X1 \ y1)))], s2 = [log(std(y2 .- X2 * (X2 \ y2)))], rho = [0.0])
Λ0 = Matrix(0.3 * I(4))

println("=== sparse TMB-like exact-gradient LBFGS, real q4_p100 (p=$p) ===")
# warm-up (compile)
fit_q4_sparse_tmb(prob, Q_cond; β0 = β0, Λ0 = Λ0, g_tol = 1e-3, iterations = 200,
                  n_newton = 40, show_trace = false)
t1 = @elapsed r1 = fit_q4_sparse_tmb(prob, Q_cond; β0 = β0, Λ0 = Λ0, g_tol = 1e-3,
                                     iterations = 200, n_newton = 40, show_trace = false)
t2 = @elapsed r2 = fit_q4_sparse_tmb(prob, Q_cond; β0 = β0, Λ0 = Λ0, g_tol = 1e-3,
                                     iterations = 200, n_newton = 40, show_trace = false)
tmed = (t1 + t2) / 2

println("\n--- q4_p100 result (sparse TMB-like) ---")
@printf "logLik (Julia):  %.4f\n" r1.loglik
@printf "logLik (drmTMB): %.4f   |Δ| = %.4f\n" DRMTMB_LL abs(r1.loglik - DRMTMB_LL)
@printf "converged: %s   iters: %d   g_resid: %.2e   f_calls: %d   g_calls: %d\n" r1.converged r1.iterations r1.g_residual r1.f_calls r1.g_calls
@printf "wall-clock Julia: %.4f s (median of 2; runs %.4f, %.4f)\n" tmed t1 t2
@printf "wall-clock drmTMB: %.3f s   ->  speedup = %.2fx %s\n" DRMTMB_T (DRMTMB_T / tmed) (tmed < DRMTMB_T ? "(Julia faster)" : "(Julia slower)")
@printf "β_mu1=%s β_mu2=%s β_s1=%s β_s2=%s β_rho=%s\n" round.(r1.β.mu1;digits=3) round.(r1.β.mu2;digits=3) round.(r1.β.s1;digits=3) round.(r1.β.s2;digits=3) round.(r1.β.rho;digits=3)
println("Λ diag = ", round.(diag(r1.Λ); digits=4))
# sd_phy = sqrt of Λ diagonal (drmTMB reports sd_phy=[1.70,0.89,0.18,0.29])
println("sd_phy (= sqrt diag Λ) = ", round.(sqrt.(diag(r1.Λ)); digits=4))
println("=== done ===")
