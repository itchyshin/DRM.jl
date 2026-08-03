# #372 six-cell measured wall-clock (retained artifact)

Date: 2026-08-03 · Arc 1 of Ultra Plan #372  
Perspectives: Shannon · Curie · Rose. No nested subagents.

Machine-readable twins (same numbers):

- [`372-six-cell-timing/julia_bridge_six_cell.toml`](372-six-cell-timing/julia_bridge_six_cell.toml)
- [`372-six-cell-timing/r_bridge_six_cell.json`](372-six-cell-timing/r_bridge_six_cell.json)

Harness (reproducible): `bench/bridge_six_cell_timing.jl`,
`bench/R/bridge_six_cell_timing.R`. Arc 0 probe:
[`2026-08-03-372-arc0-probe.md`](2026-08-03-372-arc0-probe.md).

## Method (Rose fence checklist)

| Field | Value |
|---|---|
| Cohort | six #370 bridge fixtures (xfam OUT) |
| Julia arm | `drm_bridge` on fixture `data.csv` + formula/family from `expected.toml` |
| R arm | local installed **drmTMB 0.6.0** via public API shapes from the
  `gen_fixtures.R` recipe (no GPL source vendored) |
| Protocol | 1 warmup discarded + 5 timed reps; report median / min / max |
| Threads | Julia `BLAS.set_num_threads(1)`; R `OMP_NUM_THREADS=1`
  `OPENBLAS_NUM_THREADS=1` `MKL_NUM_THREADS=1` |
| Machine | hostname `W-KW3K3Y6229.local` (arm64 Darwin) |
| Julia | 1.10.0 · `julia_threads=1` · `blas_threads=1` |
| R | 4.6.0 (2026-04-24) |
| Timestamp (UTC) | Julia `2026-08-03T13:28:41Z`; R `2026-08-03 13:28:49 UTC` |
| Coef fixture pin | still drmTMB **v0.1.3 generated numbers** (unchanged) |
| R timing version | **0.6.0** (recorded; not the 0.1.3 pin) |

**Not claimed:** p>100 scaling; CI timing; Totoro; q=4 PLSM 2.18× cell as
evidence for these families; a universal “DRM.jl is Nx faster than drmTMB”
headline beyond this fixture cohort and protocol.

**Timer note:** absolute Julia medians are sub-millisecond to a few ms; R
`proc.time()[["elapsed"]]` resolution is coarser at this scale. Ratios are
reported as **median R / median Julia** on this protocol only.

## Measured medians (warm timed fits)

| Cell | n | Julia median_s | R median_s (drmTMB 0.6.0) | ratio R/J | both ok |
|---|---:|---:|---:|---:|---|
| gaussian-locscale | 180 | 0.000979 | 0.020 | **20.4×** | yes |
| gaussian-bivariate-rho12 | 180 | 0.003093 | 0.015 | **4.8×** | yes |
| robust-student | 180 | 0.002513 | 0.018 | **7.2×** | yes |
| count-nbinom2 | 180 | 0.000921 | 0.020 | **21.7×** | yes |
| proportion-beta | 180 | 0.001559 | 0.017 | **10.9×** | yes |
| meta-analysis-V | 160 | 0.000432 | 0.020 | **46.3×** | yes |

Ratio = `R_median_s / Julia_median_s` (Julia faster when >1). All six R arms
converged; no R-blocked cells.

## LogLik sanity (same fixtures; not a parity re-gate)

| Cell | Julia logLik | R logLik |
|---|---:|---:|
| gaussian-locscale | −215.462545 | −215.462545 |
| gaussian-bivariate-rho12 | −495.618247 | −495.618247 |
| robust-student | −240.236652 | −240.236652 |
| count-nbinom2 | −278.705609 | −278.705609 |
| proportion-beta | +124.409996 | +124.409996 |
| meta-analysis-V | −93.790053 | −93.790053 |

## Rose claim-vs-evidence (this artifact)

| Claim allowed by this file | Verdict |
|---|---|
| On these six fixture cells, under the protocol above, warm median wall-clock
  showed Julia `drm_bridge` faster than local drmTMB 0.6.0 with the ratios in
  the table | **PASS** — numbers retained here + JSON/TOML |
| “Julia is ~Nx faster” as a general twin headline for all drmTMB models | **NO** — scoped to this cohort/protocol/machine/versions |
| Re-use q=4 2.18× as evidence for these families | **FORBIDDEN / not done** |
| GPL vendoring | **PASS** — fixtures + public R API only |
| Invented timings / R-blocked cells | **N/A** — all six R arms measured |

## Reproduce

```bash
julia --project=. bench/bridge_six_cell_timing.jl
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript --vanilla bench/R/bridge_six_cell_timing.R
```
