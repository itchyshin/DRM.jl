# Six UNCITED random-effect capabilities, measured

**Run date** 2026-09-05.
**DRM.jl** `345892520` (this branch's merge base, `origin/main`).
**drmTMB** `2fcbb0fbf` (`origin/main`) loaded with `pkgload::load_all()`; the
build fingerprint stamped into every row is
`drmtmb_code_hash = 3bbe615e88e512a8dc62b120a146f5e916258a986bad61e96e8087ebf3756f64`.
**Harness** `tools/parity_ranef.R`, appended into
`docs/dev-log/evidence/parity-classc.tsv`.

## Why

drmTMB's parity scoreboard reported 23 of 45 capabilities UNCITED on its bridge
axis — no receipt and no cited refusal. Six of those 23 were random-effect
capabilities. Ordinary-random-effect parity had in fact been measured before,
but into `docs/dev-log/evidence/julia-r-parity/ordinary-re-census/`, a table no
generator joins. Evidence that exists and lifts nothing is still uncited. These
rows land in a table that IS joined by `capability_id`.

## What was measured

Every cell is the same target fitted twice through `drmTMB()`,
`engine = "tmb"` against `engine = "julia"`. Ordinary cells use the census
fixture (n = 150, 15 groups x 10, seed 20260904); the phylogenetic cell uses
64 tips x 3 observations, seed 404, generating SD 0.7 (clear of DRM.jl's
`_LAPLACE_LOG_SD_FLOOR`).

| capability_id | cell | status | max abs coef diff | logLik diff | SE (max rel) |
|---|---|---|---:|---:|---:|
| `gaussian_random_intercept_mu` | ML | PARITY_PASS | 1.318e-11 | 1.506e-12 | SE_PASS 3.333e-07 |
| `gaussian_random_intercept_mu` | REML | PARITY_PASS | 8.295e-11 | 7.674e-13 | SE_PASS 3.333e-07 |
| `gaussian_random_slope_mu` | ML | PARITY_PASS | 8.457e-12 | 1.421e-13 | SE_PASS 3.290e-07 |
| `gaussian_sigma_random_intercept` | ML | **PARITY_FAIL** | 4.743e-04 | 1.009e-01 | SE_FAIL 1.762e-02 |
| `gaussian_phylo_mean` | ML | PARITY_PASS | 6.216e-09 | 1.001e-09 | **SE_FAIL 3.491e-03** |
| `tweedie_random_intercept_mu` | fence | REFUSED_BY_DRMTMB | — | — | — |
| `gaussian_phylo_slope_two_sd_mu` | fence | REFUSED_BY_DRMTMB | — | — | — |

The random-effect SD agrees to the printed digits wherever both engines report
one: 0.600437 / 0.62399 (intercept, ML and REML), 0.40507 (phylogenetic). For
the correlated `(1 + x | g)` block the Julia side leaves `sdpars` empty and
returns the block as raw log-Cholesky coefficients — a REPORTING gap, recorded
as `julia=NA` rather than filled in.

## The three findings that are not "it passes"

**1. `gaussian_sigma_random_intercept` does not reach parity, and should not.**
drmTMB integrates the sigma-side random intercept by Laplace, DRM.jl by 32-node
Gauss–Hermite quadrature (`src/gaussian_ranef.jl`). Both converge. The gap is
the approximation on the same model, not a wrong answer. This cell doubles as
the table's negative control: it is proof the harness can report a failure.

**2. `gaussian_phylo_mean` passes on coefficients and logLik but NOT on SEs.**
Coefficients agree to 6.2e-09 and logLik to 1.0e-09, but the fixed-effect Wald
SEs agree only to 3.491e-03 relative — over the 1e-3 bar `tools/parity_se.R`
argues from. DRM.jl says why, in warnings emitted during the fit: *"sparse-Laplace
vcov: finite-difference Hessian is not positive definite at the optimum; reported
SEs are not trustworthy"* and *"Hessian is numerically singular at the optimum —
using a pseudo-inverse"* (`src/vcov_guard.jl`, `rcond = 2.78e-08`, flagged
coordinate 2, the phylo-mean variance block). The point estimates are a receipt;
the SEs on this route are not.

**3. Two routes are refused by drmTMB before Julia starts, and one of those
refusals now misattributes the limit.** Both refusals carry a POSITIVE CONTROL
in the same cell — a neighbouring call the fence must not catch — and both
controls fitted:

- `tweedie_random_intercept_mu` — refused by drmTMB's fe-only fence
  (`drm_julia_refuse_fe_only_random_effects()`): *"admits "tweedie" only on the
  `fe` (fixed-effect) route of the Julia family registry"*. Control: the same
  `tweedie()` call with no random-effect bar — **fitted**. So the refusal is the
  fence, not a broken environment or a DRM.jl limit.
- `gaussian_phylo_slope_two_sd_mu` — refused by drmTMB's marker-slope guard
  (`drm_julia_refuse_marker_slope_unsupported()`), whose message says *"the
  pinned DRM.jl engine refuses this construct rather than fitting it"*. **At this
  sha that sentence is false.** `1a041d089` (merged in #644) implements the
  Gaussian two-SD phylogenetic random slope, and `test/test_phylo_slope_two_sd.jl`
  was re-run in this session at `345892520`: **51 of 51 assertions pass, 21.5 s**,
  including the same-target drmTMB oracle. `_bridge_render_formula_block`
  (`src/bridge.jl`) was widened by the same commit. The fence is drmTMB's own and
  it is stale; the correction belongs on the drmTMB side and is made there.
  Control: the same call with an intercept-only `phylo()` marker — **fitted**.

## Boundaries this run does NOT lift

One draw per shape, one seed. Result-shape and point/SE parity only — **not
interval coverage**, and no `interval_status` fence moves. The two refused
routes are recorded as cited negative controls, not as passes.
