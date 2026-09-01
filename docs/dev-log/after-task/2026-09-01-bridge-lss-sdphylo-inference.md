# After-task: bridge phylogenetic LSS SD inference

## 1. Goal
Repair direct bridge inference for the admitted phylogenetic LSS SD block,
which was parsed and fitted but excluded from the default inference target set.

## 2. Implemented
The bridge now includes `:sd_phylo` when selecting a default SD profile or
bootstrap row, and recognizes it before the older phylo SD block names.

## 3a. Decisions and rejected alternatives
Do not substitute a fixed-effect row or turn failed profile endpoints into
finite intervals. The selected LSS SD target uses the existing profile and
bootstrap engines unchanged.

## 4. Files touched
`src/bridge.jl`, `test/test_lss_phylo.jl`, this receipt, and its check-log row.

## 5. Checks run
Before repair, the fixed direct bridge probe failed with `no SD row in the
result`. After repair, the combined Julia 1.12 focused LSS file passed 42/42.
The bridge profile returned `param = "sd_phylo"` and explicit endpoint failure;
the B=2 bootstrap returned the same target and reconciled used/failed counts.

## 6. Tests of the tests
The test uses the public bridge primitive with string formulas and primitive
data payloads, so it exercises formula translation, target selection, fitting,
profile status flattening, bootstrap transport, and row naming.

## 7a. Issue ledger
This advances engine = "julia" inference transport. It does not close profile
or bootstrap calibration, R-side JuliaCall dispatch, Ayumi's full issue set,
or any release. No collaborator message or remote compute action occurred.

## 8. Consistency audit
The estimator and interval semantics are unchanged. The bridge only admits an
already implemented `sd_phylo` target and preserves a failed endpoint status.

## 9. What did not go smoothly
The bridge branch initially lacked the numerical-boundary repair in PR #574,
causing the existing 64-tip regression to fail. It was rebased onto that
required branch before validation.

## 10. Known residuals
No native-R comparison, R-JuliaCall test, bootstrap coverage, profile recovery,
large-tree measurement, or automatic thread policy evidence was produced.

## 11. Team learning
Default target allowlists must include every admitted fitted block; otherwise a
parsed capability can silently disappear only at downstream inference time.

## 12. Cross-product coverage
This covers univariate Gaussian phylogenetic LSS SD inference through direct
Julia bridge primitives. It excludes R objects, q4, sigma-phylo, missing
predictors, REML calibration, performance, DRAC/Totoro, and reconciliation.
