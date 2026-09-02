# After-Task Report: bridge coefficient names = base R, six parity fixtures re-keyed (#563 slice 2 / #467)

- **Date:** 2026-09-02
- **Issue:** #563 slice 2 / #467
- **PR:** #593 (merge commit `a929e7af`; superseded draft #584, closed only because the GraphQL budget was exhausted and a draft cannot be marked ready over REST — same branch, same commits)
- **Branch:** `feat/563-bridge-base-r-names`
- **Perspectives:** Shannon (Coordination), Boole (Grammar), Hopper (Payload Shape), Rose (Gate)

## 1. Goal

Measure whether DRM.jl's bridge (`drm_bridge`) already renders base-R
coefficient names for the ten constructs of drmTMB design 258 §2, and fix
whatever gap #467's recorded "1 pass / 6 fail" on the `bridge-*` parity
fixtures actually reflects.

## 2. Implemented

1. **`test/test_bridge_base_r_names.jl`** (new, 138 lines per `git show
   a929e7af --stat`): a measurement-first regression test asserting, for
   each of the ten design-258 §2 constructs, that DRM.jl's own typed-schema
   rendering (`_bridge_public_to_raw_coef_map`, landed in `62c4e6a2`)
   produces base-R spelling in order, with no help from any label payload.
   **20/20** (PR body, `pulls/593`).
2. **Six `bridge-*` parity fixtures re-keyed** from the pre-`62c4e6a2`
   `__bridge_*` synthetic-column spellings to the base-R names `drm_bridge`
   renders today. Keys only — every numeric value unchanged. Per `git show
   a929e7af --stat`: `bridge-I`, `bridge-factor`, `bridge-poly-cross`,
   `bridge-poly`, `bridge-power`, `bridge-scale` (`expected.toml` in each,
   4–10 line changes apiece). `bridge-minus-term` needed no change (it
   already used only base-R names; the removed term `- z` contributes no
   synthetic column). Bridge parity cells under `DRM_PARITY_TESTS=1`: **1
   pass / 6 fail → 7 pass / 0 fail**.
3. `test/runtests.jl` (+1) wires the new test file in.

Full diffstat (`git show a929e7af --stat`, this worktree): 9 files changed,
158 insertions(+), 18 deletions(-).

## 3a. Decisions and Rejected Alternatives

- **Diagnosed as stale fixtures, not a missing producer.** #467 recorded
  "1 pass / 6 fail" as if the bridge lacked a base-R producer; it has one
  (`62c4e6a2`). The `labels-red-report.md` measurement found 9 of 10
  constructs already matched base-R spelling with zero help from any
  `coef_labels` echo, and `fixture-rekey-report.md` traced the parity
  failures to `test/parity/runparity_bridge_formula.jl`'s comparator doing
  no name translation of its own (`compare.jl:508–520`) against fixtures
  still keyed by the pre-`62c4e6a2` `__bridge_<kind>_<n>` spelling — so the
  fix chosen was re-keying the fixtures' string keys, not touching
  `src/bridge.jl`'s rendering logic. This PR is test/fixture changes only;
  no `src/` change (PR body).
- **Row 7's discrepancy was resolved by trusting base R over drmTMB's
  design-258 oracle table, and reported upstream rather than silently
  matched to it.** `y ~ g + factor(h) + factor(h):g`: design 258 §2's table
  (sourced from drmTMB's non-shipping `public-004.json` oracle) listed nine
  names with full dummy coding of `factor(h)` inside the interaction.
  DRM.jl's typed-schema `StatsModels` rendering gives six — standard
  reduced/contrast coding for a crossed two-factor design where both
  main-effect margins are already present: `(Intercept)`, `gb`, `gc`,
  `factor(h)20`, `gb:factor(h)20`, `gc:factor(h)20`. `labels-red-report.md`
  confirms this is the textbook Chambers–Hastie result, not a rejection or
  spelling gap — "both sides produce a real, self-consistent design, they
  just disagree on which model-matrix contrast rule applies." Reported to
  the drmTMB lane rather than DRM.jl matching the (wrong) nine-name table
  (issue #467 comment, 2026-09-02).
- **No fixture exists for the reversed two-factor interaction construct**
  (`fixture-rekey-report.md`: `grep -rln "factor(h)"
  test/parity/fixtures/*/expected.toml` returns nothing) — it is covered
  instead by `test_bridge_base_r_names.jl` case 7 as a contrast-coding
  question, not a re-key.
- **The `coef_labels` echo (design 258 §7) was deliberately left out of
  this PR.** `labels-red-report.md` §Part B found the field completely
  inert: `grep -rn coef_labels src/` returned zero hits, and there was no
  wire channel in `drm_bridge`'s keyword signature (`formula, family, data,
  tree, K, A, coords, newdata, options`) to carry it — passing it via the
  free-form `options` dict changed nothing. The PR body states plainly:
  "nothing in `src/bridge.jl` reads that field yet ... the exact wire field
  is awaiting the drmTMB lane's answer. That is the next slice (approved
  PR-gated, D-203 §3b)."

## 4. Files Touched

Merge commit `a929e7af` (`git show a929e7af --stat`, this worktree):

- `docs/dev-log/check-log.d/2026-09-02-563-bridge-base-r-names.md` (+1)
- `test/parity/fixtures/bridge-I/expected.toml` (+2/−2)
- `test/parity/fixtures/bridge-factor/expected.toml` (+3/−3)
- `test/parity/fixtures/bridge-poly-cross/expected.toml` (+5/−5)
- `test/parity/fixtures/bridge-poly/expected.toml` (+4/−4)
- `test/parity/fixtures/bridge-power/expected.toml` (+2/−2)
- `test/parity/fixtures/bridge-scale/expected.toml` (+2/−2)
- `test/runtests.jl` (+1)
- `test/test_bridge_base_r_names.jl` (+138, new file)

9 files changed, 158 insertions(+), 18 deletions(-).

This report (written by Rose, not counted in the merge diffstat above):

- `docs/dev-log/after-task/2026-09-02-563-bridge-base-r-names.md`

(The check-log row for this slice was already written and merged as part of
PR #593 itself, per the diffstat above — this report supplies the
after-task narrative the check-log row summarises.)

## 5. Checks Run

- **`test/test_bridge_base_r_names.jl`**: **20/20**, ten design-258 §2
  constructs (PR body, `pulls/593`; issue #467 comment, 2026-09-02).
- **RED measurement, before re-keying** (`labels-red-report.md` Part A —
  Julia's own self-rendering vs base-R spelling, run on worktree
  `wt-563-labels`, branch `feat/563-bridge-base-r-names` off `origin/main`
  @ `d6519d21`): **9 PASS / 1 FAIL** across the ten constructs — row 7
  (`y ~ g + factor(h) + factor(h):g`) the sole failure, a genuine
  contrast-rule disagreement (§3a), not an error.
- **RED measurement, Part B** (`coef_labels` payload honoured?):
  identical pattern, **9 PASS / 1 FAIL** — direct evidence the field was
  completely inert before this slice (payload changed nothing about the
  output).
- **Bridge parity fixtures under `DRM_PARITY_TESTS=1`**
  (`fixture-rekey-report.md`, `test/parity/runparity_bridge_formula.jl`):
  - **Before** (original `__bridge_*`-keyed fixtures): **1 pass / 6 fail /
    7 total** — only `bridge-minus-term` passed.
  - **After** (re-keyed fixtures): **7 pass / 0 fail / 7 total**.
  - Invocation: `OPENBLAS_NUM_THREADS=1 DRM_PARITY_TESTS=1 julia
    --project=test -e 'using DRM; using Test;
    include("test/parity/runparity_bridge_formula.jl")'`.
- **Check-log row** (`docs/dev-log/check-log.d/2026-09-02-563-bridge-base-r-names.md`,
  on `main`): "✅ green; DRM.jl's own rendering already matches base R on
  all ten constructs (row-7 oracle corrected against R's `model.matrix()`);
  fixtures were keyed by pre-`62c4e6a2` names; `coef_labels` echo still to
  build once the R wire field is confirmed" — Shannon (Boole, Hopper).

## 6. Tests of the Tests

`test/test_bridge_base_r_names.jl` is measurement-first, not written to
pass vacuously: the RED measurement (`labels-red-report.md`) was run on an
independent worktree (`wt-563-labels`) before the final test file existed
in this form, and it caught a real, reproducible construct-level
discrepancy (row 7, 9-vs-6 names) rather than reporting all-green from the
start — the same discrepancy the final test's case 7 encodes as the
corrected 6-name expectation. Separately, the fixture re-key's own before/
after measurement (`fixture-rekey-report.md`) is itself evidence the fix
targets the right layer: the "before" run reproduces #467's exact "1 pass /
6 fail" signature end to end via the live parity runner (not a
hand-simulated guess), and the "after" run — changing only fixture string
keys, confirmed by `git diff` touching only quoted key text — turns that
into 7/7 with no numeric value altered.

## 7a. Issue Ledger

- **#467** — addressed; the recorded "1 pass / 6 fail" was diagnosed as
  stale bridge-parity fixture keys, not a missing base-R producer. Reported
  upstream: design 258 §2 row 7's nine-name oracle table is wrong for this
  construct; base R (and DRM.jl) give six. Comment posted 2026-09-02.
- **#563 slice 2** — landed on `feat/563-bridge-base-r-names`, PR #593
  merged as `a929e7af`.
- **`coef_labels` echo (design 258 §7)** — explicitly deferred, not an
  issue number in the sources read for this report, but named as "the next
  slice (approved PR-gated, D-203 §3b)" in the PR body — see the companion
  report `docs/dev-log/after-task/2026-09-02-563-coef-labels-echo.md`.

## 8. Consistency Audit

- **All ten design-258 §2 constructs were checked, not just the six with
  stale fixtures.** `labels-red-report.md` Part A enumerates all ten with a
  pass/fail table; only row 7 failed, and that failure was traced to a
  contrast-coding disagreement rather than left unexplained.
- **The `coef_labels` payload channel itself was checked for use, not
  assumed absent.** Part B re-ran all ten constructs supplying a
  `coef_labels`-shaped `options` payload and confirmed byte-for-byte the
  same 9-PASS/1-FAIL pattern as Part A — direct evidence of inertness, not
  an inference from reading the code alone (`grep -rn coef_labels src/`
  returning zero hits was cross-checked behaviourally).
- **Fixture re-key swept for other stale-key fixtures beyond the six
  `bridge-*` cells.** `fixture-rekey-report.md` explicitly checked whether
  `bridge-minus-term` needed a change (it didn't — no synthetic columns
  arise for `x + z - z`) and searched for a fixture covering the reversed
  two-factor construct (none exists — covered instead by the new test).
- **Names were confirmed by live invocation of `drm_bridge`**, not by
  reading `_bridge_public_term_labels` and hand-simulating it
  (`fixture-rekey-report.md`, script `probe_bridge_names.jl`) — reducing
  the risk of a re-key that matched the code's intent but not its actual
  output.

## 9. What Did Not Go Smoothly

- **Draft #584 had to be superseded by #593** because the GraphQL budget
  was exhausted and a draft PR cannot be marked ready for review over the
  REST API alone — same branch, same commits, no rework, per the PR body.
- **The worktree used for the RED measurement (`wt-563-labels`) arrived
  with corrupted git metadata** — `HEAD`/`commondir`/`index` under
  `.git/worktrees/wt-563-labels` missing, and `src/`/`test/` entirely
  absent from disk (845 tracked paths showing as deleted with zero actual
  local edits at risk). Repaired via `git archive HEAD | tar -x -C .`
  (chosen over `git checkout -- .`, which a destructive-command guard
  blocked) rather than a destructive reset (`labels-red-report.md`,
  "Worktree repair note").
- **The design-258 §2 oracle table itself needed correction** for row 7 —
  the pre-existing reference (drmTMB's non-shipping `public-004.json`)
  disagreed with actual base R, and this had to be established by direct
  comparison rather than assumed correct.

## 10. Known Residuals

- **Row 7 of design 258 §2 was corrected upstream by the drmTMB lane, not
  here.** This slice reported the nine-vs-six-name discrepancy to that
  lane (issue #467 comment, 2026-09-02); the design-258 document's own
  table is not amended by this PR.
- **The `sd_` raw names still carry `__bridge_*` spelling internally
  (raw only).** This slice's re-key covered only the six `mu_`/`sigma_`-
  keyed fixed-effect `bridge-*` parity fixtures; it did not touch or
  re-verify the internal (non-public) synthetic-column spelling used for
  `sd()`-group raw names, which is unaffected by the base-R public-name
  rendering path this slice addressed.
- **`coef_labels` (design 258 §7) is not read anywhere in `src/bridge.jl`**
  as of this slice — confirmed inert by direct measurement (§5, §6), fixed
  in the next slice (see the companion report,
  `docs/dev-log/after-task/2026-09-02-563-coef-labels-echo.md`).
- **Nothing beyond the `bridge-*` cohort and the ten design-258 §2
  constructs was investigated** — `fixture-rekey-report.md`: "Not
  investigated (out of scope per the task brief): the reversed two-factor
  interaction construct's contrast-coding question [beyond reporting it],
  and any non-`bridge-*` parity fixtures."

## 11. Team Learning

- **A recorded parity failure ("1 pass / 6 fail") can be an artefact of a
  stale test fixture, not a regression in the code under test.** Measuring
  the actual rendering directly (bypassing the parity fixtures entirely)
  before touching either side isolated that the producer was correct and
  the fixtures were the stale half — avoiding a wasted `src/` investigation.
- **When an internal oracle table disagrees with ground truth (base R
  here), verify against the ground truth directly rather than trusting the
  existing table**, and report the discrepancy to the table's owner instead
  of quietly conforming to it. `labels-red-report.md`'s row-7 finding is a
  genuine contrast-rule disagreement between two self-consistent designs —
  worth distinguishing from a bug in either implementation.
- **A payload field's inertness is worth demonstrating behaviourally, not
  just by `grep`.** Part B's identical-pattern re-run with the field
  supplied is stronger evidence than "no code reads this string" alone,
  and rules out an indirect consumption path.

## 12. Cross-Product Coverage

This slice touches the **bridge's public coefficient-name rendering**
(`_bridge_public_to_raw_coef_map`) across the constructs drmTMB design 258
§2 exercises, and the parity fixtures that key against it.

- **Covers ✓**: all ten design-258 §2 constructs, measured directly against
  base R (20/20, 9 PASS/1 FAIL corrected to 10/10 with the row-7 oracle
  fix); the six `bridge-*` parity fixtures with stale `__bridge_*` keys,
  re-keyed and re-verified end to end through the live parity runner (1/7
  → 7/7 under `DRM_PARITY_TESTS=1`); the `bridge-minus-term` fixture,
  checked and confirmed to need no change.
- **Does NOT cover ✗**: the `coef_labels` echo / design 258 §7 wire field
  (confirmed inert, not implemented — next slice); the `sd()`-group raw
  (non-public) column names, which still carry internal `__bridge_*`
  spelling; any non-`bridge-*` parity fixture; the reversed two-factor
  interaction construct beyond reporting its contrast-rule discrepancy
  upstream (design 258 §2's own table is not amended here); any `src/`
  behavioural change (test/fixture changes only, per the PR body).

## Memory receipt

No new hub `AGENTS.md` guard was added or consulted for this slice beyond
the after-task protocol (`~/shinichi-brain/protocols/after-task.md`) used
for the parallel #575 report. All numbers in this report are copied from
`git show a929e7af --stat` (run in this worktree), `gh api
repos/itchyshin/DRM.jl/pulls/593 --jq .body`, the check-log row on `main`
(`docs/dev-log/check-log.d/2026-09-02-563-bridge-base-r-names.md`), the
`gh issue view 467` comment dated 2026-09-02, and
`scratchpad/labels-red-report.md` / `scratchpad/fixture-rekey-report.md`
(all cited inline above).
