# Focused unit tests for the module-wired optimizer / mode-accuracy fixes
# (#314, #317, #325.4). These exercise the DRM-module code paths directly.
#
#   #314  locscale_grad.jl    — `_ls_marginal_grad` must return an all-NaN vector
#         (not all-zeros) when the inner Laplace mode fails, so a gradient-based
#         optimiser rejects the infeasible step instead of reading a zero gradient
#         as stationarity. Pairs with the `_ls_fit_nll` value sentinel.
#   #317  sparse_aug_plsm.jl  — `estep_mode`'s fast path must not freeze a loosely
#         converged mode into the Laplace marginal: the accepted mode's joint
#         gradient norm must be tight (≤ the tightened stall gate ~1e-6), matching
#         a robustly re-converged mode.
#   #325.4 locscale_profile.jl — `_ls_profile_ci`/`_ls_profile_nll` now carry the
#         Zη/Zψ loadings (defaulting to canonical) so the profiler reconstructs the
#         EXACT model that was fit. Passing canonical loadings explicitly must give
#         bit-identical CIs to the default.

using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

@testset "optimizer robustness / mode accuracy (#314, #317, #325.4)" begin

    # ---------------------------------------------------------------------------
    # #314  NaN (not zero) outer gradient on inner-mode failure
    # ---------------------------------------------------------------------------
    @testset "#314 _ls_marginal_grad returns NaN on inner-mode failure" begin
        Random.seed!(7)
        G = 5; m = 6; n = G * m
        gidx = repeat(1:G, inner = m)
        x = randn(n); z = randn(n)
        Xμ = hcat(ones(n), x); Xψ = hcat(ones(n), z)
        Λt = DRM._ls_lc_to_Λ([log(0.4), 0.1, log(0.5)]); Lt = cholesky(Symmetric(Λt)).L
        A = [Lt * randn(2) for _ in 1:G]
        y = [(r = exp(0.2 + A[gidx[i]][2]); μ = exp(0.3 + 0.4x[i] + A[gidx[i]][1]);
              Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ))))) for i in 1:n]
        Q = sparse(1.0 * I, G, G)

        # A feasible θ: gradient is finite and populated (no NaN).
        θgood = [0.3, 0.4, 0.1, -0.05, log(0.4), 0.1, log(0.5)]
        ggood = DRM._ls_marginal_grad(Val(:nb2), y, Xμ, Xψ, gidx, G, Q, θgood)
        @test all(isfinite, ggood)
        @test any(ggood .!= 0)

        # An infeasible θ (near-singular Λ, off-scale predictor) makes the inner
        # mode fail: `_ls_fit_nll` returns the sentinel and the gradient must be
        # all-NaN — crucially NOT all-zeros (the pre-#314 behaviour that read as
        # convergence to a gradient-based optimiser).
        θbad = [0.25, 0.35, 0.1, -0.05, log(1e-8), 5.0, log(1e-8)]
        vbad = DRM._ls_fit_nll(Val(:nb2), y, Xμ, Xψ, gidx, G, Q, θbad)
        gbad = DRM._ls_marginal_grad(Val(:nb2), y, Xμ, Xψ, gidx, G, Q, θbad)
        @test vbad >= 1e17                    # objective is the infeasible sentinel
        @test all(isnan, gbad)                # gradient signals infeasibility
        @test !any(iszero, gbad)              # NOT the old zero-vector stall signal
    end

    # ---------------------------------------------------------------------------
    # #325.4  profiler carries loadings; default == explicit canonical
    # ---------------------------------------------------------------------------
    @testset "#325.4 profile CI threads Zη/Zψ (canonical default unchanged)" begin
        Random.seed!(7)
        G = 5; m = 6; n = G * m
        gidx = repeat(1:G, inner = m)
        x = randn(n); z = randn(n)
        Xμ = hcat(ones(n), x); Xψ = hcat(ones(n), z)
        Λt = DRM._ls_lc_to_Λ([log(0.4), 0.1, log(0.5)]); Lt = cholesky(Symmetric(Λt)).L
        A = [Lt * randn(2) for _ in 1:G]
        y = [(r = exp(0.2 + A[gidx[i]][2]); μ = exp(0.3 + 0.4x[i] + A[gidx[i]][1]);
              Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ))))) for i in 1:n]
        Q = sparse(1.0 * I, G, G)
        θ̂ = [0.3, 0.4, 0.1, -0.05, log(0.4), 0.1, log(0.5)]

        ci_def = DRM._ls_profile_ci(Val(:nb2), y, Xμ, Xψ, gidx, G, Q, θ̂; idx = 2, level = 0.95)
        Zη = DRM._ls_canonical_Zeta(n); Zψ = DRM._ls_canonical_Zpsi(n)
        ci_exp = DRM._ls_profile_ci(Val(:nb2), y, Xμ, Xψ, gidx, G, Q, θ̂;
                                    idx = 2, level = 0.95, Zη = Zη, Zψ = Zψ)
        @test ci_def.lower == ci_exp.lower    # explicit canonical == default
        @test ci_def.upper == ci_exp.upper
        @test isfinite(ci_def.lower) && isfinite(ci_def.upper)
        @test ci_def.lower < θ̂[2] < ci_def.upper
    end

    # ---------------------------------------------------------------------------
    # #317  fast E-step freezes only a tightly-converged mode
    # ---------------------------------------------------------------------------
    @testset "#317 estep_mode returns a tight mode for the frozen Laplace" begin
        Random.seed!(11)
        p = 8
        phy = random_balanced_tree(p; branch_length = 0.2)
        Σ_phy = sigma_phy_dense(phy; σ²_phy = 1.0)
        n = p
        x1 = randn(n)
        X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
        Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)
        β = (mu1 = [0.5, 0.3], mu2 = [-0.2, 0.4], s1 = [-0.4], s2 = [-0.5], rho = [0.3])
        Λ = Matrix(Symmetric([0.30 0.10 0.05 0.0;
                              0.10 0.30 0.0 0.04;
                              0.05 0.0 0.12 0.02;
                              0.0 0.04 0.02 0.12]))
        Lc = cholesky(Λ).L; Sc = cholesky(Symmetric(Σ_phy)).U
        U = Lc * randn(4, p) * Sc
        y1 = zeros(n); y2 = zeros(n)
        for i in 1:n
            m1 = (X1[i, :]'β.mu1) + U[1, i]; m2 = (X2[i, :]'β.mu2) + U[2, i]
            s1 = exp((Xs1[i, :]'β.s1) + U[3, i]); s2 = exp((Xs2[i, :]'β.s2) + U[4, i])
            ρ = DRM.RHO_GUARD * tanh(Xr[i, :]'β.rho)
            e = cholesky([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2]).L * randn(2)
            y1[i] = m1 + e[1]; y2[i] = m2 + e[2]
        end
        prob, Q = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
        P = prior_precision(Q, inv(Λ))

        # Cold solve to the mode, then a WARM re-solve (exercises the fast path).
        u_cold, _, _ = estep_mode(prob, P, β)
        u_warm, ch, H = estep_mode(prob, P, β; u0 = u_cold)

        # The frozen-mode Laplace assumes ∇_u J = 0 exactly. With stall_tol tightened
        # to 1e-6 (#317), an accepted warm mode must be genuinely at the mode — its
        # joint gradient norm must be well below the old loose 1e-3 acceptance.
        ng_warm = norm(joint_grad(prob, P, u_warm, β))
        @test ng_warm < 1e-5
        # And it must agree with the cold-solved mode (no loose off-mode drift).
        @test maximum(abs, u_warm .- u_cold) < 1e-4
    end
end
