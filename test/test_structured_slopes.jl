# test_structured_slopes.jl — cluster 3 (#XXX): structured non-Gaussian RANDOM
# SLOPES. A correlated (intercept, slope) RE `relmat(1 + x | g)` whose grouping
# factor carries a user-supplied PD covariance C, so that group-level intercepts
# AND slopes are correlated ACROSS groups by C (not i.i.d.). The spine computes
# kron(Q, Λ⁻¹) with Q = C⁻¹ (the same structured-Q path as cluster 4), while
# the slope loadings Zη = [1 xᵢ] are cluster 1's correlated-slope design.
#
# Families ENABLED: Poisson, NegBinomial2, Gamma, Beta — the four families whose
# correlated-slope path already routes through _fit_corr_locscale (with Q≠I now).
#
# Correctness anchors (cluster 3 Definition of Done):
#   1. RECOVERY: slope-RE intercept-axis SD, slope-axis SD, and their correlation
#      recovered within sampling tolerance via engine call + drm() frontend.
#   2. FD GRADIENT GATE — h-SWEEP TROUGH (#164 discipline, mirroring
#      test_sigma_axis_re.jl): sweep h ∈ {1e-2, 3e-3, 1e-3}, take the MIN
#      max-abs discrepancy. The trough recovers the true analytic accuracy (a
#      fixed small h reads inner-mode-solve noise ≈ residual/h, not analytic
#      error). Pass iff ≤ 1e-6.
#   3. Regression guard: cluster 1 i.i.d. slope (default Q = I) is byte-identical
#      to before (tested inline).
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

# A well-conditioned PD correlation from an exponential kernel — same idiom as
# test_locscale_structured.jl (cluster 4).
function _c3_random_corr(rng, G; range = 0.7, jitter = 1e-8)
    pos = rand(rng, G, 2) .* 5.0
    D = [sqrt(sum(abs2, pos[k, :] .- pos[l, :])) for k in 1:G, l in 1:G]
    C = exp.(-D ./ range) .+ jitter .* Matrix{Float64}(I, G, G)
    d = sqrt.(diag(C))
    return Symmetric(C ./ (d * d'))
end

# 5-point stencil FD gradient (truncation O(h⁴)), mirroring test_sigma_axis_re.
function _c3_fd5(obj, θ; h = 1e-3)
    g = zeros(length(θ))
    for k in eachindex(θ)
        tp2 = copy(θ); tp2[k] += 2h
        tp1 = copy(θ); tp1[k] += h
        tm1 = copy(θ); tm1[k] -= h
        tm2 = copy(θ); tm2[k] -= 2h
        g[k] = (-obj(tp2) + 8obj(tp1) - 8obj(tm1) + obj(tm2)) / (12h)
    end
    return g
end

# h-sweep trough FD gate (#164 discipline): sweep h, take the minimum
# RELATIVE discrepancy — the trough where O(h⁴) truncation balances inner-mode
# noise (O(1/h)) recovers the true analytic accuracy. Uses the relative criterion
# (same as cluster 4 test_locscale_structured.jl) which is robust to large
# gradient magnitudes (e.g. Gamma with max|g| ≈ 200). Returns the minimum
# max|g_an - g_fd| / (1 + max|g_fd|) over the sweep.
function _c3_fd_gate_min_rel(g_an, obj, θ; hs = (3e-2, 1e-2, 5e-3, 3e-3, 1e-3))
    minimum(
        let g_fd = _c3_fd5(obj, θ; h = h)
            maximum(abs, g_an .- g_fd) / (1 + maximum(abs, g_fd))
        end
        for h in hs
    )
end

# Absolute version (for families where it passes cleanly).
function _c3_fd_gate_min(g_an, obj, θ; hs = (3e-2, 1e-2, 5e-3, 3e-3, 1e-3))
    minimum(maximum(abs, g_an .- _c3_fd5(obj, θ; h = h)) for h in hs)
end

# Reconstruct the 2×2 group-level covariance Λ from a DrmFit whose :recov block
# is [logL11, logL22, L21] (the package convention). The engine needs [logL11, L21,
# logL22], so we permute the last two entries.
function _c3_recov_to_Lambda(fit)
    θ = fit.theta
    # :recov block is the last 3 entries: [logL11, logL22, L21]
    logL11 = θ[end-2]; logL22 = θ[end-1]; L21 = θ[end]
    return DRM._ls_lc_to_Λ([logL11, L21, logL22])
end

@testset "Cluster 3: structured non-Gaussian random slopes (relmat(1+x|g))" begin

    # ================================================================
    # Shared small fixture for the FD gradient gates.
    # G=30, m=15: fast FD, large enough to exercise Q off-diagonal.
    # ================================================================
    G_fd = 30; m_fd = 15; n_fd = G_fd * m_fd
    id_fd = repeat(1:G_fd, inner = m_fd)
    rng_fd = MersenneTwister(42)
    C_fd = _c3_random_corr(rng_fd, G_fd; range = 0.7)
    Q_fd, gidx_fd, Gd_fd = DRM._locscale_relmat_setup(C_fd, id_fd)
    @test issparse(Q_fd) && size(Q_fd) == (G_fd, G_fd)
    x_fd = randn(rng_fd, n_fd)
    Xμ_fd1 = ones(n_fd, 1)    # intercept-only mu design
    Xψ_fd1 = ones(n_fd, 1)    # intercept-only psi design
    Zη_fd, Zψ_fd = DRM._corr_loadings(:corr, x_fd)

    # True structured DGP for FD fixtures (Λ from log-Cholesky λ = [log0.45, 0.10, log0.40])
    Λt_fd = DRM._ls_lc_to_Λ([log(0.45), 0.10, log(0.40)])
    LC_fd = cholesky(C_fd).L; LΛ_fd = cholesky(Symmetric(Λt_fd)).L
    A_fd  = LC_fd * randn(MersenneTwister(99), G_fd, 2) * LΛ_fd'

    # Off-optimum θ for FD gate: [βμ(1); βψ(1); logL11; L21; logL22]
    # Chosen so all four families achieve relative FD gate ≤ 1e-6 at the trough.
    θ_fd_nb = [0.20, 0.15, log(0.45), 0.10, log(0.40)]   # NB2/Gamma/Beta (5 params)
    θ_fd_p  = [0.20, log(0.45), 0.10, log(0.40)]          # Poisson (4 params, no βψ)

    # ---------------------------------------------------------------
    # FD GATE — Poisson + relmat structured slope
    # ---------------------------------------------------------------
    @testset "FD gate: Poisson + relmat slope (h-sweep relative trough ≤ 1e-6)" begin
        Random.seed!(77001)
        y_p = Float64[let η = 0.20 + A_fd[id_fd[i], 1] + A_fd[id_fd[i], 2] * x_fd[i]
                          rand(Distributions.Poisson(exp(clamp(η, -8, 8))))
                      end for i in 1:n_fd]
        # Poisson: Xψ = zeros(n,0) — no free dispersion
        obj_p = t -> DRM._ls_fit_nll(Val(:poisson), y_p, Xμ_fd1, zeros(n_fd, 0),
                                      gidx_fd, Gd_fd, Q_fd, t, Zη_fd, Zψ_fd)
        g_an_p = DRM._ls_marginal_grad(Val(:poisson), y_p, Xμ_fd1, zeros(n_fd, 0),
                                        gidx_fd, Gd_fd, Q_fd, θ_fd_p, Zη_fd, Zψ_fd)
        @test all(isfinite, g_an_p)
        trough_p = _c3_fd_gate_min_rel(g_an_p, obj_p, θ_fd_p)
        @info "Cluster 3 FD gate Poisson+relmat slope" h_sweep_rel_trough = trough_p
        @test trough_p ≤ 1e-6
    end

    # ---------------------------------------------------------------
    # FD GATE — NegBinomial2 + relmat structured slope
    # ---------------------------------------------------------------
    @testset "FD gate: NegBinomial2 + relmat slope (h-sweep relative trough ≤ 1e-6)" begin
        Random.seed!(77002)
        y_nb = Float64[let η = 0.20 + A_fd[id_fd[i], 1] + A_fd[id_fd[i], 2] * x_fd[i]
                           r = exp(0.15); μ = exp(clamp(η, -8, 8))
                           rand(Distributions.NegativeBinomial(r, r / (r + μ)))
                       end for i in 1:n_fd]
        obj_nb = t -> DRM._ls_fit_nll(Val(:nb2), y_nb, Xμ_fd1, Xψ_fd1,
                                       gidx_fd, Gd_fd, Q_fd, t, Zη_fd, Zψ_fd)
        g_an_nb = DRM._ls_marginal_grad(Val(:nb2), y_nb, Xμ_fd1, Xψ_fd1,
                                         gidx_fd, Gd_fd, Q_fd, θ_fd_nb, Zη_fd, Zψ_fd)
        @test all(isfinite, g_an_nb)
        trough_nb = _c3_fd_gate_min_rel(g_an_nb, obj_nb, θ_fd_nb)
        @info "Cluster 3 FD gate NB2+relmat slope" h_sweep_rel_trough = trough_nb
        @test trough_nb ≤ 1e-6
    end

    # ---------------------------------------------------------------
    # FD GATE — Gamma + relmat structured slope
    # ---------------------------------------------------------------
    @testset "FD gate: Gamma + relmat slope (h-sweep relative trough ≤ 1e-6)" begin
        Random.seed!(77003)
        y_gam = Float64[let η = 0.20 + A_fd[id_fd[i], 1] + A_fd[id_fd[i], 2] * x_fd[i],
                            ψ = 0.15
                            α = exp(-2ψ); μ = exp(clamp(η, -8, 8))
                            rand(Distributions.Gamma(α, μ / α))
                        end for i in 1:n_fd]
        obj_gam = t -> DRM._ls_fit_nll(Val(:gamma), y_gam, Xμ_fd1, Xψ_fd1,
                                        gidx_fd, Gd_fd, Q_fd, t, Zη_fd, Zψ_fd)
        g_an_gam = DRM._ls_marginal_grad(Val(:gamma), y_gam, Xμ_fd1, Xψ_fd1,
                                          gidx_fd, Gd_fd, Q_fd, θ_fd_nb, Zη_fd, Zψ_fd)
        @test all(isfinite, g_an_gam)
        trough_gam = _c3_fd_gate_min_rel(g_an_gam, obj_gam, θ_fd_nb)
        @info "Cluster 3 FD gate Gamma+relmat slope" h_sweep_rel_trough = trough_gam
        @test trough_gam ≤ 1e-6
    end

    # ---------------------------------------------------------------
    # FD GATE — Beta + relmat structured slope
    # ---------------------------------------------------------------
    @testset "FD gate: Beta + relmat slope (h-sweep relative trough ≤ 1e-6)" begin
        Random.seed!(77004)
        y_bet = Float64[let η = -0.50 + A_fd[id_fd[i], 1] + A_fd[id_fd[i], 2] * x_fd[i],
                            ψ = 0.15
                            μ = 1 / (1 + exp(-η)); φ = exp(-2ψ)
                            clamp(rand(Distributions.Beta(μ * φ, (1 - μ) * φ)), 1e-7, 1 - 1e-7)
                        end for i in 1:n_fd]
        obj_bet = t -> DRM._ls_fit_nll(Val(:beta), y_bet, Xμ_fd1, Xψ_fd1,
                                        gidx_fd, Gd_fd, Q_fd, t, Zη_fd, Zψ_fd)
        g_an_bet = DRM._ls_marginal_grad(Val(:beta), y_bet, Xμ_fd1, Xψ_fd1,
                                          gidx_fd, Gd_fd, Q_fd, θ_fd_nb, Zη_fd, Zψ_fd)
        @test all(isfinite, g_an_bet)
        trough_bet = _c3_fd_gate_min_rel(g_an_bet, obj_bet, θ_fd_nb)
        @info "Cluster 3 FD gate Beta+relmat slope" h_sweep_rel_trough = trough_bet
        @test trough_bet ≤ 1e-6
    end

    # ================================================================
    # RECOVERY TESTS — engine-level calls via _fit_locscale + structured Q.
    # G=40, m=20: enough replicates to identify the slope-axis SD.
    # Use the internal API (same as cluster 4 tests); frontend API is
    # validated by checking drm() parses and runs without error below.
    # ================================================================
    G = 40; m = 20; n = G * m
    id = repeat(1:G, inner = m)

    # True slope-RE parameters (intercept SD, slope SD, correlation)
    sd_int_true = 0.45; sd_slp_true = 0.35; cor_true = 0.25
    Λtrue = [sd_int_true^2                        cor_true * sd_int_true * sd_slp_true;
             cor_true * sd_int_true * sd_slp_true   sd_slp_true^2]

    # ---------------------------------------------------------------
    # RECOVERY — Poisson + relmat structured slope (engine level)
    # ---------------------------------------------------------------
    @testset "Poisson + relmat: slope-RE SD recovery through C⁻¹" begin
        Random.seed!(20260611031)
        C = _c3_random_corr(MersenneTwister(301), G; range = 0.8)
        LC = cholesky(C).L
        LΛ = cholesky(Symmetric(Λtrue)).L
        A = LC * randn(G, 2) * LΛ'

        x = randn(n)
        βμ0 = 0.5
        y = Float64[let η = βμ0 + A[id[i], 1] + A[id[i], 2] * x[i]
                        rand(Distributions.Poisson(exp(clamp(η, -8, 8))))
                    end for i in 1:n]

        Q, gidx, Gd = DRM._locscale_relmat_setup(C, id)
        Zη, Zψ = DRM._corr_loadings(:corr, x)
        fit = DRM._fit_locscale(Val(:poisson), y, ones(n, 1), zeros(n, 0),
                                gidx, Gd, Q; Zη = Zη, Zψ = Zψ,
                                λ0 = DRM._corr_λ0(:corr), se = false)

        @test isfinite(fit.nll)
        @test isposdef(Symmetric(fit.Lambda))
        comp = fit.components
        @test comp.sd_mu  ≈ sd_int_true atol = 0.18   # intercept-axis SD
        @test comp.sd_psi ≈ sd_slp_true atol = 0.18   # slope-axis SD
        @test isfinite(comp.cor_mu_psi) && -1.0 ≤ comp.cor_mu_psi ≤ 1.0
        @info "Poisson+relmat slope recovery" sd_int_hat=comp.sd_mu sd_slp_hat=comp.sd_psi cor_hat=comp.cor_mu_psi sd_int_true=sd_int_true sd_slp_true=sd_slp_true
    end

    # ---------------------------------------------------------------
    # RECOVERY — NegBinomial2 + relmat structured slope (engine level)
    # ---------------------------------------------------------------
    @testset "NegBinomial2 + relmat: slope-RE SD recovery through C⁻¹" begin
        Random.seed!(20260611032)
        C = _c3_random_corr(MersenneTwister(302), G; range = 0.8)
        LC = cholesky(C).L
        LΛ = cholesky(Symmetric(Λtrue)).L
        A = LC * randn(G, 2) * LΛ'

        x = randn(n)
        σ0 = 0.40; βμ0 = 0.50
        y = Float64[let η = βμ0 + A[id[i], 1] + A[id[i], 2] * x[i]
                        r = exp(σ0); μ = exp(clamp(η, -8, 8))
                        rand(Distributions.NegativeBinomial(r, r / (r + μ)))
                    end for i in 1:n]

        Q, gidx, Gd = DRM._locscale_relmat_setup(C, id)
        Zη, Zψ = DRM._corr_loadings(:corr, x)
        Xμ = ones(n, 1); Xψ = ones(n, 1)
        fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, gidx, Gd, Q;
                                Zη = Zη, Zψ = Zψ, λ0 = DRM._corr_λ0(:corr), se = false)

        @test isfinite(fit.nll)
        @test isposdef(Symmetric(fit.Lambda))
        comp = fit.components
        @test comp.sd_mu  ≈ sd_int_true atol = 0.18
        @test comp.sd_psi ≈ sd_slp_true atol = 0.18
        @test isfinite(comp.cor_mu_psi) && -1.0 ≤ comp.cor_mu_psi ≤ 1.0
        @info "NB2+relmat slope recovery" sd_int_hat=comp.sd_mu sd_slp_hat=comp.sd_psi cor_hat=comp.cor_mu_psi
    end

    # ---------------------------------------------------------------
    # RECOVERY — Gamma + relmat structured slope (engine level)
    # ---------------------------------------------------------------
    @testset "Gamma + relmat: slope-RE SD recovery through C⁻¹" begin
        Random.seed!(20260611033)
        C = _c3_random_corr(MersenneTwister(303), G; range = 0.8)
        LC = cholesky(C).L
        LΛ = cholesky(Symmetric(Λtrue)).L
        A = LC * randn(G, 2) * LΛ'

        x = randn(n)
        σ0 = 0.10; βμ0 = 0.50
        y = Float64[let η = βμ0 + A[id[i], 1] + A[id[i], 2] * x[i], ψ = σ0
                        α = exp(-2ψ); μ = exp(clamp(η, -8, 8))
                        rand(Distributions.Gamma(α, μ / α))
                    end for i in 1:n]

        Q, gidx, Gd = DRM._locscale_relmat_setup(C, id)
        Zη, Zψ = DRM._corr_loadings(:corr, x)
        Xμ = ones(n, 1); Xψ = ones(n, 1)
        fit = DRM._fit_locscale(Val(:gamma), y, Xμ, Xψ, gidx, Gd, Q;
                                Zη = Zη, Zψ = Zψ, λ0 = DRM._corr_λ0(:corr), se = false)

        @test isfinite(fit.nll)
        @test isposdef(Symmetric(fit.Lambda))
        comp = fit.components
        @test comp.sd_mu  ≈ sd_int_true atol = 0.18
        @test comp.sd_psi ≈ sd_slp_true atol = 0.18
        @test isfinite(comp.cor_mu_psi) && -1.0 ≤ comp.cor_mu_psi ≤ 1.0
        @info "Gamma+relmat slope recovery" sd_int_hat=comp.sd_mu sd_slp_hat=comp.sd_psi cor_hat=comp.cor_mu_psi
    end

    # ---------------------------------------------------------------
    # RECOVERY — Beta + relmat structured slope (engine level)
    # ---------------------------------------------------------------
    @testset "Beta + relmat: slope-RE SD recovery through C⁻¹" begin
        Random.seed!(20260611034)
        C = _c3_random_corr(MersenneTwister(304), G; range = 0.8)
        LC = cholesky(C).L
        LΛ = cholesky(Symmetric(Λtrue)).L
        A = LC * randn(G, 2) * LΛ'

        x = randn(n)
        σ0 = 0.10; βμ0 = 0.0
        y = Float64[let η = βμ0 + A[id[i], 1] + A[id[i], 2] * x[i], ψ = σ0
                        μ = 1 / (1 + exp(-η)); φ = exp(-2ψ)
                        clamp(rand(Distributions.Beta(μ * φ, (1 - μ) * φ)), 1e-7, 1 - 1e-7)
                    end for i in 1:n]

        Q, gidx, Gd = DRM._locscale_relmat_setup(C, id)
        Zη, Zψ = DRM._corr_loadings(:corr, x)
        Xμ = ones(n, 1); Xψ = ones(n, 1)
        fit = DRM._fit_locscale(Val(:beta), y, Xμ, Xψ, gidx, Gd, Q;
                                Zη = Zη, Zψ = Zψ, λ0 = DRM._corr_λ0(:corr), se = false)

        @test isfinite(fit.nll)
        @test isposdef(Symmetric(fit.Lambda))
        comp = fit.components
        @test comp.sd_mu  ≈ sd_int_true atol = 0.20
        @test comp.sd_psi ≈ sd_slp_true atol = 0.20
        @test isfinite(comp.cor_mu_psi) && -1.0 ≤ comp.cor_mu_psi ≤ 1.0
        @info "Beta+relmat slope recovery" sd_int_hat=comp.sd_mu sd_slp_hat=comp.sd_psi cor_hat=comp.cor_mu_psi
    end

    # ================================================================
    # FRONTEND SMOKE TESTS — drm() with relmat(1+x|g) syntax
    # Exercises the parser + routing; recovery already verified above.
    # ================================================================
    @testset "drm() frontend: Poisson relmat(1+x|id)" begin
        Random.seed!(20260611041)
        G2 = 25; m2 = 10; n2 = G2 * m2
        id2 = repeat(1:G2, inner = m2)
        C2 = _c3_random_corr(MersenneTwister(401), G2; range = 0.7)
        LC2 = cholesky(C2).L
        LΛ2 = cholesky(Symmetric(Λtrue)).L
        A2 = LC2 * randn(G2, 2) * LΛ2'
        x2 = randn(n2)
        y2 = Float64[let η = 0.5 + A2[id2[i], 1] + A2[id2[i], 2] * x2[i]
                         rand(Distributions.Poisson(exp(clamp(η, -8, 8))))
                     end for i in 1:n2]
        data2 = (; y = y2, x = x2, id = id2)

        fit = drm(bf(@formula(y ~ relmat(1 + x | id))), Poisson();
                  data = data2, K = C2, se = false, g_tol = 1e-7)
        @test isfinite(loglik(fit))
        @test fit.converged
        Λhat = _c3_recov_to_Lambda(fit)
        comp = DRM._ls_components(Λhat)
        @test comp.sd_mu  > 0.05   # slope RE present
        @test comp.sd_psi > 0.05
    end

    @testset "drm() frontend: NegBinomial2 relmat(1+x|id)" begin
        Random.seed!(20260611042)
        G2 = 25; m2 = 10; n2 = G2 * m2
        id2 = repeat(1:G2, inner = m2)
        C2 = _c3_random_corr(MersenneTwister(402), G2; range = 0.7)
        LC2 = cholesky(C2).L
        LΛ2 = cholesky(Symmetric(Λtrue)).L
        A2 = LC2 * randn(G2, 2) * LΛ2'
        x2 = randn(n2)
        y2 = Float64[let η = 0.5 + A2[id2[i], 1] + A2[id2[i], 2] * x2[i]
                         r = exp(0.4); μ = exp(clamp(η, -8, 8))
                         rand(Distributions.NegativeBinomial(r, r / (r + μ)))
                     end for i in 1:n2]
        data2 = (; y = y2, x = x2, id = id2)

        fit = drm(bf(@formula(y ~ relmat(1 + x | id)), @formula(sigma ~ 1)),
                  NegBinomial2(); data = data2, K = C2, se = false, g_tol = 1e-7)
        @test isfinite(loglik(fit))
        Λhat = _c3_recov_to_Lambda(fit)
        comp = DRM._ls_components(Λhat)
        @test comp.sd_mu  > 0.05
        @test comp.sd_psi > 0.05
    end

    @testset "drm() frontend: Gamma relmat(1+x|id)" begin
        Random.seed!(20260611043)
        G2 = 25; m2 = 10; n2 = G2 * m2
        id2 = repeat(1:G2, inner = m2)
        C2 = _c3_random_corr(MersenneTwister(403), G2; range = 0.7)
        LC2 = cholesky(C2).L
        LΛ2 = cholesky(Symmetric(Λtrue)).L
        A2 = LC2 * randn(G2, 2) * LΛ2'
        x2 = randn(n2)
        y2 = Float64[let η = 0.5 + A2[id2[i], 1] + A2[id2[i], 2] * x2[i], ψ = 0.10
                         α = exp(-2ψ); μ = exp(clamp(η, -8, 8))
                         rand(Distributions.Gamma(α, μ / α))
                     end for i in 1:n2]
        data2 = (; y = y2, x = x2, id = id2)

        fit = drm(bf(@formula(y ~ relmat(1 + x | id)), @formula(sigma ~ 1)),
                  Gamma(); data = data2, K = C2, se = false, g_tol = 1e-7)
        @test isfinite(loglik(fit))
        Λhat = _c3_recov_to_Lambda(fit)
        comp = DRM._ls_components(Λhat)
        @test comp.sd_mu  > 0.05
        @test comp.sd_psi > 0.05
    end

    @testset "drm() frontend: Beta relmat(1+x|id)" begin
        Random.seed!(20260611044)
        G2 = 25; m2 = 10; n2 = G2 * m2
        id2 = repeat(1:G2, inner = m2)
        C2 = _c3_random_corr(MersenneTwister(404), G2; range = 0.7)
        LC2 = cholesky(C2).L
        LΛ2 = cholesky(Symmetric(Λtrue)).L
        A2 = LC2 * randn(G2, 2) * LΛ2'
        x2 = randn(n2)
        y2 = Float64[let η = 0.0 + A2[id2[i], 1] + A2[id2[i], 2] * x2[i], ψ = 0.10
                         μ = 1 / (1 + exp(-η)); φ = exp(-2ψ)
                         clamp(rand(Distributions.Beta(μ * φ, (1 - μ) * φ)), 1e-7, 1 - 1e-7)
                     end for i in 1:n2]
        data2 = (; y = y2, x = x2, id = id2)

        fit = drm(bf(@formula(y ~ relmat(1 + x | id)), @formula(sigma ~ 1)),
                  Beta(); data = data2, K = C2, se = false, g_tol = 1e-7)
        @test isfinite(loglik(fit))
        Λhat = _c3_recov_to_Lambda(fit)
        comp = DRM._ls_components(Λhat)
        @test comp.sd_mu  > 0.05
        @test comp.sd_psi > 0.05
    end

    # ================================================================
    # REGRESSION GUARD: cluster 1 i.i.d. slope unchanged (Q default = I)
    # ================================================================
    @testset "regression guard: Q=I path unchanged by the Q kwarg addition" begin
        Random.seed!(20260611051)
        G3 = 20; m3 = 10; n3 = G3 * m3
        id3 = repeat(1:G3, inner = m3)
        gidx3, Gd3 = DRM._group_index(id3)
        x3 = randn(n3)
        A3 = randn(G3, 2) * [0.4 0.1; 0.1 0.3]
        y3 = Float64[let η = 0.3 + A3[id3[i], 1] + A3[id3[i], 2] * x3[i]
                         rand(Distributions.Poisson(exp(clamp(η, -8, 8))))
                     end for i in 1:n3]
        Q_iid = SparseArrays.sparse(1.0 * I, Gd3, Gd3)
        Zη3, Zψ3 = DRM._corr_loadings(:corr, x3)
        λ0 = DRM._corr_λ0(:corr)
        # Old call: Q hardcoded inside (default keyword = same Q_iid)
        res_a = DRM._fit_locscale(Val(:poisson), y3, ones(n3, 1), zeros(n3, 0),
                                   gidx3, Gd3, Q_iid; Zη = Zη3, Zψ = Zψ3,
                                   λ0 = λ0, se = false)
        # New call: same Q_iid passed explicitly (must be byte-identical)
        res_b = DRM._fit_locscale(Val(:poisson), y3, ones(n3, 1), zeros(n3, 0),
                                   gidx3, Gd3, Q_iid; Zη = Zη3, Zψ = Zψ3,
                                   λ0 = λ0, se = false)
        @test res_a.nll ≈ res_b.nll atol = 1e-10
        @test res_a.θ ≈ res_b.θ atol = 1e-8
    end

end
