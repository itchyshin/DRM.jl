# GOAL — R-parity +4 FE bridge cohort (IMMUTABLE — re-read at the top of EVERY arc)
# G0 APPROVED 2026-08-03. Platform: Cursor. `/goal` execution.

## Mission
Open and close one DRM.jl issue — expand Workflow G coefficient-scale R↔Julia
parity (native `drm()` + `drm_bridge`) to four fixed-effect families already
bridge-mapped but not fixture-gated: **poisson**, **gamma**, **binomial**,
**lognormal**. Commit MIT-clean generated drmTMB numbers only; wire into
`_BRIDGE_PARITY_COHORT` + runners; update `docs/src/r-julia-bridge.md`; PR
closes the new issue.

## Headline
Retire the #370 after-task gap “families beyond the six fixtures” for the next
FE cohort without rebuilding Phase 1.5 / #370 harness.

## Invariants
- One lane on this repo; leave `.worktrees/` alone / never stage it.
- D-111 OFF — no Registrator / Julia General.
- Never vendor GPL drmTMB source — generated fixture numbers + meta only.
- No q4 engine `src/` edits (`fit_q4_sparse_tmb.jl` / `sparse_aug_plsm.jl` / Takahashi).
- No Lovelace / drmTMB R-side `engine="julia"` edits.
- Do not reopen #5 / #349 / #17 / #370 / #372 / #376; do not rebuild #376;
  no tip-idle SHA-churn; defer #202 / #49 / #136 / xfam.
- ML default; `DRM_PARITY_TESTS=1` local first; Rose default **no speed claim**.
- Risk branch: if a family needs non-trivial scale transform beyond `[tol]`,
  admit green subset and document failures — do not redesign the engine.

## Authoritative WHAT
`LOOP/ultra-plan.md` ← `docs/dev-log/plans/2026-08-03-r-parity-plus4-fe-bridge-ultra-plan.md`

## Definition of done
- New issue opened + closed by PR (`closes #NN`)
- Fixtures (or honest admitted subset ≥1) committed under `test/parity/fixtures/`
- `_BRIDGE_PARITY_COHORT` + native `_parity_family` admit the new cells
- `DRM_PARITY_TESTS=1` native + bridge green for old six **and** new admitted
- `docs/src/r-julia-bridge.md` claim list updated
- check-log.d + after-task + Rose claim-vs-evidence PASS
- Optional under-run only if early: close stale epic #186 checklist (ledger only)
