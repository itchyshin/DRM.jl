# 2026-08-18 — Option A: include deferred standalones in `runtests.jl`

**Lane:** `option-a-runtests` · `closes #445`
**Platform:** Cursor (Shannon). No nested subagents.
**Wait-gate:** #423 MERGED `7dcaa41e` (2026-08-18T15:29:38Z); #428 MERGED `d40552ae` (2026-08-18T16:41:06Z).

## What landed

`test/runtests.jl` now includes the three files that waited on that gate:

- `test/test_reml_ordinary_ranef.jl` (#439 / #440)
- `test/test_parity_biv_q4_phylo_reml.jl` (#433 / #434)
- `test/test_parity_gaussian_phylo_mean.jl` (#437 / #438)

Header comments that said “do not wire while #423/#428 own `runtests.jl`” were updated. No `src/` edits. No GLLVM. No Cox–Reid.

## Rose audit

- **Claim-vs-evidence:** DoD item 2 is now complete for these three files. `claim_status` stays **partial**. No TSV `supported`. No “parity complete.”
- **Scope honesty:** include-only. Documenter capability chips were left alone (a chip flip is a separate claim, not this slice).
- **License:** no drmTMB source vendored.
- **Drift:** coordination board not edited (already on `origin/main`).

## Not done

- No capability-status / Documenter **Tested** flip
- No #256 / #255
- No REML / Cox–Reid / AGHQ restart

`PLATFORM: cursor | ON BRANCH: cursor/option-a-runtests | LANE: option-a-runtests`
`OTHER LANES: claude+cox-reid-wire · cursor+pr423-ci-tol · cursor+cox-reid-probe · docs/a3c-design · #420 · #406`
