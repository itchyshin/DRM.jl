# After-Task Report: exact gradient of the q=4 REML objective (#575)

- **Date:** 2026-09-02
- **Issue:** #575 (closes #575 on merge of PR #579)
- **Branch:** `feat/575-exact-reml-gradient`
- **Perspectives:** Shannon (Coordination), Noether (Math/Engine), Fisher (Inference), Rose (Gate)

## 1. Goal

Replace the finite-difference (FD) gradient in the q=4 REML mode-finder
(`fit_q4_reml`, `src/reml_q4.jl`) with an exact O(p) gradient, closing #575
("q4 phylo bivariate REML: bridge fit lands at slightly inferior optimum vs
TMB") — and determine whether the earlier reported "suboptimal basin" was a
real feature of the REML surface or an artefact of FD/mode-solve noise.

## 2. Implemented

- **Derivation** (`docs/src/developer-notes/reml-q4-exact-gradient.md`, commit
  `11e13860`): the implemented REML objective collapses to a single Laplace
  form over the augmented state `z = (u, β)`, `L_REML(φ) = −J(ẑ;φ) − ½
  logdet 𝓗 + ½ logdet P`, with `𝓗 = [[A,B],[B',D]] = [[H_uu, H_uβ],[H_uβ',
  H_ββ]]` built from the same per-leaf 4×4 `leaf_hess` as the ML objective.
  This makes the REML objective structurally identical to
  `fit_q4_sparse_tmb.jl`'s ML objective, so its exact O(p) implicit-function
  gradient transfers term-by-term with the leaf selected-inverse block
  replaced by `Ω_i = Vsel[leaf block] + G_i S⁻¹ G_iᵀ`, `G_i = C[leaf
  block,:] − F_i`. `𝓗` is never formed or factorised — everything is built
  from the existing CHOLMOD factor of `A`, its Takahashi selected inverse,
  and the small dense `S`. Complexity O(p·n_β²).
- **Exact gradient, test-first** (`7a05a7ca` RED → `12f758ec` GREEN): new
  public-in-module entry points in `src/reml_q4.jl` — `reml_nll_exact`,
  `reml_nll_and_exact_grad`, and `_reml_joint_newton` (joint (u,β) Newton on
  the bordered solve).
- **Certification + wiring** (`f5f8a600`): `fit_q4_reml`'s `fg!` now returns
  `reml_nll_and_exact_grad`'s value and gradient at a joint-Newton-certified
  mode, replacing the central FD (`h_inner = 5e-4`, mode alternation re-run
  per perturbation). The inner-convergence flag (#526) is now `‖∇_z J‖ <
  1e-6` at the returned point, measured directly, instead of the
  alternation's relative-β proxy. The final evaluation goes through the same
  exact path so objective, mode and `g_residual` describe one point.
  Exact-gradient polish at 10× tighter `g_tol` is adopted only if converged,
  no worse in objective, and strictly better in `g_residual`, with
  `u_cache`/`beta_cache` restored on rejection.
- **No-regression + target** (`35201b00`): `test/test_575_q4_optimum.jl`
  brought over from `fix/575-q4-optimum`; `@test_broken` flipped to `@test`;
  passes.
- **Rose D-43 remediations** (`c1773e21`): wired both new test files into
  `test/runtests.jl`; amended `expected.toml`'s
  `[status].reml_restriction_note` in place, appending a dated correction
  that withdraws the finite-difference-regime premise that had justified
  `rtol_coef = 10%`.
- **Documenter fix** (`cda42b8c`, committed after this ledger's briefing was
  written — see §9): PR #579's docs CI job failed with `:missing_docs` on
  `DRM.reml_nll_exact` and `DRM.reml_nll_and_exact_grad`. Fixed by adding an
  `## 4. API` `@docs` block to the derivation note, listing the note in the
  Documenter "Development" nav (`docs/make.jl`), and adding a `reml_q4.jl`
  row to `docs/src/developer-notes/source-map.md`.

## 3a. Decisions and Rejected Alternatives

- **Derivation-first, not another basin-selection heuristic.** Per the issue
  thread's own history, four within-basin/warm-start remedies were tried and
  measured before this slice — tighter-g_tol restart, NM+LBFGS single pass
  (−219.6258), looped NM+LBFGS (−219.6252), bounded jittered multistart
  (−219.6243, best but `g_residual > g_tol`) — all rejected because they
  either stayed short of the −219.6206 floor or broke the engine-level
  convergence contract. A structured K=5 warm-start-candidate design was
  then tried and reverted twice more (same-basin no-op; then a contract
  violation) before the hypothesis sharpened to "the FD gradient's noise
  floor sits at `g_tol`, so convergence is being certified on noise, not on
  a real optimum." This slice tested that hypothesis directly by deriving
  the exact gradient instead of adding a fifth warm-start heuristic.
- **`_reml_prior_precision` stores all 16 entries of the 4×4 axis block**
  rather than fixing `prior_precision`'s `sparse(Λinv)` zero-dropping
  globally. `prior_precision` is shared with the ML path
  (`fit_q4_sparse_tmb.jl`), and fixing it there was explicitly out of scope
  for #575 (tracked as #577) — a narrower, path-local fix was chosen to
  avoid touching ML-path behaviour in a REML-scoped slice.
- **Exact-gradient polish is accept/reject, not always-applied**: adopted
  only if converged, no worse in objective, and strictly better in
  `g_residual`, with cache restore on rejection — chosen over unconditional
  polish because of the cache-corruption hazard the issue thread's own
  basin-selection attempt found (rejected trials silently corrupting the
  accepted point's reported objective via shared `fg!` mutation of
  `u_cache`/`beta_cache`).
- **`_reml_border_blocks`'s mask-consistency change left untested** rather
  than adding missing-response REML coverage in this slice — deferred as
  #578 to keep the slice scoped to the gradient fix.

## 4. Files Touched

Branch diff, `origin/main..HEAD` (source: `git diff --stat
origin/main..HEAD` in the working directory):

- `docs/make.jl` (+1)
- `docs/src/developer-notes/reml-q4-exact-gradient.md` (+198)
- `docs/src/developer-notes/source-map.md` (+1)
- `src/reml_q4.jl` (+547/−88 net, see diffstat: `547 +++++++++++++++++----`)
- `test/parity/q4-reml/biv-q4-phylo-reml/expected.toml` (+1/−1)
- `test/runtests.jl` (+2)
- `test/test_575_exact_reml_gradient.jl` (+136)
- `test/test_575_q4_optimum.jl` (+70)

This ledger (written by Rose, not counted in the branch diffstat above):

- `docs/dev-log/after-task/2026-09-02-575-exact-reml-gradient.md`
- `docs/dev-log/check-log.d/2026-09-02-575-exact-reml-gradient.md`

Note on the three docs-wiring files (`docs/make.jl`,
`docs/src/developer-notes/reml-q4-exact-gradient.md`,
`docs/src/developer-notes/source-map.md`): this task's briefing described
them as uncommitted at task start; by the time this report was written they
had been committed as `cda42b8c` (`git log` above), so the branch now carries
7 commits, not the 6 recorded mid-slice. See §9.

## 5. Checks Run

- **Exact-vs-FD gradient test** (`test/test_575_exact_reml_gradient.jl`,
  source: `scratchpad/exact-grad-summary.md` §G2): central-difference check
  at three φ points (`ML-scale start`, `DRM.jl optimum`, `TMB fitted point`),
  each `‖∇_z J(ẑ)‖ < 1e-8`:
  - `ML-scale start`: max_abs_err = 2.8230790594108157e-8, rel =
    2.413456623609924e-9
  - `DRM.jl optimum`: max_abs_err = 6.13858829878744e-8, rel =
    6.13858829878744e-8
  - `TMB fitted point`: max_abs_err = 3.175936257471951e-8, rel =
    3.175936257471951e-8
  - `Test Summary: issue #575: exact q4 REML gradient matches a tight
    central difference | Pass 12 Total 12 | Time 48.2s` (17.5s on the
    subsequent no-regression run, 25.3s on the full-suite run — see below).
- **Target/no-regression suite** (source: `exact-grad-summary.md` §G4):
  ```
  issue #575: q4 REML reaches its own optimum                              | Pass 1  Total 1  | 31.9s
  q4 phylo REML: public drm() converges through public kwargs alone (#484) | Pass 3  Total 3  | 0.6s
  q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484) | Pass 3  Total 3  | 0.7s
  issue #575: exact q4 REML gradient matches a tight central difference    | Pass 12 Total 12 | 17.5s
  biv_q4_phylo_reml same-target fixture (#433)                             | Pass 33 Total 33 | 31.8s
  REML q4: restricted correction reaches all four axes (#18)               | Pass 9  Total 9  | 5.7s
  ```
  Wider sweep, all green: niterations 20/20, q2 REML
  (`test_reml_q2_structured.jl`, 6 testsets) 34/34, bivariate Student-t
  17/17, bivariate lognormal 46/46, bivariate q=4 relmat/animal/spatial/
  validation/gradient/#509 35/35, bivariate q=4 phylo front end (4
  testsets) 47/47, missing data listwise deletion (#49) 30/30.
- **Full suite** (`julia --project=. -e 'using Pkg; Pkg.test()'`, source:
  `exact-grad-summary.md`, tail): exit 0, ~24 min. Aggregated over 383
  parsed `Test Summary` blocks: **Pass = 9203, Fail = 0, Error = 0, Broken =
  1, Total = 9204**. Zero occurrences of `Test Failed` or `Error During
  Test` in the log. The one `Broken` is pre-existing and unrelated: `Gaussian
  LSS phylogenetic tip identity | Pass 406 Broken 1 Total 407 | 15.3s`. The
  #575/#484/#433/#18 lines from the same full-suite run:
  ```
  biv_q4_phylo_reml same-target fixture (#433)                              | Pass 33 Total 33 | 1.1s
  q4 phylo REML: public drm() converges through public kwargs alone (#484)  | Pass 3  Total 3  | 0.8s
  q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484)  | Pass 3  Total 3  | 0.8s
  issue #575: exact q4 REML gradient matches a tight central difference    | Pass 12 Total 12 | 25.3s
  issue #575: q4 REML reaches its own optimum                              | Pass 1  Total 1  | 0.9s
  REML q4: restricted correction reaches all four axes (#18)               | Pass 9  Total 9  | 3.6s
  ```
  Verbatim log retained at `scratchpad/full-suite.log`.
- **Bridge re-measure** (source: `scratchpad/p14-remeasure.md`, R↔Julia
  bridge pointed at this worktree at `35201b00`, fixture
  `test/parity/q4-reml/biv-q4-phylo-reml`), verbatim result line:
  ```
  Q4_FIXTURE_BRIDGE_PARITY_V3 conv_tmb=TRUE conv_julia=TRUE ll_delta=1.9169825e-05 max_coef_delta=0.00016828466 tmb_s=0.928 julia_s=0.876 n_common=7 tmb_conv_msg=NA
  ```
  Against the fixture's recorded tolerances (`expected.toml [tol]`:
  `atol_loglik = 0.03`, `atol_coef = 0.0251`, `rtol_coef = 0.10`): ll_delta
  1.917e-05 vs 0.03 (≈1560× margin), max_coef_delta 1.683e-04 vs 0.0251
  (≈149× margin). Both engines converged (n_common = 7 coefficients
  compared). **GATE-PASS on the log-likelihood and coefficient axes only**
  — no SE or interval evidence was re-measured (see §10).
- **PR #579 CI**, `test/parity/q4-reml/biv-q4-phylo-reml` commit
  `c1773e21` (source: task briefing, confirmed live via `gh api
  repos/itchyshin/DRM.jl/commits/c1773e21/check-runs` during this session):
  `test (1)` — success; `test (1.10)` — success; `docs` — **failure**, on
  Documenter's `:missing_docs` check for `DRM.reml_nll_exact` and
  `DRM.reml_nll_and_exact_grad`. That failure is what the `cda42b8c`
  docs-wiring commit addresses (§2). At the time this report was written,
  `gh pr checks 579` showed `docs`, `test (1)`, `test (1.10)` all
  **pending** on the new commit `cda42b8c` — the fix's own CI result was not
  yet available and is not claimed here (see §10).

## 6. Tests of the Tests

`test/test_575_exact_reml_gradient.jl` is RED-first: written failing at
`7a05a7ca`, made to pass by the implementation at `12f758ec` (source:
`exact-grad-summary.md` commit table and §G2). The RED test caught a real
defect rather than passing vacuously: `prior_precision(Q, Λ⁻¹)` calls
`sparse(Λinv)`, which drops zeros; at an exactly diagonal Λ — including
`fit_q4_reml`'s own default warm start `Λ0 = 0.3I(4)` — the cross-axis
entries of `H_uu` at non-leaf nodes are structurally absent, so the
Takahashi selected inverse cannot supply entries the logdet-H trace needs.
Two `lc` gradient components came out wrong by **0.037** and **13.70**
against the RED test's central-difference check; with a 1e-6 off-diagonal
added the fix under test, every component agreed to **6.7e-8**. Separately,
`test/test_575_q4_optimum.jl`'s target assertion was carried over from
`fix/575-q4-optimum` as `@test_broken` (recording the pre-fix failure) and
flipped to `@test` only at `35201b00`, after the fix landed — i.e. the test
is on record as having failed against the pre-fix code, not only written
after the fact.

## 7a. Issue Ledger

- **#575** — fix; closes on merge of PR #579. Root cause: the q4 REML
  mode-finder certified convergence on a finite-difference gradient whose
  noise floor sat at `g_tol`, producing an apparent suboptimal-basin
  artefact; the exact gradient shows one optimum, reached by both the
  cold-start and TMB-warm-start routes (`−219.614005` /
  `−219.614006`, 2e-5 from drmTMB's `−219.613986`).
  - Comment chain on #575 (source: `gh issue view 575 --json comments`, run
    in the working directory during this session) records five stages:
    mechanism established (mode-finder, not objective translation) →
    plateau report (basin selection, four remedies measured and reverted) →
    second basin-selection attempt (plateau ×2, reverted, hypothesis
    sharpened to the exact gradient) → FIXED (pending independent
    verification) → verified close-out (this slice's D-43 completion panel).
- **#577** — opened, carved out, still **OPEN**. `prior_precision`'s
  structural-zero degeneracy (same defect the #575 RED test caught) remains
  unguarded on the ML path (`marginal_and_exact_grad`,
  `fit_q4_sparse_tmb.jl:374–384`, which builds its `Gst` from the same
  construction). The ML fit also starts at `Λ0 = 0.3I`, so its first exact
  gradient is taken at the degenerate point.
- **#578** — opened, carved out, still **OPEN**. `_reml_border_blocks` now
  passes `prob.obs1/obs2` to `leaf_hess`, matching `H_uu`'s masking; the
  inline build it replaced did not. Identical for fully-observed data; for
  missing responses this makes the Schur complement mask-consistent, but no
  test covers q4 REML with missing responses, so this is an unverified
  consistency change, not a verified fix.
- **#484, #433, #18** — regression coverage exercised, not modified: #484
  (q4 phylo REML public-route and engine-level convergence, 3/3 + 3/3), #433
  (`biv_q4_phylo_reml` same-target fixture, 33/33), #18 (REML q4 restricted
  correction across all four axes, 9/9) — all green in both the
  no-regression and full-suite runs (§5).

## 8. Consistency Audit

- **Same-class defect (structural-zero degeneracy) searched, not fully
  fixed.** The RED test found `prior_precision`'s zero-dropping on the REML
  path; the same construction was checked against its ML-path caller
  (`marginal_and_exact_grad`) and confirmed to share the defect — filed as
  #577 rather than silently left, but not fixed in this slice (out of scope
  for a REML-scoped issue).
- **Mask-consistency swept across the REML border-block change.**
  `_reml_border_blocks` passing `prob.obs1/obs2` to `leaf_hess` was checked
  against the inline construction it replaced (identical for fully-observed
  data) and the missing-response case was identified as genuinely different
  and untested — filed as #578 rather than assumed safe.
- **Surface enumeration**: `fit_q4_reml` has exactly one caller in `src/`
  (`gaussian_bivariate.jl`), so the q4 REML route the target/no-regression
  suite (#575, #484, #433, #18) and the full-suite run exercise is the whole
  affected surface, not a sample of it.
- **Cache-corruption class checked**: the polish-acceptance path
  (`u_cache`/`beta_cache` snapshot/restore on rejection) was implemented in
  direct response to the corruption hazard the issue thread's own prior
  basin-selection attempt had already found and documented; verified present
  in this slice's implementation rather than re-discovered.

## 9. What Did Not Go Smoothly

- **Four warm-start/polish strategies were tried and reverted before the
  derivation-first fix** (tighter-g_tol restart, NM+LBFGS single pass,
  looped NM+LBFGS, bounded jittered multistart, then a structured K=5
  warm-start design across two cycles) — recorded in the issue's own
  "plateau" comments. Each was measured honestly and reverted when it either
  missed the floor or broke the engine-level `g_residual < g_tol` contract.
- **A speculative optimizer trial silently corrupted the accepted point's
  reported objective** during the second basin-selection attempt (rejected
  trials mutated the shared `u_cache`/`beta_cache` Refs via `fg!`,
  `−219.6302 → −219.6344`) until snapshot/restore was added. Committed code
  in this slice has no speculative trials so this hazard is not currently
  triggered, but is recorded as a standing constraint on any future
  multistart/polish work.
- **PR #579's Documenter CI job failed on `:missing_docs`** for
  `DRM.reml_nll_exact` and `DRM.reml_nll_and_exact_grad` at commit
  `c1773e21`, requiring the separate `cda42b8c` docs-wiring commit. This
  task's own briefing was written while that commit was still uncommitted
  in the working tree; by the time this report was drafted it had already
  been committed independently (§4) — an example of state moving out from
  under a ledger-writing task mid-session, caught by re-checking `git
  status`/`git log` rather than trusting the briefing's snapshot.
- **`cda42b8c`'s own CI result was not available at report time** (`gh pr
  checks 579` showed `docs`, `test (1)`, `test (1.10)` all `pending` on that
  commit) — recorded as a residual, not claimed as green (§10).

## 10. Known Residuals

- **Standard errors and intervals were NOT re-measured**; only the
  log-likelihood and coefficient axes were compared. `interval_status` is
  unchanged. `rtol_coef = 10%` now stands unjustified rather than
  justified; re-deriving it needs a fresh drmTMB Wald-SE refit that was not
  run.
- **#577** (ML-path `prior_precision` structural-zero degeneracy) is open
  and unfixed; the ML fit's first exact gradient is taken at a degenerate
  point by construction (default warm start `Λ0 = 0.3I`).
- **#578** (untested `_reml_border_blocks` mask-consistency change for q4
  REML with missing responses) is open; no test exercises this path.
- **Run-to-run BLAS/SuiteSparse noise on this pipeline is documented at
  ~1e-3** on `reml_loglik` (per the issue thread's plateau-report comment) —
  relevant to any future fixed tolerance on this fixture.
- **Speed is an observation, not a benchmark.** The exact path costs one
  mode solve per evaluation instead of `2·nph + 1` (nph = 11, so ~23× fewer
  mode solves — the issue thread's own phrasing, "observation, not a
  benchmark"). Wall-clock timings recorded (`fit_q4_reml` ~0.5s once
  compiled; bridge re-measure `tmb_s=0.928`, `julia_s=0.876`) were not
  controlled measurements and no speed claim is made.
- **`cda42b8c`'s CI result is not yet confirmed** (pending at report time,
  §9) — the docs-wiring fix is believed correct (adds the missing `@docs`
  entries) but its own green run was not observed by this report.
- **`reml_ll_and_mode` (`src/reml_q4.jl:309`) still calls the unguarded
  `prior_precision`** — recorded as not a defect in this slice's own
  derivation note: its only caller on the exact path, `_reml_exact_state`,
  uses it only to reach the right neighbourhood, discards that `P`, and
  re-certifies against the guarded `_reml_prior_precision`, so nothing
  derived from the unguarded `P` reaches the objective, gradient, or
  reported fit.

## 11. Team Learning

- **Certifying convergence on a finite-difference gradient whose noise
  floor sits at the convergence tolerance produces phantom basins.** The
  q4 REML "suboptimal basin" reported against #575 was not a feature of the
  objective surface; it was the FD gradient's noise floor (~1e-3, the same
  order as `g_tol = 1e-3`) being mistaken for a converged optimum. Once the
  exact gradient was available, both the cold-start and TMB-warm-start
  routes converged to the same point. When a mode-finder's certified
  convergence disagrees with a known reference optimum, check whether the
  convergence signal itself (not just the search strategy around it) is
  built on a noise floor comparable to its own tolerance before spending
  effort on basin-selection heuristics.
- **Four warm-start/polish strategies were measured and honestly reverted
  before the derivation-first fix.** Each within-basin remedy (tighter
  restart, NM+LBFGS variants, jittered multistart, structured warm-start
  candidates) was implemented, measured against the fixed floor and the
  engine-level `g_residual < g_tol` contract, and reverted when it failed
  either — rather than shipping a heuristic that happened to move the
  number. The eventual fix was a derivation, not a search-strategy tweak.
- **Speculative optimizer trials must snapshot/restore `u_cache`/
  `beta_cache`.** Any code path that evaluates `fg!` speculatively (for
  comparison, multistart, or polish) and may reject the trial must snapshot
  these shared caches first and restore them on rejection, or the accepted
  point's reported objective can be silently corrupted by a rejected trial's
  side effects — already observed once in this issue's own history.

## 12. Cross-Product Coverage

This slice touches one cross-cutting flag: **REML** on the **q=4 bivariate
phylogenetic Gaussian** engine route.

- **Covers ✓**: the q4 REML mode-finder's gradient and convergence
  certification (`fit_q4_reml`, `src/reml_q4.jl`) — exact-vs-FD gradient
  agreement (12/12, ≤6.2e-8 rel at three φ points), the target optimum test
  (#575, 1/1), full no-regression sweep across q4 REML/phylo/relmat/animal/
  spatial/validation/gradient/#509 surfaces (35/35 + 47/47), q2 REML
  (34/34), missing-data listwise deletion (30/30), and the same-target
  fixture parity check (#433, 33/33) plus the bridge re-measure on
  log-likelihood and coefficients (GATE-PASS, §5). `fit_q4_reml` has
  exactly one caller in `src/` (`gaussian_bivariate.jl`), so this is the
  whole affected surface, not a sample.
- **Does NOT cover ✗**: q4 REML with missing responses (`_reml_border_blocks`
  mask behaviour, #578, untested); the ML path's `prior_precision`
  degeneracy (#577, same defect class, unguarded on the ML side); standard
  error / interval parity (not measured — `interval_status` unchanged,
  `rtol_coef` unjustified pending a fresh drmTMB Wald-SE refit); other
  families and other q values are **n/a** to this slice — it is the Gaussian
  q=4 REML route specifically, and `fit_q4_reml` has one caller
  (`gaussian_bivariate.jl`), so no other family or q surface is touched or
  claimed.

## Memory receipt

No hub `AGENTS.md` guard was added or consulted for this slice beyond the
after-task protocol itself (`~/shinichi-brain/protocols/after-task.md`,
read in full for this report) and the check-log convention
(`docs/dev-log/check-log.d/README.md`). No sibling-project scouting was
performed; all numbers in this report are copied from
`scratchpad/exact-grad-summary.md`, `scratchpad/p14-remeasure.md`, the
`gh issue view 575` comment thread, and `git log`/`git diff --stat`/`gh pr
checks`/`gh api` output captured live during this session (cited inline
above).
