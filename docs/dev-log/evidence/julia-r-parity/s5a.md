# S5a sparse precision and grouped-gradient proposal

Status: **PROPOSAL ONLY — no protected `src/` file was changed.**

The core-write tool rejected the earlier source patch. The exact denial was
sent to the coordinator. A fresh user approval after that risk notice is needed
before applying either source change below.

## Proposed source-only patch after approval

1. In `src/gaussian_structured.jl`, inside `_phylo_aug_comp`, replace only the
   dense conversion with:

   ```julia
   Qs = dropzeros!(sparse(Symmetric(Q, :U)))
   ```

2. In `src/gaussian_sparse_lss.jl`, make the identical replacement at its
   precision initialisation. This preserves the existing upper-triangle sparse
   convention and the same Cholesky/objective/scale/estimator data semantics.

3. In the sparse-LSS `d_g` calculation, retain the existing term
   `diag_ZtWZ[r_node] * Hinv[r_node, r_node]` unchanged. First accumulate the
   existing `u[i] * Zâ[i]` by `gidx[i]` in observation order, then subtract the
   accumulated group value. Do not replace this with a residual `V^-1`
   expression.

## Test contract

`test/test_sparse_precision_storage.jl` uses stdlib `Random`, covers 1,024 and
2,048 tips for the `_phylo_aug_comp` allocation guard, and records that this is
currently the first conversion site only. The sparse-LSS route is checked on a
heteroscedastic, two-alpha, interleaved/unbalanced fixture with four unobserved
tree leaves. Its sparse objective and finite-difference stationarity are compared
against an independent dense covariance objective.

The original source already failed the allocation guard:

| Tips | Original warmed allocation | Linear bound |
| ---: | ---: | ---: |
| 1,024 | 35,519,760 bytes | 20,480,000 bytes |
| 2,048 | 138,256,064 bytes | 40,960,000 bytes |

The ignored red log is `.unlazy/julia-r-parity/red/S5a-original.log`.

## Current test receipt on unmodified source

`julia --project=. test/test_sparse_precision_storage.jl` completed the small
precision oracle and strengthened sparse-LSS oracle first: 5/5 and 6/6 checks
passed, respectively. The final allocation gate then failed exactly as intended
on the unmodified dense conversion (the two values in the table above). The
source patch is therefore still required; this is not a green S5a result.

The small LSS fit emitted a boundary-Hessian pseudo-inverse warning for its two
scale-side coordinates. The test neither consumes those standard errors nor
claims inference validity; it checks only the objective and its finite-difference
stationarity against the independent dense covariance oracle.
