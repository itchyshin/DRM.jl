# Paired location-scale fitting and coefficient profiles

## 1. Goal

Continue programme #563 / S11: recover the unchanged finite-profile workflow,
then verify independent coefficient threading. Full programme G0-G8 remain open.

## 2. Implemented

The canonical coupled location-scale frontend now selects a private whitened
state consistently for values, analytic gradients, observed information, profile
nuisance fits and fit diagnostics. Legacy sigma/correlation paths retain their raw-P representation by default. Module and test wiring includes the new helper,
independent precision/compensated checks and original finite-profile fixture.
Coefficient jobs run with owned state; single jobs remain serial.

## 3a. Decisions and Rejected Alternatives

Preserve original-coordinate acceptance, strict family domains, requested SEs,
parameter packing and iteration budgets. No global gradient-only redirection,
no relaxed1e-7 nuisance criterion, no dropped difficult fixture and no latent
neighbor-selection heuristic. Disable x/f equality stopping only on the paired
nuisance route because it could stop before the unchanged gradient criterion.

## 4. Files Touched

Eight src files and six test/fixture files, exact hashes and source snapshots
in paired-integration/manifest.json. Evidence/report/checkpoint and a dated
research-note update. No protected Gaussian/tutorial files or R source changed.

## 5. Checks Run

Receipts under docs/dev-log/evidence/julia-r-parity/locscale-profile-threads-20260831/paired-integration.

| Receipt | Result | Seconds |
|---|---|---:|
| original191539Z | 12 pass / 4 fail before stopping repair | 14.881 |
| original192052Z | 14 pass / 2 metadata failures before threading | 23.738 |
| original192423Z | 16 pass; runtime threads not asserted | 19.031 |
| neighbours192803Z | 29 pass: public frontend, inference, legacy sigma | 16.895 |
| kernels192921Z | 1982 pass including284 helper,28 precision,14 compensation | 41.964 |
| serial-profile193031Z | 193 pass, asserted1 Julia/1 BLAS | 21.082 |
| finite-profile193110Z | 16 pass, asserted4 Julia/1 BLAS | 14.206 |
| thread-status193154Z | 181 pass, asserted4 Julia/1 BLAS | 19.498 |
| whitened193230Z | 284 pass after removing test-only include fallback | 13.589 |
| integration193350Z | 44 pass: fit, independent acceptance, bridge status | 10.627 |

Production source hashes agree across the five final confirmation receipts
(serial193031, finite193110, thread193154, whitened193230, integration193350). The test-only fallback
was removed after the large kernel bundle and its final test rerun passes.
No full Pkg.test(), matched R campaign, coverage run or timing benchmark here.
The immutable finite-profile test is also a runnable public-formula example.

## 6. Tests of the Tests

Retained numerical reds, independent128/256-bit references and deliberately
negated-gradient rejection precede this repair. Original finite fixture remains
SHAca1d9db86c33fb8046028c0e9833d1e0cc0af095509d5580b48375a390bd7ad4.
Its wrapper rejects deliberately damaged logs. Existing dense-small inverse,
gradient, invalid-state, copied-seed, fallback, exception and BLAS-overlap tests
remain enabled; helper tests can no longer manually include a missing module.

## 7a. Issue Ledger

Programme #563 / S11 remains active. Local paired-consumer and original-profile
gates pass for this bounded scope. No global gate or GitHub issue is closed.
Required bootstrap defect is recorded in next-bootstrap-finding.md; neither
this profile repair nor point estimates count as bootstrap validation.

## 8. Consistency Audit

Independent Rose review found no material source blocker at the recorded
hashes. Information probes own copies of seeds; every outer point is recertified.
Final explicit thread assertions repair the earlier runtime-provenance gap.
Mission Control commit608342b updated only two fields and served values match;
other staged changes preserved and the exact lease released.

## 9. What Did Not Go Smoothly

One focused launch failed on Julia cache permissions before testing; retained.
The 42-second kernel bundle exceeded the30-second estimate before it could be
stopped, within its60-second safety cap. Subsequent bundles used30-second caps.
The threaded-status run took19.5 seconds within its recorded wrapper estimate
and cap of30 seconds. Its launch justification said15 seconds; retain that
narration mismatch in launch-estimates.json rather than changing the receipt. ForwardDiff
compilation accounted for20.7 seconds in the kernel bundle. One existing fit
emitted an early NaN-Hessian optimizer warning; the fallback checks passed.
Stale 'unwired' text in early runner receipts is explicitly annotated, not erased.

## 10. Known Residuals

Bootstrap can omit both random-effect axes for this canonical class; implement
and validate a joint marginal sampler next. Structured bridge bootstrap also
needs tree-forwarding verification. Large boundary SEs are not evidence of
valid Wald coverage. Full R/direct-Julia/bridge parity, performance, documentation,
recovery and final integration remain required. No public deployment performed.

## 11. Team Learning

Actual routes: root Sol/medium; builder Terra/high; independent Rose Sol/high;
mechanical scout Luna/low. Active agent-hours are not instrumented; do not turn
wall-clock or token totals into active-hour claims. All numerical work in this
slice ran on the Mac. No fresh remote connection verification or remote compute.

## 12. Cross-Product Coverage

This closes the bounded canonical finite-profile regression and coefficient
threading checks. It does NOT cover full R/direct-Julia/bridge numerical parity,
bootstrap validity or coverage, REML/provider combinations outside this fixture,
missing-response and missing-predictor workflows, or the original broader inference, parity,
performance, documentation or cleanup promises. The literature crosswalk
remains a terminology/method reference, not new R-squared API authorization or
profile/bootstrap validation. No release, registration, merge, push or retirement.

Lifecycle audit returned1 on persisted day-wide compaction/guardian thresholds;
not a passing efficiency verdict or billing measurement. The approved disk-goaled
checkpoint-and-roll exception retains the next bounded task in LOOP/checkpoint.md.
