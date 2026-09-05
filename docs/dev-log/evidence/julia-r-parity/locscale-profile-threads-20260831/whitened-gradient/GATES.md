# Moderate-model whitened derivative diagnostic

These gates do not replace the original finite-profile or independent boundary
reference gates. Each base/finite-difference point must have an accepted inner
mode, unchanged original-coordinate tolerance and predictors inside clamps.

CHECK: python3 run_capped.py <fresh UTC stamp>
EXPECT: status0, WHITENED_GRADIENT_MODERATE_PASS; <=60s.

Four deterministic Gamma/NB2 canonical/generalQ+Z cells, all7 coordinates,
three central-difference steps; max absolute difference<2e-6 at every step,
existing objective difference<1e-8, existing gradient difference<2e-6.
Negated derivative and missing nonidentity-Q normalization must be rejected.
Scratch dense inverse is a small-model oracle only, not a production design.
Independent high-precision boundary gate remains stricter and separate.
