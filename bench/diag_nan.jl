# diag_nan.jl — pinpoint the NaN at theta0 for the TMB-gradient route.
# Reproduces the check_grad p=20 synthetic (seed 7), then evaluates each piece
# at the EXACT theta0 (no noise) to locate the NaN.
using LinearAlgebra, Random, Statistics, Printf
include(joinpath(@__DIR__, "fit_q4_tmbgrad.jl"))

Random.seed!(7); p = 20; n = p
Lambda_phy_true = diagm([0.5^2, 0.5^2, 0.2^2, 0.2^2])
A = randn(p, p); Sigma_phy = A'A / p + 0.5 * I + 0.5 .* (ones(p) * ones(p)') ./ p
Sigma_phy = (Sigma_phy + Sigma_phy') / 2
x1 = randn(n); X_mu1 = hcat(ones(n), x1); X_mu2 = hcat(ones(n), x1)
X_sigma1 = reshape(ones(n), n, 1); X_sigma2 = reshape(ones(n), n, 1); X_rho12 = reshape(ones(n), n, 1)
L_Lambda = cholesky(Lambda_phy_true).L; L_Sigma = cholesky(Sigma_phy).L
U_true = L_Lambda * randn(4, p) * L_Sigma'; species_idx = collect(1:p)
mu1 = X_mu1*[1.0,0.5] .+ U_true[1,:]; mu2 = X_mu2*[-0.3,0.4] .+ U_true[2,:]
sigma1 = exp.((X_sigma1*[-0.5]) .+ U_true[3,:]); sigma2 = exp.((X_sigma2*[-0.5]) .+ U_true[4,:])
rho = 0.99999999 .* tanh.(X_rho12*[0.3]); y1 = zeros(n); y2 = zeros(n)
for i in 1:n
    s1,s2 = sigma1[i],sigma2[i]; r = rho[i]
    e = cholesky([s1^2 r*s1*s2; r*s1*s2 s2^2]).L * randn(2)
    y1[i] = mu1[i]+e[1]; y2[i] = mu2[i]+e[2]
end
Sinv = inv(Sigma_phy); ldS = logdet(Symmetric(Sigma_phy))

theta0 = build_initial_theta(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
@printf "theta0 finite? %s\n" all(isfinite, theta0)
@printf "theta0 = %s\n" string(round.(theta0; digits=4))

uhat = find_u_hat(theta0, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, Sinv, ldS, species_idx; n_iter=30)
@printf "u_hat finite? %s   any NaN? %s   norm=%.3e\n" all(isfinite, uhat) any(isnan, uhat) (all(isfinite,uhat) ? norm(uhat) : NaN)

# nll_joint at theta0, uhat
njoint = nll_joint(theta0, Vector{Float64}(uhat), y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, Sinv, ldS, species_idx)
@printf "nll_joint(theta0, uhat) = %s\n" string(njoint)

# marginal + exact grad at theta0
nll0, g0 = marginal_and_exact_grad(theta0, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, Sinv, ldS, species_idx; n_inner=30)
@printf "marginal nll(theta0) = %s   grad finite? %s\n" string(nll0) all(isfinite, g0)

# Also test a robust init: zero betas except sigma intercepts, log_sd=log(0.3)
println("\n--- robust init test ---")
th_rob = copy(theta0)
# layout: bmu1(2) bmu2(2) bs1(1) bs2(1) brho(1) logsd(4) choloff(6)
th_rob[10:13] .= log(0.3)   # log_sd_phy
th_rob[14:19] .= 0.0        # chol_offdiag
uhat2 = find_u_hat(th_rob, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, Sinv, ldS, species_idx; n_iter=30)
@printf "robust uhat finite? %s\n" all(isfinite, uhat2)
nll1, g1 = marginal_and_exact_grad(th_rob, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, Sinv, ldS, species_idx; n_inner=30)
@printf "robust marginal nll = %s   grad finite? %s\n" string(nll1) all(isfinite, g1)
println("=== diag done ===")
