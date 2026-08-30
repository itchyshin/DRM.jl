# Joint missing-predictor R bridge development evidence — issue563

Two Gaussian-response cases (Gaussian/Bernoulli predictor) pass public bridge
adapters and independent mathematical/output checks. **Native parity FAILS**.
Public003 is the latest receipt;002and001 retain earlier states and failures.
Elapsed003=19.747seconds including startup and both engines: NOT a warm benchmark.
The checker requires current source/runner hashes; do not relabel old receipts
as evidence for changed sources. Direct reference: joint-direct-bridge-001.toml.

Full native fit RDS artifacts remain in the GPL drmTMB repository, not this MIT
repository. Only generated data/numerical outputs and diagnostics are retained
here. R source remains in drmTMB. Rose's review scope is bounded in rose-review.md.
The required4e-6 comparison and all programme G0–G8 remain open.

Checker invocation from DRM.jl:
```
python3 tools/check_joint_bridge_public_receipt.py docs/dev-log/evidence/julia-r-parity/joint-bridge/joint-public-003.json test/fixtures/joint_missing_predictor/native_reference.toml docs/dev-log/evidence/julia-r-parity/joint-bridge/joint-direct-bridge-001.toml /private/tmp/drm-parity-20260830/drmTMB /private/tmp/drm-parity-20260830/DRM.jl
```
Add --native to exercise the REQUIRED failing native gate. It is not optional
programme scope. Run test_joint_bridge_public_receipt.py with the same arguments
normally and with python3 -O to exercise20deliberately damaged receipts.
