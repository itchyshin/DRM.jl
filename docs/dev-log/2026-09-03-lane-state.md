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

## Addendum — 2026-09-04

- **#630 MERGED** (`301121287`) — sparse LSS gradient made O(n+G), not
  O(G·n); refs #627 but does not close it (see below). #632 and #633 are
  pushed and PR'd but **not yet merged** (`gh pr view` returns OPEN,
  `mergeCommit: null` for both as of this checkpoint) — #632 forwards the
  `sparse` bridge option and fail-closes on unknown option keys; #633 fixes
  the sparse-LSS profile data race and closes #631 once it lands.
- **Two collaborator-facing corrections posted to
  Ayumi-495/LS_ecogeographical-rules#28**, both self-corrections against our
  own earlier comment on that thread: (1) the setup guide's own profile
  example passed `threads = TRUE`, so a reader following it literally was on
  the exposed (#631) path, not the safe one we'd first described — the guide
  now passes `threads = FALSE` with a warning until #633 merges; (2) two of
  the guide's stated limits were stale in the collaborator's favour and are
  now marked superseded — the 5,000-species cap is gone (sparse dispatch
  works at N=10,970), and the lss routes are no longer ML-only (REML is
  available there, on the bivariate structured routes, and on Poisson
  random intercepts).

### Open issues — one-line waits (this checkpoint)

- **#616** — OPEN. Waiting on root-causing the Julia-1.10-only CI flake in
  `test_locscale_profile_threads.jl`; #630's gradient fix does not touch the
  Gamma objective this flake drives (explicitly disclaimed in #630's PR body).
- **#620** — OPEN. Waiting on the owner scheduling the Gaussian two-SD
  phylogenetic random slope as a follow-up slice; refusal already landed.
- **#622** — CLOSED (by #623, S7b.6 tripwire hardened) — no longer waiting
  on anything.
- **#624** — OPEN. Waiting on the owner's `q4_vcov`-on-REML decision
  (10.5% gap vs `sdreport()`); #632 forwards bridge options but does not
  touch this.
- **#627** — OPEN. Waiting on a cost diagnosis of the reported 2h02m at
  N=10,970: #630 fixed the gradient's O(G·n) cost (17.4× at 16,384 tips) but
  that leaves the reported runtime ~236× unexplained, so the issue stays
  open pending a run against the reporter's actual empirical phylogeny.
- **#631** — OPEN. Waiting on #633 merging — root cause (a shared
  `Core.Box` making the sparse fit's stored objective thread-unsafe) is
  fixed on the branch (218/218 + 3/3 new tests, oracle agreement 2.8e-6/
  2.0e-6) but the PR has not landed on `main` yet.
