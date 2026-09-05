# Frozen complementary oracle grid

Declared before the first run of `verify_estimated_change_varied.jl`.
This complements the five retained failure steps; it cannot replace them.

- Families: Gamma and NB2, interior predictors.
- Observation counts: 5, 17, 64; three coupled groups in every case.
- General mean/scale loadings; dense prior at n=5, sparse prior otherwise.
- Fixed deterministic input expressions in the probe; no parameter fitting.
- Small steps in both gradient directions, original and reversed rows, objective
  shifts 0 and 10^12: 48 comparisons against independent likelihood formulas.
- Reference precision: 128 and 256 bits; require agreement within relative
  1e-16 or absolute 1e-30, whichever is larger.
- Every estimate: correct sign, relative discrepancy <=1e-4, observed error no
  larger than the unchanged engineering margin; downhill margin negative and
  uphill margin positive. Do not tune cases/constants after a failure.
- Estimate: <=60 seconds locally; hard cap120 seconds. One Julia thread and
  one BLAS thread. Source must be frozen before execution; retain source/probe
  hashes before and after. No inference or performance claim follows.

CHECK: run the probe under its bounded runner.
EXPECT: `VARIED_ESTIMATED_CHANGE_OK`, exit0, all comparisons pass and hashes
unchanged. Any error/refusal remains a failed case and is retained.

Test of the test: set `DRM_ESTIMATED_CHANGE_NEGATIVE_CONTROL=1` in a separate
process. The probe explicitly corrupts each returned estimate by1% while keeping
source and independent reference unchanged. EXPECT nonzero exit and numerical
comparison failures. Do not mistake this expected failure for solver acceptance.
