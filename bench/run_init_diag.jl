# run_init_diag.jl — distinguish "bad Λ0 scale" from "singularity at the optimum"
# as the cause of the 120-iter crawl. (1) naive Λ0 -> print FINAL Λ (are (3,1),
# (4,2) near 0?). (2) well-scaled Λ0 (diag near the known optimum + small off-
# diag) -> does iteration count drop? Tests the user's starting-point lever.
using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))
const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LL=-256.52; const DRMTMB_T=2.48
df=CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy=augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
fitit(Λ0)=fit_q4_sparse_tmb(prob,Q_cond;β0=β0,Λ0=Matrix(Symmetric(Λ0)),g_tol=1e-3,iterations=400,n_newton=40)

Λnaive=Matrix(Symmetric([0.30 0.05 0.03 0.03;0.05 0.30 0.03 0.03;0.03 0.03 0.30 0.03;0.03 0.03 0.03 0.30]))
fitit(Λnaive)                                  # warmup
t1=@elapsed r1=fitit(Λnaive)
println("=== (1) naive Λ0 ===")
@printf "total=%.3fs iters=%d LL=%.4f conv=%s g_resid=%.2e\n" t1 r1.iterations r1.loglik r1.converged r1.g_residual
println("FINAL Λ:"); show(stdout,"text/plain",round.(r1.Λ;digits=4)); println()
@printf "FINAL Λ[3,1]=%.5f (μ1-σ1)  Λ[4,2]=%.5f (μ2-σ2)  <- near 0 => singularity at optimum\n" r1.Λ[3,1] r1.Λ[4,2]

# (2) well-scaled Λ0: diag near our converged optimum, small off-diagonals
Λscaled=Matrix(Symmetric([0.95 0.05 0.03 0.02;0.05 0.27 0.02 0.02;0.03 0.02 0.04 0.01;0.02 0.02 0.01 0.05]))
@assert isposdef(Λscaled)
t2=@elapsed r2=fitit(Λscaled)
println("\n=== (2) well-scaled Λ0 (diag≈optimum) ===")
@printf "total=%.3fs iters=%d LL=%.4f conv=%s g_resid=%.2e\n" t2 r2.iterations r2.loglik r2.converged r2.g_residual
@printf "\nVERDICT: naive %d iters vs scaled %d iters -> %s\n" r1.iterations r2.iterations (r2.iterations < 0.6*r1.iterations ? "Λ0 SCALE is the lever" : "scale doesn't help much -> singularity/line-search")
println("=== done ===")
