# Bounded integration checks, programme #563

The approved programme remains active. These checks do not close G0–G8.

| Check | Executable binding | Required result |
|---|---|---|
| Merge/source identity | `git diff 4eb2af7f..567fec06 -- src`; `git diff 2cd1f2ce3..06518a5a -- R` | Empty numerical source diffs. |
| R focused integration | Retained `r-regression.R` with `testthat::test_dir` filter | All assertions pass; live skip explicitly counted. |
| Ordinary Rscript | `Rscript tools/run-julia-ayumi-batch.R JULIA_ROOT NEW_JSON` | PASS, exact source, 4 Julia threads / BLAS1, one selected profile and no opt-in. |
| Totoro integration | Retained `pilot.jl` / `pilot.sh` | All 14 files execute, source hashes match; every broken boundary check retained as unresolved. This is not an all-green parity gate. |
| Joint prediction label repair | `testthat::test_file("tests/testthat/test-julia-joint-prediction-labels.R")` | RED with old legacy rewrite; GREEN with class guard, mu/sigma and unseen-level checks. |
| Session routing | `Rscript tools/run-julia-integration-session.R JULIA_ROOT NEW_JSON` | Eight named outcomes PASS; ordinary fit unchanged after six joint fits; refusals, covariance axes, row metadata and independent newdata calculations retained. |

Frozen native 4e-6 losses, the two LSS boundary failures, large-tree profiles/bootstrap, all capability rows, whole-site checks and performance remain open. Estimates were declared before fits; receipts retain time limits. The Mac reused the existing DLL for package loading; no fresh native compilation or package check is claimed. Totoro is one-thread Linux validation, separately reported from Mac results. No DRAC compute was needed for this bounded check.
