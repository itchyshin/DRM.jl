# After-Task Report: echo drmTMB's coef_labels payload as the public bridge names, fail-closed (#563 slice 2b / design 258 §7)

- **Date:** 2026-09-02
- **Issue:** #563 slice 2b / design 258 §7
- **PR:** #594 (merge commit `be7b7ce5`; superseded draft #585, closed only because the GraphQL budget was exhausted and a draft cannot be marked ready over REST — same branch, same commit `db3ea7d4`)
- **Branch:** `feat/563-coef-labels-echo`
- **Perspectives:** Shannon (Coordination), Boole (Grammar), Hopper (Payload Shape), Rose (Gate)

## 1. Goal

Implement the Julia half of drmTMB design 258 §7 (`a17306295`): when R
sends `options["coef_labels"]`, echo those names verbatim and in order as
the public `coef_names`/`vcov_names` of `bridge_formula_labels_v1`, keeping
Julia's own spelling in `raw_coef_names` and a public→raw map in
`coef_name_map` — fail-closed on a count mismatch, an unknown dpar key, or
a dpar with columns but no labels.

## 2. Implemented

- **`_bridge_echo_coef_labels`** (new, `src/bridge.jl`), threaded through
  `_bridge_coef_vector`. Per dpar: if `options["coef_labels"]` supplies
  labels for that dpar, they are echoed verbatim and in order as the public
  names; without `coef_labels`, behaviour is unchanged (self-rendered
  base-R names from slice 2, unaffected).
- **Fail-closed guards**: a count mismatch between supplied labels and the
  dpar's actual column count, an unknown dpar key in the payload, or a
  fixed-effect dpar with columns but no supplied labels, each abort naming
  that dpar (and, per the commit's design, both counts are named in the
  error).
- **One `src/` file changed**: `src/bridge.jl`, +67 lines net (`git show
  be7b7ce5 --stat`).
- **`test/test_bridge_coef_labels_echo.jl`** (new, 145 lines): 5 RED cases
  against the pre-fix code, **28/28 GREEN** after.
- `test/test_bridge_base_r_names.jl` updated (+7/−0 net per the stat; PR
  body: "its payload case now supplies every dpar, as a real R caller
  does") so the earlier slice's payload case stays representative of a real
  caller under the new echo behaviour.
- `test/runtests.jl` (+1) wires the new test file in.

Full diffstat (`git show be7b7ce5 --stat`, this worktree): 5 files changed,
214 insertions(+), 7 deletions(-).

## 3a. Decisions and Rejected Alternatives

- **The wire field is `options["coef_labels"]`, drmTMB's choice, not
  DRM.jl's.** Design 258 §7 (`a17306295`) specifies this channel on the R
  side; this slice implements the Julia-side consumer of exactly that
  field. No alternative channel was built.
- **Fail-closed, not best-effort, on every malformed input.** A count
  mismatch, an unknown dpar key, or a dpar with columns but no labels each
  abort rather than silently falling back to self-rendered names or padding
  — chosen so a caller-side bug in constructing the payload surfaces
  immediately rather than shipping mismatched coefficient names silently.
  The RED test evidence (§6) shows these abort paths were unimplemented
  before this slice (raising an unrelated `BoundsError` instead of the
  intended, named `ArgumentError`-style abort).
- **The `<dpar>_<name>` prefix form was adopted, and confirmed against the
  R-side comparator rather than assumed.** The PR body records the drmTMB
  lane's confirmation (R side `f0b7c4da9`,
  `drm_julia_bridge_check_coef_labels()`): "public names go through
  `drm_julia_split_coef_name()` and the comparison is the bare per-dpar
  term vectors *after* the split, so the `<dpar>_<name>` form emitted here
  is exactly what R expects; a bare echo would abort every fit." A bare
  (unprefixed) echo was therefore rejected as a design option because it
  would fail on the R side, not merely because it seemed less explicit.
  Variance-component blocks are excluded on both sides by prefix.
- **Base is `main` with #593 already merged** (PR body: "Base is `main`
  (#584 merged as #593)"), i.e. this slice builds directly on slice 2's
  base-R rendering rather than on an intermediate branch state.

## 4. Files Touched

Merge commit `be7b7ce5` (`git show be7b7ce5 --stat`, this worktree):

- `docs/dev-log/check-log.d/2026-09-02-563-coef-labels-echo.md` (+1)
- `src/bridge.jl` (+67/− some; net line per stat)
- `test/runtests.jl` (+1)
- `test/test_bridge_base_r_names.jl` (+7/−0 net)
- `test/test_bridge_coef_labels_echo.jl` (+145, new file)

5 files changed, 214 insertions(+), 7 deletions(-).

This report (written by Rose, not counted in the merge diffstat above):

- `docs/dev-log/after-task/2026-09-02-563-coef-labels-echo.md`

(The check-log row for this slice was already written and merged as part of
PR #594 itself, per the diffstat above.)

## 5. Checks Run

- **RED, pre-fix code** (`scratchpad/echo-red.log`, worktree
  `wt-563-echo`): `ERROR: LoadError: Some tests did not pass: 15 passed, 2
  failed, 3 errored, 0 broken.` Full per-case breakdown:
  ```
  bridge coef_labels echo (design 258 §7, #563)                  | Pass 15  Fail 2  Error 3  Total 20  | 22.4s
    (a) echo: verbatim public names, raw stays Julia's own       | Pass 10  Fail 1                Total 11 | 17.2s
    (b) count mismatch aborts, naming dpar and both counts       |                    Error 1      Total 1  | 0.6s
    (c) unknown dpar key aborts, naming it                       |                    Error 1      Total 1  | 0.0s
    (c2) a dpar with columns but no labels aborts, naming it     |                    Error 1      Total 1  | 0.0s
    (d) absent coef_labels: identical map to today                | Pass 3                          Total 3  | 0.0s
    (e) bivariate model: echo across mu1/mu2/sigma1/sigma2/rho12 | Pass 2   Fail 1                Total 3  | 4.6s
  ```
  Case (a)'s failure: `out["coef_names"] == ["mu_(Intercept)", "mu_x",
  "mu_I(x^2)", "sigma_(Intercept)"]` (no echo happened) against the
  expected renamed vector. Cases (b)/(c)/(c2) errored with `BoundsError:
  attempt to access Tuple{Symbol, Dict{String, Any}} at index [3]` — i.e.
  the fail-closed abort paths did not exist yet and the code hit an
  unrelated destructuring error instead of a controlled abort. Case (e)
  failed identically to (a) (no echo across the bivariate dpars).
- **GREEN, patched code** (`scratchpad/echo-green.log`):
  ```
  bridge coef_labels echo (design 258 §7, #563) | Pass 28 Total 28 | 24.0s
  BRIDGE_COEF_LABELS_ECHO_DONE
  ```
- **Neighbours, patched code** (`scratchpad/echo-neighbours.log`):
  ```
  bridge formula-derived coefficient labels                        | Pass 819 Total 819 | 43.9s
  BRIDGE_FORMULA_LABELS_PASS
  bridge base-R coefficient names (design 258 §2, RED measurement) | Pass 20  Total 20  | 8.3s
  BRIDGE_BASE_R_NAMES_DONE
  ```
- **Check-log row** (`docs/dev-log/check-log.d/2026-09-02-563-coef-labels-echo.md`,
  on `main`): "✅ green; `options["coef_labels"]` echoed verbatim per dpar
  as the public names, fail-closed on count / unknown dpar / missing dpar;
  approved PR-gated (D-203 §3b); prefix form (`<dpar>_<name>`) to be
  confirmed by the drmTMB lane" — Shannon (Boole, Hopper).
- **Prefix form independently confirmed by the drmTMB lane** (PR body): R
  side `f0b7c4da9`, `drm_julia_bridge_check_coef_labels()`, validated
  against `drm_julia_split_coef_name()`'s split of the `<dpar>_<name>`
  form.

## 6. Tests of the Tests

`test/test_bridge_coef_labels_echo.jl` is RED-first with a specific,
diagnostic failure mode, not a vacuous pass: on the pre-fix code, the echo
case (a) failed by returning Julia's own self-rendered names instead of the
supplied labels (proving the echo did not yet exist), and the three
fail-closed abort cases (b, c, c2) did not fail as clean, named aborts —
they errored with a generic `BoundsError` from destructuring an
unhandled-shape tuple, i.e. the fail-closed guard logic itself did not
exist yet, not merely that it silently passed through. After the fix, all
five case groups pass together (28/28) with no change to the neighbour
surfaces (819/819, 20/20) that exercise the self-rendering and formula-
label paths the echo sits on top of — evidence the echo is additive to,
not a replacement for, the base-R self-rendering from slice 2.

## 7a. Issue Ledger

- **#563 slice 2b / design 258 §7** — landed on
  `feat/563-coef-labels-echo`, PR #594 merged as `be7b7ce5`. Approved
  PR-gated by the maintainer (D-203 §3b,
  `~/shinichi-brain/memory/DECISIONS.md:7372`, item 3(b): "the label-map
  echo in `src/bridge.jl` (payload-supplied base-R names echoed under
  `bridge_formula_labels_v1`; producer stub already at
  `src/bridge.jl:1276`; contract = drmTMB design 258 §7, per D-202 #4)").
  Review named in the PR body: Boole (grammar) + Rose (fail-closed scope).
  Merge is the maintainer's.
- No new issues opened by this slice, per the sources read for this
  report.

## 8. Consistency Audit

- **All three fail-closed conditions named in the task were implemented
  and tested together, not just the headline "count mismatch" case**:
  count mismatch (case b), unknown dpar key (case c), and a dpar with
  columns but no labels (case c2) each have their own RED case and their
  own passing GREEN case.
- **The bivariate case (mu1/mu2/sigma1/sigma2/rho12) was swept, not just
  the univariate mu/sigma case** — case (e) exercises the echo across all
  five dpars of a bivariate model, catching the same "no echo happened"
  failure mode as the univariate case (a) before the fix.
- **The "absent `coef_labels`" behaviour was explicitly re-verified
  unchanged** (case d, 3/3 pass in both RED and GREEN) — confirming the new
  echo path does not alter the no-payload default that slice 2's base-R
  self-rendering already established.
- **The prefix form was checked against the actual R-side consumer, not
  assumed correct from the Julia side alone** — the PR body records
  independent confirmation via the drmTMB lane's own validator
  (`drm_julia_bridge_check_coef_labels()`, R commit `f0b7c4da9`).

## 9. What Did Not Go Smoothly

- **Draft #585 had to be superseded by #594** for the same reason as
  slice 2's draft #584 → #593: the GraphQL budget was exhausted and a
  draft PR cannot be marked ready for review over the REST API alone —
  same branch, same commit `db3ea7d4`, no rework.
- **The pre-fix fail-closed paths errored with a generic, unhelpful
  `BoundsError`** (`attempt to access Tuple{Symbol, Dict{String, Any}} at
  index [3]`) rather than any recognisable "not implemented yet" signal —
  the RED log (§5, §6) documents this as the actual failure mode the fix
  replaced with named, controlled aborts.

## 10. Known Residuals

- **The `options` channel is the wire field by drmTMB's choice
  (`a17306295`)**, not something re-derived or chosen independently in
  this slice — DRM.jl implements the consumer side of a contract set on
  the R side.
- **No test of an R-side caller here.** This slice's evidence is entirely
  Julia-side (28/28 plus neighbours); the prefix form's correctness against
  the actual R call site is attested by the drmTMB lane's own commit
  (`f0b7c4da9`) and validator, not exercised end-to-end from this
  repository.
- **Row 7 of design 258 and the `sd_` raw-name residual from slice 2 are
  unchanged by this slice** — see
  `docs/dev-log/after-task/2026-09-02-563-bridge-base-r-names.md` §10; this
  slice only adds the echo path on top of that self-rendering.

## 11. Team Learning

- **A fail-closed contract is only as good as its own test coverage of the
  failure paths, not just the success path.** The RED evidence here shows
  the three abort conditions were not merely "not yet implemented" in a
  silent sense — the code actively hit an unrelated, confusing error
  (`BoundsError` on tuple destructuring) that would have been a poor
  diagnostic for a real R caller. Writing the RED cases first surfaced that
  the abort paths needed dedicated implementation, not just a guard clause
  bolted onto existing logic.
- **Confirm a wire-format assumption (here, the `<dpar>_<name>` prefix)
  against the actual consumer before treating it as settled**, even when
  it seems like the obvious choice — the PR body frames this explicitly as
  something "confirmed," with a named R-side commit and validator, not
  merely asserted.

## 12. Cross-Product Coverage

This slice touches the **bridge's public coefficient-name echo path**
(`_bridge_echo_coef_labels`) layered on top of slice 2's self-rendered
base-R names, across every dpar of both univariate and bivariate models.

- **Covers ✓**: the echo itself (verbatim, in order, per dpar); all three
  fail-closed conditions (count mismatch, unknown dpar key, dpar with
  columns but no labels); the no-payload default (unchanged); the bivariate
  case across mu1/mu2/sigma1/sigma2/rho12; regression coverage on the
  formula-label surface (819/819) and slice 2's base-R names (20/20,
  updated to supply every dpar in its payload case).
- **Does NOT cover ✗**: any R-side caller or end-to-end R↔Julia round trip
  (Julia-side tests only; R-side confirmation is attested by the drmTMB
  lane's own commit, not exercised here); the `sd_` raw-name / row-7
  residuals carried over unchanged from slice 2; any numeric/fit-path
  change (the PR body: "No numeric path touched").

## Memory receipt

No new hub `AGENTS.md` guard was added or consulted for this slice beyond
the after-task protocol (`~/shinichi-brain/protocols/after-task.md`). All
numbers in this report are copied from `git show be7b7ce5 --stat` (run in
this worktree), `gh api repos/itchyshin/DRM.jl/pulls/594 --jq .body`, the
check-log row on `main`
(`docs/dev-log/check-log.d/2026-09-02-563-coef-labels-echo.md`), and
`scratchpad/echo-red.log` / `scratchpad/echo-green.log` /
`scratchpad/echo-neighbours.log` (all cited inline above). Vault
`~/shinichi-brain/memory/DECISIONS.md` D-203 §3b consulted directly for the
approval record.
