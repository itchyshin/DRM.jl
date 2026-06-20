# After Task: Overnight DRM.jl Audit + Engine-Health Verification

**Date:** 2026-06-19 (overnight, autonomous; Ada orchestrating)
**Worktree:** `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`,
branch `shannon/overnight-audit-verify-20260619` off `f46035d`
(clean `origin/main`, PR #295 merged).
**Posture:** read-only audit + test verification only. No engine, family,
likelihood, or contract source changed. **Pushes held for maintainer review.**

This was the Julia side of a parallel R+Julia overnight run; the R side (drmTMB)
is tracked separately on `shannon/overnight-audit-gaps-20260619`.

## Goal

Orient on the DRM.jl finish plan, classify what is genuinely closable now vs
blocked, and bank engine-health evidence on the current clean `main`, without
crossing the direct-DRM.jl / Julia-via-R / native-R-TMB lane separation or the
MIT/GPL provenance boundary.

## What was done

A 4-mapper + synthesis audit (roadmap/handover, contract/capability, dev-log,
tests/CI) enumerated 78 items. DRM.jl is mature: univariate and bivariate
Gaussian, the q=4 phylogenetic among-axis PLSM headline (sparse augmented-state
Laplace + Takahashi selected inverse, the verified 2.18x-vs-drmTMB result),
Gaussian-only REML, missing-response FIML, and Wald/profile/bootstrap inference
are all implemented and exported; `v0.1.1` is tagged.

Engine-health was re-verified on `f46035d` with the focused-test invocation
`JULIA_LOAD_PATH="@:@v#.#:@stdlib:test" julia --project=. -e 'include("test/<f>.jl")'`:

- `test_aic_bic.jl`, `test_gaussian_core.jl`, `test_gaussian_bivariate.jl`,
  `test_inference.jl` — all pass, zero failures.
- `test_q4_laplace.jl` is a **guarded stub** here: it prints "Implementation
  file not loadable: test/fit_q4_julia.jl does not exist" and no-ops. The q=4
  engine itself lives in `src/fit_q4_sparse_tmb.jl` and is covered by the
  tagged `v0.1.1` evidence; the `test_q4_laplace.jl` fixture gap is a
  harness note for the maintainer, not an engine failure.
- `test_aqua.jl` could not run: `Aqua` is in `test/Project.toml` but not
  instantiated in this worktree (`Pkg.instantiate()` for the test env, which
  needs registry network access, is required first).

## Boundary-safe finish plan (for the maintainer / Grace)

Ordered, with the verification status of each:

1. **Issue #9 — Documenter CI broken** (`docs/Project.toml`,
   `Documenter = "1"` unpinned vs `DocumenterVitepress = "0.3"`, KeyError(:id)
   in ExampleBlocks). The fix is a compat pin of `Documenter` to the last
   version compatible with DocumenterVitepress 0.3.x. **Not applied tonight:**
   determining the exact last-good range and confirming the 36-page build needs
   either a local Documenter build (CairoMakie precompile) or a CI run, neither
   available unsupervised; an unverified version pin could make CI worse. This
   is the highest-value next slice once a build/CI check is available.
2. **Aqua hygiene gate** — `Pkg.instantiate()` the test env, then run
   `test_aqua.jl`; this gates the Julia General registry milestone. Needs
   registry network.
3. **Phase 3 documentation articles** (toward the 26-article navbar mirroring
   drmTMB). Blocked behind #9 because Documenter cannot build until the pin
   lands.

## Avoid / defer (in-flight or out-of-lane)

- **Issue #8 (logdet ridge on coalescent trees)** — engine-math correctness
  work, maintainer-owned, with a repro under `/tmp/issue8_*`. Left untouched.
  (The drmTMB side independently hit a parallel lesson tonight: a stable-logdet
  reformulation perturbed a weakly-identified spatial q4 fit and was reverted
  for supervised review — structured-covariance log-determinant changes need
  careful adjudication, not unsupervised edits.)
- **R-bridge slices** (`phase-15-r-bridge`, REML-bridge-relax, ayumi-integration)
  touch `R/julia-bridge.R` on the R side — Julia-via-R lane, owner-gated; not
  this lane.

## Boundaries respected

Direct-DRM.jl evidence kept in its own lane (no drmTMB native or Julia-via-R
claim). MIT provenance intact: no GPL-3 drmTMB/gllvmTMB code referenced or
copied. No release / registry / speed / recovery / coverage claim is made; this
is verification and planning only. Detect-don't-duplicate honored: `origin/main`
was re-fetched (still `f46035d`), and the maintainer-owned and sister-thread
items above were left alone.

## Next actions

Maintainer/Grace: apply and CI-verify the Issue #9 Documenter pin; then the
Aqua gate and Phase 3 articles can proceed. No DRM.jl source change is needed to
act on this note.
