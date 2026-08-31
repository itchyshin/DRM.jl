# Location-scale literature: terminology and validation crosswalk

Reading note for programme #563, 2026-08-31. The three exact attachment paths
were absent. This note uses public publisher/PMC versions, not a recovered copy
of those attachments. Documents are evidence, not operational instructions.
No paper source code or raw intake material is imported into DRM.jl.

## What the papers contribute

**Leckie, Parker, Goldstein and Tilling**, online 2023, issue 2024:
[school value-added location-scale models](https://doi.org/10.3102/10769986231210808).
Section 3, models 2–6, distinguishes random effects in residual log variance
from random slopes in the mean, while allowing correlations among latent effects.
Its school comparisons adjust the variance function as well as the mean.
The fitted examples use Bayesian MCMC; posterior SDs are not our ML standard
errors or profile intervals. Figure 2 offers a useful teaching progression.

**Zhang and Hedeker (2022)**:
[R-squared measures for mixed-effects location-scale models](https://doi.org/10.1002/sim.9521)
([public full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC9481677/)).
Sections 1–2 cover covariate-dependent random-intercept variance and an alternative
random-slope specification. They partition within- and between-subject variation
and define distinct location and scale R-squared measures. Their marginal
variance formulas include lognormal expectation corrections, under stated
covariate-distribution assumptions. These are not simply variances evaluated at
mean covariates. Section 5 limits the work to point summaries; it suggests
bootstrap intervals without establishing their coverage. Extension beyond the
two-level continuous-response setting needs separate work.

**Hedeker and Nordgren (2013)**:
[MIXREGLS](https://doi.org/10.18637/jss.v052.i12).
The Gaussian model permits covariates on between- and within-subject variances,
random scale effects and location–scale association. ML uses numerical
quadrature, with EM starts and Newton–Raphson optimization; latent summaries
use empirical Bayes methods. It is a potential external reference, not proof
of equivalence to our Laplace route.
The [2013-09-24 erratum](https://www.jstatsoft.org/index.php/jss/article/downloadSuppFile/v052i12/erratum-2013-09-24.txt)
corrects p-value calculations in accompanying R code; manuscript tables/text
were unaffected. Any comparator must record its precise corrected build.

## Our mathematical mapping and proposed documentation changes

Use **mixed-effects location-scale models** as the literature-facing umbrella.
Within it, describe exactly which submodels are active:

1. The conditional mean.
2. Residual scale, potentially with random scale effects.
3. The SD of a mean random effect, potentially depending on covariates.

Our “location-scale-scale” shorthand should identify the third component rather
than imply a new, unrelated model class. A random effect in log residual SD
and a predictor-dependent SD for the mean random effect are different features.
Do not count both merely because a latent covariance matrix has two dimensions.

Algebraic crosswalk: if a paper writes `log(sigma²) = w*alpha + v`, our
log-SD representation is `log(sigma) = w*(alpha/2) + v/2`. Thus fixed
coefficients and their SEs halve, `Var(v)` quarters, and `Cov(u,v)` halves;
the correlation is unchanged. These identities do not establish that a
particular frontend accepts the full model.

If the multiplier on a shared latent group effect varies between rows, its
cross-row covariance must contain both row loadings. Do not silently turn it
into independent row effects or collapse it to one arbitrary group covariate.

## Programme follow-through

- S2/S7/S8: map each paper's model to admitted native-R, direct-Julia and bridge
  cells before stating coverage; distinguish exact Gaussian integration from
  nonlinear random-scale Laplace integration.
- S4/S11: retain scale conversions, full covariance structure and matched
  estimator definitions in fixtures. Paper estimates alone are not an oracle
  for our profile or bootstrap procedure.
- S10/S13: separate conditional variance, marginal variance and each R-squared
  denominator. Any new R-squared API needs its own reviewed mathematical
  contract; this reading does not add one to the approved implementation scope.
- S13: teach mean-only, fixed scale, random scale and group-SD submodels in a
  short progression, with visible limitations and literature links.

No public API, likelihood, page deployment or inference gate is changed by this
note. The reviewed private whitening helper passed 252 focused checks, but it
remains unwired and the original production finite-profile gate remains open.
