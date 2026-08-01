# Ultra-plan — DRM.jl point 2: registry/hygiene → Phase 1.5 bridge

**Phases covered:** 0–2 planned; **Phase 3+ EXECUTION APPROVED** 2026-08-01 (Shinichi; Q1–Q3 locked below).
**PLATFORM (this session):** Cursor / Claude (Shannon speaking; Ada orchestrates).
`session_ownership.sh` printed `PLATFORM: unknown` — overridden by explicit solo-platform assignment in the brief: **this Cursor/Claude session**.
**Date:** 2026-08-01 · **Arc name:** ultra-plan point 2 (registry → bridge)

---

```
🎯 GOAL — paste into a fresh session

PLATFORM: Cursor/Claude (this session / Shannon+Ada). Do NOT hand to Codex unless
explicitly reassigned. HANDS TO: none.

DELIVERABLE: (1) Julia General-registry readiness + hygiene gate on a clean base
(#8 / scoped #3), then (2) Phase 1.5 R↔Julia bridge ship checklist against #5 —
DRM.jl side + drmTMB `engine = "julia"` contract — with Hopper parity evidence
and Rose claim-vs-evidence closeout. Plan artifact already at
docs/dev-log/plans/2026-08-01-ultra-plan-registry-bridge.md; execution waits for
Shinichi sign-off.

HEADLINE: After #339 merges into shannon/ayumi-integration, land a clean
registry/hygiene PR onto the agreed integration base, then finish Phase 1.5 bridge
honestly (reuse the large existing bridge surface — do not rebuild).

IN PARALLEL (cheap, after merge gate): Haiku/Scout recon of registry checklist vs
main tip; Hopper inventory of drmTMB julia-bridge admitted cells vs DRM.jl
drm_bridge exports; Grace CI/Aqua/TagBot green-read.

DEFER (hard fence — do not open in this arc):
  • VA/ELBO alternative marginal (#136) — scaffold may exist; no promotion, no
    public claim, no estimator work.
  • REML speed / AI-REML track (#291) — correctness of #337 is done; speed is later.
  • Do NOT dump the 4 unrelated local AGENTS/Ranganathan commits on
    drmjl/sigma-phylo-reml-beta-psi-fix (a4585bd, 7520d9d, 88a2382, 66514a0)
    into registry or bridge PRs.
  • (OVERRIDDEN by Q2=FULL) Wire remaining experimental/ including fit_em_natgrad #13;
    Rose-honest about reml_q4/location_only already promoted — do not re-claim.

DISCIPLINE: verify before claiming (local Pkg.test + Aqua before Registrator);
compute = Totoro for any multi-shape / parity matrix, laptop only for smoke;
closure = Rose audit + Melissa reconcile + after-task on the executing branch.
Merge #339 only when Shinichi says so (MERGEABLE/CLEAN as of plan time).
```

---

## Context (one paragraph)

Step 1 is done: **#337** (σ-phylo REML must restrict β_μ **and** β_ψ) is **MERGED** into `shannon/ayumi-integration` (`dc96273`). **PR #339** (docs-only `docs/design/capability-status.md` for Mission Control parity) is **OPEN**, base `shannon/ayumi-integration`, **MERGEABLE / CLEAN**, and deliberately excludes the four local AGENTS commits. Mission Control `drmTMB.json` `next_safe_action` already points here: merge #339, then ultra-plan #2 = registry/hygiene → Phase 1.5. This plan scopes that #2 arc only.

---

## Phase 0.25 — Prior-work sweep RECEIPT

| Surface | Evidence ran | Finding | Call |
|---|---|---|---|
| **repo git state** | `git status -sb` (on `drmjl/sigma-phylo-reml-beta-psi-fix`, ahead 4 / behind 1 of its origin); `git worktree list` (many locked agent worktrees + `.worktrees/capability-status` @ `docs/capability-status-parity`); `bash ~/shinichi-brain/tools/branch_drift_check.sh` → **25 ahead / 51 behind `origin/main`**; `git rev-list --left-right --count origin/main...shannon/ayumi-integration` → **51 behind / 20 ahead**; `git rev-list … docs/capability-status-parity` → **51 behind / 24 ahead**; tip of capability branch includes `dc96273` Merge #337 + `0a6f8b4` capability-status; four tip commits `a4585bd`…`66514a0` are AGENTS/Ranganathan/coord only | Dirty/drifted REML tip is **not** the ship base. #337 is on ayumi + #339 branch, **not** on `origin/main`. #339 is the merge gate. | **resume** `docs/capability-status-parity` / ayumi for docs land; **fence** REML tip's 4 AGENTS commits; **build-the-gap** registry+bridge from a clean worktree off agreed base after #339 |
| **twin / sister (drmTMB)** | `rg` + `R/julia-bridge.R` (4363 lines); `git ls-tree origin/main R/julia-bridge.R` present; `DESCRIPTION` Suggests `JuliaCall`; vignette `julia-engine.Rmd` + NEWS `#544/#555` Julia REML bridge notes; many historical `shannon/bridge-*` / `codex/julia-*` branches; current drmTMB WT on `claude/handover-freshness-0718` (dirty, unrelated REML/AGHQ work) | Bridge is **already shipped experimentally** on drmTMB main (`engine = "julia"` → JuliaCall → `DRM.drm_bridge*`). Gap is finish/parity/honesty for Phase 1.5 checklist (#5), not greenfield Lovelace glue. | **reuse / co-opt** existing R bridge + DRM.jl `src/bridge.jl`; **build-the-gap** = admitted-cell matrix, result-shape parity, bf round-trip, Rose claim fence |
| **brain** (`search_notes`, `search_all_projects: true`) | Queries: `DRM.jl registry hygiene Phase 1.5 R Julia bridge JuliaCall`; `DRM.jl VA ELBO REML speed registry #8 #3 #5 bridge decision`; `Julia General registry DRM.jl registration TagBot Aqua hygiene shannon/a1-registry`; `DRM.jl registered General registry v0.1.0 decision D-` (project `shinichi-brain`) | Hits: after-tasks for `drm_bridge` entry (#5 tracker), julia-via-R audits, gate-id registry (drmTMB#544), HANDOVER "Next = General-registry submission"; **no** decision saying "DRM.jl is already in General". Mission Control status file confirms #337 done + #339 next. VA (#136) and REML-speed (#291) remain separate open ideas. | **reuse** bridge audits + a1-registry hygiene already ancestral to `origin/main` (`f86645b` / Aqua path); **build-the-gap** = actual Registrator/General submission + Phase 1.5 closeout evidence; **park** #136/#291 |
| **external / NotebookLM** | Not run (no novelty / "first to" claim in this arc) | N/A | **Offer only** if Shinichi wants prior-art on Julia Registrator norms — not required to decompose |

**Verdict:** Genuine new work = (A) **merge-gate #339**, then (B) **registry submission + residual hygiene** on a clean base (#8 + scoped #3), then (C) **Phase 1.5 bridge finish** (#5) reusing the large existing twin surface. Do **not** rebuild bridge or re-land a1-registry. **DEFER** VA (#136) and REML-speed (#291).

---

## Phase 0.3 — Live model-roster (this platform)

| Tier | This session (Cursor → Task models) | Effort |
|---|---|---|
| Scout / mechanical | `composer-2.5-fast` or Claude Haiku-class if Claude Task used | low–medium |
| Build / default | parent Composer / Claude Sonnet-class | medium–high |
| Ceiling / verify | Claude Opus/Fable-class or `gpt-5.6-sol-*` only if handed to Codex | high |

Volatile roster file `~/shinichi-brain/memory/MODEL-ROUTING.md` last Claude refresh **2026-07-25** (Opus 5 / D-81). No web refresh needed for this plan. **LUNA/Haiku suitability: yes** — RECON + MECHANICAL-VERIFY are bounded read-only.

---

## WHAT THE BRAIN / REPO ALREADY KNOWS

- Sequence agreed: finish #337 → registry/hygiene (#8/#3) → Phase 1.5 (#5); DEFER #136, #291.
- #337 merged to **ayumi-integration**, not yet to **origin/main**.
- #339 MERGEABLE/CLEAN into ayumi; docs-only; closes #338; excludes 4 AGENTS commits.
- Tags **v0.1.0 / v0.1.1** exist; HANDOVER still lists **Julia General-registry submission** as Next; local General registry has **no** `DRM/Package.toml` (not installed/registered locally).
- `shannon/a1-registry` hygiene tip is **already ancestral to `origin/main`**; residual register-ready commits live on `claude/julia-package-register-ready-SuLOC` (**3 ahead / 178 behind** main) — cherry-pick candidates only after rebase check.
- DRM.jl already exports `drm_bridge` / `drm_bridge_inference`; drmTMB main already has `R/julia-bridge.R` + JuliaCall Suggests + `vignette("julia-engine")`.
- ROADMAP Phase 1.0 still partial (`reml_q4` / `fit_em_natgrad` unwired); issue #13 is EM natgrad — **out of default hygiene scope**.
- License: DRM.jl MIT; never vendor drmTMB GPL (Rose).

## WHAT SHINICHI TOLD US (this brief)

- Plan-first Phases 0–2 only; no code edits beyond the plan file; no merges/pushes.
- Default sequence + DEFER fences as above.
- Solo platform = this Cursor/Claude session.
- Do not dump the 4 local AGENTS commits into this work.
- Note #339 merge gate if still open (it is).

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Ada    — Merge #339 is the hard gate before any ship branch; ayumi is 51 behind
           main so registry work needs an explicit base-branch decision.
           · matters: wrong base → replay conflicts (#4/#5 trap)
           · rec: merge #339 → choose base (Q1) → fresh worktree
           · default if "use your judgment": base = origin/main + cherry #337+#339
             design file only if ayumi not ready to integrate
  Rose   — HANDOVER/ROADMAP still drift on experimental wiring + "Next: registry";
           capability-status design file corrects 3 stale capabilities.md claims
           without rewriting the audit page — keep that honesty.
           · rec: registry PR must not claim bridge "done" or reml_q4 "public"
           · default: Rose blocks any README/registry blurb that oversells Phase 1.5
  Hopper — Bridge surface already large on both sides; Phase 1.5 is a finish matrix
           (admitted cells, result-shape, bf round-trip, unsupported-cell honesty),
           not a new JuliaCall scaffold.
           · rec: inventory-first against drmTMB#544 gate registry + DRM tests
           · default: expand no new family through the bridge in this arc
  Grace  — Registry needs green local Pkg.test + Aqua + Linux CI; TagBot/Documenter
           already present from Phase 0.
           · rec: hygiene slice = CI green on register-ready tip before Registrator
           · default: no macOS/Windows CI expansion (cost discipline)
  Lovelace — R glue lives in drmTMB; DRM.jl owns stable drm_bridge contract.
           · rec: any bridge finish PR pair must name which repo owns which file
           · default: DRM.jl-only changes first if R surface already admits the cell
  Noether — Do not touch verified q=4 engine / logLik −256.51 baseline for registry.
           · default: hygiene is load-print / API docstring / Aqua — not estimator
```

## ADA'S RECOMMENDATION

1. **Shinichi merges #339** (or explicitly asks this session to merge) into `shannon/ayumi-integration`.
2. Answer **Q1–Q3** below (base branch, #3 scope, bridge Definition of Done).
3. Then execute slices S0→S5 on a **fresh worktree**; fence AGENTS commits and #136/#291.

## DECISIONS LOCKED (from prior + Shinichi approval 2026-08-01)

| ID | Decision |
|---|---|
| Seq | #337 → #339 → registry/hygiene → Phase 1.5 |
| **Q1 BASE** | **YES — Ada rec A.** After #339 merges, integrate `shannon/ayumi-integration` ↔ `main` before Registrator (**not** cherry-only onto main). |
| **Q2 #3 SCOPE** | **FULL** — not scoped hygiene only. Wire remaining `experimental/` as Phase 1.0 intends (include `fit_em_natgrad` #13 and related reml/location_only as applicable per ROADMAP/HANDOVER). Be **Rose-honest** about what's already promoted (`reml_q4` + `location_only` already in `src/` on main). Do **NOT** dump the 4 unrelated AGENTS/Ranganathan commits from `drmjl/sigma-phylo-reml-beta-psi-fix`. |
| **Q3 #5 SHIPPED BAR** | **OK — Hopper finish-matrix.** Admitted cells + result-shape for Gaussian uni/bivariate/first phylo mean + gate-ID rejections; stay **experimental**; **no new families**. |
| DEFER | #136 VA/ELBO; #291 REML speed (**hard fence**) |
| Fence | 4 AGENTS/Ranganathan commits on REML tip stay out |
| Platform | Cursor/Claude this session |
| License | MIT; no GPL vendoring |
| Registrator | Do **not** submit without explicit Shinichi say-so even after green |

## QUESTIONS — CLOSED (answers above)

### Execution status (live)

| Gate | Status |
|---|---|
| S1 #339 merge | **DONE** — MERGED 2026-08-01T13:06:15Z into `shannon/ayumi-integration` @ `7cb868d` (capability-status on tip) |
| S2 ayumi↔main | **IN PROGRESS** (this session) |
| S3 FULL #3 + hygiene | queued after S2 |
| S4 Registrator | blocked on Shinichi explicit OK |
| S5 Phase 1.5 #5 | Hopper bar; after API-stable S3 |

---

## Phase 0.4 — Questions for Shinichi (max 3)

**QUESTION 1 — Integration base for registry/hygiene**
· **WHY NOW:** ayumi is **20 ahead / 51 behind** `origin/main`; #337+#339 live on ayumi, not main. Registry PRs from a drifted tip replay the conflict trap.
· **TEAM VIEW:** Ada + Grace want a named base; Rose wants claim surfaces consistent with main docs.
· **RECOMMENDATION:** **Option A (preferred):** merge #339 → open a short ayumi→main integration PR (or rebase ayumi onto main) **before** Registrator; do registry from the integrated tip. **Option B:** registry from `origin/main` + minimal cherry of #337 engine fix + capability-status file only.
· **IF YOU DO NOT MIND:** Option A.
· **WHAT CONTINUES:** #339 stays merge-ready; plan writing; no Registrator yet.

**QUESTION 2 — Scope of #3 inside "registry/hygiene"**
· **WHY NOW:** #3 is the whole Phase 1.0 milestone (wire experimental + Manifests + Workflow Q/R). Full #3 would swallow the bridge arc.
· **TEAM VIEW:** Noether/Ada — scope #3 to **package hygiene for General registry** (Aqua green, silence load-time print, docstring/HANDOVER honesty, register-ready metadata); defer `reml_q4` / `#13 fit_em_natgrad` / Workflow R.
· **RECOMMENDATION:** **Scoped #3** = registry hygiene only; leave experimental wiring as follow-on issues.
· **IF YOU DO NOT MIND:** Scoped #3.
· **WHAT CONTINUES:** Inventory of residual SuLOC commits vs main.

**QUESTION 3 — Phase 1.5 "shipped" bar for #5**
· **WHY NOW:** twin already has experimental `engine = "julia"`; #5 checklist still open (JuliaCall bridge / result-shape / bf round-trip). Need the closeout bar so Hopper/Rose don't move the goalposts mid-arc.
· **TEAM VIEW:** Hopper — close #5 when (i) admitted-cell matrix is published + tested, (ii) result-shape parity for the **Gaussian uni + bivariate + first phylo mean** slice matches native drmTMB fields needed by vignette, (iii) unsupported cells error with gate IDs, (iv) Rose accepts "experimental" wording. Lovelace — no new family cells in this arc.
· **RECOMMENDATION:** Adopt Hopper's bar; keep status **experimental** in NEWS/vignette; do not claim CRAN/registry dependency on JuliaCall for drmTMB (Suggests only).
· **IF YOU DO NOT MIND:** Hopper bar above.
· **WHAT CONTINUES:** Read-only matrix draft after approval.

**NotebookLM offer (optional, not blocking):** Want a short grounded pass on current Julia General Registrator / AutoMerge norms? Default = **no** (process is well-trodden; not a novelty claim).

---

## Phase 1 — Decomposition (slices)

### SLICE TABLE

| ID | Member | Model+effort | Dispatch | ~Time | Detail / output | Dep |
|---|---|---|---|---|---|---|
| **S0 RECON** | Ada+Scout | Haiku / composer-fast · low | native/explicit | 20–40m | Fresh drift vs main+ayumi; residual SuLOC vs main; registry checklist file `docs/dev-log/plans/registry-checklist-2026-08-01.md` | #339 merged (or explicit skip) |
| **S1** Merge gate | Shannon (human/gh) | — | manual | 5–15m | Merge PR #339 into `shannon/ayumi-integration` when Shinichi approves; confirm tip = capability-status without AGENTS commits | Shinichi |
| **S2** Base integrate | Ada+Grace | Sonnet · medium | native/explicit | 1–3h | Per Q1: ayumi↔main integration or cherry path; fresh worktree; **no** AGENTS commits | S1, Q1 |
| **S3** FULL #3 + registry hygiene | Grace+Rose+Noether (+Karpinski Aqua) | Sonnet · medium–high | native/explicit | 4–8h | **FULL #3** (Q2 override): wire remaining `experimental/` (`fit_em_natgrad` #13 + related); Rose-honest HANDOVER (reml_q4 + location_only already promoted); plus #8 load-print/Aqua/Pkg.test/register metadata. **No** AGENTS dumps. **output:** PR(s) closing #3/#8 as earned | S2, Q2 |
| **S4** Registrator | Grace+Rose | Sonnet · medium | native/explicit | 1–2h + wait | Tag policy (reuse v0.1.1 vs bump); submit General registry PR; watch AutoMerge | S3, Shinichi tag OK |
| **S5** Phase 1.5 bridge finish | Hopper+Lovelace (+Boole bf) | Sonnet · medium–high | native/explicit | 4–8h | #5 matrix: admitted cells, result-shape tests, bf round-trip where CI allows; drmTMB vignette honesty; DRM.jl `r-julia-bridge.md` sync; **no new families** | S3 (stable API), Q3 |
| **S6 MECHANICAL-VERIFY** | Scout | Haiku · low | native/explicit | 30–60m | Re-read PR diffs, issue checklists, CI conclusions, fence DEFER items still closed | S4–S5 |
| **S7** Rose plan+ship audit | Rose | Sonnet→Opus if claim gate · medium–high | native/explicit | 45–90m | Claim-vs-evidence on registry README + bridge "experimental" wording; license boundary | S6 |
| **S8 RECONCILE** | Melissa | Sonnet · low–medium | native/explicit | 20–40m | `docs/dev-log/plan-actual/2026-08-01-registry-bridge.md` | S7 |

**PARALLEL after S2:** S0 leftovers / matrix inventory can overlap S3 drafting; **S4 sequential after S3**; **S5** may start inventory in parallel with S3 but must not change public bridge claims until S3 API freeze.

**SEQUENTIAL spine:** S1 → S2 → S3 → S4; S5 finishes after API-stable S3; S6→S7→S8 close.

### Explicit DEFER fences

```
DEFER — do not schedule, implement, or "just quickly" open:
  [#136] VA/ELBO marginal (variational.jl scaffold stays untouched)
  [#291] REML speed / AI-REML / q4 acceleration
  dumping commits a4585bd / 7520d9d / 88a2382 / 66514a0 into ship PRs
  (Q2=FULL: #13 fit_em_natgrad + related reml/location_only honesty ARE in scope for S3;
   reml_q4/location_only already promoted on main — do not re-claim as new)
```

### #339 merge gate (status at plan time)

| Field | Value |
|---|---|
| URL | https://github.com/itchyshin/DRM.jl/pull/339 |
| State | **OPEN** |
| mergeable | **MERGEABLE** |
| mergeStateStatus | **CLEAN** |
| base ← head | `shannon/ayumi-integration` ← `docs/capability-status-parity` |
| Includes | #337 merge `dc96273` + capability-status `0a6f8b4` |
| Excludes | 4 AGENTS commits on REML tip |
| Action | **Shinichi (or session after approval) merges** before S2 |

---

## Phase 2 — Runnable plan metadata

| Field | Value |
|---|---|
| **SEARCH** | none required; NotebookLM offered (default no) |
| **FAN-OUT** | ≤6 children / checkpoint `registry-bridge-2026-08-01`; 1 scout RECON, 2–4 build, 0–1 Rose ceiling if claim gate |
| **FAN-OUT BUDGET** | checkpoint=registry-bridge-2026-08-01 · new children≤6 · scout=1 · build≤4 · ceiling≤1 · reuse on repair |
| **LUNA SUITABILITY** | yes — S0 RECON + S6 MECHANICAL-VERIFY |
| **ULTRA EFFORT** | no |
| **CONTEXT BRAKE** | parent unknown · fresh-task if session compacts twice |
| **COMPACTIONS** | open |
| **LANE RECEIPT** | CONTINUE HERE for Q&A; START A FRESH TASK for execution after approval |
| **D-43 PANEL** | milestone=`registry-or-bridge-ship` · fire once when claiming registered or #5 closed · 2 build + 1 ceiling |
| **ESTIMATE** | wall-clock **~1–2 working days** after answers (registry AutoMerge wait extra); fits **one execution session + registry wait handoff** |
| **ARC PROGRAM** | Arc 0 = this plan (~now); Arc 1 (2–4h) hygiene PR; Arc 2 (4–8h) bridge finish; integration/closeout 1h |
| **REVIEW (plan)** | Rose confirms this receipt is non-vacuous ✅; Hopper confirms bridge = finish-not-rebuild ✅ |
| **VERIFY** | local `Pkg.test` + Aqua; Workflow G / bridge tests where R available; CI Linux; Rose audit |
| **CONSOLIDATE** | after-task + check-log.d + Mission Control status refresh + close #8/#5 checklists as earned |
| **RECONCILE** | Melissa → `docs/dev-log/plan-actual/2026-08-01-registry-bridge.md` |
| **COMPUTE** | Totoro for any multi-shape / parity matrix; laptop smoke OK; **not** GHA for heavy benches (D-50) |

### Members plan-review (pre-execution)

- **Rose:** Sweep receipt present with cited commands/queries — **PASS**. Plan does not smuggle VA/REML-speed. Risk: calling #5 "ship" while vignette still says experimental — mitigated by Q3.
- **Hopper:** Decomposition correctly treats bridge as finish matrix; warns against dual-repo drive-by on dirty drmTMB WT (`claude/handover-freshness-0718`) — execution must use clean drmTMB worktree/main.

---

## Execution trigger (Phase 3 — NOT started)

Do **not** begin S1–S8 until Shinichi answers Q1–Q3 (or says *"use your judgment"*) **and** explicitly approves leaving plan-only mode. Preferred first execution prompt:

> Approved. Merge #339. Use Ada defaults on Q1–Q3. Execute ultra-plan point 2 from `docs/dev-log/plans/2026-08-01-ultra-plan-registry-bridge.md`. Fence AGENTS commits, #136, #291.

---

## Issue map (ledger)

| Issue | Role in this arc |
|---|---|
| #337 | Done (merged to ayumi) |
| #339 / #338 | Merge gate (docs capability-status) |
| #8 | Registry / v0.1.x release gate — primary hygiene+register target |
| #3 | **FULL** Phase 1.0 wire (Q2 locked) |
| #5 | Phase 1.5 bridge finish |
| #13 | **IN SCOPE** via Q2=FULL |
| #17 | Parity gate — may support S5; not a blocker for Registrator if R CI absent |
| #136 | **DEFER** |
| #291 | **DEFER** |
