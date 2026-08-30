# S9 prepared joint predictor prototype

**Owns:** `src/joint_missing_predictor.jl`,
`test/test_joint_missing_predictor.jl`,
`docs/dev-log/evidence/julia-r-parity/joint-prototype-contract.md`, and this
leaf. Root owns module inclusion, exports, integrated test wiring, native
fixtures, and live evidence.

**Scope:** prepared fixed-effect Gaussian-response prototypes with one missing
Gaussian or Bernoulli predictor. This is not formula or R admission and does
not complete the 24-cell missing-predictor denominator.

- [x] G1: source parses into `DRM`.
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM; if !isdefined(DRM, :PreparedJointModel); Base.include(DRM, "src/joint_missing_predictor.jl"); end; println("S9_JOINT_PARSE_PASS")'
  EXPECT: S9_JOINT_PARSE_PASS
  CWD: /private/tmp/drm-parity-20260830/DRM.jl
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=S9_JOINT_PARSE_PASS
  TIMEOUT: 120
- [x] G2: local prepared likelihood, moment, derivative, Hessian, extreme, invalid-input, and in-process optimizer controls pass.
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_joint_missing_predictor.jl
  EXPECT: S9_JOINT_PURE_PASS
  CWD: /private/tmp/drm-parity-20260830/DRM.jl
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=finite extremes and fail-closed input validation |   16     16  0.2s | S9_JOINT_PURE_PASS
  TIMEOUT: 120

This leaf covers local source/focused Julia checks, including one optimizer
smoke. It does not authorize native-R fitting or R/TMB compilation. Separate
root-owned leaves cover common-parameter evaluation and two prepared Julia fits.
