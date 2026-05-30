# run_ml_warm_p100.jl — the headline single-fit benchmark: warm finite-diff ML
# vs drmTMB on real q4_p100 (drmTMB: 2.48s, logLik -256.52).
using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_ml_warm.jl"))
FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LL=-256.52; const DRMTMB_T=2.48
df=CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy=augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
println("=== warm finite-diff ML, real q4_p100 (p=$p) ===")
fit_ml_warm(prob,Q_cond,β0,Matrix(0.3*I(4));max_em=2,n_lam=1,verbose=false)  # warmup
t=@elapsed r=fit_ml_warm(prob,Q_cond,β0,Matrix(0.3*I(4));max_em=60,n_lam=2,tol=1e-4)
println("\n--- result ---")
@printf "logLik Julia=%.4f  drmTMB=%.4f  |Δ|=%.4f\n" r.loglik DRMTMB_LL abs(r.loglik-DRMTMB_LL)
@printf "wall Julia=%.2fs  drmTMB=%.2fs  ratio=%.2fx %s\n" t DRMTMB_T (DRMTMB_T/t) (t<DRMTMB_T ? "JULIA FASTER" : "(was 26.8s cold)")
@printf "iters=%d   Λ diag=%s\n" r.iters round.(diag(r.Λ);digits=3)
println("=== done ===")
