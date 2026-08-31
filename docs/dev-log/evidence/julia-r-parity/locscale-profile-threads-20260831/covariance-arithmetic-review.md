# Covariance-gradient arithmetic diagnosis

PLATFORM: Codex. Branch: `codex/parity-integration-20260831`.
Root lease: `codex:01a05261-julia-r-parity`; evidence paths only.
Other checkout lanes are untouched. Production numerical files and the original
unwired profile-threading test are unchanged.

## Measured result

Two fixed-outer diagnostics evaluated all four retained Gamma nuisance endpoints;
neither re-ran an outer optimizer. The original input SHA is
`d8727b67ae76c66fcc76cdd9f672b1f2bed72c165bf47e526caf50f769998434`.
The first took 6.53 seconds (15-second estimate, 60-second cap); the second took
4.94 seconds (10-second estimate, 30-second cap). Both exited normally. JSON
receipts bind exact commands, scripts and unchanged source/input hashes.

The first computes current production modes, selected-inverse blocks and adjoints,
then holds those Float64 inputs fixed while recomputing covariance derivative
construction and contractions in 256-bit arithmetic. This isolates downstream
arithmetic sensitivity; it does not validate those upstream inputs.

| Endpoint | Production L21 derivative | Lifted-input derivative | Production minus lifted |
|---|---:|---:|---:|
| Intercept lower | -3.58192e-6 | 3.18210e-7 | -3.90013e-6 |
| Intercept upper | 4.98837e-5 | 1.69376e-5 | 3.29461e-5 |
| Slope lower | -8.38338e-5 | -5.78139e-6 | -7.80524e-5 |
| Slope upper | -7.77115e-4 | 4.95509e-6 | -7.82071e-4 |

The diagnostic's Float64 dot/sum order differs from production's scalar order.
Both its Float64 result and the actual production component are retained; they
are not asserted bit-identical. "Held fixed" means within this comparison,
not independently validated or recovered historical intermediate values.

## Minimal algebra experiment

With log-Cholesky coordinates `(u,c,v)`, define
`A=exp(-2u)+c^2*exp(-2(u+v))`, `B=-c*exp(-u-2v)`, `C=exp(-2v)`.
The inverse covariance is `[A B; B C]`. Differentiate those entries directly:

```
dP/du = [-2A -B; -B 0]
dP/dc = [2c*exp(-2(u+v)) -exp(-u-2v); -exp(-u-2v) 0]
dP/dv = [-2c^2*exp(-2(u+v)) -2B; -2B -2C]
```

The normalization derivatives are exactly `G*(1,0,1)`. This avoids constructing
`-inverse_covariance * d_covariance * inverse_covariance`.
Rose independently checked these identities before the second diagnostic.

Rebuilding the direct derivatives in Float64 versus 256 bits from the exact
saved binary coordinates, while still holding mode/selected-inverse/adjoint
inputs fixed, gives L21 differences of about `9.94e-10`, `-7.88e-9`, `9.82e-9`
and `-5.87e-9`. This supports a small derivative-construction repair experiment;
it is not yet proof of the correct marginal gradient or of converged profiles.

## Independent review and remaining requirement

Rose (explicit Sol/high, read-only) reviewed first diagnostic SHA
`cb89792d8bf4c7854efa24a1c172f72d53cdbcf1f82805faf73ab987e84eface`:
the Q=I contractions, canonical third-derivative mapping and sign conventions
are correct; lifting before derivative construction establishes arithmetic
sensitivity but preserves upstream numerical error. The proposed direct inverse
derivatives are algebraically correct. No production repair was approved from
this evidence alone.

Next: finish the independent whitened Gamma fixed-outer reference, including
density/normalization negative controls and precision gates, then compare
directional derivatives at all retained endpoints. Keep the original finite-CI
fixture and optimizer tolerances unchanged. S11 and global G0–G8 remain open.
