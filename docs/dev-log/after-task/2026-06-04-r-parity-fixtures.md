# After-task: R-parity canonical fixtures

## Scope

Completed issue #177 as the local R + Julia hand-off for the #17 R-parity gate.

Implemented:

- Added `test/parity/gen_fixtures.R`, a maintainer-only R generator that writes
  generated numeric outputs only: `data.csv`, `expected.toml`, and
  `expected.meta.toml`.
- Generated six canonical fixtures from a temporary install of the local
  `drmTMB` `v0.1.3` tag:
  `gaussian-locscale`, `gaussian-bivariate-rho12`, `meta-analysis-V`,
  `robust-student`, `count-nbinom2`, and `proportion-beta`.
- Extended `test/parity/runparity.jl` to handle generic univariate formula
  bundles, bivariate keyword-form bundles, `meta_V(v)`, and family mapping for
  `Student()`, `NegBinomial2()`, and `Beta()`.
- Extended `compare_fit()` to check `n` / `df` metadata and to use a small
  absolute tolerance for near-zero `vcov` entries.
- Updated `test/parity/README.md` and `test/parity/GENERATING.md` from scaffold
  wording to the active fixture workflow.

## Scale Notes

Two R-side coefficients are transformed before writing `expected.toml`, so the
fixtures compare against DRM.jl's documented public coefficient scale:

- NB2: drmTMB `log(sigma)` -> DRM.jl `log(theta) = -2 log(sigma)`.
- Student: drmTMB `log(nu - 2)` -> DRM.jl `log(nu)`.

The corresponding covariance rows and columns are transformed by the same
Jacobians. The original R call and `drmTMB` version are recorded in each
`expected.meta.toml`.

## Evidence

Focused generator and direct parity gate:

```sh
Rscript --vanilla test/parity/gen_fixtures.R
DRM_PARITY_TESTS=1 julia --project=. test/parity/runparity.jl
```

Result:

```text
Generated drmTMB parity fixtures under test/parity/fixtures/
count-nbinom2: pass
gaussian-bivariate-rho12: pass
gaussian-locscale: pass
meta-analysis-V: pass
proportion-beta: pass
robust-student: pass
```

Full gated acceptance:

```sh
DRM_PARITY_TESTS=1 julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `DRM tests passed`; final parity block `R-parity vs drmTMB v0.1.3` was
6 passed / 6 total.

Default gate-off check:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `DRM tests passed`; final message confirmed
`R-parity suite skipped (set DRM_PARITY_TESTS=1 to run)`.

Observed warnings were pre-existing / unrelated: the manifest resolve notice,
the `sparse_aug_plsm.jl` load-time print, and the `rtnb` helper overwrite
warning in tests.

## Rose Audit

- GPL boundary intact: no drmTMB `.R`, `.cpp`, `.hpp`, or generated source was
  copied into DRM.jl.
- Fixtures are generated data and numeric results only, with provenance sidecars.
- The temporary `drmTMB v0.1.3` install lived outside the repo under `/tmp`.
- No public parity claim is made beyond the six committed canonical fixtures.
