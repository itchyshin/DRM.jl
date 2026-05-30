# Why the q=4 PLSM matters for DRM.jl

*Strategic framing — drm-julia-poc, 2026-05-29*

## 1. Mission

Phylogenetic location–scale models (PLSMs; Nakagawa et al. 2025, *Methods in Ecology and Evolution*) are the methodological centre of gravity for this line of work. They extend the phylogenetic GLMM (Hadfield & Nakagawa 2010; Ives & Helmus 2011) by treating the log residual standard deviation as a second response with its own fixed effects and phylogenetic random effect (Eqs. 1–4 of the paper; Figure 1d). The framework culminates in the bivariate q=4 model (Section 2.3; Eqs. 26–29), in which four phylogenetic random effects — `a_l1`, `a_l2`, `a_s1`, `a_s2` — share a 4×4 covariance block `Σ_a` that encodes mean–mean, variance–variance, within-trait mean–variance, and across-trait mean–variance phylogenetic correlations. This is the model where the current tooling stops working at field-realistic scale. DRM.jl exists to remove that constraint and make the q=4 PLSM a routine, not heroic, fit.

## 2. The Box 1 pain point

Box 1 of the paper states it plainly: the bivariate PLSM took *approximately 122 hours* to run in brms (Bürkner 2017) on an Apple M1 Ultra with 128 GB RAM. That is the Section 3.3 / Model 5 fit — beak width × beak depth across 354 parrot species from AVONET, with phylogenetic random effects in both `location` and `scale` parts of both traits. The 122-hour ceiling is what frames every downstream design decision here.

The current tooling stack between research-grade-slow and production looks like this:

- **brms / Stan**: 122 h per fit, full Bayesian posterior, q=4 PLSM achievable but not iteration-friendly.
- **MCMCglmm**: similar order of magnitude on the q=4 case, same Bayesian envelope.
- **drmTMB**: TMB + Laplace + the Hadfield–Nakagawa sparse phylogenetic precision `A^{-1}`. The same Model-5-style fit drops to seconds for the frequentist point estimate plus Hessian-based SEs.
- **DRM.jl (planned)**: Julia + sparse Cholesky + automatic differentiation, plus native threading for bootstrap and simulation grids.

drmTMB has already closed most of the 122-hour gap for the frequentist PLSM. DRM.jl is not trying to reopen that gap. It is trying to make the *next* layer of work — bootstrap, coverage simulation, phylogenetic-uncertainty integration, individual-level extensions — actually tractable.

## 3. What PLSMs unlock that traditional PCMs do not

Traditional PCMs (PIC, PGLS, PGLMM) model the mean only and treat residual variance as a nuisance (Section 1). PLSMs make `ln(σ)` a second modelled response (Eq. 4), and the multivariate extension (Eqs. 26–29) gives a covariance block `Σ_a` whose off-diagonal entries are not interchangeable nuisance parameters — they each diagnose a distinct evolutionary mechanism (Figure 2; Figure 3):

- **Mean–mean** `ρ_a(l1l2)` (Eq. 28, top-left of Figure 2) — pleiotropy, anatomical integration, correlated selection on means.
- **Variance–variance** `ρ_a(s1s2)` (Eq. 28, bottom-right) — co-divergence of lability across traits; positive under adaptive radiation, negative under "contra-divergence" (e.g. song elaboration coupled to reduced plumage variability; Badyaev et al. 2002).
- **Within-trait mean–variance** `ρ_a(l1s1)`, `ρ_a(l2s2)` (Eqs. 12–13; Figure 3 "saturation / ceiling") — negative correlation diagnoses ceilings; positive correlation diagnoses co-divergence.
- **Across-trait mean–variance** `ρ_a(l1s2)`, `ρ_a(l2s1)` (Eq. 29) — selection-relaxation: a shift in trait 1's mean associated with altered variance in trait 2 (life-history trade-offs).

The point is that the q=4 PLSM is not a generic distributional regression on a phylogeny. It is a *specific* phylogenetic comparative model with a one-to-one mapping from covariance entries to biological mechanisms. DRM.jl's scope must be framed around supporting this exact model class with maximum efficiency. It is not a general-purpose stats engine.

## 4. The compute story for science

If a single q=4 PLSM fit costs 122 hours, four classes of routine downstream analysis are simply not done:

1. **ADEMP-style coverage and power simulations** for the q=4 PLSM. A modest design — 50 replicates × 24 cells in a parameter grid (p, sample size, true `ρ_a(l1s2)`, tree imbalance) — would require 50 × 24 × 122 h ≈ 146,400 h, roughly 17 wall-clock years on the same M1 Ultra. The simulation is not done. The properties of `ρ_a(l1s2)` under finite sample sizes are therefore not empirically characterised.

2. **Phylogenetic uncertainty integration** via Rubin's rules across posterior trees (Nakagawa & De Villemereuil 2019). Refitting across 1000 posterior trees per Box 1's own recommendation costs 122,000 h in brms — about 14 years. It is mentioned as future work in Box 1 precisely because the compute is prohibitive.

3. **Re-analysis of major comparative datasets** under PLSM. The Discussion (Section 4) calls for re-analysing AVONET, FishBase, PanTHERIA, and similar resources. Even one q=4 fit per dataset is a multi-day commitment; comparing across plausible specifications (with/without phylogenetic effect on scale, different families, sensitivity to outliers) is not.

4. **Model 7 with individual-level data** (Section 2.4; Eqs. 34–36). The paper notes that within-species data are still rare, but where available (e.g. 354 species × ~10 individuals ≈ 3540 rows) the q=4 PLSM expands into a model with both phylogenetic and non-phylogenetic species random effects and individual-level residuals. The fixed cost per fit grows with `n_obs`, not just `p`, putting brms further out of reach.

Each of these becomes a routine workflow if a single fit takes seconds and a 50-rep grid takes minutes.

## 5. Why drmTMB already moved the needle but did not close it

drmTMB takes the Section 3.3 / Model 5 q=4 PLSM and compresses it from 122 hours (brms) to seconds via TMB's C++ AD plus a sparse Laplace approximation around the random effects, exploiting the Hadfield–Nakagawa block-sparse phylogenetic precision `A^{-1}`. That is a roughly 10^5× speedup for the frequentist point estimate. For *one fit*, the problem is solved.

The remaining headroom is:

- **CppAD + R glue overhead.** TMB's tape-recorded AD plus the R↔C++ data marshalling carries a constant overhead that scales poorly when the same model is refit thousands of times for bootstrap or simulation.
- **Wall-clock cost on simulation grids.** A 50-rep × 24-cell ADEMP grid that takes seconds-per-fit still costs hours-per-grid in serial drmTMB. Parallel `parLapply` from R helps but inherits OS-process startup overhead and is not the same as a threaded native loop.
- **Within-species extension (Model 7).** Once `n_obs` grows from ~354 to ~3540 (individual-level data), the per-fit cost increases and the bootstrap / simulation budget tightens further.

drmTMB makes the *frequentist* q=4 PLSM practical. DRM.jl is the increment that makes the *workflow around* the q=4 PLSM practical.

## 6. What DRM.jl can plausibly add on top of drmTMB

The POC benchmark in [`report/summary.md`](summary.md) reports a *median 22.6× speedup* (max 83.8×, min 0.1×) on closed-form Gaussian distributional regression, and the phylogenetic cells show drmTMB at parity or better at large `p` (`phylo_p1000`: drmTMB faster by ~10×) because drmTMB already uses the sparse `A^{-1}` representation. Honest projection for a single q=4 PLSM fit: DRM.jl is realistically 2–10× faster than drmTMB, not 100×.

The compounding factor is not the per-fit speedup; it is parallelism:

- **Threaded parametric bootstrap.** A 20-core machine running `Threads.@threads` over `n_boot = 199` bootstrap fits gives an additional ~10–20× over serial drmTMB bootstrap.
- **Embarrassingly parallel simulation grids.** ADEMP grids decompose along (replicate × cell). Julia's threading model handles this in one line; R-side equivalents require `parallel`/`future` plus per-worker package loading.
- **Composition.** A per-fit 5–10× combined with threaded 10–20× yields a 50–200× total wall-clock improvement on bootstrap-heavy or simulation-heavy workloads. That converts a "drmTMB-takes-an-hour" coverage simulation into a "DRM.jl-takes-a-minute" coverage simulation.

This is the compute story that matters. Not "Julia is faster than R"; rather, "the parametric bootstrap and ADEMP grids around a Gaussian q=4 PLSM stop being a budget item."

## 7. The clean demonstration the v0.1 DRM.jl needs

Three numbered, measurable claims:

(i) **Match drmTMB on the AVONET-scale q=4 PLSM** — `p ≈ 354` parrot species, Model 5 from Section 3.3 (cbeak_width × cbeak_depth with cmass as a fixed effect in all four sub-formulae). Acceptance: `|Δ logLik| < 1e-3`, `max |Δ coef| < 1e-2`, wall-clock no worse than 2× drmTMB on a single fit.

(ii) **Threaded parametric bootstrap** on the same fit at `n_boot = 199`. Acceptance: 10–20× speedup over serial drmTMB bootstrap on a 20-core machine.

(iii) **A 50-rep coverage simulation grid** for the q=4 PLSM. Acceptance: minutes in DRM.jl, hours in serial drmTMB, and an explicit citation back to Box 1's 122-hour benchmark showing that the brms-equivalent run would take centuries.

Three claims, three numbers, one paper-style write-up.

## 8. Out of scope for v0.1

To be explicit about what is *not* in the v0.1 demonstration:

- Model 7 with within-species individual-level data (Section 2.4; Eqs. 34–36) — deferred to v0.2 or later.
- Non-Gaussian families with random effects (count, proportion, ordinal — Box 1's "future opportunities").
- Multi-rate phylogeny (relaxed clock, Ornstein–Uhlenbeck) — the parameterisation lives in the planned GLLVM.jl effort, not here.
- The rest of drmTMB's family catalogue.

v0.1 is: Gaussian PLSM at q=2 (univariate) and q=4 (bivariate), `bf()` + `(1 | p | species)` syntax, single tree. That is the entire surface.

## 9. Effort gate

Implementation: 2–3 weeks of focused work, followed by the comparison plus paper-style write-up. **Not now.** This is the v0.3-ish milestone, logged after the closed-form Gaussian v0.1 lands and the architectural choices in [`DRM-architecture.md`](DRM-architecture.md) and [`laplace-design.md`](laplace-design.md) are validated against drmTMB on simpler cases.

## 10. Connection back to the paper

DRM.jl, when released, should be framed unambiguously: *the computational backend for the PLSM framework introduced in Nakagawa et al. 2025*. Specifically — taking the q=4 bivariate PLSM workflow from research-grade-slow to routine, with native parallelism for the parametric bootstrap, phylogenetic-uncertainty integration, and ADEMP simulation that the 122-hour ceiling currently blocks (Box 1).

This is a follow-up *methods* contribution. It does not invent a model. It does not extend the biology. It removes the binding compute constraint on a model the user has already published and motivated. That is its scope, and that is enough.

---

**Word count: 1622** (verified via `wc -w`).
