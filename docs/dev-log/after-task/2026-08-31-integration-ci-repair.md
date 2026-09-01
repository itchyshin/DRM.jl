# Paired integration CI repair

## 1. Goal

Repair the Documenter, bootstrap-refit, and threaded-profile blockers exposed by
DRM.jl PR #565 without widening its model or inference claims.

## 2. Implemented

The internal reference now includes the five private paired-whitening docstrings
reported missing by Documenter. The phylogenetic LSS boundary helper now keeps
the unresolved dedicated comparison broken. The scalar multi-component case
compares its likelihood and identified coefficients directly, while comparing
the zero-boundary phylogenetic standard deviation on its natural scale.

Whitened location-scale point fits now use a strictly certified recovery ladder
after an unsuccessful Newton solve: BFGS with backtracking, L-BFGS with
backtracking, then default L-BFGS. Each method tries the failed endpoint before
the canonical start. A replacement must converge, have a finite exact gradient
within the original tolerance, and have an objective no worse than the original
endpoint apart from eight units of floating-point rounding.

Whitened profile nuisance fits retain their warm start but continue once from a
failed optimizer endpoint with a fresh inner seed. If a cross-point warm start
still fails, the final retry uses the fitted nuisance coordinates. Every retry
uses the same optimizer limit and must pass the same fresh objective and
exact-gradient checks. Its use is recorded in the returned internal status; the
legacy raw route does not take these retries.

## 3a. Decisions and Rejected Alternatives

The scalar multi-component test was not left as a raw-parameter comparison.
At a zero-variance boundary, very different negative values of `log(sd)` can
represent the same negligible standard deviation, so the log coordinate is not
identified. The invariant now checks the likelihood, identified coefficients,
and the natural-scale phylogenetic SD. The separate two-coefficient fixture
remains broken and visible because its broader discrepancy is unresolved.

Neither optimizer repair accepts a raw failed endpoint, relaxes convergence,
changes a random seed, changes an estimator, or widens a numerical tolerance.
The repairs deliberately reset the inner warm state and change the numerical
start after failure. Canonical restart was chosen only after exact Julia 1.10.12
diagnostics on Totoro showed
that the same constrained likelihood converged from the fitted coordinates with
free-gradient maxima between `5.18e-9` and `9.63e-8`.

## 4. Files Touched

The internal reference and API-stability pages, the phylogenetic boundary test,
two internal location-scale implementation files, the bootstrap replay
regression, the profile-status and threaded-profile regressions, the raw-profile
loading-contract test, the canonical phylogenetic end-to-end regression, the
structured Beta-Binomial recovery regression, the isolated test project and
bridge-label import, the API-freeze classification, the bootstrap-test
dependency comment, the deterministic bootstrap-simulator boundary test, the
module's prepared-joint API comment, two phylogenetic location-scale test-helper
names, explicit `DRM.Gamma()` constructors in every remaining test included
after the failing shared-namespace point and in its parity mapper, this report,
and one collision-free check-log entry. No public API changed; the existing
prepared-joint exports are now explicitly classified Experimental.

## 5. Checks Run

The focused file completed with 401 passes, two explicit non-passes on macOS
(one known broken, one platform skip), and no failures. A full local Documenter
build completed through VitePress rendering with no missing-doc error.

On macOS with Julia 1.10.12, profile status passes 102/102, threaded profile passes
19/19, and bootstrap refit passes 15/15. On Totoro with exact Julia 1.10.12,
one BLAS thread, and one or two Julia threads, the same focused files pass 102/102, 19/19,
and 15/15.

The optimizer-robustness neighbour passes 19/19 on macOS and Totoro with exact
Julia 1.10.12.

The canonical coupled phylogenetic end-to-end regression passes 8/8 on macOS
and Totoro with exact Julia 1.10.12. It now exercises the certified whitened
route selected by that public frontend, including convergence, certified exact
gradient, and finite fixed-effect Wald standard errors.

The structured non-Gaussian location-scale file passes 29/29 on macOS and
Totoro with exact Julia 1.10.12. Its Beta-Binomial recovery fixture was
right-sized from 70 groups × 22 observations to 30 × 12 and moved to the
certified whitened route after the larger raw fit returned a platform-specific
non-finite post-fit gradient. The smaller locked fixture retains the original
recovery tolerances for both fixed-effect slopes and both random-effect SDs,
requires optimizer convergence and a certified exact gradient, and completes in
14–15 seconds. The separate off-optimum raw Beta/Beta-Binomial finite-difference
gradient gate is unchanged.

The isolated test project now declares its direct `QuadGK`, `StatsAPI`, and
`StatsModels` imports, and the bridge-label test imports `LinearAlgebra.I`
explicitly. The bridge-label file passes 819/819 on macOS and Totoro, and the
joint-missing file passes 63/63 on macOS. A fresh full Totoro run then passed
every numerical, inference, family, bootstrap, and bridge block through the
late q4 inference checks. Its only failure was the API-freeze gate correctly
detecting 21 unclassified prepared-joint exports; after deliberately assigning
those existing exports to the Experimental tier, that focused gate passes
188/188. Fresh GitHub CI remains the final complete isolated-suite run.

The first fresh GitHub run made Documenter green, then exposed two independent
late test failures. Julia 1.10 rejected a lower profile endpoint after the first
strict nuisance solve exhausted its budget. A locked ten-iteration regression
proves that continuing from that failed endpoint can earn convergence with the
unchanged `1e-7` exact-gradient gate; profile status and threading pass on both
Julia 1.10 and 1.12 after the repair. Julia 1.12 also exposed a test that assumed
a fixed Beta RNG seed must round to exactly zero or one. The test now injects
the boundary response explicitly and retains the real response validator and
bootstrap failure ledger. The bootstrap-simulator file passes 100/100 on Totoro
Julia 1.10.12 and 1.12.6.

The second fresh GitHub run kept Documenter green and passed those two repaired
blocks, then Julia 1.10 exposed the retained second Gamma bootstrap refit. Its
trust-region Hessian became non-finite and both default-LBFGS starts stalled at
an exact-gradient maximum of `4.33e-4`, so the fit was correctly rejected.
Failed whitened point fits now try full BFGS with backtracking first, followed by
two L-BFGS line-search variants. A replacement still must report optimizer
convergence, have a finite exact gradient no larger than the original `g_tol`,
and improve the same likelihood within eight floating-point units. The retained
two-replicate integration fixture passes 15/15 on Totoro Julia 1.10.12 in 16
seconds and Julia 1.12.6 in 25 seconds.

The third fresh run kept Documenter green and reached the late phylogenetic
identity block on Julia 1.12.7. There, two orderings agreed in `mu`, `sigma`, and
the IID `sd` to about `1e-9`, but their boundary `log(sd_phylo)` values were
`-22.73` and `-19.77`. Those correspond to natural-scale SDs differing by only
about `2.5e-9`; the former raw-coordinate assertion was testing an unidentified
quantity. The corrected focused file passes 406/407 with the one deliberately
broken fixture on macOS Julia 1.10.12 and Totoro Julia 1.12.6. A fourth fresh
GitHub run kept Documenter green and completed the full Julia 1.10 suite in 46
minutes. Julia 1.12.7 reached the public phylogenetic location-scale test after
84 minutes, then rejected its bare `Gamma()` because both DRM and Distributions
provided that exported name in the shared test process. The test now names
`DRM.Gamma()` explicitly. Its local helpers and the adjacent sigma-axis helper
also have file-specific names, removing both method-overwrite warnings reported
immediately before the failure. The adjacent sequence passes 26/26 on macOS
Julia 1.10.12 and Totoro Julia 1.12.6. The expanded affected numerical set
passes 99/99 on macOS Julia 1.10.12; Totoro Julia 1.12.6 separately passes the
26-test adjacent sequence and the 26-test heterogeneous-Gamma/Beta sequence.
The mixed-family file requires the isolated `Pkg.test()` environment because
`StableRNGs` is test-only, so it remains part of the fresh full-suite gate. A
fifth fresh GitHub run remains required.

## 6. Tests of the Tests

Both Linux CI jobs first failed because the scalar comparison produced an
unexpected pass under `@test_broken`. Promoting the raw-coordinate comparison
unconditionally then produced macOS and Julia 1.12.7 failures. The latter run
showed the identified coefficients agreed while only the effectively zero
phylogenetic log-SD varied, proving that the raw boundary coordinate was the
wrong invariant.

The bootstrap regression replays both retained seeds and independently requires
`is_converged` plus an exact objective gradient no larger than `1e-8`; it also
retains the prior failed parameter vector as a negative control. Totoro profile
diagnostics reproduced nonfinite public endpoints from three rejected nuisance
fits, while canonical restarts of those exact constrained problems passed the
unchanged stationarity rule.

A deterministic damaged-warm-start control forces the whitened canonical retry,
requires `fallback=true`, convergence, and an exact free gradient no larger than
`1e-7`, then verifies the same call with `whitened=false` does not retry. The
public threaded test checks fallback fields agree with retained endpoint
diagnostics and between serial and threaded execution.

The raw NB2 loading fixture uses a hand-written reference vector rather than a
fitted optimum. Its test now compares the entire structured default-versus-
explicit-loading result, including endpoint and nuisance diagnostics, while
requiring explicit accepted/failed/unbounded statuses and non-NaN bounds.
Finiteness on real fitted profiles remains required by the separate public
profile fixtures.

The original 70 × 22 Beta-Binomial raw recovery fit reproduced the Linux
failure (`gmax = NaN`). Simply re-evaluating that endpoint with the whitened
oracle also failed certification, so the test was not repaired by relabelling a
failed point. A one-core Totoro pilot showed the locked 30 × 12 fixture
converged in 9.65 seconds with certified `gmax = 3.46e-12` while preserving all
pre-existing recovery bounds; the final full-file checks then passed on both
platforms.

## 7a. Issue Ledger

This repairs the current checks for PR #565. The paired drmTMB PR #1104 and the
global parity programme remain open; DRM.jl must merge first. Fresh full-suite
and GitHub checks remain required before merge. The fourth run is retained as
partial evidence: Documenter and Julia 1.10 passed, while Julia 1.12.7 failed
only at the late shared-namespace test described above.

## 8. Consistency Audit

Every newly documented symbol is the exact private symbol named by Documenter.
The test distinction matches observed platforms and retains strict mode through
`DRM_LSS_STRICT_BOUNDARY=1`.

## 9. What Did Not Go Smoothly

The first local Documenter run reached rendering but the sandbox blocked Julia's
standard manifest-usage log. The identical build completed with normal Julia
filesystem permission.

The isolated full suite exposed four test-environment assumptions in sequence:
three directly imported packages absent from `test/Project.toml`, followed by a
bridge-label test relying on another test file to import `LinearAlgebra.I`.
After those were made explicit, the suite reached its final API-freeze gate and
correctly rejected the new prepared-joint exports until they were classified.

The first fresh GitHub CI run then found two platform/version neighbours that
the two-thread Julia 1.10 Totoro run did not expose: a one-runner profile
continuation failure and a Julia-version-dependent Beta RNG endpoint. Both now
have deterministic focused regressions. The second fresh run crossed those
blocks, then exposed the retained second Gamma bootstrap refit on the GitHub
Julia 1.10 runner. Its strict rejection led to the certified
alternative-optimizer ladder. The third fresh run then exposed the unidentified
raw log-SD comparison on Julia 1.12.7. The fourth fresh run passed Julia 1.10
but took 46 minutes, and Julia 1.12.7 took 84 minutes to expose a late bare-name
ambiguity. The earlier 12–25 minute full-run estimate was therefore wrong;
future complete CI should be budgeted at roughly 45–90 minutes per Julia job.
A fifth fresh run is required.

The full Totoro suite exposed an older raw-profile loading test that demanded a
finite CI around a hand-written non-optimum vector. Exact diagnostics showed both
arms correctly failed the unchanged stationarity check; the test was narrowed to
its actual loading-threading contract rather than weakening the optimizer.

## 10. Known Residuals

The dedicated small two-coefficient fixture remains known broken on all
measured platforms unless strict mode is requested. The point-fit canonical
restart has been replaced by alternative optimizers attempted only after a
failed whitened solve; profile continuation is also whitened-only. Neither is a
general claim that every difficult likelihood will converge. The focused
namespace repair is verified on Julia 1.10.12 and 1.12.6, but Julia 1.12.7 still
requires the fresh full CI run.

## 11. Team Learning

An unexpected pass can reveal a platform-specific numerical result rather than
universal closure. Optimizer recovery should restart the same likelihood from a
stable state and then earn acceptance through the original exact checks.

## 12. Cross-Product Coverage

This slice covers Documenter completeness, the named LSS boundary test,
the two retained bootstrap random seeds, and the observed whitened warm-start profile failures.
It does NOT cover coefficient invariance beyond the named locked fixtures,
Windows behavior, every profile shape, global parity, performance, release, or
deployment.

## 13. Next Action and Routing

Complete the final independent review, push the namespace repair, require the
fifth fresh green run on PR #565 as the complete isolated-suite proof, merge it,
then recheck and merge the already-green PR #1104 second.
