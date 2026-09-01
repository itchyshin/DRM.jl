# Location-scale profile status repair — bounded verification complete

Parent: DRM.jl #563; all programme gates remain open.

- bridge-status-red/green: extracted helper, 14 pass / 3 expected fail versus
  17 pass. Not an actual-module result by itself.
- r-profile-status-green: real public R row conversion with mocked inference,
  14 pass; damaged adapter negative control has six expected failures.
- module-1threads: first attempt blocked by Julia precompile-cache permission,
  before test execution. Retained as an infrastructure failure.
- module-1threads-002: actual DRM module, 65 status +17 bridge +17 BLAS assertions
  and one final BLAS restoration assertion; 41.71s, exit0, unchanged input hashes.
  This is a pre-review candidate result, not final repair acceptance.
- rose-draft-review: four blocking issues and test refinements, repaired in the final source.
- final003/final004 module receipts:196/200 assertions at one/four threads, including deterministic generic warning coverage. All four local slice gates met; see rose-final-review and final-verification.
- docs/: strict52page source build passed in152.17seconds. No new HTML visual/deployment verdict.

The small Gamma model had one attempted interval row, zero certified endpoints,
zero no-crossing endpoints and two not_converged arms. Passing status assertions
prove disclosure, not numerically valid confidence limits. No live JuliaCall,
full native/direct/bridge parity, bootstrap calibration or speed claim follows.

The 002 receipt's started_utc was written at completion by the early runner;
read it as completion time. Its elapsed duration uses a monotonic clock. Later
runner revisions record separate start/end timestamps and actual DRM sourcepath.

Later module-1threads-inner001 and module-4threads-inner002 receipts belong to
the subsequent uncommitted inner-mode candidate2ab0c168. Both error during the
Gamma fit. They do not change the historical de4620c7 verdict, and demonstrate
why that verdict cannot be inherited by later engine changes. See the separate
locscale-inner-status-20260831 investigation.

The later `module-1threads-round001` and `module-4threads-round002` receipts
also belong to the unaccepted inner-engine candidate608c24c8. Both fail before
profiling during Gamma covariance construction. They are not passing evidence
for the accepted de4620c7 profile-status source. See the inner-status directory.
