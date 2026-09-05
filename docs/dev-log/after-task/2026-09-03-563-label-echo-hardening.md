# After-Task Report: bridge coefficient-label-echo hardening (#614, #563 follow-up to #594)

- **Date:** 2026-09-03
- **Issue:** #563 (bridge label contract `bridge_formula_labels_v1`, PR #594
  follow-ups); PR #614, branch `fix/563-coef-labels-scalar-string` @
  `3dd997f3f613cc6c0427cd115aba9d95fb87fa28`
  (**PR open at report time — not yet merged**)
- **Perspectives:** Shannon (Coordination/Rose after-task pass, retrospective)

## 1. Goal

Fix the two follow-ups the drmTMB lane raised after its A4/A5 re-pin (at
`77513aa0`) to the `bridge_formula_labels_v1` coefficient-label-echo contract:
(1) accept a scalar `String` for a length-1 coefficient block, and (2) document
that every reported `fit.blocks` entry — including `phylocov`/`sd`/`sd_phylo` —
needs a `coef_labels` entry when supplied.

## 2. Implemented

1. **Scalar `String` for a length-1 block.** JuliaCall unboxes a length-1 R
   character vector to a Julia `String` (not a length-1 vector), so
   single-coefficient blocks (intercept-only `sigma`, scalar `phylocov`/`sd`
   blocks) previously arrived as bare `"sigma_(Intercept)"` and forced R to
   list-wrap defensively. `_bridge_echo_coef_labels` now normalises
   `AbstractString → String[s]` at its **one entry point**, then requires an
   `AbstractVector` of strings downstream. An `Int` (or other non-string,
   non-vector type) still fails closed with an explicit type message — no
   silent stringification. Count / unknown-dpar / missing-dpar checks
   unchanged.
2. **Docstring.** Documents that every block in `fit.blocks` — including
   `phylocov` and `sd`/`sd_phylo` — needs an entry in
   `options["coef_labels"]` when it is supplied (R labels them, design 258
   §7.5); a scalar `String` is accepted for a length-1 block.
- `src/bridge.jl`: +28/−1.

## 3a. Decisions and Rejected Alternatives

- **Normalise at the one entry point (`_bridge_echo_coef_labels`)** rather than
  at every call site — a single normalisation choke point means every caller
  gets the scalar-acceptance behaviour uniformly and the fail-closed type check
  for genuinely wrong types (e.g. `Int`) only needs to exist once.
- **Fail closed on non-string, non-vector types** rather than attempting a
  generic `string()` coercion — an `Int` label is a caller bug, not a valid
  input to silently accept; the PR explicitly keeps this fail-closed rather
  than loosening it further than the scalar-`String` case required.
- **Scope limited to the two items the drmTMB lane actually raised** (scalar
  string, docstring completeness) — no broader rework of the label-echo
  contract attempted in this PR.

## 4. Files Touched

Per `git diff --stat origin/main...origin/fix/563-coef-labels-scalar-string`:

```
src/bridge.jl                        | 28 ++++++++++++++++++++++-
test/test_bridge_coef_labels_echo.jl | 44 ++++++++++++++++++++++++++++++++++++
2 files changed, 71 insertions(+), 1 deletion(-)
```

## 5. Checks Run

- **RED first:** the scalar-`String` case failed (`status = :error`) on
  `origin/main`, per PR body.
- **GREEN 42/42** in `test_bridge_coef_labels_echo.jl` (3 new cases added: a
  scalar `String` echoes like a length-1 `[s]`; a scalar `String` supplied for
  a 2+-element block fails closed with the count-mismatch error; a non-string
  scalar still fails closed with the type error).
- **Neighbours green (per PR body):** fourteen bridge test files —
  `test_bridge_formula_labels.jl` 819/819, `…_q2_direct_export.jl` (8 sets),
  `…_q4_direct_export.jl` (3 sets), `objective_at` 17/17, `profile` 24/24 +
  36/36, base-R names 20/20, and others.

## 6. Tests of the Tests

- The three new cases are structured to distinguish the fix from a
  weaker/wrong one: (a) scalar-echoes-as-`[s]` would fail under the old
  behaviour (RED-first confirms this); (b) scalar-for-a-2+-block-fails-closed
  confirms the fix does not silently accept a scalar where a full vector is
  required (i.e. it did not just delete the count check); (c)
  non-string-fails-closed confirms the fix did not loosen type-checking beyond
  `AbstractString`, i.e. an `Int` is still rejected, not stringified.

## 7a. Issue Ledger

- Closes the two drmTMB-lane follow-ups to #594's
  `bridge_formula_labels_v1` contract (re-pinned at `77513aa0`).
- **PR #614 was still OPEN (not merged) at the time of this report.**

## 8. Consistency Audit

- All fourteen bridge test files exercising the label-echo path were checked
  and stayed green per the PR body (formula labels, q2/q4 direct export,
  objective_at, profile ×2, base-R names) — the normalisation at the single
  entry point did not regress any of the existing vector-input call sites.
- The "every block needs labels when supplied" docstring claim was checked
  against `phylocov` and `sd`/`sd_phylo` specifically (the scalar-block cases
  that motivated this PR), not just the general contract statement.
- No independent re-run performed in this docs-only session; PR body's
  reported counts are taken at face value.

## 9. What Did Not Go Smoothly

- Nothing flagged in the PR body. The scope was narrow and pre-identified by
  the drmTMB lane's own re-pin review, so this was a targeted fix rather than
  an open-ended investigation.

## 10. Known Residuals

- **PR not yet merged** at report time (`state: OPEN`).
- No broader audit of other bridge-side R-unboxing edge cases (e.g. other
  length-1-vector-vs-scalar JuliaCall coercions elsewhere in the bridge) was
  performed as part of this PR — scope was deliberately limited to the
  coefficient-label-echo path.
- This after-task report was written retrospectively from the PR body, diff
  stat, and file contents — no fresh `Pkg.test()` run was performed to
  reconfirm the 42/42 + neighbour counts.

## 11. Team Learning

- **JuliaCall's R-to-Julia unboxing of length-1 character vectors to a bare
  `String`** is a general hazard for any bridge function that expects an
  `AbstractVector{String}` from R — this PR fixes it for coefficient labels
  specifically; other bridge entry points that accept R character vectors
  should be checked against the same failure mode (worth a sweep, not
  performed here).
- **Normalise-at-one-entry-point, fail-closed-on-genuine-type-errors** is the
  reusable pattern demonstrated here for future scalar-vs-vector R/Julia
  boundary fixes.

## 12. Cross-Product Coverage

The coefficient-label-echo contract (`bridge_formula_labels_v1`) is
cross-cutting — every bridge-built model's `fit.blocks` (mu, sigma, phylocov,
sd/sd_phylo, and any other reported block) flows through it.

- **Covers ✓:** scalar-`String` input for any length-1 block (intercept-only
  `sigma`, scalar `phylocov`/`sd` blocks); fail-closed behaviour preserved for
  genuinely wrong types (`Int`) and for a scalar supplied where a 2+-element
  vector is required; docstring now states every block — including
  `phylocov`/`sd`/`sd_phylo` — needs a `coef_labels` entry when supplied;
  fourteen existing bridge test files (formula labels, q2/q4 direct export,
  objective_at, profile, base-R names) confirmed unregressed.
- **Does NOT cover:** other R-to-Julia scalar/vector unboxing edge cases
  elsewhere in the bridge beyond coefficient labels (not swept in this PR); a
  fresh independent re-run of the 42/42 + neighbour suites in this docs-only
  session (numbers are taken from the PR body); merge/landing status (PR #614
  was open, not merged, at report time).
