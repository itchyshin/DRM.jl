# After-task: non-Gaussian phylo internal sparse-Laplace (#80)

## Scope

Added the first Julia-side non-Gaussian phylo engine slice. This is an internal
structured sparse-Laplace route, not public `phylo()` formula routing yet.

Implemented in `src/sparse_laplace_glmm.jl`:

- A reusable structured mean mode solver with known relatedness matrix `K`.
- Internal wrappers for:
  - `_fit_binomial_phylo_laplace`
  - `_fit_nb2_phylo_laplace`
  - `_fit_gamma_phylo_laplace`
  - `_fit_beta_phylo_laplace`
- Exact implicit-gradient corrections for fixed-mean and nuisance-family
  structured routes, reusing the crossed-family derivative kernels.

Not implemented in this slice:

- Public non-Gaussian `phylo()` formula dispatch.
- Beta-binomial phylo in Julia; that needs a beta-binomial derivative kernel.
- Plain-binomial drmTMB counterpart; drmTMB still rejects plain `binomial()`.

## Evidence

Focused Julia tests:

```sh
julia --project=. test/test_phylo_laplace_nongaussian.jl
```

Result: 5/5 passing. The test covers convergence for internal Binomial, NB2,
Gamma, and beta phylo wrappers, finite log-likelihoods/coefs, metadata, and a
central finite-difference gradient check for beta with max error below `1e-5`.

Adjacent regression tests:

```sh
julia --project=. test/test_crossed_laplace_generic.jl
julia --project=. test/test_crossed_selected_inverse.jl
julia --project=. test/test_poisson_crossed_laplace.jl
julia --project=. -e 'using Pkg; Pkg.test()'
git diff --check
```

Results:

- Generic crossed sparse-Laplace non-Gaussian kernels: 31/31 passing.
- Crossed sparse-Laplace nuisance exact gradient: 9/9 passing.
- Crossed selected inverse entries: 5/5 passing.
- Poisson crossed recovery/routing tests: 11/11 passing across the three
  reported testsets.
- Full `Pkg.test()` passed. Existing warnings remain: project/manifest resolve
  notice and the pre-existing `rtnb` overwrite warning from test helper names.
- `git diff --check` passed.

Paired phylo benchmark:

```sh
DRMTMB_SOURCE=/private/tmp/drmtmb-nongaussian-phylo-counterpart \
  Rscript --vanilla bench/R/gen_phylo_family.R

DRMTMB_SOURCE=/private/tmp/drmtmb-nongaussian-phylo-counterpart \
  Rscript --vanilla bench/R/fit_phylo_family.R

julia --project=bench bench/fit_phylo_family.jl

DRMTMB_SOURCE_LABEL='local drmTMB worktree codex/nongaussian-phylo-counterpart' \
  Rscript --vanilla bench/R/compare_phylo_family.R
```

Updated phylo report: `report/phylo-family-benchmark.md`.

Measured R/Julia speedup across successful paired non-Gaussian phylo cells:

- Median: 71.49x.
- Range: 18.46x to 139.59x.
- Medium NB2: 1.8880 s in drmTMB vs 0.0229 s in DRM.jl, 82.51x.
- Medium Gamma: 0.7350 s in drmTMB vs 0.0398 s in DRM.jl, 18.46x.
- Medium beta: 3.3960 s in drmTMB vs 0.0518 s in DRM.jl, 65.58x.

Report gates:

- Every successful medium phylo family cell Julia faster than drmTMB: PASS.
- Every successful medium phylo family cell at least 2x faster: PASS.
- Coefficient and phylo-SD parity on successful paired cells: PASS.
- No R failures recorded for NB2, Gamma, or beta.

## Guardrails

- The benchmark uses the internal Julia structured route directly. It should not
  be described as public non-Gaussian `phylo()` support until formula routing and
  user-facing tests/docs are added.
- Beta-binomial R-side phylo converges in the drmTMB worktree, but it is not in
  the Julia phylo speed table yet.
- Timings are local JSON-backed measurements, not extrapolations.
