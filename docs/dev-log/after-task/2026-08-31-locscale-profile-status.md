## 1. Goal

Stop canonical non-Gaussian location-scale profiling from reporting failed or uncertified endpoints as successful, within programme #563 (S11/G3).

## 2. Implemented

Constrained nuisance results now require successful optimization plus fresh finite objective and free-gradient checks. Root searches return explicit accepted, no-crossing or failed status, including last candidate, residual, reason and counters. The public profile result propagates failures; the R-facing message includes selected endpoint details. Compatibility wrappers retain their previous return shapes. No likelihood, optimizer budget, estimator or coefficient scale changes.

## 3a. Decisions and Rejected Alternatives

Keep signed infinities for failed endpoints to match the existing interface, but distinguish failure from searched-range no crossing. Preserve the 200-iteration nuisance budget and existing tolerances. Use existing likelihood-difference cancellation checks rather than relaxing tolerances. Ordinary callback failures become status records; interrupts propagate. Coefficient threading remains a separate obligation.

## 4. Files Touched

src/locscale_profile.jl, canonical location-scale sections of src/inference.jl, the bridge message helper, focused tests and runtests include, two reference pages, evidence, this report and check-log. Neither denied Gaussian source file changed. R test work is separately committed at 9007338e5.

## 5. Checks Run

Final executable G0–G2 pass. The focused test has 90 assertions; actual-module checks pass 196 assertions with one Julia thread in 39.22 seconds and 200 with four threads in 39.00 seconds. Counts include two standalone source-path/BLAS-restoration assertions. All source/test hashes match before, after and current files. The generic nuisance fixture independently exercises deterministic warning behavior. Rose approved the final production and test design; all four local slice gates are met. All 52 documentation pages built with strict production navigation in 152.17 seconds against unchanged source. This is a source build, not a new HTML visual or deployed-site verdict. Earlier candidate checks remain separately identified.

## 6. Tests of the Tests

Retained initial missing-helper RED, old helper 14-pass/3-fail bridge control, endpoint iteration-exhaustion and failed-refinement probes, shifted-likelihood false certification, exception and infinite-coordinate controls. R damaged adapters produce six expected status/message failures. The fresh tests reject numerical failures rather than asserting finite limits universally. Existing generic nuisance tests supply deterministic public warning coverage.

## 7a. Issue Ledger

Programme #563 and all global G0–G8 remain open. A separately reproduced inner-mode stationarity defect is next, before coefficient threading. No issue closure or collaborator message.

## 8. Consistency Audit

A small real Gamma example reports two failed nuisance arms, zero certified endpoints and zero no-crossing endpoints. This proves disclosure only. The canonical profiler remains serial even with threads=true. Documentation now describes status columns and restores both internal doc bindings. Global numerical accuracy is not certified by this repair.

## 9. What Did Not Go Smoothly

Rose found four additional gaps after initial passing tests: NLL cancellation, escaping callback exceptions, nonfinite coordinates and a moved docstring. A test used a documentation API unavailable on Julia 1.10; its failure is retained. One local run could not start because macOS lacks timeout; another was blocked by precompile-cache permissions before tests. The first ledger draft did not parse; executable gates were corrected. The first frozen model test still assumed optimization must fail; the final test removes that assumption and fresh checks pass.

## 10. Known Residuals

Inner-mode exhaustion currently checks Hessian factorization without stationarity; independent synthetic probes reproduce false success even at the default budget. This has not been shown to cause the real Gamma failures. Remaining live JuliaCall/native/direct parity, valid profile endpoints, slow tests, bootstrap, threading and performance remain open. Preserve the deferred threading RED fixture, including the disclosed missing bytes of its earliest overwritten draft.

## 11. Team Learning

Root Sol/medium, builder Terra/high, Rose Sol/high, mechanical scout Luna/low. Active agent-hours uninstrumented. Golden Set: exact root controls, existing generic nuisance status fixture, small Gamma model and public bridge conversion. Memory receipt: no Codex memory changed. Run times are retained separately; no new remote allocation or campaign launched.

## 12. Cross-Product Coverage

This does NOT cover full functional parity, calibrated profile/bootstrap inference, canonical profile threading, every-workflow speed wins, all-site visual verification, deployment, worktree retirement or programme completion.
