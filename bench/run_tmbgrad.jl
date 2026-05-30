# run_tmbgrad.jl — fit driver + benchmark for the EXACT Laplace-marginal
# gradient (cheap frozen-mode gradient + implicit dû/dθ correction) wired into
# Optim only_fg! + LBFGS(BackTracking).
#
# Two parts:
#   (a) synthetic p=20 recovery: confirm MONOTONE descent of the true marginal
#       NLL, parameter recovery, and seconds-scale wall-clock.
#   (b) real q4_p100 fixture: align species by NAME (data row i ↔ Σ_phy row i ↔
#       df.species[i]); compare logLik to drmTMB's −513.99 (gate |Δ|<1e-2) and
#       wall-clock to drmTMB's 2.585 s.
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. run_tmbgrad.jl

using LinearAlgebra, Random, Statistics, Printf
using CSV, DataFrames

include(joinpath(@__DIR__, "fit_q4_tmbgrad.jl"))   # also pulls fit_q4_julia.jl

const DRMTMB_LOGLIK = -513.99
const DRMTMB_TIME_S = 2.585

# ---------------------------------------------------------------------------
# Pull the per-iteration objective values from an Optim result trace and check
# the sequence is (weakly) monotone non-increasing.
# ---------------------------------------------------------------------------
function trace_objective_values(res)
    tr = Optim.trace(res)
    return [s.value for s in tr]
end

function check_monotone(vals; atol = 1e-6)
    ok = true
    worst = 0.0
    for k in 2:length(vals)
        inc = vals[k] - vals[k-1]
        worst = max(worst, inc)
        if inc > atol
            ok = false
        end
    end
    return ok, worst
end

# ===========================================================================
# (a) Synthetic p=20 recovery
# ===========================================================================
function run_p20()
    println("=" ^ 70)
    println("(a) EXACT-gradient LBFGS — synthetic p=20 recovery")
    println("=" ^ 70)

    Random.seed!(2026)
    p = 20
    n = p

    beta_mu1_true = [1.0, 0.5];  beta_mu2_true = [-0.3, 0.4]
    beta_sigma1_true = [-0.5];   beta_sigma2_true = [-0.5];  beta_rho12_true = [0.3]
    Lambda_phy_true = Float64[0.25 0.10 0.05 0.0;
                              0.10 0.25 0.0  0.04;
                              0.05 0.0  0.09 0.02;
                              0.0  0.04 0.02 0.09]
    Lambda_phy_true = (Lambda_phy_true + Lambda_phy_true') / 2
    @assert isposdef(Lambda_phy_true)

    A = randn(p, p)
    Sigma_phy = A'A / p + 0.5 * I + 0.5 .* (ones(p) * ones(p)') ./ p
    Sigma_phy = (Sigma_phy + Sigma_phy') / 2
    @assert isposdef(Sigma_phy)

    L_Lambda = cholesky(Lambda_phy_true).L
    L_Sigma  = cholesky(Symmetric(Sigma_phy)).L
    U_true = L_Lambda * randn(4, p) * L_Sigma'

    x1 = randn(n)
    X_mu1 = hcat(ones(n), x1);  X_mu2 = hcat(ones(n), x1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)
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

    # warm-up (compile) — short
    fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                     Sigma_phy, species_idx; g_tol = 1e-3, iterations = 3,
                     n_inner = 20, show_trace = false)

    t = @elapsed res = fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                        X_rho12, Sigma_phy, species_idx;
                                        g_tol = 1e-3, iterations = 200,
                                        n_inner = 20, show_trace = true)

    vals = trace_objective_values(res)
    mono_ok, worst = check_monotone(vals)

    println("\n--- p=20 result ---")
    @printf "wall-clock: %.3f s   iters: %d   converged: %s\n" t res.iterations res.converged
    @printf "logLik: %.4f   final nll: %.4f   g_residual: %.3e\n" res.logLik res.nll res.g_residual
    @printf "MONOTONE descent: %s   (worst step-to-step increase: %.3e)\n" mono_ok worst

    upk = unpack_theta(res.theta, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    println("\nRecovered vs truth:")
    @printf "  beta_mu1:    truth %s  ->  hat %s\n" round.(beta_mu1_true; digits=3) round.(upk.beta_mu1; digits=3)
    @printf "  beta_mu2:    truth %s  ->  hat %s\n" round.(beta_mu2_true; digits=3) round.(upk.beta_mu2; digits=3)
    @printf "  beta_sigma1: truth %s  ->  hat %s\n" round.(beta_sigma1_true; digits=3) round.(upk.beta_sigma1; digits=3)
    @printf "  beta_sigma2: truth %s  ->  hat %s\n" round.(beta_sigma2_true; digits=3) round.(upk.beta_sigma2; digits=3)
    @printf "  beta_rho12:  truth %s  ->  hat %s\n" round.(beta_rho12_true; digits=3) round.(upk.beta_rho12; digits=3)
    @printf "  sd_phy:      truth %s  ->  hat %s\n" round.(sqrt.(diag(Lambda_phy_true)); digits=3) round.(upk.sd_phy; digits=3)

    return (t = t, res = res, mono_ok = mono_ok, worst = worst)
end

# ===========================================================================
# (b) Real q4_p100 fixture
# ===========================================================================
function run_p100()
    println("\n" * "=" ^ 70)
    println("(b) EXACT-gradient LBFGS — real q4_p100 fixture")
    println("=" ^ 70)

    fixtures_dir = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
    fixture_csv  = joinpath(fixtures_dir, "q4_p100.csv")
    sigma_phy_csv = joinpath(fixtures_dir, "q4_p100_sigma_phy.csv")

    df = CSV.read(fixture_csv, DataFrame)
    M = Matrix{Float64}(CSV.read(sigma_phy_csv, DataFrame))
    p = size(M, 1)
    @assert size(M, 1) == size(M, 2) "Sigma_phy not square"
    Sigma_phy = (M + M') / 2
    @assert isposdef(Sigma_phy) "Sigma_phy not PD"

    # Align species by NAME: data row i ↔ Σ_phy row i ↔ df.species[i].
    # The R side wrote Σ_phy = vcv(tree)[tip.label, tip.label] and species =
    # tip.label, so unique(df.species) gives the Σ_phy row/col ordering.
    @assert nrow(df) == p "Expected one row per species (n=$(nrow(df)), p=$p)"
    species_levels = unique(df.species)
    @assert length(species_levels) == p
    sp_to_idx = Dict(s => i for (i, s) in enumerate(species_levels))
    species_idx = [sp_to_idx[s] for s in df.species]

    n = nrow(df)
    X_mu1    = hcat(ones(n), df.x1)
    X_mu2    = hcat(ones(n), df.x1)
    X_sigma1 = reshape(ones(n), n, 1)
    X_sigma2 = reshape(ones(n), n, 1)
    X_rho12  = reshape(ones(n), n, 1)
    y1 = Vector{Float64}(df.y1)
    y2 = Vector{Float64}(df.y2)

    println("Read $fixture_csv ($n rows), Sigma_phy: $p x $p")

    # warm-up (compile) — short
    fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                     Sigma_phy, species_idx; g_tol = 1e-3, iterations = 3,
                     n_inner = 20, show_trace = false)

    # two timed fits (median, like fit_q4_julia.jl)
    t1 = @elapsed res1 = fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                          X_rho12, Sigma_phy, species_idx;
                                          g_tol = 1e-3, iterations = 200,
                                          n_inner = 20, show_trace = false)
    t2 = @elapsed res2 = fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                          X_rho12, Sigma_phy, species_idx;
                                          g_tol = 1e-3, iterations = 200,
                                          n_inner = 20, show_trace = false)
    time_med = median([t1, t2])
    res = res2

    upk = unpack_theta(res.theta, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)
    dLL = res.logLik - DRMTMB_LOGLIK

    println("\n--- q4_p100 result ---")
    @printf "wall-clock: t1=%.3f s  t2=%.3f s  median=%.3f s\n" t1 t2 time_med
    @printf "iters: %d   converged: %s   g_residual: %.3e\n" res.iterations res.converged res.g_residual
    @printf "logLik (Julia exact-grad): %.4f\n" res.logLik
    @printf "logLik (drmTMB target):    %.4f\n" DRMTMB_LOGLIK
    @printf "|Δ logLik| = %.4e   (gate < 1e-2: %s)\n" abs(dLL) (abs(dLL) < 1e-2)
    @printf "wall-clock vs drmTMB %.3f s: speedup = %.2fx\n" DRMTMB_TIME_S (DRMTMB_TIME_S / time_med)

    println("\nEstimates:")
    @printf "  beta_mu1     = %s\n" round.(upk.beta_mu1; digits=4)
    @printf "  beta_mu2     = %s\n" round.(upk.beta_mu2; digits=4)
    @printf "  beta_sigma1  = %s\n" round.(upk.beta_sigma1; digits=4)
    @printf "  beta_sigma2  = %s\n" round.(upk.beta_sigma2; digits=4)
    @printf "  beta_rho12   = %s\n" round.(upk.beta_rho12; digits=4)
    @printf "  sd_phy       = %s\n" round.(upk.sd_phy; digits=4)
    @printf "  cor_phy      = %s\n" round.(upk.cor_phy; digits=4)

    return (t1 = t1, t2 = t2, time_med = time_med, res = res, upk = upk, dLL = dLL)
end

# ===========================================================================
if abspath(PROGRAM_FILE) == @__FILE__
    r20 = run_p20()
    r100 = run_p100()
    println("\n" * "=" ^ 70)
    println("SUMMARY")
    println("=" ^ 70)
    @printf "p=20:    %.3f s, monotone=%s, logLik=%.4f, converged=%s\n" r20.t r20.mono_ok r20.res.logLik r20.res.converged
    @printf "q4_p100: %.3f s (median), logLik=%.4f, |Δ vs drmTMB|=%.3e, speedup=%.2fx\n" r100.time_med r100.res.logLik abs(r100.dLL) (DRMTMB_TIME_S / r100.time_med)
end
