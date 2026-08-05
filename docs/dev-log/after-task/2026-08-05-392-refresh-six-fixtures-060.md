# After-task: #392 refresh original six fixtures → drmTMB 0.6.0

Date: 2026-08-05 · closes #392

Perspectives: Shannon · Hopper · Rose. No nested subagents.

## Summary

Re-anchored the original six Workflow G coef fixtures from recorded drmTMB
**v0.1.3** to maintainer-installed **0.6.0** (same seeds/DGPs via
`gen_fixtures.R`), so all eleven admitted cells share one numeric pin.
Verified `DRM_PARITY_TESTS=1` native 11 (+ xfam skip) and bridge 11/11.

## What landed

- Issue #392; branch `feat/392-refresh-six-060` from `a956dbd`
- Regenerated six fixtures (`expected.toml` + `expected.meta.toml`; data.csv
  unchanged — same seeds)
- Soft `[tol]` with measured Δ:
  - `robust-student`: `atol_coef=2e-5`, `atol_vcov=3e-8` (nu |Δ|≈1.21e-5; vcov≈2.04e-8)
  - `meta-analysis-V`: `atol_vcov=3e-8` (mu↔sigma cross |Δ|≈1.46e-8)
- Docs: GENERATING.md, parity README, `r-julia-bridge.md`, `runtests.jl` testset names
- `AGENTS.md` parity anchor: formula spelling stays v0.1.3; numeric fixtures = 0.6.0
- Plan: `docs/dev-log/plans/2026-08-05-refresh-six-fixtures-060-ultra-plan.md`

## Verify (log)

```
native  | 11 Pass, 1 Broken (xfam)
bridge  | 11 Pass
```

## Not covered

- #390 (+5 timing) still OPEN at closeout — rebase if it merges first
- No re-time #372/#389; no Lovelace; no `src/`
- No CRAN/tag claim beyond `packageVersion("drmTMB")` = 0.6.0

## Rose audit

| Check | Verdict |
|---|---|
| Generated numbers only / no GPL | **PASS** |
| Version claim = recorded packageVersion | **PASS** |
| Soft-tol measured + documented | **PASS** |
| Docs no longer split 0.1.3 vs 0.6.0 for Workflow G numbers | **PASS** |
| `.worktrees/` unstaged; D-111 OFF | **PASS** |

*Shannon · Hopper · Rose.*
