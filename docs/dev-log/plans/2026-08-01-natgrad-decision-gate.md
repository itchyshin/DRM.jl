# #13 decision gate — `fit_em_natgrad` vs `fit_q4_sparse_tmb` (q4_p100)

**Date:** 2026-08-01  
**Issue:** [#13](https://github.com/itchyshin/DRM.jl/issues/13)  
**Design:** [`report/wire-em-solvers-design.md`](../../../report/wire-em-solvers-design.md)  
**Voice:** Shannon + Noether (measured locally; numbers from the run, not exit codes)

## Gate criteria (design)

Wire `algorithm = :natgrad` **only if** `fit_em_natgrad` reaches the same MLE as
`fit_q4_sparse_tmb` on the real `q4_p100` cell (logLik within tol, gradient
stationarity). Otherwise extract `lc_metric` as Fisher/AI-REML infrastructure and
**do not** expose a public solver.

## Measured results (laptop, 2026-08-01)

| Solver | logLik | wall (s) | iters | max\\|g\\| | notes |
|---|---:|---:|---:|---:|---|
| `fit_q4_sparse_tmb` (ref) | **−256.512618** | 16.27 | 85 | 0.547 | matches verified baseline (−256.51); singular-boundary plateau on ‖g‖ |
| `fit_em_natgrad` (candidate) | **−259.795539** | 4.19 | 58 | 2.778 | stalls; same class as plain EM (−259.79 in comparison-grid) |

- **ΔlogLik(|ng − ref|) = 3.282921** (tol 0.05) → logLik parity **FAIL**
- Absolute grad ≤ 1e−6: **not attainable** on this singular cell even for the
  reference (ref max\\|g\\| ≈ 0.55). Secondary relative check ng ≤ 2×ref also **FAIL**.
- vs drmTMB −256.52: |ref| = 0.0074 (OK); |ng| = 3.2755 (stall)

Raw keyvals: `docs/dev-log/plans/_natgrad_gate_raw.txt`.

## Verdict

**FAIL** — natural-gradient block-coordinate EM does **not** clear the β↔σ stall
on the full q=4 location–scale model. Reconciles the comparison-grid verified-
negative EM cell with the experimental driver's optimistic claim: the driver
does **not** match the sparse-TMB / drmTMB MLE.

## Action taken (S1b)

1. **Do not** wire `algorithm = :natgrad` into the public API.
2. Extract `lc_metric` → `src/lc_metric.jl` (Fisher / observed-information metric
   on log-Cholesky params) for #11 / #165 AI-REML infra.
3. Close #13 as infrastructure landed, not a public solver.
4. Keep `src/experimental/fit_em_natgrad.jl` as an unwired prototype with a
   FAIL note pointing here.
