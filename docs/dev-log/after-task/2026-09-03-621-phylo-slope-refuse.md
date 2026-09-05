# After-Task Report: refuse non-intercept lhs on phylo/relmat/animal/spatial markers (#621, closes #620)

- **Date:** 2026-09-03
- **Issue:** #620 (defect); PR #621, branch `fix/phylo-slope-univariate-refuse`,
  merged `9fa0d72ed1b42a2690d3ed3b6ec45e1d677a0efd`
- **Perspectives:** Shannon (Rose after-task pass, retrospective)

## 1. Goal

Stop the silent-drop defect #620: `_split_ranef` (`src/gaussian_ranef.jl`) kept
only the grouping symbol of a structured marker, so `phylo(1 + x | g)` and the
same forms on `relmat`/`animal`/`spatial` silently fitted the intercept-only
model on every univariate family (Gaussian included), discarding `x` with no
warning.

## 2. Implemented

- One check at the single parse choke point (`_check_phylo_re_lhs`,
  `_check_structured_re_lhs`) that throws an `ArgumentError` naming the marker
  before any fitting: `phylo(1 + x | species)` now errors, naming that only
  `phylo(1 | species)` (intercept) is implemented on the univariate routes,
  and that drmTMB fits a two-SD phylogenetic random slope on Gaussian only
  (tracked as a follow-up, not built here). `relmat`/`animal`/`spatial` get
  the same refusal shape without the drmTMB clause.
- The bridge's formula translation now errors identically (3 assertions
  added to `test/test_bridge_formula_translation.jl`).
- `src/gaussian_ranef.jl`: +42 lines; `test/test_phylo_slope_refusal.jl`: new,
  291 lines.

## 3a. Decisions and Rejected Alternatives

- **Fail-closed refusal, not silent fitting or a warning.** A warning would
  repeat the original defect's failure mode (easy to miss); refusal forces the
  caller to notice. Consistent with the repo's existing fail-closed convention
  for unimplemented structured-marker forms.
- **Did not implement the Gaussian two-SD phylogenetic random slope in this
  PR.** drmTMB implements it; DRM.jl does not. Building it was judged a
  separate, non-trivial engine slice (owner follow-up, tracked as an S8
  candidate) — this PR's scope is closing the silent-drop defect, not adding
  the missing capability.
- **Verified the bivariate and location-scale-coupling constructs are
  unaffected rather than assuming it.** The PR body states the bivariate
  q4/q2 `phylo(1 + x | p | species)` construct, the `(1 | tag | phylo(group))`
  location-scale coupling, and the bivariate lognormal `spatial(1 | group)`
  delegation never route through `_split_ranef` — confirmed in source, not by
  inference from the fix's location.

## 4. Files Touched

Per `git diff --stat 9fa0d72e~1..9fa0d72e`:

```
src/gaussian_ranef.jl                   |  42 +++++
test/runtests.jl                        |   3 +
test/test_bridge_formula_translation.jl |   9 +
test/test_phylo_slope_refusal.jl        | 291 ++++++++++++++++++++++++++++++++
4 files changed, 345 insertions(+)
```

## 5. Checks Run

- **RED first (per PR body):** `test/test_phylo_slope_refusal.jl` — all slope
  forms fitted silently on `origin/main` (2 pass / 4 fail / 8 error), then
  17 pass / 6 fail / 12 error for the extension to relmat/animal/spatial.
- **GREEN 35/35**, plus 3 positive-control sets confirming every intercept
  form still fits on Gaussian and Poisson, relmat/animal/spatial intercepts
  still fit, and the q4 bivariate slope form still constructs.
- **Neighbours green (per PR body):** 23 phylo/structured/bridge test files —
  missing-response 45/45; Poisson/Binomial/BetaBinomial/NB2/Gamma/Beta phylo
  Laplace routes and gradients; bivariate phylo 14/6/9/18; LSS phylo; two
  structured Gaussian dense + sparse; heritability; Cox–Reid; penalty; REML
  sigma-phylo; spatial 4/4; bivariate lognormal 46/46; non-Gaussian structured
  bootstrap 31/31; formula translation 52/52.

## 6. Tests of the Tests

- RED-first is explicit and quantified: the new refusal tests failed against
  `origin/main` in exactly the way the defect predicts (silent successful fit,
  not an error) — 2/4/8 then 17/6/12 — before the fix, and pass 35/35 after.
  A test suite that could not distinguish "silently fits the wrong model" from
  "correctly refuses" would not have shown this RED/GREEN contrast.
- The three positive-control sets are the falsifiability check on the fix
  itself: a refusal patch broad enough to also block legitimate intercept-only
  and bivariate-slope forms would fail those controls; it did not.

## 7a. Issue Ledger

- Closes #620.
- **Not covered by this PR (explicit follow-up):** the Gaussian two-SD
  phylogenetic random slope that drmTMB implements — only refused here, not
  built. Tracked as an owner follow-up (S8 candidate).
- **Third affected call site found in drmTMB's own suite.** drmTMB's live
  Julia tests exercise `relmat(1 + x | id, K = K)` and will now see this
  refusal (correct) rather than the prior silent drop — evidence the original
  defect was marker-agnostic (phylo, relmat, animal, spatial), not specific
  to the phylogenetic case that #620 was filed against.

## 8. Consistency Audit

- All four structured markers (`phylo`, `relmat`, `animal`, `spatial`) route
  through the same `_split_ranef` choke point, so the fix was applied once at
  the parse boundary rather than per-marker — the "fix the class, not the
  instance" pattern: #620 was filed as a phylo-specific defect, but the PR
  swept all four markers sharing the same code path.
- Confirmed (per PR body, from source) that constructs which do **not** route
  through `_split_ranef` — bivariate q4/q2 coupling, the location-scale `(1 |
  tag | phylo(group))` form, and the bivariate lognormal `spatial(1 | group)`
  delegation — are unchanged and still pass their existing suites (14/6/9/18
  bivariate phylo, 46/46 bivariate lognormal).

## 9. What Did Not Go Smoothly

- Nothing reported in the PR body beyond the defect itself; this after-task
  pass found no additional friction in the merged diff.

## 10. Known Residuals

- The Gaussian two-SD phylogenetic random slope (drmTMB's target) remains
  unbuilt — only refused. This is the acknowledged capability gap, not a
  documentation gap.
- drmTMB's own test suite will now see new refusals on `relmat(1 + x | id, K
  = K)` calls that previously silently mis-fit — correct behaviour, but a
  cross-repo test-surface change worth flagging to that lane if not already
  known there.

## 11. Team Learning

- **A structured-marker parse choke point is the right place to fail closed.**
  Because all four markers (`phylo`/`relmat`/`animal`/`spatial`) share
  `_split_ranef`, one fix at that single point closed the defect for all of
  them at once, and the drmTMB-suite discovery (`relmat(1 + x | id, K = K)`)
  confirms the defect really was marker-agnostic — a useful confirmation that
  auditing "does this defect have siblings sharing the same code path"
  generalises the fix for free.

## 12. Cross-Product Coverage

Refusing a non-intercept lhs on structured random-effect markers is a
cross-cutting change: it changes what every univariate family accepts for
`phylo`/`relmat`/`animal`/`spatial` markers.

- **Covers ✓:** `phylo(1 + x | g)`, `phylo(0 + x | g)`, and the equivalent
  `relmat`/`animal`/`spatial` non-intercept forms, refused fail-closed with a
  named-marker error, across all univariate families including Gaussian; the
  bridge's formula translation errors identically; intercept-only forms on
  Gaussian and Poisson, and relmat/animal/spatial intercepts, still fit
  (positive control); the bivariate q4 slope form still constructs (positive
  control).
- **Does NOT cover:** the Gaussian two-SD phylogenetic random slope itself
  (only refused, not implemented — drmTMB's target, tracked as a follow-up);
  any non-Gaussian random-slope implementation (drmTMB itself only supports
  the slope on Gaussian, so nothing wider is owed); the bivariate q4/q2
  coupling and location-scale `(1 | tag | phylo(group))` forms are unaffected
  because they never route through `_split_ranef` (confirmed unchanged, not
  independently re-tested by this after-task pass beyond reading the PR's
  own neighbour-suite results).
