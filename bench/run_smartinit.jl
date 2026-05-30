# run_smartinit.jl — starting-point tricks for the TMB-like LBFGS. Innovative
# combination: seed the exact-gradient LBFGS with k cheap closed-form EM steps,
# which (a) move near the optimum (fewer LBFGS iters) and (b) introduce off-
# diagonal Λ structure so we start OFF the lc3/lc7 diagonal singularity.
# Compares: naive Λ0 (baseline 3.0s/120it) vs 1-step vs 2-step EM seed.
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

pd_clamp(Λ; floor=1e-4) = (E=eigen(Symmetric(Matrix(Λ))); Matrix(Symmetric(E.vectors*Diagonal(max.(E.values,floor))*E.vectors')))

function em_seed(β, Λ, k)
    for _ in 1:k
        P=prior_precision(Q_cond,inv(Λ)); u,ch,_=estep_mode(prob,P,β;n_newton=60)
        β=mstep_beta(prob,u,β); Λ=pd_clamp(mstep_Lambda(prob,Q_cond,u,ch))
    end
    return β,Λ
end

function trial(label, seedk, Λ0naive)
    seed()= seedk==0 ? (β0, Λ0naive) : em_seed(β0, Matrix(0.3*I(4)), seedk)
    fit(βs,Λs)=fit_q4_sparse_tmb(prob,Q_cond;β0=βs,Λ0=Λs,g_tol=1e-3,iterations=400,n_newton=40)
    βs,Λs=seed(); fit(βs,Λs)                       # warmup (compile)
    t=@elapsed begin βs,Λs=seed(); r=fit(βs,Λs) end
    @printf "%-18s total=%6.3fs  iters=%3d  LL=%.4f |Δ|=%.4f  conv=%s  off-diag(seed)=%.3f\n" label t r.iterations r.loglik abs(r.loglik-DRMTMB_LL) r.converged maximum(abs.(Λs-Diagonal(Λs)))
    return r
end

Λ0naive=Matrix(Symmetric([0.30 0.05 0.03 0.03;0.05 0.30 0.03 0.03;0.03 0.03 0.30 0.03;0.03 0.03 0.03 0.30]))
println("=== starting-point tricks, q4_p100 (drmTMB 2.48s, LL -256.52) ===")
trial("naive Λ0 (base)", 0, Λ0naive)
trial("1-step EM seed", 1, Λ0naive)
trial("2-step EM seed", 2, Λ0naive)
trial("3-step EM seed", 3, Λ0naive)
println("=== done ===")
