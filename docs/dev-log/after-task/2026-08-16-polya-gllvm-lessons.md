# 2026-08-16 — Pólya scout: what GLLVM.jl can teach DRM.jl (propose only)

**Role:** Pólya (scout). **Propose only — no implementation.**
**Lane:** Cursor docs-only after-task. Feeds Ada (`43cd961e`); does not replace her catch-up plan.
**Platform:** Cursor. Read-only on both Julia repos. No `src/` edits. No drmTMB checkout. No Julia suite. No recovery.
**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design (leftover) | LANE: after-task/polya-gllvm-lessons | OTHER LANES: 10 live on DRM.jl; GLLVM.jl worktrees left untouched`

Rose fence: **DRM.jl should not “become GLLVM.”** Different estimand, different R twin, different G0.

---

## Verdict in one paragraph

GLLVM.jl *looks* greener because it is mid a **family-admit conveyor** against **gllvmTMB**, and because Mission Control’s GLLVM board is showing a live **VA-GH programme** plus overnight Julia surface admits. That is a **different dashboard and a different twin**, not evidence that DRM.jl is sequenced behind GLLVM.jl. [[DECISIONS#D-94]] sequences each Julia repo behind **its own R half**. DRM.jl’s next arc stays the already-named **drmTMB 0.7.0 catch-up G0** (Ada’s note). Copy **process honesty** from GLLVM.jl; do not copy latent-variable product.

---

## Method (receipt)

| Surface | What was read | Note |
|---|---|---|
| Brain MCP | `search_notes` ×3 (`search_all_projects: true`; never `project:` name); `read_note` on [[DECISIONS]] + [[FOR-gllvmTMB … Bolker brief]] | Rung 1 ran. |
| Vault grep | `memory/DECISIONS.md` D-94 / D-111; `memory/AGENT_LOG.md` | AGENT_LOG has almost no GLLVM-vs-DRM sequencing — board-count line only. |
| DRM.jl maps | `git show origin/main:` `docs/design/capability-status.md`, `HANDOVER.md`, `ROADMAP.md`, `LOOP/GOAL.md` | Dropbox checkout is leftover `docs/a3c-design` — **not** used as truth. |
| GLLVM.jl maps | `git show origin/main:` `docs/design/capability-status.md`, `AGENTS.md`, `ROADMAP.md`, `LOOP/GOAL.md`, `docs/dev-log/after-task/2026-08-16-reml-promote-ledger-honesty.md` | Parked checkout is leftover `claude/jl-bridge-capabilities-20260619`. **No branch checkout.** Repo exists at `/Users/z3437171/Dropbox/Github Local/GLLVM.jl`. |
| Mission Control | `~/shinichi-brain/Shinichi/Dashboards/mission-control/live/projects.json`; `status/drmTMB.json`; `status/gllvmTMB.json` | No `DRM.jl.json` / `GLLVM.jl.json`. Pair boards only. |

No spawned subagents. No `Pkg.test`. No recovery.

---

## Sequencing (load-bearing, not vibes)

**D-94** (`memory/DECISIONS.md`): R leads Julia for **drmTMB → DRM.jl** and **gllvmTMB → GLLVM.jl**. Julia quiet can be deliberate. Do not open a “why has Julia stopped” investigation from commit velocity.

**D-111** (same file): DRM.jl stays off Julia General until it has **caught up with drmTMB** and both halves work. Not “caught up with GLLVM.jl.”

**Bolker brief** (`shinichi-brain/memory/lane-notes/for-gllvmtmb-2026-07-28-bolker-brief`): community open order is **drmTMB first** (smaller), then gllvmTMB, then the Julia twins. Combined with D-94, GLLVM.jl is not DRM.jl’s predecessor.

**AGENT-INFERRED (do not treat as Shinichi’s reason):** “GLLVM seems a bit more advanced” is most likely (a) the August family-admit / Identity→engine→ADMIT conveyor on GLLVM.jl `origin/main`, (b) the gllvmTMB Mission Control **VA-GH** panel, and/or (c) leftover-checkout contrast — GLLVM.jl’s Dropbox `AGENTS.md` still reads like a May Phase-1 pilot while `origin/main` is an August catch-up log. It is **not** a decision to re-sequence DRM behind GLLVM.

---

## Why the grass looks greener (dashboard / twin / estimand)

1. **Different twin.** GLLVM.jl’s capability file opens: “twin of gllvmTMB” (`git show origin/main:docs/design/capability-status.md`). DRM.jl’s opens: “R ↔ Julia parity view” against **drmTMB** (same path on DRM `origin/main`). Comparing family counts across those files compares **JSDM / LV** to **distributional regression**.
2. **Different Mission Control board.** `projects.json` has one card per *pair* (`drmTMB`+`DRM.jl`, `gllvmTMB`+`GLLVM.jl`). There is no `status/DRM.jl.json`. The gllvmTMB card still points the **R** capability HTML at `canonical_ref: "codex/va-gh-all-families"` while the Julia twin audit is `origin/main`. The live `gllvmTMB.json` `capability.va_parity` block is an 18-family VA-GH programme. That panel does not exist on the drmTMB card. **AGENT-INFERRED:** that VA panel is a large part of “GLLVM looks ahead.”
3. **Different activity shape.** GLLVM.jl `origin/main` `AGENTS.md` phase snapshot is a two-week Identity→engine→light-Δ conveyor (NB2/Beta/Gamma/Ordinal/ZIP/ZINB/ZIB, 63/63 named-route logLik). DRM.jl’s live G0 (Ada) is **export-gap countdown 0 ≠ parity complete**, 11 capability rows none `supported`, `@ref` parked. Same *kind* of honesty; different remaining work.
4. **Stale checkouts on both sides.** GLLVM.jl LOOP forbids coding on `claude/jl-bridge-capabilities-20260619`. DRM.jl Ada already forbids leftover `docs/a3c-design`. Looking at either Dropbox tree understates `origin/main`.

---

## Bucket 1 — TRANSFERABLE now

Process / docs / CI patterns DRM.jl can copy **without changing the model class**. Each row: what GLLVM does, what DRM lacks or already has weakly, **THIS arc vs DEFER**.

| # | Lesson | GLLVM.jl (`origin/main`) | DRM.jl (`origin/main`) | This arc? |
|---|---|---|---|---|
| 1 | **Rose fence *inside* the capability ledger** | `docs/design/capability-status.md` opens with “Intended API similarity ≠ full parity claim.” AGENTS snapshot repeats “Rose fence: ≠ full family parity ≠ ADEMP ≠ invented twin Δ.” | Capability-status has evidence rules and corrects stale `docs/src/capabilities.md`, but no equivalent banner. LOOP already says “never claim more than the twin does.” | **THIS ARC.** Cheap prose on the 11-row inventory and any MC julia-surface line. Do not promote a row because an export exists. |
| 2 | **No invented twin Δ** | ZIP/ZINB/ZIB/student notes: if gllvmTMB cut or never shipped the family, a light RCall Δ is **forbidden**, not owed (`capability-status.md` family notes; `status/gllvmTMB.json` julia_surface). | LOOP + A0 ledger already: no capability row is `supported` on drmTMB; promoting is a **drmTMB claim decision**. | **THIS ARC.** Apply to the 11 rows and to any “Julia-forward” cell (do not invent drmTMB support). |
| 3 | **Promote on evidence, not on say-so** | 2026-08-16 REML after-task: `REML (Gaussian pilot twin)` moved `planned` → `implemented` only after `test/test_reml.jl` existed; `fit_gaussian_gllvm(reml=true)` / phylo REML explicitly **not on main**; non-Gaussian REML stays `rejected`. | Same spirit already: natgrad `rejected` on measured logLik; ordinary-RE REML `rejected` by guard; VA `planned` with `#136` stub. `docs/src/capabilities.md` still stale vs capability-status on a few historical rows (capability-status itself names this). | **THIS ARC** for ledger/docs honesty. **DEFER** any new REML/VA/natgrad *engine* work. |
| 4 | **Identity-before-engine (docs lock, then code)** | Per-family `docs/dev-log/decisions/2026-08-*-identity.md` then engine PR then ADMIT handover. Dispersion/cutpoint parameterisation locked before `src/`. | Workflow H / `docs/src/developer-notes/adding-families.md` exist; the August Identity→ADMIT conveyor is sharper. DRM family set is already Phase-2 complete. | **DEFER** as a family factory. **THIS ARC** only if a new route is opened (then lock identity first). Not a reason to add families. |
| 5 | **Worktree-from-current-main; forbid leftover fork** | LOOP/GOAL.md: one write lane under `.worktrees/…`; **FORBIDDEN:** coding on stale `claude/jl-bridge-capabilities-20260619`. ~53 worktrees visible (other lanes — do not touch). | LOOP already: one branch per arc; Ada already: `@ref` on a **new** docs branch from current `main` in scratch worktree, not leftover `docs/a3c-design`, not armed `#426`. ~10 worktrees. | **THIS ARC.** Process already named; keep it. Do not copy GLLVM’s worktree *volume*. |
| 6 | **Documenter `@ref` / convention-change cascade** | AGENTS.md: syntax/export rename must atomically update docstrings, Documenter, tests, README, status tables. | Ada measured **24** undocumented `@ref` targets, **16** exported; VitePress dies on literal `./@ref`. Already OWED / parked. | **THIS ARC** (Ada’s parked `@ref` slice). Copy the cascade rule, not GLLVM pages. |
| 7 | **VA experimental honesty (label, don’t promote)** | ROADMAP: VA landed for selected families as an *alternative* (not R-default on the Julia twin). capability-status: `VA / ELBO alternative (selected families; not R-default) = implemented`. Known-limitations section still says Laplace bias is why VA exists. MC R board’s VA-GH programme is **gllvmTMB**, not a DRM G0. | VA is `planned` (`src/variational.jl` errors at `#136`). LOOP fences `#136`. HANDOVER: Experimental `(1\|g)` on a few families; 136e / phylo/ZI deferred. | **THIS ARC:** keep the fence and the word *experimental*. **DEFER:** implementing or promoting VA. |
| 8 | **Light logLik / same-model oracle before ADEMP** | GLLVM LOOP: live light oracle vs gllvmTMB; ADEMP/coverage/Totoro fenced. 63/63 named-route logLik with Rose fence. | DRM LOOP: native-vs-Julia parity fixture; verify = log + artefact; `#136` / `#49` / D-111 fenced. Catch-up ultra-plan exhausted; 11 rows not on that list. | **Already matched** as doctrine. Refresh LOOP *after* Ada’s OWED 1–6, under the **same** G0 — do not start a GLLVM-style family conveyor. |

---

## Bucket 2 — WRONG TWIN (must not become DRM.jl G0)

These are latent-variable / GLLVM-class capabilities. Copying them would change the product. Say why.

| GLLVM.jl capability (`origin/main` ROADMAP / capability-status) | Why it is the wrong twin |
|---|---|
| Ordinary / phylo / spatial **latent** modes (`latent()`, `phylo_latent()`, `spatial_latent()`) | Factor structure and site scores. DRM’s random effects are GLMM / location-scale, not LV loadings. |
| **Ordination trio** — unconstrained `num.lv`, concurrent `num.lv.c`, constrained/RRR `num.RR`; `ordination` / `select_lv` / biplot | Community ecology product. drmTMB has no ordination surface to twin. |
| **Fourth-corner / trait–environment** (`X×TR`); **species-specific `B`** (`(0+trait):x`) | Per-trait environmental slopes. DRM formulas are per *parameter* (μ/σ/ρ), not per species. |
| **Quadratic-response GLLVM** (optima/tolerances) | LV response shape. Not a drmTMB estimand. |
| **Row (community) effects** as GLLVM site intercepts | Different object from DRM’s `(1\|g)` / phylo / animal / relmat. |
| **SPDE field as a latent variable** (`fit_spde_latent_gllvm`, kriging `predict_spatial`) | Shared *sparse-precision infrastructure* is interesting later; the *LV-field* product is GLLVM. ROADMAP even says “shared-ready with DRM.jl” — that is a **future sister-module**, not this G0. |
| **VA as the fix for high-`K` binary JSDM** (gllvm default `method = "VA"`) | Motivated by many latent factors + hyper-sparse binary data. DRM’s verified engine is sparse augmented-state **Laplace** on q=4 PLSM. Bolker brief: AGHQ/VA questions live on the GLLVM pair. |
| **Mixed-family response vector** (GLLVM-style) | Stacked traits with different families under a shared LV. DRM’s missing row is **cross-family bivariate** (y1/y2), a different (and still `missing`) cell — do not “catch up” by importing GLLVM mixed-family. |
| **Phylo Model A** / source-specific `lv` intervals | GLLVM itself **rejects** advertising this. Do not import a rejected twin claim. |
| Family-count race (truncated_*, censored_poisson, com_poisson, delta_*, ordered_beta, …) | GLLVM is admitting **gllvmTMB families**. DRM Phase 2 is already “effectively complete” against **drmTMB** (`ROADMAP.md`). Extra families without a drmTMB twin are Julia-forward, not catch-up. |

---

## Bucket 3 — ALREADY MATCHED or DRM AHEAD

Do not “catch up” to a ghost.

| Area | Why DRM is not behind |
|---|---|
| **LOOP kit** | Both have `LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`. DRM’s kit is the drmTMB catch-up G0; GLLVM’s is a logLik-oracle G0. Same tool, different mission. |
| **capability-status.md as MC input** | Both exist on `origin/main`; both use `implemented/rejected/planned/missing`. DRM’s file is the more conservative VA/natgrad/REML-ordinary story. |
| **`claim_boundary`** | Already on DRM `src/bridge.jl` and drmTMB `inst/extdata/julia-capabilities.tsv` (Hopper re-measure 2026-08-16). GLLVM uses Rose-fence prose instead of that column name. |
| **Verified q=4 PLSM engine** | `HANDOVER.md`: 2.18× vs drmTMB, O(p) to p=10,000, CIs where TMB Hessian is all-NaN. GLLVM’s headline ~340× is **closed-form single-σ² Gaussian** — different model. Do not chase 340× on q=4. |
| **Location-scale (`sigma` formulas)** | DRM’s reason to exist. GLLVM is mean/LV/dispersion-per-trait, not μ+logσ phylogenetic coscale. |
| **REML honesty** | DRM: ML default; ordinary-RE REML `rejected`; q4 REML `implemented`. GLLVM: Gaussian REML pilot only; non-Gaussian REML `rejected`. DRM is not behind. |
| **`:natgrad`** | DRM **rejected** on measured logLik (−259.80 vs −256.51). GLLVM does not have a public natgrad solver to copy. MC `drmTMB.json` already: do not invent AI-REML / `:natgrad` labels. |
| **χ̄² boundary LRT, model-comparison suite, h²/ICC** | DRM capability-status: `implemented`. Not on the GLLVM twin vocabulary. |
| **Non-Gaussian phylo location-scale (μ + log σ)** | DRM `implemented` (`closes #202`); capability-status calls this a genuine R↔Julia gap (drmTMB still scope-limited). Ahead of the *R* twin on that cell — D-94 says do not treat that as a reason to sprint past drmTMB. |
| **Engine Quality Battery (Workflow Q)** | Both AGENTS.md list the same seven gates (FD / cross-check / R-parity / JET / Allocs / Aqua / multi-shape). Already shared doctrine. |
| **License boundary** | Both MIT twins; both forbid vendoring GPL R source. Already matched. |

---

## What Ada should take for THIS arc (top 3)

Ada’s live plan (`docs/dev-log/after-task/2026-08-16-parity-ultra-vs-loop.md`): finish OWED 1–6, keep the 2026-08-14 catch-up G0, do **not** start a new ultra-plan, do **not** start the 11 rows until owner calls, `@ref` on a new docs branch from current `main`. This scout **agrees** and adds only:

1. **Put a GLLVM-style Rose fence on the 11-row inventory** — “export present ≠ supported”; “no invented drmTMB Δ”; capability-status banner. That is the transferable core of GLLVM’s August honesty pass (`capability-status.md` Rose fence + 2026-08-16 REML promote-on-evidence).
2. **Keep `@ref` + leftover-checkout discipline** — GLLVM LOOP’s “do not code on the June leftover branch” is the same rule Ada already wrote for `docs/a3c-design` / `#426`. Copy the *convention-change cascade* sentence into the `@ref` slice so VitePress and status tables move together.
3. **Treat VA / SPDE / family-count as sister-package scenery** — cite them in a one-line “out of scope / wrong twin” fence so the next arc cannot drift into `#136` or a GLLVM family conveyor.

---

## Must stay DEFER

- **VA/ELBO implementation or promotion** (`#136`, 136e, phylo/ZI VA). GLLVM having VA on `main` is a *gllvmTMB-class* estimator choice, not a DRM gap.
- **SPDE / Matérn-GMRF** as a shared module (GLLVM ROADMAP §3). Interesting later; not catch-up.
- **Identity→ADMIT family factory** and GLLVM family volume (truncated_*, censored_poisson, com_poisson, delta_*, ZIB, …).
- **Ordination, fourth-corner, species-XB, concurrent/RRR, mixed-family LV.**
- **AGHQ** (missing on both Julia maps; Bolker named it for the GLLVM pair).
- **Non-Gaussian REML**, phylo REML beyond what each `main` already ships.
- **`:natgrad` / AI-REML public solver** (DRM already rejected; MC forbids inventing the label).
- **`#49` / FIML / `mi()`** (GLLVM has NA-mask on selected Laplace fitters; that is still a different missing-data contract from drmTMB’s native per-route mask).
- **Julia General / Registrator** (D-111).
- **Any G0 of the form “catch up to GLLVM.jl.”**

---

## Sources (cited)

- `memory/DECISIONS.md` — D-94, D-111
- `shinichi-brain/memory/lane-notes/for-gllvmtmb-2026-07-28-bolker-brief`
- DRM.jl `origin/main`: `docs/design/capability-status.md`, `HANDOVER.md`, `ROADMAP.md`, `LOOP/GOAL.md`
- GLLVM.jl `origin/main`: `docs/design/capability-status.md`, `AGENTS.md`, `ROADMAP.md`, `LOOP/GOAL.md`, `docs/dev-log/after-task/2026-08-16-reml-promote-ledger-honesty.md`
- Mission Control: `live/projects.json`, `live/status/drmTMB.json`, `live/status/gllvmTMB.json`
- Ada (same day, leftover tree, do not stage from here): `docs/dev-log/after-task/2026-08-16-parity-ultra-vs-loop.md`

**Not done:** no git add, no PR, no src, no drmTMB, no Julia tests.
