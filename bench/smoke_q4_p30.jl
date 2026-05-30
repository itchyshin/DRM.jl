# smoke_q4_p30.jl — quick end-to-end validation of the patched Laplace fit
# on a synthetic p=30 q=4 PLSM fixture. NOT a head-to-head benchmark; just
# confirms the patched Newton + Laplace can converge on small data.
#
# Run via:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia
#   /Users/z3437171/.juliaup/bin/julia --project=. smoke_q4_p30.jl

using Random, LinearAlgebra, Statistics, Printf

# Load fit_q4_julia.jl — main() is now guarded by abspath check, so this
# include() only loads functions.
include("fit_q4_julia.jl")

println("=== q=4 PLSM smoke test, p=30 ===\n")

# ---------------------------------------------------------------------------
# Truth
# ---------------------------------------------------------------------------
Random.seed!(123)
p = 30
n = p   # one obs per species

beta_mu1_true    = [1.0,  0.5]
beta_mu2_true    = [-0.3, 0.4]
beta_sigma1_true = [-0.5]   # sigma1 ≈ 0.61
beta_sigma2_true = [-0.5]   # sigma2 ≈ 0.61
beta_rho12_true  = [0.3]    # rho ≈ 0.29

# Λ_phy: simple diagonal — large for mu, smaller for log_sigma
Lambda_phy_true = diagm([0.5^2, 0.5^2, 0.2^2, 0.2^2])

# Σ_phy: synthetic PD matrix (not a real phylogeny — just for smoke test)
A = randn(p, p)
Sigma_phy = A'A / p + 0.5 * I + 0.5 .* (ones(p) * ones(p)') ./ p
Sigma_phy = (Sigma_phy + Sigma_phy') / 2
@assert isposdef(Sigma_phy) "Sigma_phy not PD"

# Covariate
x1 = randn(n)
X_mu1    = hcat(ones(n), x1)
X_mu2    = hcat(ones(n), x1)
X_sigma1 = reshape(ones(n), n, 1)
X_sigma2 = reshape(ones(n), n, 1)
X_rho12  = reshape(ones(n), n, 1)

# Random effects U ~ MVN(0, Σ_phy ⊗ Λ_phy) via Kronecker Cholesky
L_Lambda = cholesky(Lambda_phy_true).L
L_Sigma  = cholesky(Sigma_phy).L
U_true = L_Lambda * randn(4, p) * L_Sigma'  # 4×p

# Build per-species mu, sigma, rho
species_idx = collect(1:p)
mu1_fix = X_mu1 * beta_mu1_true
mu2_fix = X_mu2 * beta_mu2_true
ls1_fix = X_sigma1 * beta_sigma1_true
ls2_fix = X_sigma2 * beta_sigma2_true
eta_rho = X_rho12 * beta_rho12_true

mu1 = mu1_fix .+ U_true[1, species_idx]
mu2 = mu2_fix .+ U_true[2, species_idx]
sigma1 = exp.(ls1_fix .+ U_true[3, species_idx])
sigma2 = exp.(ls2_fix .+ U_true[4, species_idx])
rho = 0.99999999 .* tanh.(eta_rho)

# Simulate y1, y2 per species
y1 = zeros(n)
y2 = zeros(n)
for i in 1:n
    s1, s2 = sigma1[i], sigma2[i]
    r = rho[i]
    cov22 = [s1^2  r*s1*s2; r*s1*s2  s2^2]
    L = cholesky(cov22).L
    eps = L * randn(2)
    y1[i] = mu1[i] + eps[1]
    y2[i] = mu2[i] + eps[2]
end

println("Truth simulated. y1 range [$(round(minimum(y1); digits=2)), $(round(maximum(y1); digits=2))]")
println("                  y2 range [$(round(minimum(y2); digits=2)), $(round(maximum(y2); digits=2))]")

# ---------------------------------------------------------------------------
# Fit
# ---------------------------------------------------------------------------
println("\n--- Fitting (patched code, finite-diff outer, p=$p) ---")
flush(stdout)
const SLOG = open(joinpath(@__DIR__, "smoke_q4.log"), "w")
println(SLOG, "starting fit, p=$p"); flush(SLOG)

t_fit = @elapsed res = fit_q4(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                              Sigma_phy, species_idx;
                              g_tol=1e-2, iterations=60, n_inner=12,
                              show_trace=true)

println("\n=== RESULT ===")
println("Wall-clock: $(round(t_fit; digits=2)) s")
println("Converged:  $(Optim.converged(res))")
println("Final nll:  $(round(Optim.minimum(res); digits=3))")
println("Iters:      $(Optim.iterations(res))")
println("g_norm:     $(round(Optim.g_residual(res); digits=6))")

theta_hat = Optim.minimizer(res)
upk = unpack_theta(theta_hat, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
println("\nRecovered vs truth:")
@printf "  beta_mu1:    truth %s  ->  hat %s\n" round.(beta_mu1_true; digits=3) round.(upk.beta_mu1; digits=3)
@printf "  beta_mu2:    truth %s  ->  hat %s\n" round.(beta_mu2_true; digits=3) round.(upk.beta_mu2; digits=3)
@printf "  beta_sigma1: truth %s  ->  hat %s\n" round.(beta_sigma1_true; digits=3) round.(upk.beta_sigma1; digits=3)
@printf "  beta_sigma2: truth %s  ->  hat %s\n" round.(beta_sigma2_true; digits=3) round.(upk.beta_sigma2; digits=3)
@printf "  beta_rho12:  truth %s  ->  hat %s\n" round.(beta_rho12_true; digits=3) round.(upk.beta_rho12; digits=3)
@printf "  sd_phy:      truth %s  ->  hat %s\n" round.(sqrt.(diag(Lambda_phy_true)); digits=3) round.(upk.sd_phy; digits=3)
println(SLOG, "DONE wall=$(round(t_fit;digits=2))s conv=$(Optim.converged(res)) nll=$(round(Optim.minimum(res);digits=3))"); flush(SLOG); close(SLOG)
println("\n=== smoke test complete ===")
