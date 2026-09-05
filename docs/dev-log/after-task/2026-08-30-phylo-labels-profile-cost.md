# Lossless tree labels and measured profile-cost diagnostic

## 1. Goal
Address Ayumi's label transport limitation and investigate sparse Gaussian LSS
profile cost within approved programme DRM.jl#563. Programme G0–G8 remain open.

## 2. Implemented
Julia parses single-quoted Newick labels with doubled apostrophes and preserves
literal spaces, punctuation, Unicode, tabs and newlines. R quotes labels without
changing raw tip identity. Token whitespace remains accepted; malformed labels,
comments and literal NUL input are rejected. Internal labels remain discarded.
A separate diagnostic measures one constrained nuisance solve on each of three
small sparse Gaussian LSS models, with independent dense likelihood oracles.

## 3a. Decisions and Rejected Alternatives
Do not sanitize labels, use a lossy external serializer, resolve polytomies
arbitrarily or forbid control whitespace accepted by native R. Do not treat
profiling's optimizer minimum as certified when the optimizer did not converge.
No likelihood, optimizer tolerance, iteration budget or estimator was changed.
The previously denied numerical engine files were neither edited nor bypassed.

## 4. Files Touched
Julia parser, dedicated label tests and runner include, bridge documentation;
R label encoder/serializer hunks, dedicated and neighbouring serializer tests,
public runner/checker and article. Diagnostic runner/checker and retained evidence
are separate from implementation. Foreign R ZOB and Julia S5 changes are preserved.

## 5. Checks Run
Final focused Julia labels: 30 assertions. R labels: 14 assertions, including
exact reversed-edge traversal. Existing Julia polytomy/height: 69 assertions;
R polytomy: 33 assertions. Public-002 passes eight native/direct/bridge checks
in 28.395 seconds including startup: 12 labeled tips, 72 shuffled observations,
Gaussian phylogenetic LSS. Maximum native coefficient difference is 1.01e-6
against the predeclared 4e-6 tolerance; bridge/direct differences are zero.
Independent dense likelihood errors are below 7e-14. Source hashes before/after
agree. Direct input was explicitly sorted by tree-tip order, which is recorded.
The changed Documenter page executes both examples (one page, 6.225 seconds);
this is Markdown/example validation, not a visual site or deployment check.
All four executable label gates pass final re-verification; Rose approves the
bounded leaf and Melissa finds no material scope drop. The independent checker
passes public002 and rejects 11 damaged receipts; whole-site gates stay open.

## 6. Tests of the Tests
Retained original Julia RED: 5 pass, 10 fail, 1 error; R RED: 3 pass, 4 fail.
Rose caught NUL after the semicolon being confused with the parser EOF sentinel.
The dedicated pre-repair NUL run retained 26 pass/4 fail; repaired run 30/30.
Diagnostic checker rejects six damaged receipts under normal and optimized
Python. Label receipt checker separately mutates source, names, rows and numbers.
Public-001 binds the old parser and is retained as historical evidence, not
substituted for repaired-source public-002. Permission/harness failures remain.

## 7a. Issue Ledger
Programme #563 stays open. Ayumi issues 28/29 remain read-only intake sources;
no collaborator message or issue closure was sent. Her 10,970-species fit report
supersedes a supposed 5,000-species ceiling, but is not our independent large-tree
validation. Label support closes only the bounded admitted-tree transport gap.

## 8. Consistency Audit
Rose reviewed parser and serializer source, caught the NUL defect and approved
the repair. Golden Set: literal names/collision neighbours, topology covariance,
malformed input, reversed edge serialization, public shuffled-row LSS likelihood
and row restoration. The diagnostic is explicitly not an inference acceptance
receipt or warm full-workflow speed comparison. Source-stamped development bytes
include preserved foreign bridge work; final clean integration needs new evidence.

## 9. What Did Not Go Smoothly
Checker failures 001–003 exposed raw-covariance versus correlation, row-order,
and fixed-mean versus conditional-prediction assumptions; they were repaired
and retained before the independent green run.
Initial test fixtures were non-ultrametric and were repaired before meaningful
RED evidence. A bare-token whitespace regression and the NUL sentinel alias were
caught and repaired. Julia cache permission failure was retained and the bounded
run used the approved cache access. One constrained solve exhausted 1,000
iterations; its failure is retained, not reclassified by its small score.

## 10. Known Residuals
The profile pilot used 64/128/256 tips and 15 total coefficients. With 14 nuisance
coordinates, finite differences made exactly 29 objective calls per gradient
request plus one final call: 4,148/58,204/79,548 evaluations. The 256-tip solve did
not converge. Analytic gradient retention, nuisance-status propagation, endpoint
diagnostics, efficient refits and larger bootstrap qualification remain required.
Direct Julia LSS currently indexes phylogenetic groups by first-seen row order;
this separate source-grounded risk needs its own regression and repair. The
public label pilot deliberately orders direct input and does not conceal that gap.

## 11. Team Learning
Exact names are data identity, not cosmetic formatting. Test encoding and decoded
covariance separately. Retain optimizer statuses as well as scores and elapsed
time. Small score does not erase a failed termination flag. Diagnostic allocations
are cumulative Julia bytes, not peak RAM or CHOLMOD memory. Root actual Sol/medium
(plan requested high), Terra/high builder/reconciler, Sol/high Rose, Luna/low scout.
Agent-hours remain uninstrumented; do not convert token counts to hours.

## 12. Cross-Product Coverage
This slice does NOT cover direct arbitrary-row LSS identity, zero/unary branches,
all families, complete profile intervals, large-tree speed, stable bootstrap
quantiles/coverage, whole Documenter rendering/deployment or clean-head parity.
All 24 native missing-predictor obligations, strict tolerance failures, original
LSS SE/REML/mask/large-tree evidence, registered warm wins and safe worktree cleanup
remain required. Totoro/Fir existing sockets were verified live; no remote compute,
installation or transfer ran. No release, registration or collaborator message.
