# After-Task Report: LogNormal phylo/relmat markers on the mean (#608, closes #563 S8 item)

- **Date:** 2026-09-03
- **Issue:** #563 (S8, remaining engine gaps); PR #608, merged `a9d435b74363765ca9e8abd0372d0875819a3213`
- **Perspectives:** Shannon (Coordination/Rose after-task pass, retrospective — not present for the implementation)

## 1. Goal

Close the univariate `LogNormal()` structured-marker gap for the two markers
drmTMB's `lognormal` family actually implements: phylogenetic and relmat markers
on the **mean** only. `sigma`-marker and `animal` calls must stay refused with a
named message.

## 2. Implemented

- `log(y)` is exactly Gaussian, so a structured `LogNormal()` call delegates
  wholesale to `drm(f, Gaussian(); data = data-with-logged-response, tree = …,
  K = …)`. The reported log-likelihood is shifted by the parameter-free Jacobian
  `−Σ log y`, the identity `biv_lognormal()` already used for the bivariate case.
- `theta`/`vcov`/`ranef`/gradient carry over from the Gaussian delegate untouched;
  `loglik`, `ml_loglik`, `reml_loglik`, `nll`, and everything derived
  (`aic`/`bic`/`deviance`) shift by the Jacobian term.
- New keywords (`tree =`, `K =`) added to the `LogNormal` entry point; guard
  restructured so `sigma`-marker and `animal` structured terms still refuse with
  a named message.
- `src/lognormal.jl`: +73/−8 — keywords, guard restructure, new
  `_fit_lognormal_structured` and `_lognormal_jacobian_shift` helpers, docstring.

## 3a. Decisions and Rejected Alternatives

- **Delegate to Gaussian-on-log(y) rather than a bespoke LogNormal phylo/relmat
  kernel.** Rejected writing a new Laplace kernel for lognormal phylo/relmat: the
  transform is exact (no approximation), reuses the already-verified Gaussian
  phylo/relmat engine, and mirrors the existing bivariate identity
  (`biv_lognormal()`), so it is both less code and lower risk than a parallel
  kernel.
- **Keyword names mirror this package's Gaussian phylo/relmat interface** (`tree
  =`, `K =`), not a fresh read of drmTMB's R-side signature — flagged explicitly
  in the PR body as "not covered" (see §12).
- **`animal`/`spatial`/`meta_V` and any marker off the mean stay refused** rather
  than silently attempted, matching drmTMB's own scope for this family.

## 4. Files Touched

Per merge commit `a9d435b74363765ca9e8abd0372d0875819a3213` (merge of PR #608):

```
docs/src/families.md                   |   7 +-
docs/src/model-guides/model-map.md     |  11 +++-
src/lognormal.jl                       |  73 ++++++++++++++++++--
test/runtests.jl                       |   1 +
test/test_lognormal_structured_mean.jl | 117 +++++++++++++++++++++++++++++++++
5 files changed, 201 insertions(+), 8 deletions(-)
```

## 5. Checks Run

- **RED first:** `test/test_lognormal_structured_mean.jl` failed on pre-PR
  `origin/main` (no `tree`/`K` keywords on the `LogNormal` entry) — per PR #608
  body.
- **GREEN:** 17/17 in `test_lognormal_structured_mean.jl` — phylo identity
  (theta/coef at `1e-10`; loglik = Gaussian delegate `−` `Σ log y` at `1e-8`;
  vcov at `1e-6` across two independent optimiser runs; `re_sd` at `1e-10`; aic
  `+ 2·Σ log y`), relmat identity, sigma-marker refusal, `animal` refusal.
- **Neighbours green (per PR body):** bivariate lognormal 46/46, LogNormal
  recovery 5/5 + 4/4 + 4/4, Gaussian structured relmat/animal/phylo
  4/4 + 2/2 + 2/2, #482 missing-response 45/45.
- Wired mid-file into `test/runtests.jl` (+1 line).

This after-task report is a retrospective pass written the morning after the
overnight lane; the numbers above are the PR's own reported counts, not
independently re-run in this docs-only session.

## 6. Tests of the Tests

- The identity check is non-tautological by construction: `loglik` is asserted
  to equal the **Gaussian delegate's** log-likelihood minus `Σ log y`, computed
  independently of the LogNormal path's own internals, at `1e-8` — a broken
  Jacobian sign or a missing shift would fail this immediately.
- `vcov` is cross-checked across **two independent optimiser runs** at `1e-6`,
  which would catch a non-deterministic or path-dependent covariance.
- Explicit RED-then-GREEN: the new test file failed on `origin/main` before the
  keywords were added (documented in the PR body), so the test suite is known to
  fail on the pre-fix code, not just pass on the post-fix code.

## 7a. Issue Ledger

- Closes the LogNormal phylo/relmat-on-the-mean cell of #563 S8 (remaining
  engine gaps).
- Opens no new tracked issue; the "not covered" items below are documented in
  the PR body rather than filed as separate issues.

## 8. Consistency Audit

- The bivariate `biv_lognormal()` identity (Jacobian-shift-on-log-y) was reused
  rather than re-derived, so the two lognormal code paths (univariate structured,
  bivariate) now share the same mathematical pattern — checked by the PR author
  against `biv_lognormal()`'s existing 46/46 suite, which stayed green.
- Sibling families' phylo/relmat guards (Gaussian's own `animal`/`relmat`/`phylo`
  refusal messages) were not touched; their 4/4 + 2/2 + 2/2 suites stayed green,
  confirming no shared-guard regression.
- No sweep was done in this docs-only session beyond reading the PR body, merge
  commit diff, and CI-implied test counts; a full local `Pkg.test()` re-run was
  not performed here (see §10).

## 9. What Did Not Go Smoothly

- Nothing flagged in the PR body itself. From this after-task pass: no R-side
  same-target parity fixture exists yet for lognormal+phylo through the bridge
  (see §10/§12) — the identity is verified analytically (Gaussian-delegate
  equivalence) but not against an independent drmTMB fit.

## 10. Known Residuals

- **No R same-target receipt for lognormal+phylo through the bridge yet.** The
  PR body states this explicitly: "parity fixture to follow."
- **Keyword names (`tree =`, `K =`) are not verified against drmTMB's own R
  signature** — they mirror this package's existing Gaussian phylo/relmat
  interface, which is a reasonable but unverified assumption of naming parity.
- This after-task report was written retrospectively, in a docs-only worktree,
  from the PR body, merge commit diff, and file contents — no fresh
  `Pkg.test()` run was performed to reconfirm the 17/17 + neighbour counts.

## 11. Team Learning

- The Gaussian-on-log(y) delegation pattern (exact transform + Jacobian shift,
  reusing an already-verified engine rather than writing a new kernel) is a
  reusable template for any future "family = monotone transform of an existing
  family" case (e.g. other log-linked continuous families), and should be
  recalled before writing a bespoke kernel from scratch for such cases.

## 12. Cross-Product Coverage

`LogNormal()` structured markers is a cross-cutting capability (a family gains
phylo/relmat support, which touches theta, vcov, ranef, gradient, loglik/AIC/BIC,
and the bridge).

- **Covers ✓:** phylo intercept on the mean; relmat marker on the mean; theta,
  coef, vcov (cross-checked across two optimiser runs), `ranef()`, gradient,
  `loglik`/`ml_loglik`/`reml_loglik`/`nll`/`aic`/`bic`/`deviance` (all correctly
  Jacobian-shifted); explicit refusal (not silent misbehaviour) for sigma-marker
  and `animal` structured terms.
- **Does NOT cover:** `spatial`/`meta_V` markers on the mean (refused, not
  implemented); any structured marker on `sigma` (refused); the R-bridge
  same-target parity fixture for lognormal+phylo (not yet generated — "parity
  fixture to follow" per the PR body); independent verification that the
  `tree =`/`K =` keyword names match drmTMB's own R-side signature (assumed by
  mirroring the Gaussian interface, not read from drmTMB source in this PR).
