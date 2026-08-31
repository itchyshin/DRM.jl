# Enabled slow-profile baseline — incomplete at cap

Both original opt-in testsets were enabled with DRM_SLOW_TESTS=1 on frozen
479f1e06. Totoro Julia 1.10.10, one Julia and one BLAS thread. Estimate 5–15 minutes;
hard Julia cap900 seconds. The wrapper finished after901 seconds, exit124.
No completed testset summaries or file/group completion markers were printed.
The termination trace is inside the first testset (test_locscale_profile.jl:51);
the second public full-vector testset was not reached. This does not imply zero
assertions executed: incomplete Test.jl testsets have no final assertion summary.

All327 expected/before/after hashes match immutable source, and runners match
logged hashes. The trace was in the constrained nuisance/root-refinement path;
it is not a cost decomposition or diagnosis of the dominant bottleneck.
The raw allocation count is retained, not used as a benchmark headline.
No continuation, automatic extension or replacement run was launched.

The separately reproduced endpoint failure-disclosure bug remains an independent
finding, not proven by this timeout. No profile correctness, full-suite, native-R
parity, coverage or warm-performance pass is claimed.
