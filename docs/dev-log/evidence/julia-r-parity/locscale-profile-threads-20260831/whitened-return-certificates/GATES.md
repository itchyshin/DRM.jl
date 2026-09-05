# Fixed-point return certificate gate

**Estimate:** about 10 seconds. **Hard process-group cap:** 30 seconds.

The script reads only the immutable neighbor-selection and frozen-design artifacts.
It makes no call to `DRM`, no mode solve, and no outer fit.  For each selected
representable `a64`, it independently reconstructs the intended BigFloat
`B`, `Q kron I`, and `P = B^-T (Q kron I) B^-1`; evaluates the full Gamma
joint objective, gradient, and undamped Hessian; and compares the selected
objective against the prior returned `a64`.

Prospective numerical gate per row, recorded but not used to suppress failures:

`||g_a||2 <= 1e-9 * (1 + ||a||2)`, undamped Hessian PD, strict `-30 < eta,psi < 30`,
and 128/256-bit consistency (`|J128-J256|` and `|norm(g128)-norm(g256)| <= 1e-20`).

This certificate cannot repair or erase the prior three of four returned-a
failures, and it is not a solver or inference result.
