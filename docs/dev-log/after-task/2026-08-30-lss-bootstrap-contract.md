# Gaussian LSS bootstrap repair — bounded verification, programme still open

## 1. Goal
Address Ayumi's inference concern within approved programme DRM.jl#563: preserve
all variance components, species identity, response masks and the estimator in
Gaussian models with sd() submodels. All programme G0–G8 remain open. This is a
bounded inference repair, not complete Julia–R parity or a coverage claim.

## 2. Implemented
The Gaussian LSS simulator builds full fixed-mean and residual-scale designs,
and independently draws every IID and phylogenetic mean component. IID grouping
retains first-seen order; phylogenetic grouping uses named tree-tip order. Shared
IID coefficient blocks are consumed in formula order with exact name/width checks.
Scalar components without their own sd() formula contribute too. LSS phylogenetic
SDs use normalized tree correlation, including scalar multi-component terms.
Missing responses remain unobserved in every refit. LSS refits preserve ML/REML.
The formula-based Gaussian bootstrap now invokes the marginal simulator as well.

A separate shared collector defect used packed Boolean flags for parallel writes.
A no-fit reproduction lost a successful replicate. Byte-addressable Boolean flags
now retain independent success slots without changing convergence criteria.

## 3a. Decisions and Rejected Alternatives
Reuse existing likelihoods and estimators. Never use a conditional simulator as a
fallback for malformed LSS metadata. Require matching design names, SD segments,
observed counts and finite means/scales/draws. Retain private scratch per replicate
and read-only prepared factors. No tolerance or convergence rule is weakened.
Ordinary Gaussian REML/MAP propagation remains a separate existing gap; this slice
preserves estimators only for the sd()-routed Gaussian LSS models. No denied engine
file was edited or bypassed. Dense simulation cost remains an open performance issue.

## 4. Files Touched
Owned inference.jl hunks; test_lss_bootstrap_contract.jl; test_bootstrap_thread_flags.jl;
the two test-runner includes; LSS tutorial; evidence, check-log and this report.
Foreign sparse-storage test/include and R ZOB bridge changes are preserved and not
staged. Boundary diagnosis owns only its separate runner/evidence; no likelihood
or fitting test source was changed by that diagnostic.

## 5. Checks Run
Final002:187/187 assertions pass in68.65 seconds, Julia1.10.0, four Julia threads,
one measured BLAS thread. Recursive source, six tests and Project/Manifest hashes
are unchanged before/after. This comprises60 focused LSS checks, two no-fit parallel
flag checks and125 existing Gaussian/non-Gaussian bootstrap neighbour checks.
Known-parameter fixtures separate simulator correctness from optimizer behavior.
Manual REML refits match public bootstrap summaries and identical-seed serial and
threaded results. A small formula-versus-fit comparison uses the same marginal model.

Docs001 executes eight examples in25.186 build seconds (27.15 process seconds),
including an auditable four-replicate bootstrap with convergence checking. This is
local executable-Markdown proof, not a whole-site visual or deployed-page verdict.
The public R bootstrap comparison is pending at report creation; no success is
inferred from the source-only bridge call-path audit.

## 6. Tests of the Tests
Corrected RED003 retained13passes/9failures, including wrong species/component
simulation and a single-phylo REML refit mismatch. RED001 accidentally shadowed
the phylo marker with a Boolean fixture keyword and is not clean defect evidence;
RED002 fixes that harness error. Green001 records a cache-permission failure.
The first existing-neighbour batch retained123passes/2failures in threaded Poisson
same-seed comparisons. A no-fit B256 word-aligned probe did not reproduce the race;
B250 over300 batches did (minimum249 successful slots although every refit succeeds).
After the repair all300 batches retain250 and the two Poisson comparisons pass.
Final001 retained185passes/1failure: a count-guard test mistakenly removed an
already-missing row. It now removes an observed row and asserts that precondition.
No implementation change was needed for that test correction.

## 7a. Issue Ledger
Programme #563 remains open. The collector repair also fulfills the approved S5
safe-bootstrap-flags item at this bounded scope. Public R integration, profile
nuisance status/gradients, sparse simulation/refits, complete registered performance,
all original24 missing-predictor obligations and all prior strict losses remain
required. No issue was closed and no collaborator message was sent.

## 8. Consistency Audit
Rose approves component covariance, tree alignment, missing masks, coefficient
layout, LSS estimator propagation and byte-addressable parallel flags. Her required
metadata/finite-value guards and test-runner wiring are present. Golden Set:
known nonzero component draws against a hand-written covariance; same-group IID
and phylo effects; scalar components; actual missing and NaN; metadata refusals;
manual REML refits; serial/threaded reproducibility; independent collector bookkeeping.
Final Melissa and public R receipts remain pending at report creation.

## 9. What Did Not Go Smoothly
The fixture shadowed a formula marker; the first flag probe aligned worker chunks
with packed-word boundaries; a count test removed the wrong kind of row; Julia
cache writes needed scoped escalation. Each failed/non-reproducing attempt is
retained. Statistical boundary warnings occurred in fitted fixtures. B3 comparisons
with check_converged=false verify dispatch and reproducibility, not convergence of
every refit or useful interval endpoints. Neighbour failures prompted the concrete
parallel collector reproduction rather than being dismissed as random noise.

## 10. Known Residuals
Original six-tip coefficient differences4.5298009477 and0.8610680164 still fail
strict4e-6. The independent byte-verified diagnostic finds almost identical named
covariance likelihoods and tiny phylogenetic covariance contributions. Tiny raw
log-SD curvature alone does not establish structural nonidentifiability, because
variance is exp(2a). Neither diagnosis nor covariance agreement waives the raw
coefficient gate. Profile nuisance convergence/status and analytic-gradient reuse
remain open, including the previously failed256-tip constrained solve.
The public R bootstrap wrappers still need runtime verification and richer failure
reporting; native-R interval parity/coverage and large-tree efficiency are not proved.

## 11. Team Learning
Parallel flags need independent physical storage, not merely distinct logical
indices. A word-aligned test can miss a packed-bit race. Separate generator tests
from optimizer tests, and retain original response bytes when diagnosing flat
parameter directions. Root actualSol/medium (plan requestedhigh), Terra/high builder,
Sol/high Rose and Luna/low scout; active agent-hours are uninstrumented.

## 12. Cross-Product Coverage
This does NOT cover all families/providers, every missing-data pattern, interval
coverage, or the registered performance denominator. Keep original native
capabilities, LSS stamped SE/REML/masks/large-tree/final-head obligations, automatic
1/2/4/8 thread policy, worktree/stash preservation and cleanup, Documenter visual
review/deployment and clean-source integration required. No new remote compute,
package installation, release, registration, deployment or collaborator message.
Mission Control61d8f47 was locally committed, four served fields verified, lease released.

## Acceptance checkpoint
The executable unlazy commands were re-run after the final test correction:
G2 and G3 pass. Current leaf state is4met/2unmet (G4 finalMelissa andG6publicR
receipt pending). No gate was abandoned. Rose approves the final source/test
checkpoint; mechanical audit finds all100final-test and95docreceipt hashes
match current files. MissionControl61d8f47 records the same pending scope.
