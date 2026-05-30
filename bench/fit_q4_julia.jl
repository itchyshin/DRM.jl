# drmTMB POC -- Julia engine for the q=4 bivariate phylogenetic location-scale
# Gaussian model (PLSM), i.e. Model 5 of Nakagawa et al. 2025 MEE.
#
# Model (per species i = 1..p, one observation per species):
#   U is 4 x p, columns indexed by species. vec(U) ~ MVN(0, Sigma_phy ⊗ Lambda_phy)
#     where Sigma_phy (p x p) is the phylogenetic correlation matrix (read
#     from CSV), and Lambda_phy (4 x 4) is the 4-axis phylogenetic covariance
#     to estimate.
#   Conditional on U,
#     mu1_i    = X_mu1[i,:] * beta_mu1    + U[1, s_i]
#     mu2_i    = X_mu2[i,:] * beta_mu2    + U[2, s_i]
#     sigma1_i = exp(X_sigma1[i,:] * beta_sigma1 + U[3, s_i])
#     sigma2_i = exp(X_sigma2[i,:] * beta_sigma2 + U[4, s_i])
#     rho_i    = 0.99999999 * tanh(X_rho12[i,:] * beta_rho12)
#     (y1_i, y2_i) | U ~ MVN((mu1_i, mu2_i), Sigma_2x2(sigma1_i, sigma2_i, rho_i))
#
# Outer parameter vector theta (17 entries for q4_p100):
#   beta_mu1     (2 = intercept + x1)
#   beta_mu2     (2)
#   beta_sigma1  (1, intercept only)
#   beta_sigma2  (1)
#   beta_rho12   (1)
#   log_sd_phy   (4, log of marginal SDs for the 4 phylo axes)
#   chol_offdiag (6, strict-lower of unconstrained Cholesky factor of
#                 the 4 x 4 correlation matrix R; reconstruction rule below.)
#
# Inner Laplace mode finding uses a fixed-iteration Newton with ForwardDiff
# (no convergence check; AD flows cleanly). Outer optimization is LBFGS with
# ForwardDiff over the marginal Laplace NLL.
#
# Inputs : ../fixtures/q4_p100.csv, q4_p100_sigma_phy.csv, q4_p100_truth.json
# Output : appended to ../results/julia_results.json

using ADTypes
using CSV
using DataFrames
using ForwardDiff
using JSON3
using LinearAlgebra
using Optim
using Statistics

# -----------------------------------------------------------------------------
# Correlation matrix construction from unconstrained Cholesky offdiagonals
# -----------------------------------------------------------------------------

"""
    chol_offdiag_to_R(chol_off)

Take the 6-vector `chol_off` (strict lower 4x4) and return a 4x4 correlation
matrix R. We build a unit-lower Cholesky factor L (L[i,i] = 1, L[i,j] = chol_off
for i>j), row-normalize so each row has unit Euclidean norm, then R = L * L'.
"""
function chol_offdiag_to_R(chol_off::AbstractVector{T}) where {T}
    # idx(i,j) for i in 2..4, j in 1..i-1 -> 1..6
    # ordering: (2,1)(3,1)(3,2)(4,1)(4,2)(4,3) = 1,2,3,4,5,6
    L = Matrix{T}(undef, 4, 4)
    @inbounds for i in 1:4, j in 1:4
        L[i, j] = zero(T)
    end
    L[1, 1] = one(T)
    L[2, 1] = chol_off[1]; L[2, 2] = one(T)
    L[3, 1] = chol_off[2]; L[3, 2] = chol_off[3]; L[3, 3] = one(T)
    L[4, 1] = chol_off[4]; L[4, 2] = chol_off[5]; L[4, 3] = chol_off[6]; L[4, 4] = one(T)
    # row-normalize so diag(L L') = I
    Lhat = Matrix{T}(undef, 4, 4)
    @inbounds for i in 1:4
        nrm = sqrt(sum(L[i, k]^2 for k in 1:4))
        for k in 1:4
            Lhat[i, k] = L[i, k] / nrm
        end
    end
    return Lhat * Lhat'
end

"""
    build_Lambda_phy(log_sd, chol_off)

Lambda_phy = diag(exp(log_sd)) * R * diag(exp(log_sd))
"""
function build_Lambda_phy(log_sd::AbstractVector{T1}, chol_off::AbstractVector{T2}) where {T1, T2}
    T = promote_type(T1, T2)
    R = chol_offdiag_to_R(convert(Vector{T}, chol_off))
    sd = exp.(convert(Vector{T}, log_sd))
    return Diagonal(sd) * R * Diagonal(sd)
end

# -----------------------------------------------------------------------------
# Joint negative log-density:  -log p(y, u | theta)
# -----------------------------------------------------------------------------

"""
    nll_joint(theta, u_flat, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
              Sigma_phy_inv, logdet_Sigma_phy, species_idx)

Joint negative log-density of (y, U) at fixed theta, with u_flat = vec(U) of
length 4p (species are columns of U).
"""
function nll_joint(theta::AbstractVector{T1}, u_flat::AbstractVector{T2},
                   y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                   Sigma_phy_inv::AbstractMatrix{Float64},
                   logdet_Sigma_phy::Float64,
                   species_idx::AbstractVector{Int}) where {T1, T2}
    T = promote_type(T1, T2)
    n = length(y1)
    p = size(Sigma_phy_inv, 1)

    # Unpack theta (q4_p100 layout: 2+2+1+1+1+4+6 = 17)
    p_mu1    = size(X_mu1, 2)
    p_mu2    = size(X_mu2, 2)
    p_sigma1 = size(X_sigma1, 2)
    p_sigma2 = size(X_sigma2, 2)
    p_rho12  = size(X_rho12, 2)

    i = 0
    beta_mu1    = theta[i+1:i+p_mu1];    i += p_mu1
    beta_mu2    = theta[i+1:i+p_mu2];    i += p_mu2
    beta_sigma1 = theta[i+1:i+p_sigma1]; i += p_sigma1
    beta_sigma2 = theta[i+1:i+p_sigma2]; i += p_sigma2
    beta_rho12  = theta[i+1:i+p_rho12];  i += p_rho12
    log_sd_phy   = theta[i+1:i+4];        i += 4
    chol_offdiag = theta[i+1:i+6];        i += 6

    # Reshape u_flat to U (4 x p). Column j = species j.
    # u_flat order: row-major by species so that u_flat[(j-1)*4 + k] = U[k, j].
    # i.e. species j's 4-block is contiguous.
    U = reshape(u_flat, 4, p)

    # Linear predictors (per observation row i)
    eta_mu1    = X_mu1 * beta_mu1
    eta_mu2    = X_mu2 * beta_mu2
    eta_sigma1 = X_sigma1 * beta_sigma1
    eta_sigma2 = X_sigma2 * beta_sigma2
    eta_rho12  = X_rho12 * beta_rho12

    # Add U effects per row (allocation-free element-wise loop friendly to AD)
    mu1    = Vector{T}(undef, n)
    mu2    = Vector{T}(undef, n)
    sigma1 = Vector{T}(undef, n)
    sigma2 = Vector{T}(undef, n)
    rho    = Vector{T}(undef, n)
    @inbounds for r in 1:n
        s = species_idx[r]
        mu1[r]    = eta_mu1[r]    + U[1, s]
        mu2[r]    = eta_mu2[r]    + U[2, s]
        sigma1[r] = exp(eta_sigma1[r] + U[3, s])
        sigma2[r] = exp(eta_sigma2[r] + U[4, s])
        rho[r]    = 0.99999999 * tanh(eta_rho12[r])
    end

    # 2x2 closed-form bivariate Gaussian NLL (data part)
    e1 = y1 .- mu1
    e2 = y2 .- mu2
    one_minus_rho2 = 1 .- rho .^ 2
    quad_data = (e1 .^ 2 ./ sigma1 .^ 2 .- 2 .* rho .* e1 .* e2 ./ (sigma1 .* sigma2) .+
                 e2 .^ 2 ./ sigma2 .^ 2) ./ one_minus_rho2
    log_det_data = 2 .* (log.(sigma1) .+ log.(sigma2)) .+ log.(one_minus_rho2)
    nll_data = 0.5 * sum(log_det_data .+ quad_data) + n * log(2π)

    # Prior on U: vec(U) ~ MVN(0, Sigma_phy ⊗ Lambda_phy)
    # Using the Kronecker identity:
    #   vec(U)' (Sigma_phy ⊗ Lambda_phy)^{-1} vec(U)
    #   = tr(Lambda_phy^{-1} * U * Sigma_phy^{-1} * U')
    Lambda_phy = build_Lambda_phy(log_sd_phy, chol_offdiag)
    Lambda_inv = inv(Lambda_phy)
    # Quadratic form: trace(Lambda_inv * U * Sigma_phy_inv * U')
    # M = U * Sigma_phy_inv     (4 x p)
    # quad = sum_{k,j} Lambda_inv[k, :] * U[:, j] * Sigma_phy_inv[:, j]?
    # Simpler: tr(A * B) where A = Lambda_inv * U (4 x p), B = Sigma_phy_inv * U' (p x 4)
    A = Lambda_inv * U
    B = Sigma_phy_inv * transpose(U)
    quad_prior = tr(A * B)

    # log|Sigma_phy ⊗ Lambda_phy| = 4 * log|Sigma_phy| + p * log|Lambda_phy|
    logdet_Lambda = logdet(Lambda_phy)
    logdet_cov_prior = p * logdet_Lambda + 4 * logdet_Sigma_phy

    # Constant: 4p * log(2π) / 2  (since dimension is 4p)
    const_prior = 4 * p * log(2π)

    nll_prior = 0.5 * (quad_prior + logdet_cov_prior + const_prior)

    return nll_data + nll_prior
end

# -----------------------------------------------------------------------------
# Inner Newton solver for u_hat
# -----------------------------------------------------------------------------

"""
    find_u_hat(theta, y1, y2, X_*, Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_iter)

Fixed-iteration Newton minimizing nll_joint over u, with theta held fixed.
NO convergence check; AD flows through cleanly. ForwardDiff for gradient and
Hessian (the latter is 4p x 4p).
"""
function find_u_hat(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                    Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_iter::Int=20)
    p = size(Sigma_phy_inv, 1)
    T = eltype(theta)
    u = zeros(T, 4 * p)
    f_u = uu -> nll_joint(theta, uu, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                          X_rho12, Sigma_phy_inv, logdet_Sigma_phy, species_idx)
    for _ in 1:n_iter
        g = ForwardDiff.gradient(f_u, u)
        H = ForwardDiff.hessian(f_u, u)
        Hs = Symmetric((H + H') / 2)
        # Ridge-regularized Newton: if Hs is non-PD, add progressively
        # larger λ·I until cholesky succeeds. Keeps Newton stable at bad theta.
        chol = cholesky(Hs; check=false)
        step = if issuccess(chol)
            chol \ g
        else
            local_step = nothing
            for ridge in (1e-6, 1e-4, 1e-2, 1.0, 1e2)
                cr = cholesky(Hs + ridge * I; check=false)
                if issuccess(cr)
                    local_step = cr \ g
                    break
                end
            end
            local_step === nothing ? 1e-3 .* g : local_step
        end
        u = u - step
    end
    return u
end

# -----------------------------------------------------------------------------
# Laplace marginal NLL
# -----------------------------------------------------------------------------

"""
    nll_marginal(theta, y1, y2, X_*, Sigma_phy_inv, logdet_Sigma_phy, species_idx)

Laplace approximation:
   -log p(y; theta) ≈ -log p(y, u_hat; theta) + 0.5 * log |H_uu| - 0.5 * d * log(2π)
where d = 4p and H_uu is the Hessian of nll_joint w.r.t. u at u_hat.
"""
function nll_marginal(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                      Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_inner::Int=20)
    p = size(Sigma_phy_inv, 1)
    u_hat = find_u_hat(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                       Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_iter=n_inner)
    f_u = uu -> nll_joint(theta, uu, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                          X_rho12, Sigma_phy_inv, logdet_Sigma_phy, species_idx)
    nll_at_hat = f_u(u_hat)
    H_uu = ForwardDiff.hessian(f_u, u_hat)
    Hs = Symmetric((H_uu + H_uu') / 2)
    # Robust logdet: try plain Cholesky first; if non-PD, add a tiny ridge.
    # If still non-PD, return Inf so outer optimizer rejects this step.
    chol = cholesky(Hs; check=false)
    if !issuccess(chol)
        chol = cholesky(Hs + 1e-4 * I; check=false)
        if !issuccess(chol)
            T = promote_type(eltype(theta), Float64)
            return convert(T, Inf)
        end
    end
    logdet_H = 2 * sum(log.(diag(chol.U)))
    d = 4 * p
    return nll_at_hat + 0.5 * logdet_H - 0.5 * d * log(2π)
end

# -----------------------------------------------------------------------------
# Initial values
# -----------------------------------------------------------------------------

function build_initial_theta(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    beta_mu1_0 = X_mu1 \ y1
    beta_mu2_0 = X_mu2 \ y2

    r1 = y1 .- X_mu1 * beta_mu1_0
    r2 = y2 .- X_mu2 * beta_mu2_0

    beta_sigma1_0 = zeros(size(X_sigma1, 2))
    beta_sigma1_0[1] = log(max(std(r1), 1e-4))

    beta_sigma2_0 = zeros(size(X_sigma2, 2))
    beta_sigma2_0[1] = log(max(std(r2), 1e-4))

    sample_rho = clamp(cor(r1, r2), -0.95, 0.95)
    beta_rho12_0 = zeros(size(X_rho12, 2))
    beta_rho12_0[1] = atanh(sample_rho)

    log_sd_phy_0 = fill(log(0.5), 4)
    chol_offdiag_0 = zeros(6)

    return vcat(beta_mu1_0, beta_mu2_0, beta_sigma1_0, beta_sigma2_0, beta_rho12_0,
                log_sd_phy_0, chol_offdiag_0)
end

# -----------------------------------------------------------------------------
# Fit driver
# -----------------------------------------------------------------------------

function fit_q4(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                Sigma_phy, species_idx;
                g_tol::Float64=1e-3, iterations::Int=100, n_inner::Int=20,
                show_trace::Bool=true)
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    theta0 = build_initial_theta(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    println("  theta0 length = $(length(theta0))")
    println("  theta0 = $(round.(theta0; digits=4))")

    f(theta) = nll_marginal(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                            Sigma_phy_inv, logdet_Sigma_phy, species_idx; n_inner=n_inner)

    # Sanity: evaluate at theta0
    nll0 = f(theta0)
    println("  nll_marginal(theta0) = $nll0")

    # Outer gradient via FINITE DIFFERENCES, NOT nested ForwardDiff.
    # nll_marginal already uses ForwardDiff internally (inner Newton + Laplace
    # Hessian). Differentiating that again with ForwardDiff creates a
    # Dual-of-Dual computation that is pathologically slow (>8 min/gradient at
    # p=20). Optim falls back to central finite differences when no autodiff is
    # supplied: outer gradient = (dim(theta)+1) cheap nll_marginal evals.
    res = Optim.optimize(
        f,
        theta0,
        LBFGS(),
        Optim.Options(
            g_tol = g_tol,
            iterations = iterations,
            show_trace = show_trace,
            show_every = 1,
        ),
    )

    theta_hat = Optim.minimizer(res)
    return (
        theta = theta_hat,
        nll = Optim.minimum(res),
        logLik = -Optim.minimum(res),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
        g_residual = Optim.g_residual(res),
        f_calls = Optim.f_calls(res),
    )
end

# -----------------------------------------------------------------------------
# Result post-processing
# -----------------------------------------------------------------------------

function unpack_theta(theta_hat, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    p_mu1    = size(X_mu1, 2)
    p_mu2    = size(X_mu2, 2)
    p_sigma1 = size(X_sigma1, 2)
    p_sigma2 = size(X_sigma2, 2)
    p_rho12  = size(X_rho12, 2)

    i = 0
    beta_mu1    = theta_hat[i+1:i+p_mu1];    i += p_mu1
    beta_mu2    = theta_hat[i+1:i+p_mu2];    i += p_mu2
    beta_sigma1 = theta_hat[i+1:i+p_sigma1]; i += p_sigma1
    beta_sigma2 = theta_hat[i+1:i+p_sigma2]; i += p_sigma2
    beta_rho12  = theta_hat[i+1:i+p_rho12];  i += p_rho12
    log_sd_phy   = theta_hat[i+1:i+4];        i += 4
    chol_offdiag = theta_hat[i+1:i+6];        i += 6

    R = chol_offdiag_to_R(chol_offdiag)
    sd_phy = exp.(log_sd_phy)
    # Pair ordering (i, j) with i < j:  (1,2)(1,3)(1,4)(2,3)(2,4)(3,4)
    cor_phy = [R[1,2], R[1,3], R[1,4], R[2,3], R[2,4], R[3,4]]

    return (
        beta_mu1 = beta_mu1, beta_mu2 = beta_mu2,
        beta_sigma1 = beta_sigma1, beta_sigma2 = beta_sigma2,
        beta_rho12 = beta_rho12,
        log_sd_phy = log_sd_phy, sd_phy = sd_phy,
        chol_offdiag = chol_offdiag, R = R, cor_phy = cor_phy,
    )
end

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

function main()
    script_dir = @__DIR__
    fixtures_dir = normpath(joinpath(script_dir, "..", "fixtures"))
    results_dir = normpath(joinpath(script_dir, "..", "results"))
    mkpath(results_dir)

    fixture_csv = joinpath(fixtures_dir, "q4_p100.csv")
    sigma_phy_csv = joinpath(fixtures_dir, "q4_p100_sigma_phy.csv")

    df = CSV.read(fixture_csv, DataFrame)
    println("Read $fixture_csv ($(nrow(df)) rows)")

    # Sigma_phy: read header columns s1..sp, drop names
    M = Matrix{Float64}(CSV.read(sigma_phy_csv, DataFrame))
    p = size(M, 1)
    @assert size(M, 1) == size(M, 2) "Sigma_phy not square"
    Sigma_phy = M
    println("Sigma_phy: $p x $p")

    # Build species_idx aligned with df rows, in the order matching Sigma_phy
    # rows. The Sigma_phy columns are named s1..sp, and we expect df rows to
    # follow tip labels. Map species name -> col index.
    # The fixture df has a 'species' column (e.g. t39). Map them to 1..p by
    # first appearance. We must use the SAME ordering as Sigma_phy, but
    # Sigma_phy columns are anonymous (s1..sp). The fixture's species ordering
    # in Sigma_phy corresponds to the order of unique(df.species). We follow
    # that convention.
    @assert nrow(df) == p "Expected one row per species for q4_p100 (n=$(nrow(df)), p=$p)"
    species_levels = unique(df.species)
    @assert length(species_levels) == p "species_levels length ($(length(species_levels))) != p ($p)"
    sp_to_idx = Dict(s => i for (i, s) in enumerate(species_levels))
    species_idx = [sp_to_idx[s] for s in df.species]

    # Designs (matches the drmTMB bf() spec in the prompt)
    n = nrow(df)
    X_mu1    = hcat(ones(n), df.x1)
    X_mu2    = hcat(ones(n), df.x1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)

    y1 = Vector{Float64}(df.y1)
    y2 = Vector{Float64}(df.y2)

    println("\n--- Warm-up fit ---")
    t_warm = @elapsed res_warm = fit_q4(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                                        Sigma_phy, species_idx;
                                        g_tol=1e-3, iterations=100, n_inner=20,
                                        show_trace=true)
    println("Warm-up: $t_warm s, logLik=$(res_warm.logLik), converged=$(res_warm.converged), " *
            "iter=$(res_warm.iterations), g_residual=$(res_warm.g_residual)")

    println("\n--- Timed fit 1 ---")
    t1 = @elapsed res1 = fit_q4(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                                Sigma_phy, species_idx;
                                g_tol=1e-3, iterations=100, n_inner=20,
                                show_trace=false)
    println("Timed 1: $t1 s, logLik=$(res1.logLik), converged=$(res1.converged), iter=$(res1.iterations)")

    println("\n--- Timed fit 2 ---")
    t2 = @elapsed res2 = fit_q4(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                                Sigma_phy, species_idx;
                                g_tol=1e-3, iterations=100, n_inner=20,
                                show_trace=false)
    println("Timed 2: $t2 s, logLik=$(res2.logLik), converged=$(res2.converged), iter=$(res2.iterations)")

    times = [t1, t2]
    time_med = median(times)

    # Use the last fit's theta_hat for reporting
    res_final = res2
    upk = unpack_theta(res_final.theta, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)

    println("\n--- Final estimates ---")
    println("logLik       = $(res_final.logLik)")
    println("beta_mu1     = $(upk.beta_mu1)")
    println("beta_mu2     = $(upk.beta_mu2)")
    println("beta_sigma1  = $(upk.beta_sigma1)")
    println("beta_sigma2  = $(upk.beta_sigma2)")
    println("beta_rho12   = $(upk.beta_rho12)")
    println("log_sd_phy   = $(upk.log_sd_phy)")
    println("sd_phy       = $(upk.sd_phy)")
    println("cor_phy      = $(upk.cor_phy)")

    # Build the result entry
    entry = Dict(
        "cell_id" => "q4_p100",
        "engine"  => "julia_poc",
        "n"       => n,
        "p_species" => p,
        "model"   => "q4",
        "warmup_time_s" => t_warm,
        "time_s" => mean(times),
        "time_s_med" => time_med,
        "times_all" => round.(times; digits=4),
        "logLik" => res_final.logLik,
        "converged" => res_final.converged,
        "n_iter" => res_final.iterations,
        "g_residual" => res_final.g_residual,
        "beta_mu1" => round.(upk.beta_mu1; digits=4),
        "beta_mu2" => round.(upk.beta_mu2; digits=4),
        "beta_sigma1" => length(upk.beta_sigma1) == 1 ?
                         round(upk.beta_sigma1[1]; digits=4) :
                         round.(upk.beta_sigma1; digits=4),
        "beta_sigma2" => length(upk.beta_sigma2) == 1 ?
                         round(upk.beta_sigma2[1]; digits=4) :
                         round.(upk.beta_sigma2; digits=4),
        "beta_rho12"  => length(upk.beta_rho12) == 1 ?
                         round(upk.beta_rho12[1]; digits=4) :
                         round.(upk.beta_rho12; digits=4),
        "log_sd_phy" => round.(upk.log_sd_phy; digits=4),
        "sd_phy" => round.(upk.sd_phy; digits=4),
        "cor_phy" => round.(upk.cor_phy; digits=4),
        "note" => "Laplace approximation (ForwardDiff Newton inner, ForwardDiff LBFGS outer)",
    )

    # Read existing results, merge, write
    results_path = joinpath(results_dir, "julia_results.json")
    existing = if isfile(results_path)
        try
            JSON3.read(read(results_path, String))
        catch
            []
        end
    else
        []
    end
    merged = Any[]
    for r in existing
        if get(r, "cell_id", nothing) != "q4_p100"
            push!(merged, r)
        end
    end
    push!(merged, entry)

    open(results_path, "w") do io
        JSON3.write(io, merged)
    end
    println("\nWrote q4_p100 entry to $results_path")

    return entry
end

# Only run main() when this file is executed as a script (not when included).
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
