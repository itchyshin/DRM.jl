# Two-axis (mean + log-dispersion) conditional-likelihood kernels for the
# non-Gaussian phylogenetic location–scale model (#202 groundwork).
# Gates the analytic gradient + Hessian against ForwardDiff. Engine-lane test:
# calls the internal kernels directly (not yet wired into drm()).
using DRM
using Test
import ForwardDiff

@testset "location–scale kernels: analytic grad/Hessian vs ForwardDiff" begin
    # (family, y-grid) — y > 0 for Gamma, nonnegative counts for NB2, (0,1) for
    # Beta. BetaBinomial carries (successes, trials) per obs (handled separately).
    cases = [
        (Val(:nb2),   [0.0, 1.0, 3.0, 7.0, 20.0]),
        (Val(:gamma), [0.2, 0.8, 1.5, 4.0, 12.0]),
        (Val(:beta),  [0.03, 0.25, 0.50, 0.78, 0.96]),
    ]
    ηs = [-1.2, -0.3, 0.0, 0.6, 1.5]
    ψs = [-1.0, -0.2, 0.4, 1.1, 2.0]

    for (kind, ys) in cases
        for y in ys, η in ηs, ψ in ψs
            f = θ -> DRM._ls_nll(kind, y, θ[1], θ[2])
            θ = [η, ψ]

            gη, gψ = DRM._ls_grad(kind, y, η, ψ)
            g_ad = ForwardDiff.gradient(f, θ)
            @test gη ≈ g_ad[1] rtol = 1e-6 atol = 1e-8
            @test gψ ≈ g_ad[2] rtol = 1e-6 atol = 1e-8

            hηη, hηψ, hψψ = DRM._ls_hess(kind, y, η, ψ)
            H_ad = ForwardDiff.hessian(f, θ)
            @test hηη ≈ H_ad[1, 1] rtol = 1e-6 atol = 1e-8
            @test hηψ ≈ H_ad[1, 2] rtol = 1e-6 atol = 1e-8
            @test hηψ ≈ H_ad[2, 1] rtol = 1e-6 atol = 1e-8
            @test hψψ ≈ H_ad[2, 2] rtol = 1e-6 atol = 1e-8
        end
    end

    # BetaBinomial: response packed as (successes, trials). The grad/Hess are
    # ForwardDiff of `_ls_nll` by construction, so this block is a self-
    # consistency check (and guards nested-AD stability used by `_ls_third`).
    for (s, n) in [(0, 10), (3, 10), (7, 12), (15, 20), (20, 40)], η in ηs, ψ in ψs
        yt = (Float64(s), Float64(n))
        f = θ -> DRM._ls_nll(Val(:betabinomial), yt, θ[1], θ[2])
        θ = [η, ψ]
        gη, gψ = DRM._ls_grad(Val(:betabinomial), yt, η, ψ)
        g_ad = ForwardDiff.gradient(f, θ)
        @test gη ≈ g_ad[1] rtol = 1e-6 atol = 1e-8
        @test gψ ≈ g_ad[2] rtol = 1e-6 atol = 1e-8
        hηη, hηψ, hψψ = DRM._ls_hess(Val(:betabinomial), yt, η, ψ)
        H_ad = ForwardDiff.hessian(f, θ)
        @test hηη ≈ H_ad[1, 1] rtol = 1e-6 atol = 1e-8
        @test hηψ ≈ H_ad[1, 2] rtol = 1e-6 atol = 1e-8
        @test hψψ ≈ H_ad[2, 2] rtol = 1e-6 atol = 1e-8
    end

    # Nested ForwardDiff (the engine's `_ls_third` ForwardDiffs `_ls_hess`): must
    # be finite for the new families, else the exact O(p) outer gradient breaks.
    @test all(isfinite, DRM._ls_third(Val(:beta), 0.4, 0.3, 0.5))
    @test all(isfinite, DRM._ls_third(Val(:betabinomial), (7.0, 12.0), 0.3, 0.5))
end

@testset "location–scale kernels: η-axis matches the fixed-dispersion kernels" begin
    # The mean-axis derivatives must agree with the verified fixed-nuisance
    # kernels in sparse_laplace_glmm.jl at the corresponding dispersion value.
    for (η, ψ, y) in [(0.3, 0.5, 4.0), (-0.4, 1.2, 1.0), (0.9, -0.3, 11.0)]
        # NB2: size r = exp ψ.
        r = exp(ψ)
        aux_nb = (y = [y], size = r, lconst = [0.0])
        gη, _ = DRM._ls_grad(Val(:nb2), y, η, ψ)
        hηη, hηψ, _ = DRM._ls_hess(Val(:nb2), y, η, ψ)
        @test gη ≈ DRM._laplace_d1(Val(:nb2_fixed), aux_nb, 1, η) rtol = 1e-10
        @test hηη ≈ DRM._laplace_d2(Val(:nb2_fixed), aux_nb, 1, η) rtol = 1e-10
        @test hηψ ≈ DRM._laplace_nuisance_d1(Val(:nb2_fixed), aux_nb, 1, η) rtol = 1e-10

        # Gamma: shape α = exp ψ.
        α = exp(ψ)
        aux_g = (y = [y], shape = α, lconst = [0.0])
        gηg, _ = DRM._ls_grad(Val(:gamma), y, η, ψ)
        hηηg, _, _ = DRM._ls_hess(Val(:gamma), y, η, ψ)
        @test gηg ≈ DRM._laplace_d1(Val(:gamma_fixed), aux_g, 1, η) rtol = 1e-10
        @test hηηg ≈ DRM._laplace_d2(Val(:gamma_fixed), aux_g, 1, η) rtol = 1e-10
    end

    # Beta: precision φ = exp(-2ψ) (so ψ = log σ, matching beta.jl). The η-axis
    # AND the cross term hηψ match the `:beta_fixed` Laplace nuisance kernels
    # EXACTLY (no extra chain factor) because both use the same φ = exp(-2ψ)
    # convention — the anchor's `_laplace_nuisance_d1` already carries the
    # -2φ = dφ/dψ factor, which is precisely the _ls_ kernel's hηψ.
    for (η, ψ, y) in [(0.3, 0.5, 0.40), (-0.4, 1.2, 0.12), (0.9, -0.3, 0.83)]
        φ = exp(-2ψ)
        aux_b = (precision = φ, y = [y], ylogit = [log(y) - log1p(-y)],
                 lgammaφ = DRM.loggamma(φ))
        gηb, _ = DRM._ls_grad(Val(:beta), y, η, ψ)
        hηηb, hηψb, _ = DRM._ls_hess(Val(:beta), y, η, ψ)
        @test gηb ≈ DRM._laplace_d1(Val(:beta_fixed), aux_b, 1, η) rtol = 1e-10
        @test hηηb ≈ DRM._laplace_d2(Val(:beta_fixed), aux_b, 1, η) rtol = 1e-10
        @test hηψb ≈ DRM._laplace_nuisance_d1(Val(:beta_fixed), aux_b, 1, η) rtol = 1e-10
    end

    # BetaBinomial η-axis collapses to the plain Binomial score/curvature in the
    # large-φ (no-overdispersion) limit. There is no `:betabinomial_fixed`
    # nuisance kernel, so this is the only η-anchor available — checked loosely
    # since the finite-φ overdispersion correction never fully vanishes.
    ψbig = -3.0                                  # φ = exp(6) ≈ 403
    for (s, n) in [(3, 10), (7, 12)], η in [-0.5, 0.0, 0.6]
        aux_bin = (s = [s], ntr = [n], logchoose = [0.0])
        gηbb, _ = DRM._ls_grad(Val(:betabinomial), (Float64(s), Float64(n)), η, ψbig)
        @test gηbb ≈ DRM._laplace_d1(Val(:binomial), aux_bin, 1, η) atol = 0.2
    end
end
