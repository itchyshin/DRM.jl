# After-task — Arc 0: undocumented exported `@ref` hygiene

Date: 2026-08-16 · lane: **catch-up Arc 0** (Cursor Shannon / Grok) · no spawned subagents
**Status: LANDED** — **#430 MERGED** @ `05365c4f`
(`05365c4fdc1e2f0049e0a4ee196d96b622baf287`). This file was drafted on
`docs/undocumented-atref` (`775f0611`) before the merge and is now the
post-merge after-task.
Anchor: drmTMB **0.7.0**. Scratch worktree only
(`/Users/z3437171/local-scratch/lanes/DRM.jl-catchup`).
Plan (canonical, G0-approved):
`docs/dev-log/after-task/2026-08-16-ultra-plan-next-arc.md`
(Dropbox leftover path; **do not checkout** `docs/a3c-design`).

## G0

Owner approved G0 on 2026-08-16. Campaign G0 stays the 2026-08-14 lock:
catch up so `engine = "julia"` **admits what an R user actually fits**.
This run implemented **Arc 0 only**.

## What Arc 0 is

Arc 0 = PR **#430** (`docs/undocumented-atref`): close the undocumented
**exported** `@ref` / missing `@docs` gap. Docs-primary; `src/variational.jl`
is docstring-only `@ref` demotion of unexported `Laplace` / `Variational`.

Implementation after-task (already on `main` via #430):
`docs/dev-log/after-task/2026-08-16-undocumented-atref.md`.

## Detector

**PASS.** Re-run of the handover `@ref` detector on the #430 branch:

- **0** undocumented **exported** `@ref` targets
- **5 parked OK** (fenced-file internals, not this PR):
  `_group_index`, `_general_cov_setup`,
  `_fit_phylo_mean_laplace_nuisance`, `_fit_crossed_mean_laplace_nuisance`,
  `make_problem_from_Q`

Read the printed list (LOG), not the exit code. No full `Pkg.test`.

## Rose audit (merge-when-green — done)

- **Merged:** Documenter + `test (1)` + `test (1.10)` green; #430 merged
  as `05365c4f` on 2026-08-16. Docs-primary; docs self-merge lane.
- **Claim vs evidence:** #430 claims the *exported* undocumented `@ref`
  targets now have a `@docs` home. It does **not** claim Documenter was rebuilt
  locally and does **not** claim the 11-row capability campaign is done.
- **Claim fence:** never write “R–Julia parity complete.” COUNTDOWN 0 is an
  export-name countdown, not capability parity. No ledger row is `supported`.
- **Scope honesty:** docs + one internal-docstring edit. No `bf()` / grammar
  change; `DRM_PARITY_TESTS=1` not required. No GPL vendoring.
- **#136** stays OPEN. **#49** PARKED. **D-111** OFF.

## Fences held

- **#428** A11 `src/` — **UNARMED**; do not merge from this lane.
- **#423** left to A8. **#429**, **#406**, leftover `docs/a3c-design` untouched.
- drmTMB #1049/#1050 never merge. No GPL vendoring. Never `git add -A`.

## NEXT

**STOP.** Arc 0 DONE (verified by merge `05365c4f`). Arc 1 (inventory of
the 11 `claim_status != supported` rows) is **DEFER**. Do not open it
from this `/goal`.

**#427 update-branch done.** After #430 landed, `docs/overnight-close-out`
merged `main` (`a64e6c85`); PR #427 base is `05365c4f`. Do not mix
`@ref` hygiene into that PR. This after-task ships alone — `LOOP/` on
`main` is the A3c campaign and would collide with #427 / #420.

## Perspectives

Shannon (coordination) + Pat (reference home) + Rose (claim-vs-evidence,
merge-when-green). Noether not invoked — no engine change. No spawned
subagents.
