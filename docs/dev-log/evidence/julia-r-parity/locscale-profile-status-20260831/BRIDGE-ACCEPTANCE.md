# Bridge endpoint diagnostic message acceptance

OWNS: root src/bridge.jl _bridge_profile_outcome and test/test_bridge_profile_status.jl.
CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_bridge_status_pure.py old
EXPECT: exit1, 14pass/3fail for missing selected endpoint reason/candidate/residual.
CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_bridge_status_pure.py current
EXPECT: exit0, all17assertions; selected-row filtering, nuisance details, no-crossing
and older result fallback unchanged. Pure helper tests, no fits, each60s cap.
Final check: run the same file through actual DRM module after child source is ready.
No new payload keys, numerical model, interval transform, or R warning semantics.
