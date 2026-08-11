# VA vs Laplace bias — public Gamma `(1 | g)` (#136e, scoped)

**Date:** 2026-08-09.
**Julia:** 1.10.0 (`julia --project=. --startup-file=no`).
**Branch:** `feat/136e-va-bias-report` from `origin/main` @ `cc113cbb`.
**Harness:** `bench/va_vs_laplace_bias.jl` (log read 2026-08-09; `SMOKE_OK`).
**Status:** smoke measured on the **public** path. Issue **#136 stays OPEN**.

This is the scoped 136e report: ADEMP on what `drm(...; marginal=:VA)` can
actually fit today. It is **not** the original June design’s ZINB / two-part
Gamma cell, and it does **not** flip docs from Experimental to Implemented.

## Owner prior (locked during `/goal`)

In R / TMB, Laplace is preferred in many conditions — often **faster and more
accurate** than VA. The question for DRM.jl is whether the public Julia path
behaves the same way. **LA ≈ VA (or LA better) on a simple Gamma RI is a
finding**, not a failed 136e. Do not hunt a 7× VA win by changing the DGP into
an unwired two-part / ZINB model.

Sister unit-test already expected similarity: `test/test_variational_gamma.jl`
requires `α_VA ≈ α_LA` (atol 0.6) vs the 32-node GHQ Laplace MLE.

## What this is not

- Not ZINB `π ↔ βc` BLAS/OS stability (ZI+RE is rejected on both LA and VA).
- Not GLLVM **Delta-Gamma** (two-part) — that is the sister ~7×-shape cell;
  DRM has no public hurdle-Gamma + RE VA path.
- Not a claim that VA is “implemented everywhere.”
- Not a mixed LA/VA AIC / LRT (ELBO ≠ logLik; do not compare `obj_VA` to
  `obj_LA` as likelihoods).
- Does **not** close #136.
- Not an MCSE-justified campaign (`n_sim = 3` smoke only).

## ADEMP (Morris et al. 2019; Williams et al. 2024)

### A — Aims

1. **Primary.** On the public Gamma random-intercept path, does VA recover
   shape `α` closer to truth than Laplace?
2. **Secondary.** If not — if LA ≈ VA or LA is closer / faster — document that
   this matches the R/TMB preference for Laplace on ordinary RI geometry, and
   that the motivating ~7× cell lives on **two-part / Delta-Gamma**, which is
   not public here.

### D — Data-generating mechanism

One level: observation `i` in group `g(i)`.

- `b_g ~ N(0, σ_b²)`, `σ_b = 0.5`
- `log μ_i = β0 + βx x_i + b_{g(i)}`, `(β0, βx) = (0.4, 0.5)`, `x_i ~ N(0,1)`
- `y_i ~ Gamma(α, μ_i / α)` (shape–scale, mean `μ`), `α = 4`
- `G = 40` groups, `10` obs/group (`n = 400`)

This is the Rung 1 frontend Gamma fixture
(`test/test_va_frontend_families.jl`, seed `202608082`). Two further seeds
`202608083`, `202608084`. **n_sim = 3** is a smoke. An n-ladder was reserved
only for a **material** α gap (LA relative |bias| ≳ 50% and clearly worse than
VA — the 7× class). That gate did not fire.

### E — Estimands

| Estimand | Truth | Estimator |
|---|---|---|
| **α (headline)** | 4 | `exp(-2 * coef(fit, :sigma)[1])` |
| `β0`, `βx` | 0.4, 0.5 | `coef(fit, :mu)` |
| `σ_b` | 0.5 | `re_sd(fit)[:g]` |

### M — Methods

Same formula, same data:

```julia
drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gamma();
    data, marginal = :LA)   # default; 32-node GHQ Laplace
drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gamma();
    data, marginal = :VA)   # Experimental ELBO
```

Comparators: standard-practice LA (TMB / drmTMB class) vs opt-in VA.

### P — Performance measures

Per replicate: bias and relative bias on `α`; wall-clock (first seed includes
JIT); convergence; `α_VA − α_LA`. No RMSE / MCSE (n-ladder skipped).

## Results (smoke, log inspected)

All six fits converged. `fit.marginal` was `:LA` / `:VA` as requested. `SMOKE_OK`.

| seed | α_LA | α_VA | bias_LA | bias_VA | relbias_LA | relbias_VA | t_LA (s) | t_VA (s) | t_VA/t_LA |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 202608082 | 3.7102 | 3.7107 | −0.290 | −0.289 | −7.2% | −7.2% | 4.277* | 7.206* | 1.68* |
| 202608083 | 3.5764 | 3.5767 | −0.424 | −0.423 | −10.6% | −10.6% | 0.119 | 1.838 | 15.50 |
| 202608084 | 4.5822 | 4.5968 | +0.582 | +0.597 | +14.6% | +14.9% | 0.066 | 1.366 | 20.61 |

\*First seed includes compile. Warm LA ≈ 0.07–0.12 s; warm VA ≈ 1.4–1.8 s.

`|α_VA − α_LA|` = 0.0005, 0.0002, 0.0147. Method difference is negligible next
to replicate-to-replicate sampling error on `α` (both methods ~7–15% relative
bias; mean `α̂` across three seeds ≈ 3.96 LA / 3.96 VA vs truth 4). A 7×
collapse would be `α̂ ≈ 0.57`. That did **not** happen.

Location `β` and `σ_b` likewise agreed to visual identity on seeds 1–2; seed 3
`σ_b` 0.51 (LA) vs 0.53 (VA) vs truth 0.50.

`obj_LA` / `obj_VA` are printed in the harness `@info` lines. **Do not rank
methods by those numbers** — VA stores an ELBO, LA a Laplace log-likelihood.

## Interpretation

1. **Primary aim:** VA did **not** recover `α` closer to truth than LA on this
   public Gamma `(1 | g)` cell. The two estimators are interchangeable on `α`
   at smoke precision; seed 3 VA is slightly farther from truth.
2. **Speed:** after compile, LA is about **15–20× faster**. That matches the
   R/TMB habit of preferring Laplace when both are available.
3. **Julia ≈ R (qualitative).** Ordinary random-intercept Gamma is not the
   geometry where VA earns its cost. drmTMB staying Laplace-only is not a
   deficit on this cell.
4. **Where 7× would live:** GLLVM’s measured Laplace shape collapse is
   **Delta-Gamma / two-part**, plus ZINB multimodality. Those paths are not
   public in DRM.jl (`zi`/`hu` + RE is rejected). Closing that story is a later
   #136 slice, not a DGP change inside this report.
5. **S5 n-ladder / Totoro:** skipped — no material α gap.

## Reproduce

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
julia --project=. --startup-file=no bench/va_vs_laplace_bias.jl 3
```

Expect `SMOKE_OK` and `|α_VA − α_LA|` ≪ 0.05 on these seeds (not bit-identical
across machines; the scientific claim is “similar, not 7×”).
