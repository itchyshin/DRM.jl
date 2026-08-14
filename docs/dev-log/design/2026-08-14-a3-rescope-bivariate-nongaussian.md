# A3 re-scope — bivariate non-Gaussian

Date: 2026-08-14 · lane: DRM.jl (Claude) · anchor: drmTMB **0.7.0 @ `origin/main`
`f5ec53634`** · supersedes A3's original subject

## Why A3 needed re-scoping

A3 was written as *"admit fixed-effect non-Gaussian families through
`engine = "julia"`"*. Arc A0 showed that was **already delivered** by drmTMB PR
#499 (2026-08-09): `drm_julia_family_tag()` routes nine Workflow G fixed-effect
families unconditionally. The original A3 has nothing left to do.

The genuine 0.7.0 gap the ledger surfaced is the **bivariate non-Gaussian**
cluster — 6 of the 25 export gaps, and the only cluster that is a whole missing
capability rather than a payload or naming detail.

## It is two routes, not one cluster

The six exports are **not** one feature. drmTMB splits them by *association
scale*, and the vignette's own table is the contract:

| Paired outcomes | Route | Association means |
|---|---|---|
| Two Gaussian traits | direct `biv_gaussian()` | Gaussian residual `rho12` — **DRM.jl has this** |
| Two positive traits | direct **`biv_lognormal()`** | log-response residual `rho12` |
| Two heavy-tailed traits | direct **`biv_student()`** | shared-Student-t scatter `rho12` |
| A reviewed mixed/discrete pair | staged **`biv_associate()`** | latent-normal copula `eta` after **frozen margins** |

So `biv_lognormal` / `biv_student` live in `R/family.R` (direct joint models),
while `biv_associate` / `associate_pairs` / `association` / `latent_normal` live
in `R/associate-pairs.R` (a staged two-stage route). They should be separate
arcs.

## drmTMB's own first slice is tightly bounded

From the vignette's *"What is currently outside these routes"* — this is the
parity target, and it is much smaller than "a bivariate non-Gaussian capability":

- Direct routes keep **`sigma1`, `sigma2`, `rho12`, and `nu` constant across
  rows** (intercept-only).
- **No random effects** and **no missing-data support** in either route.
- The staged route rejects offsets, missing predictors, aliased columns, dot
  expansion, and random effects; `eta` is usually constant, the one exception
  being an intercept-bearing fixed-effect association formula for
  literal-Bernoulli × ordinary-NB2.
- Neither route is a general non-Gaussian bivariate claim. Lognormal interval
  calibration evidence covers only the fixed-effect DGP in the Arc 6 artifact.

**Matching that boundary is the arc.** Exceeding it would be inventing capability
the twin does not have.

## What the research already settles (do not re-derive)

**[[dr18-bivariate-lognormal-distilled]] — bivariate lognormal is the EASY case.**
The fixed-effect regression has a **closed-form likelihood**: the log-scale
vector is bivariate normal, so the density is `φ₂(log y; μ, Σ)` times the
Jacobian `∏ 1/yᵢ`. No integration, no rectangle probabilities, no RQMC
(Gustavsson's MLLN). Also: bivariate-normal-on-log-scale and
Gaussian-copula-on-lognormal-margins are the **same model**, not a design choice.
And no R package implements this contract — MLLN was MATLAB-only — so drmTMB's
version is genuine prior-art-free ground.

**[[dr19-bivariate-student-t-distilled]] — exact density available; ν is
structurally shared.** The exact bivariate-t density is directly implementable
via the Mahalanobis form. **ν cannot vary by margin** — the scale-mixture uses one
scalar mixing variable — which is exactly why drmTMB's table says *shared*-Student-t.
Per-margin tail heaviness would require a copula, losing the exact density.
Two cautions to carry into docs: *zero `rho12` ≠ independence* for any finite ν,
and heavy-tail/correlation interaction is an open question the corpus did not settle.

**One caveat that does NOT apply to us.** dr19 reports a real failure mode —
RQMC approximation error defeating derivative-based optimisers, fixed by
derivative-free optimisation. That is about multivariate-t **probabilities**
(CDF/rectangles). Our likelihood needs only the **density**, which is
closed-form, so ForwardDiff + LBFGS remains appropriate. Do not import the
derivative-free workaround on the strength of that note.

## Reuse — this is why the estimate is modest

`src/gaussian_bivariate.jl:187` `_fit_bivariate_residual` is a self-contained
fitter: per-parameter design matrices for `mu1/mu2/sigma1/sigma2/rho12`, an
explicit `nll`, `RHO_GUARD` on `tanh(ηρ)`, per-cell missing-response handling,
and finite seeding. Both direct families are that scaffold with a different
kernel:

- **`biv_lognormal`** — identical kernel on `log(y₁), log(y₂)`, plus the Jacobian
  term `+ Σ log yᵢ` on observed cells, plus a `y > 0` validation. Two small
  changes.
- **`biv_student`** — replace the Gaussian kernel with the bivariate-t
  log-density and add one shared scalar `ν` (fit on an unconstrained scale with a
  lower guard, mirroring `RHO_GUARD`'s role).

Both then need what every DRM.jl family needs: a family struct, the `bf()`
grammar tag, exports, recovery tests, docstrings, a worked example, and a
`check-log.d` entry (`AGENTS.md` Definition of Done).

## Estimates (D-139 — stated before any code)

| sub-arc | scope | estimate |
|---|---|---|
| **A3a** `biv_lognormal` | reuse `_fit_bivariate_residual`; log-transform + Jacobian; constant `sigma1/sigma2/rho12` | **0.5–1 day** |
| **A3b** `biv_student` | new bivariate-t kernel; one shared `ν`; constant scatter params | **1–1.5 days** |
| **A3c** staged `biv_associate` | two-stage: fit margins, freeze, then latent-normal copula `eta`; needs its own design pass first | **2–3 days** |

Full cluster **≈ 4–6 days**. The original A3 carried 2–3 days, so the cluster as
a whole is roughly **double** what it replaces — but no single sub-arc is.

**Recommended next arc: A3a alone.** It is the closed-form case, it reuses an
existing verified fitter, it is the smallest thing that closes a real capability
gap, and it has an R comparator to test against — `tools/parity_fixture.R`
already fits the same target both engines and compares coefficients and logLik.

**A3c should not start without its own design pass.** "Frozen margins" is a
two-stage estimator whose uncertainty propagation is the hard part, and drmTMB
bounds its own version heavily (alpha-scale Wald only, experimental-interval
warning, no simultaneous eta bands).

## What must NOT be claimed

Matching drmTMB's boundary means shipping the *same* restrictions, not quietly
exceeding them: constant `sigma1/sigma2/rho12/nu`, no random effects, no
missing-data support, no general non-Gaussian bivariate claim, and no interval
calibration claim beyond a fixed-effect DGP. `rho12` on the log scale is **not**
the raw-scale Pearson correlation — the vignette makes that scale part of the
scientific interpretation, and DRM.jl's docs must say the same.
