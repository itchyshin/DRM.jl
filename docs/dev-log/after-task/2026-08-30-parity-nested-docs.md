# Nested documentation execution and mathematical wording

## 1. Goal

Advance S13 of issue563: execute the complete documentation source inventory,
repair broken examples and reference entries, and audit numerical claims.

## 2. Implemented

Added a fresh-output, strict-example Documenter runner and a synthetic nested
execution test. Repaired the scale-effect accessor and phylogenetic example
imports. Clarified finite quadrature versus exact integration, numerical fitting,
raw-tree covariance scales, replication, and the limitations of the ELBO bound.
Removed a duplicate API registration and documented three low-level interfaces
in prose, retaining their visibility without inventing missing docstrings.

## 3a. Decisions and Rejected Alternatives

Did not change engine source, loosen numerical tolerances, precreate output
folders that Documenter cleans, or suppress example errors. Historical directory
failures were not reproduced by the final fresh-output configuration; no claim
is made that their original cause was proved. Production navigation and full
link checks remain separate from source execution.

## 4. Files Touched

Six tutorial/guide/reference pages, the documentation inventory, two tools, and
retained S13 evidence. The deliberately red S5 tests remain unstaged and separate.

## 5. Checks Run

Nested positive/negative tests and the three-page/four-example gate passed.
All51 source pages emitted in run002 (110.775s), with122 example blocks and no
fatal example/docstring errors. Its gate remained unmet because EXPECT
incorrectly counted119 blocks: three indented bivariate examples were omitted.
Final run003 passed the actual gate in111.795s with51 pages and122 examples;
its emitted output and hashes are retained in the evidence archive.
The static inventory checker and its eight tests pass. Light/dark desktop
screenshots were inspected for the three-page preview; production navigation
and mobile/live validation were not part of that preview.

## 6. Tests of the Tests

The synthetic test requires output on its own line, not echoed source, verifies
the nested working directory, and requires an intentional example error to
throw. First full-source run retained five failures (one missing import and
four reference registrations). Failed setup probes and the count-mismatch gate
are retained; an environment-bearing exception line is explicitly redacted with
its original and retained hashes recorded.

## 7a. Issue Ledger

Issue563 and all programme G0–G8 remain open. Source execution advances G6 but
is not publication, whole-site accuracy review, or programme completion.

## 8. Consistency Audit

Rose reviewed the mathematics and check validity. Required covariance-square,
effect-SD and initial-value wording fixes were applied. Native dispatch remains
unchanged. The full source runner uses flat navigation, while the production
site has50 visible pages plus an unlisted legacy URL; no equivalence is claimed.

## 9. What Did Not Go Smoothly

macOS path aliases and the writer's Git context complicated synthetic setup.
The Julia script initially had an invalid documentation string before imports.
The full-source gate initially undercounted three indented examples. Estimates
were conservative: run002 took about two minutes rather than8–12 minutes.

## 10. Known Residuals

Production navigation/theme, unsuppressed internal-link checks, mobile review,
and deployed content remain unverified. Four index link warnings, a repeated
example-module warning, and missing-logo/favicon warnings remain visible in the
source logs. No general statistical validation follows from example execution.
Protected engine edits still await fresh explicit approval; R prediction parity
remains red. No remote compute was launched.

## 11. Team Learning

Memory receipt: current source, retained logs and agent reviews informed this
slice; no Codex memory was written. Golden Set: not run. Count nested examples
and distinguish Gaussian integration, covariance estimation, and reported scales.
Model routing stayed Luna/low for log preservation, Terra/high for bounded
source/navigation work, and Sol/high for Rose review. Active agent-hours were
not separately measured and are not inferred from wall time.

## 12. Cross-Product Coverage

This does NOT cover R–Julia parity, inference coverage, performance, complete
publication-ready documentation, or cleanup. Mac was used for bounded checks;
Totoro/DRAC remain reserved for pilot-led CPU campaigns under the approved plan.
