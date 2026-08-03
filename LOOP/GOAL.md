# GOAL — issue #372 measured wall-clock for six #370 bridge cells
# (IMMUTABLE once G0 APPROVED — re-read at the top of EVERY arc)
# Status: DONE 2026-08-03 — closed by PR #374 @ 04c482a (G0 was APPROVED earlier same day).

## Mission
Close DRM.jl #372: replace the six #370-bridge fixture cells' **timing not
measured — no claim** with a **retained measured wall-clock artifact** (Julia
`drm_bridge` and/or native `drm` vs local drmTMB on the same fixtures), update
`docs/src/r-julia-bridge.md` only from that artifact, PR `closes #372`.

## Headline
Make the twin-mission speed story auditable for the six families the bridge
already admits — measured edge or honest no-claim with reason — without
inventing timings or re-using the q=4 PLSM 2.18× cell.

## Cohort
**IN:** `gaussian-locscale`, `gaussian-bivariate-rho12`, `robust-student`,
`count-nbinom2`, `proportion-beta`, `meta-analysis-V`.  
**OUT:** `xfam-external-gllvm`.

## Invariants
- New lane / branch for #372 (prefer from `origin/main` after #371 merges).
  Do **not** reopen #370 implementation; leave `.worktrees/` unstaged.
- No Registrator / Julia General (D-111).
- No `:natgrad` / AI-REML; no #291 acceleration follow-on.
- No drmTMB R-side Lovelace / `engine = "julia"` glue edits.
- Never vendor GPL drmTMB source; fixtures stay generated outputs only.
- Do not regress verified q=4 engine (logLik −256.51 / 2.18×); do not edit
  `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi core.
- Do not expand into ROADMAP p>100 head-to-head, #202, or #136.
- Rose speed fence: no measured-speed claim without a retained measurement
  artifact; record exact drmTMB version (prefer v0.1.3 pin).
- PLATFORM after approval: Cursor `/goal` (solo).

## Prior lane note
#370 arcs 0–4 **complete**. PR #371 may still be open/CI-gated at G0 time —
merge is a separate human/CI gate, not this issue's work. Prefer rebase onto
`origin/main` after #371 merges before opening the #372 PR.

## Authoritative WHAT
`LOOP/ultra-plan.md` (frozen at G0) and
`docs/dev-log/plans/2026-08-03-372-six-cell-measured-timing-ultra-plan.md`.

## Definition of done
1. Retained six-cell timing artifact with method, machine, versions, both arms
   (or honest per-cell “R arm blocked — no claim” with reason).
2. `docs/src/r-julia-bridge.md` claim surface matches the artifact (no overclaim).
3. DoD artifacts: check-log.d entry, after-task, Rose claim-vs-evidence.
4. PR closes #372.
