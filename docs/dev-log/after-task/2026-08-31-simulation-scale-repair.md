# Conditional simulation scale repair; joint bootstrap continues

## 1. Goal

S11 within programme #563: simulate the fitted likelihood correctly before
using those draws for bootstrap refits. Full programme G0-G8 remain open.

## 2. Implemented

NB2 simulation now uses size=sigma^-2, including zero-inflated, hurdle and
truncated neighbours. Gamma simulation respects the existing structural marker
that distinguishes the coupled route's shape-valued slot from ordinary CV.
A private per-draw sigma override supports the four coupled families without
mutating fits. The shared generic kernel is reused by the planned joint sampler.

## 3a. Decisions and Rejected Alternatives

No fit objective, coefficient, covariance or public keyword changes. Gamma
public normalization requires a separate coherent Jacobian/inverse-objective
change; it remains required parity work. Do not convert only one Gamma slot.
Do not interpret NB2 sigma as size or silently reuse fixed scales for joint draws.

## 4. Files Touched

src/gaussian_core.jl, test/test_simulate_scale_conventions.jl, test/runtests.jl,
local gate and retained evidence under locscale-bootstrap-20260831. The new
joint-sampler fixture belongs to the separate ongoing child; do not call it done.
No protected Gaussian structured/sparse-LSS or tutorial paths changed.

## 5. Checks Run

All local, one Julia/one BLAS thread,30-second estimate/cap. First scales194757Z
was a test parser error, not numerical evidence. Corrected194830Z:1pass5fail,
6.277s; four NB2 branches and coupled Gamma disagree with independent seeded
distribution draws. Expanded194953Z:5pass5fail4missing-keyworderrors,5.817s;
an outer testset ensures early failures do not skip the override checks.
Repair195136Z:14/14,8.934s. Gaussian/Poisson simulation neighbour bundle195329Z:
32/32,14.810s. Source hashes unchanged across runs. No long campaign or remote run.

## 6. Tests of the Tests

Retained actual numeric failures, nonunit scales, four NB2 branch mechanisms,
ordinary/coupled Gamma distinction and unchanged-fit checks. Independent
Distributions draws supply conditional references. The original parser failure
and early testset abort are preserved rather than counted as desired reds.
Sparse precision contract separately passes a nonidentity permutation and
rejects Q^-2 and omitted-permutation alternatives; it is not yet sampler proof.

## 7a. Issue Ledger

Programme #563/S11 and globalG0-G8 remain open. Local G1 passes; full joint
sampler/refit/bridge gates remain open. No issue closure or publication.
Named separate debt: Gamma public logshape/shape versus documented logCV/CV.

## 8. Consistency Audit

Rose's independent Sol/high review found no blocker at sourceeafb80c0/test6b20ba84.
Private override follows stored-slot semantics, not a universal CV convention.
Unsupported families ignore this internal keyword; new callers must be restricted
to the admitted four families. Bootstrap validity cannot follow from these tests.

## 9. What Did Not Go Smoothly

The first synthetic joint fixture had an invalid field name and inconsistent
formula/design/covariance. Those errors were corrected before accepting a red.
The next fixture assumed AMD would permute a dense inverse; that assumption was
removed, with nonidentity handling retained as a separate mathematical oracle.
Corrected joint baseline195735Z:9pass2capabilityfail0error,11.001s. IID returns no
sampler; structured coupled grouping errors in the generic parser. Joint source
implementation follows that retained red, not the invalid fixture failures.

## 10. Known Residuals

Implement and validate the joint sampler; tiny direct/bridge refits; tree
forwarding and serial/threaded agreement. Gamma public-scale normalization
requires beta_sigma=-beta_psi/2, latent D Lambda D withD=diag(1,-1/2), full outer
Jacobian, inverse objective/profile maps and reversed decreasing CI endpoints.
No partial conversion or claim that normalization is complete.

## 11. Team Learning

Root Sol/medium; builder Terra/high; independent Rose Sol/high. Retained figures
are command wall times, not active agent-hours. No Codex memory edits, releases,
remote compute, deployments or collaborator messages. Existing artifacts remain.

## 12. Cross-Product Coverage

This covers conditional draws for ordinary/coupled Gamma and NB2 plain/ZI/hurdle/
truncated routes, plus internal Beta/BB auxiliary overrides and Gaussian/Poisson
neighbours. It does NOT cover completed joint bootstrap, coverage, R bridge
numeric parity, Gamma public-scale parity, other providers/REML/missingness cells,
full suites, performance, whole-site verification, recovery or programme closure.
