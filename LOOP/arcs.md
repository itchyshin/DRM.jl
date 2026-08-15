# Arcs — DRM.jl `engine = "julia"` catch-up campaign

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

Refresh the countdown before picking an arc:
`python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main`

| id | status | slice | what | est | gate |
|---|---|---|---|---|---|
| **A0** | done | parity ledger | `tools/parity_ledger.py` + first measured run. Anchor pinned at drmTMB 0.7.0 `f5ec53634`. Corrected three stale premises (see GOAL). Evidence: `docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md` | 2–3 h | no |
| **A1** | done | vcov guard | `src/vcov_guard.jl` `_vcov_from_hessian`; 45 fitter sites / 17 files + 2 ad-hoc blocks in `gaussian_bivariate.jl`. 18 suites pass; VA scaffold 15/15 (was 14/1 error). Unblocks drmTMB #406 | 3–4 h | no |
| **A2a** | done | result-shape contract (Julia) | Enrich `drm_bridge` / `drm_bridge_inference` payload so drmTMB's R post-fit works unchanged on a Julia fit: `fitted_distribution`, `qq_plot`, `worm_plot`, `centile_chart`, `exceedance`, `predict(dpar="sigma")`, scale/variance Wald blocks. `julia-engine.Rmd` names the shortfall | 1–2 d | no |
| **A2b** | blocked | result-shape contract (R) | Widen gate + parity fixtures so those calls are admitted, not errored | 0.5–1 d | **[GATE]** drmTMB PR timing |
| **A3a** | done | `biv_lognormal` | **RE-SCOPED — next arc.** Closed-form (dr18): bivariate normal on `log y` × Jacobian `∏1/yᵢ`. Reuses `_fit_bivariate_residual` (`gaussian_bivariate.jl:187`) + log-transform + `+Σ log yᵢ` + `y>0` check. **DONE** — PARITY_PASS vs native drmTMB (coef 9.15e-07, logLik 7.39e-12); identities asserted; PR #410 | 0.5–1 d | no |
| **A3b** | pending | `biv_student` | Exact bivariate-t density (dr19); **ν structurally SHARED** across margins. Same scaffold, new kernel + one scalar ν. dr19's RQMC/derivative-free caveat is about *probabilities*, not our density — do not import it | 1–1.5 d | no |
| **A3c** | pending | staged `biv_associate` | Two-stage: frozen margins → latent-normal copula `eta`. `associate_pairs` / `association` / `latent_normal`. **Needs its own design pass first** — uncertainty propagation through frozen margins is the hard part | 2–3 d | **[GATE]** design pass |
| **A4+** | pending | remaining rows | Per the ledger: distributional outputs (5) · spatial mesh (`make_mesh`, `spatial_coords`) · phylo penalty (2) · `categorical` family · misc (`profile_targets`, `rho_latent`, `structured_effects`, `corpair`, `meta_vcov_bivariate`) | per ledger | no |
| **A-park** | parked | missing data / FIML | `mi`, `impute_model`, `imputed`, `miss_control` + `base_impute` gate. **#49 PARKED** | — | **[GATE]** owner |
| **A-tag** | pending | release boundary | Rose pre-publish audit (Workflow F) + license-boundary check + version bump | — | **[GATE]** owner |

## Open gates (need human)

1. **drmTMB PR timing** — before or after 0.7.0 ships? Its tree has 9 live lanes
   and an open release slice #959. D-111's "drmTMB first" suggests after. All
   Julia-side arcs proceed either way.
2. ~~**A3 re-scope**~~ **DONE 2026-08-14** — see
   `docs/dev-log/design/2026-08-14-a3-rescope-bivariate-nongaussian.md`. Split into
   A3a/A3b/A3c above; cluster ≈ 4–6 d (≈ double the 2–3 d the original A3 carried),
   but no single sub-arc is. **A3a is the recommended next arc.**

## Do not autoload

Later #136 two-part / ZI×RE · #49 · `engine_control` · Julia General · q=4 core
rewrite · phylo×spatial joint engine · drmTMB work outside the narrow lane.
