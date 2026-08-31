using DRM, Random, LinearAlgebra, SparseArrays, Test
import Distributions
function fixture_state(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    pmu, ppsi = size(Xmu,2), size(Xpsi,2)
    lambda = theta[pmu+ppsi+1:pmu+ppsi+3]
    P = DRM.prior_precision(Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
    return Xmu * theta[1:pmu], Xpsi * theta[pmu+1:pmu+ppsi], P
end

function diagnose(name, kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    @testset "$name certified perturbations" begin
        points = [("base", copy(theta))]
        for k in eachindex(theta), direction in (-1, 1)
            t = copy(theta); t[k] += direction * 1e-6
            push!(points, ("$(k):$(direction)", t))
        end
        for (label, t) in points
            eta0, psi0, P = fixture_state(kind,y,Xmu,Xpsi,gidx,G,Q,t)
            a,ch,ok = DRM._ls_inner_mode(kind,y,eta0,psi0,gidx,G,P)
            grad=DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P)
            bound=1e-9*(1+norm(a))
            ga=DRM._ls_marginal_grad(kind,y,Xmu,Xpsi,gidx,G,Q,t)
            nll=DRM._ls_fit_nll(kind,y,Xmu,Xpsi,gidx,G,Q,t)
            println(name," ",label," ok=",ok," norm=",norm(grad)," bound=",bound," nll=",nll)
            @test ok
            @test issuccess(ch)
            @test all(isfinite,a) && all(isfinite,grad) && isfinite(bound) && isfinite(norm(grad)) && norm(grad)<=bound
            @test all(isfinite,ga)
            @test isfinite(nll) && nll != 1e18
        end
    end
end
@testset "all exact gradient perturbations" begin
Random.seed!(202)
G=5; m=6; n=G*m; gidx=repeat(1:G,inner=m)
x=randn(n); z=randn(n); Xmu=hcat(ones(n),x); Xpsi=hcat(ones(n),z)
L=cholesky(Symmetric(DRM._ls_lc_to_Λ([log(.35),.05,log(.4)]))).L
A=[L*randn(2) for _ in 1:G]
ygamma=[begin alpha=exp(.5+A[gidx[i]][2]); mu=exp(.2+.3x[i]+A[gidx[i]][1]); rand(Distributions.Gamma(alpha,mu/alpha)) end for i in 1:n]
diagnose("gamma_iid",Val(:gamma),ygamma,Xmu,Xpsi,gidx,G,sparse(1.0I,G,G),[.15,.25,.4,.06,log(.4),.05,log(.45)])

Random.seed!(303)
p=6; m=6; n=p*m; phy=random_balanced_tree(p;branch_length=.25)
C=sigma_phy_dense(phy;σ²_phy=1.0); LC=cholesky(Symmetric(C)).L
LΛ=cholesky(Symmetric(DRM._ls_lc_to_Λ([log(.4),0.,log(.3)]))).L
A=LC*randn(p,2)*LΛ'; species=repeat(1:p,inner=m); x=randn(n); z=randn(n); Xmu=hcat(ones(n),x); Xpsi=hcat(ones(n),z)
ynb=[begin r=exp(.2+A[species[i],2]); mu=exp(.15+.4x[i]+A[species[i],1]); Float64(rand(Distributions.NegativeBinomial(r,r/(r+mu)))) end for i in 1:n]
Q,gidx,G=DRM._locscale_phylo_setup(phy,species)
diagnose("nb2_phy",Val(:nb2),ynb,Xmu,Xpsi,gidx,G,Q,[.2,.3,.1,.04,log(.42),.05,log(.32)])
end
println("INNER_PERTURBATIONS_OK")
