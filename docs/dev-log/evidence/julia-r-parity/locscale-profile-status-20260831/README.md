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
