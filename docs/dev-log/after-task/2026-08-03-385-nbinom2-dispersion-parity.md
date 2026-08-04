# After-task: #385 admit nbinom2-dispersion parity

Date: 2026-08-03 · closes #385

Perspectives: Shannon · Ada · Hopper · Rose · Noether (narrow AD guard). No nested
subagents at closeout.

## Summary

Admitted `nbinom2-dispersion` (NB2 FE `y ~ x; sigma ~ x`) into the Workflow G
coefficient-scale cohort. Reused #370/#383 harness. Generator already existed;
fixture was never committed.

## What landed

- Issue [#385](https://github.com/itchyshin/DRM.jl/issues/385)
- Fixture `test/parity/fixtures/nbinom2-dispersion/` (drmTMB **0.6.0** numbers)
- `_BRIDGE_PARITY_COHORT` + docs (`r-julia-bridge.md`) — **11** admitted cells
- Engine: `_nb2(r,p) = NegativeBinomial(...; check_args=false)` in
  `src/negbinomial.jl` — ForwardDiff Dual with value `p=1.0` fails
  Distributions' `p <= one(p)` because `one(p)` has zero partials
- Unit: `test/test_nbinom2.jl` FE `sigma ~ x` regression
- Soft-diff: `[tol] atol_coef = 2e-5` (σ intercept Δ ~7.7e-6; loglik Δ ~1e-9)

## Rose audit

| Claim | Verdict |
|---|---|
| Cell passes coef-scale parity via native + `drm_bridge` | **PASS** — bridge 11/11 |
| Prior 10 cells still green | **PASS** |
| Harness always-on green | **PASS** |
| Timing / speed for this cell | **NO CLAIM** |
| GPL vendoring | **PASS** — generated numbers only |
| q4 engine regression | **PASS** — no q4 `src/` edits |
| Lovelace / D-111 / #202 / #49 | **OUT** |

## Not covered

- Measured wall-clock for this cell
- Regenerating original six to drmTMB 0.6.0
- `nbinom2-locscale` coupled RE (drmTMB unsupported; generator guarded)

## Verify

```bash
julia --project=. -e 'include("test/test_parity_harness.jl")'
julia --project=. -e 'include("test/test_nbinom2.jl")'
DRM_PARITY_TESTS=1 julia --project=. -e '
  using Test, DRM
  @testset "native" begin include("test/parity/runparity.jl") end
  @testset "bridge" begin include("test/parity/runparity_bridge.jl") end
'
# → harness 17+8; nbinom2 5+4; native 11 + xfam skip; bridge 11/11
```
