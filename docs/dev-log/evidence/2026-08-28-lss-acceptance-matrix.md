# Acceptance matrix — Ayumi's model ladder through `engine = "julia"` (owner gate)

Owner instruction 2026-08-28: *"Do not write to Ayumi till we got everything working for her
models — not just point estimates but SE, CI."* This is that gate, measured on the final PR-#547
head (includes #548/#549/#550/#555/#556). Simulated 200-species clade, `JULIA_NUM_THREADS=8`,
`threads = TRUE`; ΔlogLik is julia − tmb on the identical data; profile/bootstrap target is
`fixef:sd_phylo:temp` where the block exists, else `fixef:mu:temp`.

| model | ΔlogLik | SEs finite | Wald CI | profile CI | profile s | bootstrap CI | refits | boot s |
|---|---|---|---|---|---|---|---|---|
| M2  | 0 | ✅ | ✅ | ✅ | 3.6 | ✅ | 183/199 | 2.9 |
| M3  | 0 | ✅ | ✅ | ✅ | 3.7 | ✅ | 199/199 | 17.1 |
| M5  | 0 | ✅ | ✅ | ✅ | 3.6 | ✅ | 199/199 | 16.8 |
| M6  | 0 | ✅ | ✅ | ✅ | 4.8 | ✅ | 199/199 | 32.4 |
| M6q | 0 | ✅ | ✅ | ✅ | 30.0 | ✅ | 198/199 | 147.3 |

History that matters: the FIRST run of this matrix had one red cell — M2's `sigma` SE was NA —
which turned out to be the sparse phylo route's vcov being `fill(NaN, …)` outside the mean block
(#556, fixed; the repaired SE matches drmTMB to 5 digits). M2's 183/199 bootstrap refits reflect
`failures = drop` on scalar-phylo refits near the variance boundary; the CI is finite and the
failure count is reported, not hidden.
