# After-task: NB2 covariate dispersion with a mean-only phylo RE (#164)

Date: 2026-06-10

## Summary

The prior audit flagged a missing cell: `bf(y ~ x + phylo(1 | species), sigma ~ x)`
— covariate dispersion (`log σ ~ x`) with a random effect on the MEAN only —
routed to the non-Gaussian phylo Laplace spine, which carried a SCALAR
dispersion nuisance `θσ` and HARD-ERRORED on a non-constant `Xσ`
("supports only `sigma ~ 1`"). A per-observation log-dispersion needs a VECTOR
nuisance gradient.

This slice generalises ONE family — **NegBinomial2** — to accept a
per-observation log-dispersion `ησ = Xσ·βσ`, while leaving every other family's
constant-σ guard in place. The mean keeps its phylogenetic random intercept.

### What changed (`src/sparse_laplace_glmm.jl`)

- New per-observation kernel `Val(:nb2_hetero)` (`_laplace_value/_laplace_d12/
  _laplace_v123/_laplace_v123_nuisance`): identical NB2 log-likelihood and
  η/nuisance derivatives to `Val(:nb2_fixed)`, but the size is a per-observation
  vector `aux.size[i] = exp(Xσ[i,:]·βσ)`. Each nuisance derivative is taken
  w.r.t. that observation's `log r_i`.
- New `_phylo_mean_laplace_hetero_fg`: the f/g of `_phylo_mean_laplace_nuisance_fg`
  with the scalar `θσ` replaced by `βσ(pσ)`. The single scalar `gnuis` becomes a
  `pσ`-vector `gν` whose per-observation contributions (`nval`, the `½ nw·lever`
  logdet-trace term, and the `crossν` implicit cross-term) are weighted by
  `Xσ[i,k]`. `crossν` is now a `q × pσ` matrix — structurally identical to how
  the mean axis already chains `r/w` through `Xμ`. The mean-axis and phylo-logσ
  code is copied verbatim.
- New `_fit_phylo_mean_laplace_hetero` fitter (parallels the scalar
  `_fit_phylo_mean_laplace_nuisance`): builds the per-observation `scales[:sigma]`
  and a `(pμ+1):(pμ+pσ)` `:sigma` block.
- `_fit_nb2_phylo_laplace` branches: a constant 1-column `Xσ` keeps the exact
  scalar `Val(:nb2_fixed)` path; any other `Xσ` routes to the hetero path.

### Dispatcher (`src/negbinomial.jl`)

- Removed the `NegBinomial2() phylo sparse Laplace currently supports sigma ~ 1`
  guard so a covariate `sigma` formula reaches the (now-capable) fitter. The
  `zi`/`hu` and ordinary-RE guards are untouched. Docstring updated.

## Math contract

The marginal is
`L = data(b̂) + ½σ⁻²b̂'Qb̂ + q·logσ − ½logdetQ + ½logdet H`,
`H = σ⁻²Q + diag(w_i)`. For a per-observation dispersion `s_i = Xσ[i,:]·βσ`,
`∂L/∂βσ_k = Σ_i Xσ[i,k]·∂L/∂s_i`, so the βσ gradient is exactly the Xσ-chained
version of the scalar nuisance gradient (explicit `nval`, the IFT logdet-trace
`½ nw·lever`, and the implicit `−½ crossν'·H⁻¹·tlogdet`). A one-column constant
`Xσ` reproduces the scalar f/g bit-for-bit.

## Evidence

Run with `/Users/z3437171/.juliaup/bin/julia --project=. …`.

1. **FD-vs-exact gradient gate ≤ 1e-6** (the #165 recipe: tight inner mode
   `newton_tol=1e-10`, warm-started, evaluated OFF the optimum so the implicit
   `db̂/dβσ` and `db̂/dlogσ` terms are exercised). `sigma ~ 1 + x`, NB2 phylo:
   - 5 seeds: max-abs-diff ∈ {5.6e-9, 8.0e-9, 1.0e-8, 2.9e-8, 1.8e-8} — all PASS.
   - Adversarial `pσ=3` (intercept + 2 covariates) with a strong NEGATIVE
     dispersion slope: 4.96e-8 — PASS.
2. **Reduction invariant**: with a 1-column constant `Xσ`,
   `_phylo_mean_laplace_hetero_fg` vs `_phylo_mean_laplace_nuisance_fg`:
   value diff 0.0, gradient diff 0.0 (bit-identical) — proves the scalar
   `sigma ~ 1` path is untouched.
3. **End-to-end `drm()` recovery** (`bf(y ~ x + phylo(1|species), sigma ~ x)`,
   p=40, m=12): converged; βμ slope 0.293 (true 0.35); βσ slope 0.452
   (true 0.60); re_sd 0.414 (true 0.45); finite logLik; all fitted > 0.
4. **New test file** `test/test_164_mean_re_covariate_sigma.jl` (3 testsets,
   13 assertions) PASS in isolation; wired into `runtests.jl`.
5. **No regression**: directly-affected existing tests (`test_nb2_phylo_laplace.jl`,
   `test_gamma_beta_phylo_laplace.jl`, `test_nongaussian_phylo_grad_gate.jl`,
   `test_nbinom2*.jl`) — 48/48 PASS. Full `test/runtests.jl`: exit code 0; 157
   testsets all-Pass with zero fail/error, plus the one pre-existing
   `VA marginal scaffold (#136)` testset (6 pass / 3 `@test_broken`, unrelated to
   this change). All four standing #165 FD gates and the #202 locscale
   heteroscedastic test stay green.

The one existing assertion that changed: `test_nb2_phylo_laplace.jl` previously
asserted `@test_throws` for `sigma ~ 0 + x` on the NB2 phylo route. That guard is
exactly the capability this slice adds, so it is now an affirmative test that the
covariate-σ fit converges with a 1-column `:sigma` block. (Gamma/Beta still
assert the throw — their guards are deliberately unchanged.)

## Scope / Rose note

- Scoped to NB2 only (the task's "one most tractable family"). Gamma, Beta, and
  the crossed-intercept routes keep their constant-σ guards — a follow-up could
  fan the hetero pattern out to Gamma/Beta (their `Val(:*_hetero)` kernels would
  mirror this one) and to `_fit_*_crossed_laplace`.
- No drmTMB GPL source vendored; the NB2 kernels are re-derived from the existing
  in-repo `Val(:nb2_fixed)` kernels (MIT).
- No R-vs-Julia timing claim made.
