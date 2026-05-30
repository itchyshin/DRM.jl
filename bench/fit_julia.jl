# drmTMB POC — Julia engine for univariate / bivariate Gaussian distributional regression.
#
# Likelihood parameterisation follows /Users/z3437171/Dropbox/Github Local/drm-julia-poc/CONTRACT.md:
#   mu_i    = X_mu_i' * beta_mu                       (identity)
#   sigma_i = exp(X_sigma_i' * beta_sigma)            (log link)
#   rho_i   = 0.99999999 * tanh(X_rho12_i' * beta_rho12)
# The 2x2 closed-form bivariate Gaussian density avoids per-row MvNormal overhead.
#
# Inputs : ../fixtures/<cell_id>.csv (written by the R harness)
# Output : ../results/julia_results.json

using ADTypes
using CSV
using DataFrames
using ForwardDiff
using JSON3
using LinearAlgebra
using Optim
using Random
using Statistics

# -----------------------------------------------------------------------------
# Negative log-likelihoods
# -----------------------------------------------------------------------------

"""
    nll_univariate(theta, y, X_mu, X_sigma)

Negative log-likelihood for Gaussian distributional regression with identity link
on mu and log link on sigma. `theta = [beta_mu; beta_sigma]`.
"""
function nll_univariate(theta, y, X_mu, X_sigma)
    p_mu = size(X_mu, 2)
    beta_mu = theta[1:p_mu]
    beta_sigma = theta[p_mu+1:end]
    mu = X_mu * beta_mu
    log_sigma = X_sigma * beta_sigma
    sigma = exp.(log_sigma)
    return 0.5 * sum(((y .- mu) ./ sigma) .^ 2) + sum(log_sigma) +
           0.5 * length(y) * log(2π)
end

"""
    nll_phylo_uni(theta, y, X_mu, Sigma_phy)

Negative log-likelihood for the univariate Gaussian + phylogenetic random
intercept model, in closed form (one obs per species). Parameter order
`theta = [beta_mu...; log_sigma_phy; log_sigma_eps]`. Marginal covariance is
`Sigma_y = sigma_phy^2 * Sigma_phy + sigma_eps^2 * I(p)`.

ForwardDiff-compatible: `cholesky(Symmetric(...))` works for AD Duals in
current ForwardDiff.
"""
function nll_phylo_uni(theta, y, X_mu, Sigma_phy)
    q = size(X_mu, 2)
    beta_mu = theta[1:q]
    log_sigma_phy = theta[q+1]
    log_sigma_eps = theta[q+2]
    sigma_phy = exp(log_sigma_phy)
    sigma_eps = exp(log_sigma_eps)
    p = length(y)
    Sigma_y = (sigma_phy^2) .* Sigma_phy .+ (sigma_eps^2) .* I(p)
    L = cholesky(Symmetric(Sigma_y)).L
    e = y .- X_mu * beta_mu
    z = L \ e
    logdet_Sigma = 2 * sum(log.(diag(L)))
    return 0.5 * (dot(z, z) + logdet_Sigma) + 0.5 * p * log(2π)
end

"""
    nll_bivariate(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)

Negative log-likelihood for bivariate Gaussian distributional regression with
identity links on mu1, mu2; log links on sigma1, sigma2; and `0.99999999*tanh`
on rho12.  Uses the 2x2 closed-form Gaussian density (no per-row MvNormal).
"""
function nll_bivariate(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    p1 = size(X_mu1, 2)
    p2 = size(X_mu2, 2)
    p3 = size(X_sigma1, 2)
    p4 = size(X_sigma2, 2)
    p5 = size(X_rho12, 2)

    i = 0
    beta_mu1 = theta[i+1:i+p1]; i += p1
    beta_mu2 = theta[i+1:i+p2]; i += p2
    beta_sigma1 = theta[i+1:i+p3]; i += p3
    beta_sigma2 = theta[i+1:i+p4]; i += p4
    beta_rho12 = theta[i+1:i+p5]

    mu1 = X_mu1 * beta_mu1
    mu2 = X_mu2 * beta_mu2
    s1 = exp.(X_sigma1 * beta_sigma1)
    s2 = exp.(X_sigma2 * beta_sigma2)
    eta = X_rho12 * beta_rho12
    rho = 0.99999999 .* tanh.(eta)

    e1 = y1 .- mu1
    e2 = y2 .- mu2
    one_minus_rho2 = 1 .- rho .^ 2
    quad = (e1 .^ 2 ./ s1 .^ 2 .- 2 .* rho .* e1 .* e2 ./ (s1 .* s2) .+
            e2 .^ 2 ./ s2 .^ 2) ./ one_minus_rho2
    log_det = 2 .* (log.(s1) .+ log.(s2)) .+ log.(one_minus_rho2)
    return 0.5 * sum(log_det .+ quad) + length(y1) * log(2π)
end

# -----------------------------------------------------------------------------
# Fit drivers
# -----------------------------------------------------------------------------

"""
    fit_univariate(y, X_mu, X_sigma)

LBFGS + ForwardDiff fit. Init:
  beta_mu0      = OLS of y on X_mu
  beta_sigma0   = log-residual regression / 2 (log SD link)
"""
function fit_univariate(y, X_mu, X_sigma)
    p_mu = size(X_mu, 2)
    p_sigma = size(X_sigma, 2)

    beta_mu0 = X_mu \ y
    resid2 = max.((y .- X_mu * beta_mu0) .^ 2, 1e-8)
    beta_sigma0 = (X_sigma \ log.(resid2)) ./ 2

    theta0 = vcat(beta_mu0, beta_sigma0)
    f(theta) = nll_univariate(theta, y, X_mu, X_sigma)
    od = OnceDifferentiable(f, theta0; autodiff = AutoForwardDiff())

    res = Optim.optimize(
        od,
        theta0,
        LBFGS(),
        Optim.Options(g_tol = 1e-8, iterations = 500),
    )

    theta_hat = Optim.minimizer(res)
    return (
        theta = theta_hat,
        beta_mu = theta_hat[1:p_mu],
        beta_sigma = theta_hat[p_mu+1:end],
        logLik = -Optim.minimum(res),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
    )
end

"""
    fit_bivariate(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
"""
function fit_bivariate(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    p1 = size(X_mu1, 2)
    p2 = size(X_mu2, 2)
    p3 = size(X_sigma1, 2)
    p4 = size(X_sigma2, 2)
    p5 = size(X_rho12, 2)

    beta_mu1_0 = X_mu1 \ y1
    beta_mu2_0 = X_mu2 \ y2
    r1 = y1 .- X_mu1 * beta_mu1_0
    r2 = y2 .- X_mu2 * beta_mu2_0

    beta_sigma1_0 = zeros(p3)
    beta_sigma1_0[1] = log(max(std(r1), 1e-4))
    beta_sigma2_0 = zeros(p4)
    beta_sigma2_0[1] = log(max(std(r2), 1e-4))

    sample_rho = clamp(cor(r1, r2), -0.95, 0.95)
    beta_rho12_0 = zeros(p5)
    beta_rho12_0[1] = atanh(sample_rho)

    theta0 = vcat(beta_mu1_0, beta_mu2_0, beta_sigma1_0, beta_sigma2_0, beta_rho12_0)
    f(theta) = nll_bivariate(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    od = OnceDifferentiable(f, theta0; autodiff = AutoForwardDiff())

    res = Optim.optimize(
        od,
        theta0,
        LBFGS(),
        Optim.Options(g_tol = 1e-8, iterations = 500),
    )

    theta_hat = Optim.minimizer(res)
    i = 0
    beta_mu1 = theta_hat[i+1:i+p1]; i += p1
    beta_mu2 = theta_hat[i+1:i+p2]; i += p2
    beta_sigma1 = theta_hat[i+1:i+p3]; i += p3
    beta_sigma2 = theta_hat[i+1:i+p4]; i += p4
    beta_rho12 = theta_hat[i+1:i+p5]

    return (
        theta = theta_hat,
        beta_mu1 = beta_mu1,
        beta_mu2 = beta_mu2,
        beta_sigma1 = beta_sigma1,
        beta_sigma2 = beta_sigma2,
        beta_rho12 = beta_rho12,
        logLik = -Optim.minimum(res),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
    )
end

"""
    fit_phylo_uni(y, X_mu, Sigma_phy)

LBFGS + ForwardDiff fit for the univariate Gaussian + phylogenetic random
intercept model (closed-form marginal). Init:
  beta_mu0       = OLS of y on X_mu
  log_sigma_phy0 = 0.0       (sigma_phy = 1)
  log_sigma_eps0 = log(0.5)  (sigma_eps ≈ 0.5; safe positive start)
"""
function fit_phylo_uni(y, X_mu, Sigma_phy)
    q = size(X_mu, 2)

    beta_mu0 = X_mu \ y
    log_sigma_phy0 = 0.0
    log_sigma_eps0 = log(0.5)

    theta0 = vcat(beta_mu0, log_sigma_phy0, log_sigma_eps0)
    f(theta) = nll_phylo_uni(theta, y, X_mu, Sigma_phy)
    od = OnceDifferentiable(f, theta0; autodiff = AutoForwardDiff())

    res = Optim.optimize(
        od,
        theta0,
        LBFGS(),
        Optim.Options(g_tol = 1e-6, iterations = 500),
    )

    theta_hat = Optim.minimizer(res)
    return (
        theta = theta_hat,
        beta_mu = theta_hat[1:q],
        sigma_phy = exp(theta_hat[q+1]),
        sigma_eps = exp(theta_hat[q+2]),
        logLik = -Optim.minimum(res),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
    )
end

# -----------------------------------------------------------------------------
# Cell definitions (mirrors CONTRACT.md)
# -----------------------------------------------------------------------------

const CELLS = [
    (cell_id = "u_small",    n = 100,  model = :univariate),
    (cell_id = "u_med",      n = 500,  model = :univariate),
    (cell_id = "u_large",    n = 2000, model = :univariate),
    (cell_id = "b_small",    n = 200,  model = :bivariate),
    (cell_id = "b_med",      n = 1000, model = :bivariate),
    (cell_id = "phylo_p50",  n = 50,   model = :phylo_uni),
    (cell_id = "phylo_p200", n = 200,  model = :phylo_uni),
    (cell_id = "phylo_p500", n = 500,  model = :phylo_uni),
    (cell_id = "phylo_p1000",n = 1000, model = :phylo_uni),
]

"""
    build_univariate_designs(df)

For all three univariate cells: X_mu = [1 x1 x2], X_sigma = [1 x1].
"""
function build_univariate_designs(df::DataFrame)
    n = nrow(df)
    X_mu = hcat(ones(n), df.x1, df.x2)
    X_sigma = hcat(ones(n), df.x1)
    return (y = Vector{Float64}(df.y), X_mu = X_mu, X_sigma = X_sigma)
end

"""
    build_phylo_uni_designs(df)

For all phylo cells: X_mu = [1 x1], y = df.y.
"""
function build_phylo_uni_designs(df::DataFrame)
    n = nrow(df)
    X_mu = hcat(ones(n), df.x1)
    return (y = Vector{Float64}(df.y), X_mu = X_mu)
end

"""
    read_sigma_phy(path)

Read `<cell>_sigma_phy.csv` (p×p with column headers s1..sp). Drop the
headers and return a dense `Matrix{Float64}` of size p×p.
"""
function read_sigma_phy(path::AbstractString)
    df = CSV.read(path, DataFrame)
    M = Matrix{Float64}(df)
    p1, p2 = size(M)
    if p1 != p2
        error("Sigma_phy at $path is not square ($p1 × $p2)")
    end
    return M
end

"""
    build_bivariate_designs(df, cell_id)

b_small: X_mu1=X_mu2=[1 x1], X_sigma1=X_sigma2=[1], X_rho12=[1]
b_med  : X_mu1=X_mu2=[1 x1], X_sigma1=X_sigma2=[1 x1], X_rho12=[1 x1]
"""
function build_bivariate_designs(df::DataFrame, cell_id::AbstractString)
    n = nrow(df)
    X_mu1 = hcat(ones(n), df.x1)
    X_mu2 = hcat(ones(n), df.x1)
    if cell_id == "b_small"
        X_sigma1 = reshape(ones(n), n, 1)
        X_sigma2 = reshape(ones(n), n, 1)
        X_rho12 = reshape(ones(n), n, 1)
    elseif cell_id == "b_med"
        X_sigma1 = hcat(ones(n), df.x1)
        X_sigma2 = hcat(ones(n), df.x1)
        X_rho12 = hcat(ones(n), df.x1)
    else
        error("unknown bivariate cell_id: $cell_id")
    end
    return (
        y1 = Vector{Float64}(df.y1),
        y2 = Vector{Float64}(df.y2),
        X_mu1 = X_mu1, X_mu2 = X_mu2,
        X_sigma1 = X_sigma1, X_sigma2 = X_sigma2,
        X_rho12 = X_rho12,
    )
end

# -----------------------------------------------------------------------------
# Per-cell runner
# -----------------------------------------------------------------------------

"""
    run_cell(cell, fixtures_dir)

Warm-up fit then 5 timed fits, returns a result dict for the cell.
Errors out (caller catches) if the fixture CSV is missing.
"""
function run_cell(cell, fixtures_dir::AbstractString)
    fixture_path = joinpath(fixtures_dir, cell.cell_id * ".csv")
    if !isfile(fixture_path)
        error("Fixture not found: $fixture_path")
    end

    df = CSV.read(fixture_path, DataFrame)
    println("  -> read $(fixture_path) (n=$(nrow(df)))")

    if cell.model == :univariate
        d = build_univariate_designs(df)

        # warm-up
        _ = fit_univariate(d.y, d.X_mu, d.X_sigma)

        times = Float64[]
        local last_fit
        for _ in 1:5
            t = @elapsed last_fit = fit_univariate(d.y, d.X_mu, d.X_sigma)
            push!(times, t)
        end

        return Dict(
            "cell_id" => cell.cell_id,
            "engine" => "julia_poc",
            "time_s" => mean(times),
            "time_s_med" => median(times),
            "logLik" => last_fit.logLik,
            "converged" => last_fit.converged,
            "n_iter" => last_fit.iterations,
            "beta_mu" => collect(last_fit.beta_mu),
            "beta_sigma" => collect(last_fit.beta_sigma),
        )
    elseif cell.model == :bivariate
        d = build_bivariate_designs(df, cell.cell_id)

        # warm-up
        _ = fit_bivariate(d.y1, d.y2, d.X_mu1, d.X_mu2, d.X_sigma1, d.X_sigma2, d.X_rho12)

        times = Float64[]
        local last_fit
        for _ in 1:5
            t = @elapsed last_fit = fit_bivariate(
                d.y1, d.y2, d.X_mu1, d.X_mu2, d.X_sigma1, d.X_sigma2, d.X_rho12,
            )
            push!(times, t)
        end

        return Dict(
            "cell_id" => cell.cell_id,
            "engine" => "julia_poc",
            "time_s" => mean(times),
            "time_s_med" => median(times),
            "logLik" => last_fit.logLik,
            "converged" => last_fit.converged,
            "n_iter" => last_fit.iterations,
            "beta_mu1" => collect(last_fit.beta_mu1),
            "beta_mu2" => collect(last_fit.beta_mu2),
            "beta_sigma1" => collect(last_fit.beta_sigma1),
            "beta_sigma2" => collect(last_fit.beta_sigma2),
            "beta_rho12" => collect(last_fit.beta_rho12),
        )
    elseif cell.model == :phylo_uni
        sigma_phy_path = joinpath(fixtures_dir, cell.cell_id * "_sigma_phy.csv")
        if !isfile(sigma_phy_path)
            error("Sigma_phy fixture not found: $sigma_phy_path")
        end
        Sigma_phy = read_sigma_phy(sigma_phy_path)
        if size(Sigma_phy, 1) != nrow(df)
            error("Sigma_phy size $(size(Sigma_phy,1)) does not match df rows $(nrow(df))")
        end

        d = build_phylo_uni_designs(df)

        # Soft timeout: for phylo_p1000, if any single fit takes > 300s,
        # record NaN/false for that cell rather than blocking the whole run.
        soft_timeout = cell.cell_id == "phylo_p1000" ? 300.0 : Inf

        function timed_fit()
            t = @elapsed res = fit_phylo_uni(d.y, d.X_mu, Sigma_phy)
            return t, res
        end

        # warm-up (also gated by the timeout, so a runaway p1000 warm-up
        # doesn't hang the driver before any timed runs)
        local last_fit
        try
            t0, warm = timed_fit()
            if t0 > soft_timeout
                @warn "phylo warm-up exceeded soft timeout ($(round(t0;digits=1))s > $soft_timeout s) for $(cell.cell_id)"
                return Dict(
                    "cell_id" => cell.cell_id,
                    "engine" => "julia_poc",
                    "time_s" => NaN,
                    "time_s_med" => NaN,
                    "logLik" => NaN,
                    "converged" => false,
                    "n_iter" => 0,
                    "beta_mu" => Float64[],
                    "sigma_phy" => NaN,
                    "sigma_eps" => NaN,
                )
            end
            last_fit = warm
        catch err
            @warn "phylo warm-up failed for $(cell.cell_id): $err"
            return Dict(
                "cell_id" => cell.cell_id,
                "engine" => "julia_poc",
                "time_s" => NaN,
                "time_s_med" => NaN,
                "logLik" => NaN,
                "converged" => false,
                "n_iter" => 0,
                "beta_mu" => Float64[],
                "sigma_phy" => NaN,
                "sigma_eps" => NaN,
            )
        end

        times = Float64[]
        timed_out = false
        for _ in 1:3
            try
                t, res = timed_fit()
                if t > soft_timeout
                    @warn "phylo timed fit exceeded soft timeout ($(round(t;digits=1))s) for $(cell.cell_id)"
                    timed_out = true
                    break
                end
                push!(times, t)
                last_fit = res
            catch err
                @warn "phylo timed fit failed for $(cell.cell_id): $err"
                timed_out = true
                break
            end
        end

        if timed_out || isempty(times)
            return Dict(
                "cell_id" => cell.cell_id,
                "engine" => "julia_poc",
                "time_s" => NaN,
                "time_s_med" => NaN,
                "logLik" => NaN,
                "converged" => false,
                "n_iter" => 0,
                "beta_mu" => Float64[],
                "sigma_phy" => NaN,
                "sigma_eps" => NaN,
            )
        end

        return Dict(
            "cell_id" => cell.cell_id,
            "engine" => "julia_poc",
            "time_s" => mean(times),
            "time_s_med" => median(times),
            "logLik" => last_fit.logLik,
            "converged" => last_fit.converged,
            "n_iter" => last_fit.iterations,
            "beta_mu" => collect(last_fit.beta_mu),
            "sigma_phy" => last_fit.sigma_phy,
            "sigma_eps" => last_fit.sigma_eps,
        )
    else
        error("unknown cell model: $(cell.model)")
    end
end

# -----------------------------------------------------------------------------
# Main driver
# -----------------------------------------------------------------------------

function main()
    script_dir = @__DIR__
    fixtures_dir = normpath(joinpath(script_dir, "..", "fixtures"))
    results_dir = normpath(joinpath(script_dir, "..", "results"))
    mkpath(results_dir)

    results = Dict[]
    skipped = String[]

    for cell in CELLS
        println("Cell: $(cell.cell_id) (n=$(cell.n), $(cell.model))")
        try
            res = run_cell(cell, fixtures_dir)
            push!(results, res)
            println("  done: median=$(round(res["time_s_med"]; digits=4))s, " *
                    "logLik=$(round(res["logLik"]; digits=3)), " *
                    "converged=$(res["converged"])")
        catch err
            @warn "Skipping $(cell.cell_id): $err"
            push!(skipped, cell.cell_id)
        end
    end

    out_path = joinpath(results_dir, "julia_results.json")
    open(out_path, "w") do io
        JSON3.write(io, results)
    end
    println("\nWrote $(length(results)) cells to $out_path")
    if !isempty(skipped)
        println("Skipped (missing fixture): " * join(skipped, ", "))
    end

    # human-readable per-cell median wall-clock
    println("\nPer-cell median wall-clock (s):")
    for r in results
        println("  $(rpad(r["cell_id"], 12)) $(round(r["time_s_med"]; digits=4))s")
    end
end

main()
