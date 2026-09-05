## 1. Goal

Continue source-bound package checks under programme #563 without treating a
capped or gated include as a pass. Preserve prior unfinished work and evidence.

## 2. Implemented

Retained exact runners, source manifests and raw outputs for structured and
location-scale checks on frozen source 479f1e06. No engine changes belong to this
receipt slice. The canonical profile threading repair proceeds separately.

## 3a. Decisions and Rejected Alternatives

Run bounded groups on Totoro with one Julia and BLAS thread. Retain timeouts;
do not rerun completed files or count disabled testsets. Treat minute-formatted
Test.jl durations as valid summaries. Run the three unfinished files separately.

## 4. Files Touched

Three evidence directories under docs/dev-log/evidence/julia-r-parity/:
structured-continuation-20260831, locscale-continuation-20260831, and
locscale-suffix-20260831; this report,
matching check-log and LOOP/checkpoint.md. The earlier BLAS report adds a dated
Mission Control application note; its queued receipt remains historical.

## 5. Checks Run

Structured: 15 complete files, 228 assertions across 40 testsets, 50 seconds,
exit 0. Location-scale: 10 files with substantive completed tests, 1,611 assertions
across 18 testsets, 301 seconds, exit 124. Both runs used Julia 1.10.10 on Totoro;
327 expected/before/after source hashes and path sets agreed. Rose independently
checked classifications and hashes. No complete original location-scale group
marker. The separate three-file suffix subsequently completed 55 assertions in
four testsets, 126 seconds, exit 0, with all 327 hashes bound to immutable
479f1e06 Git objects rather than the changing implementation worktree. Rose
independently approved the suffix receipt.

## 6. Tests of the Tests

Original package tests were unchanged. The time cap produced a retained nonzero
exit and incomplete classification rather than a pass. The profile file's two
explicit skip messages are recorded as unmet tests despite its include-completion
marker. No new general verifier is claimed; raw assertions and manifests remain
available for independent inspection.

## 7a. Issue Ledger

Programme #563 and all G0–G8 gates remain open. No issue was closed, and no public
message, PR, release or deployment occurred. The unfinished suffix has a separate
3–10 minute estimate and 600-second cap; it cannot borrow this receipt's verdict.

## 8. Consistency Audit

The 228 and 1,611 assertions are disjoint original test groups. Historical
pre-BLAS tests remain bound to their earlier source. Slow profile tests are not
counted as passed. Mission Control application receipt records the final scoped
commit with empty unchanged foreign staging, distinct from its earlier guard. A later exact three-field MC update at b5e2099
records the new receipts and correct integration resume paths; served fields
match, and unrelated staged state was empty and unchanged.

## 9. What Did Not Go Smoothly

The location-scale group exhausted its cap. Two NaN-gradient early-termination
warnings remain visible and unresolved at this evidence scope. A default include
silently skipped substantive profile coverage except for its INFO messages.
The first suffix launch was blocked by the filesystem/network sandbox; it ran
only after the existing-socket operation received escalation approval.

## 10. Known Residuals

The three-file suffix passed; both formerly skipped DRM_SLOW_TESTS profile blocks
now run separately on the frozen baseline, estimate 5–15 minutes, cap 900 seconds.
They have no terminal verdict yet.
The remaining default suite, native-R/direct/bridge inference comparisons,
calibration, performance policy, cleanup and documentation deployment remain open.
Neither previously denied Gaussian source file was changed.

## 11. Team Learning

Memory receipt: current repository and raw receipts supplied technical facts;
no Codex memory was changed. Golden Set: original unchanged assertions, explicit
completion markers, timeout exits and skip messages protect evidence accounting.
Root Sol/medium; Rose Sol/high; scout Luna/low; builder Terra/high works separately.
Agent-hours are not instrumented. The first two runs used 351 Totoro wall seconds; the suffix adds 126 seconds
(477 total). The slow profile pilot has separate unfinished compute accounting. No DRAC compute was needed.

## 12. Cross-Product Coverage

This receipt covers the named structured and partial location-scale package
checks on frozen source 479f1e06. It does NOT cover a full-suite pass, skipped
profiles, cross-engine parity, calibrated intervals, warm-workflow speedups,
current post-repair source, worktree retirement or live documentation deployment.
