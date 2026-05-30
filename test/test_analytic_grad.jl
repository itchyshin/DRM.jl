# test_analytic_grad.jl — verify the analytic Λ gradient against finite diff.
# Derivation: ∂L/∂Λ = ½ N Λ⁻¹ (Λ_em − Λ) Λ⁻¹, with Λ_em = mstep_Lambda (O(p),
# Takahashi). If the directional derivative along G matches FD, integrate it
# (replaces the 20-eval finite-diff Λ gradient → ~20× faster single fit).
using LinearAlgebra, SparseArrays, ForwardDiff, Random, Statistics, Printf
include(joinpath(@__DIR__, "sparse_em_fit.jl"))

Random.seed!(7); p=8; n=p
phy=random_balanced_tree(p;branch_length=0.2); Σ_phy=sigma_phy_dense(phy;σ²_phy=1.0)
βt=(mu1=[1.0,0.5],mu2=[-0.3,0.4],s1=[-0.4],s2=[-0.5],rho=[0.3])
Λt=[0.25 0.10 0.05 0.0;0.10 0.25 0.0 0.04;0.05 0.0 0.09 0.02;0.0 0.04 0.02 0.09];Λt=(Λt+Λt')/2
x1=randn(n);X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
U=cholesky(Λt).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
y1=zeros(n);y2=zeros(n)
for i in 1:n
    m1=(X1[i,:]'βt.mu1)+U[1,i];m2=(X2[i,:]'βt.mu2)+U[2,i]
    s1=exp((Xs1[i,:]'βt.s1)+U[3,i]);s2=exp((Xs2[i,:]'βt.s2)+U[4,i]);ρ=RHO_GUARD*tanh(Xr[i,:]'βt.rho)
    e=cholesky([s1^2 ρ*s1*s2;ρ*s1*s2 s2^2]).L*randn(2);y1[i]=m1+e[1];y2[i]=m2+e[2]
end
prob,Q_cond=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
β=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
N=prob.n_total

function L_of_Λ(Λ)
    P=prior_precision(Q_cond,inv(Λ)); u,ch,_=estep_mode(prob,P,β;n_newton=60)
    return laplace_ll(prob,P,β,u,ch)
end

# pick a test Λ (PD, not the optimum)
Λ=[0.4 0.05 0.0 0.0;0.05 0.35 0.02 0.0;0.0 0.02 0.15 0.01;0.0 0.0 0.01 0.18];Λ=(Λ+Λ')/2

# analytic G = 0.5 N Λ⁻¹(Λ_em − Λ)Λ⁻¹
P=prior_precision(Q_cond,inv(Λ)); u,ch,_=estep_mode(prob,P,β;n_newton=60)
Λem=mstep_Lambda(prob,Q_cond,u,ch)
Λi=inv(Λ)
G=0.5*N*Λi*(Λem-Λ)*Λi; G=(G+G')/2

# directional derivative along a symmetric direction D, FD vs analytic <G,D>
function check(D)
    D=(D+D')/2; ε=1e-5
    fd=(L_of_Λ(Symmetric(Λ.+ε.*D))-L_of_Λ(Symmetric(Λ.-ε.*D)))/(2ε)
    an=sum(G.*D)         # <G,D>_F = tr(G'D) since both symmetric
    return fd, an
end
@printf "=== analytic Λ gradient check (p=8) ===\n"
for (name,D) in [("E11",[1.0 0 0 0;0 0 0 0;0 0 0 0;0 0 0 0]),
                 ("E33",[0 0 0 0;0 0 0 0;0 0 1.0 0;0 0 0 0]),
                 ("E12",[0 1.0 0 0;1.0 0 0 0;0 0 0 0;0 0 0 0]),
                 ("Gdir",G)]
    fd,an=check(D)
    @printf "  %-5s: FD=% .5f  analytic=% .5f  relerr=%.2e\n" name fd an abs(fd-an)/(abs(fd)+1e-8)
end
println("If relerr<1e-3, the analytic gradient is correct -> integrate (O(p), ~20x faster Λ step).")
println("=== done ===")
