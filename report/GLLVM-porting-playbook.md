# GLLVM.jl → DRM.jl porting playbook

Audience: an agent (Codex or Claude) who has to do the port. This playbook
covers what to carry over from `gllvmTMB.jl/src/` into a future `DRM.jl/src/`,
what to leave behind, and in what order.

Read-firsts:
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB.jl/src/` — the donor.
- `/Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/fit_julia.jl` —
  the 553-line working POC. It already does univariate + bivariate Gaussian
  distributional regression and the closed-form univariate phylogenetic fit.
- `/Users/z3437171/Dropbox/Github Local/drm-julia-poc/CONTRACT.md` — bench
  contract (parameter links, cell grid, JSON formats).
- `/Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/bf_sketch.jl` —
  brms-style `bf()` parser sketch. No GLLVM.jl analog; you write this.

## Per-file verdicts

| GLLVM.jl file | LOC | What it contains | Port verdict | Target DRM.jl file | Effort | Dependencies | Notes |
|---|---:|---|---|---|---|---|---|
| `GLLVM.jl` | 32 | Top-level module: `using`, `include`s, exports. | ADAPT | `DRM.jl` | 1 h | — | Rewrite from scratch with `DRM` module, DRM-specific exports (`fit_drm`, `nll_univariate`, etc.). Reuse layered include order (packing → likelihood → fit → confint). |
| `packing.jl` | 101 | Pack/unpack p×K lower-tri loading matrix Λ as flat θ. | SKIP | — | 0 | — | No latent-factor matrix in DRM.jl. DRM packing is one β vector per dpar plus log-Cholesky for any RE block — write fresh as `packing.jl` matching `bf_sketch.jl §5`. |
| `lowrank_cholesky.jl` | 205 | Woodbury factor of `M = ΛΛ' + diag(d)`. | SKIP | — | 0 | — | Only useful when K ≪ p (latent factors). DRM's q≤4 RE block is dense Cholesky territory. Revisit only if a q≥10 use case appears. |
| `likelihood.jl` | 403 | Closed-form Gaussian marginal log-lik for J1 / J2-A-WD / J3 phylo via rotation trick. | ADAPT | `likelihood_gaussian_phylo.jl` | 2 d | new `packing.jl` | The J3 rotation-trick block (`A = ΛΛ' + diag(d_total)`, `B = (Λ_aug Λ_aug') ∘ Σ_phy`, two p×p Choleskys, mean+centred decomposition) is exactly what drmTMB needs for the q-block univariate phylo case. Strip the K_B/K_W/Λ_W code paths; keep the phy block and the X·β fixed effects. Rename `Λ_phy_aug` → `L_phy_block` (it is a phy block-Cholesky for DRM). |
| `ppca_init.jl` | 125 | Tipping & Bishop closed-form PPCA ML for `y ~ N(0, ΛΛ' + σ²I)`. | SKIP | — | 0 | — | DRM has no latent factors. Warm-start in DRM is OLS + log-residual regression (already in `fit_julia.jl` lines 122-125). |
| `em_fa.jl` | 139 | Rubin–Thayer EM for factor analysis. | SKIP | — | 0 | — | Factor-analysis-specific. Not portable. |
| `em_squarem.jl` | 251 | SQUAREM accelerator wrapping `em_phylo`. | SKIP | — | 0 | — | Pure gain only matters when plain EM is the bottleneck. DRM uses gradient-based LBFGS throughout. |
| `em_phylo.jl` | 477 | Gradient-free EM for the Gaussian phylo GLLVM. | REFERENCE_ONLY | — | 0 | — | Useful as a sanity-check fixed-point reference for the LBFGS fit, but the closed-form path in `likelihood.jl` is faster for the cells in `CONTRACT.md`. Skip unless a CHOLMOD-AD wall appears. |
| `profile.jl` | 571 | σ²_eps profile-out + GLS β profile-out, MixedModels.jl-style. | ADAPT | `profile_sigma.jl` | 1–2 d | `likelihood_gaussian_phylo.jl` | The σ²_eps profile-out trick (reparameterise all variance components in σ²_eps units; `Λ = σ_eps · L`) translates directly to DRM's residual `sigma`. For DRM the natural rename is `σ_eps → σ_residual` (univariate) or `σ_residual1`/`σ_residual2` (bivariate). β GLS profile-out is optional — bench in `fit_julia.jl` shows it is not needed at q ≤ 5. |
| `fit.jl` | 411 | LBFGS driver, warm-starts, sign-anchor restarts, GllvmFit struct. | ADAPT | `fit.jl` | 2–3 d | `likelihood_gaussian_phylo.jl`, `profile.jl`, `bf_sketch.jl` parser | The `Optim.optimize(... LBFGS(); autodiff = :forward)` boilerplate, `Optim.Options` setup, and the `GllvmFit` result struct shape (params NamedTuple + logLik + n_iter + converged + cputime) are reusable. Replace `GllvmModel(p, K, K_W, has_diag, K_phy, has_phy_unique)` with a `DRMSpec` carrying the `DistributionalFormula` from `bf()`. Drop PPCA warm-start, sign-anchor restarts, σ_phy joint-flip code (no signed phy-unique loading in DRM). |
| `simulate.jl` | 1 | Placeholder. | SKIP | — | 0 | — | Empty. |
| `sparse_phy.jl` | 414 | Augmented-state sparse phy precision + Newick parser. | REFERENCE_ONLY | — | 0 | — | drmTMB takes Σ_phy in dense form from R (see `read_sigma_phy` in POC). Only port if p > 1000 cells need sparse — out of POC scope. |
| `likelihood_sparse_phy.jl` | 343 | Sparse-phy marginal log-lik via Schur saddle. | SKIP | — | 0 | — | Companion to `sparse_phy.jl`; same justification to defer. |
| `sparse_phy_grad.jl` | 484 | Hand-coded analytic gradient for the sparse path (CHOLMOD-AD workaround). | SKIP | — | 0 | — | Only valuable if you port `sparse_phy.jl`. |
| `edge_incidence.jl` | 482 | `Q = B W B'` edge-node factorisation; AD-friendly sparse phy. | REFERENCE_ONLY | — | 0 | — | The AD-friendly sparse alternative to CHOLMOD. Worth porting if p > 1000 phy cells ever land in DRM scope; otherwise dense Σ_phy from R is fine. |
| `likelihood_edge_incidence.jl` | 125 | Marginal log-lik on the edge-incidence substrate. | REFERENCE_ONLY | — | 0 | — | Same as above. |
| `phylo_contrasts.jl` | 330 | Felsenstein independent contrasts (U Σ_phy U' = σ²_phy · diag). | REFERENCE_ONLY | — | 0 | — | Beautiful for BM-only models; the dense rotation trick in `likelihood.jl` is cheaper at p ≤ 1000 and already covers DRM's POC cells. Port only if BM-specific speedups matter. |
| `likelihood_contrasts.jl` | 322 | Closed-form marginal log-lik on the contrast scale. | REFERENCE_ONLY | — | 0 | — | Companion to `phylo_contrasts.jl`. |
| `relaxed_clock.jl` | 581 | Per-branch evolution-rate model on the edge-incidence substrate. | SKIP | — | 0 | — | Research artefact, not yet a DRM design target. |
| `confint.jl` | 341 | Wald CI via observed information matrix; log-scale back-transform for SDs. | COPY | `confint_wald.jl` | 1 d | `fit.jl`, `likelihood_gaussian_phylo.jl` | The Hessian-via-ForwardDiff machinery, the log-scale back-transform for SDs, the non-PD-Hessian NaN handling, and the term-name layout helpers all carry over. Strip `_confint_lambda_term_names` (no Λ in DRM); replace with per-dpar β term names. |
| `confint_profile.jl` | 485 | Profile-likelihood CIs by re-optimising with one param fixed. | COPY | `confint_profile.jl` | 1 d | `confint_wald.jl`, `fit.jl` | The bracket-then-bisect algorithm, the warm-start chaining across candidates, and the chisq-cutoff bookkeeping are model-agnostic. Pure copy with one rename: the parameter name list is generated from `DistributionalFormula`, not from a `GllvmModel`. |
| `confint_bootstrap.jl` | 429 | Parametric bootstrap CIs (sample y_b ~ N(μ̂, Σ̂_y), refit, percentile). | COPY | `confint_bootstrap.jl` | 1 d | `fit.jl`, `simulate_drm` (write fresh) | Replace `gaussian_marginal_loglik`-based sampler with a `simulate_drm(fit; rng)` helper that reads (μ_i, Σ_i) from the fitted DRM. The percentile-CI and refit-failure handling code is reusable verbatim. |
| `confint_derived.jl` | 959 | Profile + bootstrap CI for derived scalars (Σ_y entries, communality, ICC, H², ρ). | ADAPT | `confint_derived.jl` | 2–3 d | `confint_profile.jl`, `confint_bootstrap.jl` | The constrained-refit quadratic-penalty trick `NLL_pen = NLL + 0.5·w·(g(θ) − c)²` carries over fully. Communality and ICC are factor-analysis quantities — drop those derived_fn implementations. Keep ρ (cross-trait correlation, applies to bivariate `rho12`), variance ratios, and the abstract derived_fn dispatch. |
| `confint_derived_wald.jl` | 341 | Transformed-scale Wald CI for bounded derived quantities (Fisher-z, logit). | COPY | `confint_derived_wald.jl` | 0.5 d | `confint_wald.jl`, `confint_derived.jl` | Math is model-agnostic. The Fisher-z transform for ρ and the logit transform for variance ratios both apply to DRM's `rho12` and any future `var(re) / (var(re) + sigma²)` quantities. |

(24 file rows.)

## 1. Recommended porting order

Effort estimates are calendar-day estimates for a single focused agent. Tasks
marked with `||` may run in parallel.

```
1. packing.jl (fresh, mirroring bf_sketch.jl §5)            0.5 d  (no deps)
2. likelihood_gaussian_phylo.jl (port J3 from likelihood.jl) 2 d   (needs 1)
3. profile.jl  (port σ²_eps profile-out)                    1–2 d  (needs 2)   ||
   bf() parser (lift bf_sketch.jl to real)                  3 d    (no deps)   ||
4. fit.jl (LBFGS + DRMSpec + bf() integration)              2–3 d  (needs 2, 3, bf parser)
5. confint_wald.jl                                          1 d    (needs 4)
6. confint_profile.jl                                       1 d    (needs 4, 5)   ||
   confint_bootstrap.jl + simulate_drm                      1 d    (needs 4)      ||
7. confint_derived.jl + confint_derived_wald.jl             2.5 d  (needs 5, 6)
```

Critical path: `packing` → `likelihood` → `fit` → `confint_wald` →
`confint_derived`. Total ≈ 9–11 focused days.

Three parallelisation opportunities:
- Step 3: `profile.jl` port and `bf()` parser are independent.
- Step 6: `confint_profile.jl` and `confint_bootstrap.jl` share no state.
- Phylo-only files (`sparse_phy.jl`, `edge_incidence.jl`, `phylo_contrasts.jl`)
  are all deferred and can be picked up later in a parallel track if a
  p > 1000 phy cell ever enters scope.

## 2. Naming convention mapping (GLLVM.jl → DRM.jl)

| GLLVM.jl | DRM.jl | Reason |
|---|---|---|
| `Λ_B`, `K_B`, `θ_rr_B`, `θ_B₀` | (drop) | No latent factors in DRM. |
| `Λ_W`, `K_W`, `θ_rr_W` | (drop) | Same. |
| `σ²_B`, `σ²_W`, `has_diag` | (drop) | Tier-specific REs not in DRM. |
| `σ_eps` | `σ_residual` (univariate); `σ_residual1`, `σ_residual2` (bivariate) | Project rule: `sigma`, not `tau`, in the public API. Use `σ_residual` to disambiguate from per-row `σ_i`. |
| `log_σ_eps` | `log_σ_residual` | Same. |
| `σ_phy` (length-p signed loading) | `σ_phy_dpar` (one per dpar) | DRM phy block is a q×q dpar-correlated block, not a p-vector of trait loadings. |
| `Λ_phy` (p × K_phy loading) | (drop) | Same. |
| `Σ_phy` | `Σ_phy` | Keep. Same semantics: dense p×p species covariance from caller. |
| `gaussian_marginal_loglik` | `nll_univariate_gaussian_phylo` and `nll_bivariate_gaussian_phylo` | DRM splits univariate vs bivariate at the type level. POC already follows this. |
| `gaussian_nll_packed` | `nll_packed_drm` | Single dispatch point taking `DistributionalFormula` + flat θ. |
| `gaussian_profile_nll` | `profile_nll_drm` | Same. |
| `fit_gaussian_gllvm` | `fit_drm` | Entry point. |
| `GllvmModel` | `DRMSpec` | Holds `DistributionalFormula`, families per dpar, X matrices, optional Σ_phy. |
| `GllvmFit` | `DRMFit` | Same fields (`pars`, `logLik`, `n_iter`, `converged`, `optim_result`, `cputime`). |
| `pack_lambda`, `unpack_lambda`, `init_theta_rr`, `rr_theta_len` | (drop) | Replaced by `pack_drm_params(spec, θ_nt)` / `unpack_drm_params(spec, θ_flat)` from new `packing.jl`. |
| `confint(fit::GllvmFit)` | `confint(fit::DRMFit)` | Method on the renamed struct. |
| `_confint_lambda_term_names` | `_confint_beta_term_names(spec, dpar)` | Per-dpar β term names. |
| `K`, `K_W`, `K_phy` (latent ranks) | `q` (RE-block size from `bf()`) | DRM uses q (≤ 4 for the q4_p100 phy cell). |
| `ppca_init`, `em_fa`, `em_fit_phylo`, `em_fit_phylo_squarem` | (drop) | No latent factors to initialise. |
| `augmented_phy`, `make_phy`, `gaussian_marginal_loglik_sparse_phy` | (drop / defer) | R-side passes dense Σ_phy. |
| `EdgePhy`, `gaussian_marginal_loglik_edge_phy` | (drop / defer) | Same. |

## 3. What is missing from GLLVM.jl

You will not find these in the donor — they are genuinely new work:

1. **`bf()` multi-formula parser.** The single biggest deliverable. GLLVM.jl
   never needed one because the model is `y ~ Λη + ε` and `Λ` is the
   parameter, not a formula. DRM.jl needs per-dpar formulas (`mu`, `sigma`,
   `rho12`) plus the brms three-pipe `(rhs | label | group)` form for
   cross-dpar shared RE blocks. `bf_sketch.jl` (416 LOC) has the parser
   skeleton, the `DistributionalFormula` / `CovBlockSpec` types, and worked
   examples. Lift it into `bf.jl`, wire `apply_schema` against
   StatsModels.jl, build the design-matrix materialisers (`X_mu`, `X_sigma`,
   `Z_block`), and add Schoolbook-AD tests on small fixtures.

2. **Laplace approximation for non-Gaussian families with REs.** GLLVM.jl is
   Gaussian-only and uses the closed-form marginal everywhere. DRM.jl v0.3+
   needs to handle Student-t / Tweedie / Beta / NB2 / ordinal / ZI with
   random effects, where the marginal is no longer closed-form. The path is
   TMB-style: inner mode-finding for the latent state, outer LBFGS on the
   profile, AD through the inner solve. None of GLLVM.jl helps here. Out of
   POC scope per `CONTRACT.md` lines 254–262 (q4_p100 cell is marked
   R-only).

3. **Family-specific likelihoods beyond Gaussian.** DRM.jl's promise is
   "univariate and bivariate distributional regression" across families.
   The POC and GLLVM.jl both cover Gaussian only. Each new family
   (Student-t, log-Normal, Gamma, Beta, NB2, Tweedie, ordinal cumulative,
   ZI variants) needs:
   - A negative log-likelihood (matches one of drmTMB's existing C++
     densities to set the parameterisation, then write in Julia).
   - Link function for any dpar beyond `mu` (e.g. `nu` for Student-t with
     `log` link; ordinal threshold parameters).
   - Recovery test on a fixture.
   This is a per-family port from drmTMB's C++ source, not from GLLVM.jl.

4. **`meta_known_V()` data carrier.** Per project rule: meta-analysis is
   `family = gaussian()` plus `meta_known_V(V = V)`. DRM.jl needs a small
   data adapter that hands the known V down to the Gaussian likelihood.
   No GLLVM.jl analog; trivial (≈ 40 LOC).

## 4. Provenance / attribution

drmTMB's `inst/COPYRIGHTS` is the authoritative log. The Julia package
mirror is `COPYRIGHTS.md` at the DRM.jl project root (or `inst/COPYRIGHTS.md`
if the package layout grows an `inst/`). Whenever a file in DRM.jl is a
direct port from GLLVM.jl (the COPY / ADAPT verdicts above):

1. **Prepend this header** to the ported file, with the donor path on disk
   and the commit SHA (run `git rev-parse HEAD` in `gllvmTMB.jl/` at
   port time):

   ```julia
   # ---------------------------------------------------------------------------
   # Ported from gllvmTMB.jl/src/<donor-filename>.jl
   #   donor commit: <SHA>
   #   donor LOC at port time: <N>
   #   ported on: <YYYY-MM-DD>
   #   licence: MIT (gllvmTMB.jl)
   #   adaptations: <one-line summary, e.g.
   #     - dropped Λ_B / K_B / Λ_W code paths;
   #     - renamed σ_eps → σ_residual;
   #     - replaced GllvmModel with DRMSpec.>
   # ---------------------------------------------------------------------------
   ```

2. **Add a `COPYRIGHTS.md` entry** in DRM.jl/ root, one block per ported
   file:

   ```markdown
   ## <ported-filename>

   - Source: `gllvmTMB.jl/src/<donor>.jl`
   - Donor commit: <SHA>
   - Donor licence: MIT
   - Ported: <YYYY-MM-DD>
   - Adaptations: <same summary as the header, prose-paragraph fine.>
   - Tests: `test/<corresponding test file>.jl` verifies the port against
     <reference value or R-side drmTMB output, with tolerance>.
   ```

3. **Test the port.** A COPY needs an equivalence test against either the
   GLLVM.jl original on a Gaussian fixture or the R-side drmTMB output.
   An ADAPT needs the recovery / coverage gate that already lives in
   `CONTRACT.md` (|Δ logLik| < 1e-3, max |Δ coef| < 1e-2).

4. **Do not skip the header for SKIP / REFERENCE_ONLY files** — they are
   not in DRM.jl, so they cannot need a header. Only the files that ship
   in DRM.jl carry the provenance header.

5. **Mention provenance in the slice PR description.** Per drmTMB's
   `AGENTS.md` line 9: "If code is ported from `gllvmTMB` or another
   package, document provenance in `inst/COPYRIGHTS` before treating the
   change as complete." The DRM.jl equivalent is `COPYRIGHTS.md`. The
   slice must update it as part of the same PR that introduces the code.

---

Word count: ~930 prose words (≈ 2400 incl. table cells). Table row count: 24.
