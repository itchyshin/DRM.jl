# After-task: status and ledger cleanup

## Slice

Resume cleanup after the local branch was found to be stale relative to
`origin/main`.

## What changed

- Rebased the work onto a fresh `codex/status-ledger-cleanup` branch from
  current `origin/main` (`1c5094e`, PR #132).
- Updated `README.md` from scaffold-era wording to the current v0.1.1 public
  surface:
  - all drmTMB response families implemented;
  - Gaussian structured/random-effect surface;
  - non-Gaussian GLMM support;
  - open gaps: #80, #17, #11-#13, #5/#19.
- Rewrote `ROADMAP.md` from stale phase wording to the current completed
  milestones, active work, and release targets.
- Updated `docs/dev-log/coordination-board.md` to remove stale PR #74/#70 state
  and list current open overlap, including #135, #137, #138, and #139.
- Added this check-log entry through `docs/dev-log/check-log.d/`, matching the
  collision-free convention added by #124.

## Guardrails

- Did not edit `docs/src/r-julia-bridge.md`; PR #135 owns that page.
- Did not edit `src/DRM.jl`; PR #137 and PR #138 currently touch that shared
  module file.
- Did not edit the frozen `docs/dev-log/check-log.md`.
- Did not claim full R numerical parity; #17 remains open.
- Did not claim non-Gaussian structured effects; #80 remains open.
- Did not promote VA/ELBO capability; #136 is described as an in-flight planned
  lane with deterministic anchors required before promotion.
- No `src/` files or engine behavior changed.

## Verification

- `git diff --check`
- `julia --project=docs docs/make.jl`
- `julia tools/build_check_log.jl --check`

The docs build passed with existing warnings about absolute local links,
docstrings not yet included in `@docs`, missing local logo/favicon assets, and
the npm audit notice.
