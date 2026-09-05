# S9 joint formula frontend and imputation uncertainty checkpoint — #563

## 1. Goal
Extend the shared prepared joint likelihood to a direct-Julia formula frontend
and validate native-shaped imputation summaries. The approved full Julia–R
parity programme remains active; this is a bounded implementation checkpoint.

## 2. Implemented
Gaussian-response ML now admits one additive mi(x) predictor with a Gaussian or
Bernoulli predictor model, complete exogenous fixed designs, and retained rows.
Added miss_control(), impute_model(), JointDrmFit, coefficient/likelihood/covariance
accessors and imputed(). Gaussian imputation SEs use conditional variance plus
first-order parameter uncertainty; Bernoulli summaries use conditional Bernoulli
variance. Observed predictor SEs are missing. se=false preserves failure statuses.
Raw and natural predictor-SD coordinates are explicitly separated. Module and
runtests wiring are included; no unsupported options are silently dropped.

## 3a. Decisions and Rejected Alternatives
Derive the Gaussian prediction-error identity v + J Vtheta J' independently,
using the marginal observed-information inverse. Do not mistake conditional
variance alone for native Gaussian imputation uncertainty. No GPL source was
copied. Reject response/marked predictor in all fixed designs, including nested
transforms, because circular conditional specifications need not normalize.
One source layer serves both admitted direct-Julia routes; R bridge admission
is still outstanding. Do not replace the frozen native optimizer baseline with
the closer diagnostic restart. The registered4e-6 tolerance is unchanged.

## 4. Files Touched
Added src/joint_missing_frontend.jl and src/joint_missing_uncertainty.jl;
wired src/DRM.jl and src/gaussian_core.jl. Updated prepared summary wording/status
and corresponding test/checker expectations. Added frontend/uncertainty tests,
a native generated uncertainty fixture, native uncertainty probe/exporter,
common-parameter and public-fit runners/checkers with damaged-input controls.
Updated two reference pages, check-log, this report, evidence and LOOP resume
files. Scoped Mission Control status was locally committed in the vault.
No R implementation file changed in this slice. Existing S5 red test/include
and unfinished R ZOB changes are excluded. Exact paths are in retained manifests.

## 5. Checks Run
Public frontend:57 assertions, including two small fits and nine self/cyclic or
raw-control refusal tests. Uncertainty kernel:19 assertions with an independent
analytic Gaussian Jacobian, four missingness masks and failure-status checks.
Supplied-parameter receipt002:320 means/SEs and all row/status fields pass native
comparison; max mean error4.663e-15 and SE error5.829e-16. This uses supplied native
covariance and does not by itself validate covariance estimation.
Public formula fit001:two fits converge in10.236s, gradients6.739e-10 Gaussian and
2.351e-11 Bernoulli, H*V identity errors at most5.552e-16. Independent likelihood
and imputation checks pass at fitted Julia parameters. Native theta errors:
Gaussian2.754638e-6 PASS; Bernoulli1.001509e-5 FAIL against4e-6, retained red.
Native current-source probe passes in1.933s, with imputation mean error4.441e-16
and SE error2.658e-13. Old installed-build Gaussian means fail by0.000860606;
current R already contains the selected-state repair, so no duplicate patch.
All Julia checks pin Julia and BLAS to one thread. No remote job or speed claim.
Existing Gaussian core/formula and63prepared assertions also pass. Final strict
documentation source build:52pages124examples116.529s. This is not a rendered
site/deployment verdict. Both source-bound receipts match all89current source
files; both protected files match the original source pin.

## 6. Tests of the Tests
Public API tests failed before integration. Nine fullyobserved invalid joint
models failed refusal tests before repair and pass after it. The initial cache
permission failure is retained separately and is not described as a code-red test.
Common-parameter checker rejects14 targeted damaged receipts normally and with
Python -O. Public-fit checker has17 damage controls, including negative Hessian,
negative SE, nonfinite estimates, overlong field vectors and independent likelihood
corruption; all17 pass normally and with Python -O. Initial checker-control
mistakes and corrected outcomes are retained.

## 7a. Issue Ledger
https://github.com/itchyshin/DRM.jl/issues/563 remains open. All programme G0–G8
remain open. The24 native missing-predictor obligations remain required; two
partial direct-Julia admissions do not close R bridge or broader model coverage.
The Bernoulli native default comparison is an unmet gate, not an exclusion.

## 8. Consistency Audit
Terra/high built the frontend/tests and public-fit harness. Luna/low identified
the existing R selected-state correction and reconstructed the exact old native
probe runner, whose SHA matches its receipt. Sol/high independently reviewed the
uncertainty identity, found the two admission defects, and approved the repaired
frontend SHA8bfc53ae2ecc382ee68e51def44a3373415f2fd6db1ae57f7956d8d5b7e4c15a.
Root integrated and reran acceptance checks. A bounded Melissa review reconciles
this checkpoint; it is not programme G8 closure. It flagged inherited LOOP plan
and resume drift; the checkpoint now points explicitly to the approved programme
plan, preserving the unrelated Cox–Reid plan untouched. Mission Control status is locally
committed as ef05ad8; all three edited fields were verified through served JSON.
Memory receipt: programme choices and remaining obligations are retained in this
report, LOOP/GOAL.md, LOOP/checkpoint.md and the approved
docs/dev-log/plans/2026-08-30-julia-r-parity.md; no Codex memory file was edited. Golden Set: existing Gaussian
core/formula tests plus the two frozen160-row native datasets; not a full suite.

## 9. What Did Not Go Smoothly
An installed R build predated a source fix and returned stale imputation means;
separately loading current R source with byte fingerprints isolated this cause.
The native probe was extended after its old run; the exact old runner was
reconstructed and SHA verified rather than misattributing current bytes.
Rose caught invalid raw controls and self/cyclic formulas. New damaging controls
also revealed incorrect expected-failure labels in a test of the fit checker;
the failing evidence remains retained, and corrections must pass before acceptance.
The original native Bernoulli fit remains outside tolerance, even though a tighter
diagnostic restart approaches Julia's solution. This does not justify reseeding,
changing tolerance or discarding the frozen native default result.

## 10. Known Residuals
The after-task validator passes report structure but returns exit1 because the
programme acceptance ledgers remain unmet. This is retained, not bypassed or
converted to abandoned gates. No R bridge missing-predictor admission, grouped/multiple predictor model, further
response/predictor family, missing-predictor REML, profile/bootstrap/MI draws or
parallel policy is implemented here. No full Pkg.test or cross-platform campaign.
Whole-site visual and deployed-content verification remain open. Both denied
sparse conversion source files remain untouched; no workaround. Safe worktree
retirement and recovered obligations remain open. Required performance work
includes the large-tree manifest, matched warm full workflows, automatic thread
policy with separate calibration/evaluation fixtures,1/2/4/8thread results and
separate cold-start timings.

## 11. Team Learning
Validate the generative factorization, not just individual conditional densities.
N(x;c*y,tau²) N(y;b*x,sigma²) integrates to1/abs(1-b*c), or diverges at b*c=1.
Separate kernel correctness, covariance calculation, native optimizer agreement,
and runtime source identity. Keep the Mac for bounded single-thread checks;
Totoro pilots and DRAC allocations remain the campaign path. Actual agent-hours
are not instrumented; measured fit/build seconds are not agent-hours.

## 12. Cross-Product Coverage
This covers fixed-effect Gaussian-response ML with one Gaussian/Bernoulli
predictor in direct Julia, its prepared interface and native-shaped imputation
summaries on the frozen fixtures. It does NOT cover complete native parity,
R bridge admission, interval coverage, all-user-operation compatibility,
thread/performance claims, safe cleanup closure or published documentation.
Local programme branches remain CARRIED-OVER pending the full programme gates.
No release, registration, collaborator message, destructive cleanup, push or merge.
