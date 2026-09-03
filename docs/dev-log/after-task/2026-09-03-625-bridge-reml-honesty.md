# After-Task Report: bridge reports estim_method/loglik honestly; REML refusal message corrected (#625, part of #624)

- **Date:** 2026-09-03
- **Issue:** #624 (engine capability parity for estimators, mirror of drmTMB
  #1142); PR #625, branch `fix/624-reml-honesty`, merged
  `7d8daaf2c12906ea279cc8909f3bf744d50f9408`
- **Perspectives:** Shannon (Rose after-task pass, retrospective)

## 1. Goal

Fix two honesty-of-interface defects found by the measured REML route census
posted on #624: (a) `drm_bridge()` fitting by REML returned no way for an R
caller to tell which estimator ran, with `aic`/`bic` silently computed on the
restricted REML likelihood and only a Julia-side `@warn` that never crossed
into R; (b) the generic REML-unsupported refusal message understated what is
actually supported, naming only the fixed-effect Gaussian location-scale
model and a single Gaussian mean random intercept, when the census shows REML
also fits every LSS route, both bivariate structured routes, and Poisson
random-intercept/phylo-intercept cells.

## 2. Implemented

- Every `drm_bridge()` fit now returns `estim_method` ("ML"/"REML"),
  `ml_loglik`, and `infocrit_basis` ("ml"/"reml") unconditionally, plus
  `reml_loglik` and a `warnings` array on REML fits.
- `aic`/`bic` are **kept** on REML fits (not dropped) — they are genuine
  REML-restricted values, valid for variance-only comparisons; the caveat is
  made crossable into R via `infocrit_basis` plus a `warnings` entry, both
  sourced from a single shared text (`_reml_infocrit_warning_text`) so the
  Julia console `@warn` and the bridge's `warnings` field say exactly the
  same thing.
- The generic REML-unsupported refusal message is corrected to name the
  measured supported set (every LSS route: `sd(g)`, `sd_phylo` dense and
  sparse, multi-component; both bivariate structured routes, q=2 and q=4,
  native and via the bridge; Poisson `(1 | g)` and `phylo(1 | species)`)
  rather than the old, narrower claim (fixed-effect Gaussian location-scale
  plus a single Gaussian mean random intercept only). No capability is
  widened — message only.
- `src/bridge.jl`: +22 lines; `src/gaussian_core.jl`: +30/−9 lines;
  `test/test_reml_surface_contract.jl`: new, 136 lines.

## 3a. Decisions and Rejected Alternatives

- **Kept `aic`/`bic` on REML fits rather than dropping them.** Considered
  and rejected: dropping the keys would be a silent breaking change for any R
  caller already reading them unconditionally, and the values themselves are
  not wrong — they are genuine REML-restricted information criteria, valid
  for comparing models with the same fixed-effect structure (variance-only
  comparisons). The chosen fix makes the caveat machine-readable
  (`infocrit_basis`) and human-readable (`warnings`) instead of removing
  data the caller may already depend on.
- **Single shared warning-text function** (`_reml_infocrit_warning_text`)
  rather than two independently maintained strings for the Julia `@warn` and
  the bridge's `warnings` field — avoids the two channels drifting apart, which
  was itself part of the original defect (a warning existing on one side of
  the R/Julia boundary but not the other).
- **Corrected the refusal message rather than widening REML's actual
  fitting capability** — this PR is scoped to interface honesty (can the
  caller tell what happened / what is supported), not to closing the actual
  capability gaps the census found (e.g. `q4_vcov` on REML fits, explicitly
  left open, see below).

## 4. Files Touched

Per `git diff --stat 7d8daaf2~1..7d8daaf2`:

```
src/bridge.jl                      |  22 ++++++
src/gaussian_core.jl               |  30 +++++---
test/runtests.jl                   |   1 +
test/test_reml_surface_contract.jl | 136 +++++++++++++++++++++++++++++++++++++
4 files changed, 180 insertions(+), 9 deletions(-)
```

## 5. Checks Run

- **RED first:** `test/test_reml_surface_contract.jl` on `origin/main`: 14
  pass, 6 fail, 7 error, all on the new assertions.
- **GREEN 27/27**, covering the bridge REML/ML round trip, the refusal-message
  content, and a positive control that three census cells still fit by REML
  with `reml_loglik != ml_loglik`.
- **Neighbours green (per PR body):** the whole bridge suite (primitive
  boundary 128/128, formula labels 819/819, coef_labels echo 42/42, q2 and q4
  direct-export suites, `objective_at` 17/17, profile 24/24 + 36/36, S6 route
  matrix) and LSS REML 41/41 — zero failures across every file run.

## 6. Tests of the Tests

- The positive control (three census cells still fit by REML with
  `reml_loglik != ml_loglik`) is the falsifiability check specific to this
  defect class: a fix that accidentally made every fit report `estim_method
  = "ML"` unconditionally, or that made `reml_loglik` equal `ml_loglik` by a
  copy-paste bug, would fail this control even though the new fields would
  technically be present.
- RED-first (14/6/7 against the new assertions on `origin/main`) confirms the
  test file actually distinguishes the old (missing-field) interface from the
  new one, rather than passing regardless of whether the fields exist.

## 7a. Issue Ledger

- Part of #624 (owner's capability-parity request; mirror of drmTMB #1142).
- **Not covered by this PR (explicit, left open on #624 item 3):** the
  `q4_vcov`-on-REML question — ML curvature reported for a REML fit, 10.5%
  apart from `sdreport()` — is untouched here and still owed a decision.

## 8. Consistency Audit

- The PR body reports the whole bridge suite green across primitive
  boundary, formula labels, coef_labels echo, q2/q4 export, `objective_at`,
  profile, S6 route matrix, and LSS REML — i.e. the neighbourhood of every
  surface that reads bridge-returned fit dictionaries was checked, not just
  the new REML-specific assertions, appropriate for a change that adds keys
  to every fit's return value (ML fits too, via `ml_loglik`/`infocrit_basis`
  now being unconditional).
- The shared-text approach for the warning (`_reml_infocrit_warning_text`)
  was itself an audit move: rather than fixing only the message the census
  happened to probe, it collapses both call sites (Julia console, bridge
  `warnings` field) onto one source of truth so they cannot re-diverge.

## 9. What Did Not Go Smoothly

- Nothing beyond the defects themselves is reported in the PR body; no
  additional friction surfaced in this after-task pass's reading of the
  merged diff.

## 10. Known Residuals

- **`q4_vcov` on REML fits** (#624 item 3): ML curvature is reported for a
  REML fit, measured 10.5% apart from `sdreport()` — untouched by this PR,
  explicitly left as an open owner decision.
- The refusal-message fix documents the *measured* supported set as of this
  PR; it is not machine-generated from the actual routing logic, so it can
  drift out of sync again if new REML routes are added without updating the
  message (same risk class the original defect had, mitigated but not
  structurally eliminated).

## 11. Team Learning

- **A capability-parity census (#624) surfaces two distinct kinds of defect:
  missing information (no `estim_method` in the return value) and wrong
  information presented as authoritative (a refusal message that understates
  what is actually supported).** Both are "honesty of interface" bugs, not
  capability gaps — worth keeping separate from the actual capability
  questions (`q4_vcov` on REML) they surface, so a parity issue does not
  collapse "tell the truth about what we do" and "do more" into one ticket.
- **When a caveat must cross the R/Julia boundary, factor its text into one
  function used by both the native warning and the bridge field** — prevents
  the two channels from silently diverging, which was adjacent to this PR's
  own defect (a Julia-side `@warn` that "never crosses into R").

## 12. Cross-Product Coverage

Bridge estimator reporting is cross-cutting: `estim_method`/`ml_loglik`/
`infocrit_basis` are now unconditional on every `drm_bridge()` fit (ML and
REML alike), not just REML ones.

- **Covers ✓:** every bridge fit (ML or REML) now reports `estim_method`,
  `ml_loglik`, `infocrit_basis`; REML fits additionally report `reml_loglik`
  and `warnings`; the generic refusal message names the measured supported
  set (all LSS routes, both bivariate structured routes q=2/q=4, Poisson
  `(1|g)` and `phylo(1|species)`); `aic`/`bic` are preserved and their basis
  is now machine-readable via `infocrit_basis`; whole bridge suite (primitive
  boundary, formula labels, coef_labels echo, q2/q4 export, `objective_at`,
  profile, S6 route matrix) confirmed unaffected.
- **Does NOT cover:** the `q4_vcov`-on-REML discrepancy (#624 item 3, 10.5%
  gap vs `sdreport()`, explicitly deferred); any widening of which models can
  actually be fit by REML (message-only fix — the census's supported set was
  already true before this PR, just not honestly reported); a machine-checked
  guarantee that the refusal message stays in sync with the routing logic as
  new REML routes are added (documented risk, not structurally closed).
