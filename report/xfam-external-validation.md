# External validation: cross-family latent correlation vs `gllvm`

**Question (user).** Is DRM.jl's cross-family latent correlation
(`fit_mixed_family`) the right number? Validate it independently — against the
`gllvm` package where possible, otherwise against an independent Monte-Carlo /
analytic reference.

**Estimand.** For the shared-latent model `η_k = X_k β_k + λ_k u`, `u ~ N(0,1)`,
DRM reports the latent-scale correlation

```
ρ = λ1 λ2 / sqrt((λ1² + v1) (λ2² + v2)),   v_k = link_residual(family_k, …)
```

(Nakagawa & Schielzeth 2010 standardization). This is the **same estimand** as
the trait–trait residual correlation of a 2-response, 1-factor GLLVM
(`gllvm(num.lv = 1)`), reported by `gllvm::getResidualCor`.

## Was `gllvm` available?

**Yes** — `gllvm` 2.0.5 on the local `/usr/local/bin/Rscript`. So the external
package check was run for real (not the analytic-only fallback).

## Key constraint: `gllvm` fits one family per matrix

Stock `gllvm` 2.0.5 takes a **single** `family` for the whole response matrix; a
per-column family vector (`family = c("gaussian","poisson")`) errors with
*"the condition has length > 1"*. So `gllvm` can supply an external reference for
the **same-family** case (Gaussian × Gaussian — an identical-estimand,
independent-engine cross-check) but **cannot** fit a literally mixed
Gaussian × Poisson. That genuinely cross-family number is therefore validated
against an independent Monte-Carlo population reference instead. (This single-
family limitation is itself the gap DRM's `fit_mixed_family` fills.)

Verified that `getResidualCor` *is* DRM's estimand and not merely a similar
quantity: `gllvm::getResidualCov` adds `phi²` (Gaussian) and `π²/3`
(binomial-logit) to its diagonal — the same `link_residual` terms DRM uses — and
reconstructing `getResidualCor` from gllvm's own loadings `θ·σ_lv` and `phi`
via DRM's formula reproduces it to < 1e-4 (checked in the generator script).

## Three independent checks (`test/test_xfam_external_validation.jl`)

| # | Reference | Pair | DRM vs reference | Result (gap) |
|---|-----------|------|------------------|--------------|
| 1 | **`gllvm` (external package)** | Gaussian × Gaussian | `getResidualCor` on identical data | **1.2e-4** |
| 2 | **Independent Monte-Carlo** | Gaussian × Poisson | population ρ from true λ/v | **7.7e-4** (mean of 3 seeds) |
| 3 | **Closed form** | Gaussian × Gaussian | exact bivariate-normal ρ | **3.3e-3** |

### (1) External package — `gllvm`, Gaussian × Gaussian

A shared-latent Gaussian × Gaussian dataset (n = 2000, seed 20260610) is fit by
**both** engines on the **identical** simulated data:

- `gllvm(family = "gaussian", num.lv = 1)` → `getResidualCor[1,2] = 0.657552`,
  logLik −5001.780.
- DRM `fit_mixed_family` → `rho_latent = 0.657669`, logLik −5001.760.

`|ρ_DRM − ρ_gllvm| = 1.2e-4` — two orders of magnitude tighter than the sampling
gap to the true ρ = 0.663710 (≈ 6e-3). DRM's logLik is ≥ gllvm's (the GHQ
optimum is at least as high as gllvm's VA optimum). Note the individual Gaussian-
axis loadings sit on a flat ridge (DRM lands at λ = (0.71, 0.88), gllvm at the
mirror (0.89, 0.70)); ρ and logLik — the identified quantities — agree regardless,
exactly as the `mixed_family.jl` identifiability note predicts.

DRM (GHQ + ForwardDiff + LBFGS) and `gllvm` (variational-approx + TMB) share no
code, so this is a genuine independent-engine cross-check.

### (2) Cross-family — independent Monte-Carlo, Gaussian × Poisson

The literally mixed case `gllvm` cannot fit. The population latent-scale ρ is
built from the **true** parameters using DRM's documented standardization:

- `v1 = σ1²`;
- `v2 = log(1 + 1/μ̄2)` with `μ̄2 = E_x[exp(X β2)]` — the **conditional-mean
  baseline** (excluding the latent), which is `rho_of`'s convention. `E_x` is a
  2e6-draw Monte-Carlo over the true covariate law. No DRM fit enters the
  reference.

For (β2 = [0.3, −0.5], λ1 = 0.8, λ2 = 0.6, σ1 = 0.5): ρ_ref = 0.547733. DRM at
n = 10 000 (mean of seeds 101/202/303) gives ρ̄ = 0.548499, gap **7.7e-4**;
per-seed max gap ≈ 5.5e-3. λ1, λ2, σ1 recover to within 0.05.

**Definitional finding (worth recording).** An early reference mistakenly used
`μ̄2 = E[exp(η2)]` (the *marginal* mean, including the latent), giving v2 = 0.434
and a spurious 0.029 ρ-gap. DRM evaluates v2 at the conditional baseline
`E[exp(Xβ2)]` (v2 = 0.503). With the references aligned to DRM's actual
convention the gap collapses to < 1e-3. The estimand depends on *which*
representative Poisson mean feeds `link_residual`; DRM uses the
fixed-effect-only mean, and the test pins this.

### (3) Closed form — Gaussian × Gaussian

Where the marginal is exactly bivariate normal,
`ρ = λ1 λ2 / sqrt((λ1²+σ1²)(λ2²+σ2²))` holds analytically. DRM recovers it to
3.3e-3 at n = 4000.

## Reproducibility

- Fixture generator (fresh MIT code; calls `gllvm`, vendors no GPL source):
  `test/parity/gen_xfam_external.R`. Run: `Rscript test/parity/gen_xfam_external.R`.
- Fixture (generated **numbers only** — gllvm is GPL, fitted numbers are data,
  per AGENTS.md §3): `test/parity/fixtures/xfam-external-gllvm/`
  (`data.csv`, `expected.toml`, `expected.meta.toml`).
- Test: `test/test_xfam_external_validation.jl` (wired into `runtests.jl`).
  Testset 1 is **guarded** — it logs a skip and the suite still passes if the
  fixture is absent (machines without R/gllvm). Testsets 2–3 are self-contained.
- All 14 assertions pass; full testset runtime ≈ 33 s (dominated by the
  n = 10 000 × 3 cross-family Monte-Carlo fits).

## Verdict

DRM.jl's cross-family latent correlation matches an **independent external
package** (`gllvm`, Gaussian × Gaussian) to **1.2e-4** on identical data, and
matches an **independent Monte-Carlo population reference** for the genuinely
mixed **Gaussian × Poisson** case to **7.7e-4**. The estimand, the
standardization, and DRM's implementation are externally validated.
