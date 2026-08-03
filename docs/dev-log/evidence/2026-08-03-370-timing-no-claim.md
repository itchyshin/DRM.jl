# #370 timing cells — honest no-claim

Date: 2026-08-03 · Arc 3 of Ultra Plan #370

## Decision

Per G0-approved default (Ada): allow honest **timing not measured — no claim**
so coefficient-scale parity can ship without inventing a speed headline.

## Per-cell status

| Cell | Timing claim |
|---|---|
| gaussian-locscale | timing not measured — no claim |
| gaussian-bivariate-rho12 | timing not measured — no claim |
| robust-student | timing not measured — no claim |
| count-nbinom2 | timing not measured — no claim |
| proportion-beta | timing not measured — no claim |
| meta-analysis-V | timing not measured — no claim |

## Rose fence

- No “Julia is ~Nx faster” language for these cells.
- Do not re-use the verified q=4 PLSM 2.18× cell (`report/comparison-grid.md`)
  as evidence for these fixture families.
- A future measured edge needs a retained artifact (method, machine, n, both
  sides) before any speed claim lands in docs/README.
