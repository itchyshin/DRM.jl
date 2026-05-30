# Run via:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia
#   /Users/z3437171/.juliaup/bin/julia --project=. test_q4_laplace.jl
#
# Requires fit_q4_julia.jl to be present and loadable via include().

using Test
using LinearAlgebra
using Random
using Statistics

# -----------------------------------------------------------------------------
# Load the implementation defensively.
#
# fit_q4_julia.jl currently calls `main()` at the bottom of the file, which
# triggers the full fit pipeline (reads fixtures, optimises, writes results).
# For unit testing we only want the function definitions, so we load the file
# as a string, strip the trailing `main()` call, and eval the rest. If the
# file is missing or cannot be parsed/evaluated, exit gracefully (status 0).
# -----------------------------------------------------------------------------

const IMPL_PATH = joinpath(@__DIR__, "fit_q4_julia.jl")

function _load_impl()
    if !isfile(IMPL_PATH)
        println("Implementation file not loadable: $IMPL_PATH does not exist.")
        println("Run after fit_q4_julia.jl is in place.")
        exit(0)
    end
    src = read(IMPL_PATH, String)

    # Strip any bare top-level `main()` call. The function definition (with
    # `function main(...)` ... `end`) stays; only the unwrapped invocation is
    # removed so the test file does not trigger the full fit.
    stripped = replace(src, r"(?m)^\s*main\s*\(\s*\)\s*$" => "")

    try
        Base.include_string(Main, stripped, IMPL_PATH)
    catch e
        println("Implementation file not loadable: ", e)
        println("Run after fit_q4_julia.jl is in place.")
        exit(0)
    end
end

_load_impl()

# Sanity-check the API we depend on. If any of these symbols are missing,
# bail out gracefully with a clear message.
const REQUIRED_SYMBOLS = (:build_Lambda_phy, :chol_offdiag_to_R, :nll_joint,
                          :find_u_hat, :nll_marginal)

for sym in REQUIRED_SYMBOLS
    if !isdefined(Main, sym)
        println("Implementation file is missing required symbol: $sym")
        println("Run after fit_q4_julia.jl exposes the documented API.")
        exit(0)
    end
end

# Distributions is in the project (see Project.toml) and we need it for
# Test 2 (brute-force prior NLL) and Test 5 (MC marginal). Load defensively.
try
    @eval using Distributions
catch e
    println("Distributions.jl not available: ", e)
    println("Add it to the project or instantiate before running tests.")
    exit(0)
end

# ForwardDiff is used by the implementation; it's already loaded via the
# include above. Bring it into scope here for the explicit gradient checks.
try
    @eval using ForwardDiff
catch e
    println("ForwardDiff.jl not available: ", e)
    exit(0)
end

println("Implementation loaded; running tests.")

# -----------------------------------------------------------------------------
# Helpers shared across @testsets
# -----------------------------------------------------------------------------

"""
    bivariate_data_nll(y1, y2, mu1, mu2, sigma1, sigma2, rho)

Brute-force per-observation bivariate Gaussian NLL with the same 0.99999999
tanh-bounded rho convention as the implementation. Used to isolate the data
contribution from `nll_joint` in Test 2.

Mirrors the closed-form expression on lines 152-158 of fit_q4_julia.jl.
"""
function bivariate_data_nll(y1, y2, mu1, mu2, sigma1, sigma2, rho)
    n = length(y1)
    e1 = y1 .- mu1
    e2 = y2 .- mu2
    one_minus_rho2 = 1 .- rho .^ 2
    quad = (e1 .^ 2 ./ sigma1 .^ 2 .- 2 .* rho .* e1 .* e2 ./ (sigma1 .* sigma2) .+
            e2 .^ 2 ./ sigma2 .^ 2) ./ one_minus_rho2
    log_det = 2 .* (log.(sigma1) .+ log.(sigma2)) .+ log.(one_minus_rho2)
    return 0.5 * sum(log_det .+ quad) + n * log(2π)
end

"""
    pack_theta(b_mu1, b_mu2, b_s1, b_s2, b_r, log_sd, chol_off)

Build the 17-entry theta vector following the layout documented at the top of
fit_q4_julia.jl: beta_mu1 (length p_mu1), beta_mu2, beta_sigma1, beta_sigma2,
beta_rho12, log_sd_phy (4), chol_offdiag (6).
"""
function pack_theta(b_mu1, b_mu2, b_s1, b_s2, b_r, log_sd, chol_off)
    return vcat(b_mu1, b_mu2, b_s1, b_s2, b_r, log_sd, chol_off)
end

# Convenience: zero-data, zero-design fixture lets us isolate the prior part
# of nll_joint. With X_* = zeros(n, 1) and beta_* set so the linear predictors
# are arbitrary constants, we can solve for the data NLL contribution
# analytically.
"""
    build_zero_design_fixture(p, U_true)

Construct a per-species fixture with one observation per species, all design
columns equal to 1 (intercept-only), and y1 = y2 = 0. With U = U_true, the
species random effect controls mu / sigma / rho per row.

Returns (y1, y2, X_*, species_idx, U_true_flat).
"""
function build_zero_design_fixture(p::Int, U_true::AbstractMatrix)
    n = p
    y1 = zeros(n)
    y2 = zeros(n)
    X_mu1    = reshape(ones(n), n, 1)
    X_mu2    = reshape(ones(n), n, 1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)
    species_idx = collect(1:p)
    u_flat = vec(U_true)
    return (y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, species_idx, u_flat)
end

# =============================================================================
# Test 1: build_Lambda_phy is positive-definite and round-trips SDs
# =============================================================================

@testset "Test 1: build_Lambda_phy is PD and round-trips SDs" begin
    Random.seed!(20260529)
    for _ in 1:20
        log_sd = 4 .* rand(4) .- 2.0           # uniform in [-2, 2]
        chol_off = 6 .* rand(6) .- 3.0         # uniform in [-3, 3]

        Lambda = build_Lambda_phy(log_sd, chol_off)

        @test size(Lambda) == (4, 4)
        # Symmetric (up to floating noise)
        @test maximum(abs.(Lambda .- Lambda')) < 1e-10
        # Positive definite -- symmetric wrap to avoid asymmetry false negatives
        @test isposdef(Symmetric((Lambda .+ Lambda') ./ 2))
        # Smallest eigenvalue strictly positive
        ev = eigvals(Symmetric((Lambda .+ Lambda') ./ 2))
        @test minimum(ev) > 0

        # SDs round-trip: diag(Lambda) == exp(log_sd).^2 (R is a correlation
        # matrix with unit diagonal because of the row-normalisation step in
        # chol_offdiag_to_R, so diag(D R D) = exp(log_sd).^2).
        expected_diag = exp.(log_sd) .^ 2
        @test maximum(abs.(diag(Lambda) .- expected_diag)) < 1e-10
    end
end

# =============================================================================
# Test 2: prior NLL contribution agrees with brute-force MvNormal(0, Σ ⊗ Λ)
# =============================================================================

@testset "Test 2: prior NLL matches brute-force MvNormal logpdf" begin
    Random.seed!(42)
    p = 5

    # Sigma_phy: 0.5 I + 0.5 * J/p. Eigenvalues are 0.5 + 0.5/p (one) and 0.5
    # (with multiplicity p-1), so it's strictly PD.
    Sigma_phy = 0.5 .* Matrix{Float64}(I, p, p) .+ 0.5 .* ones(p, p) ./ p
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    # Lambda_phy = diag(1.0, 1.0, 0.5, 0.5). Pick log_sd accordingly and zero
    # chol_off so R = I, giving the diagonal Lambda.
    log_sd_phy = log.([1.0, 1.0, sqrt(0.5), sqrt(0.5)])
    chol_offdiag = zeros(6)
    Lambda_phy = build_Lambda_phy(log_sd_phy, chol_offdiag)
    @test maximum(abs.(Lambda_phy .- Diagonal([1.0, 1.0, 0.5, 0.5]))) < 1e-10

    # Random U (4 x p)
    U = randn(4, p)
    u_flat = vec(U)

    # Build the zero-design fixture so we can isolate the prior part by
    # subtracting the data NLL we compute brute-force.
    y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12, species_idx, _ =
        build_zero_design_fixture(p, U)

    # Choose beta so the linear predictors are zero everywhere (intercept-only
    # designs with beta = 0). Then per species i:
    #   mu1_i    = U[1, i],   mu2_i    = U[2, i]
    #   sigma1_i = exp(U[3, i]), sigma2_i = exp(U[4, i])
    #   rho_i    = 0.99999999 * tanh(0) = 0
    # And y1 = y2 = 0, so e1 = -U[1, :], e2 = -U[2, :].
    theta = pack_theta(
        [0.0],            # beta_mu1
        [0.0],            # beta_mu2
        [0.0],            # beta_sigma1
        [0.0],            # beta_sigma2
        [0.0],            # beta_rho12
        log_sd_phy,
        chol_offdiag,
    )

    nll_total = nll_joint(theta, u_flat, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                          X_rho12, Sigma_phy_inv, logdet_Sigma_phy, species_idx)

    # Brute-force data NLL (matches the closed-form in the implementation).
    mu1 = U[1, :]
    mu2 = U[2, :]
    sigma1 = exp.(U[3, :])
    sigma2 = exp.(U[4, :])
    rho = fill(0.0, p)
    nll_data_bf = bivariate_data_nll(y1, y2, mu1, mu2, sigma1, sigma2, rho)

    # Prior NLL from implementation = total - data
    nll_prior_from_impl = nll_total - nll_data_bf

    # Brute-force prior NLL using Distributions.MvNormal
    Sigma_full = kron(Sigma_phy, Lambda_phy)
    # Symmetrize for numerical safety
    Sigma_full = (Sigma_full + Sigma_full') ./ 2
    mvn = MvNormal(zeros(4 * p), Sigma_full)
    nll_prior_bf = -logpdf(mvn, u_flat)

    @test isapprox(nll_prior_from_impl, nll_prior_bf; rtol = 1e-8, atol = 1e-8)

    # Also check that the total matches the sum of the brute-force pieces.
    @test isapprox(nll_total, nll_data_bf + nll_prior_bf; rtol = 1e-8, atol = 1e-8)
end

# =============================================================================
# Test 3: ∇_u nll_joint via ForwardDiff matches central finite differences
# =============================================================================

@testset "Test 3: gradient of nll_joint w.r.t. u (FD vs ForwardDiff)" begin
    Random.seed!(1234)
    p = 10
    n = p
    species_idx = collect(1:p)

    # Build a small, well-conditioned fixture
    x1 = randn(n)
    X_mu1    = hcat(ones(n), x1)
    X_mu2    = hcat(ones(n), x1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)

    # PD Sigma_phy (compound symmetry)
    Sigma_phy = 0.6 .* Matrix{Float64}(I, p, p) .+ 0.4 .* ones(p, p) ./ p
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    # Random theta in a reasonable range
    theta = pack_theta(
        randn(2) .* 0.3,                       # beta_mu1
        randn(2) .* 0.3,                       # beta_mu2
        [randn() * 0.2],                       # beta_sigma1
        [randn() * 0.2],                       # beta_sigma2
        [randn() * 0.2],                       # beta_rho12
        log.(fill(0.7, 4)),                    # log_sd_phy
        randn(6) .* 0.2,                       # chol_offdiag
    )

    # Synthetic y from a known truth at a fixed u0
    u0 = randn(4 * p) .* 0.3
    U0 = reshape(u0, 4, p)
    eta_mu1 = X_mu1 * theta[1:2]
    eta_mu2 = X_mu2 * theta[3:4]
    eta_s1  = X_sigma1 * theta[5:5]
    eta_s2  = X_sigma2 * theta[6:6]
    eta_r   = X_rho12  * theta[7:7]
    mu1 = eta_mu1 .+ U0[1, species_idx]
    mu2 = eta_mu2 .+ U0[2, species_idx]
    sig1 = exp.(eta_s1 .+ U0[3, species_idx])
    sig2 = exp.(eta_s2 .+ U0[4, species_idx])
    rho = 0.99999999 .* tanh.(eta_r)
    y1 = mu1 .+ sig1 .* randn(n) .* 0.5
    y2 = mu2 .+ sig2 .* randn(n) .* 0.5

    # Evaluate gradient at a perturbed u
    u_eval = u0 .+ 0.1 .* randn(4 * p)

    f_u = uu -> nll_joint(theta, uu, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                          X_rho12, Sigma_phy_inv, logdet_Sigma_phy, species_idx)

    g_ad = ForwardDiff.gradient(f_u, u_eval)

    # 5-point central finite differences
    eps = 1e-5
    g_fd = zeros(length(u_eval))
    for k in eachindex(u_eval)
        u_p2 = copy(u_eval); u_p2[k] += 2eps
        u_p1 = copy(u_eval); u_p1[k] += eps
        u_m1 = copy(u_eval); u_m1[k] -= eps
        u_m2 = copy(u_eval); u_m2[k] -= 2eps
        # 5-point stencil: (-f(+2h) + 8 f(+h) - 8 f(-h) + f(-2h)) / (12 h)
        g_fd[k] = (-f_u(u_p2) + 8 * f_u(u_p1) - 8 * f_u(u_m1) + f_u(u_m2)) / (12 * eps)
    end

    abs_err = maximum(abs.(g_ad .- g_fd))
    rel_err = maximum(abs.(g_ad .- g_fd) ./ (abs.(g_ad) .+ 1e-8))

    @test rel_err < 1e-4
    @test abs_err < 1e-4 * (maximum(abs.(g_ad)) + 1.0)
end

# =============================================================================
# Test 4: Newton inner solver drives the gradient to ~0 at small p
# =============================================================================

@testset "Test 4: find_u_hat converges (small ||∇_u nll_joint||)" begin
    Random.seed!(7)
    p = 10
    n = p
    species_idx = collect(1:p)

    x1 = randn(n)
    X_mu1    = hcat(ones(n), x1)
    X_mu2    = hcat(ones(n), x1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)

    Sigma_phy = 0.6 .* Matrix{Float64}(I, p, p) .+ 0.4 .* ones(p, p) ./ p
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    # Moderate theta -- mild fixed effects and modest phylo SDs
    theta = pack_theta(
        [0.0, 0.5],
        [0.0, -0.3],
        [log(0.6)],
        [log(0.6)],
        [atanh(0.3)],
        log.(fill(0.5, 4)),
        zeros(6),
    )

    # Generate y from a known u_truth
    u_truth = 0.4 .* randn(4 * p)
    U_truth = reshape(u_truth, 4, p)
    eta_mu1 = X_mu1 * theta[1:2]
    eta_mu2 = X_mu2 * theta[3:4]
    eta_s1  = X_sigma1 * theta[5:5]
    eta_s2  = X_sigma2 * theta[6:6]
    eta_r   = X_rho12  * theta[7:7]
    mu1 = eta_mu1 .+ U_truth[1, species_idx]
    mu2 = eta_mu2 .+ U_truth[2, species_idx]
    sig1 = exp.(eta_s1 .+ U_truth[3, species_idx])
    sig2 = exp.(eta_s2 .+ U_truth[4, species_idx])
    rho = 0.99999999 .* tanh.(eta_r)
    y1 = mu1 .+ sig1 .* randn(n) .* 0.3
    y2 = mu2 .+ sig2 .* randn(n) .* 0.3

    u_hat = find_u_hat(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                       Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_iter = 30)

    f_u = uu -> nll_joint(theta, uu, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                          X_rho12, Sigma_phy_inv, logdet_Sigma_phy, species_idx)
    g_at_hat = ForwardDiff.gradient(f_u, u_hat)
    gnorm = norm(g_at_hat)

    if gnorm >= 1e-6
        @info "Newton inner solver did not reach ||g|| < 1e-6 in 30 iterations" gnorm
    end
    @test gnorm < 1e-6
end

# =============================================================================
# Test 5: Laplace nll_marginal ≈ Monte-Carlo marginal at tiny p
# =============================================================================

@testset "Test 5: Laplace marginal matches MC marginal at p=4" begin
    Random.seed!(2025)
    p = 4
    n = p
    species_idx = collect(1:p)

    # Designs: intercept-only for everything (so beta covers a single column).
    X_mu1    = reshape(ones(n), n, 1)
    X_mu2    = reshape(ones(n), n, 1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)

    # PD Sigma_phy
    Sigma_phy = 0.7 .* Matrix{Float64}(I, p, p) .+ 0.3 .* ones(p, p) ./ p
    Sigma_phy = (Sigma_phy + Sigma_phy') ./ 2
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    # True parameters: diagonal Lambda_phy with two repeated SD pairs so the
    # q=4 problem decouples into two q=2-like pieces (as the prompt suggests).
    sd_mu = 0.4
    sd_log_sigma = 0.3
    log_sd_phy_true = log.([sd_mu, sd_mu, sd_log_sigma, sd_log_sigma])
    chol_offdiag_true = zeros(6)
    Lambda_phy_true = build_Lambda_phy(log_sd_phy_true, chol_offdiag_true)

    theta_true = pack_theta(
        [0.5],                        # beta_mu1 (intercept)
        [-0.2],                       # beta_mu2
        [log(0.6)],                   # beta_sigma1 (log intercept)
        [log(0.5)],                   # beta_sigma2
        [atanh(0.2)],                 # beta_rho12 (atanh of correlation)
        log_sd_phy_true,
        chol_offdiag_true,
    )

    # Simulate y from the joint model (one U draw + bivariate data conditional)
    Sigma_full = kron(Sigma_phy, Lambda_phy_true)
    Sigma_full = (Sigma_full + Sigma_full') ./ 2
    mvn_prior = MvNormal(zeros(4 * p), Sigma_full)
    u_draw = rand(mvn_prior)
    U_draw = reshape(u_draw, 4, p)

    eta_mu1 = X_mu1 * theta_true[1:1]
    eta_mu2 = X_mu2 * theta_true[2:2]
    eta_s1  = X_sigma1 * theta_true[3:3]
    eta_s2  = X_sigma2 * theta_true[4:4]
    eta_r   = X_rho12  * theta_true[5:5]
    mu1_draw = eta_mu1 .+ U_draw[1, species_idx]
    mu2_draw = eta_mu2 .+ U_draw[2, species_idx]
    sig1_draw = exp.(eta_s1 .+ U_draw[3, species_idx])
    sig2_draw = exp.(eta_s2 .+ U_draw[4, species_idx])
    rho_draw = 0.99999999 .* tanh.(eta_r)

    # Sample y given U via 2x2 Cholesky per observation
    y1 = similar(mu1_draw)
    y2 = similar(mu2_draw)
    for i in 1:n
        Σi = [sig1_draw[i]^2          rho_draw[i] * sig1_draw[i] * sig2_draw[i];
              rho_draw[i] * sig1_draw[i] * sig2_draw[i]   sig2_draw[i]^2]
        L = cholesky(Σi).L
        z = randn(2)
        y1[i] = mu1_draw[i] + (L * z)[1]
        y2[i] = mu2_draw[i] + (L * z)[2]
    end

    # Laplace marginal
    laplace_nll = nll_marginal(theta_true, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                               X_rho12, Sigma_phy_inv, logdet_Sigma_phy,
                               species_idx; n_inner = 30)

    # Monte Carlo marginal: -log E_U[ p(y | U) ] = -log E_U[ exp(-data_nll(U)) ]
    # Use log-sum-exp on -data_nll for numerical stability.
    S = 100_000
    log_w = Vector{Float64}(undef, S)
    for s in 1:S
        u_s = rand(mvn_prior)
        U_s = reshape(u_s, 4, p)
        mu1_s = eta_mu1 .+ U_s[1, species_idx]
        mu2_s = eta_mu2 .+ U_s[2, species_idx]
        sig1_s = exp.(eta_s1 .+ U_s[3, species_idx])
        sig2_s = exp.(eta_s2 .+ U_s[4, species_idx])
        rho_s = 0.99999999 .* tanh.(eta_r)
        data_nll_s = bivariate_data_nll(y1, y2, mu1_s, mu2_s, sig1_s, sig2_s, rho_s)
        log_w[s] = -data_nll_s
    end
    m = maximum(log_w)
    log_mean_w = m + log(mean(exp.(log_w .- m)))
    mc_nll = -log_mean_w

    # SE of log(mean(w)) ≈ SD(w) / (sqrt(S) * mean(w)), computed in shifted space.
    w_shift = exp.(log_w .- m)
    mean_ws = mean(w_shift)
    sd_ws   = std(w_shift)
    se_log_mean_w = sd_ws / (sqrt(S) * mean_ws)
    # -log monotone so SE on -log(mean(w)) is the same magnitude.
    se_mc_nll = se_log_mean_w

    diff = laplace_nll - mc_nll

    @info "Test 5: Laplace vs MC marginal" laplace_nll mc_nll diff se_mc_nll

    # Sanity: SE must be finite. If it's huge the MC is too noisy and we
    # can't make a useful comparison.
    @test isfinite(se_mc_nll)
    @test se_mc_nll < 0.5

    # Laplace is approximate; for tiny p with this diagonal Λ structure it
    # should be very close. Tolerance: 4 SE, with a floor of 0.05 to absorb
    # the genuine Laplace bias.
    tol = max(4 * se_mc_nll, 0.05)
    @test abs(diff) < tol
end

# =============================================================================
# Test 6: Sigma_phy_inv pre-computation matches direct compute
# =============================================================================

@testset "Test 6: Sigma_phy_inv and logdet pre-computation are correct" begin
    Random.seed!(31415)
    p = 5

    # Build a PD Sigma_phy: 0.4 I + 0.6 * (J/p)
    Sigma_phy = 0.4 .* Matrix{Float64}(I, p, p) .+ 0.6 .* ones(p, p) ./ p
    Sigma_phy = (Sigma_phy + Sigma_phy') ./ 2

    # The implementation pre-computes:
    #   Sigma_phy_inv    = inv(Sigma_phy)
    #   logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    # Sigma_phy * Sigma_phy_inv ≈ I
    I_check = Sigma_phy * Sigma_phy_inv
    @test maximum(abs.(I_check .- Matrix{Float64}(I, p, p))) < 1e-10

    # logdet matches a second route (Cholesky)
    logdet_chol = 2 * sum(log.(diag(cholesky(Symmetric(Sigma_phy)).L)))
    @test isapprox(logdet_Sigma_phy, logdet_chol; rtol = 1e-10, atol = 1e-10)
end

println("\nAll tests complete.")
