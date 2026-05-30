# run_sparse_q4p100.jl — fit the REAL q4_p100 fixture with the sparse
# augmented Laplace-EM and compare to drmTMB (logLik -513.99, 2.585 s).
# Uses the real ultrametric tree (augmented_phy on the .nwk) → sparse,
# well-conditioned (the dense route got NaN here).

using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "sparse_em_fit.jl"))

const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LL = -513.99
const DRMTMB_T = 2.585

df = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame)
p = nrow(df)
newick = read(joinpath(FIX, "q4_p100_tree.nwk"), String)
phy = augmented_phy(newick)
@assert phy.n_leaves == p

# Reorder data rows into phy.leaf_names (Newick) order so data leaf k = phy leaf k.
name2row = Dict(String(s) => i for (i, s) in enumerate(df.species))
perm = [name2row[phy.leaf_names[k]] for k in 1:p]
y1 = Vector{Float64}(df.y1)[perm]; y2 = Vector{Float64}(df.y2)[perm]
x1 = Vector{Float64}(df.x1)[perm]
n = p
X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)

prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
β0 = (mu1=X1\y1, mu2=X2\y2, s1=[log(std(y1 .- X1*(X1\y1)))], s2=[log(std(y2 .- X2*(X2\y2)))], rho=[0.0])

println("=== sparse augmented Laplace-EM, real q4_p100 (p=$p) ===")
# warm-up (compile) with few iters
fit_em_aug(prob, Q_cond, β0, Matrix(0.3*I(4)); max_em=2, verbose=false)
t1 = @elapsed r1 = fit_em_aug(prob, Q_cond, β0, Matrix(0.3*I(4)); max_em=300, tol=1e-6, verbose=true)
t2 = @elapsed r2 = fit_em_aug(prob, Q_cond, β0, Matrix(0.3*I(4)); max_em=300, tol=1e-6, verbose=false)
tmed = (t1 + t2) / 2

println("\n--- q4_p100 result (sparse EM) ---")
@printf "logLik (Julia):  %.4f\n" r1.loglik
@printf "logLik (drmTMB): %.4f   |Δ| = %.4f\n" DRMTMB_LL abs(r1.loglik - DRMTMB_LL)
@printf "converged: %s  iters: %d\n" r1.converged r1.iters
@printf "wall-clock Julia: %.4f s (median of 2)\n" tmed
@printf "wall-clock drmTMB: %.3f s  ->  SPEEDUP = %.2fx\n" DRMTMB_T (DRMTMB_T / tmed)
@printf "β_mu1=%s β_mu2=%s β_s1=%s β_s2=%s β_rho=%s\n" round.(r1.β.mu1;digits=3) round.(r1.β.mu2;digits=3) round.(r1.β.s1;digits=3) round.(r1.β.s2;digits=3) round.(r1.β.rho;digits=3)
println("Λ diag = ", round.(diag(r1.Λ); digits=3))
println("=== done ===")
