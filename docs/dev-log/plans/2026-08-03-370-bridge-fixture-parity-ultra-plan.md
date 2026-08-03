# Ultra-plan — DRM.jl #370: bridge fixture coefficient-scale parity

**Status:** G0 **APPROVED** 2026-08-03 by Shinichi. `/goal` executing on
`feat/370-bridge-fixture-parity` (rebased onto `origin/main` @ `379890a`).

**Issue:** https://github.com/itchyshin/DRM.jl/issues/370  
**Branch (already created):** `feat/370-bridge-fixture-parity` @ `0d93070` (== `origin/main`)  
**Human review link:** [`docs/dev-log/plans/2026-08-03-370-bridge-fixture-parity-ultra-plan.md`](2026-08-03-370-bridge-fixture-parity-ultra-plan.md)  
**Operational copies:** `LOOP/ultra-plan.md`, `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`

---

## 🎯 GOAL (paste-ready — copy verbatim into a fresh session to resume this plan)

```
SOLO PLATFORM: Cursor (this session is running in Cursor; after G0 approval,
execution hands to /goal — do not continue Phase 3 in the planning chat).

DELIVERABLE: Close DRM.jl #370 — coefficient-scale R↔Julia parity for the
Workflow G fixture cohort via drm_bridge (not only native drm()), behind
DRM_PARITY_TESTS=1, plus per-cell measured timing notes OR honest
"timing not measured — no claim" lines; update docs/src/r-julia-bridge.md
claim surface to match the gate; PR closes #370.

HEADLINE: Retire the documented blocker in docs/src/r-julia-bridge.md
("broader families wait for coefficient-scale parity tests") for the six
in-tree fixture families by exercising the marshalling path R will call
(drm_bridge), reusing committed drmTMB v0.1.3 generated numbers only.

IN PARALLEL (cheap): Arc-0 smoke inventory of the six fixtures through
drm_bridge; compare_bridge design note vs Fit-object compare_fit; Rose claim
fence draft for speed language.

DEFER (fenced, do not touch): R-side Lovelace glue / drmTMB engine="julia"
edits; Registrator / Julia General (D-111); AI-REML / :natgrad / #291 accel;
GPL vendoring of drmTMB source; src/ q=4 engine regressions of verified
logLik −256.51 / 2.18×; #202 non-Gaussian phylo location-scale; #136 VA;
xfam-external-gllvm (out of cohort); leave .worktrees/ alone / never stage.

DISCIPLINE: verify with DRM_PARITY_TESTS=1 locally first (coef ≤1e-6 bar per
Workflow G / issue body; reuse compare.jl contract); compute = local Julia
(+ optional local drmTMB only if measuring timing — never invent timings);
closure = PR closes #370 with tests + docs honesty + check-log.d + after-task
+ Rose claim-vs-evidence (DoD per AGENTS.md). Rose: no speed claim without a
retained measurement artifact.
```

---

## Phase 0 — Orient

**One-sentence goal:** make the six Workflow G fixtures pass coefficient-scale
parity through `drm_bridge`, with honest speed language, so bridge docs can stop
saying broader families are waiting.

**Tip → this lane:** tip was idle after #166 (`LOOP/checkpoint.md` at tip-idle).
Shinichi opened G0 = #370; branch `feat/370-bridge-fixture-parity` already exists
from `main` @ `0d93070`. This plan **owns that lane** and overwrites tip-idle
LOOP carefully.

```
$ git status -sb
## feat/370-bridge-fixture-parity
?? .worktrees/                      ← untracked, fenced, leave alone

$ git log --oneline -1
0d93070 docs(loop): tip idle after #166

$ bash ~/shinichi-brain/tools/branch_drift_check.sh
branch feat/370-bridge-fixture-parity vs origin/main: 0 ahead, 0 behind  ok
```

---

## Phase 0.25 — Prior-work sweep (RECEIPT) — gate before decompose

| Surface | Command / query run | Finding | Call |
|---|---|---|---|
| **Repo git state** | `git status -sb`; `git log --oneline -20`; `git branch -a`; `git worktree list`; `git stash list`; `branch_drift_check.sh` | On `feat/370-bridge-fixture-parity` @ `0d93070`, **0 ahead / 0 behind** `origin/main`; only untracked `.worktrees/` (fenced); no prior commits on this branch; many unrelated locked worktrees exist — **do not touch** | **Resume this branch** (empty of code); build the gap here — nothing to resume from another #370 branch |
| **Twin (drmTMB)** | `ls …/drmTMB`; `rg engine.*julia\|drm_bridge` in drmTMB README/NEWS/tests | Twin present; R already has experimental `engine = "julia"` glue + JuliaCall tests — **out of scope for #370** (Lovelace / drmTMB repo). DRM.jl-side `drm_bridge` is what those tests call | **Co-opt contract only** — do not edit drmTMB; Julia fixture gates unblock broader twin honesty on this side |
| **Brain** (`search_notes`, `search_all_projects: true`) | `"DRM.jl bridge fixture parity drm_bridge Workflow G #370"`; `"D-111 Registrator DRM.jl twin mission Workflow G parity"` | Hits: prior Workflow G fixture work (`2026-06-04-r-parity-fixtures`, #177/#17); q2 bridge parity notes; **D-111** live (no Registrator until twin ready); GPL→MIT fixture-numbers-only discipline already encoded in `test/parity/README.md` | **Reuse** harness + fixtures + license discipline; **build** the missing `drm_bridge` fixture path; **fence** D-111 |
| **External prior art** | Not commissioned | No novelty / “first to do X” claim — this is a twin-parity harness extension | **N/A** — no NotebookLM sweep required |

**Code evidence (this repo, inspected):**

| Claim | Evidence |
|---|---|
| Native runner uses `drm()` only | `test/parity/runparity.jl` L132: `fit = drm(bundle, fam; data = data)` |
| Zero fixture-backed `drm_bridge` tests | `rg fixtures/\|gaussian-locscale\|robust-student` under `test/test_bridge*.jl` → no hits; bridge tests use synthetic data |
| Fixtures have no timing metadata | All `expected.meta.toml` lack wall-clock / elapsed keys; `rg wall\|timing\|elapsed` under `test/parity` → none |
| Bridge family dispatch already covers cohort | `src/bridge.jl` `_bridge_family`: gaussian / biv_gaussian / student / nbinom2 / beta (+ others); meta_V is a formula marker on gaussian, not a family string |
| Cohort fixtures committed | `test/parity/fixtures/{gaussian-locscale,gaussian-bivariate-rho12,robust-student,count-nbinom2,proportion-beta,meta-analysis-V}/` each have `data.csv` + `expected.toml` + `expected.meta.toml` |
| OUT: xfam | `xfam-external-gllvm` is gllvm cross-package estimand — issue body excludes unless twin-mission owner overrides |
| Docs blocker text | `docs/src/r-julia-bridge.md` L3–4 / L58–61: broader families wait for coefficient-scale parity tests |
| License boundary | Fixtures = generated numbers only; drmTMB v0.1.3 provenance in `*.meta.toml`; MIT/GPL rule in AGENTS.md §3 + parity README |

**Verdict:** **build-the-gap** on this branch. Reuse fixtures + `compare.jl` + `_bridge_family`. Genuine new work = (1) bridge-shaped compare path, (2) fixture runner through `drm_bridge`, (3) docs honesty, (4) timing measure-or-no-claim. Nothing to invent outside #370.

---

## Phase 0.3 / 0.3b — Model roster + Cursor two-bar

- **PLATFORM = Cursor** (this planning session). After G0: `/goal` on Cursor; heavy live R timing optional → local maintainer machine (not CI).
- **Bar column (execution):** Scout/recon → Cursor Models (Composer); judgment / Rose / Ada → Other Models (Auto Cost / pinned Claude); do not drain one bar.
- **Two-bar reading:** not recorded in this planning turn (no Settings→Usage access from subagent). **Record both meters at `/goal` start** before fan-out.

**LUNA SUITABILITY:** yes — Arc 0 recon + mechanical `DRM_PARITY_TESTS=1` receipt are scout/mechanical. **ULTRA EFFORT:** no.

---

## WHAT THE BRAIN ALREADY KNOWS

- Workflow G / #17 closed at opt-in fixture bar; Phase 1.5 / #5 closed at experimental bridge bar — docs still withhold broader family claims pending coefficient-scale gates (#370 body).
- D-111: no Julia General / Registrator until twin readiness (fenced).
- GPL→MIT: never vendor drmTMB source; commit generated outputs only (Rose tag gate).
- Student / NB2 fixtures already transformed onto DRM.jl parameter scales at generate time (`gen_fixtures.R` `transform_expected`; README §transforms).
- Tip-idle after #166 was correct; #370 is the owner-opened next G0.

## WHAT SHINICHI TOLD US (this request)

- Plan-only; do not implement / push / open PR.
- Cohort + OUT list explicit; fences explicit.
- Prior sweep findings already known (native `drm()` only; zero bridge fixtures; no timing metadata; bridge families present).
- Want a **link** to the ultra-plan for G0 approval.
- Tip was idle; this lane owns #370 — overwrite LOOP carefully.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Hopper — native runparity proves drm() parity, not the R marshalling surface ·
           R users hit drm_bridge · recommend fixture runner call drm_bridge ·
           Q: one runner dual-path vs separate runparity_bridge.jl? ·
           default: extend behind the same DRM_PARITY_TESTS=1 gate with a
           clearly named @testset "drm_bridge fixtures"
  Rose   — issue language wants a "measured wall-clock edge" but fixtures have
           zero timing metadata · promoting any speed number without a retained
           measurement is claim drift · recommend measure-or-no-claim per cell ·
           Q: block merge on measured edge, or allow honest no-claim? ·
           default: allow honest "timing not measured — no claim" so parity
           can ship; never write a speed headline without an artifact
  Ada    — scope is harness + docs, not engine · avoid src/ q4 · meta_V is the
           highest smoke risk (marker spelling through bridge string parse) ·
           recommend Arc 0 smoke before writing the full harness ·
           Q: if one family fails hard, skip-with-issue vs hold whole PR? ·
           default: hold PR until all six cohort cells pass OR Shinichi
           explicitly shrinks the cohort mid-run
```

## ADA'S RECOMMENDATION

Approve this plan as written. Execution shape: Arc 0 smoke → Arc 1 harness →
Arc 2 admit six cells → Arc 3 timing (measure if cheap local drmTMB available,
else honest no-claim) → Arc 4 docs/DoD/Rose/PR. Prefer extending the existing
parity gate over a parallel env var. Keep MIT/GPL explicit in every fixture note.

## DECISIONS LOCKED (pending G0 = approval of this list)

1. Cohort IN: gaussian-locscale, gaussian-bivariate-rho12, robust-student,
   count-nbinom2, proportion-beta, meta-analysis-V. OUT: xfam-external-gllvm.
2. Path under test: `drm_bridge` (string/dict formula + family string + data),
   not only native `drm()`.
3. Numeric bar: reuse `compare.jl` contract (`atol_coef=1e-6` default; case
   `[tol]` overrides); issue body ≤1e-6 is the public bar for coefficients.
4. Timing: per newly admitted cell, either a retained measured note **or**
   `timing not measured — no claim`. No extrapolated p-scaling. No README speed
   headline without measurement.
5. License: generated fixture numbers only; no drmTMB source; no R-side edits.
6. Fences: D-111, :natgrad/AI-REML, q4 −256.51/2.18×, #202, #136, `.worktrees/`.
7. After G0: hand to `/goal`; do not implement in the planning chat.

## QUESTIONS STILL OPEN (resolve at G0 or early Arc 0)

1. **Timing gate strength:** allow honest no-claim for merge? (**Ada default: yes.**)
2. **Cohort failure policy:** one hard fail blocks PR vs shrink cohort?
   (**Ada default: block until all six pass unless you shrink.**)
3. **Want NotebookLM / external prior-art?** (**Ada default: no — not a novelty claim.**)

---

## ARC PROGRAM

| Arc | Budget | Status | Deliverable |
|---|---|---|---|
| **0** Smoke + inventory | ~20–40 min | pending | Per-cell `drm_bridge` smoke log; risk list (esp. meta_V / student / formula spelling); confirm compare gap |
| **1** Bridge parity harness | ~1–2 h | pending | `compare_bridge` (or equivalent) + `DRM_PARITY_TESTS=1` runner path that calls `drm_bridge`; xfam skipped/out |
| **2** Admit six cells | ~1–2 h | pending | All six cohort cells pass coef + logLik (+ vcov when fixture supplies it) |
| **3** Timing cells | ~30–60 min | pending | Per-cell measured note **or** honest no-claim; Rose-auditable artifact path |
| **4** Docs + DoD + close | ~45–90 min | pending | `r-julia-bridge.md` honesty; check-log.d; after-task; Rose; PR `closes #370` |

**Total capacity:** ~4–7 h wall-clock one session (or two short `/goal` sessions if timing needs local R).  
**Under-run:** if Arc 0 finds all six already green via a thin harness, collapse Arc 1–2.  
**Integration slot:** Arc 4 only after Arc 2 green; Arc 3 may parallel Arc 4 docs draft if no-claim path chosen.

---

## SLICE TABLE (roles · model · bar · time · deps)

| Slice | Member | Model+effort | Bar | Dispatch | Time | Detail | Dep |
|---|---|---|---|---|---|---|---|
| **RECON** Arc0 smoke | Hopper/Curie | Composer low–med | Cursor Models | native | 20–40m | Fit each cohort fixture via `drm_bridge`; write `docs/dev-log/…/370-arc0-smoke.md` | — |
| S1 compare_bridge | Hopper | Composer/Auto med | Cursor / Other | native | 45–90m | Accept flattened Dict (`coef`/`loglik`/`vcov`); mirror `compare_fit` failures | Arc0 |
| S2 runner wire | Hopper | Composer med | Cursor Models | native | 30–60m | `runparity.jl` dual path or `runparity_bridge.jl` + `runtests.jl` gate; skip xfam | S1 |
| S3 admit cells | Hopper+Curie | Composer med | Cursor Models | native | 45–90m | Fix formula/family spelling only as needed; **no q4 engine edits** | S2 |
| S4 timing | Curie+Rose | Auto Cost med | Other Models | native | 30–60m | Measure local Julia (± local drmTMB) **or** no-claim lines | S3 |
| S5 docs honesty | Pat/Hopper | Composer med | Cursor Models | native | 30–45m | Update `docs/src/r-julia-bridge.md` claim surface | S3 |
| **MECH-VERIFY** | Grace/Hopper | Composer low | Cursor Models | native | 20–40m | `DRM_PARITY_TESTS=1 julia --project=. -e '…'` receipt; six cells green | S3 |
| **Rose plan/close** | Rose | Auto/Claude med–high | Other Models | native | 20–40m | Claim-vs-evidence; speed fence; license boundary | S4+S5 |
| **RECONCILE** | Melissa | Auto med | Other Models | native | 15–20m | `docs/dev-log/plan-actual/2026-08-03-370-….md` | close |

**FAN-OUT BUDGET:** checkpoint=`370-g0` · new children ≤4/6 · scout=1 · build=2–3 · ceiling=0–1 (Rose only if claim dispute) · reuse on repair.  
**CONTEXT BRAKE:** planning parent stays plan-only; `/goal` starts fresh.  
**D-43 PANEL:** fire once at PR-ready milestone (2 build + 1 ceiling) if claiming “broader families unblocked.”

---

## Verification plan

1. **Always-on:** existing `test_parity_harness.jl` must still pass (machinery smoke).
2. **Opt-in:** `DRM_PARITY_TESTS=1` runs native `drm()` path **and** new `drm_bridge` fixture path; both green for the six cohort cells.
3. **xfam:** must not fail the suite (skip / exclude / unsupported family path — not admitted).
4. **Local before CI:** run parity locally; CI remains Linux opt-in / cost-disciplined.
5. **Tolerance:** default `atol_coef=1e-6`, `rtol_coef=1e-4` unless case `[tol]` overrides; logLik uses fixture `atol_loglik` (currently 1e-3 in committed tomls — **do not silently tighten without evidence**; coefficient bar is the #370 headline).
6. **No engine regression:** do not touch `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi; if a cell needs engine change → STOP and re-G0.

### Rose claim fence (speed)

| Allowed | Forbidden |
|---|---|
| “Cell X: Julia wall-clock = … s (method …, machine …, n=…); drmTMB = … s” with artifact path | “Julia is ~Nx faster” without both sides measured |
| “timing not measured — no claim” | Extrapolating from p=180 fixtures to large-p headlines |
| Pointing at existing verified 2.18× q=4 cell as **already published elsewhere** with citation | Re-using 2.18× as evidence for these fixture families |

---

## MIT / GPL boundary (explicit)

- drmTMB is GPL(≥3); DRM.jl is MIT.
- Fixtures remain **generated numeric outputs** + input `data.csv` + provenance `expected.meta.toml`.
- **Never** vendor drmTMB `.R` / TMB / C++ source into DRM.jl.
- Optional local drmTMB timing reruns produce **numbers for notes**, not source commits.
- Rose audits this at close and before any tag that cites #370.

---

## Out of scope (restate)

R-side Lovelace glue · D-111 Registrator · AI-REML / `:natgrad` · q4 −256.51 / 2.18× regressions · GPL vendoring · #202 · #136 · xfam-external-gllvm · inventing ship work outside #370 · editing `.worktrees/`.

---

## After G0 — paste-ready `/goal` prompt

```
/goal
PLATFORM: Cursor
Read: LOOP/checkpoint.md → LOOP/GOAL.md → LOOP/ultra-plan.md
→ docs/dev-log/plans/2026-08-03-370-bridge-fixture-parity-ultra-plan.md
Branch: feat/370-bridge-fixture-parity (from 0d93070)
Issue: #370 — drm_bridge coefficient-scale parity for Workflow G fixture cohort
Execute Arc 0 → … → Arc 4 per LOOP/arcs.md. Do not touch fences in GOAL.md.
Verify: DRM_PARITY_TESTS=1. Rose speed fence. Leave .worktrees/ alone.
PR closes #370 when DoD met. Stop at G0-complete only when PR is ready / merged
per owner instruction.
```

---

## G0 APPROVAL CHECKLIST

Shinichi, by approving this plan you are saying **yes** to:

1. **Mission:** close #370 on `feat/370-bridge-fixture-parity` via `drm_bridge` fixture parity for the **six** cohort families listed (xfam OUT).
2. **Method:** extend Workflow G harness (`DRM_PARITY_TESTS=1`); reuse committed drmTMB v0.1.3 numbers; no live R required for coefficient gates.
3. **Speed:** measure-or-honest-no-claim; **no** speed headline without a retained measurement.
4. **Fences:** no Lovelace/drmTMB R edits; no D-111; no `:natgrad`/AI-REML; no q4 engine regression; no GPL vendoring; no #202/#136; leave `.worktrees/` alone.
5. **Docs:** update `docs/src/r-julia-bridge.md` so claims match the new gate.
6. **Process:** after yes → `/goal` execution (not this planning chat); PR `closes #370` with full DoD + Rose.
7. **Open Q defaults** (unless you override): allow no-claim timing; hold PR until all six cells pass; no NotebookLM sweep.

**G0 question (exact):**  
**Do you approve this #370 Ultra Plan for `/goal` execution as written? (yes / no)**  
If no: name the checklist item(s) to change.
