# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

- **DONE:** Arc 0 (pre-flight, issue #441, lane scaffolded off `origin/main` `5e392c6e`,
  branch renamed to the `cursor/` prefix). Arc 1 (LOOP kit overwritten — the inherited
  #434 kit was a different subject). Arcs 2–3 (engine mapped; hook named and its
  `(obj, grad_fn, pμ)` contract confirmed by reading every non-Gaussian `_fg` route).
  Arcs 4–5 (cells B and A measured).
- **IN PROGRESS:** Arc 6 — Cell C, hook viability on the sparse-Laplace route itself
  (Poisson phylo, analytic gradient). The script is written; the run was interrupted
  mid-flight and needs re-running to capture `bench/out/cox_reid_probe.txt`.
- **NEXT:** Arc 7 standalone characterization test → Arc 8 design note → Arc 9 after-task
  + check-log → Arc 10 PR.
- **OPEN GATE:** none. Owner gave full pre-approval for this lane including the PR.
- **WHERE TRUTH LIVES:** this worktree on `cursor/lane-cox-reid-probe`; measured output in
  `bench/out/cox_reid_probe.txt`; the probe itself in `bench/cox_reid_probe.jl`.
- **RESUME:** read `LOOP/GOAL.md` → this file → `LOOP/ultra-plan.md`, then continue from NEXT.

## Measured so far (reproduce with `julia --project=. bench/cox_reid_probe.jl`)

**Cell B — Gaussian reduction anchor.** Gaussian `(1|g)`, G=12, n_each=5. The generic
Cox–Reid penalty `½logdet(I_ββ)` applied to the ML objective versus #440's exact Woodbury
REML: **max |θ̂_CR − θ̂_REML| = 2.87e-06** across all four parameters. The penalty is
anchored, not ad hoc.

**Cell A — ML variance-component bias, Poisson `(1|g)`, GHQ-32, true σ_b = 0.6, 60 seeds.**

| G | n_each | nrep | σ̂_ML | bias_ML | σ̂_CR | bias_CR |
|---|---|---|---|---|---|---|
| 10 | 6 | 58 | 0.5258 | **−12.37%** | 0.5894 | **−1.77%** |
| 20 | 6 | 60 | 0.5561 | **−7.32%** | 0.5903 | **−1.62%** |
| 40 | 6 | 60 | 0.6085 | +1.41% | 0.6263 | +4.38% |

Reproduces the vault's *mechanism* on our engine: the ML bias shrinks with the number of
clusters M, Cox–Reid removes most of it where it is large, and it mildly **over-corrects**
once M is big enough that ML is already fine. That over-correction is the evidence-backed
reason Cox–Reid must stay **opt-in** with ML the default — which is what was locked.

**Caveat carried forward:** 2 of 60 seeds at G=10 failed the refit (boundary / non-PD
β-information). The sentinel path is exercised; a production estimator needs that fallback
tested, not assumed.
