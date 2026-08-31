## 1. Goal

Resume bounded default-package verification under programme #563 after the
five-minute full-suite pilot, retaining exact-source evidence and time limits.

## 2. Implemented

This verification slice made no numerical source changes. It ran the interrupted
location-only REML file, a four-file profile/bootstrap/REML group, an isolated
Newton REML file, a four-file bootstrap/spatial/prediction continuation, and
prediction/response-family groups on Totoro. Retained runners, hashes, terminal
status, completed-file markers, failures, and interpretation.

## 3a. Decisions and Rejected Alternatives

Used one Julia thread, one BLAS thread, the existing SSH connection, and
300-second server-side caps. Did not restart after the SSH observation timeout.
Did not count the timed-out group or its partial Newton REML output as complete,
and did not replace tests or relax assertions. The later unchanged whole Newton
file was counted only once after its own completion marker. All retained results
precede the later BLAS-helper repair and are not final-head qualification.

## 4. Files Touched

- docs/dev-log/evidence/julia-r-parity/package-continuation-20260831/ (runners, logs, hashes, receipts and README)
- docs/dev-log/after-task/2026-08-31-package-continuation.md
- docs/dev-log/check-log.d/2026-08-31-package-continuation.md
- LOOP/checkpoint.md, LOOP/GOAL.md, and LOOP/arcs.md (location/status correction)
- Mission Control's scoped programme record (42 foreign files preserved)

Remote artefacts are in the existing source checkout's retained continuation
subdirectories. No R source, tree fixtures, or protected files changed.

## 5. Checks Run

Location-only REML: 602 assertions across three test sets in 20 seconds, exit 0,
with a complete-file marker. The historical four-file group stopped at 300 seconds
with exit 124. Its completed files were profile (20 assertions; 102.3 seconds),
bootstrap (36; 12.0 seconds), and sigma-phylo REML (12; 103.4 seconds). Its Newton
file reported 34 assertions before interruption at line 231 and had no completion
marker. Those assertions overlap the later isolated unchanged whole Newton file,
which completed with 39 assertions across eight test sets in 107 seconds, exit 0.
The subsequent unchanged bootstrap, marginal-bootstrap, spatial, and prediction
files completed in 41 seconds with 79 assertions. Six prediction/response files
then completed in 31 seconds with 50 assertions, and 16 basic-family files in a
further 31 seconds with 133 assertions. The 31 complete original files therefore
contain 971 assertions (602 + 20 + 36 + 12 + 39 + 79 + 50 + 133); the historical
34 partial assertions are not counted again. The full default suite remains
incomplete. Times include JIT compilation and setup. Every retained run records
unchanged before/after manifests; the later groups verify all 326 archived Julia
source/test hashes at pre-BLAS-repair commit `39150792`. Boundary-Hessian,
raw-covariance-scale, and untrustworthy-SE warnings were retained rather than
suppressed; these regressions make no inference-calibration claim.

## 6. Tests of the Tests

Existing Julia tests ran unchanged; no new statistical test logic was added. The
server-side timeout produced explicit exit 124 and preserved partial results.
The later isolated Newton and each succeeding group retained their own completion
markers and unchanged input manifests. Input hashes were checked before loading or
fitting and reject mismatches; complete-file markers are written only after each
original `include` returns. The exact 326-hash archive check for the latest groups
is tied to pre-BLAS-repair commit `39150792`. This adds no broad verifier claim.

## 7a. Issue Ledger

Programme #563 remains open. This contributes G3/G7 evidence but closes neither.
Ayumi's issues 28 and 29 remain separate; no comments or issue closures were sent.

## 8. Consistency Audit

Recorded the source/test manifest for each numerical run and kept the verification
work distinct from the docs-only integration commit `5e9d5883`. The latest group
manifests bind to archived pre-BLAS-repair commit `39150792`; no retained result
qualifies the upcoming helper-repair head. Distinguished complete files from
passing partial test sets, retained the original full-suite and group timeouts,
and did not add the historical partial Newton assertions to the later completed
file. q4 among-axis profiles differ from Ayumi's Gaussian LSS `mu:temp_z` target.
The Mission Control update remained scoped and preserved 42 foreign files.

## 9. What Did Not Go Smoothly

The first SSH launch observation timed out after 15 seconds while the existing
job completed in 20 seconds; its terminal files were inspected and it was never
restarted. A later launcher stored its PID and returned normally. The four-file
group reached its five-minute cap before all files completed. Its partial Newton
output remains historical evidence only; the later isolated full file supplied
the separately retained completion result.

## 10. Known Residuals

The full package suite and opt-in R parity remain incomplete. Canonical-tree
profile feasibility, stable larger-bootstrap inference, control/gradient parity,
all capability cells, registered warm performance, recovery/cleanup, deployed
docs, and final Melissa reconciliation remain open. The two denied source files
remain untouched. Two known LSS boundary assertions remain unresolved and are
not counted as successes in this 31-file continuation. The accumulated records
predate the BLAS-helper repair and require later final-head qualification.

## 11. Team Learning

Memory receipt: existing programme, compute, and ownership rules applied; no new
memory mutation. Golden Set: no new numerical algorithm; the original regression
files provide the relevant checks. Scout Luna/low interpreted the requested
profile work; root Sol/medium executed bounded checks. Active agent-hours are
uninstrumented; this continuation used 530 Totoro wall seconds in total.

## 12. Cross-Product Coverage

Covers 31 complete original test files, plus retained historical partial Newton
output, on Linux with Julia 1.10.10, one Julia thread, and one BLAS thread. These
records predate the BLAS-helper repair. This slice does NOT cover full-suite
completion, native R comparison, the canonical Ayumi tree, calibration, automatic
thread policy, cold/warm benchmark wins, other platforms, or all inference
surfaces. All programme G0–G8 remain open.
