# S10 ordinary Gaussian component prediction checkpoint — #563

## 1. Goal
Extend stored conditional predictions through the R bridge using existing Julia
random-effect modes, and verify them against independent small-model oracles.
The complete Julia–R parity programme remains active.

## 2. Implemented
The verified adapter carries scalar intercept/slope,
one correlated intercept-and-slope, and distinct-group scalar components.
It validates component identity, first-seen levels, row indices, loadings and
mode dimensions. Newdata remains fixed-effect prediction. No Julia engine
source is changed.

## 3a. Decisions and Rejected Alternatives
Reuse one existing fit and its modes. Do not refit to reconstruct predictions,
change estimators, loosen the frozen tolerance, or merge unfinished zero-one-beta
work. Repeated-group and wider/mixed correlated capabilities remain required
programme gaps. Preserve the existing multi-component scale clamp when returning
stored scales; compatibility with native fits in that extreme region stays open.

## 4. Files Touched
R: selected conditional sections of R/julia-bridge.R, the prediction manual and
new component tests. Julia: independent pilot/checker tools, retained component
evidence, this report and checkpoint files. Mission Control was separately
updated in the local vault and verified against its served JSON.

## 5. Checks Run
Four component cases passed 32/32 prediction comparisons against both the dense
oracle and native R: maximum adapter error 3.553e-15, native difference
1.896e-6 (tolerance 4e-6), and likelihood error 1.706e-13. Runtime was 27.118
seconds. The original three RI cases were rerun in 19.457 seconds: all 24
adapter comparisons pass, while the original varying-scale newdata mu failure
remains 1.08595e-5 > 4e-6. Julia and BLAS each used one thread. The isolated
candidate passed the component, legacy RI and prediction-scale pure suites;
27 assertions belong to the new component file. No remote compute was launched.
The first RI-only baseline remains retained: eight stored-mean refusals,
24 other comparisons passing, all four dense likelihoods agreeing, 26.813 seconds.

## 6. Tests of the Tests
The first component pure tests failed before implementation. Deliberate payload
damage exercises map, loading and mode validation. The receipt checker rechecks
retained vectors and likelihood values; its negative fixtures include biased
means/likelihoods, missing rows/cases, non-finite values and a wrong thread budget.
All 14 normal/optimized Python subprocess outcomes pass; invalid receipts fail
without a success token. The inner checker rejects eight shifted means, one
shifted likelihood and one missing row.

## 7a. Issue Ledger
https://github.com/itchyshin/DRM.jl/issues/563 stays open. Full G0–G8, the frozen
native-fit discrepancies and the remaining functional/performance/documentation
obligations are unchanged.

## 8. Consistency Audit
Terra/high implemented the R adapter; Sol/high independently reviewed the
mathematics and identified payload/scale neighbours; the coordinator owns
candidate isolation and live checks. Rose independently approved the final
candidate, reran 27 pure assertions and 14 receipt-checker outcomes, and verified
all 86 Julia source hashes plus R source/runner/build hashes. Memory receipt: existing on-disk programme
state was used; no Codex memory files changed. Golden Set: not run for this
bounded code slice; no global memory-regression claim.

## 9. What Did Not Go Smoothly
The first generated wrapper contained two Julia expressions. JuliaCall accepts
one expression, so setup failed before a fit. That source hash and error log are
retained. Review also found a mismatched v1 payload could yield empty predictions,
and multi-component stored scales could omit the engine's clamp. Both were repaired and have explicit regression evidence. Rose also found an
inherited candidate provenance file from the prior RI slice; it was archived
privately and replaced with the actual component source/build hashes. The live
receipt had independently recorded the correct executed hash throughout. Two
isolated-gate attempts used wrong working-directory/test paths; both failed
without fitting. Correct absolute paths passed all three reverified gates.

## 10. Known Residuals
Repeated-group modes, wider/mixed correlated effects, structured/non-Gaussian
conditional predictions and extreme native clamp compatibility remain open.
The prior ordinary-RI varying-scale native-fit mismatch and fixed-effect factor
stopping discrepancy remain failures. Protected Julia precision edits remain
unapproved and untouched. No campaign, deployment, release or destructive cleanup.

## 11. Team Learning
Test the generated Julia expression through JuliaCall, not only R parsing.
Separate adapter agreement with the fitted model from agreement between two
independently optimized fits. Retain exact executed source hashes and failed
attempts. Actual agent-hours are not instrumented; none are fabricated.

## 12. Cross-Product Coverage
This slice concerns four complete-data Gaussian ML component cases, alongside
the previous RI regression cells. It does NOT cover the complete capability denominator,
inference matrix, missing-predictor engine, performance gate or documentation
programme. Receipt comparison checks do not regenerate the dense solve; that
calculation belongs to the separately executed R oracle harness.
