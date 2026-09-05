# Tree bootstrap integration evidence

Final runs: tree-threads1-20260831T210056Z (18/18),
tree-threads4-20260831T210121Z (18/18),
actual-r-threads1-20260831T210144Z and actual-r-threads4-20260831T210213Z
(both 2/2 draws, original comparison tolerance 1e-12),
neighbours-threads4-20260831T205027Z (858/858), and the separately retained
pure-r-julia-bootstrap-tree-20260831T211100Z.log (16 assertions).

Earlier failures and intermediate successes are retained. Cache EPERM is an
environment failure. The real R CSV comparison failed despite successful
refits; csv-roundtrip.md explains the three one-ULP differences. Final binary
fixtures preserve the original Julia values; no tolerance or seed changed.
Some initial R routing failures existed only in tool transcripts, as the R
after-task report states; no raw logs for them are invented here.

Run python3 verify.py to check retained artifacts. Drivers retain absolute
historical checkout/scratch paths; relocate their paths deliberately if
replaying. JSON receipts record before/after source hashes, loaded paths and
commands. verify.py checks artifact integrity, not statistical correctness.
No GPL implementation source is vendored; R drivers call the public package.
Timing is local bounded test runtime, not a speed comparison.
