# Design: wire REML into the public API (`method = :REML`) — #11

**Status:** design / implementation map. Promotes an **existing, partially-verified**
`experimental/` variant; no new estimator math required for the first slice.
Implementation + verification are local Julia. Part of the "wire `experimental/`"
effort (#3); ML stays the default (REML is opt-in). Follows the `wire-experimental`
workflow (A).

## Goal

Expose REML estimation — `drm(...; method = :REML)` — for the models where a
verified REML objective exists, with the bias-correction property drmTMB users
expect, while keeping **ML the default** (REML likelihoods are *not* comparable
across fixed-effect structures, so model selection must stay on ML — `CLAUDE.md`).

## What already exists

| Piece | Where | State |
|---|---|---|
| q=4 REML objective + fitter | `src/experimental/reml_q4.jl` (559 lines): `fit_q4_reml(prob, Q_cond; beta0, Lambda0, phi0, g_tol, …)` | β_μ **profiled out** (Patterson–Thompson; Schur complement `S = X̃_μ' H_uu⁻¹ X̃_μ`, correction `−0.5 logdet S`); warm-starts from the ML optimum; returns `(; phi, beta, Lambda, reml_loglik, ml_loglik, converged, …)` |
| Verified property | `report/comparison-grid.md` §5 + the file header | **mean-axis** variance inflation `diag(Λ_REML) ≥ diag(Λ_ML)` (Λ[1,1] 0.70→0.83, ×1.18) confirmed; gradient ≈ 0 at the REML optimum (FD check) |
| ML public path (the host) | `fit_q4_sparse_tmb` (`method` not an estimation arg today) | REML must slot in beside it |

**Not done:** `experimental/reml_q4.jl` is **not `include`d** by `src/DRM.jl`; there
is **no `method=:REML` estimation kwarg** (`method` currently only selects the CI
type in `confint`/`profile`); inference/AIC under REML is unguarded.

## Honest limits (must ship in the docstring + a warning, per the verify bar)

From `comparison-grid.md` §5 and the file header — do **not** oversell:
- **Mean-axis only:** REML > ML holds reliably for the *mean*-axis variances
  (Λ dims 1,2); the *scale*-axis variances (dims 3,4) do **not** consistently
  satisfy it (they compete with the non-profiled β_σ/β_ρ) — expected, document it.
- **FD gradient:** the outer gradient is central finite-difference (φ is 13-dim).
  No exact REML gradient yet → the analog of #165 for REML (see Follow-ups).
- **Cost:** ~4–5× per eval (alternating joint-mode solve + Schur complement).
- **Stability:** the Schur complement `S` is only PD at the joint mode; an
  `S`-non-PD barrier triggers far from the optimum → REML must **warm-start from
  the ML fit** (as `fit_q4_reml` already does).
- **"Needs human review before production"** (the file's own note) — first
  release should mark REML **experimental/opt-in**, not co-equal with ML.

## Scope & the #187 dependency (important)

`fit_q4_reml` is the REML objective **for the q=4 PLSM**. But the public q=4
*path itself* only becomes reachable when the front end (#187) lands — so
**`method=:REML` on the bivariate coevolution model is gated by #187.** Two
independently-shippable slices:

- **Slice 1 — q=4 bivariate REML** (needs #187): once `drm(bf(… phylo …), Gaussian(); tree=…)`
  routes to `fit_q4_sparse_tmb`, add the `method` switch so it routes to
  `fit_q4_reml` instead. This is the headline REML capability.
- **Slice 2 — univariate / location-scale REML** (independent of #187): standard
  REML for the fixed-effect Gaussian models (integrate out β_μ in the residual
  σ estimate). Smaller, separate addition; **not** covered by `reml_q4.jl` and
  can land first if q=4 REML is blocked on #187.

The design below is the shared `method=:REML` contract; Slice 1 wires the
existing engine, Slice 2 is a follow-on.

## API contract

- **`drm(...; method::Symbol = :ML)`** — `:ML` (default, unchanged) or `:REML`.
  Validate against the family/model (error if REML unsupported for that model,
  e.g. non-Gaussian RE in the first slice).
- **Routing:** `method=:REML` on the q=4 path → `fit_q4_reml(prob, Q_cond; …)`
  warm-started from a quick `fit_q4_sparse_tmb` (ML) solve (reuses its β̂, Λ̂).
- **`DrmFit` packaging:** store **both** `reml_loglik` and `ml_loglik`; mark the
  fit's estimation method (a field or in `ranef`/metadata) so accessors and the
  AIC/lrtest guard can read it. `loglik(fit)` returns the REML value **with a
  documented caveat**; expose `ml_loglik` for cross-structure comparison.
- **Model-selection guard:** `aic`/`bic`/`lrtest`/`anova` must **warn (or error)
  when comparing REML fits with different fixed-effect structures** — the classic
  REML trap. Comparing REML fits that differ *only* in variance structure is
  valid; differing mean structure is not.

## Acceptance / test plan (local Julia)

1. **Bias-correction property (the defining test):** on a seeded fixture,
   `diag(Λ_REML) ≥ diag(Λ_ML)` on the **mean axis** (dims 1,2), within tolerance —
   the verified §5 result, now reachable from the public API.
2. **Gradient self-consistency:** FD gradient ≈ 0 at the REML optimum
   (`max|g|` small) — matches the existing check. (Exact gradient is a follow-up.)
3. **ML unchanged:** `method=:ML` is bit-for-bit the current default path.
4. **Guard:** AIC/lrtest across different mean structures under REML warns/errors;
   across variance-only structures is allowed.
5. **R-parity (where available):** REML variance components vs drmTMB REML on a
   shared fixture (generated outputs; Workflow G / #17).

## Follow-ups (tracked, not this slice)

- **Exact REML gradient** — replace the FD outer gradient with the analytic REML
  gradient (the REML analog of the q=4 exact-gradient recipe / #165); removes the
  ~4–5× cost driver and the FD noise.
- **Scale-axis REML** — the consistent scale-axis bias-correction (dims 3,4) is an
  open research item; keep REML opt-in until resolved.
- **Slice 2** — univariate/location-scale REML.

## Implementation checklist

- [ ] `include("experimental/reml_q4.jl")` into `src/DRM.jl` (promote out of `experimental/`); resolve any orphaned deps.
- [ ] Add `method::Symbol = :ML` to the relevant `drm(...)` dispatch(es); validate.
- [ ] Route `method=:REML` (q=4) → `fit_q4_reml`, warm-started from an ML solve. *(Gated by #187 for the public bivariate path.)*
- [ ] `DrmFit`: store `reml_loglik` + `ml_loglik` + estimation-method marker; `loglik` docstring caveat.
- [ ] Model-selection guard in `aic`/`bic`/`lrtest`/`anova` for cross-mean-structure REML comparisons.
- [ ] Tests 1–4; docstrings with the honest limits; a worked REML example in the relevant article (mark experimental).
- [ ] Update `report/comparison-grid.md` if REML behaviour/coverage changes.
