# Phase 1.5 #5 Hopper finish-matrix — Julia side only (2026-08-01)

**Lane:** DRM.jl only (Shannon / Hopper inventory).  
**Workspace tip:** `.worktrees/ayumi-main-integrate` on `shannon/s3-scoped-hygiene`.  
**Not done here:** drmTMB `R/julia-bridge.R` inventory, JuliaCall round-trip, gate-ID parity vs drmTMB#544, merge of #340, any R execution.

**Hopper #5 bar (from `LOOP/GOAL.md` / ultra-plan Q3):** admitted cells + result-shape for **Gaussian uni / bivariate / first phylo mean** + gate-ID rejections; stay **experimental**; no new families.

This note inventories what DRM.jl **already evidences in-repo** via direct Julia tests of `drm_bridge` / `drm_bridge_inference`. Anything that needs the twin R surface is marked **BLOCKED-until-Codex-free**.

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
| Field-by-field ≡ native drmTMB `engine="julia"` object | **BLOCKED-until-Codex-free** | Needs drmTMB vignette / Workflow G |
| Numeric gate-ID on unsupported R formula ops | **BLOCKED-until-Codex-free** | Julia throws message strings (`test/test_bridge_formula_translation.jl`); drmTMB#544 gate registry not confirmed here |

### 2.2 Gaussian bivariate (no phylo)

| Cell | Julia status | Evidence |
|---|---|---|
| `family="biv_gaussian"`, keyed `mu1/mu2/sigma1/sigma2/rho12` | **JULIA-EVIDENCED** | `test/test_bridge.jl` — coef names, coef/vcov, fitted mu1/mu2, sigma1/sigma2, corpairs vs native |
| Result-shape residual correlation payload (`corpairs`) | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| ≡ drmTMB bivariate `engine="julia"` result shape | **BLOCKED-until-Codex-free** | Twin R surface |

### 2.3 First Gaussian phylo mean (`phylo(1|species)`, constant sigma)

| Cell | Julia status | Evidence |
|---|---|---|
| `mu = y ~ x + phylo(1\|species)`, `sigma ~ 1`, Newick/`PhyloTree` via `tree=` | **JULIA-EVIDENCED** | `test/test_bridge.jl` — coef/loglik/converged/fitted/sigma vs native |
| Tree string cache (`_bridge_tree`) | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| Semicolon / string formula with phylo (no crash) | **JULIA-EVIDENCED** | `test/test_bridge_formula_translation.jl` |
| `drm_bridge_inference` profile on phylo-mean residual SD (`param="resd"`) | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| `drm_bridge_inference` bootstrap on same cell | **JULIA-EVIDENCED** | `test/test_bridge.jl` |
| Sparse L-BFGS / location-only route honesty in Documenter | Doc-only | `docs/src/r-julia-bridge.md` (not a test assertion of R parity) |
| ≡ drmTMB first phylo-mean `engine="julia"` + vignette fields | **BLOCKED-until-Codex-free** | Twin R surface |

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
| `family` | ✓ | ✓ | (implicit via fit) |
| `coef_names` / `coefficients` | ✓ | ✓ | ✓ |
| `vcov` | ✓ | ✓ | (not asserted vs native in phylo block; uni/biv are) |
| `loglik` / `aic` / `bic` / `df` / `nobs` | ✓ | (loglik via coef path) | ✓ loglik |
| `converged` | ✓ | — | ✓ |
| `fitted` / `residuals` / `sigma` | ✓ | fitted + sigma split | ✓ |
| `corpairs` | empty ✓ | ✓ | — |
| Inference flatten (`method`,`param`,`lower`,`upper`,…) | — | q4 multi-row **EXTRA** | uni phylo `resd` ✓ |

**BLOCKED-until-Codex-free:** mapping these Dict keys onto drmTMB S3/`drm_fit` slots (`$fit`, `$sdr`, `confint` methods, vignette columns).

---

## 5. Rejection / gate-ID matrix

| Rejection | Julia evidenced? | drmTMB gate-ID match? |
|---|---|---|
| Missing univariate `mu` key | Yes — `test/test_bridge.jl` | **BLOCKED-until-Codex-free** |
| Unsupported family string | Code path in `_bridge_family` (no dedicated #5 test) | **BLOCKED-until-Codex-free** |
| R `I`/`poly`/`scale`/`factor`/`^` | Yes — `test/test_bridge_formula_translation.jl` | **BLOCKED-until-Codex-free** (messages cite `engine="julia"`; no `#GATE-…` IDs in DRM.jl) |
| REML + coupled loc-scale phylo | Yes — `ErrorException` in `test/test_bridge.jl` | **BLOCKED-until-Codex-free** |
| Wald on q4 among-axis | Yes — `test/test_bridge_bivariate_inference.jl` | **BLOCKED-until-Codex-free** |
| drmTMB#544 admitted/denied cell registry | Not inventoriable without reading drmTMB | **BLOCKED-until-Codex-free** |

---

## 6. What closes #5 vs what remains

### Already enough on the Julia side to *draft* the Hopper matrix

1. Gaussian uni loc-scale bridge flatten ↔ native (`test_bridge.jl`).
2. Gaussian bivariate residual-correlation bridge flatten ↔ native (`test_bridge.jl`).
3. First Gaussian phylo-mean bridge flatten ↔ native + profile/bootstrap inference row (`test_bridge.jl`).
4. Formula translation / clear rejections (`test_bridge_formula_translation.jl`).
5. Documenter experimental framing (`docs/src/r-julia-bridge.md`).

No new failing tests added in this slice (matrix-only; existing suite is the evidence).

### Still **BLOCKED-until-Codex-free** (drmTMB / Codex lane)

1. Inventory of `R/julia-bridge.R` admitted cells vs this matrix.
2. Result-shape parity against a real `drmTMB(..., engine="julia")` object (Workflow G / vignette fields).
3. Gate-ID string/number alignment with drmTMB#544.
4. `bf()` R↔Julia round-trip under RCall (`DRM_PARITY_TESTS=1`).
5. Rose claim-vs-evidence closeout that mentions the twin vignette / NEWS.
6. Any JuliaCall smoke (explicitly out of scope for this parallel slice).

---

## 7. Suggested next actions (when Codex frees drmTMB)

1. Codex: publish drmTMB-side admitted-cell + gate-ID table (mirror columns of §2–§5).
2. Hopper: join tables; mark mismatches only.
3. Shannon: tiny DRM.jl PR if gate-ID strings need to land in `_BRIDGE_REJECT_CALLS` (API-stable after S3).
4. Rose: experimental wording pass; close #5 only when both sides agree.

---

*Perspectives: Shannon (coord) + Hopper (bridge inventory). No subagents. No JuliaCall/R invoked. #340 not merged.*
