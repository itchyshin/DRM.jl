# After-task: #389 +5 bridge measured wall-clock

Date: 2026-08-05 · closes #389

Perspectives: Shannon (coordination) · Ada · Curie · Rose. No nested subagents.

## Summary

Closed the Rose timing no-claim gap for the five #383/#385 bridge cells by
reusing the #372 harness (`DRM_BRIDGE_TIMING_COHORT=plus5`), retaining a
measured wall-clock artifact (Julia `drm_bridge` vs local drmTMB **0.6.0**),
and updating `docs/src/r-julia-bridge.md` from that artifact only.

## What landed

- Issue #389; branch `feat/389-plus5-bridge-timing` from `a956dbd`
- Harness extend: plus5 cohort + R `fit_cell` constructors; env
  `DRM_BRIDGE_TIMING_COHORT=plus5`
- Evidence: `docs/dev-log/evidence/2026-08-05-389-plus5-bridge-timing.md`
  + twins under `docs/dev-log/evidence/389-plus5-bridge-timing/`
- Docs: `docs/src/r-julia-bridge.md` (#372 + #389 scoped; no general Nx)
- Plan committed: `docs/dev-log/plans/2026-08-05-plus5-bridge-timing-ultra-plan.md`
- LOOP kit for #389; check-log.d + this after-task

## Measurement summary (warm median; R / Julia)

| Cell | Julia median_s | R median_s | ratio |
|---|---:|---:|---:|
| count-poisson | 0.000185 | 0.011 | 59.6× |
| positive-gamma | 0.000662 | 0.013 | 19.6× |
| binomial-trials | 0.001053 | 0.012 | 11.4× |
| positive-lognormal | 0.000309 | 0.012 | 38.8× |
| nbinom2-dispersion | 0.001147 | 0.018 | 15.7× |

## Not covered

- Original six not re-timed (#372 stands)
- Fixture 0.6.0 refresh of v0.1.3 six; #376/q4; Lovelace; `src/`
- CI timing; Totoro

## Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| Five cells have retained both-arm wall-clock numbers | **PASS** |
| Docs claim matches artifact only (scoped 11.4×–59.6×) | **PASS** |
| No general Nx / no q4 2.18× reuse | **PASS** |
| No GPL vendoring; `.worktrees/` unstaged; D-111 OFF | **PASS** |
| No invented timings | **PASS** — all five R arms ok |

*Shannon · Curie · Rose.*
