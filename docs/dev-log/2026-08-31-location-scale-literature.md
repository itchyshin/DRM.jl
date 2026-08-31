# Location-scale and location-scale-scale: focused reading note

**Scope.** This is a conceptual literature note for the DRM.jl/drmTMB parity programme. The three named intake PDFs were not present at the supplied paths, so the reading used the corresponding public primary versions below. The Leckie equations were checked in the public author-preprint PDF and against the final open publisher text; the JSS paper and erratum were downloaded from JSS; Zhang and Hedeker were read in the open publisher/PMC full text (the publisher PDF endpoint returned 403). This is not evidence that any particular DRM.jl route fits, or infers for, the models below.

## Sources and evidence checked

1. Leckie, G., Parker, R., Goldstein, H., & Tilling, K. (2024). *Mixed-Effects Location Scale Models for Joint Modeling School Value-Added Effects on the Mean and Variance of Student Achievement*. **Journal of Educational and Behavioral Statistics, 49**(6), 879-911. https://doi.org/10.3102/10769986231210808. Final paper, pp. 891-894, Eqs. (2)-(6); public author-preprint, pp. 13-17, Eqs. (2)-(6), visually checked on preprint pp. 13-14. Final first-online date: 27 November 2023.
2. Zhang, X., & Hedeker, D. (2022). *Defining R-squared measures for mixed-effects location scale models*. **Statistics in Medicine, 41**(22), 4467-4483. https://doi.org/10.1002/sim.9521; PMCID: PMC9481677. Eqs. (1)-(18), Tables 1-3, and Discussion; open full text and machine-readable primary XML checked. The journal's printed page range is 4467-4483.
3. Hedeker, D., & Nordgren, R. (2013). *MIXREGLS: A Program for Mixed-Effects Location Scale Analysis*. **Journal of Statistical Software, 52**(12), 1-38. https://doi.org/10.18637/jss.v052.i12. PDF pp. 3-7, Eqs. (1)-(12), visually checked on pp. 3-6. Its 24 September 2013 erratum corrects some p-value calculations in `mixregls_function.R`; it says these values were not shown in the manuscript. It does **not** amend the paper's model equations.

## What the papers call a mixed-effects location-scale model

All three papers concern **conditionally Gaussian, two-level MELS models**. They distinguish three quantities that should not be collapsed into a single word "scale":

| Quantity | JSS / Zhang notation | What varies | Typical link |
|---|---|---|---|
| Location | `x_ij' beta + v_i` | conditional mean, including a random location intercept/slope | identity |
| Within-subject (WS) / residual variance | `sigma^2_eij` | residual variance around the conditional mean; covariates and a subject/group random scale effect may enter | **log variance** |
| Between-subject (BS) / random-effect variance | `sigma^2_vi` | variance of the random location effect itself, which may depend on covariates | **log variance** |

The term *scale* in these papers operates on the **variance metric**, even though scale can elsewhere mean SD (Zhang & Hedeker, p. 4468, Sec. 1). Thus a coefficient in `log(sigma^2)` is twice the matching coefficient in `log(sigma)`. That conversion is essential when comparing these papers with DRM.jl's documented `sigma` and `sd(...)` formulas, which use log-SD.

### Hedeker & Nordgren (2013): the broadest two-variance template

Their basic model is

`y_ij = x_ij' beta + nu_i + e_ij`  (Eq. 1),

with covariate-dependent BS and WS variances

`Var(nu_i) = sigma^2_nu,ij = exp(u_ij' alpha)`  (Eq. 2),

`Var(e_ij) = sigma^2_e,ij = exp(w_ij' tau)`  (Eq. 3).

The full MELS version adds a random scale effect to **WS residual variance**,

`sigma^2_e,ij = exp(w_ij' tau + omega_i)`  (Eq. 4),

so `omega_i` is Normal on log variance and makes the subject-specific WS variances log-normal. The random location effect `nu_i` and random scale effect `omega_i` can have covariance `sigma_nu,omega`; the equivalent standardized/Cholesky representation is Eqs. (5)-(7). Their Eq. (8) reexpresses the linear association as a regression of log WS variance on the random location effect. Eq. (9) extends that dependence quadratically; it is not merely a reparameterisation of the correlated Gaussian model. Neither expression models the variance of the random location effect.

Crucially, the paper separately permits covariates on BS random-effect variance (Eq. 2) and WS residual variance (Eqs. 3-4). This is an earlier formulation of the component that DRM.jl documentation calls location-scale-scale: a third predictor changes the SD of a latent location random effect. It is not merely a random effect on the residual-scale formula.

**Estimation.** MIXREGLS is maximum likelihood: 20 preliminary EM iterations for starting values, then three Newton-Raphson stages (BS variance effects; WS variance effects; random scale plus its association with location), with numerical, optionally adaptive, quadrature over random effects; empirical-Bayes random effects follow convergence (pp. 2, 7, Appendix A). The paper warns that the final random-scale stage can be sensitive to quadrature and that a random-scale variance may not be identifiable even with many quadrature points (p. 10). Its ICC varies with covariates under the model (Eqs. 10-12, p. 6).

### Leckie et al. (2024): residual variance differs by school

Leckie et al.'s Model 2 is

`y_ij = beta_0 + beta_1 x_1ij + u_j + e_ij`,

`log(sigma^2_e,j) = alpha_0 + v_j`,  (Eq. 2)

where `(u_j, v_j)` are bivariate Normal. `u_j` is a school random mean effect; `v_j` is a **random residual-log-variance** effect. `sigma^2_v` is variation across schools in log residual variance, and `sigma_uv` describes association between school mean and school residual variance. Their Model 3 adds a covariate to the residual variance function,

`log(sigma^2_e,ij) = alpha_0 + alpha_1 x_1ij + v_j`  (Eq. 3).

They also fit random-slope extensions (Models 4-6). A random slope changes part of the marginal within-school variance, but alone leaves `sigma^2_e` constant; the MELS extension supplies the additional residual-variance term (pp. 895-898, Eqs. 4-6). Their substantive point is to compare adjusted school variances at a **common covariate value**, rather than confounding the school variance with differing student composition (p. 894).

**Estimation.** They fit these Gaussian models by Bayesian adaptive Metropolis-Hastings MCMC (`bayesmh`), with hierarchical centering, diffuse Normal fixed-effect priors, minimally informative inverse-Wishart covariance priors, four chains, diagnostics, and DIC comparison (p. 900). This is an application/estimation choice, not a claim that MELS must be Bayesian.

### Zhang & Hedeker (2022): model-implied R-squared, not a generic pseudo-R2

Zhang & Hedeker start from the same two-level Gaussian MELS family. For the random-intercept version (pp. 4469-4470, Eqs. 1-6):

`y_ij = beta_0 + x_ij' beta + v_i + epsilon_ij`  (Eq. 1),

`Var(v_i | u_ij) = exp(alpha_0 + u_ij' alpha)`  (Eq. 2),

`Var(epsilon_ij | w_ij, omega_i) = exp(tau_0 + w_ij' tau + omega_i)`  (Eq. 3).

Here `v_i` is a random location effect; `omega_i` is a random residual-log-variance effect. They may correlate (`rho_v,omega`; Eq. 6). Their second specification uses random intercepts plus random slopes of observation-level covariates (Eqs. 7-11), while still allowing the residual variance model above.

Their R-squared family is constructed from **model-implied variances**, after decomposing an observation-level covariate into its between-subject mean and within-subject deviation (Eq. 12). Location variance is partitioned into fixed within-subject (`f1`), fixed between-subject (`f2`), random-location (`v`, or `v1/v2/m` for random slopes), and residual-scale (`e`) components (Eqs. 13-18; Tables 1-2). The subscript gives the denominator: total (`t`), within-subject (`w`), between-subject (`b`), or residual scale (`s`) (p. 4474, Tables 1-3).

For the scale part, `e0` is residual variance at mean scale covariates with no random-scale contribution; `e-e0` is the variance attributable to scale covariates and random scale effects. They divide the latter among covariate-derived log-scale components (`e1`, `e2`) and random-scale component `d = sigma^2_omega/2`; for example, `R_s^2(d)` is the attributed proportion for the random residual-scale effect (Table 3). This is a decomposition of the fitted MELS variance function, **not** a universal response-scale R2 and not a likelihood-comparison statistic.

**Limits stated by the authors.** The framework is two-level, applies to their continuous MELS specifications, assumes their variance/covariate decomposition, presently reports point estimates, and defines R2 for one model rather than between-model differences. They identify three-level, count/ordinal, autocorrelated residual, and bootstrap-interval extensions as future work (p. 4481, Discussion). The paper therefore does not supply a ready-made R2 for DRM.jl's Gamma mean/shape model.

## Map to the documented DRM.jl concepts (our inference)

The current DRM.jl documentation distinguishes:

* **Location-scale:** `mu` plus residual `sigma`; its Gaussian tutorial has `log sigma`, so a literature coefficient on `log sigma^2` corresponds to `2 * coef(:sigma)` on the paper's variance scale.
* **Location-scale-scale:** `mu`, residual `sigma`, plus `sd(group)`, which predicts the **SD of the latent location random effect**. The docs' Gaussian example has `log sigma_b,i = alpha_0 + alpha_1 z_i`; in the MELS papers the closest same-idea form is `log Var(nu_i) = u_ij' alpha`, and the SD coefficient is one half of the paper's variance coefficient.
* **Separate fourth idea:** a random effect in the residual-scale formula, e.g. `sigma ~ ... + (1 | group)`, corresponds to MELS `omega_i` / Leckie's `v_j`: heterogeneity in **residual** log variance. It must not be described as a predictor of random-effect SD.

This mapping is about nomenclature and mathematical scale. The active parity repair concerns **Gamma location/shape with random effects on log shape**, not Gaussian residual-SD MELS. These papers support the value of explicitly naming which distributional quantity varies; they do not validate a Gamma likelihood, its random-effects integration, its inference, or its R2.

## Practical proposals (proposals only)

1. **Documentation crosswalk.** Add a compact three-row glossary to the location-scale-scale page: residual `log sigma` (DRM.jl), residual `log sigma^2` (MELS papers), and random-effect `log sd` / `log Var` conversion. State `log Var = 2 log SD` once beside each translation.
2. **Terminology guard.** Reserve “location-scale-scale” for a predictor on `sd(group)`/a latent random-effect SD. Call a random effect on `sigma` “random residual scale” (or “random residual log-variance”), matching the MELS distinction. This prevents readers from mistaking the two models for one another.
3. **Gaussian documentation example.** In an eventual docs-only example, show the two distinct third components side by side: `sigma ~ x + (1|id)` versus `sd(id) ~ z`. Ask different scientific questions and have different likelihood structure. Do not add a MELS claim to Gamma documentation.
4. **Future research/test design.** If a Gaussian MELS compatibility slice is ever opened, use the analytic conversion as a test oracle: simulate on `log Var` and assert the recovered log-SD slope is half the generating slope. Separately test the sign/meaning of the location--residual-scale covariance. This is a future scoped test, not a request to implement it now.
5. **R2 boundary note.** Do not expose a generic `R2MELS`-style statistic for all families. Any future MELS R2 needs a named estimand, its variance decomposition, outcome assumptions, and uncertainty method; Zhang & Hedeker's paper is a strong template for that contract, not a drop-in formula.

## Terminology for our documentation

The literature uses “location-scale” for a conditional mean together with a model for residual **variance**, often including correlated random effects on the mean and residual log variance. It also explicitly models the variance of the random location effect, which is the closest conceptual analogue of DRM.jl’s “location-scale-scale.” The terminology becomes reliable only when every coefficient states whether it is on log variance or log SD, and whether it governs residual dispersion or latent random-effect dispersion.
