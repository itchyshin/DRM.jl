# Family and random-effect continuation

Fifteen original files completed on Totoro Julia 1.10.10, one Julia and one BLAS
thread: 91 assertions across 16 testsets, 65 seconds, exit 0. All requested file
markers and final group marker appear. No skips or warning/error lines appear
in the retained log. Every one of the 327 source/test hashes matches immutable
479f1e06; before/after manifests are identical and runner hashes match the log.

This covers the original NB2, beta, Gamma, Student, lognormal, beta-binomial and
binomial random-effect/slope regressions and summary methods listed in plan.json.
It does not establish full-suite, cross-engine parity, coverage or speed claims.
The independent slow-profile run remains outside this receipt.
