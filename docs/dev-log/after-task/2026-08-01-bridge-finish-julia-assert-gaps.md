# After-task: bridge finish-matrix Julia-only assert gaps (2026-08-01)

**Lane:** DRM.jl only (Shannon + Hopper inventory follow-up).  
**Branch:** `shannon/bridge-finish-matrix-phase15-5` from `origin/main`.  
**Refs:** `docs/dev-log/plans/bridge-finish-matrix-julia-side-2026-08-01.md`; contributes to Phase 1.5 #5 (does not close the whole roadmap issue).

## What changed

Minimal native↔bridge flatten assertions for the Hopper #5 admitted cells that were only partially checked:

1. **Gaussian bivariate** — `family`, `loglik`/`aic`/`bic`/`df`/`nobs`/`converged`, split `residuals`.
2. **Gaussian phylo-mean** — `family`, `vcov` via `isequal` (NaN RE block; `≈` alone is false-negative), IC fields, `residuals`, empty `corpairs`.
3. **Unsupported family string** — `ArgumentError` from `_bridge_family`.

Matrix §2 / §4 / §5 / §6 updated to mark those rows JULIA-EVIDENCED.

## Out of scope (unchanged)

- drmTMB / JuliaCall / Workflow G result-shape parity  
- Gate-ID numeric alignment with drmTMB#544  
- Registrator / version bump  
- JULIA-EXTRA cells (loc-scale phylo, q4 inference, …)

## Rose audit

- Claims stay Julia-Dict / native-`drm` parity only; no R-object equivalence claimed.  
- License boundary untouched (no drmTMB source).  
- Experimental bridge wording unchanged in Documenter.

## Verification

```
julia --project=. -e 'using Test; include("test/test_bridge.jl")'
# → Test Summary: drm_bridge primitive R boundary | 69 Pass
```
