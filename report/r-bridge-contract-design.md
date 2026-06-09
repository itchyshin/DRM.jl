# Design: DRM.jl-side R-bridge contract (`engine = "julia"`) — #5

**Status:** first implementation slice. DRM.jl now exposes `drm_bridge()` as the
stable Julia surface that R-side glue calls. The companion
`drmTMB(..., engine = "julia")` JuliaCall glue lives in the **drmTMB R repo**.
The first tested R-facing slice is Gaussian one-response and two-response; the
broader parity gate **#17 is already wired** (`test/parity/`,
`DRM_PARITY_TESTS=1`) and remains the acceptance path before non-Gaussian
families are admitted through the R bridge. Phase 1.5; part of the v0.1.0
"R-bridge functional" gate (#8).

## Goal

Let an R user keep writing ordinary `drmTMB(...)` and transparently fit on the
faster DRM.jl engine, getting back a drmTMB-shaped result. The win is exactly the
mission (HANDOVER): the simulation studies bottlenecked by R/TMB (coverage grids,
bootstrap, power) become cheap **without leaving R**.

## What already exists

| Piece | Where | State |
|---|---|---|
| Bridge intent + DRM.jl-side contract sketch | `docs/src/r-julia-bridge.md` | the two-way design (hand-translate vs `engine="julia"`) and the accessor list R expects |
| Hand-translation phrasebook | `docs/src/rosetta.md` | the R→Julia spelling map (the bridge automates this) |
| **Numerical parity harness** | `test/parity/` (#17, **done**) | static drmTMB v0.1.3 fixtures (`data.csv` + `expected.toml`), `compare.jl` contract (coef `rtol 1e-4`, vcov `rtol 1e-3`, loglik/aic `atol 1e-4`), `DRM_PARITY_TESTS=1`; **no RCall at runtime**. Already documents the coefficient-scale transforms (NB2 `log θ = −2 log σ`, Student `log ν` vs `log(ν−2)`) |
| Result accessors | `src/*.jl` | `coef, vcov, stderror, loglik, aic, bic, confint, coeftable, fitted, residuals, predict, simulate, ranef, vc, dof, deviance, nobs, is_converged` — all present |
| Newick input | `augmented_phy` (`sparse_phy.jl`) | a Newick string already crosses as text and parses (see #19) |

So the bridge is **not** a from-scratch build: the result accessors, the
coefficient-scale map, and the parity gate already exist. The first
marshalling-friendly entry point plus flattening contract now exists in
`src/bridge.jl`; coefficient-scale transforms and the parity-harness round-trip
mode remain follow-up work.

## Scope split (important)

- **In scope here (DRM.jl / this repo):** the Julia entry point, the
  marshalling/flattening contract, the coefficient-scale exposure, and the
  parity-harness round-trip acceptance.
- **Companion scope (drmTMB R repo):** the JuliaCall setup, the R
  `engine="julia"` dispatch, and reconstructing a lightweight `drmTMB_julia`
  object from the flat list. The first Gaussian-only companion slice was
  implemented in the sibling drmTMB worktree.

## The DRM.jl-side contract

### 1. One marshalling entry point
A single function that takes already-marshalled primitives (strings, column
tables, plain matrices — the types JuliaCall passes cleanly) and returns a
**flat, R-reconstructable result** (a `Dict`/`NamedTuple` of primitives, no
custom Julia structs crossing the boundary):

```julia
drm_bridge(; formula::Dict{Symbol,String},   # {:mu1=>"y1 ~ x", :sigma1=>"~x", …}
             family::String,                  # "gaussian", "nbinom2", …
             data,                            # column table (Dict/NamedTuple of vectors)
             tree::Union{Nothing,String}=nothing,   # Newick text (→ augmented_phy)
             K=nothing, Ainv=nothing,         # plain Float64 matrices + a names vector
             options::Dict=Dict()) -> Dict{String,Any}
```

Rationale: keep the boundary to primitives so JuliaCall marshalling is trivial
and version-robust; do all DRM.jl-specific construction (`bf`, `drm_formula`,
family dispatch) **inside** Julia from the strings.

### 2. Formula marshalling
R-side passes each parameter formula as **text** keyed by parameter name; the
Julia side parses with the existing `@formula`/`drm_formula`/`bf` machinery. The
spelling map is exactly the Rosetta table (`meta_known_V`→`meta_V`, etc.). The
round-trip equivalence ("R formula and its Julia translation describe the same
model") is enforced by the parity tests (§Acceptance).

### 3. Data marshalling
R `data.frame` → column table keyed by the same names (JuliaCall hands columns as
vectors). No new code — `drm(...; data=...)` already accepts a column table.

### 4. Structured inputs (ties to #19)
- **tree** — Newick string → `augmented_phy` (already works). Needs the
  **tip-name↔row alignment** noted in #19 (the `species` map).
- **K / Ainv** — cross as a plain `Float64` matrix **plus a names vector** for
  row/col alignment to the grouping factor. The alignment convention is the
  genuinely-open R-marshalling question shared with #19.

### 5. Result flattening (`DrmFit` → flat list)
The contract R reconstructs from. Field map (all from existing accessors):

| R expects | DRM.jl source |
|---|---|
| `coefficients` (named vector) | `coef(fit)` + `coeftable` names |
| `vcov` (matrix + dimnames) | `vcov(fit)` + the block/coef-name order |
| `logLik`, `df`, `nobs` | `loglik`, `dof`, `nobs` |
| `aic`, `bic` | `aic`, `bic` |
| `fitted`, `residuals` | `fitted`, `residuals(fit; type=…)` |
| `confint` | `confint(fit; level, method)` |
| `ranef` / `vc` | `ranef`, `vc` (+ `Σ_a`/coevolution once #186/#188 land) |
| `converged` | `is_converged` |
| (predict on newdata) | a second small entry point `drm_bridge_predict(handle, newdata; …)` |

Two options for `predict` on new data: (a) return enough to refit-free predict
R-side, or (b) keep the fitted object alive in the Julia session and expose a
`predict` entry point keyed by a handle. **(b) recommended** — JuliaCall holds
the Julia object; avoids re-marshalling the whole fit.

### 6. Coefficient-scale exposure (parity-critical)
drmTMB and DRM.jl use different working scales for some families (the parity
README documents NB2 `log θ = −2 log σ`, Student `log ν` vs `log(ν−2)`). The
bridge must return coefficients on the scale the R wrapper expects **and** name
them consistently, reusing the **same transforms + Jacobians** the parity harness
already applies. Expose this as a documented `scale = :drmtmb | :drm` option so
the R side gets drmTMB-scale numbers by default.

## Acceptance — reuse the #17 harness

The bridge is "functional" when, for each existing parity fixture, the result
obtained **through `drm_bridge`** matches `expected.toml` under the *same*
`compare.jl` tolerances as the native DRM.jl fit:

1. **Round-trip parity cell:** add a harness mode that fits each
   `test/parity/fixtures/*/` case via `drm_bridge` (string formula + column-table
   data) and runs the existing `compare.jl` contract. No new fixtures needed.
2. **Formula round-trip:** assert the string-marshalled formula builds the *same*
   model object as the hand-written `bf(...)` (compare `drm_formula` text / model
   matrices) across the canonical cases.
3. **Flattening round-trip (Julia-side):** `DrmFit` → flat `Dict` → assert every
   contracted field is present, finite, and on the documented scale.
4. *(R-side, drmTMB repo, deferred):* JuliaCall smoke test that an R
   `drmTMB(..., engine="julia")` call returns a native-shaped object — lives in
   that repo, behind its own gate.

## Dependencies & sequencing

- **#19** — tip-name alignment + K/Ainv name-marshalling convention (shared).
- **#17** — done; this design consumes it (no change beyond a round-trip mode).
- **Family coverage** — bridge parity is only as wide as the committed fixtures
  (currently gaussian-locscale, bivariate-rho12, meta-analysis-V, proportion-beta,
  robust-student, …); widening fixtures (deferred part of #17) widens bridge
  assurance.
- **R-side glue** — separate deliverable in the drmTMB repo (out of scope here).

## Test plan (local Julia)

1. `drm_bridge` builds + fits each canonical fixture from strings; results pass
   `compare.jl` at native tolerances (the core gate).
2. Flattening contract: all fields present/finite/correctly-scaled; names match.
3. Scale option: `:drmtmb` vs `:drm` coefficients differ by exactly the
   documented transform; vcov by the matching Jacobian.
4. Handle-based `predict` returns the same numbers as in-Julia `predict`.

## Implementation checklist

- [x] `drm_bridge(; formula, family, data, tree, K, Ainv, options)` entry point (primitives in, flat `Dict` out; current implementation uses `A` rather than `Ainv` until the alignment convention lands).
- [x] String→`bf`/`drm_formula` builder reusing the Rosetta map; family-name dispatch table.
- [x] `DrmFit` → flat `Dict` flattener with the §5 field map + name order.
- [ ] Coefficient-scale exposure (`scale=:drmtmb` default) reusing the parity transforms/Jacobians.
- [ ] Handle-based `drm_bridge_predict`.
- [ ] Parity-harness **round-trip mode** (fits fixtures via `drm_bridge`); formula + flattening round-trip tests.
- [ ] K/Ainv name-marshalling + tip alignment (with #19).
- [x] Docstrings; promote `docs/src/r-julia-bridge.md` from "planned" to "DRM.jl-side shipped; R glue in drmTMB repo".

## Open question for the maintainer

The next maintainer decision is whether the R bridge should return DRM.jl-native
coefficient scales for non-Gaussian families or transform them back to drmTMB
public scales by default. The current R-side companion guard keeps
`engine = "julia"` Gaussian-only until that policy is tested.
