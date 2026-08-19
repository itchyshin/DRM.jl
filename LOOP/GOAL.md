# GOAL — phylo-laplace-cox-reid (IMMUTABLE — re-read at the top of EVERY arc)

Read this first, every cycle. Auto-compact eats messages, not this file.

## Mission

One issue · one branch · one PR — opt-in `method=:REML` on Poisson routes that call `_fit_poisson_general_laplace` (phylo + relmat/animal). ML default unchanged. No recovery headline. Human merges the PR (`closes #<B issue>`). Do not `gh pr merge`.

## Headline

B. Poisson phylo Laplace Cox–Reid (reuse #444 helpers after `_withnll`).

## Invariants

- Solo platform: Cursor (this `/goal` lane).
- Dual-start guard: AGHQ lane A is LIVE (#448, PR #449, worktree `~/local-scratch/lanes/DRM.jl-aghq-lever-2`, branch `claude/lane-aghq-lever-2`). Do NOT edit those files. Do NOT open a second AGHQ issue.
- Do NOT use `/Users/z3437171/local-scratch/lanes/DRM.jl-handover-20260818` (handover leftover LOOP/), Dropbox `docs/a3c-design`, or catchup `docs/arc1-inventory`.
- Wait for AGHQ **open PR** (not merge) before B `src/` — that PR exists (#449). Branch from `origin/main`. Keep B's `poisson.jl` edits disjoint from AGHQ dispatch if possible. Do not revert A's hunks if they land on main.
- All `_fit_poisson_general_laplace` callers (phylo + relmat/animal). Do NOT punch `_fit_poisson_ranef` (GHQ `(1|g)` already wired).
- Lift `_reject_reml_route` for those structured routes only; KEEP rejecting spatial-coord estimated-ρ, crossed, slopes, VA, FE-only, Binomial.
- Do NOT edit `test/runtests.jl` (AGHQ dirties it). Standalone `test/test_cox_reid_poisson_phylo.jl`.
- ML is the default. Twin = drmTMB (mechanism only; no GPL vendoring). Capability chip stays missing. Cell D ≠ recovery.
- Never `git add -A`. Never vendor drmTMB. Never mutate GLLVM `LOOP/GOAL.md`. No q4. D-111 OFF. #49 PARKED. No steal #420/#406.
- Skip NotebookLM.

## DEFER

AGHQ (#448) · q4 · D-111 · #49 · ADEMP · Cell D as recovery · dual-start A+B

## Authoritative WHAT

`LOOP/ultra-plan.md` (copy of the approved G0 plan). Detail wins there; this file wins on "what must never be lost".

## Definition of done

- [ ] NEW GitHub issue for B (not #448 / #443 / #103)
- [ ] `method=:REML` wired on `_fit_poisson_general_laplace` after `_withnll` via #444 helpers
- [ ] Callers: `_fit_poisson_phylo_laplace` and `_fit_poisson_relmat_laplace`
- [ ] Tests: `estimation_method === :REML`; σ̂_CR > σ̂_ML direction; reml_loglik ≠ ml_loglik; uncertified routes still error; no recovery target
- [ ] Docs: warning Cell D not recovery; ML default; no capability chip
- [ ] check-log.d + after-task + Rose audit
- [ ] PR opened `closes #<B issue>` — human merges; this worker does not `gh pr merge`
