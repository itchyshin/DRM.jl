🎯 GOAL
Solo platform: Cursor
Deliverable: One PR from tip `origin/main` @ `94a47e8b` that makes Poisson
  random-intercept `drm(...; marginal=:VA)` a real public path (ELBO tagged;
  unsupported VA errors; default LA unchanged). Issue #136 stays OPEN.
HEADLINE: Reuse existing `_fit_poisson_ranef_va`; wire public `marginal=:VA`
  on Poisson `(1|g)` only — do not rebuild kernels; do not cherry-pick the
  stale 5-family `method=:VA` commit wholesale.
IN PARALLEL: none required (linear TDD → dispatch → DrmFit tag → AIC/LRT
  guard → docs honesty). Optional scout: inventory `b32488d5` Poisson hunks.
DEFER: rungs 1–4 / 136e bias report; Binomial/NB2/Gamma/Beta public VA;
  closing #136; q=4 core; #49 FIML; R-bridge; Gamma MGF rewrite; GPL vendoring;
  staging `.worktrees/`; merging `shannon/overnight-audit-verify-20260619`.
DISCIPLINE: verify before claiming · ML default · no silent LA fallback ·
  ELBO ≠ logLik · Noether+maintainer merge gate · PR does not `closes #136` ·
  local `Pkg.test` before CI.

**Why ultra-plan (vs Arc Creation EXECUTE DIRECTLY):** owner invoked `/ultra-plan`
explicitly for coordination + the `src/` / public-API maintainer gate. Arc 0 is
still one linear ~2 h slice — not a 5-family epic.

**Plan mode:** Cursor cannot flip Plan mode programmatically. This artifact is
Phases 0–2 read-only. Do not implement, commit, push, or open a PR until G0.
After approval, run via `/goal` in a **fresh** chat. Durable copy after G0:
`docs/dev-log/plans/2026-08-08-136-va-poisson-frontend-ultra-plan.md` (do not
write that file in the planning chat).

ARC PROGRAM: size mode · Arc 0 ≈ 2 h (90–150 min) Poisson public `marginal=:VA` · epic rungs 1–4 / 136e deferred · #136 stays OPEN.

---

## PHASE 0.25 — SWEEP RECEIPT

| Surface | Evidence ran | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb`; `git log --oneline -20`; `git branch -a --no-merged main`; `git worktree list`; `git stash list`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` | Tip **IDLE** `main`==`origin/main` @ `94a47e8b` (Merge #398 / #336 CLOSED). Drift 0/0. Many locked `.claude/worktrees/` + `.worktrees/` (never stage). Stash unrelated. Unmerged: `shannon/overnight-audit-verify-20260619` is **174 ahead / 11 behind** main. | **nothing to resume as a branch**; **do not merge** overnight-audit. Fresh `feat/136-va-poisson-frontend` from tip. |
| **this-repo code** | Read `src/variational.jl`, `src/poisson.jl` `drm()` (no `method`/`marginal`), `test/test_variational.jl` (3 `@test_skip`), `test/test_va_poisson_elbo.jl` + family VA tests in `runtests.jl`; `git show b32488d5 --stat`; `git show b32488d5:test/test_va_frontend.jl` | Kernels **on tip**. Public `drm()` **not** threaded. June-21 frontend = commit **`b32488d5`** (`method=:VA`, 5 families, `_va_reject`, `test_va_frontend.jl` 55/55 then). **No** `DrmFit.marginal` in that commit. `capabilities.md` still “Absent (stub)”. | **reuse kernels**; **co-opt Poisson dispatch + `_va_reject` + Poisson tests from `b32488d5`**; retarget keyword; **build** tag + mixed-marginal guard (gap vs old commit). |
| **twin / sister** | `rg` drmTMB `method.*VA\|variational\|ELBO` (docs/design 160 GVA **not implemented**; Laplace-only engine); GLLVM.jl checkout has **no** `src/families/variational*` (other branch); files exist on GLLVM `integration` / worktrees `variational*.jl` | drmTMB has **no** `method="VA"` to parity against. GLLVM VA is sister **bias motivation** + ELBO structure — **do not vendor**. | **reuse** GLLVM motivation; **n/a** R-parity for Arc 0; **no** twin API to copy. |
| **brain** | MCP `search_notes` query `DRM.jl #136 VA ELBO marginal=:VA method=:VA Poisson frontend` `search_all_projects: true`; deterministic `grep -in '#136\|VA/ELBO\|marginal=:VA\|method=:VA\|variational.jl'` on `memory/AGENT_LOG.md`, `DECISIONS.md`, `OPEN_QUESTIONS.md`; `grep -rin` `journal/`; `grep -in` `projects/deep-research/README.md` | Design note `2026-06-02-va-marginal-design` still says `method=:LA/:VA`. Scaffold/docs check-logs Jun 2026. **No D-## locking the public keyword.** AGENT_LOG / OPEN_QUESTIONS / deep-research README: **no DRM #136 keyword decision** (empty or pigauto #136 / board-count 136). | **reuse** design anchors + opt-in posture; **build** keyword as `marginal=` (Ada default). |
| **Verdict** | | Genuinely new on tip: public Poisson `drm` selector + Fisher tag/guard + docs honesty. Not new: ELBO kernels, σ→0 tests, `_va_reject` pattern. | **reuse kernels / co-opt `b32488d5` Poisson pattern / build public gap** |

Rose (plan review): receipt is **non-vacuous** — each line cites command/query. Gate **PASS** → Phase 1 allowed.

---

## PHASE 0.3 / 0.3b — ROSTER + TWO-BAR

- **Roster:** `MODEL-ROUTING.md` Cursor row refreshed **2026-08-01** — Cursor Models = Composer 2.5 + Grok 4.5; Other Models = Auto Cost / Claude / GPT (≥$400 API; on-demand **off**). Not re-fetched this turn.
- **Phase 0.3b:** this agent **cannot read** Settings → Usage. **Owner: glance both bars before `/goal`.** Plan table still has a **Bar** column. Planning used Other Models (this judgment pass) + prior Composer scout in the arc-creation fork; do not drain one bar in `/goal`.

---

## WHAT THE BRAIN / REPO ALREADY KNOWS

- Tip idle after #398; coordination-board still calls VA “scaffold/deferred” (stale vs kernels, honest vs public API).
- Design contract: VA opt-in, never default; RE-only; deterministic anchors; ELBO is a bound; q=4 Laplace untouched.
- Internal kernels + tests already on `main`. Frontend once existed on a **kitchen-sink** branch using `method=:VA` (non-Gaussian `drm()` had no `method` then). Gaussian `drm(...; method=:ML/:REML)` makes that spelling a **cross-family homonym**.
- drmTMB remains Laplace-only — VA is beyond-parity, not a Workflow G cell.

## WHAT SHINICHI TOLD US

- Run `/ultra-plan` for **Arc 0 only** (not close #136).
- Platform = Cursor. STOP at G0; paste-ready `/goal`; no Phase 3 here.
- Fences: no q=4; ML default; #49 parked; no R-bridge; never stage `.worktrees/`; no GPL; Noether+maintainer merge gate.
- IF YOU DO NOT MIND on the one question = `marginal=:VA`.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Noether — Kernels on tip are the verified Poisson ELBO path; do not rewrite
    `_fit_poisson_ranef_va` or touch q=4 / sparse Laplace. Stale branch is 174
    commits behind — cherry-pick pattern, never merge. · Rec: dispatch-only
    `src/poisson.jl` + small `_va_reject` in `variational.jl`. · Q: none if
    keyword locked. · Default: leave kernels byte-stable.
  Fisher  — Old `b32488d5` left DrmFit untagged; AIC/LRT will mix ELBO with LA
    logLik. `method` already means ML/REML on Gaussian. · Rec: `marginal=:VA`
    + `_withmarginal` + mixed-marginal error in `lrtest`/`aic`/`aicc`/`bic`.
    · Q: keyword (below). · Default: tag + guard in Arc 0, not a later rung.
  Rose    — capabilities.md “Absent (stub)” is false for kernels and true for
    public drm(). Do not flip guide to “implemented”; do not close #136; do not
    claim bias recovery. · Rec: honesty row = Experimental Poisson RI only.
    · Default: Planned banner stays for the epic; add a one-line “Poisson RI
    public path landing in #NNN”.
  Pat     — Same keyword name must not mean estimator on Gaussian and marginal
    on Poisson. Error `method=:VA` → point at `marginal`. · Rec: `marginal`.
  Grace   — Linux CI only after local Pkg.test; new test file in runtests.jl;
    no new CI OS. · Rec: local subset first (frontend + poisson VA + comparison).
  Ada     — Scope = Poisson public gap only. Ultra-plan exists because owner
    asked + maintainer gate, not because Arc 0 is a 6-slice fan-out.
```

## ADA'S RECOMMENDATION

Ship Arc 0 as **`marginal=:VA`** on Poisson `(1|g)`, co-opting `_va_reject` + routing tests from `b32488d5`, adding the Fisher tag the old commit skipped. Keep #136 open.

## DECISIONS LOCKED (pending G0)

1. Base = `origin/main` @ **`94a47e8b`**. Branch **`feat/136-va-poisson-frontend`**.
2. Keyword = **`marginal=:LA/:VA`** (default `:LA`). Reject `method=:VA` on Poisson with a pointer. Gaussian `method=:ML/:REML` untouched.
3. In scope: Poisson `(1|g)` → `_fit_poisson_ranef_va`; `_va_reject` otherwise; `_withmarginal`; mixed-marginal comparison guard; frontend test; capabilities/guide honesty; DoD; PR **does not** close #136.
4. Out: other families’ public VA; 136e; q=4; #49; R-bridge; merge overnight-audit; GPL; `.worktrees/`.
5. Merge = **OPEN GATE**: Noether + maintainer sign-off (`src/` + public API).
6. After G0: `/goal` in a fresh chat — not Phase 3 here. Write durable plan copy on execution start.

## QUESTIONS STILL OPEN (1 max)

**Q1.** Public selector: **`marginal=:VA`** vs design-note **`method=:VA`** (as in `b32488d5`)?  
**WHY NOW:** same symbol cannot mean ML/REML on Gaussian and LA/VA on Poisson.  
**TEAM VIEW:** Fisher + Pat + Ada → `marginal=`. Noether indifferent if default LA is unchanged.  
**RECOMMENDATION:** `marginal=:VA`.  
**IF YOU DO NOT MIND:** proceed with **`marginal=:VA`**.  
**WHAT CONTINUES:** reversible plan only until G0.

---

## SLICE TABLE (post-G0 `/goal` — sequential)

| Slice | Member | Bar | Model+effort | Dispatch | Time | Detail (files) | Dep |
|---|---|---|---|---|---|---|---|
| S0 RECON | Ada | Cursor Models | Composer / Grok · low | native Cursor Agent | 10m | Diff `b32488d5` Poisson + `_va_reject` vs tip `poisson.jl`; list hunks to port. **Luna-suitable** (mechanical). | — |
| S1 TDD + Poisson dispatch | Noether / Boole | Cursor Models | Composer · med | native Cursor Agent | 45m | Failing `test/test_va_frontend_poisson.jl`; `src/poisson.jl` `marginal` kwarg; `(1\|g)` → `_fit_poisson_ranef_va`; `_va_reject` in `src/variational.jl`; forward through missing-response recursion. | S0 |
| S2 `DrmFit` tag | Fisher | Cursor Models | Composer · med | native Cursor Agent | 25m | `marginal::Symbol=:LA` + `_withmarginal`; thread `_withformula/_withnll/_withranef/_withreml`; default LA for 11-arg ctor. Risk: stop expanding struct if >25m — record and ship S1. | S1 |
| S3 comparison guard | Fisher | Other Models | Auto Cost · med | native Cursor Agent | 15m | `lrtest`/`aic`/`aicc`/`bic`: error if mixed `:LA`/`:VA` (mirror REML guard). | S2 |
| S4 docs honesty | Pat / Rose | Other Models | Auto Cost · med | native Cursor Agent | 15m | `capabilities.md` VA row; `marginal-la-vs-va.md` one-line Experimental Poisson RI (banner stays Planned for epic). | S1 |
| S5 MECHANICAL-VERIFY | Grace | Cursor Models | Composer / Grok · low | native Cursor Agent | 20m | Local `Pkg.test` subset: new frontend + `test_va_poisson_elbo` + `test_variational` + `test_aic_bic`/`comparison`; default Poisson LA smoke. | S1–S4 |
| S6 DoD + PR | Rose / Grace | Other Models | Auto Cost · med | native Cursor Agent | 15m | check-log.d + after-task; PR **not** `closes #136`; OPEN GATE = maintainer merge. | S5 |
| RECONCILE | Melissa | Other Models | Auto Cost · low | native Cursor Agent | 5m | `docs/dev-log/plan-actual/2026-08-08-136-va-poisson-frontend.md` | S6 |

SEARCH: none (not a novelty/priority claim). NotebookLM tier-b **not offered as a gate** — sister GLLVM VA already cited; drmTMB has no VA API.

SLICES: S0→S1→S2→S3; S4 ∥ after S1; S5←all; S6←S5; RECONCILE←S6  
PARALLEL: {S4 ∥ S2/S3 after S1}  
SEQUENTIAL: S0 → S1 → S2 → S3 → S5 → S6

FAN-OUT: 0 children in this planning chat (recon ran inline on the forked parent; no nested spawn). Post-G0: **one `/goal` lane**, not a 6-child fan-out.  
FAN-OUT BUDGET: checkpoint=`136-arc0` · new children=0/6 (plan) · scout=S0 in `/goal` · build=S1–S4 · ceiling=0 · reuse=n/a  
LUNA SUITABILITY: **yes** — S0 + S5 mechanical; on Cursor that is Composer/Grok (Cursor Models), not Codex `tiered-cli`.  
ULTRA EFFORT: no  
CONTEXT BRAKE: parent input=unknown (fork after arc-creation) · **LANE: START A FRESH TASK** for `/goal`  
COMPACTIONS: parent=0 known · boundary=open for this plan chat; `/goal` starts fresh  
AUTO-REVIEW: guardian unknown · action=none  
D-43 PANEL: milestone=not a milestone (narrow frontend; not a release/claim gate) · status=not fired  
MODELS: see table · Bar required  
ESTIMATE: ~2 h wall-clock · 1 session `/goal` · 1 PR · ARC ACTUALS: fill Arc Card Actuals at close  
REVIEW (plan, this turn): **Rose** (receipt + claims) + **Noether** (no kernel rewrite / no stale-branch merge) — both above.  
VERIFY: routing identity `drm(...; marginal=:VA)` ≈ `_fit_poisson_ranef_va`; default LA unchanged; `_va_reject` on FE/phylo/crossed/corr/zi; mixed AIC/LRT errors; Rose no close-#136 / no bias claim.  
CONSOLIDATE: check-log.d + after-task; capabilities honesty; plan-actual.  
RECONCILE: Melissa required (meaningful `src/`+API close).

---

## Execution sketch (only after G0)

1. Fresh chat + `/goal` (prompt below). Pull `main` @ `94a47e8b`. Branch `feat/136-va-poisson-frontend`.
2. Copy this plan → `docs/dev-log/plans/2026-08-08-136-va-poisson-frontend-ultra-plan.md` + LOOP/ kit.
3. S0 inventory `b32488d5` Poisson hunks (do not cherry-pick the whole commit).
4. S1 failing test → wire `marginal` + `_va_reject`.
5. S2–S3 tag + comparison guard (risk branch as table).
6. S4–S6 docs, local tests, DoD, PR, **stop**. OPEN GATE = merge.

---

## Paste-ready `/goal` (after G0 approval)

```
/goal DRM.jl #136 Arc 0 — Poisson public marginal=:VA

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: drm-136-va-poisson   REPO: /Users/z3437171/Dropbox/Github Local/DRM.jl
PLAN: ~/.cursor/plans/136_va_poisson_frontend_94a47e8b.plan.md
DURABLE COPY ON START: docs/dev-log/plans/2026-08-08-136-va-poisson-frontend-ultra-plan.md

READ FIRST: the approved plan → repo AGENTS.md → HANDOVER.md.
SCAFFOLD: LOOP/GOAL.md, LOOP/arcs.md, LOOP/checkpoint.md, LOOP/ultra-plan.md; commit LOOP/ with the durable plan copy.
PLATFORM: Cursor. Tip must be origin/main @ 94a47e8b (pull first).
BRANCH: feat/136-va-poisson-frontend

DELIVERABLE: One PR — Poisson (1|g) drm(...; marginal=:VA) routes to existing
 _fit_poisson_ranef_va; DrmFit tagged; mixed LA/VA AIC/LRT errors; unsupported
 VA rejects; capabilities/guide honesty. #136 stays OPEN.

HEADLINE: reuse kernels; wire public gap only.

IF YOU DO NOT MIND (Q1): keyword is marginal=:VA (default :LA).
 Reject method=:VA on Poisson with a pointer to marginal.

IN SCOPE: src/poisson.jl, src/variational.jl (_va_reject only), DrmFit
 _withmarginal + comparison.jl / aic guards, test/test_va_frontend_poisson.jl,
 runtests include, capabilities.md + marginal-la-vs-va.md honesty, DoD.
 Co-opt pattern from b32488d5 Poisson hunks + _va_reject — do not merge
 shannon/overnight-audit-verify-20260619; do not port 5-family method=:VA.

FENCE: no q=4 core; ML default; no close #136; #49 parked; no R-bridge;
 never stage .worktrees/; no GPL vendoring; no Gamma/Binomial/NB2/Beta public
 VA; no 136e bias report; no kernel rewrite.

FIRST ACTION: git fetch && git checkout main && git pull &&
 git checkout -b feat/136-va-poisson-frontend
 then write failing test/test_va_frontend_poisson.jl

DONE WHEN: PR open (does NOT close #136), local Pkg.test subset green,
 Rose honesty PASS. NEXT GATE: Noether + maintainer merge sign-off.
STOP: do not start rungs 1–4 / 136e in the same PR.
```

---

**Await G0 sign-off; do not execute.**
