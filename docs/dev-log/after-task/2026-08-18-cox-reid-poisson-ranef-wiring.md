# 2026-08-18 — Cox–Reid wiring: opt-in `method = :REML` on Poisson `(1 | g)` (#443)

**Lane:** `claude/lane-cox-reid-wire` @ `~/local-scratch/lanes/DRM.jl-cox-reid-wire`
(branch name is `lane_launch.sh`'s fixed prefix; the session was **Cursor**).
**Base:** `origin/main` @ `e161c165` — probe PR #442 and REML #440 both already in.
**Persona:** Shannon (lane coordination) executing the wiring; Noether's probe map consumed
as-is, not re-derived. No nested subagents were spawned.
**Closes #443.** Does **not** close #136 / #11 / #49 / #441.

## What landed

Opt-in restricted (Cox–Reid) estimation on the one cell the #441 probe certified:
a Poisson scalar random intercept `(1 | g)` integrated by 32-node Gauss–Hermite
quadrature.

| Change | File | What it does |
|---|---|---|
| `_reject_method_as_marginal(fam, method; allow_reml = false)` | `src/variational.jl` | Gains an opt-in `allow_reml` and now **returns** the normalised selector (`nothing` / `:ML` / `:REML`) so the caller can branch. Default `false` ⇒ Binomial / NB2 / Gamma / Beta behaviour is untouched. |
| `_reject_reml_route(fam, what)` | `src/variational.jl` | New. The honest error for a route the restricted objective is not certified on. |
| `drm(::Poisson)` dispatch | `src/poisson.jl` | Captures the selector, then guards **five** non-`(1|g)` routes: structured/phylo, crossed intercepts, `(1 + x | g)`, `marginal = :VA`, and fixed-effects-only / `zi` / `hu`. |
| `_fit_poisson_ranef(...; reml = false)` | `src/poisson.jl` | On `reml`, refits under ℓ_ML − ½·log\|I_ββ\| via `_glsp_reml_refit_clean`, takes the restricted vcov from `_glsp_reml_vcov` (#310), and tags with `_withreml`. |
| Docstring | `src/poisson.jl` | Worked example + a `!!! warning` carrying the over-correction numbers. |
| `test/test_cox_reid_poisson_ranef.jl` | new | 38 assertions. **Not** in `runtests.jl`. |
| `test/test_cox_reid_characterization.jl` | updated | The probe's tripwire fired as designed; rewritten to guard the ML default and the still-uncertified routes. |

**Nothing was derived.** `_glsp_reml_penalty`, `_glsp_reml_refit_clean`,
`_glsp_reml_vcov` and `_withreml` are reused unmodified. `(1|g)` has no analytic
gradient closure, so `grad_fn = θ -> ForwardDiff.gradient(nll, θ)` supplies the exact
gradient — the same quantity probe Cell A measured with.

## One correction to the dispatch brief (site vs cell)

The brief named the hook as `sparse_laplace_glmm.jl:555` **and** said "the Poisson
`(1|g)` hole only". Those are two different routes and cannot both be satisfied:

- `:555` is `_fit_poisson_general_laplace` — the phylo/relmat **Laplace** spine. That is
  probe **Cell C** and Go item **#2**.
- Poisson `(1 | g)` GHQ-32 is `_fit_poisson_ranef` in `src/poisson.jl`. The probe note
  states it outright: *"Public `(1 | g)` is **not** this spine."*

Resolved in favour of the **cell**, because the brief stated it twice, and the probe's own
Go list orders `(1|g)` first with the reason: on `(1|g)` the integral lever is already
paid at 32 nodes, so σ̂_b's residual bias is the ML variance-component bias and nothing
else. That is what makes it the clean first cell. `:555` is left to the follow-up.

## Verification

- **TDD red first.** The new test file was written before any `src/` edit and failed
  3 errors + 2 failures (the three REML fits threw; the route messages did not name the
  cell). Post-implementation: **38/38 pass**.
- **Full `Pkg.test()` regression gate** run in this worktree — see the check-log row.
  (`julia --project=. test/runtests.jl` alone fails on a missing `Aqua`; the suite must be
  entered through `Pkg.test()` so `test/Project.toml` resolves. Worth knowing in a fresh
  worktree — it looks like a real failure and is not one.)
- **Fresh worktrees need `Pkg.instantiate()`** before anything runs.

### What the tests actually assert

Direction and mechanism, never a recovery target:

- σ̂_b(REML) > σ̂_b(ML) **per seed** across three seeds. This is not a coincidence of the
  draw: ½·logdet(I_ββ) falls as σ_b grows (more cluster variance ⇒ less information about
  β), so the restricted optimum necessarily sits at a larger σ̂_b.
- The mean block barely moves — the correction targets the variance component.
- `reml_loglik != ml_loglik`, so the penalty demonstrably entered the objective; a
  `_withreml` tag over an unchanged fit would pass a weaker test.
- REML vcov differs from ML vcov (#310): the restricted objective carries the penalty
  curvature.
- The five uncertified routes **error** rather than silently returning an ML fit.
- Binomial still rejects `:REML`; the `marginal` vs `method` split is intact; Gaussian
  REML (#440) is undisturbed.

## Honesty ledger

- **No DRM.jl recovery claim is made here.** The numbers quoted in the docstring and issue
  (ML −12.37% at G=10, Cox–Reid −1.77%; +1.41% / +4.38% at G=40) are the **probe's**
  Cell A on this engine, 60 seeds, one cell, one family. They justify "opt-in, useful when
  clusters are few" and nothing broader.
- drmTMB's **−7.3 / −5.0 / −0.9** stay attributed to drmTMB (`cumulative_logit`,
  different package, family and cell). Not restated as ours.
- GLLVM loading-matrix numbers do not transfer at all (Hopper fence). Cox–Reid moved the
  estimate ~1% the *wrong* way there because it never touches Λ; that is a different
  estimand, not a contradiction of this cell.
- **This is one cell, not a capability.** No TSV row, no capability chip, no
  "DRM.jl has non-Gaussian REML" sentence. Binomial / NB2 / Gamma / Beta and every
  Laplace route remain ML-only *by construction*, not by omission.
- Cell D (cheap phylo Laplace) remains underpowered for a bias-*sign* claim and is not
  cited as support for anything.

## Fence held

No AGHQ. No q4 / `src/reml_q4.jl`. No `src/gaussian_ranef.jl` edit. No REML #440 redo.
No bivariate. No `test/runtests.jl` registration. No TSV / capability chip. No GLLVM Λ
numbers. No GPL vendoring. No default flip. `docs/a3c-design` untouched.

## Lane coordination (Shannon's own lens)

Pre-flight at lane start: **no foreign platform** (no Claude, no Codex), but **8 lanes
live** including a second Cursor lane. Per-file re-measurement before each write:

- `src/variational.jl` — 6 refs flagged. All 8–10 weeks old and **none contains
  `_reject_method_as_marginal` at all**; they predate the function. Zero overlap.
- `src/poisson.jl` — of the seven live lanes, six have a **0-line** diff against
  `origin/main` on this file. Verified the path exists on each ref first, so the empty
  diff is agreement and not absence.
- `test/test_cox_reid_characterization.jl` — flagged by `cursor/lane-cox-reid-probe`,
  whose content is already in this base (PR #442). 0-line diff, path present.

### Two findings for other owners (not this lane's to fix)

1. **PR #406 (`docs/github-auto-merge`) would revert a merged fix.** It is a docs-only PR,
   but its base is 5 days old and its `src/poisson.jl` still carries
   `V = inv(ForwardDiff.hessian(nll, θ̂))` in **five** places where `origin/main` now has
   `_vcov_from_hessian(...)` — the NaN-guard from `fix/check-drm-nan-vcov`. Merging #406
   without rebasing silently undoes that guard. **Rebase before merge.**
2. **58 stale local branches.** Most are squash-merged and long dead, which is why
   `git merge-base --is-ancestor` reports nearly everything "divergent" and the per-file
   lane check fires on history rather than live work. The signal is being drowned. Worth a
   prune pass so the next lane's checks mean something.

## Next (probe's order, unchanged)

1. Same wiring on **Poisson phylo Laplace** (`sparse_laplace_glmm.jl:555`) — the hook is
   already proven by Cell C, but the bias direction is **not** certified (Cell D was
   underpowered), so that cell needs its own ADEMP with a larger tree and more seeds
   before `:REML` is admitted there.
2. Other scalar-per-cluster families (Binomial / NB2 / Gamma / Beta), one at a time.
3. Register the standalone test in `runtests.jl` once the Option A sibling lands.
4. AGHQ is lever 2 — **after** Cox–Reid, and after GLLVM honesty. Not next.
