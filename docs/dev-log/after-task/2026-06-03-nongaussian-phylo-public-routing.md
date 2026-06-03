# After-task: non-Gaussian phylo public formula routing (#80)

## Scope

Wired the verified internal non-Gaussian phylo sparse-Laplace kernels into the
public formula front end for:

- `NegBinomial2()` with `phylo(1 | group)` on `mu` and constant `sigma`.
- `Gamma()` with `phylo(1 | group)` on `mu` and constant `sigma`.
- `Beta()` with `phylo(1 | group)` on `mu` and constant `sigma`.
- `Binomial()` with `phylo(1 | group)` on `mu` for `cbind(successes, failures)`.

The public shape is:

```julia
drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
    Gamma(); data = dat, tree = phy)
```

For `Binomial()`:

```julia
drm(bf(@formula(cbind(successes, failures) ~ x + phylo(1 | species))),
    Binomial(); data = dat, tree = phy)
```

## Implementation Notes

- `_split_ranef()` now preserves the structured marker's inner lhs as
  `(:phylo, group, lhs)` instead of dropping it.
- Gaussian structured routing was updated to read the richer tuple and now
  rejects non-intercept structured terms explicitly.
- `_nongaussian_phylo_structure()` centralizes the non-Gaussian public-route
  contract:
  - only `phylo(1 | group)`;
  - no `meta_V`;
  - no ordinary random effects mixed with the structured route;
  - `tree = ...` required;
  - tree-derived correlation dimension must match the grouping levels.
- The family front ends route to:
  - `_fit_nb2_phylo_laplace`
  - `_fit_gamma_phylo_laplace`
  - `_fit_beta_phylo_laplace`
  - `_fit_binomial_phylo_laplace`

## Evidence

Focused test:

```sh
julia --project=. test/test_phylo_laplace_nongaussian.jl
```

Result:

- Internal sparse-Laplace phylo wrappers: 5/5 passing.
- Public formula routing: 7/7 passing.

Adjacent regression tests:

```sh
julia --project=. test/test_gaussian_structured.jl
julia --project=. test/test_nbinom2_re.jl
julia --project=. test/test_gamma_re.jl
julia --project=. test/test_beta_re.jl
julia --project=. test/test_binomial.jl
julia --project=. test/test_binomial_re.jl
julia --project=. test/test_crossed_laplace_generic.jl
julia --project=. test/test_crossed_selected_inverse.jl
julia --project=. test/test_nbinom2.jl
julia --project=. test/test_gamma.jl
julia --project=. test/test_beta.jl
```

Results:

- Gaussian structured route: 8/8 passing across relmat, animal, and phylo.
- NB2, Gamma, beta, and Binomial fixed/random-intercept tests passed.
- Generic crossed sparse-Laplace kernels: 31/31 passing.
- Crossed sparse-Laplace nuisance exact gradient: 9/9 passing.
- Crossed sparse-Laplace public routing smoke: 6/6 passing.
- Crossed selected inverse entries: 5/5 passing.

Full package gate:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
git diff --check
```

Result: `Pkg.test()` passed and `git diff --check` passed. Existing warnings
remain: the project/manifest resolve notice and the pre-existing `rtnb` helper
overwrite warning from the test suite.

## Report Update

`report/phylo-family-benchmark.md` still reports the measured counterpart speed
table for NB2, Gamma, and beta:

- Median paired phylo speedup: 71.49x.
- Medium NB2: 82.51x.
- Medium Gamma: 18.46x.
- Medium beta: 65.58x.

The report wording now separates those R-counterpart cells from the additional
Julia-only Binomial public phylo route.

Regenerated with:

```sh
DRMTMB_SOURCE_LABEL='local drmTMB worktree codex/nongaussian-phylo-counterpart' \
  Rscript --vanilla bench/R/compare_phylo_family.R
```

## Guardrails

- Beta-binomial phylo remains unclaimed in Julia; it needs a beta-binomial
  derivative kernel before public routing.
- Plain `Binomial()` phylo is public in DRM.jl but has no drmTMB counterpart in
  the current benchmark worktree, so it is not included in the R/Julia speedup
  table.
- `sigma ~ x` with non-Gaussian phylo remains outside this slice; the current
  nuisance-family phylo wrappers require constant `sigma`.
