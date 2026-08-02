# Phase 1.5 #5 Hopper finish-matrix — paired R ↔ Julia (2026-08-01)

**Lane:** Hopper / Shannon (twin inventory).  
**Bar (Q3):** admitted cells + result-shape for **Gaussian uni / bivariate / first phylo mean** + gate-ID rejections; stay **experimental**; no new families.  
**Rose fence:** drmTMB vignette may say Julia is deferred for CRAN readers; twin docs keep **experimental**. Do **not** claim CRAN/registry depends on JuliaCall.

Companion notes:
- Julia-only draft: `bridge-finish-matrix-julia-side-2026-08-01.md`
- drmTMB twin copy: `docs/dev-log/plans/bridge-finish-matrix-2026-08-01.md` (same basename)

---

## 1. Admitted cells (Hopper #5 trio)

| Cell | capability_id (R) | R evidence | Julia evidence (`drm_bridge`) | Status |
|---|---|---|---|---|
| Gaussian uni loc-scale (`sigma ~ x`) | `base_gaussian_location_scale` | Offline `new_drmTMB_julia` methods (`test-julia-bridge.R`); live Route C TMB↔Julia ≤1e-6 (`test-julia-tmb-parity.R`, skip w/o JuliaCall) | `test/test_bridge.jl` flatten ↔ native | **EVIDENCED** (experimental) |
| Gaussian bivariate residual `rho12` | `biv_gaussian_residual` | Offline result-shape (`test-julia-bridge.R`); live Route B logLik parity (`test-julia-tmb-parity.R`) | `test/test_bridge.jl` family/IC/fitted/residuals/sigma/corpairs | **EVIDENCED** (experimental) |
| First Gaussian phylo mean (`phylo(1\|species)`, `sigma ~ 1`) | `gaussian_phylo_mean` | Offline phylo result-shape + profile targets (`test-julia-bridge.R`); live Route A (`test-julia-tmb-parity.R`) | `test/test_bridge.jl` + `drm_bridge_inference` profile/bootstrap | **EVIDENCED** (experimental) |

R helper: `drmTMB:::drm_julia_phase15_admitted_cells()` returns exactly these three rows from `drm_julia_capability_comparison()`.

**Tip honesty (2026-08-01):** `base_gaussian_location_scale` and `gaussian_response_mask` use `r_bridge_status = experimental` (aligned with `claim_status = partial`); not a promotion beyond the experimental #5 bar.

**Not in #5 bar** (extra / gated): q4 phylo REML, count phylo, non-Gaussian phylo, structured `relmat`, cross-family, response masks beyond Gaussian, `engine_control`.

---

## 2. Result-shape checklist (Dict → `drmTMB_julia`)

| Field / method | Uni | Biv residual | Phylo-mean |
|---|---|---|---|
| `family` / model_type | R+J | R+J | R+J |
| `coef` / `coef_names` / `coefficients` | R+J | R+J | R+J |
| `vcov` | R+J | R+J | R+J (NaN RE rows OK via `isequal` on Julia) |
| `logLik` / AIC / BIC / `df` / `nobs` | R+J | R+J | R+J |
| `converged` / `is_converged` | R+J | R+J | R+J |
| `fitted` / `residuals` / `sigma` | R+J | R+J (split lists) | R+J |
| `rho12` / `corpairs` | empty / error | R+J | empty |
| Inference (`confint` profile/bootstrap on phylo SD) | — | q4 EXTRA | R+J uni `resd` |

---

## 3. Gate-ID rejections (drmTMB#544)

R registry: `drmTMB:::drm_julia_intentional_gates()` — 15 named `gate_id`s; CI in `test-julia-gate-vs-engine.R`; artifacts `julia-gates.tsv`.

| gate_id | Route | Matches Hopper #5? |
|---|---|---|
| `base_weights` … `base_nonphylo_count` (7) | base | Guards around admitted uni cell |
| `biv_invalid_partial_phylo`, `biv_rho12_phylo` | bivariate_phylo | Neighbours of residual biv / q4 |
| `structured_*` (3) | structured | Outside #5 |
| `xfam_*` (3) | cross_family | Outside #5 |

Julia-side formula rejections (`I`/`poly`/`scale`/`factor`/`^`, unsupported family) use clear `ArgumentError` strings mentioning `engine="julia"`; they are **not** numbered with R `gate_id`s (R owns pre-JuliaCall gates; Julia owns payload/formula honesty). That split is intentional.

---

## 4. bf() / marshalling

| Check | Where |
|---|---|
| R `bf()` → Julia formula strings (uni / biv / phylo strip `tree=`) | `test-julia-bridge.R` |
| Julia semicolon / keyed Dict / R `:`→`&` / reject calls | `test_bridge_formula_translation.jl` |
| Live `DRM_PARITY_TESTS=1` RCall round-trip | Optional CI; not required to close experimental #5 bar |

---

## 5. Close #5?

| Criterion | Met? |
|---|---|
| Admitted-cell matrix published + tested | **Yes** (this file + R capability rows + Julia tests) |
| Result-shape for uni / biv / first phylo mean | **Yes** (offline both sides; live parity skip-guarded) |
| Unsupported cells error with named gate IDs | **Yes** (R #544 registry + gate-vs-engine tests) |
| Stay experimental / no new families | **Yes** (claim_status `partial`; vignette deferred for CRAN) |
| Rose claim-vs-evidence on public README/registry | **Pending** maintainer Rose pass |
| Issue #5 checklist “round-trip bf()” as Workflow G always-on | **Partial** — marshalling tested; full RCall optional |

**Verdict:** Hopper bar is **evidenced enough to propose closing #5** after Rose accepts experimental wording on the PR pair. Do **not** flip vignette from deferred → “supported”, and do **not** make JuliaCall a CRAN Depends.

---

*Perspectives: Shannon + Hopper. Worktrees: DRM.jl `shannon/bridge-finish-matrix-phase15-5`; drmTMB `hopper/bridge-finish-phase15-5` off `origin/main`. No VA/REML-speed touch.*
