# Shared finite-state prepared likelihood — development checkpoint

Issue DRM.jl#563 remains open. One ordinal or categorical predictor with a Gaussian
response is implemented through a common state-expanded prepared likelihood.
Direct Julia formula admission and R bridge transport for these routes remain
required next. All24 native missing-predictor obligations remain open; these two
prepared cases do not close entire capability axes.

## Current evidence

- `finite-native-003.json`: unchanged native defaults;180rows each,3states,
  all4response/predictor masks,3parameter points. Complete source/DLL/control hashes.
  Raw native ordinal order is beta,delta,cuts,alpha; transport explicitly permutes
  to beta,delta,alpha,cuts. Categorical alpha is level-major, then designterm.
- `finite-reference-003.toml`: validated numerical transport plus independent
  finite-sum likelihood/posterior/prediction values; no GPL implementation source.
- `finite-julia-002.toml`:48fixed-point checks against current source. Likelihood,
  gradient, allrow probabilities, ordinal score SD, categorical mode and full
  state-weighted predictions pass. This is not default fitting parity.
- `finite-fit-002.toml`: actual default prepared fits, raw covariance, actual
  imputed SDs and availability/status masks, predictions, native errors and losses.
  Both fits converged with observed-information covariance; numerical independent
  Hessian inversion checks pass (absolute max|HV-I|<=1e-4, predeclared).
- Native oracle18damage controls and fit oracle17damage controls pass normally and
  with Python assertions disabled. The fit oracle rejects arbitrary1000I covariance,
  changed SDs/masks and dishonest success flags. All raw failures are retained.
- The updated developer page executes its3examples (`finite-kernel-002` build).
  This is source-build evidence only, not rendered/full-site/deployment evidence.

## Strict native-default losses

The native comparator and4e-6 threshold are unchanged. Ordinal theta error2.163e-6
passes, but prediction7.561e-6 and imputation5.124e-6 fail. Categorical theta1.741e-5
and prediction9.576e-6 fail. Likelihood errors are below6.3e-9. These discrepancies
remain open; close likelihoods do not waive coefficient/output parity.
`check_finite_fit_receipt.py ... --require-parity` exits1 intentionally on this receipt.

## History and interpretation

Native001 incorrectly recorded a nonexistent control field;002 corrected controls
but stored a one-row gradient matrix.003 corrects both. Earlier JSONs are retained,
not current anchors. Julia001 fixed-point/fit receipts predate the final tiny-spacing
arithmetic repair or actual-SD retention;002 is the current source receipt.
Several stress-test expectations were corrected from independent state calculations;
logs preserve each failure. An initial sandbox attempt could not write Julia's
cache. An initial gate-wrapper attempt used the ledger directory instead of the
checkout; explicit --cwd corrected it. No tolerance or estimator was changed.

Rose approved the bounded prepared kernel and independently checked covariance/SD
receipts. The representable1e308 arithmetic repair was inspected; there is no
specific1e308 test assertion, so no such test coverage is claimed. Actual cutraw
-1000, logits±1000 and large spacing+10 are exercised.

No frontend/bridge parity, recovery, coverage, profile/bootstrap, warm-performance,
release or registration claim. The original full programme and its gates remain open.
