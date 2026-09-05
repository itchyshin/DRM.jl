# S4 coefficient comparison integrity

The legacy `tools/parity_fixture.R` compared an intersection of coefficient names
for Gaussian cases and the shorter vector length for other cases. Either could
omit a required coefficient. It also exited successfully after a failed table.

The revised runner requires equal, nonempty, unique named coefficient sets,
finite values, and the pre-existing tolerance. It normalizes only the separator
after a recognized distributional parameter, then compares every named value.
It does not equate punctuation inside predictor names. Unnamed raw payloads fail;
the raw Julia route must supply a matching `coef_names` vector. A failed row
causes exit1 after writing the completed table.

Both pure-R checks passed through actual unlazy execution with the worktree CWD
bound. Damaged observations include missing/extra/duplicate keys, nonfinite or
unnamed values, changed term names, invalid tolerances and numerical perturbations.
The wiring test initially failed before the three loops used the helper. Rose
independently reran and approved these limited checks.

Limits: this is coefficient/log-likelihood comparison integrity, not convergence,
SE, full-operation parity or loaded-build validation. Existing setup or extraction
errors can still terminate before a completed table; raw process logs remain
necessary. Syntax inspection alone does not prove runtime exit behavior.

## Recovered work obligation

Preflight found commit `034d93823b28bfd29ad72e0c16ae12e1b22eed31` on
`worktree-agent-a16e54e8043041b7b`, dated 2026-08-24, at
`.claude/worktrees/agent-a16e54e8043041b7b`. Its changes add a bivariate Gaussian
case and SE columns but still retain the partial coefficient comparisons. It is
not the complete fix implemented here. The branch, checkout and changes remain
untouched; its unique additions still require recovery/integration review.

No old result table is replaced by this repair. A fresh scratch pilot is separate
from historical evidence and cannot retrospectively validate those measurements.

## Executed runner controls

A fresh scratch run completed all eight legacy fixtures in 33.50s, with every
named coefficient and log-likelihood inside the existing 1e-4 thresholds. Six
use public R engine calls; the two bivariate cases use raw bridge payloads.
A second scratch run deliberately removed the first observed coefficient before
every comparison. It completed in 33.30s, retained all eight PARITY_FAIL rows,
and exited1. This proves the tested missing-coefficient failure path, not every
possible setup/extraction failure. Both used the isolated R library and requested one Julia/BLAS thread through
environment variables. Actual runtime BLAS counts were not captured; no
single-BLAS-thread or performance claim is made. No historical result table was overwritten.

Logs, result tables, process metadata, the exact damaged runner, source hashes
and artifact hashes are retained in coefficient-contract-pilot/. The historical
PARITY_PASS token means only this script's coefficient/log-likelihood tests; it
is not a programme-wide verdict or proof of convergence and all post-fit methods.
