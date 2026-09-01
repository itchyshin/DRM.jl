# Rose review — frozen comparison candidate

Reviewer: `/root/rose_plan_gate`, Sol/high, 2026-08-31. Read-only; no runs or edits.
Source SHA: `2c534141d8439a4ee339bfc6d795e4a4836fea885f986f677b418016a4afc32f`.
Focused test SHA: `194b91bd750d3dc4a24c0a84cf9e2686e46f048da3ff0746eb7e66b4a1f9a4ec`.

**APPROVE source and focused tests at this bounded scope.** Cancellation controls
are meaningful. The five numerical estimates meet the1e-4 relative criterion
(maximum1.446e-5), and observed errors lie within estimated margins. No rigorous
descent bound or global optimum is claimed.

Rose found one remaining private pilot-checker defect: its high-precision
opposite steps were checked as uphill, but the production helper's opposite
margin was not asserted nonnegative. Require finite opposite results and
nonnegative margins, plus deliberate corruption to verify the assertion.

Root follow-up: pilot004 adds those assertions and reports success on all five
cases. Negative control005 injects `opposite.margin=-1` and fails the new guard.
Root independently inspected the script and both logs. This closes that checker
finding; it is not a new Rose integration verdict. The unchanged full regression
batch still fails Gamma covariance construction, so integration remains open.
