# Approved bounded implementation contract — estimated local descent

Rose Sol/high and parent approved implementation after the full-input high-
precision diagnostics. This is finite numerical validation, not a new universal
proof obligation for libm. No certified-descent/global-optimum claim is allowed.

Keep current four-ULP fast polishing and all full-undamped, representable-local-
step, finite, positive-predicted-descent, strict-gradient-reduction, unchanged
stationarity and clean-PD guards. A stable-comparison fallback uses compensated
2/4/8-point Gauss-Legendre evaluation of the exact smooth integral identity.
Freeze the estimated margin before validation:

E = 8*max(abs(Q8-Q4), abs(Q4-Q2)) + 64*eps(Float64)*S.

S records magnitudes before directional gradient, prior and quadrature
cancellation. Account for prior matrix-vector cancellation and separate data
contributions. Accept only finite Q8+E<0. Missing/ambiguous estimates, unsupported
families and clamp boundaries/crossings refuse this fallback and retain ordinary
backtracking. Do not remove any model/workflow from the programme denominator.
Use immutable quadrature nodes and private accumulators; no production BigFloat
precision mutation or new dependency.

Finite validation: all five diagnosed pairs with independent128/256bit NLL
references; correct signs, relative discrepancy<=1e-4 for resolved nonzero
differences and observed error within estimated margin. Also uphill/opposite,
zero/ambiguous, too-large displacement, failed stationarity/PD, both families,
varied observation counts/general loadings/coupled priors, row reversal, additive
constants, interior/near-clamp/crossing. Retain failures; do not inflate constants
against failing fixtures. Then rerun original gradient/recovery and1/4thread
profile checks unchanged. Current source572f46bb is NOT integrated acceptance.
