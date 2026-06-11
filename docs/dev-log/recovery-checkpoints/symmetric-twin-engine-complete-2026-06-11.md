# Recovery checkpoint — symmetric-twin ENGINE feature-complete (2026-06-11)

Branch: `shannon/RELEASE-drm` (tip `864b4b4`). All five non-Gaussian "must-close"
clusters from the ultra-plan PLUS REML-for-all-Gaussian are implemented, merged,
FD-gated (≤1e-6), recovery-verified, and bench-clean. This is the DRM.jl half of
the symmetric twin; the drmTMB R-side routing is the next chunk (scoped below).

## What landed (merge order on RELEASE-drm, off `dfb1fd9` Phase-0 baseline)

| commit | slice | capability | gate |
|---|---|---|---|
| `c38bdc4` | REML | method=:REML for EVERY Gaussian route (RE/structured/bivariate/meta_V) via +½logdet(Xμ'V⁻¹Xμ) | test_reml green |
| `3611ff8` | REML parity | DRM.jl REML == lme4 (RI/corr/crossed) + metafor (meta_V) | 15/15, **= lme4 to 5-6 figs** |
| `bb21c28`+`6ac82c1`→`22c1e26` | ① | correlated/independent non-Gaussian slopes `(1+x\|g)`,`(0+x\|g)` → unified q2 Z_lat core (Poisson/Gamma/NB2/Beta/LogNormal) | equiv vs GHQ 18/18 |
| `6c5551a` | ⑤b | rich bivariate non-Gaussian = frequentist sparse-O(p) MR-PMM (block-diagonal q×q GLM leaf on the coevo q-block) | Gaussian×Gaussian≡conjugate to 9e-10; ρ12 profile CI |
| `40a95a7`+`eb2d736`→`0b860c9` | ② | standalone σ-axis RE `sigma~(1\|g)` (NB2/Gamma/Beta) via the SYMMETRIC spine (latent on Zψ) | FD ≤1e-6 (h-sweep trough) |
| `864b4b4` | ③ | structured non-Gaussian slopes `relmat/phylo/animal/spatial(1+x\|g)` (Poisson/NB2/Gamma/Beta) | FD trough 1e-9..1e-11 |

Bench (`run_sparse_tmb_nd.jl`, q4 PLSM Gaussian phylo, the headline path — untouched
by all clusters): logLik −256.5177 (matches drmTMB −256.52), **2.16×–2.30× faster**
across every post-merge run. The zero-alloc inner-loop gate (`test_qgate_alloc_inner`)
stays in-suite.

## The load-bearing architecture fact (why ②③ were cheap)

The location-scale spine `_ls_joint`/`_ls_joint_grad`/`_ls_joint_hess`
(`src/locscale_inner.jl`) is SYMMETRIC in the mean (η) and scale (ψ) axes: it takes
per-obs loadings `Zη`/`Zψ` (canonical `Zη=[1 0], Zψ=[0 1]`). So:
- ① = slope loadings `Zη=[1 xᵢ]` on the unified core (`src/locscale_corr.jl`,
  `_fit_corr_locscale`), mapping the 2×2 Λ back to the GHQ `[L11,L22,L21]` :recov.
- ② = the SAME pattern with the latent on the scale axis (`src/locscale_sigma.jl`).
- ③ = ① with `Q≠I` — `_fit_corr_locscale` gained an optional `Q` arg fed by cluster 4's
  `_general_cov_setup`/`_locscale_structured_q` (`src/locscale_fit.jl`).
- ⑤b = the coevo q-block (`src/coevolution_q.jl`) with the Gaussian leaf swapped for a
  family-dispatched block-diagonal leaf (`src/rich_bivariate.jl`), reusing
  `marginal_and_exact_grad` verbatim — only the per-obs leaf derivatives change.

All reuse the ONE exact-gradient recipe (Takahashi diag + Q-pattern Λ-trace + implicit
adjoint); family input = only the leaf derivatives.

## FD-gate discipline confirmed (the #164 lesson, reinforced this session)

A fixed small h makes the marginal-NLL FD *reference* dominated by inner-mode-solve
noise (≈ residual/h), NOT analytic error. Sweep h and take the trough. Verified live
on ② (NB2 trough 2.2e-7 at h≈3e-3; the 1/h tail at small h is pure inner noise).
`test_sigma_axis_re.jl` has `_fd_gate_min`; cluster 4/3 use the relative-trough variant
(for large-gradient families like Gamma, |grad|~186).

## Next chunk — drmTMB R-side routing (NOT yet done)

The DRM.jl `src/bridge.jl` is GENERAL (`_bridge_formula` → `bf()` bundle → `drm()`),
so the new RE structures route with NO engine-side change. The work is R-side:
1. Point the bridge at this engine: `DRM_JL_PATH=/Users/z3437171/worktrees/DRM-RELEASE`
   (env var read at `R/julia-bridge.R:763`).
2. Relax the per-family validator walls (`R/drmTMB.R`: "X models only support mu/sigma",
   the REML het-σ/structured/bivariate walls at ~588/594/566).
3. Extend `drm_julia_family_tag` (`R/julia-bridge.R:~160`) beyond "phylo-intercept only":
   route phylo structures for the SPEED edge AND i.i.d. ①② for the CAPABILITY gap.
4. Plumb the REML *estimation* flag through the bridge (today it carries only the
   inference method wald/profile/bootstrap, not ML/REML).
5. Parity tests mirroring `tests/testthat/test-nongaussian-mu-random-slopes.R`,
   `test-nongaussian-scale-boundary.R`, `test-julia-structured.R`.

## Launch (Phase C) — USER-GATED

DRM.jl → Julia registry (version **0.2.0**; pre-existing tags v0.1.0/v0.1.1) and
drmTMB → CRAN are external writes held for one coordinated launch. The drmTMB CRAN
submission (`192e5392`, v0.1.4) is prepared but UNCONFIRMED pending the symmetric twin.
GLLVM cross-pollination brief: draft, file on go-ahead.

## Positioning honesty note (from the 2026-06-11 lit check)

⑤b's model class is NOT new — copula GAMLSS/GJRM (Marra & Radice "Bivariate Copula
Additive Model for Location, Scale and Shape") does bivariate different-distribution
distributional regression; MR-PMM (Halliwell et al. 2025, Biol. Rev.) does different
families on a phylogeny (Bayesian, MCMCglmm/brms). Our contribution is the METHOD:
frequentist + sparse-O(p) phylo + exact-gradient + location-scale + profile-CI ρ12.
Claim "fast frequentist O(p) phylogenetic location-scale MR-PMM", NOT "first".
