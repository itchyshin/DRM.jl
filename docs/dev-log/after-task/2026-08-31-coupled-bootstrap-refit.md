# Coupled marginal bootstrap and bounded refit continuation

## 1. Goal

Advance approved programme #563/S11: simulate both coupled latent axes and
refit the same likelihood correctly. Full programme G0-G8 remain OPEN.

## 2. Implemented

Canonical coupled non-Gaussian location-scale fits now dispatch to a marginal
sampler. It prepares a copied sparse triangular precision factor and permutation;
each replicate owns its normals, solves, effects, predictors and response.
Draws preserve Q^-1 tensor L*L' covariance, both latent axes, family-specific
scale conventions, row/group maps and Beta-Binomial trials. Rebuilt data, design
and precision must match the fitted objective before simulation begins.

An unsuccessful whitened fit gets one bounded LBFGS continuation from its current
point. Acceptance requires optimizer convergence, finite parameters, fresh cold
inner certification, the original full gradient tolerance, and a nonincreasing
objective within eight ULPs. Errors/rejection preserve the original failed fit;
interrupts propagate and warm state resets. Successful and raw routes bypass it.

## 3a. Decisions and Rejected Alternatives

No clipped/redrawn Beta responses, altered likelihood, weaker convergence flag,
changed Gamma coefficient scale, removed difficult seed or suppressed warning.
The extra continuation can consume one additional `iterations` budget; it is not
free and is not a measured speedup. Alpha remains the coupled Gamma stored slot;
coherent public CV normalization is separate required work.

## 4. Files Touched

src/locscale_simulate.jl, src/locscale_fit.jl, src/DRM.jl, src/inference.jl,
test/test_locscale_bootstrap_simulator.jl, test/test_locscale_bootstrap_refit.jl,
test/runtests.jl, this report, check-log, evidence and LOOP/checkpoint.md.
Mission Control changes only its two leased curated status fields.
No protected Gaussian structured/sparse-LSS or tutorial files changed.

## 5. Checks Run

All Mac-local with pinned BLAS=1. No remote or long campaign launched.
Final one-thread bundle:145/145,30.719s; final four-thread bundle:145/145,27.974s.
Both had a60s estimate/cap and unchanged before/after source hashes. Each includes
32 conditional/neighbour checks,101 joint sampler checks and12 public refit checks.
The existing finite-profile fixture also passed16/16,14.147s,4Julia threads.
Unlazy actually executed G1 and G2 successfully; broader G3/G4 remain open.
G0 is a manual retained-red and independent-review sign-off recorded after that
execution; its earlier UNMET line is preserved, not represented as an automated pass.

## 6. Tests of the Tests

Retain the original IID missing-sampler and relmat parser failures from the prior
slice. Current draft first failed on wrong objective field names. The expanded
run then found a genuine Beta float endpoint; independent Distributions output
matches exactly. Tests retain that draw, require frontend rejection and check
failed replicate number, seed and reason. The covariance oracle rejects full
Q^-2 and omitted permutation alternatives. Altered rows, designs, groups and
precision are rejected. Shared-closure serial/thread draws agree for fixed seeds.
The initial real Gamma B2 run used1/2 in each mode; preserve its failing counts.
The third initial assertion failure was NaN equality, corrected to isequal for
bookkeeping only. Fresh gradient checks, independent of the convergence flag, reject the original failed point
(maxabs1.006e-5) and accept the repaired point under the unchanged1e-8 criterion.

## 7a. Issue Ledger

Programme #563 remains open. No issue closed. This advances S11 but does not
close structured/R-facing bootstrap parity, other-family refits, Gamma public
normalization, performance, documentation or recovery obligations.

## 8. Consistency Audit

Rose independently reviewed sampler and continuation; exact hashes in review.md.
Runtime receipts confirm current-source tests. Melissa found that review.md
mistakenly called an earlier test hash final; the note now distinguishes the
snapshots. Rose subsequently reviewed the final test delta explicitly. Static review alone was never
counted as a passing numerical run. There is no speedup or coverage headline.

## 9. What Did Not Go Smoothly

The Terra builder failed with a model-capacity error after leaving a draft;
root took over rather than counting it done. Draft fields Xmu/Xpsi were incorrect
for the objective's Xμ/Xψ. A negative test originally inverted UpperTriangular(Q)
instead of full Q; corrected before claiming Q^-2 detection. Initial optimizer
warnings about a NaN Hessian remain visible; the bounded continuation recovers
the tested replicates, without claiming to remove that initial numerical warning.
The first unlazy status invocation wrongly used execution-only --cwd; the valid
status command and actual execution were then run. Raw failures remain intact.

## 10. Known Residuals

Next: reproduce and repair omitted tree forwarding in non-Gaussian fixed-target
bridge bootstrap, then test phylo/relmat/animal/spatial and other families end to
end through direct Julia and the public R `engine = "julia"` interface via JuliaCall.
This evidence set does not validate that R-facing workflow. Generic fit-based bootstrap
still lacks coords forwarding. Beta endpoint failures can bias retained draws
if frequent; measure failures in the retained evidence campaign. B2 intervals
are not statistically useful. Gamma scale normalization needs the full Jacobian,
inverse objective/profile maps and decreasing endpoint reversal, not one slot fix.
Mission Control's two-field update was locally committed and verified as served;
this status update does not close the full programme's Mission Control obligation.
All original capability/performance/documentation/recovery obligations persist.

## 11. Team Learning

Root ran Sol/medium, rather than claiming the planned high effort. The
milestone efficiency checker exited1 on persisted day-wide compaction/guardian
limits; it is not a passing gate or billing evidence. This approved disk-goaled
programme continues by checkpoint-and-roll; no new user-owned task was created. Original builder Terra/high failed; Rose Sol/high reviewed; Luna/low
traced the Beta-Binomial response adapter. No new expensive model escalation.
Recorded seconds are command wall times, not active agent-hours; total active
hours and programme completion time remain unmeasured. No Codex memory edits,
release, registration, public deployment or collaborator messages.

## 12. Cross-Product Coverage

This does NOT cover general inference parity, reliable interval coverage, the
performance manifest, other provider/family refits, completed documentation or
worktree retirement, the public R `engine = "julia"` workflow or full Mission Control closure. No required programme gate was abandoned or redefined.
All numerical processes are terminal at this checkpoint. Continue from LOOP;
reviewable local code/evidence is carried forward, never treated as programme completion.
