# Finite prediction and transformed uncertainty follow-up

## 1. Goal
Continue approved Julia–R parity programme #563. Complete a bounded direct finite
new-data prediction contract and repair native/bridge uncertainty coordinates.
Record Ayumi-san's report separately. Whole-programme G0–G8 remain OPEN.

## 2. Implemented
Direct finite formula fits retain applied mean/sigma schemas, native state order
and ordinal contrasts. Known-state predictions preserve training coding across
singleton/subset batches. Sigma needs only its own design columns. Standard errors
use valid positive-definite observed-information covariance; invalid covariance,
overflow and unknown/missing states are refused. Legacy constructors stay usable
but cannot predict without a retained schema. R commit6ca8f9377 repairs both axes
of transformed covariance, exact log/logit target metadata and log-Wald SD bounds.

## 3a. Decisions and Rejected Alternatives
No estimator, likelihood, optimizer, tolerance or frozen comparator changed.
Reject tiny negative covariance without a unit-scale tolerance floor; accept tiny
positive covariance. Never recompute factor coding on new data. Native joint
bootstrap now refuses response-only simulation/refits that omit the predictor
model; a complete joint bootstrap remains required, not closed by this guard.

## 4. Files Touched
src/joint_missing_frontend.jl, new prediction test and scoped test-runner include,
reference/engine-internals.md, independent joint bridge receipt checkers, evidence,
original-obligations, check-log and this report. Only the prediction runner include
belongs to this slice; the foreign sparse-storage include/test are preserved.
R bridge ZOB changes are untouched. Denied Gaussian sparse files were not retried.

## 5. Checks Run
Final focused run:51prediction+86frontend+109factor=246 assertions pass.
Unlazy re-executes both checks from the explicit repo directory:3/3leaf gates met.
Native R repair has442 assertions (194new+101regression+47adapter+100ordinary
inference neighbours),9.432seconds including startup. Live Gaussian/Bernoulli
bridge006 and direct reference pass the independent adapter oracle. Ordinal/
categorical public006 also pass their adapter oracle. Strict native4e-6 comparisons
remain FAIL for all four registered workflows. One documentation page executes
five examples in20.890seconds; this is not visual/deployed whole-site proof.

## 6. Tests of the Tests
Retained method-missing RED, covariance/status/nonfinite/overflow review REDs and
tiny-negative-covariance RED precede repairs. Independent joint receipt checker
rejects21corruptions normally and underPython-O, including old delta-Wald endpoints.
Finite receipt checker rejects17corruptions in both modes. Source hashes and
before/after manifests are retained. No damaged fixture was used as claim evidence.

## 7a. Issue Ledger
DRM.jl#563 remains OPEN. All24original native obligations, complete valid-case
manifest, worktree/stash recovery, LSS stampedSE/REML/masks/large-tree/final-head,
profile/bootstrap, every registered warm workflow win and full documentation remain
required. Ayumi's inference model is not yet supplied. A three-tip star polytomy
passes native R validation but fails the bridge serializer and Julia constructor;
that restriction is reproduced, not fixed.

## 8. Consistency Audit
Rose independently approved final source SHA34e715491f4b967ed119a22bd2abce5a76095d69ebfaeca99910d0585fcd4964
and testSHA478fba446c10bb8c2d1ec52f080174c3c2be950a16bf72615f02b5fe6b1a6bf9.
Melissa reconciled against original promises: known-state prediction is not missing
state integration; covariance/interval repair is not coverage; native refusals do
not finish bootstrap. Golden Set: retained native factor designs, existing finite
frontend, prediction edge cases, independent public adapters and ordinary R
inference neighbours. Public raw ordinal cutpoints still differ from R accessors.

## 9. What Did Not Go Smoothly
First prediction test fixture used inconsistent ordinal/category levels. Initial
implementation accepted invalid/tiny-negative covariance and was repaired following
review. Sandbox Julia metadata-cache failures happened before fitting. First
Unlazy call used the ledger directory and could not load DRM; corrected explicit
cwd passes. Every failure log is retained and classified rather than discarded.

## 10. Known Residuals
Gaussian native training mean discrepancy5.307e-6; Bernoulli theta1.002e-5;
ordinal prediction7.561e-6/imputation5.124e-6; categorical theta1.741e-5 and
prediction9.576e-6 exceed frozen4e-6. No threshold waiver. Full finite accessor
parity, typed ordered covariates, broader prediction/refusal contract, Julia joint
profile, complete joint simulation/bootstrap and interval coverage remain open.
Ayumi's general Julia inference concern must not be conflated with the separately
found native missing-predictor bootstrap defect. Polytomy needs branch/root-preserving
topology validation and star/mixed-tree oracles. No release or collaborator message.

## 11. Team Learning
Retaining an applied design schema is part of prediction correctness. Covariance
validation must be relative to its scale. Similar coefficient estimates cannot
stand in for uncertainty, inference or complete workflow validation. R and Julia
source hashes must be refreshed after public-method changes, even without a
likelihood change.

## 12. Cross-Product Coverage
This slice does NOT cover full native/direct/bridge parity, interval calibration,
polytomy support, universal prediction, every warm performance win, clean final
integration, worktree retirement or all-page rendered/deployed documentation.
All runtimes were bounded Mac correctness checks; no new Totoro/DRAC campaign.
Active agent-hours were not instrumented. Terra built/reconciled, Luna scouted,
Sol reviewed independently; no more than three children alongside coordinator.
Programme remains active; continue from LOOP/checkpoint.md.
