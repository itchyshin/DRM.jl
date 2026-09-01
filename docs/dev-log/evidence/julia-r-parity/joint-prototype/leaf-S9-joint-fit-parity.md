# S9 native default-fit parameter parity (must remain red if either case loses)
OWNS: tools/check_joint_predictor_fit_receipt.py

- [ ] G1: Both prepared estimates match frozen native estimates within 4e-6
  CHECK: /opt/homebrew/bin/python3 tools/check_joint_predictor_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-fit-002.toml . --native-parity
  EXPECT: JOINT_FIT_RECEIPT_PASS cases=2 rows=320 native_parity=true
