# demo_natgrad_p20.jl — verify the scout's central claim (info-geometry-scout.md
# pain #1) ON OUR PROBLEM: the closed-form EM Λ-update overshoots because it is an
# UNSCALED Euclidean step on the SPD cone; a curvature-preconditioned (natural-
# gradient / Fisher-scoring) step on the log-Cholesky params is well-scaled and
# ascends the true marginal. p=20 synthetic, started OFF the diagonal singularity.
using LinearAlgebra, SparseArrays, ForwardDiff, Random, Statistics, Printf
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

function build_p20()
    Random.seed!(7); p=20; n=p
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
    β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
    return prob,Q_cond,β0
end

offdiag(M)=maximum(abs.(M-Diagonal(M)))

function main()
    prob,Q_cond,β0=build_p20()
    Λ0=Matrix(Symmetric(0.3*I(4)+0.02*(ones(4,4)-I(4))))   # ε-nudge: off the singularity
    θ0=pack_theta(β0,Λ0)
    nll0,g,u_hat,_=marginal_and_exact_grad(prob,Q_cond,θ0;n_newton=80)
    g_lc=g[8:17]
    @printf "start: marginal LL=%.4f, Λ off-diag=%.3f\n\n" (-nll0) offdiag(Λ0)

    # (A) closed-form EM Λ step (the overshooting one)
    P=prior_precision(Q_cond,inv(Λ0)); u,ch,_=estep_mode(prob,P,β0;n_newton=80)
    Λ_em=Matrix(Symmetric(mstep_Lambda(prob,Q_cond,u,ch)))
    ll_em=isposdef(Λ_em) ? -marginal_nll(prob,Q_cond,pack_theta(β0,Λ_em);u0=u,n_newton=80)[1] : NaN
    @printf "(A) closed-form EM step:   Λ off-diag=%6.3f  ΔLL=%+8.3f   %s\n" offdiag(Λ_em) (ll_em-(-nll0)) (offdiag(Λ_em)>0.5 ? "<-- OVERSHOOT" : "")

    # (B) plain Euclidean gradient step on lc (unit-ish), best of a few sizes
    bestB=(-Inf,0.0)
    for s in (1.0,0.3,0.1,0.03)./ (norm(g_lc)+1e-12)
        lc=Λ_to_lc(Λ0).-s.*g_lc; llB=-marginal_nll(prob,Q_cond,vcat(θ0[1:7],lc);u0=u_hat,n_newton=80)[1]
        llB>bestB[1] && (bestB=(llB,s))
    end
    lcB=Λ_to_lc(Λ0).-bestB[2].*g_lc
    @printf "(B) Euclidean grad step:   Λ off-diag=%6.3f  ΔLL=%+8.3f\n" offdiag(lc_to_Λ(lcB)) (bestB[1]-(-nll0))

    # (C) natural-gradient / Fisher-scoring step: precondition by the observed
    # information H_lc (finite-diff of the EXACT lc-gradient) -> well-scaled step.
    h=1e-5; Hlc=zeros(10,10)
    for k in 1:10
        θp=copy(θ0);θp[7+k]+=h; _,gp,_,_=marginal_and_exact_grad(prob,Q_cond,θp;u0=u_hat,n_newton=80)
        θm=copy(θ0);θm[7+k]-=h; _,gm,_,_=marginal_and_exact_grad(prob,Q_cond,θm;u0=u_hat,n_newton=80)
        Hlc[:,k]=(gp[8:17].-gm[8:17])./(2h)
    end
    Hlc=Symmetric((Hlc+Hlc')/2)
    ev=eigen(Hlc); λfloor=max(1e-3,0.1*maximum(abs.(ev.values)))   # ridge to PD (Fisher metric must be SPD)
    Hpd=ev.vectors*Diagonal(max.(ev.values,λfloor))*ev.vectors'
    dlc=-(Hpd\g_lc)                                               # Newton/natural direction on NLL
    bestC=(-Inf,0.0)
    for α in (1.0,0.5,0.25,0.1)
        lc=Λ_to_lc(Λ0).+α.*dlc; llC=-marginal_nll(prob,Q_cond,vcat(θ0[1:7],lc);u0=u_hat,n_newton=80)[1]
        llC>bestC[1] && (bestC=(llC,α))
    end
    lcC=Λ_to_lc(Λ0).+bestC[2].*dlc
    @printf "(C) natural-grad step:     Λ off-diag=%6.3f  ΔLL=%+8.3f  (α=%.2f)  <-- well-scaled\n" offdiag(lc_to_Λ(lcC)) (bestC[1]-(-nll0)) bestC[2]
    println("\nH_lc cond=",round(cond(Matrix(Hlc));digits=1)," (large cond => why an unscaled Euclidean/closed-form step misfires)")
    println("=== done ===")
end
main()
