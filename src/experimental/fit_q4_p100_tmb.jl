# fit_q4_p100_tmb.jl — clean q4_p100 driver via the TMB-style EXACT-gradient
# LBFGS (verified gradient, Check C = 6.5e-9). Bypasses the run_tmbgrad harness
# (which had a trace() monitoring bug). Robust init guard: if the marginal at
# theta0 is non-finite, fall back to a safe init.
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. fit_q4_p100_tmb.jl

using LinearAlgebra, Statistics, Printf, CSV, DataFrames
include(joinpath(@__DIR__, "fit_q4_tmbgrad.jl"))   # pulls fit_q4_julia.jl too

const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))
const DRMTMB_LOGLIK = -513.99
const DRMTMB_TIME_S = 2.585

# --- load q4_p100 fixture (Σ_phy and data both in tip.label order → identity map)
df = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame)
p = nrow(df); n = p
Σ_phy = Matrix{Float64}(CSV.read(joinpath(FIX, "q4_p100_sigma_phy.csv"), DataFrame))
Σ_phy = (Σ_phy + Σ_phy') / 2
@assert size(Σ_phy) == (p, p)
species_idx = collect(1:p)

y1 = Vector{Float64}(df.y1); y2 = Vector{Float64}(df.y2)
x1 = Vector{Float64}(df.x1)
X_mu1 = hcat(ones(n), x1); X_mu2 = hcat(ones(n), x1)
X_s1 = reshape(ones(n), n, 1); X_s2 = reshape(ones(n), n, 1); X_rho = reshape(ones(n), n, 1)

println("=== TMB-exact-gradient LBFGS, real q4_p100 (p=$p) ===")

# robust init guard
Σ_inv = inv(Σ_phy); ldΣ = logdet(Symmetric(Σ_phy))
θ0 = build_initial_theta(y1, y2, X_mu1, X_mu2, X_s1, X_s2, X_rho)
nll0, _ = marginal_and_exact_grad(θ0, y1, y2, X_mu1, X_mu2, X_s1, X_s2, X_rho, Σ_inv, ldΣ, species_idx; n_inner=30)
if !isfinite(nll0)
    @warn "marginal(θ0) non-finite; using robust fallback init" nll0
    θ0[8:11] .= log(0.3); θ0[12:17] .= 0.0   # log_sd_phy, chol_offdiag
end
@printf "init marginal nll = %.4f\n" nll0

# warm-up (compile) + timed fits
fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_s1, X_s2, X_rho, Σ_phy, species_idx;
                 g_tol=1e-3, iterations=200, n_inner=30, show_trace=false)
t1 = @elapsed r1 = fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_s1, X_s2, X_rho, Σ_phy, species_idx;
                                    g_tol=1e-3, iterations=200, n_inner=30, show_trace=false)
t2 = @elapsed r2 = fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_s1, X_s2, X_rho, Σ_phy, species_idx;
                                    g_tol=1e-3, iterations=200, n_inner=30, show_trace=false)
tmed = (t1 + t2) / 2

upk = unpack_theta(r1.theta, X_mu1, X_mu2, X_s1, X_s2, X_rho)
println("\n--- q4_p100 result (TMB-exact-gradient) ---")
@printf "logLik (Julia):  %.4f\n" r1.logLik
@printf "logLik (drmTMB): %.4f   |Δ| = %.4f\n" DRMTMB_LOGLIK abs(r1.logLik - DRMTMB_LOGLIK)
@printf "converged: %s   iters: %d   g_resid: %.2e\n" r1.converged r1.iterations r1.g_residual
@printf "wall-clock Julia: %.4f s (median of 2)\n" tmed
@printf "wall-clock drmTMB: %.3f s   ->  speedup = %.2fx\n" DRMTMB_TIME_S (DRMTMB_TIME_S / tmed)
println("β_mu1=", round.(upk.beta_mu1; digits=3), " β_mu2=", round.(upk.beta_mu2; digits=3),
        " β_s1=", round.(upk.beta_sigma1; digits=3), " β_s2=", round.(upk.beta_sigma2; digits=3),
        " β_rho=", round.(upk.beta_rho12; digits=3))
println("sd_phy=", round.(upk.sd_phy; digits=3))
println("=== done ===")
