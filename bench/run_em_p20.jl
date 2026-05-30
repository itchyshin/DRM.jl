# run_em_p20.jl — fast synthetic recovery + timing check for the dense EM.
# p=20, should converge in seconds (no nested AD). Validates the EM runs
# and recovers parameters before we point it at the real q4_p100 fixture.
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. run_em_p20.jl

using LinearAlgebra, Random, Statistics, Printf
include("sparse_phy.jl")
include("q4_em_dense.jl")

Random.seed!(2026)
p = 20
n = p

# Truth
β_mu1_t = [1.0, 0.5]; β_mu2_t = [-0.3, 0.4]
β_s1_t = [-0.5]; β_s2_t = [-0.5]; β_rho_t = [0.3]
Λ_t = Float64[0.25 0.10 0.05 0.0;
              0.10 0.25 0.0  0.04;
              0.05 0.0  0.09 0.02;
              0.0  0.04 0.02 0.09]
Λ_t = (Λ_t + Λ_t') / 2
@assert isposdef(Λ_t)

# Phylo covariance from a balanced tree (sparse infra, then densify for sim)
phy = random_balanced_tree(p; branch_length = 0.15)
Σ_phy = sigma_phy_dense(phy; σ²_phy = 1.0)
Σ_phy = (Σ_phy + Σ_phy') / 2

# Simulate U ~ MN(0, Λ_t row-cov, Σ_phy col-cov): U(4×p)= chol(Λ) Z chol(Σ)'
U_t = cholesky(Λ_t).L * randn(4, p) * cholesky(Symmetric(Σ_phy)).U
x1 = randn(n)
Xmu = hcat(ones(n), x1)
X1 = reshape(ones(n), n, 1)
D = Q4Design(Xmu, Xmu, X1, X1, X1)

mu1 = Xmu * β_mu1_t .+ U_t[1, :]
mu2 = Xmu * β_mu2_t .+ U_t[2, :]
s1 = exp.(β_s1_t[1] .+ U_t[3, :])
s2 = exp.(β_s2_t[1] .+ U_t[4, :])
ρ  = RHO_GUARD * tanh(β_rho_t[1])
y1 = zeros(n); y2 = zeros(n)
for i in 1:n
    cov = [s1[i]^2 ρ*s1[i]*s2[i]; ρ*s1[i]*s2[i] s2[i]^2]
    e = cholesky(cov).L * randn(2)
    y1[i] = mu1[i] + e[1]; y2[i] = mu2[i] + e[2]
end

println("=== dense Laplace-EM, synthetic p=20 ===")
# warm-up (compile)
fit_q4_em(y1, y2, D, Σ_phy; max_em = 3, verbose = false)
t = @elapsed res = fit_q4_em(y1, y2, D, Σ_phy; max_em = 300, tol = 1e-6, verbose = true)

println("\n=== RESULT (p=20) ===")
@printf "wall-clock: %.3f s   iters: %d   converged: %s   logLik: %.4f\n" t res.iters res.converged res.loglik
pr = res.par
@printf "β_mu1:  truth %s -> %s\n" round.(β_mu1_t; digits=3) round.(pr.β_mu1; digits=3)
@printf "β_mu2:  truth %s -> %s\n" round.(β_mu2_t; digits=3) round.(pr.β_mu2; digits=3)
@printf "β_s1:   truth %s -> %s\n" round.(β_s1_t; digits=3) round.(pr.β_s1; digits=3)
@printf "β_s2:   truth %s -> %s\n" round.(β_s2_t; digits=3) round.(pr.β_s2; digits=3)
@printf "β_rho:  truth %s -> %s\n" round.(β_rho_t; digits=3) round.(pr.β_rho; digits=3)
println("Λ diag: truth ", round.(diag(Λ_t); digits=3), " -> ", round.(diag(pr.Λ); digits=3))
println("\n=== p=20 EM smoke complete ===")
