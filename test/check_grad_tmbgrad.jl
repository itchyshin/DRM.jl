# check_grad_tmbgrad.jl — correctness gate for the TMB-style analytic gradient.
#
# Two checks at a random theta on a synthetic p=20 q=4 PLSM:
#   A) AD-of-frozen-objective vs FINITE DIFF of the SAME frozen objective
#      (u_hat held fixed). This validates the H_uu rebuild + logdet AD path.
#      MUST be < 1e-4 (the prompt's correctness gate).
#   B) my analytic (cheap) gradient vs FINITE DIFF of the TRUE marginal NLL
#      (u_hat re-solved at every perturbation). This is informational: it
#      quantifies the implicit "3rd-derivative" term that TMB's cheap gradient
#      drops by design. It will NOT be ~0 in general away from the optimum.
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. check_grad_tmbgrad.jl

using LinearAlgebra, Random, Statistics, Printf

include(joinpath(@__DIR__, "fit_q4_tmbgrad.jl"))   # also pulls fit_q4_julia.jl

Random.seed!(7)
p = 20
n = p

# --- synthetic data (same generator family as smoke_q4_p30.jl) --------------
beta_mu1_true = [1.0, 0.5]; beta_mu2_true = [-0.3, 0.4]
beta_sigma1_true = [-0.5]; beta_sigma2_true = [-0.5]; beta_rho12_true = [0.3]
Lambda_phy_true = diagm([0.5^2, 0.5^2, 0.2^2, 0.2^2])

A = randn(p, p)
Sigma_phy = A'A / p + 0.5 * I + 0.5 .* (ones(p) * ones(p)') ./ p
Sigma_phy = (Sigma_phy + Sigma_phy') / 2
@assert isposdef(Sigma_phy)

x1 = randn(n)
X_mu1 = hcat(ones(n), x1); X_mu2 = hcat(ones(n), x1)
X_sigma1 = reshape(ones(n), n, 1)
X_sigma2 = reshape(ones(n), n, 1)
X_rho12  = reshape(ones(n), n, 1)

L_Lambda = cholesky(Lambda_phy_true).L
L_Sigma  = cholesky(Sigma_phy).L
U_true = L_Lambda * randn(4, p) * L_Sigma'
species_idx = collect(1:p)

mu1 = X_mu1 * beta_mu1_true .+ U_true[1, :]
mu2 = X_mu2 * beta_mu2_true .+ U_true[2, :]
sigma1 = exp.((X_sigma1 * beta_sigma1_true) .+ U_true[3, :])
sigma2 = exp.((X_sigma2 * beta_sigma2_true) .+ U_true[4, :])
rho = 0.99999999 .* tanh.(X_rho12 * beta_rho12_true)
y1 = zeros(n); y2 = zeros(n)
for i in 1:n
    s1, s2 = sigma1[i], sigma2[i]; r = rho[i]
    cov22 = [s1^2 r*s1*s2; r*s1*s2 s2^2]
    e = cholesky(cov22).L * randn(2)
    y1[i] = mu1[i] + e[1]; y2[i] = mu2[i] + e[2]
end

Sigma_phy_inv = inv(Sigma_phy)
logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

# --- a RANDOM theta (not the optimum) ---------------------------------------
theta0 = build_initial_theta(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
Random.seed!(99)
theta_test = theta0 .+ 0.15 .* randn(length(theta0))
@printf "theta_test (len %d): %s\n" length(theta_test) string(round.(theta_test; digits=3))

# === Check A: AD vs FD of the FROZEN objective (u_hat fixed) ================
u_hat = find_u_hat(theta_test, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                   Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_iter = 30)
u_hat = Vector{Float64}(u_hat)

f_frozen = th -> frozen_objective(th, u_hat, y1, y2, X_mu1, X_mu2, X_sigma1,
                                  X_sigma2, X_rho12, Sigma_phy_inv,
                                  logdet_Sigma_phy, species_idx)
g_ad = ForwardDiff.gradient(f_frozen, theta_test)

# central finite differences of the frozen objective
h = 1e-6
g_fd = similar(theta_test)
for k in eachindex(theta_test)
    tp = copy(theta_test); tp[k] += h
    tm = copy(theta_test); tm[k] -= h
    g_fd[k] = (f_frozen(tp) - f_frozen(tm)) / (2h)
end
relA = abs.(g_ad .- g_fd) ./ (abs.(g_fd) .+ 1e-8)
@printf "\n=== Check A: AD vs FD of FROZEN objective (u_hat fixed) ===\n"
for k in eachindex(theta_test)
    @printf "  [%2d] AD=% .6e  FD=% .6e  rel=%.2e\n" k g_ad[k] g_fd[k] relA[k]
end
@printf "  MAX REL ERR (Check A) = %.3e   (gate < 1e-4)\n" maximum(relA)

# === Check B: cheap analytic grad vs FD of TRUE marginal NLL ================
nll_cheap, g_cheap = marginal_and_grad(theta_test, y1, y2, X_mu1, X_mu2, X_sigma1,
                                       X_sigma2, X_rho12, Sigma_phy_inv,
                                       logdet_Sigma_phy, species_idx; n_inner = 30)

true_marg = th -> nll_marginal(th, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                               X_rho12, Sigma_phy_inv, logdet_Sigma_phy,
                               species_idx; n_inner = 30)
# sanity: cheap nll value should match the true marginal value at theta_test
nll_true_val = true_marg(theta_test)
@printf "\nmarginal NLL: cheap=% .6f  true=% .6f  |Δ|=%.2e\n" nll_cheap nll_true_val abs(nll_cheap - nll_true_val)

hB = 1e-5
g_fdB = similar(theta_test)
for k in eachindex(theta_test)
    tp = copy(theta_test); tp[k] += hB
    tm = copy(theta_test); tm[k] -= hB
    g_fdB[k] = (true_marg(tp) - true_marg(tm)) / (2hB)
end
relB = abs.(g_cheap .- g_fdB) ./ (abs.(g_fdB) .+ 1e-8)
@printf "\n=== Check B: cheap analytic grad vs FD of TRUE marginal ===\n"
for k in eachindex(theta_test)
    @printf "  [%2d] cheap=% .6e  FD_true=% .6e  rel=%.2e\n" k g_cheap[k] g_fdB[k] relB[k]
end
@printf "  MAX REL ERR (Check B, informational) = %.3e\n" maximum(relB)
@printf "  (Check B measures the implicit term TMB drops; line search on the\n"
@printf "   true NLL still guarantees descent.)\n"

# === Check C: EXACT analytic grad vs FD of TRUE marginal NLL ================
# exact_grad = cheap + implicit (dû/dθ)'v correction (steps 1-6). This MUST
# match the FD of the true marginal (g_fdB, reused from Check B) to < 1e-4.
nll_exact, g_exact = marginal_and_exact_grad(theta_test, y1, y2, X_mu1, X_mu2,
                                             X_sigma1, X_sigma2, X_rho12,
                                             Sigma_phy_inv, logdet_Sigma_phy,
                                             species_idx; n_inner = 30)
@printf "\nmarginal NLL: exact=% .6f  true=% .6f  |Δ|=%.2e\n" nll_exact nll_true_val abs(nll_exact - nll_true_val)
relC = abs.(g_exact .- g_fdB) ./ (abs.(g_fdB) .+ 1e-8)
@printf "\n=== Check C: EXACT analytic grad vs FD of TRUE marginal ===\n"
for k in eachindex(theta_test)
    @printf "  [%2d] exact=% .6e  FD_true=% .6e  rel=%.2e\n" k g_exact[k] g_fdB[k] relC[k]
end
maxC = maximum(relC)
@printf "  MAX REL ERR (Check C) = %.3e   (GATE < 1e-4)\n" maxC
if maxC < 1e-4
    @printf "  Check C PASSED.\n"
else
    @printf "  Check C FAILED — debug steps 3/5 (sign, H\\v solve, frozen quantities).\n"
end

println("\n=== gradient check done ===")
