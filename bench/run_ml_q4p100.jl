# run_ml_q4p100.jl — BASELINE benchmark (pre-Takahashi-optimization): the
# current CORRECT ML fit (Λ estimated via marginal ascent) vs drmTMB on the
# real q4_p100. Reconciles the logLik (same ML objective) and gives the honest
# current wall-clock, so we can measure the analytic-gradient speedup later.

using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_ml_q4.jl"))

FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LL = -513.99; const DRMTMB_T = 2.585

df = CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy = augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond = make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])

println("=== BASELINE ML fit (pre-Takahashi), real q4_p100 (p=$p) ===")
# modest settings to keep the finite-diff baseline tractable
fit_ml(prob,Q_cond,β0,Matrix(0.3*I(4)); max_em=2, n_lam=1, verbose=false)  # warmup
t=@elapsed r=fit_ml(prob,Q_cond,β0,Matrix(0.3*I(4)); max_em=40, n_lam=2, tol=1e-4, verbose=true)
println("\n--- result ---")
@printf "logLik Julia(ML)=%.4f   drmTMB=%.4f   |Δ|=%.4f\n" r.loglik DRMTMB_LL abs(r.loglik-DRMTMB_LL)
@printf "wall Julia=%.2fs   drmTMB=%.3fs   ratio=%.2fx %s\n" t DRMTMB_T (DRMTMB_T/t) (t<DRMTMB_T ? "(Julia faster)" : "(Julia slower — pre-optimization)")
@printf "iters=%d\n" r.iters
@printf "β_mu1=%s β_mu2=%s β_s1=%s β_s2=%s β_rho=%s\n" round.(r.β.mu1;digits=3) round.(r.β.mu2;digits=3) round.(r.β.s1;digits=3) round.(r.β.s2;digits=3) round.(r.β.rho;digits=3)
println("Λ diag=", round.(diag(r.Λ);digits=3))
println("=== done ===")
