# After-Task Report: CumulativeLogit phylogenetic intercept (#618, #563 S8)

- **Date:** 2026-09-03
- **Issue:** #563 (S8, remaining engine gaps); PR #618, branch
  `feat/563-cumlogit-phylo` (stacked on #617; base `feat/563-cumlogit-ranef`,
  to retarget to `main` once #617 merges) @
  `060c70b3bdc0c762cdc2914bcaf8097026b0f8af`
  (**PR open at report time — not yet merged; also blocked on #617 merging first**)
- **Perspectives:** Shannon (Coordination/Rose after-task pass, retrospective);
  Noether (adversarial review, session note `review-cumlogit-phylo.md`)

## 1. Goal

Add the one structured cell drmTMB 0.7.0 admits for `cumulative_logit()`: an
unlabelled, intercept-only `phylo(1 | species)` on the mean
(`validate_ordinal_phylo_mu_structured_term`, `R/drmTMB.R:10500`). Labelled
markers and slopes must stay refused.

## 2. Implemented

- The ordinal likelihood (cumulative-logit differences of thresholds minus η) is
  supplied, with first and second η-derivatives, to the existing sparse-Laplace
  GLMM route already used by Poisson/Gamma/Binomial/Beta phylo intercepts
  (`_cumulative_phylo_kernel`, `_laplace_value`/`_laplace_d12` for
  `Val(:cumlogit)`, `_fit_cumulative_phylo_laplace`).
- The threshold gradient terms are derived with boundary categories as limits of
  the interior two-threshold formula (the "phantom boundary" reduction —
  independently re-derived and confirmed by Noether's review, §1 below).
- `src/cumulative.jl`: +576 lines (net, vs the #617 base) for the phylo route.

## 3a. Decisions and Rejected Alternatives

- **Reuse the sparse-Laplace GLMM spine** (`sparse_laplace_glmm.jl`'s
  `_phylo_mean_mode` / `_phylo_mean_laplace_*_fg` pattern) rather than a
  bespoke phylo-ordinal solver — the PR's own scope check (confirmed by review
  §5) shows the change is confined to `src/cumulative.jl` plus tests/fixtures/
  docs, with **no edit to the shared spine**, so no other family can regress.
- **One formula covers all three category cases** (interior, top, bottom) by
  substituting vanishing sigmoid derivatives at the phantom boundary
  (`σ(±∞)` and its derivatives → 0/1/0), rather than three separate branches —
  independently re-derived by the reviewer and confirmed exact in the limit
  (§1, §3a below).
- **`re_sd(fit)[:species]` reported on the RAW branch-length scale**, matching
  drmTMB's own convention only after a `√h` (tree-height) conversion — decision
  carried over from the existing Gaussian-phylo-mean parity test's convention,
  not invented fresh for this PR.

## 3b. Review Findings and Applied Edits (Opus/Noether adversarial review)

An independent adversarial review (session note
`review-cumlogit-phylo.md`, target `origin/feat/563-cumlogit-phylo` @
`b8795423`, the pre-fix commit) hand-re-derived every kernel term against the
code, cross-checked against 220-bit BigFloat finite differences (2100 random
cases; max rel err ≤ 1.5e-08 across `d1`/`d2`/`d3`/`nval_*`/`nr_*`), verified the
whole Laplace objective against an independently written dense Laplace
(`|Δ| = 1.4e-14`), and verified the analytic outer gradient against central FD
at **non-optimal** θ (best-h agreement 1.7e-09 … 4.3e-09 across β/cutpoints/logσ
on the 60-tip fixture). **Verdict: APPROVE WITH REQUIRED EDITS.**

Findings and disposition, all confirmed applied on the branch tip
(`060c70b3`, verified in this after-task pass by reading the current test/
source files, not merely trusting the PR description):

- **D-1 (REQUIRED, applied).** The PR's original FD gradient test evaluated the
  gradient *at the optimum*, where `‖g‖ ≈ 1e-10` and a loose `atol` passes for
  essentially any gradient function (including a sign-flipped or zero one) —
  measured per-coordinate relative error was 1.0 in every block and the test
  still passed. **Fix applied:** the test now evaluates at a deliberately
  off-optimum θ (`θ0 .+ [0.25, -0.20, 0.15, 0.30]`, with the logσ coordinate
  re-based to `log(0.4)` to avoid a pre-existing clamp plateau — see D-5) with
  `h = 3e-4` (noise-optimal step for this tree size) and `rtol = 1e-5, atol =
  1e-6`. Confirmed present at `test/test_cumlogit_phylo.jl` (the
  "sparse-Laplace gradient sanity" testset).
- **D-2 (SUGGESTION, applied).** The top-category kernel formed `D = ga - gb`
  by subtraction, which cancels as `η − c` grows (relative error 1.8e-08 at
  `η−c=20`, 3e-01 at 37, `D=0 → v=Inf` from `η−c≈38`) — a robustness cliff, not
  reached by the fixture or reviewer's synthetic runs (`|η−c| ≲ 5`), but fixed
  anyway. **Fix applied:** `D` for the top category is now formed via the exact
  logistic-complement identity rather than subtraction, matching the
  fixed-effects route and drmTMB's `drm_log1m_inv_logit`. Confirmed present as
  the "top-category kernel stays finite at extreme η (Opus review D-2)" testset
  in `test/test_cumlogit_phylo.jl`, asserting finiteness at `η − cuts[2] ≈ 35`.
- **D-3 (SUGGESTION, applied).** The docstring did not state that
  `re_sd(fit)[:group]` on the `phylo` route is on the RAW branch-length scale
  (a `√h` factor off drmTMB's correlation-scale convention). **Fix applied:**
  the docstring now states this explicitly (confirmed at
  `src/cumulative.jl:36`).
- **D-4 (INFORMATIONAL, not addressed in this PR).** `se = true` is the route
  default but has no independent oracle — the parity test asserts with
  `se = false` (matching drmTMB's own gate for this test). The reviewer verified
  SEs are at least finite and PD on the fixture but recorded no correctness
  evidence beyond that. **Left open** — see §10/§12.
- **D-5 (INHERITED, not this PR's bug).** The `clamp(θ[pμ+nc+1], -8.0, 3.0)` on
  `logσ` makes the objective flat below −8 while the analytic gradient still
  reports the pre-clamp derivative. Identical code exists on `main` in
  `_phylo_mean_laplace_nuisance_fg`/`_phylo_mean_laplace_hetero_fg`; not
  introduced by this PR and not fixed here. Noted only so this PR is not
  blamed for it (and it is the reason the D-1 test re-bases the logσ start
  point rather than perturbing the fitted value directly).

## 4. Files Touched

Per `git diff --stat origin/main...origin/feat/563-cumlogit-phylo` (cumulative
vs `main`, i.e. including the stacked #617 changes):

```
docs/design/capability-status.md                    |  15 +
docs/src/families.md                                |  21 +
docs/src/model-guides/model-map.md                  |   5 +
src/cumulative.jl                                    | 576 ++++++++++--
test/parity/fixtures/cumlogit-mu-phylo/data.csv      | 301 ++++++++
test/parity/fixtures/cumlogit-mu-phylo/gen_data.R    |  80 ++
test/parity/fixtures/cumlogit-mu-phylo/tree.newick   |   1 +
test/parity/fixtures/cumlogit-mu-ranef/data.csv      | 811 +++++++++++++++++++++
test/parity/fixtures/cumlogit-mu-ranef/gen_data.R    |  43 ++
test/parity/fixtures/cumlogit-mu-slope-ranef/data.csv| 601 +++++++++++++++
test/parity/fixtures/cumlogit-mu-slope-ranef/gen_data.R | 47 ++
test/runtests.jl                                     |   2 +
test/test_cumlogit_phylo.jl                          | 183 +++++
test/test_cumlogit_ranef.jl                          | 146 ++++
14 files changed, 2791 insertions(+), 41 deletions(-)
```

(The `cumlogit-mu-ranef`/`cumlogit-mu-slope-ranef` fixtures and
`test_cumlogit_ranef.jl` are inherited from the #617 base branch this PR stacks
on, not new in #618 itself; the #618-specific additions are the
`cumlogit-mu-phylo` fixture/tree and `test_cumlogit_phylo.jl`.)

## 5. Checks Run

- **RED first:** `test/test_cumlogit_phylo.jl` errored on the base (no `tree`
  keyword; structured markers refused), per PR body.
- **GREEN 14/14.** Same-target vs drmTMB 0.7.0 (60-tip `ape::rcoal` tree,
  n = 300, K = 3, Brownian phylo intercept; fixture + tree + `gen_data.R`
  committed; both sides Laplace):

  | quantity | DRM.jl | drmTMB | gap | tolerance |
  |---|---|---|---|---|
  | β | 0.66487677 | 0.6648765 | 2.7e-7 | 1e-3 |
  | cutpoints | −0.31043, 0.85916 | −0.31043, 0.85916 | 9.6e-7 | 1e-3 |
  | phylo SD | 1.4718243 | 1.471822 | 1.6e-6 rel | 1e-3 rel |
  | logLik | −269.556338 | −269.5563 | 3.8e-5 | 0.01 |

  Plus a finite-difference gradient check on a small synthetic tree
  (rtol 5e-3, per PR body's original claim — **note:** the review's applied
  D-1 fix tightened the *in-file* off-optimum test to `rtol = 1e-5`; both
  numbers are cited here because they come from different tests — the PR
  body's own summary table describes the original design intent, and the
  landed test file (read directly, see §3b) is the stricter, applied version).
- **Neighbours green (per PR body):** cumlogit iid (#617) 14/14, ordinal
  recovery 4/4, Poisson/Binomial/Gamma/Beta phylo sparse-Laplace routes and
  gradients (12 sets).
- Wired mid-file in `test/runtests.jl`; `docs/src/families.md`,
  `docs/design/capability-status.md` updated.
- **Test file count check (this after-task pass):** the landed
  `test/test_cumlogit_phylo.jl` on the branch tip contains 20 `@test`
  assertions (counted directly from the file), consistent with the PR's
  reported 14/14-plus-the-two-review-added testsets (off-optimum gradient
  sanity, top-category finiteness).
- A full local `Pkg.test()` aborted earlier in the suite at
  `test_bootstrap_marginal.jl` (the #461/order-dependent set — not touched
  here); verification is per-file, per the PR body.

## 6. Tests of the Tests

- Same-target comparison against an **independently fitted drmTMB 0.7.0 model**
  on a 60-tip tree (both sides genuinely Laplace-approximated, not the same
  code path), so a wrong kernel would show up as a Δ well outside tolerance.
- The reviewer's own independent verification (hand re-derivation, BigFloat FD,
  an independently written dense Laplace, and off-optimum central FD) is a
  second, code-independent line of evidence beyond the PR's own test suite —
  and it is what caught D-1's vacuous test in the first place (the original FD
  test would have passed for a **sign-flipped or zero gradient function**,
  which is a strong "tests of the tests" finding in itself, now fixed).
- The applied D-1 fix specifically converts an unfalsifiable test (passes for
  wrong code) into a falsifiable one (rtol 1e-5 at a genuinely off-optimum θ,
  margin ≤ 6e-8 measured on a synthetic tree) — this is the textbook
  "tests of the tests" case for this slice.

## 7a. Issue Ledger

- Advances #563 S8 by adding the CumulativeLogit phylogenetic-intercept cell.
- **Blocked on #617 merging first** (this PR is stacked on #617's branch and
  needs to retarget to `main` once #617 lands) — not yet actionable as an
  independent merge.
- Adversarial review (session note `review-cumlogit-phylo.md`) is now
  APPROVE-WITH-REQUIRED-EDITS **and confirmed applied** (D-1, D-2, D-3 all
  present on the branch tip, verified directly in this pass). D-4 remains an
  open informational item; D-5 is explicitly inherited, not this PR's bug.
- **PR #618 was still OPEN (not merged) at the time of this report.**

## 8. Consistency Audit

- Review §5 (Scope check) confirms the change is confined to
  `src/cumulative.jl` plus tests/fixtures/docs — **no edit to the shared
  `sparse_laplace_glmm.jl` spine**, so no other family using that spine
  (Poisson/Gamma/Binomial/Beta phylo intercepts) can regress from this PR.
  `Val(:cumlogit)` defines only `_laplace_value`/`_laplace_d12`, exactly the
  pair `_phylo_mean_mode` needs.
- The sign convention was checked against drmTMB's actual C++ source
  (`drmTMB.cpp:3784–3805`), not assumed from symmetry — reviewer traced the
  0-based-to-1-based index translation explicitly and confirmed the increment
  parameterisation and boundary-branch assignment both match.
- This after-task pass independently re-read the current branch-tip source and
  test files (not just the PR description) to confirm the three required/
  suggested review edits actually landed — they did (§3b).

## 9. What Did Not Go Smoothly

- The PR's original FD gradient test was vacuous (D-1) — evaluated at the
  optimum, where it would pass for a wrong gradient function. This was caught
  only by an independent adversarial review, not by the author's own RED-first
  discipline (RED-first here confirmed the test *fails without the feature*,
  which is a weaker guarantee than *fails when the feature is wrong*).
- The top-category kernel had a latent robustness cliff (D-2) that neither the
  fixture nor the author's own synthetic runs reached (`|η−c| ≲ 5` in all
  cases tried), so it would not have been caught without the reviewer's
  targeted extreme-η probe.
- This PR cannot merge independently — it is stacked on the still-open #617
  and needs a retarget once that lands.

## 10. Known Residuals

- **`se = true` is unexercised** (D-4): it is the route default, but no
  independent oracle checks the resulting vcov beyond "finite and PD on the
  fixture" — mirrors drmTMB's own phylo-ordinal test, which also disables SE.
- **D-5 (inherited clamp/gradient inconsistency on `logσ`)** exists in shared
  code (`_phylo_mean_laplace_nuisance_fg`/`_phylo_mean_laplace_hetero_fg` on
  `main`), not introduced or fixed by this PR.
- **Stacked-branch state:** PR #618 targets `feat/563-cumlogit-ranef` (#617),
  not `main` — must retarget once #617 merges; this report describes the
  branch tip as of `060c70b3`, which may shift when rebased.
- A full local `Pkg.test()` aborts earlier in the suite at the pre-existing,
  order-dependent `test_bootstrap_marginal.jl` flake (not touched here);
  verification is per-file only, not a clean whole-suite run.
- One seed / one fixture (60-tip tree, n=300, K=3) for the phylo same-target
  comparison — no multi-seed or multi-tree-size campaign.

## 11. Team Learning

- **An FD gradient test evaluated at the fitted optimum is close to
  unfalsifiable** — `‖g‖` is near machine noise there and a loose `atol`
  passes for almost any gradient function. The durable pattern (now landed in
  `test_cumlogit_phylo.jl`) is: perturb θ off the optimum by a fixed,
  meaningfully large offset per block, pick `h` from a noise-floor sweep (not a
  round number), and tighten `rtol`/`atol` accordingly. This generalises to any
  future analytic-gradient-vs-FD test in this codebase.
- **The "phantom boundary" reduction** (one formula for interior/top/bottom
  ordinal categories, via vanishing sigmoid derivatives at `σ(±∞)`) is now
  independently re-derived and numerically confirmed (BigFloat FD to
  `M=40,80` giving exactly 0.0 residual) — a reusable pattern for any future
  ordinal/threshold-based kernel.
- **Cheap log-domain stabilisation (D-2's fix) is worth doing even when the
  fixture never reaches the danger zone** — the cost was low and it removes a
  latent `Inf`/`NaN` propagation path for future callers with more extreme η.

## 12. Cross-Product Coverage

Adding a structured (phylogenetic) marker to CumulativeLogit is a cross-cutting
capability (a family gains a new structured-RE surface via the shared
sparse-Laplace GLMM spine, alongside its existing iid-RE surface from #617).

- **Covers ✓:** unlabelled, intercept-only `phylo(1 | species)` on the mean;
  β/cutpoints/phylo-SD/logLik same-target validated vs drmTMB 0.7.0 (60-tip
  tree, K=3); off-optimum analytic-vs-FD gradient check (β, cutpoints, logσ,
  rtol 1e-5, applied per D-1); finite top-category kernel at extreme η
  (applied per D-2); `re_sd` scale convention documented (applied per D-3);
  confirmed no regression to the shared sparse-Laplace GLMM spine used by
  Poisson/Gamma/Binomial/Beta phylo intercepts.
- **Does NOT cover:** labelled phylo markers or phylo slopes for
  CumulativeLogit (refused); `se = true` correctness on the phylo route
  (D-4, unexercised beyond finite/PD); the inherited `logσ` clamp/gradient
  inconsistency (D-5, not fixed, shared code); multi-seed or multi-tree-size
  same-target evidence (one fixture only); a clean whole-`Pkg.test()` run (the
  pre-existing `test_bootstrap_marginal.jl` order-dependent flake aborts the
  full suite; verification here is per-file); merge/landing status (PR #618 was
  open, stacked on the also-open #617, at report time — neither had merged).
