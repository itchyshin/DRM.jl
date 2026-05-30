# run_linesearch.jl — the 120-iter crawl is the LINE SEARCH (BackTracking is
# Armijo-only; LBFGS needs Wolfe curvature). Compare BackTracking vs HagerZhang
# (Wolfe) vs MoreThuente on q4_p100. drmTMB 2.48s, LL -256.52.
using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))
import Optim.LineSearches
const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LL=-256.52; const DRMTMB_T=2.48
df=CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy=augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
Λ0=Matrix(Symmetric([0.30 0.05 0.03 0.03;0.05 0.30 0.03 0.03;0.03 0.03 0.30 0.03;0.03 0.03 0.03 0.30]))

function trial(label, ls)
    fit()=fit_q4_sparse_tmb(prob,Q_cond;β0=β0,Λ0=Λ0,g_tol=1e-3,iterations=400,n_newton=40,linesearch=ls)
    try
        fit()                                   # warmup
        t=@elapsed r=fit()
        @printf "%-14s wall=%6.3fs  iters=%3d  f=%3d g=%3d  LL=%.4f |Δ|=%.4f conv=%s g_resid=%.1e  %s\n" label t r.iterations r.f_calls r.g_calls r.loglik abs(r.loglik-DRMTMB_LL) r.converged r.g_residual (t<DRMTMB_T ? "<<< FASTER" : "")
    catch e
        @printf "%-14s FAILED: %s\n" label sprint(showerror,e)[1:min(60,end)]
    end
end
println("=== line-search comparison, q4_p100 (drmTMB 2.48s, LL -256.52) ===")
trial("BackTracking", LineSearches.BackTracking())
trial("HagerZhang", LineSearches.HagerZhang())
trial("MoreThuente", LineSearches.MoreThuente())
println("=== done ===")
