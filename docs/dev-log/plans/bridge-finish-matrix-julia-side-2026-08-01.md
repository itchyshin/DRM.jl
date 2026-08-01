# Phase 1.5 #5 Hopper finish-matrix — Julia side only (2026-08-01)

**Lane:** DRM.jl only (Shannon / Hopper inventory).  
**Workspace tip:** `.worktrees/ayumi-main-integrate` on `shannon/s3-scoped-hygiene`.  
**Paired matrix (both sides):** `bridge-finish-matrix-2026-08-01.md` (2026-08-01 Hopper finish).  
**R inventory:** done on drmTMB worktree `hopper/bridge-finish-phase15-5` off `origin/main` (not the dirty `claude/handover-freshness-0718` checkout).

**Hopper #5 bar (from `LOOP/GOAL.md` / ultra-plan Q3):** admitted cells + result-shape for **Gaussian uni / bivariate / first phylo mean** + gate-ID rejections; stay **experimental**; no new families.

This note inventories what DRM.jl **already evidences in-repo** via direct Julia tests of `drm_bridge` / `drm_bridge_inference`. R-side mapping is in the paired matrix (no longer Codex-blocked).

---

## 1. DRM.jl bridge surface inventory

### Public exports (`src/DRM.jl`)

| Symbol | Role |
|---|---|
| `drm_bridge` | Marshalling-friendly fit entry for R `engine = "julia"` |
| `drm_bridge_inference` | Narrow profile/bootstrap primitive (univariate phylo SD; bivariate q4 among-axis SDs) |

### Implementation (`src/bridge.jl`)

| API / helper | Visibility | Notes |
|---|---|---|
| `drm_bridge(...)` | **exported** | Formula string / Dict / NamedTuple → `Dict{String,Any}` flatten |
| `drm_bridge_inference(...)` | **exported** | `method ∈ {"profile","bootstrap"}`; Wald rejected for q4 among-axis |
| `drm_bridge_q2_phylo(...)` | module-local (not exported) | Private q2 phylo point-export diagnostic |
| `drm_bridge_q2_known_precision(...)` | module-local (not exported) | Private q2 `Ainv`/`Q` precision diagnostic |
| `_bridge_flatten` keys | internal | `family`, `coef_names`, `coefficients`, `coef`, `vcov`, `vcov_names`, `loglik`, `aic`, `bic`, `df`, `nobs`, `converged`, `fitted`, `residuals`, `sigma`, `corpairs`, optional `q4_point_export` / `q2_point_export` |
| `_BRIDGE_REJECT_CALLS` | internal | Clear `ArgumentError` for R `I`/`poly`/`scale`/`factor`/`^`; messages mention `engine="julia"` but **no numeric drmTMB gate IDs** |
| `_bridge_family` | internal | Maps many family strings; **#5 admitted cells are Gaussian only** |

### Tests wired in `test/runtests.jl`

| File | Included |
|---|---|
| `test/test_bridge.jl` | yes (L175) |
| `test/test_bridge_q2_direct_export.jl` | yes (L176) |
| `test/test_bridge_q4_direct_export.jl` | yes (L177) |
| `test/test_bridge_formula_translation.jl` | yes (L189) |
| `test/test_bridge_bivariate_inference.jl` | yes (L192) |

### Docs mentioning `engine=julia` / `drm_bridge`

| Doc | What it claims (Julia-side wording) |
|---|---|
| `docs/src/r-julia-bridge.md` | Experimental first slice: Gaussian 1-/2-response + first `phylo(1\|species)` mean + narrow q2 fixtures; R glue lives in drmTMB |
| `AGENTS.md` / `CLAUDE.md` / `ROADMAP.md` | Phase 1.5 bridge contract; Hopper owns parity |
| After-tasks under `docs/dev-log/after-task/*bridge*` | Historical slice notes (entrypoint, tree cache, missing response, q2 precision, …) |

---

## 2. Admitted-cell matrix (Hopper #5 core)

Status legend:

- **JULIA-EVIDENCED** — exercised by an existing DRM.jl test file (native ↔ bridge or bridge-only shape).
- **JULIA-EXTRA** — beyond the minimal #5 trio but already tested on the Julia bridge; do not promote as #5 “shipped” without Rose.
- **BLOCKED-until-Codex-free** — needs drmTMB R inventory / JuliaCall / gate-ID confirmation (Codex lane).

### 2.1 Gaussian univariate (fixed-effects loc-scale)

| Cell | Julia status | Evidence |
|---|---|---|
| `family="gaussian"`, semicolon formula `"y ~ x; sigma ~ x"` | **JULIA-EVIDENCED** | `test/test_bridge.jl` — coef/vcov/loglik/aic/bic/df/nobs/converged/fitted/residuals/sigma vs native `drm` |
| Keyed Dict formula `:mu`/`:sigma` + Dict data | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| Missing keyed `mu` → `ArgumentError` | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| Result-shape field set matches `_bridge_flatten` | **JULIA-EVIDENCED** (Julia Dict keys) | `test/test_bridge.jl` asserts the core fields |
| Unsupported family string → `ArgumentError` | **JULIA-EVIDENCED** | `test/test_bridge.jl` — `family="not_a_real_family"` (2026-08-01 gap fill) |
| Field-by-field ≡ native drmTMB `engine="julia"` object | **R-EVIDENCED (offline)** | drmTMB `new_drmTMB_julia` methods + Route C live parity (skip-guarded); see paired matrix |
| Numeric gate-ID on unsupported R formula ops | **SPLIT (intentional)** | Julia: message strings; R pre-JuliaCall: named `gate_id`s in `drm_julia_intentional_gates()` (#544) |

### 2.2 Gaussian bivariate (no phylo)

| Cell | Julia status | Evidence |
|---|---|---|
| `family="biv_gaussian"`, keyed `mu1/mu2/sigma1/sigma2/rho12` | **JULIA-EVIDENCED** | `test/test_bridge.jl` — family, coef names, coef/vcov, loglik/aic/bic/df/nobs/converged, fitted/residuals mu1/mu2, sigma1/sigma2, corpairs vs native |
| Result-shape residual correlation payload (`corpairs`) | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| ≡ drmTMB bivariate `engine="julia"` result shape | **R-EVIDENCED (offline)** | `test-julia-bridge.R` Hopper #5 bivariate residual shape + Route B parity |

### 2.3 First Gaussian phylo mean (`phylo(1|species)`, constant sigma)

| Cell | Julia status | Evidence |
|---|---|---|
| `mu = y ~ x + phylo(1\|species)`, `sigma ~ 1`, Newick/`PhyloTree` via `tree=` | **JULIA-EVIDENCED** | `test/test_bridge.jl` — family, coef/vcov (`isequal`, NaN-safe), loglik/aic/bic/df/nobs/converged/fitted/residuals/sigma/empty corpairs vs native |
| Tree string cache (`_bridge_tree`) | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| Semicolon / string formula with phylo (no crash) | **JULIA-EVIDENCED** | `test/test_bridge_formula_translation.jl` |
| `drm_bridge_inference` profile on phylo-mean residual SD (`param="resd"`) | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| `drm_bridge_inference` bootstrap on same cell | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| Sparse L-BFGS / location-only route honesty in Documenter | Doc-only | `docs/src/r-julia-bridge.md` (not a test assertion of R parity) |
| ≡ drmTMB first phylo-mean `engine="julia"` + vignette fields | **R-EVIDENCED (offline)** | `test-julia-bridge.R` + Route A parity; vignette stays CRAN-deferred |

---

## 3. Extra Julia bridge cells (not required to close #5, already tested)

| Cell | Status | Evidence |
|---|---|---|
| Univariate loc-scale phylo (`sigma ~ phylo(...)`, `phylo_coupled=true`) | **JULIA-EXTRA** | `test/test_bridge.jl` — `recov_` coef names; REML rejected with `ErrorException` |
| R `:` → `&` interactions + phylo | **JULIA-EXTRA** (formula honesty) | `test/test_bridge_formula_translation.jl` |
| Reject `I`/`poly`/`scale`/`factor`/`^` (and nested under `*`) | **JULIA-EXTRA** (rejection honesty) | `test/test_bridge_formula_translation.jl` |
| R `- 1` drops intercept | **JULIA-EXTRA** | `test/test_bridge_formula_translation.jl` |
| Bivariate q4 phylo fit + REML flatten (`vcov` all-NaN) | **JULIA-EXTRA** | `test/test_bridge_bivariate_inference.jl` |
| Bivariate q4 among-axis SD bootstrap / profile multi-row inference | **JULIA-EXTRA** | `test/test_bridge_bivariate_inference.jl` |
| Wald rejected for q4 among-axis | **JULIA-EXTRA** | `test/test_bridge_bivariate_inference.jl` |
| q2 / q4 direct point-export schemas + claim boundaries | **JULIA-EXTRA** (point export, not #5 trio) | `test/test_bridge_q2_direct_export.jl`, `test/test_bridge_q4_direct_export.jl` |

**Rose fence:** do not describe JULIA-EXTRA cells as Phase 1.5 #5 “admitted shipped” without a separate decision. Keep Documenter “experimental” wording.

---

## 4. Result-shape checklist (Julia Dict → R reconstruction)

Julia-evidenced keys on the #5 core cells (`test/test_bridge.jl`):

| Key | Uni Gaussian | Biv Gaussian | Phylo-mean Gaussian |
|---|---|---|---|
| `family` | ✓ | ✓ | ✓ |
| `coef_names` / `coefficients` | ✓ | ✓ | ✓ |
| `vcov` | ✓ | ✓ | ✓ (`isequal`; NaN RE block) |
| `loglik` / `aic` / `bic` / `df` / `nobs` | ✓ | ✓ | ✓ |
| `converged` | ✓ | ✓ | ✓ |
| `fitted` / `residuals` / `sigma` | ✓ | fitted + residuals + sigma split | ✓ |
| `corpairs` | empty ✓ | ✓ | empty ✓ |
| Inference flatten (`method`,`param`,`lower`,`upper`,…) | — | q4 multi-row **EXTRA** | uni phylo `resd` ✓ |

**2026-08-01 gap fill (Julia-only, no drmTMB):** bivariate IC/`converged`/`residuals`/`family`, phylo-mean `vcov`+IC+`residuals`+`family`+empty `corpairs`, and unsupported-family `ArgumentError` — all in `test/test_bridge.jl`.

**R mapping:** `new_drmTMB_julia` reconstructs coef/vcov/logLik/fitted/residuals/sigma/rho12; see paired matrix §2. Public vignette columns stay deferred for CRAN.

---

## 5. Rejection / gate-ID matrix

| Rejection | Julia evidenced? | drmTMB gate-ID match? |
|---|---|---|
| Missing univariate `mu` key | Yes — `test/test_bridge.jl` | R payload path; not a #544 base gate |
| Unsupported family string | Yes — `test/test_bridge.jl` | R `base_unsupported_family` (pre-JuliaCall) |
| R `I`/`poly`/`scale`/`factor`/`^` | Yes — `test/test_bridge_formula_translation.jl` | Julia-side only (no R gate_id; intentional split) |
| REML + coupled loc-scale phylo | Yes — `ErrorException` in `test/test_bridge.jl` | R warns / ML fallback on unsupported REML cells |
| Wald on q4 among-axis | Yes — `test/test_bridge_bivariate_inference.jl` | R confint path rejects unsupported targets |
| drmTMB#544 admitted/denied cell registry | Inventoriable | **Yes** — 15 `gate_id`s + `drm_julia_phase15_admitted_cells()` |

---

## 6. What closes #5 vs what remains

### Already enough on the Julia side to *draft* the Hopper matrix

1. Gaussian uni loc-scale bridge flatten ↔ native (`test_bridge.jl`).
2. Gaussian bivariate residual-correlation bridge flatten ↔ native (`test_bridge.jl`).
3. First Gaussian phylo-mean bridge flatten ↔ native + profile/bootstrap inference row (`test_bridge.jl`).
4. Formula translation / clear rejections (`test_bridge_formula_translation.jl`).
5. Documenter experimental framing (`docs/src/r-julia-bridge.md`).

**Follow-up (2026-08-01):** remaining Julia-only gaps in §4 for the #5 trio were closed with minimal assertions in `test/test_bridge.jl` (no drmTMB / no Registrator). R-side / gate-ID / Workflow G items below stay blocked.

### Remaining (not Codex-blocked)

1. Rose claim-vs-evidence closeout on the PR pair (experimental / CRAN-deferred honesty).
2. Optional always-on `DRM_PARITY_TESTS=1` RCall bf round-trip in CI (marshalling already tested offline).
3. Maintainer decision to close DRM.jl #5 after Rose.

---

## 7. Suggested next actions

1. Merge drmTMB Hopper PR (capability rows + offline biv shape + matrix).
2. Merge DRM.jl PR (Julia assert gaps + paired matrix).
3. Rose: experimental wording pass; close #5 when both PRs land.

---

*Perspectives: Shannon (coord) + Hopper (bridge inventory). Paired with drmTMB `hopper/bridge-finish-phase15-5`.*
