# After-task: #370 bridge fixture coefficient-scale parity

Date: 2026-08-03 · closes #370

Perspectives: Shannon (coordination) · Ada · Hopper · Rose. No nested subagents.

## Summary

Closed the documented `docs/src/r-julia-bridge.md` blocker (“broader families
wait for coefficient-scale parity tests”) for the six Workflow G fixture
families by exercising **`drm_bridge`** (the marshalling path R will call)
against committed drmTMB v0.1.3 **generated numbers only**, behind
`DRM_PARITY_TESTS=1`.

## What landed

- `compare_bridge` in `test/parity/compare.jl` — Dict-shaped bridge payload vs
  `ParityExpected` (same coef / loglik / vcov contract as `compare_fit`).
- `test/parity/runparity_bridge.jl` — six-cell cohort runner; wired from
  `test/runtests.jl` under the same env gate as native `runparity.jl`.
- Always-on harness: `compare_bridge` self-consistency + mismatch detection in
  `test/test_parity_harness.jl`.
- Student fixture honesty: undo stale `log(ν)` Jacobian transform so `nu` sits
  on the shared drmTMB / DRM.jl `log(ν − 2)` scale; modest `[tol] atol_coef /
  atol_vcov` for optimizer soft-diff (~1e-5 on η_ν; loglik Δ ~1e-10).
- Native runner: skip `xfam-external-gllvm` (OUT of cohort; incomplete
  expected.toml) instead of KeyError.
- Docs: `docs/src/r-julia-bridge.md` claim surface; parity README /
  GENERATING.md / `gen_fixtures.R` transform notes aligned.
- Timing artifact: `docs/dev-log/evidence/2026-08-03-370-timing-no-claim.md`
  — honest no-claim for all six cells.

## Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| Six cohort cells pass coef-scale parity through `drm_bridge` | **PASS** — `DRM_PARITY_TESTS=1` bridge suite 6/6 |
| Native path still green for the six | **PASS** — native 6 pass + xfam skip |
| Always-on harness still green | **PASS** — `test_parity_harness.jl` 17+8 |
| Broader families unblocked *for these six fixtures* | **PASS** — docs list the six explicitly |
| Speed / wall-clock edge vs drmTMB for these cells | **NO CLAIM** — timing not measured; artifact path above |
| Re-use of verified 2.18× q4 cell as evidence for these families | **FORBIDDEN / not done** |
| GPL vendoring | **PASS** — fixtures remain generated numbers; no drmTMB source |
| q4 engine regression (−256.51 / 2.18×) | **PASS** — no edits under `src/fit_q4_sparse_tmb.jl` / `sparse_aug_plsm.jl` |
| Lovelace / drmTMB R glue / D-111 / :natgrad / #202 / #136 | **OUT** — untouched |

## Not covered

- Measured Julia vs drmTMB wall-clock for the six cells.
- R-side `engine = "julia"` Lovelace edits (drmTMB repo).
- xfam-external-gllvm admission.
- Families / formula shapes beyond the six fixtures.

## Verify

```bash
julia --project=. -e 'include("test/test_parity_harness.jl")'
DRM_PARITY_TESTS=1 julia --project=. -e '
  using Test, DRM
  @testset "native" begin include("test/parity/runparity.jl") end
  @testset "bridge" begin include("test/parity/runparity_bridge.jl") end
'
```

Receipt (2026-08-03, local macOS Julia 1.10): harness green; native 6 pass +
1 broken(skip xfam); bridge 6 pass.
