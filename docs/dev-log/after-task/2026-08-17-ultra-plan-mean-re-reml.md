# 2026-08-17 — Ada Phase 0–2: ultra-plan for ordinary Gaussian mean-RE REML

**G0: PRE-APPROVED 2026-08-17 (Shinichi). Armed overnight. This chat STOPS. Overnight conductor executes `/goal`.**
**Lane claimed:** `mean-re-reml` (NEW scratch; not catchup, not `docs/a3c-design`, not biv-q4 / gaussian-phylo).
**Author:** Ada (Shannon speaking). Catchup consumed:
`docs/dev-log/evidence/2026-08-17-recon-noether-mean-re-reml.md` ·
`docs/dev-log/evidence/2026-08-17-recon-rose-claim-fence.md` ·
`docs/dev-log/evidence/2026-08-17-recon-shannon-lanes.md` ·
`docs/dev-log/evidence/2026-08-17-recon-hopper-drmtmb-reml.md`.
**Platform:** Cursor. **Cursor cannot EnterPlanMode** — said once. **No Phase 3 in this chat.**
**Locked pick:** recommended-next-g0 + owner pre-approval (start NOW; fence `(1 | g)` only; new issue + Noether/maintainer OK).

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor (this planning session; session_ownership.sh = Cursor)
  → /goal after G0 in a NEW scratch worktree
  ~/local-scratch/lanes/DRM.jl-mean-re-reml
  (not Dropbox docs/a3c-design; not catchup; not biv-q4; not gaussian-phylo)
Deliverable: opt-in method = :REML for Gaussian mean (1 | g) on the
  Woodbury spine; ML stays default; capability-status rejected→implemented
  ONLY after src + standalone test land
HEADLINE: replace gaussian_core.jl L413 guard with a real Patterson–
  Thompson path in gaussian_ranef.jl for intercept-only (1 | g)
IN PARALLEL: new GitHub issue; failing test first; DoD docs (check-log,
  after-task, capabilities.md REML-scope warning)
DEFER:
  - AGHQ
  - VA remainder (ZI×RE / phylo / crossed); #136 not this
  - :natgrad
  - HSquared AI-REML / #291 resume / public AI-REML solver
  - #428 steal
  - Option A test/runtests.jl include (wait #423+#428)
  - TSV supported / “parity complete”
  - #49 PARKED
  - D-111 OFF (no Julia General / Registrator)
  - σ-RE REML; random slopes; multi-ranef; non-Gaussian REML
  - q4 / src/reml_q4.jl / logLik −256.51 / 2.18×
  - leftover docs/a3c-design commits; shannon-coordinator.toml
DISCIPLINE: verify=standalone test + FE REML + ML (1|g) still green;
  FD ≤1e-6 on restricted objective · compute=Mac (small-n; Totoro n/a)
  · closure=G0 PRE-APPROVED; overnight /goal in the scratch lane
```

**STATE THIS LINE:** `PLATFORM: cursor | LANE: mean-re-reml | FOREIGN LANE: claude+#429+#428+#423+#420+#406+phylo-mean+arc1+biv-q4+a3c+catchup`

---

## Plan-mode note (once)

Cursor cannot flip Plan mode from here. Phases 0–2 are done. **G0 is PRE-APPROVED.** This chat **STOPS**. Overnight conductor runs the paste-ready `/goal` on the scratch worktree — not on leftover `docs/a3c-design`.

---

## ARC PROGRAM

size · ~3 h (2.5–3.5) · Arc 0 = opt-in Gaussian mean `(1 | g)` REML on Woodbury + standalone test. Card: `docs/dev-log/after-task/2026-08-17-arc-card-mean-re-reml.md`.

---

## PREFLIGHT (Phase 0.2)

```
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** `FOREIGN LANE ACTIVE (claude direct-to-main)` · 10 live lanes · `ON BRANCH: docs/a3c-design` · 4 uncommitted paths treated as a live prior-session lane.

**Lane taken:** `mean-re-reml` — does **not** own `#423`/`#428`/`#429`/`#406`/`#420` files, `claude/lane-*` leftovers, `docs/a3c-design` builds, or `DRM.jl-catchup`.

**COORD BOARD:** `docs/dev-log/coordination-board.md` committed to `origin/main` (reaches other lanes). This plan does **not** edit it. Board text is stale (catch-up campaign); live truth is preflight + open PRs.

**SESSION OWNERSHIP:** `PLATFORM: Cursor`. Dropbox dirty = **prior session**, not a concurrent editor:

- `M docs/dev-log/after-task/2026-08-17-overnight-handover.md`
- `?? .codex/agents/shannon-coordinator.toml`
- `?? docs/dev-log/after-task/2026-08-17-recommended-next-g0.md`
- `?? docs/dev-log/evidence/2026-08-17-what-else.md`

Do not stage those into the new lane. Never `git add -A`.

**BRANCH DRIFT:** `docs/a3c-design` vs `origin/main`: **2 ahead, 88 behind**. Do not build there. Cut the new lane from `origin/main`.

---

## Phase 0.25 sweep receipt (gate — required before decompose)

| Surface | Evidence that ran | Finding | Call |
|---|---|---|---|
| **repo git state** | `git status -sb`; `git log --oneline -20`; `git branch -a`; `git worktree list`; `git stash list`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` | Dirty leftover `docs/a3c-design` (88 behind). Live worktrees: `DRM.jl-catchup`, `DRM.jl-gaussian-phylo-mean`, `DRM.jl-biv-q4-phylo-reml`, `DRM.jl-arc1-backlog-after-434`. Historical REML branches exist (`shannon/reml-gaussian`, `feat/291-reml-*`, `claude/wire-reml-11`, `codex/ai-reml-gaussian-mme-pilot`) | **do not resume** those branches. **build-the-gap** on a new `origin/main` worktree |
| **twin / sister** | listed `/Users/z3437171/Dropbox/Github Local/drmTMB`; grepped `docs/` (not `R/`/`src/` GPL) for REML + capability-surface; brain hit `221-native-reml-finish` / `2026-06-13-drm-reml-borrow-map` | drmTMB already admits Gaussian REML including ordinary RE (R-side `drm_apply_estimator_spec`; no C++ REML). DRM.jl `test/parity/` has no REML+`(1\|g)` fixture (`test/parity/README.md`: ML default; REML tagged if present) | **co-opt user contract** (`method` / ML default / Gaussian-only). **do not vendor GPL**. This G0 is **not** parity-complete |
| **brain** | MCP `search_notes` `search_all_projects: true` queries: `REML ordinary random effects Gaussian mean DRM.jl method=:REML`; `D-111 Julia General registry OFF DRM.jl` | D-111 OFF (no General). FE REML already wired (`2026-06-07-wire-reml`). `#291` AI-REML speed track CLOSED — not this. HSquared eigen-REML is a sister claim | **reuse** FE REML metadata + model-selection guard. **do not mint** AI-REML |
| **deterministic greps** | `grep -in REML memory/DECISIONS.md`; `memory/AGENT_LOG.md` (tail); `memory/OPEN_QUESTIONS.md`; `journal/` (head); `projects/deep-research/README.md` | D-93 discharged (drmTMB coverage, not this cell). OPEN_QUESTIONS: sample-size-first for REML bias (n-ladder, not N=1). dr20 = REML vs AGHQ for **non-Gaussian** — out of scope. dr26 = H² GREML — out of scope | no new research slice; **offer** NotebookLM, do not run |
| **GitHub issues** | `gh issue list --repo itchyshin/DRM.jl --search REML --state all` | `#11` CLOSED (FE/q4 wire). `#291` CLOSED (AI-REML speed). `#327` OPEN (Hutchinson large-data idea — not this). `#433` CLOSED (biv_q4_phylo_reml fixture). **No ordinary mean-RE REML ticket** | **open a new issue**. Do not `closes #136` / `#11` / `#291` / `#327` / `#49` |
| **code** | `rg` `method = :REML` in `src/gaussian_core.jl`; `_fit_ranef_gaussian` in `src/gaussian_ranef.jl`; `docs/design/capability-status.md`; `docs/src/capabilities.md` REML-scope warning; `test/test_reml.jl`; `test/test_gaussian_ranef.jl` | Guard at L413–423 rejects any `re`. σ-phylo REML returns **before** that guard (L364–409). Ranef dispatch at L543–547 never receives `method`. Woodbury ML nll at `gaussian_ranef.jl:98–125`. `_withreml` already exists (L166–171) | **build-the-gap** on those two `src/` files + new test |

**Verdict:** **build-the-gap.** Nothing to resume. Twin supplies the user-facing contract only. Genuine new work is Patterson–Thompson on the existing Woodbury `(1 | g)` spine.

---

## Phase 0.3 / 0.3b — roster + two bars

- **PLATFORM (read, not inferred):** Cursor. Session model: **Grok 4.6** (owner: Grok only).
- **Live roster (this session):** Cursor Grok 4.6 · Composer 2.5 exists · Other Models (Auto Cost / Claude / GPT) exist. Owner locked **Grok only** for this plan; do not burn Other Models to even meters.
- **Phase 0.3b bars:** Settings → Usage **not readable from this session**. Last dated vault row (`memory/MODEL-ROUTING.md`, 2026-08-16): Cursor Models **51%** · Other Models **66%** · Grok Bot **4% unused** · on-demand **disabled**. Treat as **STALE prior**. Scout/recon → **Cursor Models / Grok**. Heavy `src/` repair → **HANDS TO Codex/Claude**, not a longer Cursor parent.
- **ULTRA EFFORT:** no.

---

## Phase 0.4 — what is already locked vs still open

### WHAT THE BRAIN ALREADY KNOWS

- ML is the default; REML is opt-in; REML likelihoods are not comparable across mean structures (`AGENTS.md` / `CLAUDE.md` / `comparison.jl:126–137`).
- FE Gaussian loc-scale REML is implemented (`_fit_fixed_gaussian_reml`, `test/test_reml.jl`, `#11`).
- Ordinary mean-RE REML is **rejected by guard** (`capability-status.md`).
- q4 all-axes REML is implemented (`src/reml_q4.jl`) — **do not touch**.
- σ-phylo REML already bypasses the generic guard.
- D-111 OFF. `#49` PARKED. `#136` CLOSED on GitHub 2026-08-17 (VA remainder is still not this G0).
- `#291` was AI-REML / q4 speed — CLOSED; not a resume target.

### WHAT SHINICHI TOLD US (PRE-APPROVED 2026-08-17)

1. Start this G0 **NOW** — do not wait for `#423`+`#428`; `runtests.jl` include is a later PR.
2. Fence: mean `(1 | g)` **ONLY**.
3. New GitHub issue + Noether/maintainer OK for `src/gaussian_core.jl` + `src/gaussian_ranef.jl`.
4. **Pre-approves everything** remaining (objective form, B-card footnote). Arms overnight.

### WHAT THE TEAM RAISED

```
TEAM RAISED (catchup files, not Ada paraphrase)
  Noether — docs/dev-log/evidence/2026-08-17-recon-noether-mean-re-reml.md
    Guard 413-423 fires before ranef dispatch. Narrow hole only.
    ℓ_REML = ℓ_ML − ½ logdet(XμᵀV⁻¹Xμ) + (pμ/2) log 2π on existing S/M.
    MUST invert test/test_reml.jl:121-128 (already in runtests.jl:39) or
    default suite goes red the moment the guard lifts. Do not resume
    shannon/reml-gaussian (cherry-pick Hββ ≡ XᵀV⁻¹X identity only).
    vcov from restricted Hessian. ~90 min src+test. build-the-gap.
  Rose   — docs/dev-log/evidence/2026-08-17-recon-rose-claim-fence.md
    Verdict: clean-with-limitations. B implemented ≠ Documenter Tested
    ≠ DoD item 2. Do NOT cite #434/#438 as a B-card-flip precedent
    (they were A fixtures). Cite guard 413-423 not stale :407.
    Recount snapshot (table has 2 rejected, prose said 1). capabilities.md
    REML-scope MUST move; new Inference row = Impl, untested until include.
    Scoreboard A (TSV) untouched. HANDOVER/README leave alone.
  Hopper — docs/dev-log/evidence/2026-08-17-recon-hopper-drmtmb-reml.md
    Twin: REML=TRUE (not method="REML"); R-side Laplace of β_μ; no C++
    REML kernel. Co-opt contract + statistical target. n/a for TMB port.
    No Workflow G REML+(1|g) fixture. Twin withholds SE/coverage for this cell.
  Shannon — docs/dev-log/evidence/2026-08-17-recon-shannon-lanes.md
    lane_launch.sh mean-re-reml --base origin/main. Need new issue.
    Do not put LOOP/checkpoint.md in the PR. Do not touch src/DRM.jl
    (#423 owns this cycle) unless an export is required — it is not.
  Ada    — Pre-approval consumes both open questions. Overnight /goal.
```

### ADA'S RECOMMENDATION

**Consumed.** Shinichi pre-approved. Overnight executes.

### DECISIONS LOCKED (including former open questions)

- Estimator: ordinary Gaussian mean-RE REML (Patterson–Thompson on Woodbury).
- **Objective (locked):** joint Woodbury nll + `½ logdet(Xμᵀ V⁻¹ Xμ) − (pμ/2) log 2π` formed on existing `S`/`M` (Noether). Profile β_μ only if FD fails.
- API: `drm(...; method = :REML)` opt-in; `:ML` default unchanged.
- Fence: `(1 | g)` intercept only (`w ≡ 1`).
- Files: `src/gaussian_core.jl`, `src/gaussian_ranef.jl`, **invert** `test/test_reml.jl:121-128` (already in default suite), new `test/test_reml_ordinary_ranef.jl`, DoD docs, capability-status **after** land.
- **B-card (locked):** flip `rejected` → `implemented` after src+test; footnote standalone file + “not in default suite yet” for the *new* file; Documenter row = **Impl, untested** until Option A include. Do **not** cite #434/#438 as a B-flip precedent (Rose).
- Lane: new scratch `mean-re-reml` from `origin/main`.
- No `test/runtests.jl` this PR (editing `test_reml.jl` is not an include-list edit).
- No `src/DRM.jl` (no new export). No `LOOP/checkpoint.md` in the PR.
- No q4 touch. No AI-REML. No TSV (scoreboard A). No “parity complete.” `#49` PARKED. D-111 OFF. `#136` not this.

### QUESTIONS STILL OPEN

**None.** Pre-approved.

---

## Phase 0.5 — grounded search

**Offered, not run.** Patterson–Thompson (1971) is classical; drmTMB already ships Gaussian REML. No novelty/priority claim. NotebookLM would not change the slice. Say if you want it anyway.

---

## SLICE TABLE

Scout/recon **Bar = Cursor Models / Grok**. Heavy `src/` **HANDS TO Codex/Claude** if Grok repair loops twice.

| ID | Member | Model+effort | Bar | Dispatch | Time | Detail | Dep |
|---|---|---|---|---|---|---|---|
| S0 | Shannon | Grok · low | Cursor Models | nested Task (done this plan) | 10m | Lane launch + new issue + LOOP kit | — |
| S1 | Curie/Noether | Grok · medium | Cursor Models | `/goal` build | 25m | Invert `test/test_reml.jl:121-128` (already in suite) + failing `test/test_reml_ordinary_ranef.jl`: ML default unchanged; defining property `re_sd`/`σ` REML ≥ ML (not n/(n−pμ)); still-reject σ-RE / slopes; metadata | S0 |
| S2 | Noether | Grok · medium; **HANDS TO Codex Terra** if 2nd repair | Cursor Models → hand off | `/goal` build | 70m | Narrow L413 hole; `reml` kwarg on `_fit_ranef_gaussian`; PT term; `_withreml`; do not edit `reml_q4.jl` / q4 / `_fit_sigma_ranef_gaussian` / correlated/multi | S1 |
| S3 | Curie | Grok · low | Cursor Models | `/goal` verify | 25m | Run standalone file + `test/test_reml.jl` + `test/test_gaussian_ranef.jl`. Do not claim q4. Mac only | S2 |
| S4 | Pat | Grok · low | Cursor Models | `/goal` docs | 20m | Docstrings; `docs/src/capabilities.md` REML-scope warning; worked example in the test file header | S3 |
| S5 | Rose | Grok · medium | Cursor Models | `/goal` close | 20m | Flip capability-status **only if** src+test landed; check-log.d + after-task; claim fence | S3, S4 |
| V | Rose | Grok · medium | Cursor Models | plan-review (this file) + post-land | 15m | Sweep receipt non-vacuous; no oversell | S5 |
| R | Melissa | — | hand off | N/A this G0 close if `/goal` is small-fix; else Terra later | — | `RECONCILE: light` at PR close | V |

**SEARCH:** none (NotebookLM offered, not run)
**SLICES:** S0 → S1 → S2 → {S3} → {S4, S5} → V
**PARALLEL:** {S4, S5} after S3. Planning scouts {Noether, Hopper, Shannon, Rose} already fanned out.
**FAN-OUT:** 4 nested Grok Tasks this plan (recon). Execution fan-out lives in `/goal`, not this chat.
**FAN-OUT BUDGET:** checkpoint=`mean-re-reml-g0` · new children=4/6 (recon) · scout=4 · build=0 this chat · ceiling=0 · reuse=those four if follow-up
**SCOUT SUITABILITY:** yes — recon ran on Grok
**ULTRA EFFORT:** no
**CONTEXT BRAKE:** parent input=unknown · fresh-task trigger=after G0 (`/goal` new chat)
**COMPACTIONS:** parent=0 · children max=1 · boundary=open
**LANE RECEIPT:** `START A FRESH TASK` · reason=G0 is the plan; execution is arc-shaped `src/` · next-task=`/goal` block below
**AUTO-REVIEW:** guardian calls unknown · action=batch issue+worktree in `/goal`
**D-43 PANEL:** milestone=not a milestone · status=not fired
**ESTIMATE:** ~3 h wall-clock · 1 `/goal` session · fits one scratch lane · HANDS TO Codex/Claude if S2 repair #2
**ARC ACTUALS:** `docs/dev-log/after-task/2026-08-17-arc-card-mean-re-reml.md`
**PREFLIGHT:** Shannon — `FOREIGN LANE ACTIVE (claude direct-to-main)` · lane claimed `mean-re-reml`
**REVIEW:** Rose (claim fence) + Noether (engine hole) — this plan
**VERIFY:** standalone test log, not exit code; FE REML + ML ranef still green
**CONSOLIDATE:** capability-status footnote; check-log.d; after-task; PR `closes #NN` (new issue)
**RECONCILE:** Melissa light at PR close — `docs/dev-log/plan-actual/2026-08-17-mean-re-reml.md` if the close is meaningful; else `N/A — small src+test slice`

---

## Implementation contract (overnight `/goal` — Noether catchup)

**Routing today.** `method === :REML` at `src/gaussian_core.jl:413–423` (not stale `:407`) throws unless `re` and `sigma_re` are empty (and no structured/meta). σ-phylo returns earlier (L364–409) and already threads `reml`. Ordinary ranef is dispatched at L543–547 with **no** `method` argument.

**Required hole (only this):**

- `re` is a single intercept `(1 | g)` (`kind === :intercept`, `w ≡ 1`)
- `sigma_re` empty; `structured === nothing`; `metav === nothing`
- family `Gaussian()`
- else keep today’s `ArgumentError` (σ-RE, `(0 + x | g)`, correlated, crossed, structured, meta)

**Objective (locked).** ML Woodbury nll (`gaussian_ranef.jl:98–125`):

`0.5 * (logdetV + quad) + 0.5 * n * log(2π)`

Restricted (Noether, in-tree FE / Harville form with `W` replaced by `V⁻¹`):

`ℓ_REML = ℓ_ML − ½ logdet(Xμᵀ V⁻¹ Xμ) + (pμ/2) log 2π`

i.e. add `+ ½ logdet(Xμᵀ V⁻¹ Xμ) − (pμ/2) log 2π` to `nll`. Form `Xμᵀ V⁻¹ Xμ` on the existing `S`/`M` capacitance (`M_k = 1/σb² + S[k]`), not a generic Hessian wrapper (identity `Hββ ≡ XᵀV⁻¹X` may be used as a check). Attach `_withreml(fit, reml_ll, ml_ll)`. vcov from the **restricted** Hessian. Keep `comparison.jl` guard.

**Do not resume** `shannon/reml-gaussian` (scope violates fence). Cherry-pick the identity only.

**MUST invert** `test/test_reml.jl:121-128` — that `@test_throws` is already in `test/runtests.jl:39`. Leaving it will fail the default suite the moment the guard lifts. This is **not** an include-list edit.

**Must not touch:** `src/reml_q4.jl`, `src/sparse_*.jl`, `src/fit_q4_sparse_tmb.jl`, `src/gaussian_locscale_phylo.jl`, `src/DRM.jl`, `_fit_sigma_ranef_gaussian`, `_fit_correlated_ranef_gaussian`, `_fit_multi_ranef_gaussian`, `test/runtests.jl` include list, q4 tests.

**Regression fences:** FE REML (`test/test_reml.jl` ML-default / σ² / FD / lrtest sets); ML `(1 | g)` (`test/test_gaussian_ranef.jl`); σ-phylo REML files untouched; do not run or claim q4 `logLik −256.51` / 2.18×.

**First failing tests (TDD):**

1. Invert `test/test_reml.jl:121-128` to expect a REML fit for mean `(1 | g)`; keep residual throws for structures still fenced.
2. New `test/test_reml_ordinary_ranef.jl` (standalone; not in `runtests.jl` this PR):
   - `method` omitted ≡ `:ML`
   - `re_sd(freml)[:g] ≥ re_sd(fml)[:g]` and residual `σ_REML ≥ σ_ML` (do **not** claim `n/(n−pμ)` — FE-homoscedastic only)
   - `estimation_method === :REML`; `loglik == reml_loglik`; `ml_loglik` finite
   - `:REML` + `(0 + x | g)` or `sigma ~ (1 | g)` still `ArgumentError`
   - `aic`/`lrtest` still refuse different mean structures under REML

---

## CLAIM FENCE (Rose catchup — quote, do not broaden)

Source: `docs/dev-log/evidence/2026-08-17-recon-rose-claim-fence.md`. Verdict: **clean-with-limitations**.

**Card-flip rule:** flip `REML with ordinary random effects (Gaussian mean)` `rejected` → `implemented` **only after** (i) the `gaussian_core.jl` **413–423** guard is gone for Gaussian mean `(1 | g)` and (ii) a real `test/test_*.jl` exercises that path. Do not flip on docs alone. Do not flip on a stub that still throws. Cite **413–423**, not stale `:407`.

**Scoreboards stay separate:**

- **A** = drmTMB `julia-capabilities.tsv` — **do not touch**
- **B** = `docs/design/capability-status.md` — this G0 may flip **one** B row after src+test

B `implemented` ≠ Documenter **Tested** ≠ full `AGENTS.md` DoD item 2. After-task must say: B chip flipped; default-suite include of the *new* file deferred; DoD item 2 incomplete until Option A. Do not claim `Pkg.test()` covers ordinary-RE REML via the new file (the inverted `test_reml.jl` cell *will* run in the default suite).

**Do NOT cite #434/#438 as a B-card-flip precedent** (they were A fixtures + a `runtests.jl` wait-gate). Reuse the include wait-gate only.

**MUST update after land:** capability-status row + rejection prose + **honest snapshot recount** (table already has 2 rejected; do not mint other chips); `docs/src/capabilities.md` REML-scope warning (else a fourth stale sentence). New Inference-table row = **Impl, untested** (or “standalone test file, not in the default suite”), never **Tested** / **Stable**.

**MUST NOT update** unless a single tightly scoped sentence is unavoidable: `README.md`, `HANDOVER.md` verified table, `ROADMAP.md`, `AGENTS.md`/`CLAUDE.md`, TSV / Workflow G.

**Forbidden claims:** AI-REML; parity complete; TSV `supported`; REML as default; q4 regression / 2.18× / −256.51 rewrite; GPL vendoring; `#136` as VA ship; `#49` unparked; D-111 on; σ-RE / slopes / non-Gaussian REML; un-reject `:natgrad`; “default suite covers ordinary-RE REML” via the new file before include.

---

## ROSE PLAN-REVIEW (decomposition, not code)

Catchup file: `docs/dev-log/evidence/2026-08-17-recon-rose-claim-fence.md`.

**Sweep receipt:** present and non-vacuous (git + twin + brain + greps + `gh` + live guard 413–423). Not `search_notes` alone.

**What Rose would block**

- Flipping the B row before the 413–423 guard is gone and a real test exists
- Editing `test/runtests.jl` include list while `#423`/`#428` are live
- Building on `docs/a3c-design`
- `closes #136` / `#11` / `#291`
- Calling this parity, AI-REML, or Documenter **Tested**
- Citing #434/#438 as a B-chip flip
- Copying stale `:407`

**What Rose accepts**

- Start NOW; invert `test_reml.jl:121-128` (already included) + new standalone file
- B flip after src+test with footnote + snapshot recount
- Maintainer/Noether OK for the two `src/` files

**Verdict:** **clean-with-limitations** — G0 PRE-APPROVED on this fence.

---

## DEFER (fenced — not in the `/goal`)

AGHQ; VA remainder; `:natgrad`; HSquared AI-REML; `#428` steal; Option A `runtests.jl` include; TSV flip; “parity complete”; `#49`; D-111; σ-RE / slopes / non-Gaussian REML; q4 engine; leftover `docs/a3c-design`; staging `shannon-coordinator.toml`; shared drmTMB checkout.

---

## Paste-ready `/goal` prompt (G0 PRE-APPROVED — overnight executes)

Overnight conductor: run `lane_launch.sh` if needed, then this prompt in a **fresh** chat whose workspace is the scratch tree, **not** Dropbox `docs/a3c-design`.

```
/goal

Ultra-plan G0 PRE-APPROVED 2026-08-17. Armed overnight. Run this plan to completion via LOOP/.

LANE: mean-re-reml
REPO: /Users/z3437171/local-scratch/lanes/DRM.jl-mean-re-reml
PLAN: /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-17-ultra-plan-mean-re-reml.md
ARC:  /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-17-arc-card-mean-re-reml.md
NOETHER: docs/dev-log/evidence/2026-08-17-recon-noether-mean-re-reml.md
ROSE:    docs/dev-log/evidence/2026-08-17-recon-rose-claim-fence.md

SCAFFOLD (if the worktree does not exist yet):
  bash ~/shinichi-brain/tools/lane_launch.sh \
    "/Users/z3437171/Dropbox/Github Local/DRM.jl" mean-re-reml \
    --base origin/main
  Then reopen this chat ON that worktree.

READ FIRST: the approved plan → Noether + Rose evidence → repo AGENTS.md →
  src/gaussian_core.jl:413-423 and :543-547 → src/gaussian_ranef.jl:94-158 →
  test/test_reml.jl:121-128.

RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code;
  pause at OPEN GATE; overwrite checkpoint each arc; fresh chat at batch barriers.
  Keep LOOP/ local to the worktree — do NOT put LOOP/checkpoint.md in the PR.

START ARC: S0 new GitHub issue (ordinary Gaussian mean (1|g) REML; do NOT
  closes #136 #11 #291 #327 #49) → S1 invert test_reml.jl:121-128 + failing
  test_reml_ordinary_ranef.jl → S2 narrow 413-423 hole + Woodbury PT
  (ℓ_REML = ℓ_ML − ½ logdet(XμᵀV⁻¹Xμ) + (pμ/2) log 2π on S/M; _withreml;
  restricted vcov) → S3 standalone + test_reml.jl + test_gaussian_ranef.jl
  → S4/S5 capabilities.md REML-scope + capability-status flip ONLY after
  src+test (cite 413-423 not :407; recount snapshot; Documenter Impl, untested)
  → Rose close + PR closes #<new>.

NEXT GATE: opening/arming the PR (src/ engine — no --auto unless
  maintainer says so). HANDS TO Codex/Claude if S2 repair #2.

VERIFY: method=:REML fits Gaussian mean (1|g); ML default unchanged;
  σ-RE/slopes still ArgumentError; re_sd and residual σ REML ≥ ML
  (not n/(n−pμ)); FD ≤1e-6; FE REML + ML ranef still green.

COMPUTE: Mac small-n. No Totoro/DRAC. No full Pkg.test required.

FENCE: no test/runtests.jl include-list edit; no src/DRM.jl; no q4 /
  reml_q4.jl / sparse_* / fit_q4_* / gaussian_locscale_phylo.jl;
  no σ-RE REML; no slopes; no non-Gaussian REML; no AI-REML;
  no TSV (scoreboard A); no “parity complete”; #136 not this; #49 PARKED;
  D-111 OFF; do not steal #423 #428 #429 #406; do not build on
  docs/a3c-design; never stage shannon-coordinator.toml; never vendor
  drmTMB GPL; do not resume shannon/reml-gaussian.

CLAIM FENCE: flip B-row rejected→implemented only after src+test.
  Footnote new file not in default suite. Do not cite #434/#438 as a
  B-flip. ML stays default. Leave HANDOVER/README alone.
```

---

## Routing receipt (planning session)

| Field | Value |
|---|---|
| PLATFORM | Cursor (`session_ownership.sh`) |
| Session model | Cursor Grok 4.6 (this chat) |
| bars | **STALE 2026-08-16:** Cursor Models 51% · Other Models 66% · Grok Bot 4% unused · on-demand disabled. This plan: Grok only / Cursor Models for scouts |
| Nested Task subagents | Noether, Hopper, Shannon, Rose (Grok) — catchup files consumed |
| G0 | **PRE-APPROVED 2026-08-17** · armed overnight |
| Phase 3 | **not started in this chat** — overnight conductor executes |
| git add / commit | **not done** (owner did not ask) |
| New issue | **not opened** (first `/goal` action) |
