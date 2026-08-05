# GOAL — #389 +5 bridge timing (IMMUTABLE — re-read every arc)
# Status: ACTIVE 2026-08-05 — G0 approved via /goal.

## Mission
Measure warm wall-clock for five admitted-but-untimed bridge cells
(`count-poisson`, `positive-gamma`, `binomial-trials`, `positive-lognormal`,
`nbinom2-dispersion`) by reusing the #372 harness (Julia `drm_bridge` vs local
drmTMB). Retain evidence + update `docs/src/r-julia-bridge.md` from that
artifact only. PR closes #389.

## Headline
Coef parity is green for these cells; docs still say timing no-claim — close
the Rose gap with the #372 protocol.

## Invariants
- One lane: branch `feat/389-plus5-bridge-timing` from `a956dbd`.
- Leave `.worktrees/` alone; D-111 OFF; no GPL vendoring.
- Do not re-time original six; do not refresh v0.1.3 fixtures; no #376/q4;
  no Lovelace; no inventing general “Nx faster”.
- No `src/` unless a fit bug blocks a cell (then STOP).
- Protocol: 1 warmup + 5 timed; BLAS/OMP=1; median R/J; record versions.
- Honest block per cell if R fails — never invent timings.
- ML default; Rose scoped ratios only.

## Authoritative WHAT
`docs/dev-log/plans/2026-08-05-plus5-bridge-timing-ultra-plan.md` /
`LOOP/ultra-plan.md`. Tip `origin/main` @ `a956dbd`.

## Definition of done
- Evidence artifact for all five cells (or honest FAIL notes)
- `r-julia-bridge.md` claim surface updated from artifact only
- check-log.d + after-task + Rose; PR closes #389
