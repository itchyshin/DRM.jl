# Plan vs actual — phylo Laplace Cox–Reid (2026-08-18)

Reconciler: **Melissa** (Phase 4.5 LIGHT). Shannon coordinating; no nested
subagents in this pass. Source of truth: Cursor plan
`~/.cursor/plans/phylo_laplace_cox-reid_89098790.plan.md` (copy:
`LOOP/ultra-plan.md`) vs worktree
`~/local-scratch/lanes/DRM.jl-phylo-laplace-cox-reid` @
`claude/lane-phylo-laplace-cox-reid` tip `7459e6a2`, PR
[#451](https://github.com/itchyshin/DRM.jl/pull/451) (`closes #450`),
**OPEN / not merged**. AGHQ [#449](https://github.com/itchyshin/DRM.jl/pull/449)
is a foreign lane — not read for claims, not touched.

Cosmetic wording / slice-order omitted. Material axes only.

## Verdict: **clean-with-adaptations.** No `drift` rows.

Four material deviations, all **adaptive**. Zero `unclear`.
**Melissa → Rose:** nothing to promote to the PLAN-DRIFT-LEDGER this close.
Rose already owns the capabilities.md nit (PASS-WITH-NITS); it is recorded
below, not re-litigated.

| # | Axis | Planned → actual | Tag | Owner |
|---|------|------------------|-----|-------|
| 1 | **Evidence / verification** | S6 = `Pkg.test()` + read logs → standalone `julia --project=. -e 'include("test/test_cox_reid_poisson_phylo.jl")'` **27/27 twice** (S3/S4). Default `Pkg.test()` not run; new file is outside `runtests.jl` | **adaptive** — fence “do not edit `test/runtests.jl`” won over the S6 command; equivalent smoke recorded | Curie (method evidence) |
| 2 | **Model routing** | FAN-OUT 0; PARALLEL after S1: none (single writer); one `/goal` Grok → after serial S0–S5 stop, **3 Groks** in one closeout fan-out (Rose read-only · S7 PR · this S8) | **adaptive** — src/ single-writer held through S4; closeout slices do not share writers | Ada |
| 3 | **Public claims** | Keep chip missing; no “has non-Gaussian REML” → chip **not** flipped (`docs/src/capabilities.md` / TSV / `capability-status.md` absent from the PR diff). Page still says “non-Gaussian REML stay rejected” (stale since #444; more so after #450) | **adaptive** — Rose PASS-WITH-NITS: do not flip the chip to “fix” the stale sentence | Rose |
| 4 | **Handoff state** | S7 PR then human merge; checkpoint is the pointer → PR #451 **OPEN** (not merged). Checkpoint at `c785af2e` still said NEXT=S7 after the PR existed; **fixed** at `7459e6a2` to NEXT=human merge of #451 | **adaptive** — stale pointer caught and corrected; merge still the human gate | Ada |

## Clean on the other axes

- **Scope** — S0–S5 done as planned: new issue #450; worktree off `origin/main`;
  TDD standalone `test/test_cox_reid_poisson_phylo.jl`; lift structured reject;
  thread `reml` into `_fit_poisson_general_laplace`; reuse #444 helpers
  unmodified; docstring honesty (Cell D not recovery; ML default). Relmat /
  animal / precomputed spatial admitted on the same spine. `_fit_poisson_ranef`
  GHQ cell not re-punched. `src/variational.jl` reject-copy (3 lines) names the
  two wired Poisson cells — honesty, not a second family. No ADEMP. No second
  family. No q4.
- **Safety gates** — dual-start A+B **avoided** (AGHQ stayed the other chat /
  #449). No AGHQ files. No second AGHQ issue. No `test/runtests.jl`. No
  `gh pr merge`. No drmTMB GPL. No steal #420/#406. D-111 OFF. #49 PARKED.
  Never `git add -A`. Overlap with #449 on `src/poisson.jl` /
  `src/variational.jl` is named on the PR; B hunks stay off `marginal = :AGHQ`.

## Deferred — accounted for

| Fence | Status |
|---|---|
| AGHQ lever 2 / #448 / PR #449 | honoured — foreign lane; not mixed |
| ADEMP campaign / Cell D as recovery | honoured — no recovery sentence; no ADEMP issue filed this G0 (gap stays a follow-on) |
| Dual-start A+B | honoured — retracted; B waited for #449 OPEN then ran alone |
| `test/runtests.jl` include | honoured — standalone only |
| Capability chip / TSV / “has non-Gaussian REML” | honoured — not flipped |
| q4 · D-111 · #49 · second family · GLLVM LOOP · leftover `docs/a3c-design` | honoured |

## Completeness residue (not a sixth-axis deviation)

Path + line. Half-done LOOP ledger after the checkpoint fix — pointer
(`LOOP/checkpoint.md`) is current; these two still lag:

- `LOOP/arcs.md:13` — S7 still `todo` while PR #451 is OPEN.
- `LOOP/arcs.md:14` — S8 still `todo` (this file is the S8 artifact).
- `LOOP/arcs.md:17` — `NEXT = S7 PR` (stale vs checkpoint `NEXT: human merge`).
- `LOOP/GOAL.md:36–42` — Definition of Done checkboxes still unchecked.

Rose nit 2 at `8084532e` (arcs/checkpoint still showing S3–S8 todo) is partly
cleared: S1–S6 marked done; S5 ledger landed; checkpoint pointer fixed. The
lines above are the leftover.

## DECISION RECEIPT (D-67)

```
DECISION RECEIPT
  Questions asked      — Q1 start B src/ on AGHQ OPEN PR vs MERGE; Q2
                         relmat/animal vs phylo-only; Q3 NotebookLM?
                         All three drafted in the plan (D-148). G0
                         approved with IF-YOU-DO-NOT-MIND defaults;
                         not re-asked mid-arc.
  Answers received     — G0 approval. Operative: wait for AGHQ *open PR*
                         (not merge); all `_fit_poisson_general_laplace`
                         callers; skip NotebookLM.
  Defaults accepted    — those three. S1 cleared on #449 OPEN. Relmat/
                         animal/precomputed spatial wired. NotebookLM
                         not run.
  Adaptive decisions   — standalone 27/27 in place of default Pkg.test();
                         3-Grok closeout fan-out after serial S0–S5 stop;
                         do not flip capabilities.md to paper over the
                         stale NG-REML sentence; checkpoint pointer
                         rewritten once the PR URL existed.
  Unresolved           — human merge of #451 (Noether + maintainer on
                         src/ + public method=:REML). ADEMP / larger-tree
                         recovery still a follow-on. capabilities.md
                         stale NG-REML sentence stays Rose's nit.
                         Hand to Rose / Ada — not chat-only.
```

> Related: `docs/dev-log/after-task/2026-08-18-cox-reid-poisson-phylo-laplace.md` ·
> `docs/dev-log/check-log.d/2026-08-18-cox-reid-poisson-phylo-laplace.md` ·
> Rose PASS-WITH-NITS on #450 @ `8084532e` · Melissa charter · no
> PLAN-DRIFT-LEDGER promotion this close
