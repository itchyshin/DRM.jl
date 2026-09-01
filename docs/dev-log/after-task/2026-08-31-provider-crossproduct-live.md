# Live R structured-provider cross-product

## 1. Goal

Close the three live numerical cells left open by the structured-provider
forwarding slice: R `engine = "julia"` profile and bootstrap inference for
animal A, Gaussian spatial coordinates after the existing R conversion to K,
and one admitted non-Gaussian K model. Global programme G0-G8 remain open.

## 2. Implemented

No likelihood or bridge source changed. Actual source-loaded R drivers now
exercise public Gaussian animal, Gaussian spatial and Poisson relmat fits,
fixed-effect profiles and B=2 bootstraps at one and four Julia threads. Each
public result is compared with direct Julia on the identical retained provider.
Immutable logs, drivers, binary thread-comparison results and a verifier are
retained in the evidence directory.

## 3a. Decisions and Rejected Alternatives

Poisson was selected instead of Gamma because Gamma's public scale
normalization remains a separate open contract. R spatial continues to use its
established coordinates-to-K conversion and relmat formula; this slice does not
claim raw-coordinate transport from R. B=2 is deliberately a plumbing smoke,
not coverage. Boundary-Hessian warnings were retained rather than suppressed or
removed by changing the fixture after seeing the result.

## 4. Files Touched

Evidence under
`docs/dev-log/evidence/julia-r-parity/provider-crossproduct-live-20260831/`,
this report, one check-log entry, the local unlazy ledger, and the continuation
checkpoint. No production source or standing test changed in either repository.

## 5. Checks Run

Fresh current-head baselines pass: Julia provider forwarding 19/19 and pure R
routing 48/48. Animal, converted spatial and Poisson pass public profile and B=2
bootstrap calls at Julia 1/4 with BLAS1. Each bootstrap records two successful
and zero failed refits. Public R point/profile/bootstrap results equal direct
same-engine Julia exactly. Poisson serial/threaded outputs also agree exactly.

## 6. Tests of the Tests

Replacing each retained covariance with identity changes the profile result:
maximum absolute changes are 0.00484 for animal, 0.04247 for converted spatial,
and 0.00983 for Poisson. The artifact verifier passes the final package and
rejects a scratch copy with one corrupted byte. The initial unprivileged
Poisson run is retained and fails before fitting because JuliaCall cannot write
its normal package-usage pid file.

Rose's final independent review and Melissa's bounded reconciliation both pass;
their receipts are included in the evidence manifest.

## 7a. Issue Ledger

Programme issue #563 remains open. This slice closes no release or global gate.

## 8. Consistency Audit

Animal retains the supplied A's exact numerical entries after the bridge's
canonical double/dimname conversion. Gaussian spatial retains the K computed by
drmTMB's existing precision conversion and exposes the corresponding relmat
formula. Poisson retains its supplied K. Direct comparisons use each
fitted object's rendered formula, data, provider and options. The evidence is
same-engine plumbing, not native-R parity.

## 9. What Did Not Go Smoothly

One delegated Poisson scout could not create its scratch driver under its tool
policy, so the coordinator ran that case. The first coordinator run was denied
access to `~/.julia/logs`; the exact permitted rerun passed. Every live cell
emitted at least one boundary/pseudo-inverse covariance warning. These warnings
do not invalidate the finite profile/bootstrap results, but prevent any
warning-free or Wald-accuracy claim.

## 10. Known Residuals

There is still no new native-R comparator, calibration/coverage campaign or
performance measurement in this slice. Gamma public-scale normalization,
missing predictors, full capability parity, original LSS obligations,
registered warm-workflow wins, documentation, recovery, cleanup, Mission
Control finalization and global G0-G8 remain open.

## 11. Team Learning

A live provider check needs a damage arm. Exact public/direct agreement alone
can be vacuous when a variance component lies at a boundary. Keeping the actual
provider sensitivity, warnings, threads and source provenance in one immutable
package makes the narrow claim reviewable.

## 12. Cross-Product Coverage

Live R fixed-effect profile plus B=2 bootstrap now cover Gaussian relmat,
animal, converted spatial and Poisson relmat. Direct Julia additionally has raw
coordinate coverage from the preceding slice. This slice does NOT cover
precision Q, non-Gaussian animal or spatial, broader families, random-effect
targets, native-R inference parity, REML, penalties, missing responses or
predictors, aggregation, interval calibration/coverage, or performance.

## 13. Next Action and Routing

Begin coherent Gamma public-scale normalization across coefficient mapping,
covariance construction, Jacobians, profiles and endpoint ordering. No remote
compute is needed for the first symbolic/unit slice; any campaign still follows
the 30-minute pre-run gate.
