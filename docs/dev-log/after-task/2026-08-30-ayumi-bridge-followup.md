# Ayumi bridge follow-up: batch startup and exact profile targets

## 1. Goal
Incorporate Ayumi's issue 29 and issue 28 comment 5472354858 into programme
#563 and repair two bounded bridge defects. Full programme G0–G8 remain open.

## 2. Implemented
Ordinary Rscript use no longer requires a test opt-in. The startup guard uses
R's package-check marker while retaining existing test overrides. Both Julia's
public bridge and the R-generated wrapper profile the requested coefficient,
instead of profiling its entire block and discarding other results.

## 3a. Decisions and Rejected Alternatives
Reuse the existing block/name selector; do not change the likelihood, optimizer,
interval convention or inference target. Keep the implicit phylogenetic SD target
set unchanged. Do not equate noninteractive execution with a package check. No
engine-file workaround for the previously denied sparse-engine edits was made.

## 4. Files Touched
Julia bridge, one new regression file and its runner include; R startup helper,
one generated-wrapper line, guard tests, batch runner, setup article and receipts.
The issue intake maps every reported limitation to remaining work. Foreign ZOB
bridge hunks and S5 test/include remain preserved and excluded from this slice.

## 5. Checks Run
Julia exact-target tests: 36 assertions, including intercept and two slopes,
serial/threaded equality, one attempted target and independent Gaussian ML
endpoints. Existing bridge tests: 132 assertions. R guard tests: 7 new and 34
existing assertions. Actual ordinary Rscript calls fit, the generated wrapper and
public confint without either opt-in; all 12 checks pass in public-green-001,
20.557 seconds including startup, on Julia 1.10.0, four Julia/one BLAS threads.
Source manifests before/after agree. These are correctness timings, not speedups.
All five leaf gates pass (four runnable checks re-executed, final Rose manual
approval). Melissa reconciled the remaining obligations; none were dropped.

## 6. Tests of the Tests
Julia's pre-repair run retained six failures (attempted/used three instead of one)
and 16 passes. R public-red-003 independently reproduced three attempted targets
with correct interval bounds. The startup worker ran a pre-edit test but retained
no log; its two errors were unused-argument errors from the new injected-env API,
not a clean behavioral RED. This process/receipt gap is disclosed. A separate
post-repair check of the unchanged old HEAD helper confirms the ordinary-batch
rejection; it is damage evidence, not retrospectively labelled TDD.

## 7a. Issue Ledger
Programme DRM.jl#563 stays open. External Ayumi issues were read only, not edited
or closed. The 5000 ceiling is superseded by her reported N=10970 sparse fit.
All large-tree inference, labels, transformed names, controls and diagnostics
obligations remain open, as do the original programme requirements.

## 8. Consistency Audit
Rose independently verified the exact-target change and Gaussian likelihood
oracle, and inspected the startup predicate and real marked R CMD check child.
The probe confirms rejection before path validation/Julia startup on local
R 4.6/macOS. It does not prove Windows/CRAN infrastructure or vignette subprocess
protection. The check-package source explicitly unsets the marker in some contexts.
Golden Set: Gaussian analytic profile, exact target counts, existing bridge suite,
ordinary batch integration and actual marked-check subprocess.

## 9. What Did Not Go Smoothly
Retained failures include sandbox Julia-cache permission errors, an initial
public harness using the SD-only inventory instead of fixed-effect inventory,
and a disposable check package missing Author/Maintainer fields. Those were
repaired without hiding their receipts. The completed probe has two package
NOTEs; its marked test child passed. Startup pre-edit logging was inadequate.

## 10. Known Residuals
Whole-tree profiling still lacks a matched bounded scaling pilot. Sparse fits
do not retain their analytic gradient for profiling; value-only calls allocate
fresh factors; the bridge refits on each inference request; nuisance convergence
and endpoint diagnostics are incomplete. These remain distinct open problems.
The denied gaussian_sparse_lss.jl and gaussian_structured.jl were not edited.
Joint missing-predictor inference is required independently of Ayumi's M6q case.

## 11. Team Learning
A correct returned interval can hide substantial discarded work. Assert how many
targets were profiled and compare endpoints independently. A test process exiting
zero is insufficient unless the test runner is configured to fail on assertions;
final acceptance uses stop_on_failure=TRUE. Retain RED logs at execution time.

## 12. Cross-Product Coverage
This slice does NOT cover whole-tree speed, stable bootstrap quantiles/coverage,
all-platform setup, whole-site renders/deployment, final clean-head parity or
cleanup. Receipts describe development bytes including preserved foreign bridge
work; final integration needs fresh qualification. No remote compute, release,
registration or collaborator message. Parent actual Sol/medium (plan requested
high), Terra/high builder/reconciler, Sol/high reviewer; agent-hours uninstrumented.
