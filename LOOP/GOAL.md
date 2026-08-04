# GOAL — #385 admit nbinom2-dispersion parity (IMMUTABLE — re-read every arc)
# Status: ACTIVE 2026-08-03 — G0 approved via /goal paste.

## Mission
Close DRM.jl #385: commit MIT-clean drmTMB-generated numbers for
`nbinom2-dispersion`, admit the cell into `_BRIDGE_PARITY_COHORT` (and native
fixture walk), update `docs/src/r-julia-bridge.md`, PR `closes #385`.

## Headline
Retire the #383 after-task gap: generator exists, fixture/cohort admission missing.

## Invariants
- One lane: branch `feat/nbinom2-dispersion-parity` from `c9b9bd9`. Leave `.worktrees/` alone.
- D-111 OFF (no Registrator / Julia General).
- Never vendor GPL drmTMB source; public API + generated fixtures only.
- Do not edit q4 engine core (`src/fit_q4_sparse_tmb.jl` / sparse_aug_plsm / Takahashi).
- Reuse #370/#383 harness — no Phase 1.5 rebuild; no Lovelace R edits.
- Rose: no speed claim for this cell unless measured (default no-claim).
- ML default.

## Authoritative WHAT
G0 paste in Cursor `/goal` session; tip was `origin/main` @ `c9b9bd9`.

## Definition of done
- Fixture `test/parity/fixtures/nbinom2-dispersion/` with expected.toml + meta + data
- Cohort + docs list the cell; `DRM_PARITY_TESTS=1` native+bridge green (prior 10 + this)
- check-log.d + after-task + Rose; PR closes #385
