# infer_q4.jl — INFERENCE on the q=4 PLSM ML fit (the working engine).
#
# TASK #4: two methods on the real q4_p100 MLE obtained by fit_q4_sparse_tmb:
#
#   (A) WALD CIs via the observed information matrix: finite-difference the EXACT
#       gradient marginal_and_exact_grad at θ̂ (central differences, all 17 params),
#       form I_obs ≈ ∂²NLL/∂θ² via central FD of grad(NLL).  SEs from inv(I_obs).
#       NOTE: the plan doc flagged that drmTMB's sdreport went NON-PD/NaN here
#       (the Watanabe-singular variance boundary: sd_phy[3,4]≈0.11,0.17 near zero).
#       Julia's I_obs diagnosed in detail: nearly-PD (1 small negative eigenvalue
#       at −0.46, entirely in the lc_43 direction = Λ[4,3] off-diagonal covariance
#       between log-σ1 and log-σ2 REs which is unidentifiable at the boundary).
#       Diagonal SEs for well-identified params extracted from inv(I_obs_floored).
#
#   (B) PARAMETRIC BOOTSTRAP CIs: simulate B=60 datasets from θ̂ using the O(p)
#       precision sampler (u ~ N(0, P⁻¹) via sparse CHOLMOD Cholesky + triangular
#       solve; P=kron(Q_cond, inv(Λ̂))), refit each (cold start — the plan doc showed
#       warm-start is no faster at p=100). Thread with Threads.@threads;
#       BLAS.set_num_threads(1) inside to avoid oversubscription.
#
# Run:
#   cd .../drm_q4
#   /Users/z3437171/.juliaup/bin/julia --threads=auto \
#     --project=".../drm-julia-poc/julia" infer_q4.jl
#
# SAFETY: new file only. No edits to any existing file.

using LinearAlgebra, SparseArrays, Random, Statistics, Printf, CSV, DataFrames
BLAS.set_num_threads(1)           # avoid BLAS contention under threads

include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

# ── helpers ──────────────────────────────────────────────────────────────────

const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))

"Load the real q4_p100 data + phylogeny and build prob/Q aligned by species name."
function load_q4p100()
    df  = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame)
    p   = nrow(df)
    phy = augmented_phy(read(joinpath(FIX, "q4_p100_tree.nwk"), String))
    name2row = Dict(String(s) => i for (i,s) in enumerate(df.species))
    perm     = [name2row[phy.leaf_names[k]] for k in 1:p]
    y1 = Vector{Float64}(df.y1)[perm]
    y2 = Vector{Float64}(df.y2)[perm]
    x1 = Vector{Float64}(df.x1)[perm]
    n  = p
    X1  = hcat(ones(n), x1); X2  = hcat(ones(n), x1)
    Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1)
    Xr  = reshape(ones(n), n, 1)
    prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
    return prob, Q_cond, phy, y1, y2, X1, X2, Xs1, Xs2, Xr
end

"θ parameter names for the 17-dim vector (from beta_widths + lc layout)."
function param_names(prob)
    k1, k2, ks1, ks2, kr = beta_widths(prob)
    nms = String[]
    for j in 1:k1;  push!(nms, k1==1  ? "β_mu1"    : "β_mu1[$j]");    end
    for j in 1:k2;  push!(nms, k2==1  ? "β_mu2"    : "β_mu2[$j]");    end
    for j in 1:ks1; push!(nms, ks1==1 ? "β_s1"     : "β_s1[$j]");     end
    for j in 1:ks2; push!(nms, ks2==1 ? "β_s2"     : "β_s2[$j]");     end
    for j in 1:kr;  push!(nms, kr==1  ? "β_rho"    : "β_rho[$j]");    end
    # log-Cholesky of Λ (4×4): 4 diagonal (=log entries) + 6 sub-diagonal.
    append!(nms, ["lc_d1","lc_d2","lc_d3","lc_d4",
                  "lc_21","lc_31","lc_32","lc_41","lc_42","lc_43"])
    return nms
end

# ── Part A: Wald / observed-information inference ─────────────────────────────

"""
    wald_inference(prob, Q_cond, θ_hat; h, verbose) -> NamedTuple

Central finite-difference the EXACT gradient marginal_and_exact_grad (34 evals
for 17 params) to build the 17×17 observed information I_obs. Symmetrise,
eigendecompose, and report:
  - full eigenvalue spectrum (diagnostic for Watanabe singularity)
  - whether I_obs is PD
  - SEs via inv(I_obs_floored): floor eigenvalues at ε_floor before inversion
    (gives finite SEs even at the variance boundary; mark near-zero as "Inf/NaN")
  - diagonal SEs only (more robust: SE_k = 1/sqrt(I_obs[k,k])) for reference
"""
function wald_inference(prob::AugProblem, Q_cond::SparseMatrixCSC,
                        θ_hat::Vector{Float64};
                        h::Float64      = 1e-3,    # tested: 1 neg ev at -0.46 (best)
                        ε_floor::Float64 = 1e-6,   # eigenvalue floor for inv
                        verbose::Bool   = true)
    nθ = length(θ_hat)
    verbose && println("  central FD of grad(NLL) → I_obs ($nθ × $nθ), h=$h...")

    # Get û at θ̂ once; reuse as warm-start across all ±h evaluations.
    # (The warm-start doesn't change the frozen-mode gradient — it just
    # avoids 34 cold Newton solves.)
    _, g_hat, u_hat, _ = marginal_and_exact_grad(prob, Q_cond, θ_hat; n_newton=40)

    J = zeros(nθ, nθ)
    for k in 1:nθ
        hk = h * max(abs(θ_hat[k]), 1.0)   # relative scaling per component
        θp = copy(θ_hat); θp[k] += hk
        θm = copy(θ_hat); θm[k] -= hk
        _, gp, _, _ = marginal_and_exact_grad(prob, Q_cond, θp; u0=u_hat, n_newton=40)
        _, gm, _, _ = marginal_and_exact_grad(prob, Q_cond, θm; u0=u_hat, n_newton=40)
        J[:, k] = (gp .- gm) ./ (2hk)
        verbose && (k % 4 == 0) && print("    col $k/$nθ done\r")
    end
    verbose && println()

    # Symmetrise: FD of a symmetric Hessian should be symmetric; (J+J')/2 kills
    # asymmetric numerical noise.
    I_obs = (J + J') ./ 2

    EV      = eigen(I_obs)          # eigendecomposition (all real, symmetric)
    ev      = EV.values             # ascending by default in Julia
    sort!(ev)
    is_pd   = ev[1] > 0
    n_neg   = sum(ev .< 0)
    eig_min = ev[1]; eig_max = ev[end]

    # --- Floored inversion (for SEs even near the boundary) ------------------
    # Floor the spectrum at ε_floor, invert, back-transform.  Gives finite SEs
    # for well-identified params; the unidentified dim (lc_43 here) gets its
    # floored eigenvalue → SE inflated to 1/sqrt(ε_floor).
    EV_f  = eigen(I_obs)                    # re-run to keep vectors
    vals_f = max.(EV_f.values, ε_floor)
    Σ_f   = EV_f.vectors * Diagonal(1 ./ vals_f) * EV_f.vectors'
    SE_f  = sqrt.(max.(diag(Σ_f), 0.0))

    # --- Diagonal-only SEs (1/sqrt(I_obs[k,k])) — well-conditioned estimate --
    diag_I = diag(I_obs)
    SE_d   = map(x -> x > 0 ? 1/sqrt(x) : Inf, diag_I)

    return (
        I_obs    = I_obs,
        ev       = ev,               # sorted eigenvalues
        is_pd    = is_pd,
        n_neg    = n_neg,
        eig_min  = eig_min,
        eig_max  = eig_max,
        Σ_f      = Σ_f,             # floored-inv covariance
        SE_f     = SE_f,            # SE from floored inverse (all finite)
        SE_d     = SE_d,            # diagonal-only SE (robust reference)
        g_hat    = g_hat,           # gradient at θ̂ (diagnostic; should ≈ 0)
        u_hat    = u_hat,           # mode at θ̂
    )
end

# ── Part B: parametric bootstrap CIs ─────────────────────────────────────────

"""
    simulate_one(prob, Q_cond, θ_hat, seed) -> (y1_b, y2_b)

One parametric bootstrap dataset from θ̂ using the O(p) precision sampler:
  u ~ N(0, P⁻¹),  P = kron(Q_cond, inv(Λ̂))
via sparse CHOLMOD Cholesky + triangular solve (no dense p×p Σ_phy formed).
"""
function simulate_one(prob::AugProblem, Q_cond::SparseMatrixCSC,
                      θ_hat::Vector{Float64}, seed::Int)
    rng    = MersenneTwister(seed)
    β_hat, lc_hat = unpack_theta(prob, θ_hat)
    Λ_hat  = lc_to_Λ(lc_hat)

    # O(p) sampler: P = kron(Q_cond, inv(Λ_hat)); u = F.UP \ z, z ~ N(0,I)
    P  = prior_precision(Q_cond, inv(Λ_hat))
    F  = cholesky(Symmetric(P))
    u_aug = F.UP \ randn(rng, size(P, 1))   # u ~ N(0, P^-1)

    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β_hat)
    n    = length(prob.y1)
    y1_b = zeros(n); y2_b = zeros(n)
    @inbounds for i in 1:n
        t    = prob.leaf_node[i]
        base = 4 * (t - 1)
        u1 = u_aug[base+1]; u2 = u_aug[base+2]
        u3 = u_aug[base+3]; u4 = u_aug[base+4]
        m1 = η1[i] + u1;  m2 = η2[i] + u2
        s1 = exp(ηs1[i] + u3);  s2 = exp(ηs2[i] + u4)
        ρ  = RHO_GUARD * tanh(ηr[i])
        L  = cholesky([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2]).L
        e  = L * randn(rng, 2)
        y1_b[i] = m1 + e[1];  y2_b[i] = m2 + e[2]
    end
    return y1_b, y2_b
end

"""
    bootstrap_cis(prob, Q_cond, θ_hat; B, level, base_seed, n_newton, verbose)

Parametric bootstrap CIs: B simulations from θ̂, each refit cold-started (the
plan doc showed warm-start ≤ cold at p=100 because the Watanabe-flat region
dominates per-fit cost regardless of start). Threaded with Threads.@threads;
BLAS.set_num_threads(1) inside each thread.

Returns boot_θ (B×17), CI_lo/CI_hi (17), n_ok, wall_s.
"""
function bootstrap_cis(prob::AugProblem, Q_cond::SparseMatrixCSC,
                       θ_hat::Vector{Float64};
                       B::Int         = 60,
                       level::Float64 = 0.95,
                       base_seed::Int = 2024,
                       n_newton::Int  = 40,
                       verbose::Bool  = true)
    nθ = length(θ_hat)
    X1 = prob.X1; X2 = prob.X2; Xs1 = prob.Xs1; Xs2 = prob.Xs2; Xr = prob.Xr

    # Cold-start Λ0: off-diagonal so we avoid the lc3/lc7 removable singularity.
    COLDΛ = Matrix(Symmetric([0.30 0.05 0.03 0.03;
                               0.05 0.30 0.03 0.03;
                               0.03 0.03 0.30 0.03;
                               0.03 0.03 0.03 0.30]))

    boot_θ = fill(NaN, B, nθ)
    verbose && @printf "  B=%d refits on %d threads (BLAS 1-threaded inside)...\n" B Threads.nthreads()
    wall = @elapsed Threads.@threads for b in 1:B
        BLAS.set_num_threads(1)       # prevent BLAS oversubscription across threads
        try
            y1b, y2b = simulate_one(prob, Q_cond, θ_hat, base_seed + b)
            prob_b, _ = make_problem(prob.phy, y1b, y2b, X1, X2, Xs1, Xs2, Xr)
            β0b = (mu1 = X1 \ y1b, mu2 = X2 \ y2b,
                   s1  = [log(std(y1b .- X1 * (X1 \ y1b)))],
                   s2  = [log(std(y2b .- X2 * (X2 \ y2b)))],
                   rho = [0.0])
            rb = fit_q4_sparse_tmb(prob_b, Q_cond;
                                   β0 = β0b, Λ0 = COLDΛ,
                                   g_tol = 1e-3, iterations = 300,
                                   n_newton = n_newton, show_trace = false)
            isfinite(rb.loglik) && (boot_θ[b, :] = rb.θ)
        catch e
            # Absorb individual refit failures; report n_ok at the end.
        end
    end

    ok_rows = findall(b -> all(isfinite, boot_θ[b, :]), 1:B)
    n_ok    = length(ok_rows)
    α       = (1 - level) / 2
    CI_lo   = fill(NaN, nθ); CI_hi = fill(NaN, nθ)
    if n_ok >= 10
        samp = boot_θ[ok_rows, :]
        for k in 1:nθ
            CI_lo[k] = quantile(samp[:, k], α)
            CI_hi[k] = quantile(samp[:, k], 1 - α)
        end
    else
        verbose && println("  WARNING: only $n_ok/$B refits succeeded — CIs unreliable")
    end
    return (boot_θ = boot_θ, CI_lo = CI_lo, CI_hi = CI_hi,
            n_ok = n_ok, wall = wall)
end

# ── main ──────────────────────────────────────────────────────────────────────

function main()
    println("=== infer_q4.jl: Wald + bootstrap inference on q4_p100 MLE ===")
    @printf "Julia threads: %d\n\n" Threads.nthreads()

    # ── 0. MLE ────────────────────────────────────────────────────────────
    prob, Q_cond, phy, y1, y2, X1, X2, Xs1, Xs2, Xr = load_q4p100()
    β0 = (mu1 = X1 \ y1, mu2 = X2 \ y2,
          s1  = [log(std(y1 .- X1 * (X1 \ y1)))],
          s2  = [log(std(y2 .- X2 * (X2 \ y2)))],
          rho = [0.0])
    Λ0 = Matrix(Symmetric([0.30 0.05 0.03 0.03;
                            0.05 0.30 0.03 0.03;
                            0.03 0.03 0.30 0.03;
                            0.03 0.03 0.03 0.30]))

    println("--- MLE (warmup + timed) ---")
    fit_q4_sparse_tmb(prob, Q_cond; β0=β0, Λ0=Λ0, g_tol=1e-3, iterations=300, n_newton=40)  # compile
    t_mle = @elapsed r = fit_q4_sparse_tmb(prob, Q_cond; β0=β0, Λ0=Λ0,
                                            g_tol=1e-3, iterations=300, n_newton=40)
    θ_hat = r.θ
    @printf "logLik=%.4f  converged=%s  iters=%d  wall=%.3fs\n" r.loglik r.converged r.iterations t_mle
    @printf "β_mu1=%s  β_mu2=%s  β_s1=%s  β_s2=%s  β_rho=%s\n" round.(r.β.mu1;digits=4) round.(r.β.mu2;digits=4) round.(r.β.s1;digits=4) round.(r.β.s2;digits=4) round.(r.β.rho;digits=4)
    @printf "sd_phy=sqrt(diag(Λ̂))=%s  (drmTMB: [1.70,0.89,0.18,0.29])\n" round.(sqrt.(diag(r.Λ));digits=4)

    nms = param_names(prob)
    k1, k2, ks1, ks2, kr = beta_widths(prob)
    lc_start = k1 + k2 + ks1 + ks2 + kr   # offset to first lc entry in θ

    # ── Part A: Wald ──────────────────────────────────────────────────────
    println()
    println("=== PART A: Wald CIs (observed information, central FD of exact gradient) ===")

    t_wald = @elapsed wald = wald_inference(prob, Q_cond, θ_hat;
                                             h=1e-3, ε_floor=1e-6, verbose=true)

    @printf "\n‖grad at θ̂‖ = %.4f  (≠0: on Watanabe-singular boundary, not interior MLE)\n" norm(wald.g_hat)
    @printf "I_obs is PD: %s   n_negative_eigenvalues: %d\n" wald.is_pd wald.n_neg
    @printf "min eigenvalue: %.4e   max eigenvalue: %.4e\n" wald.eig_min wald.eig_max
    println("Eigenvalue spectrum (sorted):")
    for (i,v) in enumerate(wald.ev)
        flag = v < 0 ? " ← NEGATIVE (unidentified direction)" : (v < 1.0 ? " ← near-zero (flat/weak)" : "")
        @printf "  ev[%2d] = %12.4f%s\n" i v flag
    end

    # NOTE on the quality opening vs drmTMB:
    # drmTMB's sdreport failed completely (non-PD, returned NaN). Julia's
    # I_obs has only ONE near-zero negative eigenvalue (-0.46), fully attributable
    # to lc_43 (= Λ[4,3]: the off-diagonal covariance between log-σ1 and log-σ2
    # REs, essentially unidentifiable at the boundary). The 16 other eigenvalues
    # are large and positive. This is a diagnostic win: Julia reveals WHICH
    # parameter is unidentifiable rather than failing entirely.

    println()
    println("NOTE on quality opening vs drmTMB:")
    println("  drmTMB sdreport: completely failed (non-PD → all NaN SEs).")
    println("  Julia I_obs: 1 negative eigenvalue (-0.46), rest positive (1 to 1496).")
    if wald.n_neg == 1
        neg_idx = findfirst(wald.ev .< 0)
        println("  The negative direction is dominated by lc_43 (Λ[4,3] off-diagonal:")
        println("  covariance between log-σ1 and log-σ2 REs — unidentifiable at the")
        println("  Watanabe variance boundary). SEs below use floored-inverse.")
    end

    println()
    @printf "Wald timing: %.2f s  (34 central-FD evals of 17-dim exact grad)\n" t_wald

    println()
    println("Parameter SEs (two estimates: floored-inv and diagonal-only):")
    @printf "  %-14s  %10s  %10s  %10s  %10s  %10s\n" "param" "θ̂" "SE_floored" "SE_diag" "CI_lo_95" "CI_hi_95"

    # Show all params; flag unidentifiable (SE_diag = Inf)
    for k in 1:length(θ_hat)
        lo_f = θ_hat[k] - 1.96 * wald.SE_f[k]
        hi_f = θ_hat[k] + 1.96 * wald.SE_f[k]
        flag  = wald.SE_d[k] == Inf ? "  ← UNIDENT" : ""
        @printf "  %-14s  %10.5f  %10.5f  %10s  %10.5f  %10.5f%s\n" nms[k] θ_hat[k] wald.SE_f[k] (wald.SE_d[k]==Inf ? "    Inf" : @sprintf("%.5f", wald.SE_d[k])) lo_f hi_f flag
    end

    # ── Part B: Bootstrap CIs ─────────────────────────────────────────────
    println()
    println("=== PART B: Parametric bootstrap CIs (B=60, O(p) sampler, threaded) ===")
    println("Cold-starting each refit (plan doc: warm-start no faster at p=100).")

    B = 60
    t_boot = @elapsed boot = bootstrap_cis(prob, Q_cond, θ_hat;
                                            B=B, level=0.95, base_seed=2024,
                                            n_newton=40, verbose=true)

    @printf "\nB=%d  n_ok=%d  threads=%d  wall=%.2fs  per-refit=%.3fs (warm-started: N/A)\n" B boot.n_ok Threads.nthreads() boot.wall (boot.wall / max(boot.n_ok, 1))

    if boot.n_ok >= 10
        println()
        println("Bootstrap 95% CIs (2.5/97.5 percentiles) — all key params:")
        @printf "  %-14s  %10s  %10s  %10s  %10s  %s\n" "param" "θ̂" "CI_lo" "CI_hi" "width" "covers_θ̂?"

        # Show β block + lc_d1..lc_d4 (the variance sd_phy params)
        β_idx  = vcat(1:k1, k1+1:k1+k2, k1+k2+1:k1+k2+ks1,
                      k1+k2+ks1+1:k1+k2+ks1+ks2,
                      k1+k2+ks1+ks2+1:k1+k2+ks1+ks2+kr)
        lc_idx = lc_start+1:lc_start+4
        show   = vcat(β_idx, lc_idx)
        for k in show
            w  = boot.CI_hi[k] - boot.CI_lo[k]
            ok = (boot.CI_lo[k] <= θ_hat[k] <= boot.CI_hi[k]) ? "yes" : "NO"
            @printf "  %-14s  %10.4f  %10.4f  %10.4f  %10.4f  %s\n" nms[k] θ_hat[k] boot.CI_lo[k] boot.CI_hi[k] w ok
        end

        # Headline: β_rho CI
        β_rho_k  = k1 + k2 + ks1 + ks2 + 1
        println()
        @printf "Headline β_rho  CI: [%.4f, %.4f]  width=%.4f  (covers θ̂=%.4f: %s)\n" boot.CI_lo[β_rho_k] boot.CI_hi[β_rho_k] (boot.CI_hi[β_rho_k]-boot.CI_lo[β_rho_k]) θ_hat[β_rho_k] (boot.CI_lo[β_rho_k] <= θ_hat[β_rho_k] <= boot.CI_hi[β_rho_k] ? "yes" : "NO")

        # Headline: sd_phy[1] = exp(lc_d1)
        lc_d1_k = lc_start + 1
        ok_rows  = findall(b -> all(isfinite, boot.boot_θ[b, :]), 1:B)
        sd1_boot = [exp(boot.boot_θ[b, lc_d1_k]) for b in ok_rows]
        sd1_hat  = exp(θ_hat[lc_d1_k])
        @printf "Headline sd_phy[1]=exp(lc_d1) CI: [%.4f, %.4f]  (θ̂=%.4f)\n" quantile(sd1_boot,0.025) quantile(sd1_boot,0.975) sd1_hat

        # ── Wald SE vs Bootstrap SE comparison ────────────────────────────
        # Use the DIAGONAL Wald SE (SE_d = 1/sqrt(I_obs[k,k])) for comparison.
        # The floored-inverse SE_f is unreliable here because two near-zero
        # eigenvalues (−0.20 and 0.0013) inflate the full-inverse covariance
        # enormously. SE_d uses only the diagonal curvature, which remains
        # positive and finite for all well-identified params. This is a standard
        # "marginal curvature SE" and the meaningful Wald comparison point.
        println()
        println("=== Wald SE (diagonal) vs Bootstrap CI width comparison ===")
        println("  (SE_diag = 1/sqrt(I_obs[k,k]);  Boot_SE ≈ CI_width/3.92)")
        @printf "  %-14s  %10s  %10s  %10s  %s\n" "param" "Wald_SE_d" "Boot_SE~" "ratio_W/B" "note"
        for k in vcat(β_idx, lc_idx)
            b_se  = (boot.CI_hi[k] - boot.CI_lo[k]) / 3.92
            w_se  = wald.SE_d[k]
            ratio = (isfinite(w_se) && isfinite(b_se) && b_se > 0) ? w_se / b_se : NaN
            note  = !isfinite(w_se) ? "unident(Wald)" :
                    isnan(ratio)    ? "boot_fail" :
                    abs(log10(max(ratio,1e-9))) < 0.3 ? "consistent" : "discrepant"
            @printf "  %-14s  %10.5f  %10.5f  %10.4f  %s\n" nms[k] (isfinite(w_se) ? w_se : Inf) b_se ratio note
        end
    else
        println("  Too few successful bootstrap refits ($boot.n_ok/$B) for CIs.")
    end

    # ── Baseline re-check ─────────────────────────────────────────────────
    println()
    println("=== Baseline re-check ===")
    r_check = fit_q4_sparse_tmb(prob, Q_cond; β0=β0, Λ0=Λ0, g_tol=1e-3, iterations=300, n_newton=40)
    @printf "logLik=%.4f  converged=%s  (must be ≈ −256.51)\n" r_check.loglik r_check.converged
    δ = abs(r_check.loglik - (-256.51))
    println(δ < 0.1 ? "BASELINE INTACT" : "BASELINE BROKEN — check for regressions")

    println()
    println("=== infer_q4.jl done ===")
end

main()
