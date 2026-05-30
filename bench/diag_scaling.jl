# diag_scaling.jl — root-cause the scaling-trial failures (NOT assume).
# (1) Is the p>=500 NaN crash in the TEST HARNESS (dense ultrametric Σ_phy chol,
#     known ill-conditioned) or in the FIT engine (sparse, should be fine)?
# (2) Is the p=100 synthetic 1-iter quit a NON-FINITE exact gradient at init?
using LinearAlgebra, SparseArrays, Random, Statistics, Printf
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))
const βt=(mu1=[1.0,0.5],mu2=[-0.3,0.4],s1=[-0.4],s2=[-0.5],rho=[0.3])
const Λt=Matrix(Symmetric([0.25 0.10 0.05 0.0;0.10 0.25 0.0 0.04;0.05 0.0 0.09 0.02;0.0 0.04 0.02 0.09]))
const Λ0=Matrix(Symmetric(0.3*I(4)+0.03*(ones(4,4)-I(4))))
function gen(p; seed=1)
    Random.seed!(seed); n=p
    phy=random_balanced_tree(p;branch_length=0.2); Σ_phy=sigma_phy_dense(phy;σ²_phy=1.0)
    x1=randn(n);X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
    U=cholesky(Λt).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
    y1=zeros(n);y2=zeros(n)
    for i in 1:n
        m1=dot(X1[i,:],βt.mu1)+U[1,i];m2=dot(X2[i,:],βt.mu2)+U[2,i]
        s1=exp(dot(Xs1[i,:],βt.s1)+U[3,i]);s2=exp(dot(Xs2[i,:],βt.s2)+U[4,i])
        ρ=RHO_GUARD*tanh(dot(Xr[i,:],βt.rho));e=cholesky([s1^2 ρ*s1*s2;ρ*s1*s2 s2^2]).L*randn(2);y1[i]=m1+e[1];y2[i]=m2+e[2]
    end
    prob,Q=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
    β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
    return prob,Q,β0
end

# (1) conditioning of the dense generator's Σ_phy + does gen crash at scale?
for p in (100, 500, 1000)
    phy=random_balanced_tree(p;branch_length=0.2); Σ=sigma_phy_dense(phy;σ²_phy=1.0)
    @printf "p=%-4d cond(Σ_phy dense)=%.2e  depth≈%d  " p cond(Σ) Int(ceil(log2(p)))
    try; gen(p); println("gen OK"); catch e; println("gen CRASH: ", sprint(showerror,e)[1:min(45,end)]); end
end

# (2) p=100 synthetic: is the exact gradient finite & a descent direction at init?
println("\n--- p=100 synthetic, exact gradient at off-diagonal init ---")
prob,Q,β0=gen(100); θ0=pack_theta(β0,Λ0)
nll,g,u,_=marginal_and_exact_grad(prob,Q,θ0;n_newton=80)
@printf "nll=%.3f  |g|=%.3e  finite components=%d/17\n" nll norm(g) count(isfinite,g)
println("grad=",round.(g;digits=2))
println("=== done ===")
