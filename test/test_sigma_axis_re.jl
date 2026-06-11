# test_sigma_axis_re.jl — cluster 2 (#XXX): standalone σ-axis random intercept
# `sigma ~ 1 + (1|g)` for non-Gaussian families via the q=2 location–scale Laplace.
#
# DGP: log σ_i = σ0 + u_{g(i)},  u_g ~ N(0, τ²);  mean model is fixed-only.
# Each family testset:
#   1. Simulates the DGP.
#   2. Fits with drm(bf(y ~ x, sigma ~ 1 + (1|g)), Family()).
#   3. Asserts σ-RE SD τ recovered within sampling + finite logLik.
#   4. FD self-consistency: central 5-point-stencil FD of _sigma_re_nll at an
#      off-optimum θ = [βμ; βψ; logL11] vs analytic _sigma_re_grad — must be
#      ≤ 1e-6 for NB2/Gamma/Beta via the h-sweep trough (a fixed small h reads
#      inner-mode-solve noise, not analytic error — the #164 lesson).
#
# Families ENABLED: NegBinomial2, Gamma, Beta.
# Poisson: no free sigma axis → NOT enabled (no _corr_kind dispatch).
# Binomial: no free dispersion → NOT enabled.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

# 5-point stencil FD gradient (more accurate than 2-point).
function _fd_grad_5pt(obj, θ; h = 1e-4)
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

# #164-disciplined FD gate. A single small h makes the marginal-NLL FD reference
# dominated by inner-mode-solve noise (≈ inner_residual / h), NOT analytic error:
# the analytic gradient reuses the verified _ls_marginal_grad. Sweep h and take the
# minimum max-abs discrepancy — the trough of the U-curve where 5-point truncation
# (O(h⁴)) balances inner noise (O(1/h)) — which recovers the TRUE accuracy.
# (Verified empirically: the NB2 trough is ≈ 2e-7 at h≈3e-3.)
function _fd_gate_min(g_an, obj, θ; hs = (1e-2, 3e-3, 1e-3))
    minimum(maximum(abs, g_an .- _fd_grad_5pt(obj, θ; h = h)) for h in hs)
end

# Cold-start FD objective for _sigma_re_nll (each evaluation is independent
# so the 5-point stencil formula is valid; warm-starting across stencil points
# breaks the linearity assumption).
function _sigma_re_fd_obj(kind, y, Xμ, Xψ, gidx, G, Q, Zη, Zψ)
    return θ -> DRM._sigma_re_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
end

@testset "Cluster 2: standalone sigma-axis RE (sigma ~ 1 + (1|g))" begin

    # ------------------------------------------------------------------
    # NegBinomial2: log θ = σ0 + u_g  (θ = NB2 size parameter = "sigma" slot)
    # ------------------------------------------------------------------
    @testset "NegBinomial2: log θ = σ0 + u_g — σ-RE SD recovery + FD gate" begin
        Random.seed!(20260611_1)
        G = 40; m = 40; n = G * m
        g = repeat(1:G, inner = m)
        x = randn(n)
        βμ = [0.5, 0.3]            # log μ = β0 + β1 x
        σ0_true = 0.8              # log θ intercept
        τ_true  = 0.4              # σ-RE SD on log θ
        ug      = τ_true .* randn(G)
        ψ       = [σ0_true + ug[g[i]] for i in 1:n]
        η       = [βμ[1] + βμ[2] * x[i] for i in 1:n]
        y = Float64[let r = exp(ψ[i]), μ = exp(η[i]); rand(Distributions.NegativeBinomial(r, r / (r + μ))); end for i in 1:n]
        data = (; y, x, g)

        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + (1 | g))),
                  NegBinomial2(); data = data, se = true)

        @test isfinite(loglik(fit))
        @test coef(fit, :mu)[1]   ≈ βμ[1]    atol = 0.10
        @test coef(fit, :mu)[2]   ≈ βμ[2]    atol = 0.10
        @test coef(fit, :sigma)[1] ≈ σ0_true atol = 0.20
        τ_hat = re_sd(fit)[:g]
        @test τ_hat ≈ τ_true atol = 0.15

        # FD gate: θ = [βμ; βψ; logL11], compare analytic _sigma_re_grad vs
        # central-FD of _sigma_re_nll at an off-optimum point.
        Xμ = hcat(ones(n), x)
        Xψ = ones(n, 1)
        gidx, Gd = DRM._group_index(g)
        Q = sparse(1.0 * I, Gd, Gd)
        Zη, Zψ = DRM._sigma_re_loadings(n)
        # Build a reasonable off-optimum θ from the fit's result.
        θfit = vcat(coef(fit, :mu), coef(fit, :sigma), log(τ_hat))
        θoff = copy(θfit); θoff[1] += 0.05; θoff[end] -= 0.1
        nll_fn = _sigma_re_fd_obj(Val(:nb2), y, Xμ, Xψ, gidx, Gd, Q, Zη, Zψ)
        g_an = DRM._sigma_re_grad(Val(:nb2), y, Xμ, Xψ, gidx, Gd, Q, θoff, Zη, Zψ)
        # #164 FD gate via the h-sweep trough — true analytic accuracy ≤ 1e-6
        # (a fixed small h would instead read inner-mode-solve noise ≈ residual/h).
        @test _fd_gate_min(g_an, nll_fn, θoff) ≤ 1e-6
    end

    # ------------------------------------------------------------------
    # Gamma: log α = σ0 + u_g  (α = shape; "sigma" slot carries log σ = -½ log α)
    # ------------------------------------------------------------------
    @testset "Gamma: log α = σ0 + u_g — σ-RE SD recovery + FD gate" begin
        Random.seed!(20260611_2)
        G = 35; m = 40; n = G * m
        g = repeat(1:G, inner = m)
        x = randn(n)
        βμ = [0.3, -0.2]
        σ0_true = 0.5              # log α intercept
        τ_true  = 0.35
        ug      = τ_true .* randn(G)
        ψ       = [σ0_true + ug[g[i]] for i in 1:n]
        η       = [βμ[1] + βμ[2] * x[i] for i in 1:n]
        y = Float64[let α = exp(ψ[i]), μ = exp(η[i]); rand(Distributions.Gamma(α, μ / α)); end for i in 1:n]
        data = (; y, x, g)

        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + (1 | g))),
                  Gamma(); data = data, se = true)

        @test isfinite(loglik(fit))
        @test coef(fit, :mu)[1]   ≈ βμ[1]    atol = 0.10
        @test coef(fit, :mu)[2]   ≈ βμ[2]    atol = 0.10
        τ_hat = re_sd(fit)[:g]
        @test τ_hat ≈ τ_true atol = 0.15

        # FD gate
        Xμ = hcat(ones(n), x)
        Xψ = ones(n, 1)
        gidx, Gd = DRM._group_index(g)
        Q = sparse(1.0 * I, Gd, Gd)
        Zη, Zψ = DRM._sigma_re_loadings(n)
        θfit = vcat(coef(fit, :mu), coef(fit, :sigma), log(τ_hat))
        θoff = copy(θfit); θoff[1] += 0.05; θoff[end] -= 0.1
        nll_fn = _sigma_re_fd_obj(Val(:gamma), y, Xμ, Xψ, gidx, Gd, Q, Zη, Zψ)
        g_an = DRM._sigma_re_grad(Val(:gamma), y, Xμ, Xψ, gidx, Gd, Q, θoff, Zη, Zψ)
        # #164 FD gate via the h-sweep trough — true analytic accuracy ≤ 1e-6.
        @test _fd_gate_min(g_an, nll_fn, θoff) ≤ 1e-6
    end

    # ------------------------------------------------------------------
    # Beta: log σ = σ0 + u_g  (φ = 1/σ²; "sigma" slot is log σ)
    # ------------------------------------------------------------------
    @testset "Beta: log σ = σ0 + u_g — σ-RE SD recovery + FD gate" begin
        Random.seed!(20260611_3)
        G = 40; m = 40; n = G * m
        g = repeat(1:G, inner = m)
        x = randn(n)
        βμ = [0.0, 0.4]            # logit μ
        σ0_true = -0.3             # log σ intercept (σ = dispersion, φ = 1/σ²)
        τ_true  = 0.30
        ug      = τ_true .* randn(G)
        ψ       = [σ0_true + ug[g[i]] for i in 1:n]
        η       = [βμ[1] + βμ[2] * x[i] for i in 1:n]
        y = Float64[let μ = 1 / (1 + exp(-η[i])), φ = exp(-2 * ψ[i]); rand(Distributions.Beta(μ * φ, (1 - μ) * φ)); end for i in 1:n]
        data = (; y, x, g)

        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + (1 | g))),
                  Beta(); data = data, se = true)

        @test isfinite(loglik(fit))
        @test coef(fit, :mu)[1]   ≈ βμ[1]    atol = 0.15
        @test coef(fit, :mu)[2]   ≈ βμ[2]    atol = 0.15
        τ_hat = re_sd(fit)[:g]
        @test τ_hat ≈ τ_true atol = 0.20   # Beta: wider tolerance (FD-based kernel)

        # FD gate via the h-sweep trough (Beta uses the ForwardDiff-based kernel).
        Xμ = hcat(ones(n), x)
        Xψ = ones(n, 1)
        gidx, Gd = DRM._group_index(g)
        Q = sparse(1.0 * I, Gd, Gd)
        Zη, Zψ = DRM._sigma_re_loadings(n)
        θfit = vcat(coef(fit, :mu), coef(fit, :sigma), log(τ_hat))
        θoff = copy(θfit); θoff[1] += 0.05; θoff[end] -= 0.1
        nll_fn = _sigma_re_fd_obj(Val(:beta), y, Xμ, Xψ, gidx, Gd, Q, Zη, Zψ)
        g_an = DRM._sigma_re_grad(Val(:beta), y, Xμ, Xψ, gidx, Gd, Q, θoff, Zη, Zψ)
        @test _fd_gate_min(g_an, nll_fn, θoff) ≤ 1e-6
    end

end
