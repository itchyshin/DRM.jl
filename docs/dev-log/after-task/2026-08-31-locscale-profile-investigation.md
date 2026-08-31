## 1. Goal

Investigate location-scale profile correctness and thread admission under #563.

## 2. Implemented

Reproduced ignored threading and false successful endpoint reporting. Retained
raw evidence and Rose's approved failure-status contract. Implementation is in
progress in a separately owned child slice; this report is an investigation.

## 3a. Decisions and Rejected Alternatives

Prioritize trustworthy endpoint failure reporting before threading. Preserve
signedInf plus explicit failure flags to match the generic public convention.
Keep numerical failure distinct from no crossing found in the searched range.
Do not extend the slow baseline past its approved cap or change optimizer budgets.

## 4. Files Touched

locscale-profile-investigation-20260831 and locscale-slow-profile-20260831 evidence,
this report, matching check-log and programme checkpoint. Child source/test edits
are separate work in progress; no protected Gaussian file was changed.

## 5. Checks Run

Pure default-budget quadratic root probe returns9.31e10 instead of1, residual
8.67e21; failed refinements return2 with residual3. Rose and root independently
reproduced, under one second each. Valid quadratic control converges. Gamma
threading red:12pass4fail in62.4seconds; two failures demonstrate ignoredthreads,
two finite-only assertions need correction. Original enabled slow-profile file
on Totoro reached900-second cap (901wrapper seconds, exit124) without completed
testset summaries. All327 immutable source hashes and runner hashes match.

## 6. Tests of the Tests

Valid root control distinguishes a numerical-method failure from a broken probe.
Frozen Git source is SHA-checked before extracted pure function execution. The
slow run's timeout and lack of completed markers cannot be recorded as a pass.
Stage1 exact fixture bytes were lost on revision; its log alone is retained.

## 7a. Issue Ledger

Programme #563 and G0–G8 remain open. Failure-disclosure implementation, model
regressions and deferred thread admission are explicit remaining obligations.
No issue closure, collaborator message, PR or deployment occurred.

## 8. Consistency Audit

SignedInf from the old profiler does not prove a mathematically unbounded interval.
The no-fit defect is independent of the slow-run timeout and is not an Ayumi-data
reproduction. Existing numeric wrappers, tolerance and likelihood stay preserved
in the approved repair contract. New source needs fresh evidence.

## 9. What Did Not Go Smoothly

The first NB2 threading fixture exceeded its intended five-minute cap and was
interrupted; the next fixture used a process-group deadline. Its exact initial
bytes were not retained. A child lease command printed GRANTED despite a denied
registry write; root established and independently listed a persistent exact
lease before the new source repair. These defects in execution are disclosed.

## 10. Known Residuals

Failure disclosure and threading are not fixed yet. The first enabled slow-profile
testset is incomplete; the second was not reached. Full-suite, cross-engine
inference/calibration, performance policy, recovery and documentation gates remain
open. No remote fit job remains running after the baseline timeout.

## 11. Team Learning

Memory receipt: repository and fresh probes; no Codex memory changed. Golden Set:
exact quadratic root and explicit failed-evaluation controls. RootSol/medium,
builderTerra/high, RoseSol/high. Agent-hours uninstrumented. BaselineTotoro901s;
localGamma62.4s; firstlocaltimeout exceeded its cap, exact wrapper timing absent.
Full remaining planning allowance80–150workinghours is low-confidence; current
profile repair4–8hours includes review/regressions, not a delivery guarantee.

## 12. Cross-Product Coverage

This covers two location-scale profile defects and bounded evidence. It does NOT cover repaired source, all model classes, Ayumi's full dataset, bootstrap parity,
full-suite completion, calibrated inference or performance wins.
