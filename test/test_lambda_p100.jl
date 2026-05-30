# test_lambda_p100.jl — does the EM Λ update ASCEND the true marginal on the
# REAL q4_p100 data? If yes, the p=100 freeze was the guard's warm-started
# E-step not re-converging (fixable); if no, the REML correction matters at scale.
using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "sparse_em_fit.jl"))
FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
df = CSV.read(joinpath(FIX,"q4_p100.csv"),DataFrame); p=nrow(df); n=p
phy = augmented_phy(read(joinpath(FIX,"q4_p100_tree.nwk"),String))
name2row=Dict(String(s)=>i for (i,s) in enumerate(df.species)); perm=[name2row[phy.leaf_names[k]] for k in 1:p]
y1=Vector{Float64}(df.y1)[perm];y2=Vector{Float64}(df.y2)[perm];x1=Vector{Float64}(df.x1)[perm]
X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
prob,Q_cond = make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])

# FULLY-converged E-step (no warm start, many Newton iters) for accurate marginals
function L_of_Λ(Λ; nit=60)
    P=prior_precision(Q_cond,inv(Λ)); u,ch,_=estep_mode(prob,P,β;u0=nothing,n_newton=nit); laplace_ll(prob,P,β,u,ch)
end
Λ0=Matrix(0.3*I(4)); L0=L_of_Λ(Λ0)
@printf "L0(Λ=0.3I)=%.4f\n" L0
P0=prior_precision(Q_cond,inv(Λ0)); u0,ch0,_=estep_mode(prob,P0,β;n_newton=60)
Λem=mstep_Lambda(prob,Q_cond,u0,ch0)
@printf "Λ_em diag=%s\n" round.(diag(Λem);digits=3)
for α in (1.0,0.5,0.25,0.1,0.01)
    Λα=Matrix(Symmetric(Λ0 .+ α.*(Λem.-Λ0)))
    @printf "  EM dir α=%.2f: ΔL=%.4f  %s\n" α (L_of_Λ(Λα)-L0) (L_of_Λ(Λα)>L0 ? "UP" : "down")
end
println(L_of_Λ(Λem)>L0 ? "EM ASCENDS at p=100 -> freeze was the guard/warm-start" :
                          "EM DESCENDS at p=100 -> REML correction needed at scale")
println("=== done ===")
