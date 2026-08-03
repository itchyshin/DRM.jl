# After-task: #372 six-cell measured wall-clock

Date: 2026-08-03 · closes #372

Perspectives: Shannon (coordination) · Ada · Curie · Rose. No nested subagents.

## Summary

Replaced the #370 “timing not measured — no claim” for the six admitted
`drm_bridge` fixture cells with a **retained measured wall-clock artifact**
(Julia `drm_bridge` vs local drmTMB **0.6.0** on the same `data.csv` fixtures),
then updated `docs/src/r-julia-bridge.md` only from that artifact.

## What landed

- Arc 0 probe: `docs/dev-log/evidence/2026-08-03-372-arc0-probe.md`
- Harness: `bench/bridge_six_cell_timing.jl`, `bench/R/bridge_six_cell_timing.R`
- Retained evidence: `docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md`
  + machine-readable twins under `docs/dev-log/evidence/372-six-cell-timing/`
- Docs: `docs/src/r-julia-bridge.md` claim surface (scoped ratios; no general Nx;
  not the q4 2.18× cell)
- DoD: this after-task + check-log.d entry + Rose audit below
- LOOP tip updated for #372 lane

## Measurement summary (warm median; R / Julia)

| Cell | Julia median_s | R median_s | ratio |
|---|---:|---:|---:|
| gaussian-locscale | 0.000979 | 0.020 | 20.4× |
| gaussian-bivariate-rho12 | 0.003093 | 0.015 | 4.8× |
| robust-student | 0.002513 | 0.018 | 7.2× |
| count-nbinom2 | 0.000921 | 0.020 | 21.7× |
| proportion-beta | 0.001559 | 0.017 | 10.9× |
| meta-analysis-V | 0.000432 | 0.020 | 46.3× |

## Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| Six cells have retained both-arm wall-clock numbers | **PASS** — evidence md + TOML/JSON |
| Bridge docs match the artifact (scoped; versions recorded) | **PASS** |
| No “Nx faster for all models” overclaim | **PASS** |
| No re-use of q4 2.18× as evidence for these families | **PASS** |
| drmTMB version honesty (0.6.0 ≠ fixture pin 0.1.3) | **PASS** — recorded |
| GPL vendoring | **PASS** — public API + fixtures only |
| q4 engine regression (−256.51 / 2.18×) | **PASS** — no `src/` engine edits |
| D-111 / `:natgrad` / Lovelace / p>100 / second #370 lane | **OUT** — untouched |
| R-blocked cells | **none** — all six R arms measured |

## Not covered

- Temporary-lib drmTMB v0.1.3 R arm (optional; not required with version recorded)
- ROADMAP p>100 head-to-head
- R-side `engine = "julia"` Lovelace glue
- CI timing / Totoro campaign

## Verify

```bash
# Re-read retained numbers (primary verify)
sed -n '1,120p' docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md

# Optional reproduce
julia --project=. bench/bridge_six_cell_timing.jl
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  Rscript --vanilla bench/R/bridge_six_cell_timing.R
```

Receipt: 2026-08-03 local macOS arm64 · Julia 1.10.0 · drmTMB 0.6.0 · all six
cells both arms ok.
