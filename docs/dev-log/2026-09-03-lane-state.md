# Lane state — 2026-09-03 noon checkpoint

Factual snapshot, not an after-task. State of the #563 DRM.jl lane at noon.

## Merge state

- **19 PRs merged on green** since the overnight batch.
- **`main` is at `e0a65f96b`** (merge of #618, CumulativeLogit phylogenetic
  intercept).
- **Programme ledger: 165 met / 30 unmet.**

## Not merged

- **#573** (bridge route-aware convergence diagnostics) — not merged. Its
  `test (1.10)` CI job is FAILING (green on `test (1)` and `docs`); matches
  the still-open #616 Julia-1.10 flake (`test_locscale_profile_threads.jl`,
  profile endpoints not finite, `lower_reason = :not_converged`).

## Open issues — what each is waiting on

- **#606** — S9 follow-ups. Waiting on an owner tolerance decision for the
  ordinal/categorical 4e-6 bar (categorical theta 1.74e-5 off), not a code
  defect.
- **#609** — S10 follow-ups. Waiting on a diagnosis of the factor-predictor
  contrast/coding mismatch and a fix for the conditional-components
  varying-scale route; frozen receipts close once the clone pulls `main`.
- **#616** — Julia-1.10-only CI flake in the profile-threading test. Waiting
  on root-causing the CI-version divergence; currently blocks #573's merge.
- **#620** — silent-drop defect on structured-marker random slopes. Refusal
  landed (#621); waiting on the owner scheduling the Gaussian two-SD
  phylogenetic random slope (drmTMB's target) as a follow-up slice.
- **#622** — CLOSED by #623 (S7b.6 tripwire hardened).
- **#624** — estimator capability parity. Interface honesty landed (#625);
  waiting on the owner's `q4_vcov`-on-REML decision (item 3, 10.5% gap vs
  `sdreport()`).
- **#627** — profile CI impractical at whole-tree scale (2h02m at N=10,970 vs
  1.29s at 2,048); two cheaper explanations already ruled out. Waiting on a
  cost diagnosis of the per-objective-call nuisance re-solve at scale; a
  `wt-627` worktree is active on this now (out of scope for this docs lane).

## Three owner decisions outstanding

1. **q4 covariance on REML fits** (#624 item 3) — native `vcov()` on a
   bivariate q4 REML fit reports ML curvature, 10.5% apart from
   `sdreport()`; needs a call on whether that's acceptable or needs a
   REML-consistent covariance route.
2. **Mean-only phylogenetic REML** — whether REML support for phylogenetic
   mean structures stays scoped to intercept-only (per #621's refusal) or
   extends once the Gaussian two-SD random slope (#620's follow-up) is
   built.
3. **Whether the asymmetric one-sided scale effect from the collaborator's
   issue 2 stays sidestepped** — untouched by today's merged slices; status
   unchanged from before this checkpoint.
