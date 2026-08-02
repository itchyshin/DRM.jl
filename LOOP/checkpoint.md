GOAL: Arc 0's immutable contract is retained in GOAL.md. STATE: Arc 0 and its
bounded Arc 1 documentation continuation are closed.
ARCS DONE (verified): 0 — design boundary, p=8/nrep=3 baseline record, and
report-contract test; 1 — static finite-difference route count and candidate
acceptance gates. PR #361 is open with CI pending.
ARC IN PROGRESS: none.
LANE C: LOOP freeze, check-log, after-task, and Rose claim fence recorded.
**PASS (Arc 0)**: the committed harness emitted a Markdown artifact read at
`/tmp/reml-arc1-baseline.md`; both small-fixture fits converged and the artifact
records `interval_status=not_evaluated`. The focused contract test passed 13/13.
These are baseline-harness facts, not a speed or AI-REML result.
**PASS (Arc 1)**: the static baseline route has 11 outer coordinates for this
fixture and uses up to 23 restricted-objective/mode evaluations per gradient
request before line-search calls. This is a structural count, not a speed result.
NEXT: review stacked PR [#362](https://github.com/itchyshin/DRM.jl/pull/362)
against `feat/291-reml-baseline-ladder`; the next implementation, if approved,
is report-only evaluation-count instrumentation with a contract test.
OPEN GATES (need human): merging either PR; public speed / AI-REML claim; heavy compute.
TRUTH LIVES IN: Arc 0 PR #361 @ `980a6f7`; Arc 1 PR #362 @ `f1539c8`
(stacked). The immutable Arc 0 contract is `LOOP/GOAL.md`; `LOOP/arcs.md` is
the live arc ledger.
RESUME: You are Ada continuing DRM.jl issue #291 after Arc 1. Read
`LOOP/GOAL.md` → `LOOP/checkpoint.md` → `LOOP/arcs.md` → `AGENTS.md`; do only
the next explicitly approved report-instrumentation or candidate-validation
slice. Do not touch
`src/`, prototypes, #136, bridge APIs, `.worktrees/`, General, or Registrator.
