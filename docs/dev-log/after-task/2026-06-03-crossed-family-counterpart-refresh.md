# After-task: crossed-family counterpart refresh (#80)

## Scope

Refreshed the paired crossed-family benchmark against the isolated drmTMB source
worktree at `/private/tmp/drmtmb-nongaussian-phylo-counterpart`
(`codex/nongaussian-phylo-counterpart`).

This was a benchmark/provenance slice in DRM.jl:

- Added `DRMTMB_SOURCE` support to `bench/R/fit_crossed_family.R`, so the R-side
  benchmark can load a source checkout instead of accidentally using an older
  installed drmTMB.
- Added `DRMTMB_SOURCE_LABEL` provenance support to
  `bench/R/compare_crossed_family.R`.
- Regenerated `report/crossed-family-benchmark.md` from fresh R and Julia runs.

## Evidence

First, direct R probes against the isolated drmTMB worktree showed:

- Gamma crossed ordinary random intercepts: converged.
- Beta crossed ordinary random intercepts: converged.
- Plain binomial crossed ordinary random intercepts: still rejected because
  drmTMB does not yet expose a plain `binomial()` route.
- Gamma, beta, and beta-binomial `phylo(1 | species)` probes: converged on the
  R-side worktree.

Then the paired crossed-family benchmark was rerun:

```sh
DRMTMB_SOURCE=/private/tmp/drmtmb-nongaussian-phylo-counterpart \
  Rscript --vanilla bench/R/fit_crossed_family.R

julia --project=bench bench/fit_crossed_family.jl

DRMTMB_SOURCE=/private/tmp/drmtmb-nongaussian-phylo-counterpart \
DRMTMB_SOURCE_LABEL='local drmTMB worktree codex/nongaussian-phylo-counterpart' \
  Rscript --vanilla bench/R/compare_crossed_family.R
```

Updated paired-crossed results:

- Median R/Julia speedup across successful paired cells: 43.24x.
- Successful paired range: 17.87x to 161.78x.
- Medium Gamma: 4.2130 s in drmTMB vs 0.1372 s in DRM.jl, 30.71x.
- Medium beta: 18.9330 s in drmTMB vs 0.2649 s in DRM.jl, 71.48x.
- Fixed-q Gamma at n=20000: 11.2410 s in drmTMB vs 0.6291 s in DRM.jl, 17.87x.

Report gates:

- Every successful medium family cell Julia faster than drmTMB: PASS.
- Every successful medium family cell at least 2x faster: PASS.
- Coefficient and random-effect SD parity on successful paired cells: PASS.

## Guardrails

- This report is for crossed ordinary random intercepts, not a Julia-side
  non-Gaussian `phylo()` public route.
- The R-side drmTMB worktree now has Gamma, beta, and beta-binomial q=1 phylo
  probes, but DRM.jl still rejects structured markers for non-Gaussian families
  at the public formula layer. A true non-Gaussian phylo speed table needs a
  Julia sparse-Laplace phylo slice.
- Plain binomial remains an R-side unsupported counterpart route in the tested
  drmTMB branch, so those benchmark rows remain recorded as R failures rather
  than speed claims.
- Timings are measured from local JSON results and the rendered Markdown report,
  not extrapolated.
