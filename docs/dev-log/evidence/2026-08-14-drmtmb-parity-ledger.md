# A0 — drmTMB parity ledger: first measured run

Date: 2026-08-14 · lane: DRM.jl (Claude) · arc: A0 of the `engine = "julia"`
catch-up campaign · tool: [`tools/parity_ledger.py`](../../../tools/parity_ledger.py)

## What this is

The campaign's countdown. `drmTMB` already carries the authoritative ledger —
`inst/extdata/julia-capabilities.tsv`, `inst/extdata/julia-gates.tsv`, and
`drm_julia_capability_comparison()` in `R/julia-bridge.R`. This arc did **not**
build a new one; it built a re-runnable reconciliation of that ledger against
DRM.jl's actual export surface.

## Anchor

**drmTMB 0.7.0 @ `origin/main` `f5ec53634`.** Re-run the tool to refresh:

```bash
python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main
```

## Measured state (2026-08-14)

| Axis | Count |
|---|---|
| drmTMB exports | 59 |
| DRM.jl exports | 142 |
| drmTMB exports with no DRM.jl twin | **25** |
| Bridge capability rows | 11 — 6 `partial`, 4 `experimental`, 1 `unsupported` |
| Gates closed by intentional error | **14** |

**No capability row is `supported`.** Every row is `partial`, `experimental`, or
`unsupported` by design. That is a deliberate tightening on the drmTMB side (the
claim-demotion rule), not a regression — but it means "caught up" cannot be
measured by row status alone until that vocabulary is reconciled with
[[DECISIONS#D-111]]'s readiness bar.

### The 25 export gaps, clustered

| Cluster | Exports | Note |
|---|---|---|
| **Bivariate non-Gaussian** (new in 0.7.0) | `biv_lognormal`, `biv_student`, `biv_associate`, `associate_pairs`, `association`, `latent_normal` | whole capability family DRM.jl lacks; matches the new `bivariate-nongaussian` vignette |
| Distributional outputs & adequacy | `fitted_distribution`, `centile_chart`, `exceedance`, `qq_plot`, `worm_plot` | post-fit — R-side on the returned object; needs payload, not Julia ports |
| Missing data | `mi`, `impute_model`, `imputed`, `miss_control` | **#49 PARKED**; also closed at the gate (`base_impute`) |
| Spatial mesh | `make_mesh`, `spatial_coords` | |
| Phylo penalty | `drm_phylo_penalty`, `drm_phylo_penalty_sweep` | |
| Family | `categorical` | the one missing family |
| Misc | `profile_targets`, `rho_latent`, `structured_effects`, `corpair`, `meta_vcov_bivariate` | |

Excluded as R-idiom, not capability: `gr`, `drm_control`, `meta_known_V`
(deprecated). Name-aliased and therefore **not** gaps: `nbinom2` →
`NegBinomial2`, `truncated_nbinom2` → `TruncatedNegBinomial2`, `biv_gaussian` →
`cbind`, `drmTMB` → `drm`, `phylo_interaction` → `fit_phylo_interaction`.

## Correction to the campaign's opening premises

Three premises in the approved plan were wrong, all from the same cause.

**The drmTMB working checkout was 987 commits behind `origin/main`** (on branch
`claude/handover-freshness-0718`). Reading it produced:

| Plan said | Truth on `origin/main` |
|---|---|
| drmTMB is `0.6.0.9000`; re-anchor later at 0.7.0 | drmTMB **is 0.7.0**; 0.7.0 is the anchor now |
| 51 exports, 33 vignettes, 9 registry rows | **59** exports, **37** vignettes, **11** rows |
| Fixed-effect non-Gaussian is an `intentional_error` — the headline gap | **already `experimental` / `partial`**, admitted by PR #499 (2026-08-09); the `base_nonphylo_count` gate row was removed |

The headline capability gain named in the plan (admitting FE non-Gaussian) was
therefore **largely already delivered** before the campaign began. The genuine
headline is the **bivariate non-Gaussian cluster** new in 0.7.0.

**Lesson (generalises):** a sibling repo's working checkout is not that repo's
state. Read a twin through `git show <ref>:<path>`, never the working tree —
`tools/parity_ledger.py` now enforces this by construction. This is the same
class as the standing rule that `git log` without `--all` measures only the
checkout.

## What this does not establish

Export-name presence is **not** capability parity, and direct DRM.jl evidence is
**not** R-via-Julia bridge support. A capability row is promoted only on a
native-vs-Julia same-target comparison (matching coefficients and logLik within
the row's declared tolerance). This run measures the *surface*; it does not
promote anything.
