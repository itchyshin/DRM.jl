# After-task: #383 Workflow G +4 FE bridge parity

Date: 2026-08-03 · closes #383

Perspectives: Shannon (coordination) · Ada · Hopper · Rose. No nested subagents
running for closeout (conductor-local verify).

## Summary

Expanded fixture-backed coefficient-scale R↔Julia parity beyond the closed
six-cell #370 cohort to four FE families already mapped in `_bridge_family`
but previously ungated: **poisson**, **gamma**, **binomial**, **lognormal**.
Reused the #370 harness (`compare_bridge` / `runparity_bridge.jl` / runners) —
no Phase 1.5 rebuild.

## What landed

- Issue [#383](https://github.com/itchyshin/DRM.jl/issues/383)
- Generators in `test/parity/gen_fixtures.R` (+ optional `DRM_PARITY_ONLY=`
  slug filter so the old six are not rewritten under a newer drmTMB)
- Fixtures (MIT-clean generated numbers + `expected.meta.toml`, drmTMB
  **0.6.0**):
  - `count-poisson`
  - `positive-gamma` (`Gamma(link = "log")` in the R call)
  - `binomial-trials` (`cbind(successes, failures)`)
  - `positive-lognormal`
- `_BRIDGE_PARITY_COHORT` + native `_parity_family` admit the four
- Docs: `docs/src/r-julia-bridge.md`, parity README / GENERATING.md
- LOOP kit for this `/goal` run

## Arc0 smoke (pre-fixture)

All four families `drm_bridge`-fit on synthetic data: **PASS** (no parse /
family-dispatch failures). Post-fixture bridge compare: loglik Δ ~1e-12–1e-13
— **no scale-risk**; no `[tol]` overrides needed.

## Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| +4 FE cells pass coef-scale parity through `drm_bridge` | **PASS** — bridge suite 10/10 |
| Native path green for old six + new four | **PASS** — native 10 pass + xfam skip |
| Always-on harness still green | **PASS** — 17+8 |
| Docs list admitted cells with version honesty (0.1.3 vs 0.6.0) | **PASS** |
| Speed / wall-clock for the +4 cells | **NO CLAIM** — not measured |
| Re-use of verified 2.18× q4 cell as evidence | **FORBIDDEN / not done** |
| GPL vendoring | **PASS** — generated numbers only; no drmTMB source |
| q4 engine regression (−256.51 / 2.18×) | **PASS** — no edits under q4 `src/` |
| Lovelace / drmTMB R glue / D-111 / #202 / #49 / #136 | **OUT** — untouched |
| #186 epic under-run | **DONE (ledger)** — subtasks #187–#189 already CLOSED; epic checklist closed |

## Not covered

- Measured Julia vs drmTMB wall-clock for the +4 cells
- Regenerating the original six against drmTMB 0.6.0 (left at v0.1.3 numbers)
- `nbinom2-dispersion` cohort admission (generator exists; fixture not in cohort)
- R-side `engine = "julia"` Lovelace edits
- xfam-external-gllvm

## Verify

```bash
julia --project=. -e 'include("test/test_parity_harness.jl")'
DRM_PARITY_TESTS=1 julia --project=. -e '
  using Test, DRM
  @testset "native" begin include("test/parity/runparity.jl") end
  @testset "bridge" begin include("test/parity/runparity_bridge.jl") end
'
```

Receipt (2026-08-03, local macOS Julia 1.10): harness 17+8; native 10 pass +
1 broken(skip xfam); bridge **10/10**.
