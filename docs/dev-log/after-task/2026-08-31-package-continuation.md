## 1. Goal

Resume bounded default-package verification under programme #563 after the
five-minute full-suite pilot, retaining exact-source evidence and time limits.

## 2. Implemented

No numerical source changed. Ran the interrupted location-only REML file, then
a four-file profile/bootstrap/REML group on Totoro. Retained runners, hashes,
terminal status, completed-file markers, failures, and interpretation.

## 3a. Decisions and Rejected Alternatives

Used one Julia thread, one BLAS thread, the existing SSH connection, and
300-second server-side caps. Did not restart after the SSH observation timeout.
Did not count the timed-out group or partial Newton REML file as complete, and
did not replace tests or relax assertions.

## 4. Files Touched

- docs/dev-log/evidence/julia-r-parity/package-continuation-20260831/ (runners, logs, hashes, receipts and README)
- docs/dev-log/after-task/2026-08-31-package-continuation.md
- docs/dev-log/check-log.d/2026-08-31-package-continuation.md
- LOOP/checkpoint.md

Remote artefacts are in the existing source checkout's `loconly-pilot-001` and
`profile-reml-pilot-001` subdirectories. No R source, tree fixtures, or
protected files changed.

## 5. Checks Run

Location-only REML: 602 assertions across three test sets in 20 seconds, exit 0,
with a complete-file marker. The four-file group stopped at 300 seconds with
exit 124. Completed files were profile (20 assertions; 102.3 seconds), bootstrap
(36; 12.0 seconds), and sigma-phylo REML (12; 103.4 seconds). The Newton REML
file is partial: 34 assertions were reported before interruption at line 231 and
there is no completion marker. This snapshot therefore contains four fully
completed files and 670 assertions; the partial fifth file and the full default
suite remain incomplete. Times include JIT compilation and setup. All 326 current
Julia source/test hashes were checked remotely and matched before and after.

## 6. Tests of the Tests

Existing Julia tests ran unchanged; no new statistical test logic was added. The
server-side timeout produced explicit exit 124 and preserved partial results.
Input hashes were checked before loading or fitting and reject mismatches;
complete-file markers are written only after each original `include` returns.
This adds no broad verifier claim.

## 7a. Issue Ledger

Programme #563 remains open. This contributes G3/G7 evidence but closes neither.
Ayumi's issues 28 and 29 remain separate; no comments or issue closures were sent.

## 8. Consistency Audit

Kept the numerical source distinct from the docs-only integration commit
`5e9d5883`. Distinguished complete files from passing partial test sets and
preserved the original full-suite timeout. q4 among-axis profiles differ from
Ayumi's Gaussian LSS `mu:temp_z` target.

## 9. What Did Not Go Smoothly

The first SSH launch observation timed out after 15 seconds while the existing
job completed in 20 seconds; its terminal files were inspected and it was never
restarted. A later launcher stored its PID and returned normally. The four-file
group overran its estimate and stopped at 300 seconds. The partial file remains
incomplete in this snapshot.

## 10. Known Residuals

The Newton REML file is incomplete; the full package suite and opt-in R parity
are incomplete. Canonical-tree profile feasibility, stable larger-bootstrap
inference, control/gradient parity, all capability cells, registered warm
performance, recovery/cleanup, deployed docs, and final Melissa reconciliation
remain open. The two denied source files remain untouched.

## 11. Team Learning

Memory receipt: existing programme, compute, and ownership rules applied; no new
memory mutation. Golden Set: no new numerical algorithm; the original regression
files provide the relevant checks. Scout Luna/low interpreted the requested
profile work; root Sol/medium executed bounded checks. Active agent-hours are
uninstrumented; Totoro used 320 wall seconds in total.

## 12. Cross-Product Coverage

Covers four complete original test files and a partial fifth on Linux with Julia
1.10.10, one Julia thread, and one BLAS thread. Does NOT cover full-suite
completion, native R comparison, the canonical Ayumi tree, calibration, automatic
thread policy, cold/warm benchmark wins, other platforms, or all inference
surfaces. All programme G0–G8 remain open.
