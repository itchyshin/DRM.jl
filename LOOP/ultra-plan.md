# LOOP/ultra-plan.md — frozen at G0 approval (2026-08-09)
Binding copy of the approved #136e honest public-path VA bias report plan.
Do not re-plan mid-loop. Source: ~/.cursor/plans/136e_va_bias_report_9cc79df2.plan.md

# #136e honest public-path VA bias report

GOAL
Solo platform: Cursor (this session; execution after G0 via `/goal`)
Deliverable: One PR from `origin/main` @ `cc113cbb` (#403 MERGED) that lands `report/va-vs-laplace-bias.md` with a measured ADEMP comparison of public Gamma `(1|g)` Laplace vs VA on shape α = 1/σ². Docs stay Experimental. Issue #136 stays OPEN.
HEADLINE: Measure the public path honestly — if simple Gamma RI does not reproduce GLLVM’s ~7× two-part cell, say so (Rose). That still closes 136e-as-scoped.
IN PARALLEL: none required after smoke (linear). Optional NB2 control only if Arc 0 finishes early.
DEFER: ZINB / Delta-Gamma / `zi`/`hu`×RE; phylo/crossed/`sigma ~ x` public VA; closing #136; flipping Experimental → Implemented; q=4; D-111; `.worktrees/`; drmTMB from this tree; GPL vendoring.
DISCIPLINE: verify=read the smoke log not exit code · compute=local smoke first; Totoro only if n-ladder after smoke (not GHA / D-50) · closure=report + Rose + PR open, owner merges.

Why both skills: you asked. Arc Creation sizes the unit; Ultra Plan owns the GOAL, sweep receipt, and `/goal` handoff. Gate fired: ~3 h + Rose claim gate + compute fork + #136 must stay open.

---

## ARC CARD — 136e public Gamma bias report

**Mode:** size
**Requested outcome:** not quantified — a Rose-honest report on the *public* VA path
**Mechanism authority:** new branch from tip; report + docs honesty + optional smoke script; local Julia; Totoro only after smoke warrants n-ladder. No kernel rewrite; no merge; no `closes #136`.
**Recommended arc:** ~3 h (range 2.5–4 h)
**Time contract:** ceiling ~4 h
**Estimate confidence:** inferred (Rung 1 frontend tests already use G=40/per=10 α=4; no prior 136e recovery sweep)
**Arc 0 outcome:** ADEMP written + 1–3 local reps + `report/va-vs-laplace-bias.md` stating measured bias (or honest non-reproduction)
**State transition:** no 136e artefact → report exists; Experimental banner held; #136 OPEN
**Executable rung and evidence:** local LA+VA `drm` fits on simulated Gamma RI; retain script + log + report numbers

Capacity ladder (size mode, recommended >3 h so listed):
- Arc 0 (~90–120 min): ADEMP + smoke + report skeleton with real numbers
- Rung 1 (~60–90 min, only if smoke shows material LA–VA shape gap): n-ladder / MCSE; Totoro if local n_sim would drag
- Rung 2 (~30–45 min, only if Arc 0 early): NB2 `(1|g)` control cell (expect milder gap)
- Integrate/close (~30 min): docs cite report; check-log; after-task; LOOP; PR

Budget (Arc 0): Orient 20 · Core 50 · Verify 20 · Repair 15 · Closeout 15 · Total ~120 min

**In scope:** public `drm(...; Gamma(); marginal=:LA|:VA)` with `sigma ~ 1` and `(1 | g)`; estimand α = exp(−2 · log σ)
**Not in this arc:** ZINB; Delta-Gamma; wiring `zi`/`hu`+RE; “implemented everywhere”; closing #136
**Evidence used:** [docs/dev-log/decisions/2026-06-02-va-marginal-design.md](docs/dev-log/decisions/2026-06-02-va-marginal-design.md) §5; [docs/src/model-guides/marginal-la-vs-va.md](docs/src/model-guides/marginal-la-vs-va.md); [test/test_va_frontend_families.jl](test/test_va_frontend_families.jl) Gamma block (α=4, G=40); GLLVM `test_va_vs_laplace.jl` Delta-Gamma is sister motivation only — do not vendor
**Risk branch:** If 1-rep smoke fails to converge or α is non-finite, stop n-ladder; diagnose; report the failure. If LA≈VA on α, that is the finding — do not hunt a 7× by changing the DGP into an unwired two-part model.

**Done when:** report file exists with ADEMP + measured numbers + explicit “not ZINB / not two-part / Experimental held / #136 open”; Rose PASS; PR open.
**First action after G0:** `git checkout -b feat/136e-va-bias-report origin/main` then write ADEMP into the report stub before any multi-rep run.

HAND TO `/goal` after this plan is approved (do not execute Phase 3 in this planning chat).

---

## PHASE 0.25 — SWEEP RECEIPT

- **repo git:** `git status -sb`; `git rev-parse HEAD origin/main`; `gh pr list --state open`; `branch_drift_check.sh` → clean `main` == `origin/main` @ `cc113cbb` (Merge #403). No open PRs. Stashes unrelated. `.worktrees/` exist — never stage. → nothing to resume; fresh `feat/136e-va-bias-report`.
- **this-repo code:** `report/va-vs-laplace-bias.md` **absent**; public Gamma VA wired in [src/gamma.jl](src/gamma.jl) (`α = 1/σ²`); frontend test at [test/test_va_frontend_families.jl](test/test_va_frontend_families.jl) L95–118; ZI+RE rejected in [src/negbinomial.jl](src/negbinomial.jl) / [src/poisson.jl](src/poisson.jl) for both LA and VA. → **build the report gap**; reuse public `drm` path; do not resume overnight-audit.
- **twin / sister:** drmTMB Laplace-only (no VA parity cell). GLLVM worktree `test/test_va_vs_laplace.jl` — headline 7× cell is **Delta-Gamma**, not simple Gamma. → reuse motivation; do not vendor; do not claim DRM reproduced Delta-Gamma.
- **brain:** MCP `search_notes` (`DRM.jl Julia lane G0`, `D-111 DRM.jl VA #136`); deterministic `grep -in "136e|va-vs-laplace|bias-recovery"` on `AGENT_LOG.md` (today’s START HERE only), `DECISIONS.md` (D-111 OFF, no 136e decision), `OPEN_QUESTIONS.md` (none), `projects/deep-research/README.md` (dr25 gllvmTMB VA — different estimand). → **reuse** Experimental honesty + D-111 fence; **build** the public-path ADEMP report.
- **Verdict:** genuinely new = measured DRM public-path bias report + docs citation. Not new = kernels, frontend, anchors a/b/c, Experimental banner. **reuse public path / build report / do not resume ZI×RE.**

Rose (plan review): receipt cites commands/queries — gate PASS for decompose.

---

## WHAT THE BRAIN / REPO ALREADY KNOWS · WHAT YOU TOLD US

- Tip `cc113cbb`; #136 OPEN; #403 MERGED; drmTMB sibling unknown — do not start from here.
- Public VA = Experimental `(1 | g)` on five families. Keyword is `marginal=:VA` not `method=:VA`.
- Original 136e promised Gamma 7× + ZINB BLAS stability + docs Planned→Implemented. That contract is **superseded** by your lock: **public-honest**.
- D-111 OFF. ML default. ELBO ≠ logLik.

**DECISIONS LOCKED**
- Estimand: Gamma shape α = exp(−2 · `coef(fit,:sigma)[1]`) on `sigma ~ 1` + `(1 | g)`.
- Methods: same DGP, `marginal=:LA` vs `:VA`.
- ZINB / Delta-Gamma / `zi`/`hu`×RE: named as **not public**; out of this PR.
- Docs: keep Experimental; cite the report; do **not** flip to Implemented; do **not** `closes #136`.
- Compute: 1–3 local smoke reps first; Totoro only if n-ladder; never GHA.
- Branch from `origin/main` `cc113cbb`, not the old handover branch.

**QUESTIONS STILL OPEN (execution triggers only):** Totoro vs stay-local if smoke shows a real gap and n_sim would exceed ~15 min laptop. Pause that slice; continue report prose.

**SEARCH:** none required (no novelty/priority claim). NotebookLM offered, not gated.

---

## ADEMP (write this into the report before multi-rep)

Cite Morris et al. 2019 and Williams et al. 2024.

- **A:** Primary — does public Gamma RI VA recover α closer to truth than LA? Secondary — if not, document that the motivating 7× geometry is two-part/Delta-Gamma (unwired here).
- **D:** `y_ij ~ Gamma(α, μ_ij/α)`, `log μ = β0 + βx x + b_g`, `b ~ N(0,σb²)`. Start from the existing frontend fixture: α=4, G=40, per=10, β≈(0.4, 0.5), σb=0.5, seed recorded. Vary only after smoke.
- **E:** α (headline); β and σb as diagnostics. Truth from DGP; estimator from `drm` coef mapping.
- **M:** `drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gamma(); data, marginal=:LA|:VA)`.
- **P:** bias, relative bias, RMSE; MCSE after any n-ladder. n_sim from MCSE target, not a default 1000.

Smoke-first: 1 rep must write finite α_LA, α_VA, loglik/ELBO, wall time. Abort n-ladder if empty/NA.

---

## SLICES (sequential; `/goal` executes)

- **S0 RECON (done in this chat):** git + issue + design + frontend fixture. Member Ada · Bar Other Models.
- **S1 ADEMP + harness:** Write ADEMP + `bench/va_vs_laplace_bias.jl` (or `report/scripts/…`) that fits one seed both marginals and prints a greppable table. Curie · Cursor Models (Composer) · ~40 min · dep S0.
- **S2 SMOKE:** Run 1–3 local reps; read the log. Curie · Cursor Models · ~20–40 min · dep S1.
- **S3 REPORT:** [report/va-vs-laplace-bias.md](report/va-vs-laplace-bias.md) — ADEMP, numbers, “what this is not” (ZINB/Delta-Gamma/7× unclaimed unless measured), ELBO≠logLik. Curie + Pat · Other Models · ~40 min · dep S2.
- **S4 DOCS HONESTY:** Update [docs/src/model-guides/marginal-la-vs-va.md](docs/src/model-guides/marginal-la-vs-va.md) (line ~150 “Closing #136 still needs 136e…”) and [docs/src/capabilities.md](docs/src/capabilities.md) to cite the report; keep Experimental. Pat · Other Models · ~20 min · dep S3.
- **S5 optional N-LADDER:** Only if S2 shows a material α gap. Totoro if needed. Curie · hand off Codex/Totoro · dep S2. Else skip and record why.
- **S6 ROSE + LOOP + PR:** check-log.d, after-task, [LOOP/](LOOP/) + coordination-board refresh, PR **without** `closes #136`. Rose · Other Models · ~30 min · dep S3–S4. Owner merges.
- **S7 MECHANICAL-VERIFY:** file exists, numbers match log, Experimental strings unchanged, PR body does not close #136. Scout · Cursor Models · ~10 min · dep S6.
- **S8 RECONCILE:** Melissa → `docs/dev-log/plan-actual/2026-08-09-136e-va-bias.md`. Terra/Sonnet · ~15 min · dep S7.

FAN-OUT: 0 parallel producers (linear). Roles: Ada · Curie · Pat · Rose · Melissa. LUNA/scout suitability: yes — S7 mechanical verify. ULTRA EFFORT: no. D-43: not a release milestone — skip panel.

ESTIMATE: ~3 h one `/goal` session if smoke is enough; +Totoro session if S5 fires. Fits one dedicated chat after this planning chat ends.

REVIEW (plan): Rose — do not claim 7× or Implemented; Curie — estimand is α=1/σ² not log σ.

---

## TEAM RAISED

- Curie — Public fixture already uses α=4 / G=40; start there so smoke is comparable to tests. Rec: 1-rep before any grid. Default if silent: that fixture.
- Rose — Original 136e docs flip is now claim inflation. Rec: cite report; Experimental stays; #136 stays open. Default: PASS only if “not ZINB / not 7× unless measured” is explicit.
- Noether — Do not touch `_fit_gamma_ranef_va` unless smoke proves a kernel bug. Rec: report-only `src/`. Default: no `src/` edit.
- Fisher — ELBO vs LA logLik must not be compared as IC. Rec: report α recovery, not ΔlogLik-as-likelihood. Default: no mixed AIC.
- Ada — Public-honest 136e is the right G0. Rec: `/goal` fresh chat after you approve this plan.

---

## After G0 — paste into a fresh Cursor chat

```text
/goal

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: drm-136e-va-bias-report
REPO: /Users/z3437171/Dropbox/Github Local/DRM.jl
PLAN: this approved ultra-plan (copy to LOOP/ultra-plan.md)

READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md
SCAFFOLD: write LOOP/GOAL.md, LOOP/arcs.md, LOOP/checkpoint.md, LOOP/ultra-plan.md from the plan; commit.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code; pause at OPEN GATE (Totoro; merge; close #136); overwrite checkpoint each arc.
START ARC: S1 ADEMP + harness from origin/main @ cc113cbb on feat/136e-va-bias-report.
NEXT GATE: Totoro only if smoke shows material α gap; owner merge; never closes #136.
```

Owner: glance Settings → Usage (both bars) before `/goal`. Glance #403 already merged — do not reopen the handover PR.

No nested subagents in this planning chat. Shannon · Ada · Curie · Rose · Pat · Melissa.