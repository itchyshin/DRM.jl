# Parity comparison and missing-predictor references

## 1. Goal

Advance S4/S9 of issue563 with reliable comparisons and independently derived
native reference likelihoods; retain every outstanding programme obligation.

## 2. Implemented

The legacy coefficient comparator now requires complete, finite, unique named
sets. All three loops use it, and failed completed tables cause a failing exit.
Added independent Gaussian and Bernoulli missing-predictor likelihood oracles,
native reference probes, and the exact24-cell missing-predictor obligation map.

## 3a. Decisions and Rejected Alternatives

Did not relax tolerances, remove failed cases, overwrite old result tables, or
change Julia source. Oracle implementations follow probability identities,
not copied GPL source. Numerical agreement at a common parameter vector is
distinct from optimizer convergence or recovery. No server campaign was needed.

## 4. Files Touched

tools/parity_fixture.R, new numeric/oracle tools and pure tests, evidence under
docs/dev-log/evidence/julia-r-parity, and programme checkpoint/compute notes.
The red S5 allocation tests remain separate and unstaged.

## 5. Checks Run

S4's two unlazy checks executed and passed. A full legacy eight-case run passed
coefficient/log-likelihood checks in33.50s. Its damaged counterpart completed
in33.30s with eight failed rows and exit1. S9 pure integration/mask tests passed;
the two native likelihoods agreed within1.5e-12 at identical fitted parameters.
Final S9 logs bind the source, retained data and loaded-package fingerprints.

## 6. Tests of the Tests

Missing/extra/duplicate/unnamed/nonfinite coefficients, changed term names and
numerical perturbations are rejected. The actual runner was exercised with its
first observed coefficient removed. Gaussian integration is independently checked
by numerical quadrature for every mask; Bernoulli endpoints0/1 and b=0 are tested.

## 7a. Issue Ledger

Issue563 and all programme G0–G8 remain open. These leaves do not freeze the full
valid-case denominator or close numerical parity, performance or missing predictors.

## 8. Consistency Audit

Rose approved the limited comparator and independent oracle mathematics/tests.
Six legacy cases use public R engine calls; two use raw Julia bridge payloads.
Actual BLAS counts were not recorded in these comparator probes: environment
settings are requests, not runtime proof. A separate factor-profile log showed
BLAS16; compute notes now require explicit runtime setting and verification.

## 9. What Did Not Go Smoothly

The first Gaussian oracle adapter exponentiated a public SD twice; its failed
receipt is retained. The corrected public scale matches native source semantics.
Initial unlazy runs exposed an omitted CWD/permission and wrong timeout units;
these attempts did not execute the intended checks. Corrected runs are distinct.

## 10. Known Residuals

Existing setup/extraction errors may abort the legacy runner before a completed
table. Full workflow outputs, convergence and build identity remain separate gates.
The R zero-one-beta default comparison remains red; its reviewed adapter fixes
are uncommitted. Protected Julia source approval is still unresolved.

## 11. Team Learning

Memory receipt: current repository, source contracts and prior operating guidance
informed this continuation; no Codex memory was written. Golden Set: not run.
Read public parameter scales and measure actual runtime thread counts explicitly.

## 12. Cross-Product Coverage

This does NOT cover Julia missing-predictor implementation, inference/coverage,
all24 native cells, full parity or performance. The old child branch034d93823b
adds bivariate/SE work and remains preserved for a separate recovery decision.
