# Two-Gaussian direct formula and R bridge checkpoint

## 1. Goal
Continue the approved Julia–R parity programme, issue DRM.jl#563. This slice
connects the verified two-Gaussian prepared kernel to direct Julia formulas and
the real R JuliaCall bridge. Full programme G0–G8 remain OPEN.

## 2. Implemented
Direct Julia admits two distinct bare additive mi terms and independently named
Gaussian imputation models. It exposes per-variable coefficients, natural SDs,
raw covariance, imputed summaries and fit status. R retains native preparation,
column positions and response-row policy. A separate primitive schema carries
two predictor matrices/masks and restores native coefficient order on both
covariance axes. R transforms both log SDs using the full Jacobian and retains
the full conditional covariance. Existing one-predictor routes remain supported.

## 3a. Decisions and Rejected Alternatives
Keep one shared numerical kernel; no likelihood or optimizer-default changes.
Direct raw ordering remains documented prepared order. R public ordering and
natural SD scales follow its existing adapter contract. Two-variable imputed()
requires a variable, matching native behavior. No baseline/tolerance changes.

## 4. Files Touched
Terra/high owned src/joint_missing_frontend.jl and its new frontend test.
Root owned primitive transport, R adapters, cross-language runner, dense oracle,
negative controls, module/test wiring, documentation and checkpoint. Sol/high
Rose independently reviewed source. Unrelated S5 test/include and R ZOB edits,
and previously denied sparse files, are preserved. No GPL implementation source
was copied into Julia; only generated numerical reference data cross the boundary.

## 5. Checks Run
Final direct-formula, primitive-transport and R-adapter gates pass, including
existing one-predictor neighbours, all8masks, differing design widths, factor
preparation, reversed impute entry order, fully observed exogeneity refusals,
and a fitted non-monotonic column permutation with independent Hessian/V check.
Real public002 uses the final source and actual JuliaCall. Native tolerance stays
4e-6: maximum theta error1.127707e-6, training prediction1.437083e-6,
loglik1.305e-10, imputation means below3.877e-7 and SEs below2.156e-7.
Saved-result dense Gaussian oracle independently checks likelihood, means,
conditional covariance, imputation uncertainty, public scale/covariance and
predictions. Public002 elapsed28.924seconds includes startup; NOT a warm timing.
Summary/Wald checks establish execution and row counts only, not numerical
inference parity. Both edited documentation pages execute their examples. This is source-build
verification only, not visual, full-site or deployment proof.

## 6. Tests of the Tests
New frontend and transport tests failed before implementation at their original
one-predictor admission boundaries. R preparation and result-adapter red logs are
retained. All21 damaged receipt controls fail normally and under Python -O:
source/runtime, theta, raw/public covariance, second SD/mean/SE, row/mask/status,
NaN, conditional offdiagonal, prediction and denominator damage. The initial
offdiagonal damage used a fully missing row whose true covariance was already
zero: this was a no-op test, corrected to an observed-response row with both
predictors missing. Rose found that reported operation flags and adapter-error fields were ignored;
the checker now requires exact field sets, true flags, finite independently
recomputed errors, and four additional damage controls. No oracle threshold
was weakened.

## 7a. Issue Ledger
DRM.jl#563 stays open. The new missing-predictor-progress.json records progress
without rewriting the immutable initial24-obligation audit. No entire capability
axis, full S9, benchmark denominator, release or programme gate is closed.

## 8. Consistency Audit
Julia raw covariance includes log SD coordinates; natural-SD accessors do not
silently transform it. R public covariance applies both SD transformations and
retains raw coordinates separately. The conditional covariance is retained after
R validation, repairing a metadata omission found by Terra review. Documentation
now describes the two-predictor development route and its remaining limitations.
Golden Set: frozen native160rows/all8masks plus actual JuliaCall output, independent
dense oracle, neighbour tests and targeted refusal/permutation controls.

Bounded Melissa (Terra/high) found no material scope drop; the full checkpoint
remains authoritative over the shorter progress-map next list. G8 stays open.

Rose final bounded approval follows independent saved-result verification and
21damages normal/-O. Seven slice gates met; no programme gate closed. Mission
Control eca0d56 verified through served JSON; scoped vault lease released.

## 9. What Did Not Go Smoothly
A Julia compile-cache EPERM ended the sandbox attempt; the supervised scoped
rerun passed. R helper argument names/all-variable validation needed repair.
The tiny response-drop unit fixture initially had too few observed predictor
values for a two-coefficient imputation model; its drop-policy check now uses
intercept-only models, while differing-width checks remain elsewhere. Original
native reference data, estimators and fitted comparisons are unchanged.

## 10. Known Residuals
Earlier single-predictor default4e-6 failures remain open and historical receipts
are preserved. Current-source integration evidence needs refresh after these
source changes. No full Pkg.test/R CMD check, recovery, coverage, every-case speed,
cleanup, release, registration or deployment occurred. No Totoro/DRAC jobs run.
Active agent-hours are uninstrumented; no invented actual-hours total is given.

## 11. Team Learning
Validate both covariance axes after actual non-monotonic transport, not merely
a permutation helper. Retain validated metadata in the final public object.
Use fully observed inputs to prove exogeneity refusals independently of missing
fixed-covariate checks. A damage control must change a nonzero quantity.

## 12. Cross-Product Coverage
This slice covers fixed Gaussian ML with two independent fixed Gaussian
predictors through prepared Julia, direct formulas and the real R bridge, plus
existing one-predictor neighbour tests. It does NOT cover ordinal/categorical or
other predictor families, non-Gaussian responses, grouped/structured predictors,
REML, profile/bootstrap, recovery/coverage, full public-output parity, all-page
visuals/deployment, or any registered warm performance claim.

## 13. Next Action and Checkpoint
Continue all24 original missing-predictor obligations. Next substantive admission:
ordinal/categorical predictors through a shared finite-state prepared contract.
Preserve and resolve earlier single-predictor numerical failures. Continue S2/S3,
S7/S8/S10/S11, LSS stamped-SE/REML/masks/inference/10k/final-head evidence, frozen
warm-workflow measurements and policy calibration, original Claude/Cursor recovery,
whole-site verification and final Rose/Melissa reconciliation. Programme remains
ACTIVE; this checkpoint is neither completion nor a handoff.
