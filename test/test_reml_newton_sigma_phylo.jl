# Fast REML for the Gaussian σ-phylo location-scale route — the "beat ASReml" speed headline.
#
# The shipped FD-REML refit (`_glsp_reml_refit`) minimises the Patterson–Thompson restricted
# likelihood `nll_ML + 0.5·logdet S` by letting LBFGS finite-difference the whole composite —
# which made the convergence flag misfire (the penalty is itself an FD, so the optimiser saw a
# second-order FD gradient) and converged only by judging on substance. Two faster, clean-flag
# replacements: (1) the CLEAN-GRADIENT refit (`_glsp_reml_refit_clean`, ~6 LBFGS steps) and
# (2) the OBSERVED-INFORMATION Newton (`_glsp_reml_newton_asym`, ~3 steps). NB: the literal
# average-information data-quadratic was proven INVALID here (â is the shrunk BLUP) — see the
# second testset's note.
#
# CORRECTNESS ANCHOR (this file): the FD-REML refit. Both replacements must land on the SAME
# restricted-likelihood optimum — the same σ-phylo SD — on the verified asymmetric route.
using DRM
using Test, Random, LinearAlgebra

@testset "REML σ-phylo: clean-gradient refit matches FD-REML (asymmetric route)" begin
    Random.seed!(707)
    p = 24; m = 6; n = p * m
    phy = random_balanced_tree(p; branch_length = 0.3)
    C   = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
    u_sig = 0.5 .* (LC * randn(p))               # σ-phylo RE only (asymmetric: mean fixed)
    species = repeat(1:p, inner = m)
    x = randn(n)
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)       # pμ = 2 (non-trivial REML projection)
    βμ = [1.0, -0.4]; βψ = [log(0.5)]
    y = [ (Xμ[i, 1]*βμ[1] + Xμ[i, 2]*βμ[2]) +
          exp(Xψ[i, 1]*βψ[1] + u_sig[species[i]]) * randn() for i in 1:n ]
    pμ = size(Xμ, 2)

    kind = Val(:gaussian_mean)
    Q, gidx, G = DRM._locscale_phylo_setup(phy, species)
    Zη, Zψ = DRM._glsp_asym_loadings(n)
    obj(θ)  = DRM._glsp_asym_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
    grad(θ) = DRM._glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)

    # ML estimate (the shared starting point for both refits).
    θ0 = vcat(Xμ \ y, [0.0], log(0.3))
    θ̂_ml, ml_conv = DRM._glsp_optimise(obj, (g, θ) -> (g .= grad(θ); g), θ0)
    @test ml_conv

    # FD-REML (the anchor) and the clean-gradient refit, from the identical ML start.
    θ_fd, _, _, _                  = DRM._glsp_reml_refit(obj, grad, θ̂_ml, pμ; ml_converged = ml_conv)
    θ_cg, conv_cg, _, _, nsteps    = DRM._glsp_reml_refit_clean(obj, grad, θ̂_ml, pμ; ml_converged = ml_conv)

    sd_fd = exp(θ_fd[end]); sd_cg = exp(θ_cg[end])
    @info "clean-gradient refit vs FD-REML" sd_cg sd_fd diff = abs(sd_cg - sd_fd) nsteps conv_cg
    @test isapprox(sd_cg, sd_fd; rtol = 0.05)    # same restricted-likelihood optimum

    # The whole point of the clean-gradient refit: a CLEAN convergence flag (no substance workaround).
    @test conv_cg
end

# NOTE: the literal average-information data-quadratic was proven INVALID here (â is the
# shrunk BLUP, not a residual with covariance H⁻¹ — an adversarial derivation panel measured
# the candidate at ~0.2× the true curvature). The correct fast O(p) metric is the OBSERVED
# information (central FD of the exact O(p) score) — verified to converge in ~3 Newton steps.
@testset "REML σ-phylo: observed-information Newton (asymmetric route)" begin
    Random.seed!(808)
    p = 24; m = 6; n = p * m
    phy = random_balanced_tree(p; branch_length = 0.3)
    C   = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
    u_sig = 0.5 .* (LC * randn(p))
    species = repeat(1:p, inner = m)
    x = randn(n)
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    βμ = [1.0, -0.4]; βψ = [log(0.5)]
    y = [ (Xμ[i, 1]*βμ[1] + Xμ[i, 2]*βμ[2]) +
          exp(Xψ[i, 1]*βψ[1] + u_sig[species[i]]) * randn() for i in 1:n ]
    pμ = size(Xμ, 2)

    kind = Val(:gaussian_mean)
    Q, gidx, G = DRM._locscale_phylo_setup(phy, species)
    Zη, Zψ = DRM._glsp_asym_loadings(n)
    obj(θ)  = DRM._glsp_asym_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
    grad(θ) = DRM._glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)

    θ0 = vcat(Xμ \ y, [0.0], log(0.3))
    θ̂_ml, ml_conv = DRM._glsp_optimise(obj, (g, θ) -> (g .= grad(θ); g), θ0)
    @test ml_conv

    θ_fd, _, _, _ = DRM._glsp_reml_refit(obj, grad, θ̂_ml, pμ; ml_converged = ml_conv)
    θ_nw, conv, _, _, nnewton =
        DRM._glsp_reml_newton_asym(kind, y, Xμ, Xψ, gidx, G, Q, Zη, Zψ, θ̂_ml, pμ;
                                   ml_converged = ml_conv)

    sd_fd = exp(θ_fd[end]); sd_nw = exp(θ_nw[end])
    @info "observed-info Newton vs FD-REML" sd_nw sd_fd diff = abs(sd_nw - sd_fd) nnewton conv
    @test conv
    @test nnewton <= 5                            # ASReml-class: a handful of Newton steps
    @test isapprox(sd_nw, sd_fd; rtol = 0.05)     # same restricted-likelihood optimum
end

# SEPARATE block (both axes, K=2): mean-phylo RE + σ-phylo RE, Λ = diag(L11², L22²). The
# general `_glsp_reml_newton` must recover BOTH phylo SDs at the FD-REML optimum in a handful
# of Newton steps — the capability drmTMB lacks (the MUST-HAVE σ-phylo cell, both axes).
@testset "REML σ-phylo: observed-info Newton, separate block (both axes, K=2)" begin
    Random.seed!(909)
    p = 24; m = 6; n = p * m
    phy = random_balanced_tree(p; branch_length = 0.3)
    C   = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
    u_mu  = 0.6 .* (LC * randn(p))
    u_sig = 0.5 .* (LC * randn(p))
    species = repeat(1:p, inner = m)
    y = [1.0 + u_mu[species[i]] + exp(log(0.5) + u_sig[species[i]]) * randn() for i in 1:n]
    Xμ = ones(n, 1); Xψ = ones(n, 1); pμ = 1; pψ = 1

    kind = Val(:gaussian_mean)
    Q, gidx, G = DRM._locscale_phylo_setup(phy, species)
    Zη = DRM._ls_canonical_Zeta(n); Zψ = DRM._ls_canonical_Zpsi(n)
    obj(θ)  = DRM._glsp_sep_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
    grad(θ) = DRM._glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)

    θ0 = vcat(Xμ \ y, [0.0], log(0.3), log(0.3))   # [βμ; βψ; logL11; logL22]
    θ̂_ml, ml_conv = DRM._glsp_optimise(obj, (g, θ) -> (g .= grad(θ); g), θ0)
    @test ml_conv

    vidx = [pμ + pψ + 1, pμ + pψ + 2]              # logL11, logL22 (indices 3, 4)
    θ_fd, _, _, _ = DRM._glsp_reml_refit(obj, grad, θ̂_ml, pμ; ml_converged = ml_conv)
    θ_nw, conv, _, _, nstep =
        DRM._glsp_reml_newton(obj, grad, θ̂_ml, pμ, vidx; ml_converged = ml_conv)

    sd_mu_fd = exp(θ_fd[3]); sd_sig_fd = exp(θ_fd[4])
    sd_mu_nw = exp(θ_nw[3]); sd_sig_nw = exp(θ_nw[4])
    @info "separate-block observed-info Newton vs FD-REML" sd_mu_nw sd_mu_fd sd_sig_nw sd_sig_fd nstep conv
    @test conv
    @test nstep <= 6                               # K=2: a handful of Newton steps
    @test isapprox(sd_mu_nw,  sd_mu_fd;  rtol = 0.06)
    @test isapprox(sd_sig_nw, sd_sig_fd; rtol = 0.06)
end
