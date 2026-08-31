# Integration checkpoint and joint prediction label repair

## 1. Goal

Integrate accumulated programme work with current upstream sources, exercise interactions raised by Ayumi's reports, and fix the joint-model factor-label defect discovered by independent review. Programme DRM.jl #563 remains ACTIVE; all G0–G8 remain open.

## 2. Implemented

Created clean paired `codex/parity-integration-20260831` worktrees. Julia merged current main at `567fec069758131804bc4d94582bc48e9338f63f`; R at `06518a5a5cd6888d57efc421a45b8fafd1e7f32c`. These merges changed workflows or instructions only. No numerical source changed through merging. R repair and evidence were committed locally as `acfbcd0d`; its blobs match the tested source. The R prediction helper now preserves native coefficient names for joint objects instead of applying the legacy Julia punctuation rewrite. Both mean and scale predictions with factor labels such as `a: b` and `a & b` work in the new regression.

## 3a. Decisions and Rejected Alternatives

Keep the existing legacy rewrite for older ordinary Julia objects. Joint constructors already supply native R model-matrix names; manufacturing partial versioned bridge metadata would broaden the contract unnecessarily. The change is class-specific and leaves estimators and likelihoods untouched. Root uses the clean integration pair; original worktrees and foreign changes remain preserved. No worktrees or stashes were retired.

## 4. Files Touched

R: `R/julia-bridge.R`, new `tests/testthat/test-julia-joint-prediction-labels.R`, executable worked example `tools/run-julia-integration-session.R`, and `tools/check-julia-integration-session.py`. Mission Control local commit `3b1adbd` updates four NOW fields; their served values were verified and the vault lease released. All42 expanded foreign status entries remained byte-identical. Both repositories retain integration evidence under `docs/dev-log/evidence/julia-r-parity/integration-20260831/`, this report and check-log entries. Julia receives evidence/checkpoint changes only, with no engine edit.

## 5. Checks Run

- Final pure R integration: 1,019 assertions, 23 files, no failures/errors/warnings; one explicitly skipped live-Julia test. Elapsed14.55s.
- Ordinary Rscript: startup and selected Gaussian profile oracle PASS in28.705s; Julia1.10.0, four Julia threads, one BLAS thread. No Julia-test opt-in required.
- One-session004: all eight workflows PASS in49.9s (52.83s including outer process). Ordinary before/after fits agree exactly. Six joint fits cover Gaussian, Bernoulli, two Gaussian, ordinal, categorical and punctuated-factor cases. Same-coefficient mean/scale newdata errors are zero. Row restoration, coefficient/covariance axes and inference refusals checked. This does not establish numerical imputation, covariance, interval or frozen-native parity.
- Totoro: 14 Julia test files, 1,798 passes, TWO existing broken boundary assertions,124s, Julia1.10.10, one Julia/BLAS thread.419 source/test files matched local bytes and remained unchanged. The broken checks remain unmet obligations.
- Separate Totoro four-thread run:62 bootstrap assertions pass in31s, BLAS1. Includes LSS estimator/simulator contract and status-array stress. This is not a speed comparison.
- Source and test patch reviewed independently by Rose. Existing legacy raw-name regression passes.

Mac runs reused the existing R DLL only to load the package. No fresh native compilation, full package test/check, CI or document deployment is claimed. No DRAC compute was needed for these small pilots. Total measured Totoro wall time155s, excluding transfer/setup; active agent-hours were not instrumented.

## 6. Tests of the Tests

The new pure-R constructor test fails on old source:3 passes then the expected design-alignment error. Corrected source passes70 focused assertions, followed by the full1,019 assertion subset. The session receipt checker rejects13 deliberately damaged receipts, normally and with Python `-O`, including missing cases, empty ordinary outputs, stripped joint metadata and omitted bridge source files. It checks current file hashes and exact source-file coverage. These controls concern routing/metadata only; they are not numerical parity tests.

## 7a. Issue Ledger

[DRM.jl #563](https://github.com/itchyshin/DRM.jl/issues/563) remains the programme ledger. [Ayumi #29](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/29) and [her #28 comment](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/28#issuecomment-5472354858) remain unclosed. No collaborator message was sent. No matching programme PR existed at the live check. Accumulated branches still need reviewable integration and required full checks.

## 8. Consistency Audit

Rose compared numerical source bytes with the prior verified pair and reviewed shared prediction helpers. The historic Claude factor-alignment diff was read before changing its descendant helper. Current lane leases belong to this programme; other dirty worktrees were not edited. LOAD-FIRST routing retained Gaussian-only REML wording, Totoro for bounded CPU checks, no registration, and pre-run estimates. Existing ultra-plan/unlazy/ask-brain context was reused. Golden Set was not rerun for this bounded repair. No Codex memory files were used or changed.

## 9. What Did Not Go Smoothly

Raw captured logs retain original trailing whitespace; source/test/tool/doc whitespace checks pass with raw logs excluded. The first R suite completed its tests but CSV export failed on a list column; both the failure and corrected exporter run are retained. The first one-session run passed seven cases but its test oracle failed to rename lowercase categorical suffixes; mapping through model-matrix term assignments fixed the harness, without changing model code. Totoro's launch command backgrounded too broad a shell expression, leaving the SSH invocation open until its30s client timeout; the already-running pilot was inspected rather than relaunched, completed124s, and its evidence was retrieved. The second launch redirected only the intended job and returned its PID promptly. Rose found three false-pass holes in the new receipt checker; all now have corruption controls. One intermediate checker incorrectly assumed160rows for finite fixtures; their frozen180row denominator is now explicit, and the failed checker log is preserved.

## 10. Known Residuals

All programme G0–G8 remain OPEN. Required work still includes the native capability denominator,24 original missing-predictor cells, strict4e-6 parity losses, original LSS SE/REML/mask/large-tree obligations, whole-tree profile/bootstrap feasibility, calibrated coverage, warm full-workflow timing and1/2/4/8thread policy, safe recovery/cleanup, all-page Documenter examples/rendering and live-site verification, full integration checks and programme-level Melissa reconciliation. Two LSS boundary invariance tests remain broken. Previously denied `src/gaussian_sparse_lss.jl` and `src/gaussian_structured.jl` edits were not retried or bypassed. No release, registration, public-site deployment, main merge, or remote publication occurred in this slice.

## 11. Team Learning

A bridge-wide helper can see two naming contracts: raw legacy Julia names and native names installed by a joint adapter. A missing optional metadata field is insufficient to distinguish them. Test constructors and public operations together, and preserve literal factor labels. Keep success counters separate from broken/skip counts. Do not confuse compilation-heavy regression elapsed time with warm performance.

## 12. Cross-Product Coverage

R public bridge and direct Julia regression paths were exercised separately on Mac and Totoro. This check does NOT cover other Julia twins, the24 remaining native missing-predictor cells, structured/non-Gaussian joint predictors, joint profile/bootstrap inference, large-tree timing, or coverage calibration. Root actualSol/medium; builderTerra/high; independentRoseSol/high; scoutLuna/low. At most three children alongside root; no children spawned descendants. This is a programme checkpoint and a bounded local repair, not programme completion.
