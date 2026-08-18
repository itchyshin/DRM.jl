# Arcs — from the approved G0 (issue #441)

| # | arc | status | gate? |
|---|-----|--------|-------|
| 0 | Lane pre-flight; open issue #441; `lane_launch.sh` scratch lane off `origin/main` | done | — |
| 1 | Freeze the LOOP kit (GOAL / arcs / checkpoint / ultra-plan) and commit it | done | — |
| 2 | Map `src/sparse_laplace_glmm.jl`: θ layout, gradient contract, where a restricted objective would attach | done | — |
| 3 | Punch-through question: can `_glsp_reml_penalty` / `_glsp_reml_refit_clean` / `_withreml` serve non-Gaussian routes unmodified? | done | — |
| 4 | Cell B — Gaussian reduction anchor: generic Cox–Reid penalty vs the #440 Woodbury exact REML | done | — |
| 5 | Cell A — measure the ML variance-component bias on Poisson `(1\|g)` (GHQ-32, integral error negligible) and whether Cox–Reid removes it | done | — |
| 6 | Cell C — hook viability on the sparse-Laplace route itself (Poisson phylo, analytic gradient) | done | — |
| 6b | Ingest Hopper's GLLVM fence into the plan + checkpoint | done | — |
| 7 | Standalone characterization test documenting current ML behaviour (NOT wired into `test/runtests.jl`) | done | — |
| 8 | Design note: hook points, cost model, risks, fences, explicit go/no-go for the implement-G0 | done | — |
| 9 | After-task + check-log entry; name the next G0s in order | done | — |
| 10 | PR #442 against `main`; merge if CI green and Rose-clean | done — Shannon | owner pre-approved |

**G0 CLOSED.** Verdict: **GO** for a later implement-G0, as a *wiring* job — not implemented
here. Arc 7 verified by artefact: `test/test_cox_reid_characterization.jl` ran **12/12 in
15 s**, standalone, not registered in `runtests.jl`.

Next G0 = Cox–Reid **implement** (first cell Poisson `(1|g)` GHQ; narrow
`_reject_method_as_marginal`), then the **AGHQ port**. Neither starts in this lane.

Status: todo / doing / done / blocked. Gate = needs a human before it can proceed.

**Fence reminder (every arc):** never `test/runtests.jl`, `src/reml_q4.jl`, bivariate q4,
any parity TSV, or `src/gaussian_ranef.jl` (read-only oracle). Sibling Shannon lane owns
#423 / #428 / #429 debris.
