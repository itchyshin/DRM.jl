# After-Task Report: #609 item 2 — the varying-scale conditional-fit gap was drmTMB's, not DRM.jl's; Julia-side stationarity pinned (A9b)

- **Date:** 2026-09-05
- **Issue:** #609 item 2 (S10 `varying_scale` `CONDITIONAL_FIT_PARITY_FAIL`); parity
  programme leaf A9b; PR #642, branch `claude/parity-a9b-drmjl` off `430ef64cc`
- **Perspectives:** Gauss (engine), Rose (after-task)

## 1. Goal

Land "the LBFGS `g_tol` gap in `_fit_ranef_gaussian_lss`" the overnight handover (§4)
named as the cause of the `varying_scale` cell failing fit parity against drmTMB
(`newdata/mu` at x = 0.8: 1.086e-5 vs the 4e-6 bar). Oracle: the cell passes
`tools/parity_conditional_prediction.R` afterwards.

## 2. Implemented

No engine change. The premise was measured and found wrong on both counts, so the
deliverable is the measurement and a regression pin:

- **G1 RED did not reproduce.** `tools/parity_conditional_prediction.R` at DRM.jl
  `430ef64cc` against drmTMB `origin/main` `67703f541` (checkout
  `wt-drmtmb-a0`, R/ identical to origin/main) reports `varying_scale PASS`,
  `CONDITIONAL_FIT_PARITY_PASS`, `newdata/mu/link max_abs_diff = 7.157e-11`
  (`stored/mu/link 3.215e-11`). The Julia bridge coefficients are identical to
  17 significant digits to the 2026-09-02 FAIL receipt
  (`mu_(Intercept) 0.5470387467958174, mu_x 0.5425741067214253,
  sigma_(Intercept) -0.5749856034314941, sigma_x 0.17543255098183982,
  resd_g -0.10957094512394476`); the native R prediction at x = 0.8 moved from
  `0.9810880149886124` (old receipt) to `0.9810980322445303` (now), i.e. the
  1.0e-5 was drmTMB's. drmTMB fixed it on 2026-09-03 (`bc8e753eb`, #1130:
  Newton-polish after `nlminb`; design note
  `docs/design/260-nlminb-newton-polish-optimizer-tolerance.md`, which
  already states DRM.jl's optimum was the gradient-verified one). Issue #609's
  own comments (2026-09-02/03) had reached the same diagnosis; the handover §4
  line was stale.
- **The named function was not on the path.** `bf(y ~ x + (1 | g), sigma ~ x)`
  carries no `sd(g) ~` formula, so `drm` routes it through `_fit_ranef_gaussian`
  (`src/gaussian_ranef.jl`, blocks `[:mu, :sigma, :resd]`), not
  `_fit_ranef_gaussian_lss` (blocks `[:mu, :sigma, :sd]`). On this fixture the
  two fitters agree in θ to 1.554e-15.
- **The Julia optimum does not move under a tighter `g_tol`.** Default
  `g_tol = 1e-8` (the value in force: `drm(...; g_tol = 1e-8)` default, the
  bridge passes none): max|∇nll|∞ = 4.212e-9 on both fitters; refit at
  `g_tol = 1e-12`: max|Δθ| = 5.199e-11, loglik `-143.327205865489` unchanged to
  the printed 12 decimals. A `g_tol` sweep 1e-2/1e-4/1e-6/1e-8 gives
  |∇|∞ = 1.095e-3 / 1.058e-5 / 4.212e-9 / 4.212e-9 and
  max|mu_newdata − drmTMB post-#1130 reference| = 6.475e-5 / 3.761e-8 /
  2.624e-11 / 2.624e-11. Tightening 1e-8 is a no-op here; nothing to land.
- **New test `test/test_609_varying_scale.jl`** (12 assertions, 10 s): the 144
  fixture rows inline (exact 17-digit doubles from the runner's receipt);
  route identity of both fitters; stationarity (|∇|∞ ≤ 1e-7, measured 4.2e-9);
  stability under `g_tol = 1e-12` (≤ 1e-8, measured 5.2e-11); fitter agreement
  (≤ 1e-9, measured 1.6e-15); and drmTMB's post-#1130 super-tight reference
  `[0.16723687209213173, 0.54703874680876263, 0.98109803219919800]` at
  4e-8 (100× inside the programme bar; measured 1.3e-11 at x = 0.8).

## 3a. Decisions and Rejected Alternatives

- **Rejected: tightening `g_tol` in `_fit_ranef_gaussian_lss` anyway.** It
  would change nothing measurable on the cell (5e-11 in θ), touch a fitter the
  cell does not use, and be a convergence change with no defect behind it.
- **Rejected: merging branch `fix/563-s10-lss-ranef-gtol` (744d28b3).** Its
  test pins the pre-#1130 drmTMB values as the "R oracle" and asserts
  `norm(g) ≤ 1e-10` (measured 4.2e-9), so it fails by construction on both
  counts; it was written as a RED marker for the R-side fix, not as a
  regression test. Its data and header were reused as provenance only.
- **Rejected: a fixture CSV under `test/parity/`.** Outside this leaf's OWNS;
  the rows are embedded instead.
- **Chosen: D-179 #1 read as precedent for "measure the gradient at the
  optimum, not the optimiser's flag".** That is what the test asserts.

## 4. Files Touched

- `test/test_609_varying_scale.jl` (new, 172 lines)
- `docs/dev-log/after-task/2026-09-05-a9b-varying-scale.md` (this file)
- No `src/` change. `src/gaussian_lss.jl` sha256
  `40fe8281db95bd4da020e4d688ea8f6284e51879aea9f401a1a65c0384b7440d` before and
  after the red-control plant.
- Not touched (outside OWNS; integrator follow-up): `test/runtests.jl` — the
  new file is not yet included in the suite (one `include` line).

## 5. Checks Run

- `Rscript tools/parity_conditional_prediction.R wt-drmtmb-a0 wt-a9b-drmjl red-001.json`
  (OPENBLAS_NUM_THREADS=1, DRMTMB_JULIA_TESTS=true, DRM_JL_PATH=this worktree):
  exit 0, 44 s; `constant_scale PASS / varying_scale PASS / numeric_group PASS /
  CONDITIONAL_ADAPTER_PASS predictions=24 / CONDITIONAL_FIT_PARITY_PASS`;
  varying_scale convergence `[0, 0]`; all eight observations ≤ 7.2e-11.
- `julia --project=. test/test_609_varying_scale.jl`: 12/12 pass, 10.1 s.
- LSS suite, one file at a time (`--project=.` or `--project=test` where
  StableRNGs is needed), all exit 0, zero `Test Failed`/`Error During Test`:
  test_lss_group 25, test_lss_reml 41, test_lss_tip_identity 410,
  test_lss_missing_response 57, test_lss_phylo 36, test_lss_bootstrap_contract 60,
  test_lss_sparse 53, test_lss_sparse_gradient_scaling 64, test_lss_sparse_multi 7,
  test_lss_sparse_multi_gradient 8, test_lss_sparse_multi_public 533,
  test_lss_sparse_multi_reml 25, test_lsss_multi 25, test_bridge_lss_labels 10,
  test_bridge_lss_routes 47 (1401 assertions). No `test/test_563*.jl` exists;
  the #563 LSS coverage lives in the files above. The tip-identity fixture's
  loglik pins pass unchanged (no src change, so trivially so).

## 6. Tests of the Tests

Red control (planted, run, restored byte-identically — sha256 above):
`src/gaussian_lss.jl:242` `Optim.Options(g_tol = g_tol)` → `g_tol = 1e-2`.
Result: `10 passed, 2 failed` — `norm(∇ fit1) ≤ 1e-7` evaluated
`0.0010945374710900069`, and fitter agreement evaluated `6.410685054591969e-5
≤ 1e-9`. The ranef-route sensitivity was shown by argument, not plant
(`g_tol = 1e-2` → |∇|∞ 1.095e-3, reference miss 6.475e-5; both assertions would
fail). Restored file re-run: 12/12.

## 7a. Issue Ledger

- #609 item 2: closed upstream by drmTMB #1130; this PR adds the Julia-side pin.
  No issue comment posted (no-message rule); the integrator may close item 2
  citing this report.
- drmTMB #1130: referenced, unchanged.

## 8. Consistency Audit

- Checked the S10 receipt provenance: `native_fit_source_sha256` and
  `native_methods_sha256` differ between the FAIL receipt and today's PASS
  receipt (drmTMB R/drmTMB.R changed by #1130); `runner_sha256` identical
  (`2bd0685c7bb2…`), so the runner did not move.
- Checked the sibling routes' stopping rules: every Gaussian fitter in
  `gaussian_core.jl`/`gaussian_ranef.jl`/`gaussian_lss.jl` uses the same
  absolute `Optim.Options(g_tol = g_tol)`; the `gaussian_ranef.jl` header's
  headroom table (floor 2.3e-13 at n = 1e3) is consistent with the 4.2e-9
  measured here at n = 144.
- `_fit_ranef_gaussian` vs `_fit_ranef_gaussian_lss` with `sd(g) ~ 1` are the
  same estimator on this cell (1.6e-15).

## 9. What Did Not Go Smoothly

- The leaf's premise (function and side) came from a handover line written
  before the R-side diagnosis on #609 landed; G1 could not be made RED at the
  pin. Reported as ABANDONED-with-reason rather than manufactured.
- `test_lss_group/missing_response/phylo` need `StableRNGs` (test env); first
  pass with `--project=.` errored on load, re-run under `--project=test`.
- The earlier RED-test branch `fix/563-s10-lss-ranef-gtol` is still on origin,
  unmerged and now misleading (stale R oracle); a deletion is the owner's call.

## 10. Known Residuals

- `test/runtests.jl` does not include the new file (outside OWNS).
- Totoro full suite on the PR head not run (optional in the ledger).
- `fix/563-s10-lss-ranef-gtol` left as-is.

## 11. Team Learning

Before "fixing" a parity gap on one engine, move the OTHER engine's tolerance
and see which side walks: here Julia's θ moved 5e-11 under a 10⁴× tighter
tolerance while R's moved 1e-5 — the gap belonged to the side that moved. A
handover diagnosis that names a function is a lead; check the route the cell
actually takes (`first.(fit.blocks)`) before editing.

## 12. Cross-Product Coverage

Covered: Gaussian, ML, `(1 | g)` random intercept, `sigma ~ x`, both the plain
ranef fitter and the LSS fitter with `sd(g) ~ 1`, n = 144, G = 12, one seed.
Not covered: REML on this cell; `sd(g) ~ x` (the LSS fitter's real use); the
`factors` prediction cell (#609 item 1, its own diagnosis); non-Gaussian
families; any n where the absolute-`g_tol` headroom shrinks.
