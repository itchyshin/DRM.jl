# Bounded finite-state frontend evidence

`finite-public-003.json` is the current source-stamped public R-to-Julia receipt.
It retains raw/public covariance, separate coefficient blocks and names, actual
imputation/SD/status fields, posterior probabilities, cutpoints, and actual new-data
predictions. Both adapter verdicts pass; both native default-fit verdicts fail the
unchanged 4e-6 tolerance. Runtime includes startup and is not warm performance.

001/002 are historical receipts; 003 adds independent replay fields. No receipt
is a replacement for the frozen native comparator `../finite-state/finite-native-003.json`.
The checker replays the finite sums independently and checks inverse curvature,
public covariance axes and every retained conditional output. Its 17 corruption
controls must reject normally and with Python `-O`.

R fit objects remain in the R repository only. No R implementation source is
included in the MIT Julia repository. Source and test failures are retained in
the accompanying logs. Documentation checks execute two source pages; they do
not establish visual or deployed-site completeness.

Direct Julia still uses raw coefficient/covariance coordinates including ordinal
cuts; R public accessors omit predictor cuts. Full accessor parity and the
no-intercept additional-factor case remain required. All programme gates remain open.

Provenance describes the tested working trees, including the preserved foreign R bridge edits. It is not a clean committed-head full-suite qualification; integration must refresh that evidence after all owned changes are reconciled.
