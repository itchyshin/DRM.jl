# Arcs — from the approved G0 ultra-plan

Status: todo / doing / done / blocked. Gate = needs a human before it proceeds.

Refresh the countdown before picking an arc — the twin moves:
`python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main`

| # | arc | status | est | gate? |
|---|-----|--------|-----|-------|
| A-fix | `biv_student` recovery tolerance — exclude `log(ν−2)` from the blanket check (~4× the spread of every other coef); ν covered by its own `3.5 < ν̂ < 10` range. Unblocks **#410** | **done** (landed on #410's branch before the lane opened; reproduced on Julia 1.12: old \|dev\| 0.5198 vs atol 0.25) | 0.5 h | — |
| A3c-2 | Four quadrature pair classes — `gaussian_nbinom2`, `bernoulli_bernoulli`, `bernoulli_nbinom2`, `nbinom2_nbinom2` — via **QuadGK** (already a dep), with per-row integration-error diagnostics. drmTMB reduces the 2-D rectangle to a **1-D adaptive integral**: `∫ φ(z₁)·Φ(cond z₂) dz₁`, `rel.tol = 1e-10`, and it KEEPS `abs.error` | **done** (23eb10af) — all 4 classes; gaussian_nbinom2 is CLOSED FORM so only 3 need quadrature | 1.5–2 d | — |
| A3c-3 | `associate_pairs` parity fixture vs drmTMB 0.7.0 (now runnable locally — 0.7.0 is installed) + diagnostic/warning parity (multistart disagreement, experimental-interval warning, refusal surface) | **done** (a5c56807) — 2/5 parity PASS then 5/5 after the NB2 fix; found a real DRM.jl bug | 0.5–1 d | — |
| A-sigma | `sigma()` contract → unblock `V_known` / meta post-fit (the A2a remainder). `gaussian_meta.jl` stores `scales[:sigma] = sqrt(v + σ²)` (TOTAL) while drmTMB's meta `sigma` dpar is the heterogeneity alone with `V_known` separate — shipping both **double-counts**. Adding `scales` keys silently breaks `sigma()` (`gaussian_core.jl:975` returns a bare vector only when `scales` has exactly one key) | **done** (6b7caf6c) — GATE DISSOLVED: no API change needed, V_known recoverable to 1.1e-16 | 0.5–1 d | **[GATE]** surface the design before landing |
| A-drmtmb | drmTMB **narrow-lane** registry extension. The content is already written: `docs/dev-log/evidence/2026-08-14-proposed-registry-extension.md`. Apply via a temp `git worktree` off drmTMB `origin/main` — **never** `git checkout` in that shared tree | **done** — drmTMB PR #1032 OPEN, NOT merged (gate held) | 0.5 d | **[GATE]** open PR, **NEVER merge** |
| ~~A4a~~ | `categorical` is **NOT a response family** — it returns a `drm_impute_family` (imputation, link `baseline_softmax`); belongs to the missing-data cluster | **MOVED to #49 PARKED** | — | **[GATE]** owner confirm |
| ~~A4b~~ | `make_mesh`/`spatial_coords` are R-side geospatial prep (`sf`, CRS validation, lon/lat projection) running BEFORE the model | **proposed OUT OF SCOPE** (deliberately-not-ported) | — | **[GATE]** owner confirm |
| A4c | Phylo penalty — `drm_phylo_penalty(sd_u, sd_alpha, cor_sd)` + `_sweep`. A PC-prior-style penalty spec that **changes the objective** ⇒ genuine engine capability | todo | ~1 d | — |
| A4d-1 | `corpair` **formula MARKER** (`invisible(NULL)`, parsed) — NOT the post-fit `corpairs` DRM.jl already exports. Touches `bf()` ⇒ **`DRM_PARITY_TESTS=1` mandatory** | todo | 0.5 d | — |
| A4d-2 | `profile_targets`, `structured_effects`, `meta_vcov_bivariate` — assess each; port only what is engine capability. (`rho_latent` already present) | todo | 0.5–1 d | — |

**A4 design pass DONE** (`docs/dev-log/design/2026-08-15-a4-rescope.md`) — it re-scoped THREE of the four clusters; revised total ~2–2.5 d, down from ~4–4.5, and none of the removed work was real.

_Original rationale:_ The A3c design pass paid for
itself twice over — it found the QuadGK dependency and the frozen-margin
uncertainty trap before a line was written.

## Reference — what A3c-1 already established (build ON it, don't refork)

`src/associate_pairs.jl` holds the staged architecture: `LatentNormal`,
`PairAssociation`, `_assoc_components` (freeze), `_assoc_optimise_scalar`
(bounded golden-section, multistart), FD score/curvature, `near_boundary`,
`multistart_disagreement`, and `association()`. A3c-2 adds pair classes to
`_assoc_components` + a rectangle-probability likelihood — it does **not** need a
new estimator.

**Sign convention:** drmTMB's `curvature` negates the objective's second
difference, so it is the **loglik** curvature and is **negative** at a maximum.
A test pins this.

## Total

Well beyond one session. The loop runs the list in order and stops where it
stops — that is expected, not a failure. Land the checkpoint before stopping.
