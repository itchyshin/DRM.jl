using DRM, Random, LinearAlgebra, Printf
function setup(p; m=4, seed=11)
    Random.seed!(seed); n=p*m
    phy=random_balanced_tree(p; branch_length=0.3)
    C=sigma_phy_dense(phy; σ²_phy=1.0); LC=cholesky(Symmetric(C)).L
    u_mu=0.6.*(LC*randn(p)); u_sig=0.5.*(LC*randn(p)); species=repeat(1:p,inner=m)
    y=[1.0+u_mu[species[i]]+exp(log(0.5)+u_sig[species[i]])*randn() for i in 1:n]
    Xμ=ones(n,1); Xψ=ones(n,1); kind=Val(:gaussian_mean)
    Q,gidx,G=DRM._locscale_phylo_setup(phy,species)
    Zη=DRM._ls_canonical_Zeta(n); Zψ=DRM._ls_canonical_Zpsi(n)
    obj(θ)=DRM._glsp_sep_nll(kind,y,Xμ,Xψ,gidx,G,Q,θ,Zη,Zψ)
    grad(θ)=DRM._glsp_sep_grad(kind,y,Xμ,Xψ,gidx,G,Q,θ,Zη,Zψ)
    θ̂,_=DRM._glsp_optimise(obj,(g,θ)->(g.=grad(θ);g),vcat(Xμ\y,[0.0],log(0.3),log(0.3)))
    (; obj, grad, θ̂)
end
println("\n# REML wall-clock (s), speedup vs FD in (), σ-phylo separate block")
@printf("%-5s %-16s %-18s %-18s %-20s\n","p","FD-REML","clean-LBFGS","Newton-alone","Newton+polish")
for p in [24,60,120]
    s=setup(p)
    DRM._glsp_reml_refit(s.obj,s.grad,s.θ̂,1); DRM._glsp_reml_refit_clean(s.obj,s.grad,s.θ̂,1)
    DRM._glsp_reml_newton(s.obj,s.grad,s.θ̂,1,[3,4]); DRM._glsp_reml_fit(s.obj,s.grad,s.θ̂,1,[3,4])
    tf=@elapsed DRM._glsp_reml_refit(s.obj,s.grad,s.θ̂,1)
    tc=@elapsed DRM._glsp_reml_refit_clean(s.obj,s.grad,s.θ̂,1)
    ta=@elapsed DRM._glsp_reml_newton(s.obj,s.grad,s.θ̂,1,[3,4])
    tp=@elapsed DRM._glsp_reml_fit(s.obj,s.grad,s.θ̂,1,[3,4])
    @printf("%-5d %8.2f         %8.2f (%4.1fx)   %8.2f (%4.1fx)   %8.2f (%4.1fx)\n", p, tf, tc, tf/tc, ta, tf/ta, tp, tf/tp)
end
println()
