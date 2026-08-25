# Route-C live-TMB parity, run for real — 2026-08-24

**Row:** `base_gaussian_location_scale` (`partial`). `claim_boundary`: *"Phase
1.5 Hopper admitted cell (Route C): offline result-shape + optional live TMB
parity; CRAN readers still use TMB — vignette keeps Julia deferred/
experimental."* This note addresses the **optional live TMB parity** half —
whether it actually passes when run, not just whether it exists.

## 1. The skip mechanism — exact location

The live Route-C round-trip is a `testthat` test in the **drmTMB R repository**
(GPL; not vendored here), not in DRM.jl:

- `drmTMB/tests/testthat/test-julia-tmb-parity.R:71-78` —
  `test_that("engine='julia' == engine='tmb' to <=1e-6 on Gaussian
  location-scale (Route C)", ...)`, gated by
  `skip_if_not_installed("JuliaCall")`, `skip_if_not_installed("callr")`,
  `skip_if_not_installed("pkgload")`, and
  `skip_if_not(dir.exists(drm_parity_jl_path()), "DRM.jl engine path not
  available")` (`drm_parity_jl_path()` reads `Sys.getenv("DRM_JL_PHYLO_PATH")`).
- `drmTMB/tests/testthat/test-julia-tmb-parity.R:18` — the whole file is also
  gated by `drm_skip_live_julia()`.
- `drmTMB/tests/testthat/helper-julia-bridge-path.R:42-58` —
  `drm_skip_live_julia()`'s body: skips (via `testthat::skip()`) whenever the
  session is non-interactive **and** neither `NOT_CRAN=true` nor
  `DRMTMB_JULIA_TESTS=true` is set, then calls `testthat::skip_on_cran()` for
  defense in depth. The comment at lines 33-37 records *why*: a live
  `JuliaCall::julia_setup()` hung for **~10448s** on Ligges R-release
  win-builder (2026-08-17) when this wasn't guarded.
- Inside the fit helper itself, `tryCatch(..., error = function(e)
  testthat::skip(...))` (lines 80-88) turns even a runtime error into a skip,
  not a failure — a second layer that can pass-by-not-running.

On the DRM.jl side, the **offline** half of the same row (fixture-backed
coefficient/SE/vcov comparison against committed drmTMB-generated numbers,
`test/parity/fixtures/gaussian-locscale/expected.toml`) is gated separately by
`test/runtests.jl:315`: `if get(ENV, "DRM_PARITY_TESTS", "0") == "1"` around
`include("parity/runparity.jl")` and `include("parity/runparity_bridge.jl")`,
falling back to `@info "R-parity suite skipped..."` (line 323) when unset.
That gate is a different mechanism (no live drmTMB call at test time — it
compares against a saved TOML) and is not the subject of this note.

## 2. Ran it for real

Environment: R 4.6.0, Julia 1.10.0, JuliaCall/callr/pkgload present.
Comparator build recorded via `Rscript tools/drmtmb_provenance.R --toml`
(script content read from `feat/drmtmb-catchup`, run from a scratch copy —
**not reinstalled**):

```
version    0.7.0
built      R 4.6.0; aarch64-apple-darwin23; 2026-08-15 01:49:56 UTC; unix
code_hash  8dc7c6cd77f8d5cf8bebc9adb29a5a53900d2d320de074bde43cba8fa4e1bb7e
```

This DRM.jl worktree would not precompile out of the box
(`ArgumentError: Package ForwardDiff ... is required but does not seem to be
installed`) — ran `Pkg.instantiate()` (declared deps only, no `src/` edit;
`git status` shows no diff, `Manifest.toml` was already up to date).

Opted in with `DRM_JL_PHYLO_PATH=<this worktree>` and `NOT_CRAN=true`, then:

```r
pkgload::load_all("<drmTMB checkout>", quiet = TRUE)
testthat::test_file(
  "<drmTMB checkout>/tests/testthat/test-julia-tmb-parity.R",
  package = "drmTMB",
  desc = "engine='julia' == engine='tmb' to <=1e-6 on Gaussian location-scale (Route C)"
)
```

**Result: 5/5 expectations passed, 0 skipped, 0 failed, 0 errors** (real time
48.5s). Re-ran the fit helper directly (same seed 42, n=120, `bf(y ~ x, sigma ~
x)`, `gaussian()`) to capture the actual numbers the test only bounds:

| quantity | TMB | Julia | measured |Δ| | threshold |
|---|---|---|---|---|
| converged | TRUE | TRUE | — | both must be TRUE |
| logLik | −132.5804156071 | −132.5804156008 | **6.257e-09** | < 1e-6 |
| `mu_(Intercept)` | 0.40372358 | 0.40371812 | 5.456e-06 | |
| `mu_x` | 0.53398679 | 0.53398739 | 6.010e-07 | |
| `sigma_(Intercept)` | −0.32360188 | −0.32360180 | 8.657e-08 | |
| `sigma_x` | 0.32038198 | 0.32038557 | 3.589e-06 | |
| max\|Δcoef\| | | | **5.456e-06** | < 1e-5 |

Both engines converge and agree to the asserted tolerances. This is
independent of, and consistent in order of magnitude with, the file's own
comment (*"measured |ΔlogLik|≈1.5e-10, max|Δcoef|≈1e-6"*) and with the
committed offline fixture (`test/parity/fixtures/gaussian-locscale/`) and the
SE-axis measurement (`docs/dev-log/evidence/parity-se.tsv`,
`se_gaussian_location_scale`, 1.499e-07 abs / 2.169e-06 rel) — three
independent evidence layers on the same row now agree.

## 3. Decision: made LOUD, not de-optionalised — and why that's the honest choice

**De-optionalising the drmTMB-side gate is not something this task can or
should do:**

1. **Ownership.** The gate lives in `drmTMB/tests/testthat/`, a separate GPL
   repository DRM.jl does not vendor and this task is not chartered to edit.
2. **It would be actively unsafe even with permission.** The guard exists
   *because* an unconditional live-Julia test previously hung CRAN
   win-builder for ~10448 seconds (documented in the helper's own comment).
   Removing the skip would reintroduce that failure mode on every CRAN/
   win-builder run of drmTMB, including runs having nothing to do with this
   row.
3. **The skip is not the drmTMB#1081 failure mode as-is.** `testthat` reports
   a guarded skip as **SKIPPED**, with a printed reason
   (`"Live Julia skipped on CRAN lane..."` / `"DRM.jl engine path not
   available"`), not as a silent PASS — a reader of the test log sees it did
   not run. What was actually missing was a **record that anyone had run it
   and it passed**, which is the drmTMB#1081 shape (a green run that says
   nothing about the bridge) applied to *evidence*, not to the test's own
   reporting.

**What this note does instead — makes the absence loud where DRM.jl actually
has standing to act:** this is now a dated, reproducible, git-tracked record
in DRM.jl's own evidence ledger, stating explicitly that the live Route-C
round trip (a) exists, (b) is opt-in for a documented and still-valid CRAN
safety reason, (c) was actually executed against this exact worktree and the
recorded drmTMB build, and (d) passed with the numbers above — rather than the
prior state, where `claim_boundary`'s "optional live TMB parity" clause had no
DRM.jl-side citation showing it had ever been run.

## 4. Can "optional live TMB parity" be struck from the row's `claim_boundary`?

**No, because X:** the live round trip is genuinely, permanently optional in
CI — the CRAN/win-builder hang it guards against is a real, previously
observed failure mode, not a hypothetical one, and DRM.jl cannot change that
gate (out of repo, GPL boundary). "Optional" remains an accurate description
of *how the test runs*. What changes is that the clause is no longer an
unverified assumption: it is now backed by a dated, reproducible manual run
with measured agreement (this file), on top of the two other independent
evidence layers already on this row (offline fixture `expected.toml` and
`parity-se.tsv`). The row's `partial` status and `claim_boundary` wording are
unchanged — per the task, this is evidence, not a promotion.
