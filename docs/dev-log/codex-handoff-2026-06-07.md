# Codex handoff / check-in — 2026-06-07

State snapshot to hand off to Codex. Reconstruct further detail from `git log`,
open PRs, and `docs/dev-log/` per the repo's evidence-first rehydration rule.

## 1. What landed this session (merged to `main`)
- #223 public `confint(:profile)` for the Gaussian location–scale fit
- #224 conjugate-EM `algorithm = :em`
- #225 two structured variance components (phylo + animal), dense
- #226 exact Poisson-phylo Laplace gradient + strict ≤1e-6 FD gate
- #228 epsilon-method bias correction (`bias_correct`)
- #229 crossed-route mode fix + strict 1e-6 gradient gates across non-Gaussian routes
- #230 Venzon–Moolgavkar profile-CI + full-vector variance-parameter profiling
- #231 sparse O(p) two-structured Gaussian path (`algorithm = :sparse`)
- #190, #192–#200 ten design-map docs → `report/`

Issues filed: #227 (scout backlog), #232 (end-to-end-sparse follow-ups).

## 2. CRITICAL — `main` went red on Julia 1.12 (this is the "lots of GHA failing")
The CI `test (1)` runner rolled from 1.11 → **Julia 1.12.6**. On 1.12,
`LineSearches.HagerZhang` **asserts the objective/derivative is finite**
(`AssertionError: isfinite(phi_c) && isfinite(dphi_c)`), whereas 1.11 tolerated a
non-finite probe. Several `gaussian_structured.jl` fits returned `Inf` (or threw
`PosDefException` from a bare `cholesky`) at infeasible line-search points, so
the optimisation now aborts on 1.12. This breaks `main` itself and therefore
cascades into every open PR's `test (1)` job.

**Fix (in flight on `claude/structured-non-gaussian-8AqYh` → PR to `main`):** every
structured-Gaussian objective now guards each `cholesky` with `check = false` +
`issuccess`, and returns a **large finite penalty (`1e18`)** instead of `Inf`/NaN
so the line search stays finite and backtracks. Covered: `_fit_structured_gaussian`
(single), the relmat/animal fit, the spatial fit (its `K` is rebuilt per eval, so
its `cholesky` can fail mid-optimisation), and `_fit_two_structured_gaussian_sparse`
(`eval_all`'s two `Inf` returns → `1e18`).

## 3. Open PRs (the second wave) and their status
- **#233 heritability/ICC accessors + CIs** — agent done. New code is sound
  (`bias_correct` anchors pass). Failed only because the shared fit crashed on its
  G=60 fixture (fixed by §2) and the 1.12 keystone. Rebase on the §2 fix → expect green.
- **#234 REML (`method = :REML`)** — agent may still be running; had a
  `gaussian_core.jl:444` load error mid-iteration. Confirm once its agent finishes.
- **#235 quantile residuals** — agent done. Own tests pass; was blocked only by the
  1.12 keystone. Rebase → expect green.
- **#236 end-to-end sparse + Q-gates (#232, #15/#16)** — agent done. It REWORKS
  `_fit_two_structured_gaussian_sparse`. **When it rebases onto the §2 fix, KEEP the
  finite-penalty guard in the reworked `eval_all`** (don't let the rework re-introduce
  an `Inf` return) or 1.12 will break again.
- **#201 Codex's coevolution front end** — still open; rebase/merge when ready.

## 4. Task list for Codex
1. **Land the §2 Julia-1.12 finiteness fix** (PR from `claude/structured-non-gaussian-8AqYh`);
   confirm green on BOTH `test (1)` (1.12) and `test (1.10)`, then merge to `main`.
2. **Pin CI Julia versions** so a runner bump can't silently red `main`: set the matrix
   to explicit `1.10` + `1.11` + `1.12` (or pin `1` to a known-good minor and add `1.12`
   separately). CI is `pull_request`-triggered only, so a merge never re-runs `main` — a
   version bump goes unnoticed until the next PR. Consider a scheduled `main` CI run.
3. **Rebase + merge #233 and #235** onto the fixed `main` (verify green).
4. **Verify #234 (REML)** once its agent finishes; watch the `gaussian_core.jl` load path.
5. **Rebase #236**, preserving the finite-penalty guard in the reworked sparse `eval_all`
   (see §3); verify the #15 zero-alloc + #16 scaling Q-gates trip on a deliberate regression.
6. **Audit other `cholesky(...)` / `logdet(...)` call sites** for the same 1.12 hazard
   (anything inside an objective the optimiser drives): `grep -n "cholesky(Symmetric" src/`.
   Same pattern: `check = false` + `issuccess` + finite penalty.
7. Designs still unbuilt (in `report/`): #5 R-bridge, #13 natgrad EM, #49 FIML,
   #136 VA/ELBO, #183 quantile (→ #235), #188 coevolution accessors, #15/#16 (→ #236).

## 5. Guardrails learned this session (please keep)
- **Don't push to a PR branch whose originating agent is still running** — it races the
  agent's worktree and produced a destructive dirty-state (a spurious REML revert) once.
  Fix on a separate branch, or wait for the agent to finish.
- **`main` CI is `pull_request`-triggered, not `push`** — merging does not re-test `main`,
  so latent breakage (e.g. a Julia version bump) only surfaces on the next PR.
- **No local Julia in the cloud session** (package servers blocked): all verification is
  via CI. Wall-clock speedups (conjugate-EM 3.1×, sparse O(p)) are asymptotic/previously
  measured, **not** re-measured here — keep that honesty bar.
- **Licence:** DRM.jl is MIT; never vendor drmTMB GPL source — R-parity uses generated
  outputs only.
