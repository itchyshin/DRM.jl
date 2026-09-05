# Required next slice: paired location-scale marginal bootstrap

Read-only Terra/high scout, independently grounded in current Julia source.
No patch or bootstrap run yet. The public coupled frontend stores :mu, :sigma
and :recov, not :resd. Public recov order is [logL11, logL22, L21]; engine order
is [logL11, L21, logL22] (locscale_frontend.jl:90-115).

bootstrap_result calls _marginal_simulator, but its ordinary single-axis branch
uses re_sd and receives an empty dictionary for this fit. It returns nothing
(inference.jl:1820-1889). _bootstrap_result then falls back to simulate(fit)
(around1990), whose means/scales contain fixed effects only. Thus both random
mean and log-scale effects can be omitted while refitting still succeeds.

Implement a dedicated canonical LocScaleObjective marginal sampler before the
generic fallback. Draw the joint group state using Q as PRECISION via triangular
solve, then L and both eta/psi loadings; never use fitted-mode seeds. Preserve
interleaved groups, covariance packing and family parameterization.

Start with a no-fit failing distribution test: existing simulator is missing;
fixed RNG/manual Q^-1 and L construction must validate both group effects and
nonzero L21. Cover Gamma/NB2/Beta/BetaBinomial, Q=I and nontrivial sparse Q.
Then bounded direct B=2 and iid bridge smoke; no coverage claim from B=2.

Bridge non-Gaussian bootstrap currently omits tree forwarding (bridge.jl:234-246),
although bootstrap_result accepts K/A/tree. Verify that route separately; existing
non-Gaussian tests are one-axis Poisson, not coupled location-scale coverage.
The paired profile route is reachable through bridge, but current tests are
status/dispatch tests, not complete cross-engine numeric parity.
