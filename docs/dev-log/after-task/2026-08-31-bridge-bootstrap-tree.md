# Phylogenetic bootstrap through the Julia and R bridge

## 1. Goal

Advance approved programme #563/S6/S10/S11 by carrying the original tree into
non-Gaussian bootstrap simulation and refits. Programme G0-G8 remain OPEN.
The preceding paper-reading turn confirmed existing notes but made no new
implementation progress. This continuation starts from local Julia 4fe48c1
and R 9007338e; it does not restart completed sampler work.

## 2. Implemented

Julia's explicit fixed-effect bootstrap primitive now forwards its tree to the
generic bootstrap method. Coefficient labels for a LocScaleObjective first use
the same coupled-term projection as the fitter, so a shared random-effect tag
is not mistaken for a data column. Both fixes retain existing convergence,
failure bookkeeping, coefficient coordinates and likelihood definitions.

R now forwards trees through its generated bootstrap wrapper and no longer
refuses all non-Gaussian phylogenetic bootstraps. Gaussian-only options remain
on the Gaussian path. Non-Gaussian paired terms preserve a shared tag (or the
existing unlabelled coupling contract) and reject mismatches. Family, routing
mode and coupling tag are included in cache identity, preventing mixed-family
calls in one session from reusing incompatible payloads. Actual public R fit
and confint calls pass for the retained Gamma mean-slope bootstrap case.

## 3a. Decisions and Rejected Alternatives

Do not drop trees, treat shared failures/NaNs as success, lower tolerances,
change the estimator, or suppress hard draws. The non-unit-height tree exposes
differential handling between APIs; it is not an independent covariance oracle.
B=2 tests integration only. Native Gamma rejects this coupled structured form,
so this case tests an existing Julia-backed admission, not native-Gamma parity.
Gamma shape versus public CV normalization remains required separate work.

## 4. Files Touched

Julia src/bridge.jl, test/test_bridge_bootstrap_tree.jl, test/runtests.jl;
local .unlazy/bridge-bootstrap-tree.md; this report, check-log, retained evidence
and LOOP checkpoint. R worker owns only its leased bridge/tests/report paths.
No protected Gaussian engine or tutorial files changed.

## 5. Checks Run

Mac-local, every Julia process capped at60s, BLAS1 asserted. Final18/18 at
one Julia thread24.793s and four threads22.081s, through actual unlazy G1/G2
execution. Adjacent formula-label/LSS-label/profile-status/old-Gamma-B2 suite
passes858/858 in51.386s at4Julia/1BLAS. Before/after source hashes agree.
G0 is a manual retained-red/review verdict. Actual R public fit/confint passes
at1/4Julia threads in29.800s/27.360s, with BLAS1,2/2 successful draws,
unchanged runtime source hashes and the original1e-12 comparison tolerance.
Maximum observed difference from direct Julia is1.35e-14, not bit equality.
R source was loaded from the integration checkout with pkgload, compile=FALSE;
loaded paths and DLL provenance are recorded. No installed comparator changed.
The final pure-R focused check passes16 assertions; its separate retained log
and test hash bind this evidence. The adjacent R inference file had live-engine
skips, so its modified Poisson case is not claimed as executed here.
Unlazy G1-G3 are executed passes; final G4 review/reconciliation is recorded
separately below, not inferred from checked boxes.

Existing ControlMaster connections verified with hostname only: Totoro, Fir,
Narval, Rorqual, Trillium and Killarney. No fresh authentication, jobs or remote
compute. Initial socket EPERM was sandbox-only, not expired credentials.

## 6. Tests of the Tests

Retain204158Z: direct2/2, bridge label renderer errors on missing tree_boot
data column. Label-only patch retained. Retain204403Z: direct2/2, bridge errors
because no tree reaches the sampler. Retain204352Z cache EPERM separately as
environment failure. Strengthened tests require direct2/2, finite estimates and
bounds, exact bridge equality, correct thread metadata, and rejection of missing
or changed trees. Generated per-run scripts and test snapshots are retained.

## 7a. Issue Ledger

#563 stays open. This advances bridge integration; it closes no programme issue.
R worker follows up the actual public R call rather than substituting a mock.

## 8. Consistency Audit

Rose reviewed Julia source43829548 and the binary-export test delta cf1d2326.
The18-test runs use that final test; the858-test neighbour run uses the same
production source. Rose found and reviewed the R cache fix861037c5; the
return-to-Gaussian test was added after her review request. Melissa verified
the final R receipts and required updating draft status and binding the
separate pure-R evidence. Final review notes are retained alongside receipts.

## 9. What Did Not Go Smoothly

The actual call exposed a chain of stale integration assumptions, not just the
initial tree omission. Julia cache and R activation writes required scoped
sandbox escalation. All unsuccessful runs remain visible. Existing NaN-Hessian
warnings in the adjacent bootstrap fixture remain; no warning-free claim.
The first actual R comparison205655Z failed1e-12 despite completing2/2 refits.
R CSV conversion changed three response values by one ULP. Retain that failure
and the exactly reconstructed original driver (hash checked against its receipt).
The rerun reads lossless little-endian Float64 copies of the original Julia
arrays and reference; no reseeding, data-value change or relaxed tolerance.
The day-wide lifecycle checker still reports historical compaction/guardian
threshold failures. This disk-goaled continuation uses the approved checkpoint
exception; that administrative exit is not a technical validation result.

## 10. Known Residuals

The retained Gamma mu-slope integration is verified; other R inference routes
are not thereby qualified. Implicit non-Gaussian SD targets,
K/A/coords provider forwarding, remaining families, public Gamma normalization,
profile/bootstrap reliability and calibration, all native capability cases,
matched warm timings and automatic1/2/4/8thread policy remain required. Preserve
the24 missing-predictor cells, strict4e-6 losses, stamped LSS SE/REML/masks/
inference matrix/large-tree/final-head obligations, all-page docs and live-site
verification, safe worktree/stash recovery, final Mission Control and Melissa.

## 11. Team Learning

Exercise the real public R call after a direct Julia fix: here it found dropped
tags and a wrong family option that a Julia-only test could not see. Cache
identity must include every routing field stored in the cached payload; test
both call orders. Equal CSV bytes do not ensure equal floating-point arrays
across readers, so retain exact numeric inputs for strict integration checks.
The after-task checker now requires Team Learning and Cross-Product Coverage;
the initial draft failed those headings and was repaired before closure.

## 12. Cross-Product Coverage

Retained positive cell: coupled Gamma, phylogenetic intercepts on mean and
scale, shared tag, non-unit-height four-tip tree, mu slope target, B=2,
direct Julia and actual R-via-Julia, serial/parallel at1/4Julia threads and1BLAS.
Pure-R routing checks cover labels, both cache call orders and Gaussian options.
This slice does NOT cover non-Gaussian implicit SD targets, K/A/coords providers,
REML, missing rows or predictors, all profile/bootstrap targets and families,
native Gamma parity, calibrated interval coverage or performance. Those and all
original obligations listed above remain required programme work.

## 13. Next Action and Routing

Next: validate other admitted non-Gaussian structured targets, complete K/A/
coords forwarding, and implement coherent Gamma public-scale normalization.
Keep the full original programme scope and failed receipts. Do not rerun the
old label/tree discovery or call this two-draw check interval calibration.
One root coordinator; R builder requested Terra/high, Rose Sol/high,
connectivity scout Luna/low, bounded Melissa Terra/high. Active agent-hours are
not instrumented. No release, registration, public deployment, collaborator
message, main merge or worktree retirement is represented by these local tests.

Final checkpoint: Melissa found one contradictory R log-provenance sentence;
the owning worker corrected it. Rose and Melissa give bounded PASS for this
case only. Mission Control two-field change matched the served dashboard and
was locally committed as 5cf820c; its lease was released. Artifact integrity
passed, and a deliberately flipped fixture byte was rejected in a scratch copy.
