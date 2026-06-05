# Design: wire the experimental EM solvers — #12 (location-only) & #13 (natural-gradient)

**Status:** design / implementation map. Completes the **"wire `experimental/`"
epic (#3)** alongside the REML spec (#11/#195). Promotes two *built, partially-
verified* solver variants. No new model capability — these are **alternative
estimators** for models that already exist, exposed opt-in. Implementation +
verification are local Julia. ML/the current solver stays the default.

## Framing: solver, not model

Neither issue adds a model drmTMB has and DRM.jl lacks — they add **faster /
differently-conditioned ways to fit existing models**. So the value bar is
"measurably better on a defined cell, verified," not "new capability." Be honest
where the advantage is real vs unproven.

## #12 — location-only conjugate EM (the clean win)

`src/experimental/location_only.jl` (487 lines) fits the **Gaussian phylo
mean-only** model (RE on μ only ⇒ conjugate ⇒ closed-form marginal):
- `make_loc_problem(phy, y, X)` → `LocOnlyProblem`;
- `em_fit(prob)` — closed-form E-step + M-step with **exact O(p) Takahashi
  traces** → `(; β, σ²_phy, σ², loglik, iterations)`;
- `lbfgs_fit(prob)` — reference; `marginal_loglik`, `build_M`, `exact_traces`.

**Verified (comparison-grid §4):** EM and LBFGS reach the *same MLE*
(|ΔlogLik|=0.0017); **EM 3.1× faster** at p=200/1k — the conjugacy thesis. EM's
edge narrows at p=5k (1.4×).

**The opportunity:** the public Gaussian phylo-mean path today is the dense GLS
`_fit_structured_gaussian` (`gaussian_structured.jl`) — fine at small G, but it
forms dense G×G matrices. `location_only`'s **sparse O(p)** EM is the scalable
engine for *large-p* phylo-mean Gaussian fits, and faster on the conjugate cell.

**Wiring:**
- Add an estimation-**algorithm** selector, e.g. `drm(...; algorithm = :auto)`
  with `:auto | :em | :gls | :lbfgs`. `:auto` picks the sparse EM when the model
  is **conjugate** (Gaussian, RE on the *mean only*, `sigma ~ 1`) and `G`/`p` is
  large; otherwise the existing path. `:em` forces it (error if non-conjugate).
- Route the conjugate case to `make_loc_problem` + `em_fit`; package a normal
  `DrmFit` (β block, the variance components into `vc`/`ranef`, loglik, vcov from
  the marginal Hessian / the existing structured-Gaussian SE path).
- Keep dense GLS as `:gls`/the small-G default — **no behaviour change** unless
  `:em`/large-p `:auto` is selected.

**This is the recommended slice to land** — verified, bounded, real scaling win.

## #13 — natural-gradient EM (opt-in; mostly infrastructure)

`src/experimental/fit_em_natgrad.jl` (81 lines): `fit_em_natgrad(prob, Q_cond,
β0, Λ0)` — block-coordinate **natural-gradient** (= Fisher scoring = AI-REML)
ascent on the full q=4 PLSM: conditional-Newton β-step + a Λ-step that uses the
**Fisher metric** `lc_metric` (a natural/Newton direction on the log-Cholesky
params) with a line search on the true marginal.

**Honest status (the catch):** the comparison-grid §1 records block-coordinate EM
**stalling on the β↔σ coupling** for the full location-scale model (Julia-EM
−259.79 vs the joint LBFGS −256.51 — a *verified-negative* cell), while the
`fit_em_natgrad` driver's own run claims parity with drmTMB. **These must be
reconciled before any "faster solver" claim** — the natural-gradient upgrade may
or may not clear the stall the plain block-coord EM hit.

**Where the value likely is — infrastructure, not a default solver:**
natural-gradient = **Fisher scoring = AI-REML**. The `lc_metric` Fisher-metric
machinery is exactly what the **exact REML gradient (#11 follow-up)** and the
**exact non-Gaussian RE gradient (#165)** want. So the durable payoff of #13 is
the reusable Fisher/AI-REML metric, more than a new default ML path.

**Wiring (conservative):**
- Expose only as `algorithm = :natgrad` (explicitly opt-in, marked experimental),
  **gated on a head-to-head verification** that it reaches the same MLE as
  `fit_q4_sparse_tmb` on the q4 cell (logLik within tol, gradient ≤ 1e-6).
- If it *doesn't* clear the stall: **don't** wire it as a solver; instead extract
  `lc_metric` into the inference/gradient utilities for #11/#165 and close #13 as
  "infrastructure landed, not a public solver."
- Q=4 path reachability is gated by #187 (same as REML).

## Acceptance / test plan (local Julia)

- **#12:** (a) `em_fit` ≡ `lbfgs_fit` MLE on a seeded conjugate fixture
  (|ΔlogLik| small, β/σ² rel-diff small); (b) measured EM-vs-GLS speed at p=1k
  (expect ~3×); (c) `:gls` default unchanged; (d) `DrmFit` accessors correct.
- **#13:** (a) **decision gate** — `fit_em_natgrad` vs `fit_q4_sparse_tmb` on q4:
  logLik within tol and gradient ≤ 1e-6 ⇒ wire as `:natgrad`; else (b) extract
  `lc_metric` + a unit test that it equals the Fisher information on a small case,
  and route it to #11/#165 rather than the public solver.

## Dependencies & sequencing

1. **#12 first** — independent, verified, scalable win; lands the `algorithm`
   selector that #13 (and future solvers) reuse.
2. **#13 decision gate** — verify before wiring; likely yields reusable AI-REML
   infrastructure feeding #11 / #165 rather than a new default.
- Both inherit the q=4 public-path dependency (#187) only for the bivariate cell.

## Implementation checklist

- [ ] `algorithm = :auto` kwarg on `drm(...)` (`:auto|:em|:gls|:lbfgs|:natgrad`); validate per model.
- [ ] **#12** route conjugate Gaussian phylo-mean → `make_loc_problem`/`em_fit`; `DrmFit` packaging; `:gls` default unchanged; conjugacy detection for `:auto`.
- [ ] **#12** tests: EM≡GLS MLE, speed at p=1k, no-regression.
- [ ] **#13** head-to-head verification gate vs `fit_q4_sparse_tmb`; wire `:natgrad` **only if** it clears the stall.
- [ ] **#13** otherwise extract `lc_metric` (Fisher/AI-REML) into gradient utils for #11/#165 + a unit test; document outcome.
- [ ] Docstrings (mark `:natgrad` experimental); update `comparison-grid.md` with the reconciled #13 result.
