# Current-run provenance refresh

`run-005.log` remains the historical result for runner SHA-256
`5e31621…`; the two wording corrections changed the runner without changing its
calculation. This fresh execution avoids conflating those bytes.

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. tools/lss_boundary_diagnostic.jl \
  --fixture=original-test-bytes
```

`run-006.log` completed in 19.39 seconds. It reports one Julia and one actual
BLAS thread, source SHA-256
`4465956f8786436b72827366032178f1a81f0b76582df7f232d155ed624191f9`,
fixture test SHA-256
`9e8f2522841c1294d4cfac6aa11d26fe7c8bd2b1c6d501f2fe22b8391e283068`,
and current runner SHA-256
`447f15e595da3b246a9fa626a9f0375867619027f2baf9599d0185b9a5c6c2df`.

It reproduces the two strict raw-coordinate discrepancies (4.5298009477 and
0.8610680164) with byte-verified fixture inputs and an independent named-
covariance likelihood. This is diagnostic evidence only: neither the very
small phylogenetic covariance terms nor flat raw log-SD coordinates waive the
strict coefficient gate or establish structural nonidentifiability.

## Independent verdict

Rose (Sol/high) reviewed run006 and approves the bounded diagnosis: both original
strict coefficient failures remain reproduced and OPEN. Agreement of named
covariance likelihoods and tiny phylogenetic variance does not waive coefficient
parity or establish general structural nonidentifiability. No engine/test edits.
