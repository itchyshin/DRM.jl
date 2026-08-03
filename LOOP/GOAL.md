# GOAL — issue #370 bridge fixture coefficient-scale parity
# (IMMUTABLE — G0 APPROVED 2026-08-03 by Shinichi; re-read at the top of EVERY arc)

## Mission
Close DRM.jl #370: coefficient-scale R↔Julia parity for the Workflow G fixture
cohort **via `drm_bridge`** (not only native `drm()`), behind `DRM_PARITY_TESTS=1`,
with per-cell measured timing notes **or** honest `timing not measured — no claim`
lines; update `docs/src/r-julia-bridge.md` so the claim surface matches the gate;
PR `closes #370`.

## Headline
Retire the documented blocker (“broader families wait for coefficient-scale
parity tests”) for six in-tree fixtures by exercising the marshalling path R
will call, using committed drmTMB v0.1.3 **generated numbers only** (MIT/GPL-clean).

## Cohort
**IN:** `gaussian-locscale`, `gaussian-bivariate-rho12`, `robust-student`,
`count-nbinom2`, `proportion-beta`, `meta-analysis-V`.  
**OUT:** `xfam-external-gllvm` (unless twin-mission owner explicitly overrides).

## Invariants
- One DRM.jl lane on `feat/370-bridge-fixture-parity`; leave `.worktrees/` unstaged.
- No Registrator / Julia General (D-111).
- No `:natgrad` / AI-REML; no #291 acceleration follow-on.
- No drmTMB R-side Lovelace / `engine = "julia"` glue edits in this issue.
- Never vendor GPL drmTMB source; fixtures stay generated outputs only.
- Do not regress verified q=4 engine (logLik −256.51 / 2.18×); do not edit
  `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi core for this issue.
- Do not expand into #202 or #136.
- Rose speed fence: no measured-speed claim without a retained measurement artifact.
- PLATFORM after approval: Cursor `/goal` (solo).

## Authoritative WHAT
`LOOP/ultra-plan.md` (frozen at G0) and
`docs/dev-log/plans/2026-08-03-370-bridge-fixture-parity-ultra-plan.md`.

## Definition of done
1. Six cohort cells pass coefficient-scale parity through `drm_bridge` under
   `DRM_PARITY_TESTS=1` (coef bar ≤1e-6 per issue / Workflow G; reuse `compare.jl`
   contract; logLik/vcov per fixture supply + tolerances).
2. Each newly admitted cell has a retained measured timing note **or** an honest
   `timing not measured — no claim` line.
3. `docs/src/r-julia-bridge.md` claim surface matches the gate (no overclaim).
4. DoD artifacts: tests wired, docstrings if new public helpers, worked note or
   doc example, `docs/dev-log/check-log.d/` entry, after-task, Rose claim-vs-evidence.
5. PR closes #370.
