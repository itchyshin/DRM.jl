# Approved ultra-plan (frozen at G0) — R-parity +4 FE bridge

**Source:** `docs/dev-log/plans/2026-08-03-r-parity-plus4-fe-bridge-ultra-plan.md`
**Status:** G0 APPROVED 2026-08-03 · tip `origin/main` @ `b538768` (or newer)

## Cohort
`poisson` / `gamma` / `binomial` / `lognormal` — already in `_bridge_family`,
absent from `_BRIDGE_PARITY_COHORT` / fixtures.

## Harness reuse (#370)
`compare_bridge` / `runparity_bridge.jl` / `runparity.jl` / `gen_fixtures.R`
— **no rebuild**.

## Arcs
1. **Arc0** — `gh issue create`; 4-cell `drm_bridge` smoke (pass/fail/scale-risk)
2. **Rung1** — generators + MIT-clean fixtures + `expected.meta.toml` (record drmTMB version)
3. **Rung2** — wire cohort + runners; `DRM_PARITY_TESTS=1` native+bridge green
4. **Docs** — `docs/src/r-julia-bridge.md` (+ parity README if needed)
5. **Closeout** — check-log.d + after-task + Rose; PR `closes #NN`
6. **Optional under-run** — #186 epic checklist ledger close if early

## Fences
D-111 OFF · leave `.worktrees/` · no GPL · no q4 `src/` · no Lovelace ·
do not reopen #5/#349/#17/#370/#372/#376 · no tip-idle churn · defer
#202/#49/#136.

## Risk branch
Non-trivial scale mismatch → admit green subset + document failures; no engine redesign.

## Done when
PR merges with +4 fixtures (or honest subset ≥1), gates green for admitted
cells, docs list them, Rose PASS, `closes #NN`.
