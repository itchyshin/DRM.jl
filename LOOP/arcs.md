# Arcs — phylo-laplace-cox-reid (from approved G0)

Status: todo / doing / done / blocked. Gate = needs a human before it can proceed.

| # | arc | status | gate? |
|---|-----|--------|-------|
| S1 | Wait until AGHQ #448 has an **open PR** (not merge) before B `src/` | done | wait — **cleared**: [PR #449](https://github.com/itchyshin/DRM.jl/pull/449) OPEN |
| S2 | File a NEW B issue; fill LOOP kit on `claude/lane-phylo-laplace-cox-reid` off `origin/main` | done | issue [#450](https://github.com/itchyshin/DRM.jl/issues/450) |
| S3 | TDD red: standalone `test/test_cox_reid_poisson_phylo.jl` (not in `runtests.jl`) | done | 27/27 verified twice |
| S4 | Wire: lift structured `_reject_reml_route`; thread `reml` into `_fit_poisson_general_laplace`; reuse #444 helpers | done | tip `8084532e` |
| S5 | Docs: Poisson docstring warning (Cell D not recovery; ML default; no chip) | done | docstring already on `Poisson()` from S4; check-log + after-task this slice |
| S6 | `Pkg.test()`; read logs; no recovery sentence | done | standalone 27/27 twice (S3/S4); this S5 slice did not re-run |
| S7 | Rose check-log + after-task + PR `closes #<B>` — do **not** `gh pr merge` | todo | OPEN GATE: human merge |
| S8 | Melissa plan-vs-actual reconcile | todo | — |

**SEQUENTIAL:** S1→S2→S3→S4→S5/S6→S7→S8. **PARALLEL after S1:** none (single writer).
**NEXT = S7 PR.** Sibling opens it. This worker does not `gh pr create` / `gh pr merge`.

**Overlap note:** A (#449) adds `marginal=:AGHQ` on `(1|g)` in `src/poisson.jl`. B lifts structured `_reject_reml_route` and punches `_fit_poisson_general_laplace`. Keep B's `poisson.jl` hunks disjoint from AGHQ dispatch. Do not revert A's hunks if they land on main.
