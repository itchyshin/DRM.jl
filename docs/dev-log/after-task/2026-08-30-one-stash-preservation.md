# One-stash preservation checkpoint

## 1. Goal
Prove recoverability and determine whether old R inference work still needs
integration, without deleting or overwriting anyone's work (programme #563).

## 2. Implemented
Added a bounded Git stash export/replay tool. Preserved two modified R files
privately, with saved base/index/working-tree versions and binary patches.

## 3a. Decisions and Rejected Alternatives
Retain the stash as superseded WIP. Its work already landed in 414b0f95, while
later main has important fixes. No source hunks recovered and nothing retired.

## 4. Files Touched
tools/parity_stash_probe.py, its corruption test, hash-only evidence, this report,
a check-log entry and the programme checkpoint. GPL snapshots remain outside
the MIT repository under the private recovery path recorded in the receipt.

## 5. Checks Run
Actual unlazy --reverify executed the optimized-Python corruption test and a
new saved-base replay. Exact blob and permission checks passed for both states;
one bounded gate met. Source stash and working repos were unchanged.

## 6. Tests of the Tests
Known Git hello-object control rejects changed bytes, executable mode and a
symlink. The replay itself corrupts each restored file and invokes the same
verifier, then restores its bytes. Explicit exceptions remain active with -O.

## 7a. Issue Ledger
Umbrella #563 remains open. This handles one disposition in the 18-stash census;
the programme's G1 recoverability gate remains open.

## 8. Consistency Audit
Rose checked immutable main/stash blobs and six saved versions independently.
All eight old inference functions and the Wald test block are already present.
Whole-file restoration would undo later setup, inference and test fixes.

## 9. What Did Not Go Smoothly
The first scratch proof preceded its executable acceptance leaf. Rose caught
Python assertions that could be disabled; these were replaced before final
verification. --approve alone reused a checked state; the final --reverify log
contains an actual RUN and successful exit, not that cached result.

## 10. Known Residuals
No full repository/history backup, off-Mac backup, retirement, all-stash proof
or numerical inference validation. Other dirty worktrees and stashes remain.

## 11. Team Learning
Memory receipt: original obligations and the source census informed selection;
no Codex memory edits. Golden Set: not applicable to this Git preservation tool.
Preserve exact versions first, then compare against immutable current main.

## 12. Cross-Product Coverage
This does NOT cover complete cleanup or parity. It covers two modified regular
files in one immutable R stash; the tool refuses unsupported stash shapes.
