# Ultra-plan — DRM.jl #372: measured wall-clock for six #370 bridge cells

**Status:** G0 **APPROVED** 2026-08-03 (Shinichi). `/goal` executing.
Written by Shannon (Ada + Rose + Curie). Plan frozen; execution follows arc ladder.

**Issue:** https://github.com/itchyshin/DRM.jl/issues/372  
**Prior lane:** #370 arcs 0–4 **complete**; PR #371 open (docs green;
`test (1)` / `test (1.10)` still pending at plan time — **merge left OPEN GATE**).  
**Human review link:** this file  
**Operational copies:** `LOOP/ultra-plan.md`, `LOOP/GOAL.md`, `LOOP/arcs.md`,
`LOOP/checkpoint.md`

---

## 🎯 GOAL (paste-ready — copy verbatim into a fresh session to resume this plan)

```
SOLO PLATFORM: Cursor (this session is running in Cursor; after G0 approval,
execution hands to /goal — do not continue Phase 3 in the planning chat).

DELIVERABLE: Close DRM.jl #372 — replace the six #370-bridge fixture cells'
"timing not measured — no claim" with a retained measured wall-clock artifact
(Julia drm_bridge and/or native drm vs local drmTMB on the same fixtures),
then update docs/src/r-julia-bridge.md claim surface to match the artifact
only; PR closes #372.

HEADLINE: Make the twin-mission speed story auditable for the six families
the bridge already admits — measured edge or honest no-claim with reason —
without inventing timings or re-using the q=4 2.18× cell.

IN PARALLEL (cheap): Arc-0 probe of local drmTMB version + one-cell smoke
refit; inventory of existing bench/R compare scripts for reuse patterns;
Rose fence checklist (method/machine/versions/BLAS/threads).

DEFER (fenced, do not touch): R-side Lovelace glue / drmTMB engine="julia"
edits; Registrator / Julia General (D-111); AI-REML / :natgrad / #291 accel;
GPL vendoring of drmTMB source; src/ q=4 engine regressions of verified
logLik −256.51 / 2.18×; ROADMAP nrep=4 / p>100 head-to-head (later issue);
#202 non-Gaussian phylo location-scale; #136 VA; xfam-external-gllvm;
leave .worktrees/ alone / never stage; do not reopen #370 implementation.

DISCIPLINE: verify with retained evidence file + local re-read of numbers;
compute = local Julia + local drmTMB R arm (Totoro only if local R blocked —
ask before remote); closure = PR closes #372 with docs honesty + check-log.d
+ after-task + Rose claim-vs-evidence. Rose: no "Nx faster" without retained
artifact; prefer drmTMB v0.1.3 for R arm, else record exact version.
```

---

## Phase 0 — Orient

**One-sentence goal:** turn the six-cell timing no-claim into a Rose-auditable
measured wall-clock artifact (or honest blocked per-cell reasons).

**#370 status (honest):** Arcs 0–4 **implementation/DoD done**. PR #371
https://github.com/itchyshin/DRM.jl/pull/371 is **OPEN / MERGEABLE**; Documenter
**pass**; CI `test (1)` + `test (1.10)` **still in progress** at plan write —
**not merged**. Do not start a second #370 lane.

**Tip → this lane:** after G0 yes, new branch from `origin/main` (or from
merged #371 tip if already on main). Do not continue coding on
`feat/370-bridge-fixture-parity` for this issue.

```
$ git status -sb
## feat/370-bridge-fixture-parity...origin/feat/370-bridge-fixture-parity
?? .worktrees/                      ← untracked, fenced, leave alone

$ bash ~/shinichi-brain/tools/branch_drift_check.sh
branch feat/370-bridge-fixture-parity vs origin/main: 2 ahead, 0 behind  ok
```

---

## Phase 0.25 — Prior-work sweep (RECEIPT) — gate before decompose

| Surface | Command / query run | Finding | Call |
|---|---|---|---|
| **Repo git state** | `git status -sb`; `git log --oneline -15`; `git worktree list`; `branch_drift_check.sh` | On `feat/370-bridge-fixture-parity` @ `b1e5359` (**2 ahead / 0 behind** `origin/main`); #370 commits + docs H1 fix; many unrelated `.worktrees/` — **do not touch**; PR #371 open, tests pending | **Do not resume #370 code**; after G0 start **new branch** for #372 from main/#371 tip when ready |
| **Twin (drmTMB)** | `ls …/drmTMB`; `Rscript -e 'packageVersion("drmTMB")'` | Twin repo present; **local installed drmTMB = 0.6.0** (not the v0.1.3 parity pin). Fixtures remain v0.1.3-generated numbers | **Measure R arm with recorded version**; prefer pin/refit under v0.1.3 if available; **no drmTMB source edits / no GPL vendor** |
| **Brain** (`search_notes`, `search_all_projects: true`) | `"DRM.jl twin mission measured speed parity bridge timing head-to-head"`; `"DRM.jl measured wall-clock six bridge cells after 370"` | Hits: #370 timing no-claim; comparison-grid extrapolated-p fence; prior phylo/crossed measured benches; D-111 live | **Reuse** Rose speed fence + bench CPU-aware patterns; **build** six-cell retained artifact; **fence** D-111 / p>100 |
| **External prior art** | Not commissioned | No novelty claim — measurement / claim-honesty slice | **N/A** |

**Code / doc evidence:**

| Claim | Evidence |
|---|---|
| Six cells coef-parity via `drm_bridge` | #370 after-task; `runparity_bridge.jl`; PR #371 |
| Timing explicitly no-claim | `docs/dev-log/evidence/2026-08-03-370-timing-no-claim.md`; bridge docs note |
| Fixtures lack timing metadata | prior #370 sweep: no wall-clock keys in `expected*.toml` |
| Measured-bench patterns exist | `bench/R/compare_*.R`; phylo/crossed reports; `threaded_bootstrap_demo.jl` (different estimand) |
| p>100 still extrapolated | `ROADMAP.md` open research; `report/comparison-grid.md` |

**Verdict:** **build-the-gap** for a **new** issue/branch. Reuse fixtures + Rose fence + bench timing discipline. Genuine new work = protocol + six-cell retained artifact + docs claim update. Not a rebuild of #370.

---

## Phase 0.3 / 0.3b — Model roster + Cursor two-bar

- **PLATFORM:** Cursor (owner instruction).
- **Bar habit:** scout/recon on Cursor Models (Composer); judgment / Rose on
  Other Models (Auto Cost / pinned Claude|GPT) if needed; after G0 hand
  execution to `/goal` (not continue Phase 3 in planning chat).
- Two-bar glance: not read live in this subagent; Ada default = keep Composer
  for mechanical probe/timing scripts, judgment for claim language.

---

## Phase 0.4 — TEAM RAISED (dialogue at G0)

```
TEAM RAISED
  Ada    — Next twin rung after #370 is the documented timing gap, not p>100
           or bootstrap. Size ~3–5 h. · Prefer six-cell measured artifact. ·
           Default if judgment: approve #372 as written.
  Rose   — Local drmTMB is 0.6.0 vs fixture pin 0.1.3 — version mismatch can
           poison a speed claim. · Must record version; prefer v0.1.3 R arm. ·
           Default: allow claim only with retained method+version artifact.
  Hopper — R arm needed for head-to-head; Julia-only timings ≠ twin edge. ·
           Reuse fixture data.csv; no GPL source. · Default: measure both arms
           or mark R-blocked per cell.
  Curie  — CPU-aware protocol (BLAS=1, warm+timed, same machine). · Avoid CI
           for heavy timing. · Default: local first; Totoro only if blocked.
  Ada    — Synthesis: G0 = #372 six-cell measured timing; defer p>100.
```

**WHAT THE BRAIN ALREADY KNOWS:** D-111 (no General registry); Rose speed
fence; #370 no-claim artifact; extrapolated p=10k forbidden as measured.

**WHAT SHINICHI TOLD US (this turn):** #370 finished? → check; then one more
arc via arc-creation + ultra-plan STOP at G0; PLATFORM=Cursor; twin mission
continue with measured Julia-faster; DRM.jl-only unless twin requires drmTMB.

**DECISIONS LOCKED (pending G0 yes):** #372 is the next lane; #371 merge stays
human/CI gate; no second #370 implementation.

**QUESTIONS STILL OPEN:** see G0 below (yes/no only).

---

## ARC PROGRAM (from Arc Creation — size mode)

**Mode:** size  
**Recommended arc:** **3–5 hours** (Arc 0 probe 30–45 min + measure 90–150 min
+ docs/DoD 60–90 min)  
**Estimate confidence:** **inferred** (bench analogues exist; R-version risk)

| Order | Budget | Outcome | Trigger / definition of done |
|---|---:|---|---|
| Arc 0 | 30–45 min | Probe: drmTMB version + one-cell smoke both arms; write protocol stub | Start now after G0 |
| Rung 1 | 90–150 min | Time all six cells both arms; retained evidence md (+ optional JSON) | Arc 0 smoke works **or** R-blocked path documented |
| Rung 2 | 45–75 min | Update `r-julia-bridge.md` from artifact only; check-log.d + after-task + Rose | Rung 1 artifact exists |
| Integrate/close | 30–45 min | PR `closes #372`; LOOP tip update | DoD green |
| **Total** | **~3–5 h** | | |

**Risk branch:** If local drmTMB cannot refit a cell by Arc 0 minute 40 → do
**not** invent timings; mark that cell R-blocked / no-claim and continue
measurable cells. If **all** R arms blocked → close as preparation + probe
report; do not fake a twin speed claim.

**Not in this arc:** p>100 head-to-head; threaded-bootstrap campaign;
Lovelace R glue; engine changes; D-111.

**HAND TO ULTRA PLAN:** #372 · 3–5 h · retained six-cell wall-clock artifact +
honest bridge docs · DRM.jl harness/docs; local drmTMB for R arm only · fences
as GOAL block.

---

## Phase 1–2 — Slice table (plan only; no execution)

| Slice | Member | Model+effort | Bar | Time | Detail | Dep |
|---|---|---|---|---:|---|---|
| RECON Arc 0 | Curie/Hopper | Composer / low | Cursor Models | 30–45m | version + smoke + protocol stub | — |
| MEASURE Rung 1 | Curie | Composer / med | Cursor Models | 90–150m | six-cell both-arm timings → evidence file | Arc 0 |
| DOCS+DoD Rung 2 | Pat/Rose | Auto Cost / med | Other Models | 45–75m | bridge docs; check-log; after-task; Rose | Rung 1 |
| PR close | Ada/Grace | Composer / low | Cursor Models | 30–45m | PR closes #372 | Rung 2 |
| MECHANICAL-VERIFY | Grace | Composer / low | Cursor Models | 15m | re-read artifact numbers vs docs claims | Rung 2 |
| RECONCILE | Melissa | Terra/Sonnet med | hand off if needed | 10m | plan-vs-actual at close | PR |

**LUNA SUITABILITY (Cursor analogue):** yes — RECON + MEASURE scripts are
mechanical on Composer.  
**FAN-OUT BUDGET:** checkpoint=`372-g0` · children ≤3 · no ceiling child unless
Rose claim fight.  
**ULTRA EFFORT:** no.  
**SEARCH:** none / NotebookLM not required.  
**ESTIMATE:** ~3–5 h wall · fits one `/goal` session with optional fresh-task
if R version hunt balloons.  
**REVIEW (pre-run):** Rose + Curie critique this plan at G0 — **done above**.  
**VERIFY:** artifact exists; docs claims ⊆ artifact; no q4 / GPL / D-111 drift.  
**CONSOLIDATE:** evidence md + bridge docs + after-task + LOOP tip idle after merge.

---

## Arc ladder (operational)

| Arc | Gate | Budget | Deliverable |
|---|---|---:|---|
| 0 Probe + protocol | **G0 yes** | 30–45 min | Smoke log + version matrix in evidence stub |
| 1 Six-cell measure | Arc 0 | 90–150 min | Retained timing artifact for IN cohort |
| 2 Docs + DoD + Rose | Arc 1 | 45–75 min | Bridge docs match; check-log.d; after-task; Rose |
| 3 PR close | Arc 2 | 30–45 min | PR `closes #372` |

---

## G0 — YES / NO (STOP HERE)

**QUESTION:** Approve G0 for **#372** — measured wall-clock for the six #370
bridge fixture cells vs local drmTMB (retained artifact; Rose-fenced docs),
DRM.jl harness/docs only + R arm measurement (no Lovelace glue), fences
D-111 / no GPL / no `:natgrad` / no q4 regression / leave `.worktrees/` /
defer p>100 — **yes or no**?

**WHY NOW:** #370 coef parity landed (arcs done; #371 merge still CI-gated);
twin mission’s next honesty gap is the explicit timing no-claim.

**TEAM VIEW:** Ada recommend yes; Rose require version-honest R arm; Hopper
require both arms or blocked labels.

**RECOMMENDATION:** **Yes** — smallest twin-mission arc that converts no-claim
into measured evidence.

**IF YOU DO NOT MIND:** Approve yes; after merge of #371 (when green), run
`/goal` on a fresh branch from main.

**WHAT CONTINUES (reversible):** nothing executable until G0 yes — plan files
+ issue #372 only.

---

## After G0 approval — paste-ready `/goal` kickoff (do not run until yes)

```
/goal Execute approved ultra-plan for DRM.jl #372
(docs/dev-log/plans/2026-08-03-372-six-cell-measured-timing-ultra-plan.md).
PLATFORM=Cursor. Branch from origin/main (prefer after #371 merged).
Leave .worktrees/ alone. Do not reopen #370. Stop at DoD + PR closes #372.
```
