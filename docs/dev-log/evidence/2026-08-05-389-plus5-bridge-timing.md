# #389 +5 bridge measured wall-clock (retained artifact)

Date: 2026-08-05 · Ultra Plan #389  
Perspectives: Shannon · Curie · Rose. No nested subagents.

Machine-readable twins (same numbers):

- [`389-plus5-bridge-timing/julia_bridge_plus5.toml`](389-plus5-bridge-timing/julia_bridge_plus5.toml)
- [`389-plus5-bridge-timing/r_bridge_plus5.json`](389-plus5-bridge-timing/r_bridge_plus5.json)

Harness (reproducible): `bench/bridge_six_cell_timing.jl`,
`bench/R/bridge_six_cell_timing.R` with `DRM_BRIDGE_TIMING_COHORT=plus5`.
Original six (#372) unchanged — do not treat this file as a re-time of those cells.

## Method (Rose fence checklist)

| Field | Value |
|---|---|
| Cohort | five #383/#385 bridge fixtures (xfam OUT; original six OUT) |
| Julia arm | `drm_bridge` on fixture `data.csv` + formula/family from `expected.toml` |
| R arm | local installed **drmTMB 0.6.0** via public API shapes from the
  `gen_fixtures.R` recipe (no GPL source vendored) |
| Protocol | 1 warmup discarded + 5 timed reps; report median / min / max |
| Threads | Julia `BLAS.set_num_threads(1)`; R `OMP_NUM_THREADS=1`
  `OPENBLAS_NUM_THREADS=1` `MKL_NUM_THREADS=1` |
| Machine | hostname `psychdhcp68.psych.ualberta.ca` (arm64 Darwin) |
| Julia | 1.10.0 · `julia_threads=1` · `blas_threads=1` |
| R | 4.6.0 (2026-04-24) · drmTMB **0.6.0** |
| Timestamp (UTC) | Julia `2026-08-05T11:26:45Z`; R `2026-08-05 11:26:46 UTC` |
| Coef fixture pin | drmTMB **0.6.0** generated numbers (unchanged by this timing run) |

**Not claimed:** p>100 scaling; CI timing; Totoro; q=4 PLSM 2.18×; #372 six-cell
ratios as evidence for these five; a universal “DRM.jl is Nx faster than drmTMB”
headline beyond this fixture cohort and protocol.

**Timer note:** absolute Julia medians are sub-millisecond to ~1 ms; R
`proc.time()[["elapsed"]]` resolution is coarser at this scale. Ratios are
reported as **median R / median Julia** on this protocol only.

## Measured medians (warm timed fits)

| Cell | n | Julia median_s | R median_s (drmTMB 0.6.0) | ratio R/J | both ok |
|---|---:|---:|---:|---:|---|
| count-poisson | 180 | 0.000185 | 0.011 | **59.6×** | yes |
| positive-gamma | 180 | 0.000662 | 0.013 | **19.6×** | yes |
| binomial-trials | 180 | 0.001053 | 0.012 | **11.4×** | yes |
| positive-lognormal | 180 | 0.000309 | 0.012 | **38.8×** | yes |
| nbinom2-dispersion | 200 | 0.001147 | 0.018 | **15.7×** | yes |

Ratio = `R_median_s / Julia_median_s` (Julia faster when >1). All five R arms
converged; no R-blocked cells. Scoped range ≈ **11.4×–59.6×**.

## LogLik sanity (same fixtures; not a parity re-gate)

| Cell | Julia logLik | R logLik |
|---|---:|---:|
| count-poisson | −283.223235 | −283.223235 |
| positive-gamma | −122.017688 | −122.017688 |
| binomial-trials | −323.544600 | −323.544600 |
| positive-lognormal | −147.360064 | −147.360064 |
| nbinom2-dispersion | −285.485603 | −285.485603 |

## Rose claim-vs-evidence (this artifact)

| Claim allowed by this file | Verdict |
|---|---|
| On these five fixture cells, under the protocol above, warm median wall-clock
  showed Julia `drm_bridge` faster than local drmTMB 0.6.0 with the ratios in
  the table | **PASS** — numbers retained here + JSON/TOML |
| “Julia is ~Nx faster” as a general twin headline for all drmTMB models | **NO** — scoped to this cohort/protocol/machine/versions |
| Re-use #372 six-cell ratios or q4 2.18× as evidence for these families | **FORBIDDEN / not done** |
| GPL vendoring | **PASS** — fixtures + public R API only |
| Invented timings / R-blocked cells | **N/A** — all five R arms measured |

## Reproduce

```bash
DRM_BRIDGE_TIMING_COHORT=plus5 DRM_372_REPS=5 \
  julia --project=. bench/bridge_six_cell_timing.jl
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  DRM_BRIDGE_TIMING_COHORT=plus5 DRM_372_REPS=5 \
  Rscript --vanilla bench/R/bridge_six_cell_timing.R
```
