# After-Task Report: drm_bridge_objective_at — supported cross-engine objective at a point (#563 / #569 / #575, D-203 §5)

- **Date:** 2026-09-02
- **Issue:** #563 / #569 / #575, vault D-203 §5
- **PR:** #590 (merge commit `e4647333`; superseded draft #587, closed only because the GraphQL budget was exhausted and a draft cannot be marked ready over REST — same branch)
- **Branch:** `feat/563-bridge-objective-at`
- **Perspectives:** Shannon (Coordination), Hopper (Payload Shape), Noether (Point Parameterisation), Rose (Gate)

## 1. Goal

Add one **supported**, public Julia entry point,
`drm_bridge_objective_at(formula, family, data, tree, options; beta,
Lambda, rho12)`, that takes the same payload as `drm_bridge` plus an outer
point and returns DRM.jl's q4 REML objective there — so drmTMB's A4/A5
cross-engine shim can stop depending on five DRM.jl private names and
hand-written Julia source strings.

## 2. Implemented

- **`drm_bridge_objective_at`** (new, `src/bridge.jl`, +116 lines per `git
  show e4647333 --stat`): route-guarded to the bivariate q=4 phylogenetic
  REML route; reuses `drm_bridge`'s own parsing helpers for
  `formula`/`family`/`data`/`tree`/`options`; delegates to the private
  `reml_objective_at` (#586) for the actual evaluation. Returns
  `contract = "bridge_objective_at_v1"`, `objective`/`reml_loglik`
  (route-agnostic alias), `raw_reml_ll`, and `converged_inner` (the inner
  conditional-Newton alternation's own convergence flag — renamed from the
  old ad hoc shim's `"converged"`).
- **One export line** in `src/DRM.jl` (+1/−1 net per the stat).
- **`test/test_bridge_objective_at.jl`** (new, 217 lines): RED
  (`UndefVarError: drm_bridge_objective_at not defined`) → **GREEN 17/17**.
- `test/test_api_stability.jl` (+1/−1): the new entry registered in the
  EXPERIMENTAL tier next to `drm_bridge`/`drm_bridge_inference`.
- `test/runtests.jl` (+1) wires the new test file in.

Full diffstat (`git show e4647333 --stat`, this worktree): 6 files changed,
337 insertions(+), 2 deletions(-).

## 3a. Decisions and Rejected Alternatives

- **Route-guarded to bivariate q=4 phylogenetic REML only, not a general
  objective-at-a-point entry.** The function rejects non-q4 payloads, a
  wrong-length `beta`, and a non-4×4 `Lambda` (tested directly, §5/§6) —
  chosen to match the one route drmTMB's A4/A5 shim actually needs, rather
  than generalising to routes with no measured cross-engine receipt yet.
- **Delegates to the existing private `reml_objective_at` (#586) rather
  than reimplementing the evaluation.** The PR body: "equals the private
  `reml_objective_at` path at an identical point, atol 1e-8" — tested as an
  explicit equivalence check, not assumed from shared code.
- **`converged_inner` replaces the old ad hoc shim's `converged` key
  name**, documented explicitly in `objat-r-note.md` as a deliberate,
  named breaking change from the R-side shim this entry replaces (a
  barrier hit still surfaces as `raw_reml_ll = reml_loglik = -Inf,
  converged_inner = FALSE`, same semantics, new key name) — R-side callers
  must remap `converged = result$converged_inner`.
- **Error messages are now specific `ArgumentError`s per failure mode**
  (missing `tree`, non-bivariate formula, no shared `phylo(...)` term on
  all four axes, non-4×4 `Lambda`, missing/wrong-length `beta` field,
  `beta` not a `Dict`/`NamedTuple`) instead of the old hand-written shim's
  generic errors or deeper, less specific failures inside
  `reml_objective_at`/`pack_phi` — `objat-r-note.md`: "a wrong-length
  `beta` or non-4×4 `Lambda` would previously have failed deeper ... with a
  much less specific message, or silently misaligned."
- **`options` is accepted for positional parity with `drm_bridge` but not
  otherwise read** on this route — this entry is a diagnostic, not a fit,
  so fit-controlling keys like `method = "REML"` inside `options` have no
  effect here (`objat-r-note.md`), a deliberate scope limit rather than an
  oversight.
- **The Julia-point pin was re-derived after #575 landed, in a separate
  commit (`2500ab39`) on the same branch**, rather than leaving the
  pre-#575 finite-difference-era value in the test: "after #579 [sic, #575
  via PR #579] `fit_q4_reml`'s optimum on the committed fixture is
  −219.614005, so the value at 'Julia's own point' moves from the A5
  receipt's −219.630326 (`dc3ce190`, finite-difference era); the TMB-point
  value −219.620688 is unchanged. History kept in comments." (commit
  message, `git show -s --format=%B 2500ab39`).
- **Base is `main` with #589 (the `reml_objective_at` primitive) and #579
  (exact REML gradient) already merged**, per the PR body — this entry is
  built as a thin bridge layer on top of already-landed primitives, not a
  standalone reimplementation.

## 4. Files Touched

Merge commit `e4647333` (`git show e4647333 --stat`, this worktree):

- `docs/dev-log/check-log.d/2026-09-02-563-bridge-objective-at.md` (+1)
- `src/DRM.jl` (+1/−1)
- `src/bridge.jl` (+116)
- `test/runtests.jl` (+1)
- `test/test_api_stability.jl` (+1/−1)
- `test/test_bridge_objective_at.jl` (+217, new file)

6 files changed, 337 insertions(+), 2 deletions(-). Also on the same branch,
merged with it: commit `2500ab39` (`test(bridge): re-derive the Julia-point
pin of drm_bridge_objective_at on the exact-gradient engine (#579)`),
already reflected in the diffstat and numbers above.

This report (written by Rose, not counted in the merge diffstat above):

- `docs/dev-log/after-task/2026-09-02-563-bridge-objective-at.md`

(The check-log row for this slice was already written and merged as part of
PR #590 itself, per the diffstat above.)

## 5. Checks Run

- **RED, pre-implementation** (`scratchpad/objat-red.log`, worktree
  `wt-563-objat`): `ERROR: LoadError: Some tests did not pass: 1 passed, 6
  failed, 4 errored, 0 broken.` Root cause of every failure/error:
  `UndefVarError: drm_bridge_objective_at not defined`. Recorded testset
  breakdown at the point the run stopped:
  ```
  drm_bridge_objective_at — bivariate q4 phylo REML                     | Pass 1 Fail 6 Error 4 Total 11 | 35.7s
    (a) reproduces #575's cross-engine receipt at TMB's point           |               Error 1  Total 1  | 4.6s
    (a) reproduces #575's cross-engine receipt at Julia's own point     | Pass 1        Error 1  Total 2  | 30.2s
    (b) equals the private reml_objective_at path at an identical point |               Error 1  Total 1  | 0.0s
    (c) rejects a non-q4 payload                                       |      Fail 2             Total 2  | 0.8s
  ```
  (Further (c)/(d) cases in the file — wrong-length `beta`, non-4×4
  `Lambda`, return shape — also failed/errored on `UndefVarError` per the
  detailed log, but the summary table's later rows are not fully captured
  in this run's output; the reported total for this RED run is 11, not the
  file's full 17, because the top-level `LoadError` interrupted before
  every testset in the file was tallied — see §9.)
- **GREEN, after implementation** (`scratchpad/objat-green.log`):
  ```
  drm_bridge_objective_at — bivariate q4 phylo REML | Pass 17 Total 17 | 25.7s
  ```
- **Re-verified on the merged head** (`scratchpad/objat-merged3.log`,
  after `2500ab39`'s pin re-derivation):
  ```
  drm_bridge_objective_at — bivariate q4 phylo REML | Pass 17 Total 17 | 32.4s
  OBJAT3_EXIT=0
  ```
- **Neighbours** (PR body): `test_reml_objective_at.jl` **5/5**;
  `test_bridge_formula_labels.jl` **819/819**; `test_api_stability.jl`
  **188/188** (entry registered in the EXPERIMENTAL tier).
- **Cross-engine receipt reproduced** (`objat-r-note.md` "Verified
  evidence"): at TMB's fitted point, receipt **−219.620688**, bridge
  returns within `atol = 2e-4` — PASS; at Julia's own REML optimum, receipt
  **−219.630326** (pre-#575, `dc3ce190`, finite-difference era; per
  `2500ab39`'s commit message, re-derived to **−219.614005** post-#575 on
  the merged branch), bridge returns within the same `2e-4` window — PASS;
  bridge result equals the private `reml_objective_at` path at an identical
  point to `atol = 1e-8` — PASS.
- **Check-log row** (`docs/dev-log/check-log.d/2026-09-02-563-bridge-objective-at.md`,
  on `main`): "✅ green; same payload as `drm_bridge` + (beta, Lambda,
  rho12); reproduces the drmTMB A5 receipt at both points (−219.620688 /
  −219.630326, atol 2e-4); equals the private path atol 1e-8; rejects
  non-q4 payloads and malformed points; `contract = "bridge_objective_at_v1"`"
  — Shannon (Hopper, Noether).

## 6. Tests of the Tests

The RED run (`scratchpad/objat-red.log`) is direct evidence the test suite
actually depends on the new function existing: every failure/error traces
to a single root cause, `UndefVarError: drm_bridge_objective_at not
defined`, across the cross-engine receipt cases (a), the private-path
equivalence case (b), and the input-validation cases (c) — i.e. the tests
are not merely checking values that happen to be defined elsewhere; they
require the named entry point. After implementation, the same test file
passes 17/17 with the numeric receipt values matching independently
recorded references (`objat-r-note.md`'s TMB-point and Julia-point
receipts) rather than values back-derived from the implementation itself.
The subsequent re-verification on the merged head after the pin
re-derivation commit (`2500ab39`) — still 17/17 — is further evidence the
test's Julia-point assertion tracks the actual solver optimum rather than
a value hardcoded independent of the engine's real behaviour: when #575
changed that optimum, the test's expected value was intentionally moved to
match, with the history of the change kept in comments per the commit
message, rather than silently re-tolerable through a loose `atol`.

## 7a. Issue Ledger

- **#563 / #569 / #575, D-203 §5** — landed on
  `feat/563-bridge-objective-at`, PR #590 merged as `e4647333`. Vault
  record (`~/shinichi-brain/memory/DECISIONS.md:7372`, D-203 item 5,
  "added later the same day"): "A supported bridge entry
  `drm_bridge_objective_at(payload…, φ)` is APPROVED, PR-gated (Shinichi
  2026-09-02: 'go ahead with the (payload, phi) bridge entry -
  PR-gated')... Built test-first on `feat/563-bridge-objective-at`, stacked
  on PR #586 (`reml_objective_at`)." Review named in the PR body: Hopper
  (payload shape) + Noether (point parameterisation) + Rose (scope). Ledger
  `.unlazy/563-objat` (local run state, not read for this report). Merge is
  the maintainer's.
- **#575** — the Julia-point pin in this slice's own test was re-derived
  in commit `2500ab39` once #575's exact-gradient fix landed, keeping the
  cross-engine receipt test aligned with the corrected solver optimum
  rather than the earlier finite-difference-era value.

## 8. Consistency Audit

- **Both reference points in the drmTMB A5 receipt were reproduced, not
  just one** — TMB's fitted point (−219.620688, unaffected by #575, since
  it is TMB's own value) and Julia's own optimum (moved by #575 and
  re-verified to track that move via `2500ab39`).
- **The new entry was checked for equivalence against its own delegate**
  (`reml_objective_at`, case (b), `atol = 1e-8`) — not just against the
  external cross-engine receipt — isolating whether the bridge wrapper
  introduces any discrepancy from the primitive it wraps.
- **Input validation was swept across all three malformed-input shapes
  named in the design** (non-q4 payload, wrong-length `beta`, non-4×4
  `Lambda`), each with its own RED case and GREEN pass, plus a return-shape
  check (case (d)) — not just the headline cross-engine numbers.
- **API-stability registration was checked and updated**
  (`test_api_stability.jl`, 188/188, entry added to the EXPERIMENTAL tier)
  rather than leaving the new public entry unregistered in that ledger.

## 9. What Did Not Go Smoothly

- **Draft #587 had to be superseded by #590** for the same reason as the
  other two slices in this batch: the GraphQL budget was exhausted and a
  draft PR cannot be marked ready for review over the REST API alone —
  same branch, no rework.
- **The RED log's own summary table is incomplete relative to the file's
  full 17 assertions** — the run's top-level `LoadError` interrupted
  processing after 11 of the file's testset entries were tallied (1 pass /
  6 fail / 4 error), so the RED evidence available from
  `scratchpad/objat-red.log` covers cases (a), (b), and part of (c), not
  every one of the 17 GREEN-run assertions individually. The `UndefVarError`
  root cause is uniform across every failure recorded, so this is a
  completeness gap in the captured log, not a discrepancy in what failed —
  flagged rather than papered over (see §10).
- **The Julia-point receipt value needed a second, dedicated commit
  (`2500ab39`) to stay correct** after #575 changed the underlying solver
  optimum mid-stream — the branch had to be updated to track a moving
  target rather than being written once and left alone.

## 10. Known Residuals

- **The Julia SE axis on the q4 REML route stays fenced
  (`wald_unavailable`, #495).** `drm_bridge_objective_at` returns the
  objective/log-likelihood at a point only — it does not compute or expose
  standard errors, and the pre-existing SE fence on this route is
  unaffected by this slice.
- **This entry is diagnostic only; no promotion claim.** Per the PR body:
  "Diagnostic only; no promotion claim." It exists so drmTMB's A4/A5 shim
  can drop five private-name dependencies, not as a claim that the q4
  bridge route is promoted to any higher status.
- **`options` is accepted but not read on this route** — any fit-controlling
  key inside it (e.g. `method = "REML"`) has no effect here, by design; a
  caller that expects `options` to configure this diagnostic call will be
  silently ignored on those keys (not fail-closed on unknown `options`
  content, unlike the coef_labels echo slice's fail-closed contract — a
  narrower scope, since this route needs no dpar-shaped configuration).
- **The RED log's summary table does not individually confirm all 17
  GREEN-run assertions were also present and failing pre-fix** — 11 of the
  17 are directly evidenced in the captured RED log; the remainder are
  inferred to share the same `UndefVarError` root cause (the file could not
  have executed past the first `UndefVarError` for a not-yet-defined
  function on any code path that calls it), but this report does not claim
  a literal one-to-one RED tally for cases beyond what `objat-red.log`
  shows (§9).
- **No R-side end-to-end test is run from this repository.** The R call
  site is documented (`objat-r-note.md`, "The call to make instead") but
  not exercised here; its correctness rests on the drmTMB lane's own
  adoption and any receipts it produces separately.

## 11. Team Learning

- **When a test's expected value tracks a solver's true optimum, re-derive
  it explicitly (with history kept) the moment the solver changes, rather
  than loosening the tolerance to absorb the drift.** Commit `2500ab39`
  re-pins the Julia-point value to #575's corrected optimum in its own
  dedicated commit with an explanatory message, keeping the test's
  precision meaningful instead of widening `atol` to paper over a moving
  target.
- **A bridge/wrapper entry should be tested for equivalence against the
  primitive it delegates to, not only against an external reference.**
  Case (b)'s `atol = 1e-8` equivalence check against `reml_objective_at`
  isolates wrapper-introduced discrepancy from primitive-level accuracy,
  which the external cross-engine receipt (`atol = 2e-4`) alone cannot
  distinguish.
- **A diagnostic entry point's scope (what it does NOT configure, e.g.
  `options` here) is worth stating explicitly in the entry's own
  documentation** (`objat-r-note.md`) rather than leaving a caller to
  discover by trial that certain payload keys are silently inert on this
  route.

## 12. Cross-Product Coverage

This slice touches one new **supported, public** bridge entry
(`drm_bridge_objective_at`) on the **bivariate q=4 phylogenetic REML**
route specifically.

- **Covers ✓**: the cross-engine objective-at-a-point evaluation at both
  the TMB-fitted point and Julia's own REML optimum, reproducing the drmTMB
  A5 receipt at each (17/17, plus a dedicated re-verification post-#575 pin
  re-derivation, still 17/17); equivalence with the private
  `reml_objective_at` primitive it delegates to (`atol = 1e-8`); input
  validation for non-q4 payloads, wrong-length `beta`, and non-4×4
  `Lambda`; API-stability registration (188/188); regression on the
  formula-label surface (819/819) and the underlying primitive (5/5).
- **Does NOT cover ✗**: the Julia SE axis on the q4 REML route, which
  stays fenced (`wald_unavailable`, #495) and is untouched by this
  diagnostic entry; any promotion of the q4 bridge route's status (none
  claimed); any fit-controlling behaviour of `options` on this route
  (accepted but not read, by design); any R-side end-to-end exercise of
  the documented call site (`objat-r-note.md`); any route other than
  bivariate q=4 phylogenetic REML (explicitly rejected by the function's
  own route guard, tested directly).

## Memory receipt

No new hub `AGENTS.md` guard was added or consulted for this slice beyond
the after-task protocol (`~/shinichi-brain/protocols/after-task.md`). All
numbers in this report are copied from `git show e4647333 --stat` and `git
show -s --format=%B 2500ab39` (run in this worktree), `gh api
repos/itchyshin/DRM.jl/pulls/590 --jq .body`, the check-log row on `main`
(`docs/dev-log/check-log.d/2026-09-02-563-bridge-objective-at.md`), and
`scratchpad/objat-red.log` / `scratchpad/objat-green.log` /
`scratchpad/objat-merged3.log` / `scratchpad/objat-r-note.md` (all cited
inline above). Vault `~/shinichi-brain/memory/DECISIONS.md` D-203 §5
consulted directly for the approval record.
