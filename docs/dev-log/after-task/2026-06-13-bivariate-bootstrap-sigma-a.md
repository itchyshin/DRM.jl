# After-Task: Bivariate q=4 among-axis SD bootstrap + bridge + R reach (2026-06-13)

**Branch:** `shannon/bivariate-bootstrap-sigma-a` (off `main`). Local-only
verification on a core-contended Mac (Julia 1.10, R 4.5.2 + JuliaCall).
Serves Ayumi LS#2: boundary-honest uncertainty for the bivariate σ-phylo cell,
reachable from R — "uncertainty in Julia via R is where Julia shines".

## Problem

A bivariate q=4 phylogenetic location-scale fit reports the 4×4 among-axis
covariance `Σ_a`; the quantities Ayumi needs are its diagonal SDs
`sqrt.(diag(Σ_a))` = (sd_μ1, sd_μ2, sd_σ1, sd_σ2) — "is there phylogenetic signal
in this trait's mean / in its variance?". When a scale axis collapses (no signal)
the boundary makes the Hessian singular: `profile_result` on a q4 fit raises
`SingularException(1)`, the Wald SE is undefined, and the native TMB fit reports
`pdHess = FALSE`. There was **no honest interval** for the collapsing pairs.
Verified directly: a q4 σ2-collapse gave `vc` SDs `[0.87, 0.66, 0.62, 0.08]`
(point estimate correct), but `profile_result` → SingularException and
`bootstrap_result` → "bivariate not supported".

The Fisher-z separation parameterization (built earlier) was verified NOT to
resolve this — it conditions the correlation block but cannot manufacture
identifiability on a flat likelihood. So the fix is a method that needs no
Hessian: a parametric bootstrap.

## Changes

1. **`src/bootstrap_q4_phylo.jl` (new) — `bootstrap_sigma_a(fit; data, B, ...)`.**
   Each replicate redraws tip random effects from the fitted
   `N(0, Q_cond⁻¹ ⊗ Σ̂_a)` on the SAME tree (the exact precision-Cholesky draw the
   verified `simulate_coevolution` uses: `F = cholesky(Symmetric(prior_precision(
   Q_cond, inv(Σ_a)))); u = F.UP \\ randn`), adds them to the fitted fixed effects
   on all four axes (μ1, μ2 directly; log σ1, log σ2 on the log scale), regenerates
   (y1, y2) with the fitted residual ρ12, refits the q=4 engine (`q4_vcov=false`
   for speed), and records `sqrt.(diag(Σ̂_a))`. Percentile CIs respect SD ≥ 0:
   a collapsing axis returns an interval at ~0. The leaf→node RE-draw mapping is
   taken verbatim from how the fit extracts its own BLUPs (gaussian_bivariate.jl:
   472-474) → guaranteed consistent with `re.Q_cond`. Jitter guard for a
   near-singular Σ_a. The existing residual-only `simulate(biv_fit)` is NOT reused
   (it carries no phylo signal → Σ_a ≈ 0 every replicate).

2. **`bootstrap_result(fit)` dispatch** (`src/inference.jl`). Both the
   `DrmFit{<:Gaussian}` and generic methods now route a bivariate q4 fit
   (`fit.formula isa BivariateDrmFormula && haskey(fit.ranef, :Sigma_a)`) to
   `bootstrap_sigma_a`, so the public API is uniform (K/A/tree carried by the fit).

3. **`drm_bridge_inference` bivariate branch** (`src/bridge.jl`). A bivariate q4
   fit returns ALL FOUR SD rows as a multi-row payload (`param/estimate/std_error/
   lower/upper` as equal-length vectors, `"multi" => true`) so the R side reads
   them as a data.frame. Bivariate-ness is detected from the formula bundle BEFORE
   the fit so the univariate-only `profile_ci` fit flag is not passed to the q4
   drm method (which rejects it — was a MethodError on the profile path).
   `method="profile"/"wald"` → a clear ArgumentError directing to bootstrap.

4. **R reach** (`report/finish-audit/ayumi-bivariate-bootstrap-via-R.R`). The
   drmTMB `engine="julia"` bridge still gates bivariate phylogenetic fits to native
   TMB (`drm_julia_phylo_payload`, a deliberate "needs parity tests" gate — NOT
   removed unattended), so the bivariate bootstrap is reached today via direct
   JuliaCall: activate DRM.jl, `julia_assign` the data + Newick, fit + bootstrap in
   Julia, `julia_eval` the 4-row CI table back. Verified end-to-end with Rscript.

## Verification

- `test_bootstrap_sigma_a.jl` — σ2-collapse: collapsed-axis CI sits entirely below
  an identified-axis CI; point estimates == `vc(fit)`; `bootstrap_result` dispatch
  returns the 4 SD rows. **20/20.** (~6 s for 20 refits at p=24, n=120.)
- `test_bridge_bivariate_inference.jl` — bridge bootstrap returns 4 finite ordered
  SD rows (≥10/12 refits), `multi==true`; profile throws ArgumentError. **10/10.**
- **Full `Pkg.test()` green** (exit 0, no regression in the bootstrap/bridge
  testsets I touched).
- R round-trip verified via `Rscript` (JuliaCall → DRM.jl → 4-row CI data.frame).

## Independent cross-check

The understand workflow's read-only analysts independently arrived at the same
design: A1 (engine) specified the precision-Cholesky phylo-aware refit +
`sqrt(diag(lc_to_Λ))` percentile rows; A2 (bridge) specified the q4-detect +
4-SD-row multi payload. A4 confirmed bivariate missing-response is a moderate
change touching the verified gradient kernel (deferred, honest throw kept). A5
confirmed REML is provisional (bootstrap is the valid-SE path there). Rose's audit
corrected the reply's stale merge statuses and flagged the Fisher-z / "drop==include"
claims (both softened in rev4).

## Deferred (with honest docs, not rushed unattended)

- Bivariate q4 **missing-response** (#19): per-observation observed-cell mask
  through leaf_nll/grad/hess incl. the exact gradient. Throw at
  gaussian_bivariate.jl:358 is honest.
- drmTMB R-side **idiomatic `confint(engine="julia")`** for the bivariate (#20):
  behind the deliberate `drm_julia_phylo_payload` parity-test gate, in a repo in
  release-prep state. Needs parity tests + user coordination.
- **Optimizer-control** exposure (#14) and REML non-provisional SEs (#18).
