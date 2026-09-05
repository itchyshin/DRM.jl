# Direct LSS tree-tip identity: reviewed repair, strict numerical gate open

## 1. Goal
Repair the phylogenetic LSS frontend's first-seen species indexing in both
fitting routes, under approved programme DRM.jl#563. Preserve all original
parity/performance requirements. The previous goal turn made concrete progress;
this turn reproduces and repairs an additional fitting defect. Programme G0–G8
remain open; this is not a complete-leaf or programme-completion report.

## 2. Implemented
Dedicated and multi-component phylogenetic LSS now map observations to named
tree tips before building group SD designs or filtering missing responses.
Integer labels use positional1:p semantics; exact String-convertible labels,
including Symbols, retain their identity. All tree tips must be represented in
the full input, including tips whose responses are entirely missing. Ordinary
IID grouping remains first-seen. Newick is parsed once and passed on as a tree.

## 3a. Decisions and Rejected Alternatives
Reuse the existing likelihoods, estimators and numerical engines. Do not sort
observations to hide a wrong tree mapping; test original shuffled rows. Preserve
Symbol compatibility and validate integer bounds before conversion. Only shipped
AugmentedPhy/Newick providers are qualified, not arbitrary custom tree types.
No previously denied source file was edited or bypassed. No threshold was relaxed
or difficult coefficient comparison removed to produce a green summary.

## 4. Files Touched
Julia gaussian_lss.jl frontend/helper hunks, dedicated regression file and its
runner include, LSS tutorial and retained reports/logs. R public label runner and
receipt checker now distinguish direct tree-order versus original-input order.
No R production bridge changes in this slice. Foreign Julia S5 include/test and
R ZOB96insertions/10deletions remain preserved and excluded from staging.

## 5. Checks Run
Focused default run:401pass,2known broken; strict mode:401pass,2fail. The original
multi-component varying-SD coefficient comparison was restored during review and
passes. Tests include independent hand-written tree covariance and GLS REML,
identifiable16tip permutation checks, sparse REML with an entirely masked tip,
integer/Symbol/error neighbours and scalar/multi-component phylogenetic effects.
Existing suites:161LSS checks plus35including threaded profile/bootstrap, all
pass. StableRNGs1.0.4 was already installed and supplied through its explicit
project load path; no package installation. The updated tutorial executes seven
examples; this is local Markdown/example proof, not visual/deployed-site proof.

The native/direct/bridge public workflow has12labeled tips and72shuffled rows.
Before repair, all fits converged but four of eight checks failed; direct
likelihood error against named covariance was0.84057 and phylogenetic-SD
coefficient difference0.12536. After repair, all eight pass (29.356seconds,
including startup); maximum coefficient difference1.00642e-6<4e-6, likelihood
errors<7e-14. Direct input is explicitly unchanged, with no sorting workaround.
Source manifests before/after and current hashes agree. Checker rejects12damages.

## 6. Tests of the Tests
Pure red001 was an invalid Tables fixture containing metadata, not evidence of
the model bug; it is retained. Corrected red002 retained194passes/10failures.
Public-red001 independently reproduces the wrong fit on valid data with sources
unchanged. Green001 records cache-permission failure; green002 retains the two
coefficient failures; green003 records a Symbol test error. Earlier accidental
removal of the passing multi-varying coefficient assertion was caught by Rose
and reversed. Final tests retain the two original failures through both default
@test_broken and DRM_LSS_STRICT_BOUNDARY=1 normal assertions. The required strict
leaf gate G8 is OPEN; default suite exit0 is not proof that it passed.

## 7a. Issue Ledger
Programme #563 remains open. All24native missing-predictor obligations and prior
strict4e-6 failures remain required. No external issue was closed or collaborator
message sent. New source-grounded inference obligations include bootstrap
first-seen tree mapping, single-component simulation of multi-component models,
and ML refits losing REML choice. These require their own runtime reproductions
and repairs; they are not solved by the fitting frontend change.

## 8. Consistency Audit
Rose approved source4465956 and the unsorted public receipt; she verified both
mapping sites, Symbol compatibility, preserved full pre-mask design, unchanged
IID mapping, restored original assertion, hand covariance/GLS and current-source
provenance. Melissa found no scope drop, provided strictG8 stays open.
Golden Set: named covariance under row permutation, independent ML/REML,
sparse+dense, multi-component, missing-response identity and exact label mapping.

## 9. What Did Not Go Smoothly
Test fixture metadata initially violated Tables' input shape; a test dependency
was absent from the active environment though installed; and a cache write was
sandbox-blocked. All receipts are retained. Two original6tip coefficient tests
still fail strictly. One31.2second strict test slightly exceeded its30second
estimate before completion; subsequent test budgeting uses up to45seconds.
The tutorial also incorrectly called dense storage O(G^3); it now separates
O(G^2) storage from O(G^3) factorization and avoids promising unbiased REML.

## 10. Known Residuals
Two small cases diverge in phylogenetic log-SD coefficients:4.52980 for dedicated
LSS and0.86107 for scalar-phylogenetic multi-component LSS. Other coefficient
blocks agree closely. The reported log-SD values correspond to very small
phylogenetic scales; that observation suggests further boundary investigation,
not a completed objective/score/covariance or causal diagnosis. StrictG8 remains
open with both cases retained. It is not a waived tolerance or an exclusion.

The marginal bootstrap simulator still maps unsorted phylogenetic groups by
first-seen order. Profile nuisance convergence/status, analytic-gradient reuse,
efficient refits and the previously measured256tip failed nuisance solve remain
required. No full bootstrap, profile, warm performance or clean-head qualification
follows from this frontend repair.

## 11. Team Learning
Correct convergence flags do not prove that a covariance was assigned to the
right species. Compare the likelihood against an independently named covariance
and challenge first-seen order explicitly. Preserve failure oracles even when
other parts of the repair pass. Exact String conversion admits useful Julia label
types; restricting to AbstractString would have introduced a compatibility bug.
Root actual Sol/medium (plan requested high), Terra/high builder and Melissa,
Sol/high Rose, Luna/low source scout. Active agent-hours remain uninstrumented.

## 12. Cross-Product Coverage
This work does NOT cover every tree provider, all families, every masked-data
cross-product, corrected unsorted bootstrap, large-tree intervals, all registered
warm wins, whole-site renders/deployment, safe worktree cleanup or final integration.
Keep LSS SE/REML/mask/large-tree/final-head obligations, automatic1/2/4/8 policy,
original native scope and all retained failures. No remote compute, installation,
release, registration, deployment or collaborator message occurred this turn.

## Final bounded verification receipt

The final unlazy rerun (`gates-001.log`) exited 1: **7 gates met, 1 unmet**.
All five executable checks ran; G3/G4/G6/G7 passed and strict coefficient G8
failed on exactly the two preserved six-tip comparisons. No gate was abandoned.
This is partial progress, not a completed leaf. Programme G0-G8 remain open.

Reviewed Julia source SHA256:
`4465956f8786436b72827366032178f1a81f0b76582df7f232d155ed624191f9`.
Final regression SHA256:
`9e8f2522841c1294d4cfac6aa11d26fe7c8bd2b1c6d501f2fe22b8391e283068`.
Rose approved the bounded mapping repair and retained strict failure status.
Melissa reconciled the original and approved obligations without exclusions.
Final tutorial build `docs-002.log`: seven examples passed in 20.865 build
seconds (22.82 process seconds); no visual or deployed-page claim.
