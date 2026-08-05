# GOAL — #392 refresh original six fixtures → drmTMB 0.6.0 (IMMUTABLE)
# Status: ACTIVE 2026-08-05 — G0 approved via /goal.

## Mission
Regenerate the original six Workflow G parity fixtures against local installed
drmTMB **0.6.0** (same seeds/DGPs via `gen_fixtures.R`). Re-verify
`DRM_PARITY_TESTS=1` native + bridge (11 cells). Update provenance docs so the
cohort is not split 0.1.3 vs 0.6.0. PR closes #392.

## Headline
Coef pins for the original six still say v0.1.3 while +4 FE /
nbinom2-dispersion / timing arms already use 0.6.0 — close the twin version split.

## Invariants
- One lane: branch `feat/392-refresh-six-060` from tip (prefer after #390).
- Leave `.worktrees/` alone; D-111 OFF; no GPL vendoring.
- Same seeds/DGPs; six cells only; do not redesign DGPs.
- Soft `[tol]` only with measured Δ + Rose note.
- No re-time #372/#389; no Lovelace; no #202/#49; no `src/` unless STOP.
- Record `packageVersion("drmTMB")` only — no CRAN/tag claim.
- AGENTS.md parity-anchor: maintainer-approved via this G0 `/goal`.
- ML default.

## Authoritative WHAT
`docs/dev-log/plans/2026-08-05-refresh-six-fixtures-060-ultra-plan.md` /
`LOOP/ultra-plan.md`.

## Definition of done
- Six `expected.meta.toml` show drmtmb_version 0.6.0 (exact installed)
- native 11 + bridge 11/11 green under `DRM_PARITY_TESTS=1`
- Docs provenance unified; check-log.d + after-task + Rose; PR closes #392
