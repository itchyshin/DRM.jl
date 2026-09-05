# Location-scale continuation — partial, timed out

Source 479f1e06, Totoro Julia 1.10.10, one Julia and one BLAS thread. The 300-second
cap terminated the group after 301 wrapper wall seconds, exit 124. All 327
source/test hashes matched the expected manifest and remained unchanged.

Ten files completed substantive tests: 1,611 passing assertions across 18
summaries. Eleven include-completion markers appear because test_locscale_profile.jl
was included but skipped BOTH substantive testsets under DRM_SLOW_TESTS=0.
Neither the reference profile check nor the public full-vector profile check
passed in this run. Minute-formatted Test.jl durations are included in the count.

The group entered test_locscale_structured.jl but did not finish it. The sigma-axis
and nonconstant-sigma files never started. A separate suffix run must not rerun
or double-count the completed files. Its results are separate evidence.

Two warnings reported early termination due to a NaN gradient. They are retained
in the raw log; no assertion failure is printed, but they are not dismissed or
claimed to establish convergence. This is not a complete-group, full-suite,
native-R parity, calibrated-inference or performance pass.
