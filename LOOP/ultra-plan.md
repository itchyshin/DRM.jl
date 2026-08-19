---
name: Phylo Laplace Cox-Reid
overview: "Ultra-plan Phases 0–2 for B: opt-in Cox–Reid `method = :REML` on Poisson phylo/relmat Laplace (`_fit_poisson_general_laplace` only). Execution waits until AGHQ (#448) has a PR or Shinichi overrides. No ADEMP this G0. #447 already merged; #103 is a closed unrelated issue."
todos:
  - id: s1-wait-aghq-pr
    content: "S1: Wait until AGHQ #448 has a PR (or owner override). Do not start B src/."
    status: pending
  - id: s2-issue-scaffold
    content: "S2: File a NEW B issue; lane_launch.sh DRM.jl phylo-laplace-cox-reid off origin/main"
    status: pending
  - id: s3-tdd-red
    content: "S3: Standalone test_cox_reid_poisson_phylo.jl (TDD red; not in runtests.jl)"
    status: pending
  - id: s4-wire
    content: "S4: Lift structured REML reject; thread reml into _fit_poisson_general_laplace; reuse #444 helpers"
    status: pending
  - id: s5-s8-docs-verify-pr
    content: "S5–S8: docstring honesty, Pkg.test(), Rose check-log/after-task, PR closes #B, Melissa reconcile"
    status: pending
isProject: false
---

# Phylo Laplace Cox-Reid (B)

**Plan-first:** this session entered Cursor Plan mode mid-flight; Phases 0–2 stayed read-only. No Phase 3. No `src/` edits. No AGHQ files claimed. Plan kept in Cursor plans only (do not dirty the merged #447 handover branch).

**Shannon.** Active perspectives: Ada (this plan), Noether, Hopper, Curie, Rose. No nested Task scouts were spawned; Ada ran the mechanical sweep inline.

## GOAL

```
GOAL
Solo platform: Cursor (this session; session_ownership.sh)
Deliverable: one-issue / one-branch / one-PR that admits opt-in method=:REML
  on Poisson routes that call _fit_poisson_general_laplace (phylo + relmat/
  animal / precomputed spatial). ML default unchanged. No recovery headline.
HEADLINE: Poisson phylo Laplace Cox–Reid punch — reuse #444 helpers after
  _withnll. Function name, not frozen line :555 (function starts at
  src/sparse_laplace_glmm.jl:470 on this tree).
IN PARALLEL: none until AGHQ has a PR. #447 already merged (option 1 done).
  #420/#406 not blocking B (skip option 2).
DEFER: AGHQ lever 2 (lane A / #448) · q4 · D-111 · #49 · second family ·
  ADEMP campaign · Cell D as recovery · dual-start A+B · GLLVM LOOP ·
  drmTMB GPL · leftover docs/a3c-design
DISCIPLINE: verify=TDD + Pkg.test() + Rose claim-vs-evidence · compute=local
  Mac (no Totoro this G0) · closure=PR opens closes #<new B issue>
```

**Do not start B `src/` until A (AGHQ) has a PR or the owner overrides.**

## Sweep receipt (Phase 0.25 gate — required)

- **repo git** — `git status -sb`; `branch_drift_check.sh`; `gh pr/issue` — this WS `handover/2026-08-18-cursor` @ `1779c55f`, clean, 0 ahead / 1 behind `origin/main` (`53742f4d` = merge of #447). Call: **do not resume this branch for B**; new worktree off `origin/main`.
- **function** — `_fit_poisson_general_laplace` at [`src/sparse_laplace_glmm.jl`](src/sparse_laplace_glmm.jl):470–556; returns `_withnll` at :555. Callers: `_fit_poisson_phylo_laplace` (:414) and `_fit_poisson_relmat_laplace` (:458). Spatial-coord estimated-ρ is a **different** fitter.
- **#444 wiring** — merged `2dcc5508`. Public `(1|g)` is GHQ-32 via `_fit_poisson_ranef` ([`src/poisson.jl`](src/poisson.jl):208). Structured/phylo still `_reject_reml_route` at :88. Helpers already generic: `_glsp_reml_penalty` / `_glsp_reml_refit_clean` / `_glsp_reml_vcov` / `_withreml`.
- **probe C/D** — [`docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md`](docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md). Cell C: hook viable (penalty vs FD rel 8.29e-04; refit 5 LBFGS). Cell D: ntip=16 / 12 seeds — **not a recovery headline** (ML +8.18%, CR +17.41%).
- **twin drmTMB** — Hopper fence + design 211 / 224. Twin has **Gaussian** structured/phylo REML; Arc 1a **excludes non-Gaussian families**. Public NG REML still gated. O3 is nested AGHQ+CR on `cumulative_logit`, not a TMB `random=` fold. **Co-opt mechanism only** (`½ log|I_ββ|`, ML default). Do not copy O2/O3 or vendor `R/aghq-coxreid.R`.
- **brain** — `search_notes` hybrid `"Cox-Reid phylo Laplace Poisson _fit_poisson_general_laplace REML"` + `"AGHQ lever 2 handover 2026-08-18…"` (`search_all_projects: true`). Semantic hits were mostly older drmTMB/gllvmTMB/Poisson-phylo-q1 notes, not today's B cell.
- **deterministic greps** — `Cox-Reid|phylo Laplace|_fit_poisson_general_laplace` on `memory/AGENT_LOG.md` (2026-08-18 two-lever rec, lines ~295–320), `memory/DECISIONS.md` (Cox-Reid as drmTMB estimator; D-94 sequence), `journal/` (2026-07-19 drmTMB AGHQ/CR landed), `OPEN_QUESTIONS.md` (old Gaussian orthogonality note), `projects/deep-research/README.md` (none).
- **#103** — **real GitHub issue, MERGED, not this plan.** Title: "Add profile curve diagnostics" (`profile_curve` / Fisher). `doo all 103` = planning-chat **options 1+3**, not issue #103.
- **#448** — live AGHQ issue. Body **DEFER B**: do not edit `_fit_poisson_general_laplace`. Foreign lane `claude/lane-aghq-lever-2` @ `~/local-scratch/lanes/DRM.jl-aghq-lever-2` HEAD `0955569f` (brief cited `9966ca79` — stale), dirty `src/aghq_1d.jl` + `src/DRM.jl` + `test/runtests.jl`. **No AGHQ PR yet.** Do not open a second AGHQ issue.

**Verdict:** **build the gap** (wiring). Reuse #444 pattern + generic helpers. Resume nothing (no B branch/issue). #420/#406 are docs-only `CONFLICTING` — **not blocking B**. #447 option-1 human merge **already happened**.

## Preflight / bars / NotebookLM

- **0.2** `lane_preflight.sh`: **FOREIGN LANE ACTIVE (claude)** = AGHQ. Also 3 other Cursor lanes + #420/#406. **Lane claimed (plan-only): `phylo-laplace-cox-reid`.** Do not claim AGHQ files.
- **0.3 / 0.3b:** bars **UNKNOWN** (Usage not read). This plan on **Grok**. `/goal` on **Grok**.
- **0.5:** NotebookLM offered below; **not run**.

## What is already known

- Dual-start A+B is **RETRACTED**. This plan is allowed; B `src/` waits.
- Public `(1|g)` is GHQ-32, not Laplace. Do not punch `_fit_poisson_ranef` again.
- Line `:555` drifts. Durable name: `_fit_poisson_general_laplace`.
- Tree-scale trap: `ape::vcv(corr=TRUE)` = unit tip variance; raw Newick tip variance = height `h`.
- #444 after-task said "ADEMP before `:REML` admitted on Laplace." Owner override for **this G0**: wire only; ADEMP is a follow-on (D-139, Totoro). Honesty: no bias-sign / recovery claim from Cell D.
- Capability row for Poisson REML / AGHQ stays **missing**. No TSV chip. No "has non-Gaussian REML".
- AGHQ already dirties `test/runtests.jl` — B must **not** register tests there this G0.

## Team raised

- **Noether** — hook is proven (Cell C); attach after `_withnll`; reuse unmodified helpers; thread `reml::Bool=false` through phylo + relmat wrappers. Analytic `grad!` already exists (unlike GHQ). Why: wiring, not derivation. Rec: same `_glsp_reml_refit_clean` + `_glsp_reml_vcov` + `_withreml` as #444. Default if "use your judgment": that.
- **Hopper** — twin = drmTMB scalar-RE mechanism, not GLLVM Λ. Cite −7.3/−5.0/−0.9 as drmTMB's. No GPL. Why: license + estimand fence. Rec: copy #444 honesty ledger. Default: that.
- **Curie** — Cell D underpowered; ADEMP needs a larger tree + more seeds **before a recovery sentence**. Why: D-139. Rec: **no ADEMP this G0**; file a follow-on issue only. Default: that.
- **Rose** — one cell, not a capability; do not flip chips; do not headline Cell D; do not steal #420/#406; do not vendor drmTMB. Why: claim-vs-evidence. Rec: docstring warning + tests assert direction/mechanism only. Default: that.
- **Ada** — wait for AGHQ PR because A and B both touch [`src/poisson.jl`](src/poisson.jl) (A: `marginal=:AGHQ` on `(1|g)`; B: lift structured `_reject_reml_route`). `test/runtests.jl` is already dirty on A — B stays standalone.

## Decisions locked (defaults)

- Wire `:REML` only on callers of `_fit_poisson_general_laplace` (phylo + relmat/animal/precomputed spatial). Keep spatial-coord estimated-ρ, crossed, slopes, VA, FE-only rejected.
- No ADEMP campaign this G0. No second family.
- Standalone test file; **do not edit `test/runtests.jl`**.
- New GitHub issue at `/goal` scaffold (not this chat). Do not reuse #448 / #443 / #103.
- New worktree off `origin/main` via `lane_launch.sh`. Do not build on this handover tree, Dropbox `docs/a3c-design`, or catchup `docs/arc1-inventory`.
- Human merges PRs. This worker does not `gh pr merge`.

## Slice table (compact)

- **S0 RECON (done here)** — Ada · Grok · Cursor Models · ~20 min · receipt above · dep: none
- **S1 GATE (human / unattended wait)** — Shannon · n/a · — · until AGHQ PR URL exists or owner override · dep: lane A
- **S2 ISSUE+SCAFFOLD** — Ada · Grok · Cursor Models · ~15 min · `gh issue create` + `lane_launch.sh DRM.jl phylo-laplace-cox-reid` · dep: S1
- **S3 TDD red** — Noether · Grok · Cursor Models · ~30 min · new `test/test_cox_reid_poisson_phylo.jl` (not in runtests) · dep: S2
- **S4 WIRE** — Noether + maintainer sign-off · Grok · Cursor Models · ~60–90 min · `poisson.jl` lift reject; thread `reml` through phylo/relmat wrappers; punch `_fit_poisson_general_laplace` after `_withnll`; update `_reject_reml_route` message · dep: S3
- **S5 DOCS** — Pat/Shannon · Grok · Cursor Models · ~20 min · Poisson docstring + warning (Cell D not recovery; over-correction; ML default) · dep: S4
- **S6 VERIFY** — Karpinski mechanical + Curie honesty · Grok · Cursor Models · ~30 min · `Pkg.test()`; read logs; no recovery sentence · dep: S4
- **S7 ROSE+PR** — Rose · Grok · Cursor Models · ~20 min · check-log.d + after-task + PR `closes #<B>` · dep: S5+S6
- **S8 RECONCILE** — Melissa · Grok · Cursor Models · ~10 min · `docs/dev-log/plan-actual/2026-08-18-phylo-laplace-cox-reid.md` · dep: S7

**PARALLEL after S1:** none (single writer). **SEQUENTIAL:** S1→S2→S3→S4→S5/S6→S7→S8.

**FAN-OUT:** 0 during this planning chat. Execution `/goal` is one Cursor lane (Grok). **SCOUT SUITABILITY:** yes (S0 done). **ULTRA EFFORT:** no. **ESTIMATE:** ~3–5 h after S1 unblocks; one `/goal` session + Rose close. **PREFLIGHT:** FOREIGN claude AGHQ; lane `phylo-laplace-cox-reid`. **REVIEW:** Rose + Noether of this plan (below). **SEARCH:** none; NotebookLM offered, not run.

## Members plan-review (before execute)

- **Rose on receipt:** present and non-vacuous (commands/queries cited). Pass.
- **Rose on scope:** wiring-only, no chip, no Cell D recovery — matches #444 honesty. Pass if S7 keeps that ledger.
- **Noether on slice:** S4 is the only `src/` punch; q4 / `reml_q4.jl` / `gaussian_ranef.jl` stay frozen. Pass.
- **Gap this plan does not close:** ADEMP / larger-tree recovery stays a follow-on issue.

## What execution actually changes (after S1)

In [`src/poisson.jl`](src/poisson.jl) ~88, stop rejecting structured REML for routes that call `_fit_poisson_general_laplace`; keep rejecting spatial-coord estimated-ρ, crossed, slopes, VA, FE-only.

Thread `reml::Bool=false` through `_fit_poisson_phylo_laplace` and `_fit_poisson_relmat_laplace` into `_fit_poisson_general_laplace`. After the existing `_withnll` (today :555), if `reml`: `grad_fn` from existing `grad!`, then `_glsp_reml_refit_clean` + `_glsp_reml_vcov` + `_withreml` — same as [`src/poisson.jl`](src/poisson.jl):244–254, except this spine already has an analytic gradient.

Tests assert: `estimation_method === :REML`; σ̂_CR > σ̂_ML per seed (penalty direction); reml_loglik ≠ ml_loglik; uncertified routes still error; Binomial still rejects; GHQ `(1|g)` cell untouched; no recovery target.

## Fences

no AGHQ files · no second AGHQ issue · no q4 · D-111 OFF · #49 PARKED · ML default · twin=drmTMB · no steal #420 #406 · no src on leftover docs/a3c-design · never mutate GLLVM LOOP/GOAL.md · never vendor drmTMB · never git add -A · Cell D not recovery · tree-scale trap · public (1|g) is GHQ-32 · do not edit `test/runtests.jl` · no `gh pr merge`

## Questions (D-148 drafted replies)

1. **Start B `src/` when AGHQ has an OPEN PR, or only after AGHQ MERGES?** WHY NOW: file overlap on `poisson.jl`. TEAM: Ada wait-for-PR (rebase onto A's diff). **RECOMMENDATION / IF YOU DO NOT MIND: OPEN PR is enough** (matches your brief). WHAT CONTINUES: S2 scaffold can wait; no `src/` until then.
2. **Admit relmat/animal on the same spine, or phylo-only?** WHY NOW: both wrappers share the function. TEAM: Noether all callers; Curie still no ADEMP. **RECOMMENDATION / IF YOU DO NOT MIND: all `_fit_poisson_general_laplace` callers**; keep spatial-coord estimated-ρ rejected.
3. **Want a NotebookLM grounded pass on Cox–Reid / Laplace phylo REML first?** WHY NOW: Phase 0.5 offer. TEAM: Hopper twin already mapped; novelty claim is not this G0. **RECOMMENDATION / IF YOU DO NOT MIND: skip.** Wiring, not a literature claim.

## Paste-ready /goal (after G0 approval — do not run in this chat)

```
/goal

Ultra-plan G0 approved. Run plan B to completion via LOOP/.

LANE: phylo-laplace-cox-reid
REPO: DRM.jl
PLAN: this Cursor plan (Phylo Laplace Cox-Reid)

READ FIRST: this plan → repo AGENTS.md →
  docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md →
  docs/dev-log/after-task/2026-08-18-cox-reid-poisson-ranef-wiring.md →
  docs/dev-log/evidence/2026-08-18-hopper-cox-reid-gllvm-fence.md

SCAFFOLD: ~/shinichi-brain/tools/lane_launch.sh DRM.jl phylo-laplace-cox-reid
  — NEW worktree off origin/main. Do NOT use the handover tree, Dropbox
  docs/a3c-design, catchup, or ~/local-scratch/lanes/DRM.jl-aghq-lever-2.
  Write LOOP/GOAL.md, LOOP/arcs.md, LOOP/checkpoint.md, LOOP/ultra-plan.md
  from the plan; commit the kit.

HARD GATE: do not start src/ until AGHQ (#448) has a PR URL, or Shinichi
  says go. If no PR, STOP after LOOP scaffold + file a NEW GitHub issue
  for B (do not reuse #448 / #443 / #103). Then wait.

START ARC: S2 (issue + worktree) if AGHQ PR exists; else S1 wait.
NEXT GATE: human merge of B's PR (do not gh pr merge).

Fences: no AGHQ files · no q4 · D-111 OFF · #49 PARKED · ML default ·
  twin=drmTMB · no steal #420 #406 · Cell D not recovery · tree-scale trap ·
  public (1|g) is GHQ-32 not Laplace · no test/runtests.jl · no GPL ·
  never git add -A · never mutate GLLVM LOOP/GOAL.md.
```
