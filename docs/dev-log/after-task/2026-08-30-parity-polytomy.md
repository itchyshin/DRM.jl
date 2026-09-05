# Rooted polytomy admission and public verification

## 1. Goal
Repair the confirmed binary-only tree restriction in programme #563 without changing implied covariance. All programme gates G0–G8 remain open.

## 2. Implemented
Both Julia constructors accept positive-length rooted multifurcations and validate topology, tip names and representable precision. The R serializer accepts internal nodes with at least two children. Tree-height traversal uses an advancing queue cursor instead of repeatedly shifting the queue.

## 3a. Decisions and Rejected Alternatives
For edge-incidence matrix B, Q = Bᵀ diag(1/b) B. Conditioning the root gives shared-path Brownian covariance. Binary node counts are a special case. No invented branches, normalization, estimator changes or tolerance changes were introduced. Scalar height normalization matches correlation scale only for ultrametric trees.

## 4. Files Touched
Julia: src/sparse_phy.jl, two new tests and their runner includes, independent receipt checker, two documentation pages and evidence. R: two serializer lines, new tests, verification runner and evidence. Foreign ZOB edits and the Julia S5 include/test remain untouched and unstaged. Previously denied Gaussian files were not edited.

## 5. Checks Run
Julia: 55 constructor, 22 kernel and 14 height assertions pass (91 total). R: 33 serializer and 122 existing bridge assertions pass (155 total). Two default Gaussian ML cases—12-tip star and mixed polytomy, each with 60 shuffled repeated observations—pass native/direct/bridge comparisons at 4e-6. Public003 retains source, DLL and runtime stamps; elapsed 21.399 seconds includes startup. Two edited documentation pages execute one example. All five leaf gates pass final re-verification.

## 6. Tests of the Tests
Before repair, Julia returned 3 passes, 17 failures and 4 errors; R reproduced binary refusals. The independent public checker rejects 16 corruptions normally and under Python -O, including wrong topology, covariance, SD, row order, convergence, source, DLL and tolerance. Public001 lacked the live-Julia opt-in. R green001 had six scalar-name oracle mismatches. These failures and their repairs are retained.

## 7a. Issue Ledger
DRM.jl#563 remains open. Positive-length polytomy admission is repaired at the tested scope. All-family qualification, inference, additional tree forms, the 24 native missing-predictor obligations, prior strict losses, LSS evidence, recovery, performance and final integration remain required.

## 8. Consistency Audit
Rose approved source18c72189e6eddc6ee325f8ce70e26d7055bbdf7492fe303bcdc8c988941bcfff; both required test includes are wired. Melissa reconciled this bounded closure against the programme. Golden Set: explicit shared-path covariance/log-determinant identities, binary fixtures, q2 dense Gaussian likelihood, q4 fixed-state Hessian/normalization, public fits and corrupted receipts. No q4 mode-convergence or interval-coverage claim follows.

## 9. What Did Not Go Smoothly
The old stored-nonzero example counted assembly triplets; corrected from 16 to 13. Height guidance silently assumed ultrametricity; corrected. A mechanical scout returned stale serializer findings, so the coordinator checked the current file and passing tests. The first public harness omitted the required live-Julia opt-in; the failure remains visible.

## 10. Known Residuals
Ayumi's profile/bootstrap report has no supplied model yet; do not describe it as a joint missing-predictor defect. Known joint inference gaps can progress independently. Zero-length edges, unary nodes, single-tip behavior and broader labels remain unqualified here. The R correlation-scale bridge still requires ultrametric trees. Receipts describe development bytes with preserved foreign R work, not clean final integration. No release, registration, deployment or collaborator message.

## 11. Team Learning
Validate topology using mathematical tree invariants, including root identity, leaf maps and finite summed precisions. Dirty-file authorship cannot be inferred from unrelated commits. Preserve foreign bytes and stage only the owned hunk.

## 12. Cross-Product Coverage
This slice does NOT cover full phylogenetic parity, all inference, interval calibration, warm performance, whole-site rendering/deployment, worktree cleanup or final integration. These were bounded Mac checks; no new Totoro/DRAC campaign. Agent-hours were not instrumented. Terra/high built and reconciled, Sol/high reviewed, Luna/low scouted; the actual parent route is Sol/medium, while the approved plan requested high. Programme remains active.
