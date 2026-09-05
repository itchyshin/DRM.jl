# Independent review receipt — bounded and provisional

Reviewer: explicit Sol/high child /root/rose_whitened_oracle. Requested routing
recorded by dispatch; active agent-hours are not instrumented.

The first direct-precision implementation (3025e2e2) has correct algebra and
normalization G*(1,0,1); its retained 24/24 numerical regression agrees with the
independent four-terminal whitened-Laplace reference. Rose found unnecessary
intermediate overflow at lambda=(-180,0,-180). A new regression first failed
four checks (24 existing checks passed), then scaled_c=c*exp(-(u+v)) avoided
squaring the exponential before multiplying by zero.

Hardened source c0369528 and test60d13d50 were independently reviewed: algebra
and finite-range regression approved on inspection; no universal Float64-range
claim. Root retained green-cache170623Z:28/28,10.572s,unchanged input hashes.
Cache EPERM attempts remain failures, not numerical evidence.

This is NOT full-slice approval. Profile-status one/four-thread covgrad001 each
has76pass1error in _ls_vcov; original finite-CI fixture170646Z has0pass1error
before profile_result. The strict classifier rejects this and the original
12pass4fail baseline. Finite CIs and threading remain required.

Literature review additionally corrected two statements: quadratic dependence
extends the linear location-scale association model; conditional residual
variance must condition on the random scale effect. Both edits are present in
2026-08-31-location-scale-literature.md. No Gaussian literature result validates
the Gamma inference route.
