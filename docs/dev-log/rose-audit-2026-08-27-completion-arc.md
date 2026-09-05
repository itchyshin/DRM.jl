# Rose audit — the completion arc, pre-v0.2.0

**2026-08-27, run as an ultracode workflow at the owner's instruction.** Method: six independent
adversarial review lenses over everything the arc merged (DRM.jl #515–#524, drmTMB #1087/#1089/#1091),
each briefed to find what is wrong rather than confirm; every non-low finding then handed to a skeptic
briefed to *refute* it against primary sources. 18 agents, 12 findings verified: **11 confirmed, 1
refuted** — plus 4 low-severity carried unverified. This document is the audit of record; the DoD's
Rose-audit limb.

## Confirmed and FIXED (DRM.jl #525, drmTMB #1093)

1. **The ninth converged site** *(high)* — `_fit_poisson_crossed_laplace` (the generic K≥3 crossed
   route) still reported raw `Optim.converged(res)`: the one fit function the #491 sweep missed,
   because the sweep enumerated `_laplace_outer_converged` call sites and this function never had
   one. Fixed with the same fixed relative criterion; the K=3 testset now carries the
   converged-is-not-for-sale pair. *Lesson: sweeping a helper's call sites cannot find the site
   that never called the helper — sweep the OUTPUT (every `DrmFit(...)` construction), not the
   mechanism.*
2. **The FD clamp comment overstated its guarantee** *(medium)* — `_fd_hessian_step`'s 1e-2 ceiling
   bounds the base step only; `_finite_hessian` scales per coordinate by (1+|θᵢ|). The calibration
   was measured through that same scaling, so the numbers stand; the comment now says what the
   clamp actually guarantees.
3. **Ledger hash citation stale** *(high)* — `general_covariance_structured` cited only the Phase 1
   build (f3e754a4) while the live TSV stamps the Phase 2 re-bank (19ecb005). Both now named, with
   the identical-values fact.
4. **Uncited baseline** *(high)* — `phylo_count_large_p`'s before-fix numbers (1.178e-03/9.01e-04)
   existed only in git history; the boundary now cites the exact commit (DRM.jl c664c4b0) so the
   295×/199× factors are checkable.
5. **Assertion miscount** *(medium)* — `test_cross_family_formula.jl` holds 18 assertions, not the
   24 the cross_family boundary claimed.
6. **README** *(3 findings, medium)* — the head-to-head table's "infeasible (dense)" at p=10,000
   contradicted the ledger's own #486 measurement of native TMB at O(p^1.27) (now "not attempted at
   that scale"); "13 families" omitted SkewNormal (now 14); `report/` holds 53 files, not 13.

## Confirmed and FILED (not blocking the tag)

7. **q4 ML/REML converged semantics differ** *(medium)* → DRM.jl #526. The REML path's inner
   alternation never surfaces its own convergence; both paths' flags are conservative in the
   failure direction, so this is a semantics decision, not a correctness emergency.

## Confirmed but queue-timing artifacts (no action — the queue IS the fix)

Three "high" findings reported merged claims absent from `origin/main`: the #509 q4 gate, the #472
characterisation, and the two "missing" files (`report/speed-per-family.md`,
`src/experimental/README.md`). All four live in PRs #518–#521, armed in the merge queue at audit
time. These findings are the audit *verifying the queue's contents match the claims* — they dissolve
as the queue drains, and they flag one wording lesson: an after-task report should say "queued as PR
#N", never "landed", for anything the cascade has not yet merged.

## Refuted (1)

- *"Bivariate q2 arm silently drops method=REML"* — the code literally returns early, but the
  skeptic confirmed q2 REML is gated upstream before the options builder is consulted, so no REML
  request can reach the early return. Plausible reading of one function; wrong at the system level —
  the failure mode this audit design exists to catch.

## Unverified lows → batched as DRM.jl #527

Ladder arms without pinning tests; a defensive-default gap for family-type-less payloads; a
leak-guard test that may assert the wrong gate fired.

## Verdict

**PASS for v0.2.0, conditional on PRs #525 (DRM.jl) and #1093 (drmTMB) merging** — both contain
only audit fixes and are in their queues. The arc's headline claims (the completed ledger, the SE
parity numbers, the byte-identity of include/drop, the honest-flag semantics) all survived
adversarial verification; what the audit caught was one genuinely missed code site, provenance
citation gaps, and public-text drift — exactly the classes a pre-release audit exists for.
