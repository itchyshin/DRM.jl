# After-task: exact implicit-logdet gradient gate for Poisson phylo Laplace (#165)

> **Status: UNVERIFIED in-session.** Written in a cloud session with **no Julia
> runtime** (package servers blocked). Verification is CI-only: the GitHub
> Actions `test (1)`, `test (1.10)`, and `docs` jobs on the PR. Do not promote
> any claim to "verified" until those jobs are green.

## Scope

Brought the **Poisson phylogenetic** sparse-Laplace route (`phylo(1 | grp)`) to
the issue-#165 "verified-engine bar": an exact implicit-function / implicit-logdet
outer gradient, gated FD-vs-analytic at ≤ 1e-6.

Investigation finding: the analytic gradient was **already present** in
`_fit_poisson_phylo_laplace` (introduced under #80/#161) — it forms
`S = takahashi_selinv(ch)`, the leverages `hd = diag(S)`, the logdet carrier
`tlogdet`, the implicit solve `implicit = H⁻¹ tlogdet`, and the β/σ implicit
corrections. The "frozen-mode + finite-difference polish" the issue body quotes
had already been removed for this route (the remaining `polish_iterations` is an
extra exact-gradient Optim pass, not an FD step). What was **missing** was the
issue's actual acceptance criterion: a strict ≤ 1e-6 FD-vs-analytic gate. The
existing `test_poisson_phylo_laplace.jl` only checked `rtol/atol = 2e-3`, loose
enough to hide a small gradient error and dominated by inner-mode stopping noise.

### Changes (`src/sparse_laplace_glmm.jl`)

- Hoisted the f/g body out of the `_fit_poisson_phylo_laplace` closure into a
  module-level `_poisson_phylo_laplace_fg(y, Xμ, leaf_node, Q, logdetQ, lf, θ;
  grad, b0, newton_tol, newton_maxiter)` returning `(val[, grad], b, ok)`. This
  mirrors the existing `_phylo_mean_laplace_fg` / `_phylo_mean_laplace_nuisance_fg`
  structure and — critically — lets a test drive a **tightly-converged,
  warm-started** inner mode (the exact recipe `test_qgate_fd_gradient.jl` uses to
  reach 1e-6). The fit closure now delegates to it; the marginal value and
  gradient are byte-for-byte the same computation as before, so **no logLik
  change**.

### Math (why the analytic gradient is exact)

Marginal `L = data(b̂) + ½σ⁻² b̂'Qb̂ + q logσ − ½ logdetQ + ½ logdet H`,
`H = σ⁻²Q + diag(Σ_{i∈leaf} μ_i)`. Envelope/IFT: `dL/dθ = ∂L/∂θ|_b̂ + (½∂logdetH/∂b)·db̂/dθ`,
`db̂/dθ = −H⁻¹ ∂²(data+prior)/∂b∂θ`. Hand-derivation confirms the code term by term:
- **σ:** explicit `q − σ⁻²(b̂'Qb̂ + tr(H⁻¹Q))`; implicit `+ dot(implicit, σ⁻²Qb̂)`
  (since `∂²prior/∂b∂logσ = −2σ⁻²Qb̂`, `db̂/dlogσ = 2H⁻¹σ⁻²Qb̂`).
- **β:** implicit `− ½ implicit'·crossβ[:,k]`, `crossβ[l,k] = Σ_{i∈l} μ_i X_{ik}
  = ∂²data/∂b_l∂β_k`.
The family-specific third derivative the IFT introduces is `d³ℓ = μ` for Poisson,
which is exactly the `μ` carried into `tlogdet` and the leverage product.

### Test (`test/test_poisson_phylo_grad_gate.jl`, wired into `runtests.jl`)

Self-contained Poisson `phylo(1|species)` fixture (p=12, nrep=4). Computes a
base mode at Newton tol 1e-13, then the analytic gradient and a central-difference
gradient of the TRUE marginal NLL, **warm-starting every perturbed solve from the
base mode** so the FD reference is not stopping-noise-limited. θ is taken OFF the
optimum so the implicit (db̂/dθ) correction is exercised. Asserts
`max|g_analytic − g_fd| ≤ 1e-6` and logs the achieved max error via `@info`.

## Evidence (CI-only — to read from the PR's Actions run)

- `test (1)` / `test (1.10)`: full `Pkg.test()` incl. the new gate + the existing
  `test_poisson_phylo_laplace.jl` recovery/2e-3 test (unchanged) + the q4
  Q-gate. Read the `@info "Poisson phylo gradient gate" max_abs_diff …` line for
  the achieved error.
- `docs`: doctest/build unaffected (no public API change).

## Not in this slice

- NB2 / Gamma / Beta / Binomial phylo and the crossed routes: their exact
  gradients are already present (`_phylo_mean_laplace_fg` via `_laplace_v123`'s
  `d3`; the K-crossed path under #204). Extending the strict 1e-6 gate to them is
  the natural follow-up — one fully-verified route first, per the task brief.

## Risk / honesty

If the gate fails on CI, the likely culprit is a sign/factor in the σ implicit
term (`dot(implicit, Pu)`) or an inner-mode that didn't reach the 1e-13 tol on
the seeded fixture (raise `newton_maxiter` or relax the gate's central-difference
`h`). The hand-derivation above matched the code in every term, so a clean pass
is expected, but it is **not yet observed**.
