# After-task: propagate the full-Newton-in-basin fix + FD gradient gates (#165)

> **Status: UNVERIFIED in-session.** Written in a cloud session with **no Julia
> runtime** (package servers blocked). Verification is CI-only: the GitHub
> Actions `test (1)`, `test (1.10)`, and `docs` jobs on the PR. Do not promote
> any claim to "verified" until those jobs are green.

## Scope

Propagate the merged `_poisson_phylo_mode` win (#226) to the sibling non-Gaussian
sparse-Laplace mode-finders, and extend the strict ≤ 1e-6 FD-vs-analytic gradient
gate (#165) to the routes that already carry an exact implicit-logdet gradient.

## The bug (recap)

The inner Newton mode used a step-norm stop followed by a backtracking line search
that requires a **strict** joint decrease. Inside the quadratic-convergence basin
the full Newton step is contractive, but near the minimum the only available
decreases are at rounding level, so the line search exhausts (`α` underflows the
`1e-4` floor) and the routine returns the `false`/sentinel path with the mode only
loosely converged (~1e-6). Differencing that loosely-converged marginal is what
blows up a central-difference gradient. The fix (already merged for the phylo
Poisson route) is to take the **full Newton step** once `‖step‖ ≤ 1e-3(1+‖b‖)` and
keep the safeguarded line search only far from the mode.

## Changes (`src/sparse_laplace_glmm.jl`)

1. **`_poisson_crossed_mode`** — applied the identical full-Newton-in-basin fix.
   The crossed-Poisson inner joint is strictly convex (convex Poisson data term +
   diagonal Gaussian prior), so the full step in the basin is always safe.

2. **`_phylo_mean_mode`** and **`_crossed_mean_mode`** (the generic non-Gaussian
   mode-finders behind NB2/Gamma/Beta/Binomial) — applied the same fix **gated on
   convexity**: track `all_w_nonneg` over the per-iteration data-Hessian weights
   and take the full basin step only when every weight is ≥ 0. The
   binomial/nb2/gamma data terms have `d²ℓ/dη² ≥ 0` everywhere, so they always
   take the tight path; beta's `d²` is **not** sign-definite, so when a weight
   goes negative the routine falls back to the safeguarded line search — never an
   unsafe full step.

3. **Hoisted `_poisson_crossed_laplace_fg`** out of the
   `_fit_poisson_crossed_intercepts_laplace` closure (mirroring
   `_poisson_phylo_laplace_fg`), returning `(val[, grad], b, ok)` and accepting
   `newton_tol`/`newton_maxiter`/`b0`. The fit closure now delegates to it; the
   marginal value/gradient are byte-identical, so **no logLik change**.

4. Added `newton_tol`/`newton_maxiter` kwargs to `_phylo_mean_laplace_fg` and
   `_phylo_mean_laplace_nuisance_fg` so the gates can drive a controlled,
   warm-started, tightly-converged inner mode (the q4 / Poisson-phylo recipe).

## Tests (wired into `runtests.jl`)

- `test/test_poisson_crossed_grad_gate.jl` — fully-crossed Poisson (G=6, H=5,
  4 reps/cell). Tight warm-started base mode, central FD of the true marginal,
  θ off the optimum. Asserts `max|g_an − g_fd| ≤ 1e-6`, `@info`s the error.
- `test/test_nongaussian_phylo_grad_gate.jl` — NB2, Gamma, Binomial phylo gates
  at ≤ 1e-6; Beta phylo gate at a looser, **honest** `BETA_TOL = 1e-4` because
  its inner joint is not cleanly convex (line-search inner mode → looser
  attainable FD agreement). Each `@info`s its achieved error.

## Math (why these analytic gradients are exact)

Identical IFT/envelope structure as the Poisson phylo route. Marginal
`L = data(b̂) + ½σ⁻²b̂'Qb̂ + q logσ − ½logdetQ + ½logdet H`. The family enters the
implicit logdet term only through the third derivative `d³ℓ/dη³` (= the `t` carried
by `_laplace_v123`) and the Hessian weight `w = d²ℓ` (the `crossβ` carrier). The
crossed route replaces `Q` leverages with the selected-inverse entries from
`_crossed_selected_inverse_entries` (`hd[gi]+hd[hi]+2·crossinv[i]`).

## Evidence (CI-only — read from the PR's Actions run)

- `test (1)` / `test (1.10)`: full `Pkg.test()` incl. the two new gate files and
  all pre-existing Laplace tests. Read each `@info "… gradient gate" max_abs_diff`
  line for the achieved error per route.
- `docs`: unaffected (no public API change).

## Honest caveats

- **Beta** does not reach ≤ 1e-6 by design — its inner joint is not cleanly
  convex, so the mode is only converged to the line search's reach. The gate
  records the genuinely-achieved error at `BETA_TOL = 1e-4` rather than forcing an
  unsafe full Newton step or loosening for the convex families. If a future
  trust-region inner solve tightens the beta mode, drop `BETA_TOL` to 1e-6.
- If a convex-family gate fails on CI, suspect either the inner mode not reaching
  `ntol = 1e-10` on the seeded fixture (raise `newton_maxiter`) or a stale FD
  reference (the sentinel `@assert` in each `mnll` will surface that explicitly).
- `_crossed_mean_mode` got the convexity-gated fix for consistency but has **no
  dedicated gate in this slice** — it is exercised only by the existing generic
  crossed tests. Adding a strict gate there is the natural follow-up.
