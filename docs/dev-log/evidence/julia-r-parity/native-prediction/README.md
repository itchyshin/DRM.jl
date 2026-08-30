# Native prediction repair evidence

Latest matched receipt: joint-public-004.json. Both public adapters PASS;
strict native comparison remains FAIL at unchanged4e-6. The prediction defect
is independently repaired; remaining errors reflect different fitted parameters.
Use the sibling joint-bridge evidence for original public001–003 failures.

Latest fresh native neighbours: native-prediction-neighbours-002.json, all three
PASS in3.002seconds, not a warm benchmark. The ordinal/categorical fixtures have
nondegenerate state probabilities. The neighbour oracles have complete response,
unweighted fixed-effect Gaussian scope; they are not covariance/recovery evidence.
All native RDS files live in drmTMB/docs/dev-log/evidence/julia-r-parity/native-prediction.

Run from the drmTMB worktree (no fits):
```
Rscript tools/check-native-joint-prediction.R docs/dev-log/evidence/julia-r-parity/joint-bridge/joint-public-003.rds
Rscript tools/test-native-joint-prediction.R docs/dev-log/evidence/julia-r-parity/joint-bridge/joint-public-003.rds
```
The latter validates10malformed output shapes and4damaged model states. Earlier
red checks, the initial wrong-slot damage failure and all numerical failures are
retained. Source/runner hashes are in receipts; do not substitute later source
for those exact inputs. No whole-programme gate is closed by this directory.
