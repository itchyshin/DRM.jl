# diag2.jl — where does finiteness break at scale? Check the E-step mode and the
# exact gradient at the INIT for p=100/500/1000, plus whether the Newton mode
# converged (residual) or hit the cap.
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
# Is the E-step SLOW (more iters fixes it) or STUCK (premature break)?
for p in (500, 1000)
    prob,Q,β0=gen(p); P=prior_precision(Q,inv(Λ0))
    @printf "p=%d:\n" p
    for nn in (40, 150, 400, 1000)
        u,_,_=estep_mode(prob,P,β0;n_newton=nn)
        @printf "  n_newton=%-4d  ||∇_u||@mode=%.3e  max|u|=%.2f\n" nn norm(joint_grad(prob,P,u,β0)) maximum(abs,u)
    end
end
println("=== done ===")
