# Independent review, 2026-08-31

Rose (existing Sol/high child) reviewed sampler hash 3fecf608b5c10dc6ca7706e2b279013ed0c5eaadfe9806b7f49253eb9b2a289d and fitter hash 8b023b49de6ccfb2563ce155572be785a0f5f471f15c3881463b97f8108cd701.
No static blocker: covariance/permutation, both latent axes, family conventions,
owned workspaces, exact input checks, and Beta endpoint failure retention.
The continuation uses a fresh cold baseline and candidate, unchanged gradient
tolerance, eight-ULP nonincrease allowance, one extra bounded attempt, original
result on failure, interrupt propagation, and warm-state reset. Successful and
legacy raw routes bypass it. At that review, the refit-test hash was
fd9ffe05af9c73a19dba4bd365f6696b01e51ccee509d08de4ea8f7ce06a12d3.
The final tested version is
59290926921570396a715ca3136d29e8919df0c6a707dd510e3b29c555c182fa;
it adds a fresh gradient check and the retained failed point as a negative
control, and makes serial_result local. Those later test edits were not part
of the earlier Rose review. Subsequently Rose explicitly reviewed this delta and found no blocker: the
packing, replayed seed, gradient threshold, rejected original point and objective
nonincrease are correct. The gradient check is independent of the returned
convergence flag, not a second independently implemented gradient oracle.
Rose also checked both final145/145 receipts and the16/16 profile receipt.

Review does NOT establish general bootstrap coverage, full bridge parity or
performance. Initial Gamma B2 used only 1/2 replicates; that original failure
and the NaN equality test artifact are retained. Subsequent final runners are
separate execution evidence, not retroactive changes to the review verdict.
