# G0 — arc-loop: finish the DRM.jl ↔ drmTMB catch-up campaign

*Plan gate for `/arc-loop`. Supersedes this file's earlier contents (the A3 re-scope
plan, now executed: A0, A1, A2a, A3a, A3b, A3c design, A3c-1 all landed).*

## Context

The `engine = "julia"` catch-up campaign has been running semi-manually, one
approval per arc. You asked to run it as a proper arc-loop for ~10 hours. This
is the G0 gate: the arc list and the fence, for approval before anything runs.

**State now:** A0 (ledger) · A1 (vcov guard) · A2a (result-shape) · A3a
(`biv_lognormal`) · A3b (`biv_student`) · A3c design · A3c-1
(`gaussian_bernoulli`) are done. drmTMB **0.7.0 is installed**, QuadGK is a
dependency, and the FE non-Gaussian headline is **measured** through
`engine = "julia"`, not merely read. Countdown: **22 export gaps** (was 25).

**One thing is red.** `#410`'s `test (1)` genuinely fails — not a cancellation.
`test_bivariate_student.jl:38` asserts `isapprox(est, truth; atol = 0.25)` across
all 8 coefficients, but a 10-seed measurement shows `log(ν−2)` has **sd 0.154 and
max deviation 0.414**, against ≤ 0.042 / ≤ 0.080 for every other parameter. The
tolerance was fitted to one local run; a different RNG stream on Julia 1 crosses
it. My error, and the first arc fixes it.

## Preflight + sweep receipt (Phases 0.2 / 0.25)

| surface | evidence | finding |
|---|---|---|
| lane | `lane_preflight.sh` DRM.jl | no foreign lane; ours is the only one |
| drmTMB lane | `lane_preflight.sh` drmTMB | **9 lanes live, foreign codex active, release slice #959 open** → narrow lane only, and no auto-merge there |
| repo git | `git status`, `git log`, branch inspection | clean; work on `docs/a3c-design` stacked over `#410` |
| twin | `parity_ledger.py --ref origin/main` | 22 gaps · 11 rows · 14 gates; CLOSURE **PASS** |
| brain | `search_notes` + `grep DECISIONS/AGENT_LOG` | D-111 sets the bar; dr18/dr19 supply the bivariate contracts |
| anchor drift | `git rev-parse origin/main` | moved `f5ec53634` → `859c0f6e6` — re-run the ledger before trusting a count |

## 🎯 GOAL (this becomes `LOOP/GOAL.md`, immutable for the run)

```
Mission: close the measured drmTMB parity gaps in DRM.jl, each backed by a
  native-vs-Julia parity fixture, without ever claiming more than the twin does.
Headline: the ledger countdown falls; every capability shipped is parity-verified
  against installed drmTMB 0.7.0, and every boundary drmTMB declares is mirrored.
Definition of done: all in-fence arcs landed on main with green CI, the ledger
  re-run, and plan-vs-actual reconciled.
```

## Arc list

Ordered so the red branch clears first and cheap evidence lands early.

| id | arc | est | gate |
|---|---|---|---|
| **A-fix** | Drop `log(ν−2)` from the blanket recovery tolerance in `test_bivariate_student.jl`; ν stays covered by its own `3.5 < ν̂ < 10` range assertion, sized from the 10-seed spread. Unblocks **#410** | 0.5 h | no |
| **A3c-2** | The four quadrature pair classes (`gaussian_nbinom2`, `bernoulli_bernoulli`, `bernoulli_nbinom2`, `nbinom2_nbinom2`) using **QuadGK**, with per-row integration-error diagnostics | 1.5–2 d | no |
| **A3c-3** | `associate_pairs` parity fixture vs drmTMB 0.7.0 (now runnable locally) + diagnostic/warning parity | 0.5–1 d | no |
| **A-sigma** | `sigma()` contract → unblock `V_known` / meta post-fit (the A2a remainder). **Public API change**: today `sigma(fit)` returns a bare vector only when `scales` has exactly one key | 0.5–1 d | **[GATE]** design surfaced before landing |
| **A-drmtmb** | drmTMB **narrow-lane** registry extension (`docs/dev-log/evidence/2026-08-14-proposed-registry-extension.md` is already written and ready to apply) | 0.5 d | **[GATE]** opens PR, **never merges** |
| **A4a** | `categorical` family | ~1 d | no |
| **A4b** | Spatial mesh — `make_mesh`, `spatial_coords` | 1–1.5 d | no |
| **A4c** | Phylo penalty — `drm_phylo_penalty`, `drm_phylo_penalty_sweep` | ~1 d | no |
| **A4d** | Misc accessors — `profile_targets`, `rho_latent`, `structured_effects`, `corpair`, `meta_vcov_bivariate` | ~1 d | no |

Total well exceeds 10 hours; the loop runs the list in order and stops where it
stops. **A4a–A4d each get a short design pass first** (the A3c pass paid for
itself by finding the QuadGK dependency and the frozen-margin uncertainty trap).

## Gate policy

**DRM.jl:** push, open PR, **auto-merge on green CI** — your call this session.

**Structural fix for the failure mode I hit twice** (arming auto-merge, then
pushing more onto the branch, so later work rode an earlier approval):

- **One branch per arc.** No arc ever commits onto a branch that already has
  auto-merge armed.
- **Auto-merge is the last action on a branch**, after the final commit and only
  once the arc is complete.

**drmTMB:** narrow lane only (`R/julia-bridge.R`, `tests/testthat/test-julia-*`,
`vignettes/julia-engine.Rmd`). **Opens a PR and STOPS — no auto-merge, no merge.**
That repo has 9 live lanes and an open 0.7.0 release slice; merging into another
team's active release unattended is not covered by your DRM.jl precedent.

**Stop and surface** on: a genuine surprise that invalidates this plan; any
destructive/irreversible action; `sigma()`'s public contract before it lands.

## Fences (never crossed unattended)

`#136` stays OPEN — never a closer keyword near that number. `#49` PARKED. No
Registrator / Julia General (**D-111**). No GPL vendoring. Never regress the
verified q=4 core (2.18×, logLik −256.51). Never stage `.worktrees/` or
`.codex/agents/shannon-coordinator.toml`; never `git add -A` unscoped. No drmTMB
edits outside the narrow lane.

## Verification (per arc, non-negotiable)

- **Read the log, not the exit code.** Inspect the artifact.
- Targeted Julia suites during an arc (~2–5 min); **full suite at the PR boundary**
  via CI (`test (1)` + `test (1.10)` + `docs`).
- **`DRM_PARITY_TESTS=1` mandatory** on any arc touching `bf()` / formula grammar.
- **Every new capability gets a `tools/parity_fixture.R` cell** — native-vs-Julia,
  tolerance 1e-4 — and the cell must PASS before the arc closes.
- **Tolerances are measured, never guessed.** Multi-seed spread first, then set the
  bound from it. A-fix exists because I broke this rule once.
- Each arc closes with what it did **NOT** cover, plus a `check-log.d/` entry and
  an after-task report (`AGENTS.md` DoD).

## Workspace

`~/shinichi-brain/tools/lane_launch.sh DRM.jl catchup` → bounded worktree at
`~/local-scratch/lanes/DRM.jl-catchup` on `claude/lane-catchup`, off the Dropbox
path (which already produced one transient `.git/index.lock`). It scaffolds and
commits the LOOP/ kit; I fill `GOAL.md` from the block above and `arcs.md` from
the table, then emit the launch prompt for a **fresh session**.

## Reconciliation

At the end of the run, Melissa-style plan-vs-actual to
`docs/dev-log/plan-actual/<date>-arc-loop-catchup.md`: every arc's planned vs
actual scope, evidence, and anything skipped — tagged adaptive vs drift.
