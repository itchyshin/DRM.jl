# probe_q4.jl — time the building blocks to find the bottleneck.
# Writes progress to a file with explicit flush so we see output even if killed.
using Random, LinearAlgebra, Statistics, Printf, ForwardDiff

include("fit_q4_julia.jl")

const LOG = open(joinpath(@__DIR__, "probe_q4.log"), "w")
logln(s) = (println(s); println(LOG, s); flush(LOG); flush(stdout))

Random.seed!(123)
p = 20
n = p
beta_mu1_true=[1.0,0.5]; beta_mu2_true=[-0.3,0.4]
beta_sigma1_true=[-0.5]; beta_sigma2_true=[-0.5]; beta_rho12_true=[0.3]
Lambda=diagm([0.25,0.25,0.04,0.04])
A=randn(p,p); Sigma_phy=(A'A/p + 0.5I + 0.5 .*(ones(p)*ones(p)')./p); Sigma_phy=(Sigma_phy+Sigma_phy')/2
x1=randn(n)
X_mu1=hcat(ones(n),x1); X_mu2=hcat(ones(n),x1)
X_sigma1=reshape(ones(n),n,1); X_sigma2=reshape(ones(n),n,1); X_rho12=reshape(ones(n),n,1)
LL=cholesky(Lambda).L; LS=cholesky(Sigma_phy).L
U=LL*randn(4,p)*LS'
sidx=collect(1:p)
mu1=X_mu1*beta_mu1_true .+ U[1,sidx]; mu2=X_mu2*beta_mu2_true .+ U[2,sidx]
s1=exp.(X_sigma1*beta_sigma1_true .+ U[3,sidx]); s2=exp.(X_sigma2*beta_sigma2_true .+ U[4,sidx])
rho=0.99999999 .*tanh.(X_rho12*beta_rho12_true)
y1=zeros(n); y2=zeros(n)
for i in 1:n
    cov=[s1[i]^2 rho[i]*s1[i]*s2[i]; rho[i]*s1[i]*s2[i] s2[i]^2]
    e=cholesky(cov).L*randn(2); y1[i]=mu1[i]+e[1]; y2[i]=mu2[i]+e[2]
end

Sinv=inv(Sigma_phy); ldS=logdet(Symmetric(Sigma_phy))
theta0=build_initial_theta(y1,y2,X_mu1,X_mu2,X_sigma1,X_sigma2,X_rho12)
logln("p=$p, 4p=$(4p), theta dim=$(length(theta0))")

# 1. one nll_marginal eval (includes inner Newton + Laplace Hessian)
logln("--- timing single nll_marginal eval ---")
nm(th)=nll_marginal(th,y1,y2,X_mu1,X_mu2,X_sigma1,X_sigma2,X_rho12,Sinv,ldS,sidx;n_inner=10)
v0=nm(theta0); logln("nll_marginal(theta0)=$(round(v0;digits=4))")  # warm-up compile
t1=@elapsed v1=nm(theta0)
logln("  single eval: $(round(t1*1000;digits=1)) ms")

# 2. one OUTER ForwardDiff.gradient (this is the nested-AD path)
logln("--- timing single outer ForwardDiff.gradient (NESTED AD) ---")
g=ForwardDiff.gradient(nm,theta0); logln("  grad norm=$(round(norm(g);digits=4))")  # warm-up
t2=@elapsed g2=ForwardDiff.gradient(nm,theta0)
logln("  single outer gradient: $(round(t2;digits=2)) s")

logln("--- estimated cost ---")
logln("  if outer LBFGS needs ~40 iters: ~$(round(40*t2;digits=1)) s with nested AD")
close(LOG)
println("PROBE DONE")
