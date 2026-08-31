# Sparse LSS profile cost diagnostic

This is a diagnostic of three synthetic Gaussian ML models with the M6q design
shape: five coefficients each for mean, residual log SD and phylogenetic log SD.
It is not Ayumi's dataset, a complete confidence interval, or a matched R timing.
The sparse route was explicitly selected even below its automatic 500-group
threshold. Each tree has two observations per tip; fixtures use seed 56328.

| Species | Nuisance iterations | Gradient requests | Actual objective calls | Constrained solve seconds | Converged |
|---:|---:|---:|---:|---:|:---|
| 64 | 47 | 143 | 4,148 | 0.546 | yes |
| 128 | 743 | 2,007 | 58,204 | 4.672 | yes |
| 256 | 1,000 | 2,743 | 79,548 | 11.115 | **no** |

The target is the first linear mean slope, fixed half an estimated standard error
above the fitted estimate. All other 14 coordinates are optimized. The exact
Gaussian objective independently agrees with a dense observation-covariance
calculation, with absolute differences 9.95e-14, 1.05e-12 and 5.68e-12. All three
reference fits converged. The last constrained solve did not; its objective must
not be mistaken for a certified profile endpoint. Numerical nuisance-score maxima
were 6.21e-7, 4.46e-8 and 1.22e-7. A small score and an optimizer convergence flag
are different diagnostics; the failure remains recorded.

## Confirmed mechanism

No analytic gradient is attached to these fitted objects. ForwardDiff cannot
propagate through their Float64 workspaces, so the profiler selects finite
differences. Fourteen nuisance coordinates require two perturbed objective calls
each, plus the base evaluation: 29 calls per gradient request. In every receipt,
actual calls equal `29 * gradient_requests + 1` exactly. Generic profiling currently
consumes optimizer minima without checking this convergence flag.

The retained full function includes compilation in each fresh process. The solve
times above include first-use wrapper/optimizer compilation, so they are **not warm
full-workflow measurements**. Five warmed objective calls separately had median
times 49.8, 70.1 and 204.8 microseconds, and Julia-accounted allocations 93,248,
183,888 and 363,408 bytes. Total constrained-solve allocations were roughly
0.44, 10.78 and 28.99 GB cumulatively; these are not peak RAM or CHOLMOD memory.

## What this changes next

Exact coefficient targeting is already repaired. This pilot now demonstrates the
finite-difference multiplier and an unchecked termination at a modest tree size.
Required follow-up: nuisance-solve status/score validation, endpoint status
transport, and retaining safe analytic gradients with private numerical workspaces.
The two previously denied engine files remain untouched; do not implement an
alternate-location workaround. No tolerance relaxation or iteration-budget waiver
was used to turn the failed solve into a success.

Before publishing a performance comparison, measure warm complete native-R,
direct-Julia and R-bridge workflows with matched inputs and resources. Retain ties,
losses and solver failures. Do not extrapolate these three points to 10,970 species
or claim the measured multiplier explains all of Ayumi's two-hour timeout.

## Separate identity obligation found during review

The direct LSS frontend currently uses `_group_index` (first-seen data order)
for phylogenetic groups at `gaussian_lss.jl` lines 327 and 668, whereas the
phylogenetic covariance uses tree-tip order. The single-component and multi-component
routes both need a name-to-tip mapping regression and repair. The R bridge sorts
its observations by serialized tip order, so this does not imply its sorted
workflow has the same defect. Quoted labels alone do not repair direct-LSS group
identity. This is a distinct required frontend obligation, not a justification to
edit the previously denied numerical engine files.

## Provenance and compute

Mac, Julia 1.10.0, one Julia thread and one BLAS thread. Runner and every Julia
source file are SHA256-stamped before/after in each TOML receipt. These receipts
remain tied to those development bytes; later parser edits do not retrospectively
qualify a new whole-source revision. Each process had a 120-second outer hard stop;
none reached it. Raw logs and failure status are retained.

Totoro and Fir existing SSH ControlMaster sockets were verified live. Totoro's
load averages at inspection were approximately 30/31/31. Julia is outside its SSH
PATH but installed at `/home/snakagaw/.juliaup/bin/julia`, with 1.10.10 and 1.12.6
binaries available. No remote job, package installation or source transfer ran.
Use Totoro for the next measured CPU campaign; use DRAC allocations when warranted.
No run longer than 30 minutes is authorized by this diagnostic.

`check_profile_cost_receipt.py` validates diagnostic accounting and independently
checked objective agreement, retains nonconvergence, and rejects damaged receipts.
Its successful exit certifies receipt consistency only, **not successful inference**.
Programme correctness and performance gates remain open.
