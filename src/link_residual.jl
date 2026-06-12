# link_residual.jl — distribution-specific observation variance on the link/latent
# scale (σ²_d), used to standardise CROSS-FAMILY latent correlations onto a common
# scale. Sources: Nakagawa & Schielzeth (2010); gllvmTMB `link_residual_per_trait`
# (R/extract-sigma.R). Reporting only — never enters the fit objective.
#
# The cross-family bivariate model (see `mixed_family.jl`) puts a shared latent on
# both axes: η_k = X_k β_k + λ_k u, u ~ N(0,1). The latent-scale variance of axis k
# is λ_k² + v_k, where v_k = link_residual(family_k, …) is the family's own
# observation-level variance on its link scale, and the cross-axis covariance is
# λ1 λ2. Hence the rotation-invariant latent-scale correlation is
#     ρ = λ1 λ2 / sqrt((λ1² + v1) (λ2² + v2)).

"""
    link_residual(fam, μ̂; dispersion) -> Float64

Distribution-specific observation variance `v` of `fam` on its link (latent) scale.

- `Gaussian`     → `dispersion` (residual variance σ²); identity link.
- `Poisson`      → `log(1 + 1/μ̂)`; log link (`μ̂` a representative fitted mean).
- `Binomial`     → `π²/3`; logit link (distribution-free).
- `Beta`         → `trigamma(μ̂ φ) + trigamma((1-μ̂) φ)`; logit link, `dispersion = φ`.
- `Gamma`        → `trigamma(1/φ)`; log link, `dispersion = φ`.

Feeds the cross-family latent correlation `ρ = λ1 λ2 / sqrt((λ1²+v1)(λ2²+v2))`.
"""
# NB: in this shared-latent model the Gaussian axis carries its residual variance
# σ² in `v` directly — there is no separate Ψ as in GLLVM/gllvmTMB (which report 0
# for Gaussian because the residual lives in Ψ). So `v = σ²` is correct for THIS
# parameterisation; verified by the Gaussian×Gaussian ≡ rho12 parity (using 0 here
# would force ρ = 1).
link_residual(::Gaussian, μ̂ = 0.0; dispersion) = float(dispersion)
link_residual(::Poisson, μ̂; dispersion = nothing) = log1p(inv(max(μ̂, 1e-12)))
link_residual(::Binomial, μ̂ = 0.0; dispersion = nothing) = (π^2) / 3
link_residual(::Beta, μ̂; dispersion) =
    trigamma(μ̂ * dispersion) + trigamma((1 - μ̂) * dispersion)
link_residual(::Gamma, μ̂ = 0.0; dispersion) = trigamma(inv(dispersion))
