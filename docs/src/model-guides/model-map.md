# What can I fit today?

This page is the **map of the model space** DRM.jl covers — the overview for the
Model Guides. It mirrors drmTMB's
[What can I fit today?](https://itchyshin.github.io/drmTMB/articles/model-map.html),
and points you at the guide or tutorial for each piece. Read it top to bottom for
the big picture, or jump to the [which page next](#Which-page-next) table.

## The one idea: a formula per parameter

DRM.jl is **distributional regression** — you put predictors on *every*
parameter of the response distribution, not just the mean. Each parameter gets
its own formula, bundled together with [`bf`](@ref):

| Parameter | What it controls | Formula |
|---|---|---|
| **μ** (mean / location) | where the response sits | the response formula, `y ~ …` |
| **`sigma`** (scale / dispersion) | how spread out it is | `sigma ~ …` |
| family extras — `nu`, `zi`, `hu`, `zoi`, `coi` | shape, zero-inflation, hurdle, boundary mass | `nu ~ …`, `zi ~ …`, … |
| **`rho12`** (bivariate only) | residual correlation between two responses | `rho12 ~ …` |

Always write `sigma` (never `tau`) for the scale and `rho12` for residual
correlation. The same machinery drives every parameter: a formula → a linear
predictor → a family-specific link. Which parameters are *available* depends on
the family (Gaussian has no `nu`; only counts take `zi` / `hu`).

See [Which scale are you modelling?](which-scale.md) for the difference between
the residual `sigma`, a group-level SD, and a known sampling variance — they are
distinct quantities DRM.jl keeps separate.

## The `bf(...)` front end

[`bf`](@ref) (alias `drm_formula`) collects one formula per parameter and reads
exactly like drmTMB and brms. It has two forms:

**Univariate — positional.** The first formula is the mean; the rest name their
parameter on the left-hand side:

```julia
bf(@formula(y ~ x), @formula(sigma ~ x))                 # mean + scale
bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1))   # + shape (Student)
```

**Bivariate — keyword.** Name each of the two responses' parameters explicitly,
including the residual correlation `rho12`:

```julia
bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
   sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
   rho12 = @formula(rho12 ~ x))
```

You pass the bundle and a family to [`drm`](@ref):
`drm(bf(...), Gaussian(); data = dat)`. ML is the default (REML likelihoods are
not comparable across fixed-effect structures, so ML is what model selection
needs). For the full grammar — including `cbind(successes, failures) ~ …` for
binomial-type responses — see the
[model specification reference](../reference/model-specification.md).

## Supported families

Pick the family from the *shape* of the response; the
[Choosing response families](distribution-families.md) guide has the full
decision table and worked examples. DRM.jl implements drmTMB's complete family
set:

| Family | Response | Mean link | `sigma` slot / extras |
|---|---|---|---|
| [`Gaussian`](@ref) | real-valued, symmetric | identity | residual SD `σ` (log) |
| [`Student`](@ref) | real-valued, heavy tails | identity | scale `σ` + d.o.f. `nu` |
| [`LogNormal`](@ref) | positive, multiplicative | identity on `log y` | SD of `log y` |
| [`Gamma`](@ref) | positive, continuous | log | CV → shape `α = 1/σ²` |
| [`Tweedie`](@ref) | positive **with exact zeros** | log | √dispersion `σ` + power `nu` ∈ (1,2) |
| [`Poisson`](@ref) | counts (var ≈ mean) | log | — (`+ zi` / `+ hu`) |
| [`NegBinomial2`](@ref) | overdispersed counts (NB2) | log | dispersion `θ` (`+ zi` / `+ hu`) |
| [`TruncatedNegBinomial2`](@ref) | positive counts (≥ 1) | log | dispersion `θ` |
| [`Beta`](@ref) | proportions in (0,1) | logit | precision `φ = 1/σ²` |
| [`BetaBinomial`](@ref) | successes / trials, overdispersed | logit | `φ = 1/σ²` (`cbind`) |
| [`Binomial`](@ref) | successes / trials | logit | — (`cbind` or 0/1) |
| [`ZeroOneBeta`](@ref) | proportions on `[0,1]` incl. 0 and 1 | logit | `φ` + `zoi` / `coi` |
| [`CumulativeLogit`](@ref) | ordered categories `1..K` | logit (cutpoints) | K−1 ordered cutpoints |

The count modifiers — `zi` (zero-inflation, ZIP / ZINB), `hu` (hurdle), and the
beta boundary modifiers `zoi` / `coi` — are themselves formulas you add to the
bundle, e.g. `bf(@formula(y ~ x), @formula(zi ~ 1))`.

## Structured and random effects

On top of fixed effects, DRM.jl carries ordinary random effects and several
**structured** effects whose covariance comes from a known matrix or geometry.
Write them as terms in the mean formula:

| Effect | Term | What it encodes |
|---|---|---|
| Random intercept / slope | `(1 \| g)`, `(0 + x \| g)`, `(1 + x \| g)` | exchangeable group variation; correlated slopes |
| Crossed / nested RE | `(1 \| g) + (1 \| h)` | multiple grouping factors |
| [`phylo`](@ref) | `phylo(1 \| species)` | covariance from a phylogenetic tree |
| [`spatial`](@ref) | `spatial(1 \| site)` | exponential kernel over coordinates, estimated range |
| [`animal`](@ref) | `animal(1 \| id)` | additive-genetic covariance from a pedigree `A` |
| [`relmat`](@ref) | `relmat(1 \| id)` | a user-supplied relatedness matrix `K` |
| [`meta_V`](@ref) | `meta_V(v)` | known sampling (co)variances for meta-analysis |

**Which families route which effects.** Gaussian gets the full set — random
intercept/slope, correlated and crossed RE, phylo / spatial / animal / relmat
structure, `meta_V`, and a random effect *on* `sigma` — fit in closed form or
via a sparse augmented-state Laplace approximation. The non-Gaussian families
(Poisson, NB2, Binomial, Gamma, Beta, and the deeper Student-t / LogNormal /
Beta-binomial GLMMs) carry random intercepts and correlated slopes via
Gauss–Hermite marginals, and **phylogenetic** (`phylo`) effects via a sparse
Laplace path — currently with a **constant `sigma`**. So put predictors on
`sigma` for Gaussian freely; for the count/proportion families, vary the mean and
keep dispersion constant when adding a structured or phylogenetic effect.

For the verified engine behind the phylogenetic models — the q=4 phylogenetic
bivariate location–scale model that fits 2.18× faster than drmTMB with valid
intervals where its Hessian is singular — see `HANDOVER.md` and
[`report/comparison-grid.md`](https://github.com/itchyshin/DRM.jl/blob/main/report/comparison-grid.md).

## After the fit

Every fitted model supports the same post-fit surface: [`coef`](@ref),
[`stderror`](@ref), Wald **and** profile-likelihood [`confint`](@ref),
[`fitted`](@ref) / [`residuals`](@ref), [`predict`](@ref), [`simulate`](@ref),
parametric [`bootstrap_ci`](@ref), `summary` / [`coeftable`](@ref), and
[`aic`](@ref) / [`bic`](@ref) for ML model selection. Variance components come
back via [`re_sd`](@ref) (one SD per grouping) and [`vc`](@ref) (the RE
covariance). See
[Checking and using fitted models](model-workflow.md) for the workflow, and
[Which scale are you modelling?](which-scale.md) for honest inference at a
variance boundary (where drmTMB's `sdreport` returns all-`NaN`).

## Which page next

| If you want to… | Go to |
|---|---|
| Fit your first model, end to end | [Get started](../get-started.md) |
| Choose the right response family | [Choosing response families](distribution-families.md) |
| Tell residual `σ`, group SD, and known V apart | [Which scale are you modelling?](which-scale.md) |
| Extract coefficients, CIs, predictions | [Checking and using fitted models](model-workflow.md) |
| Diagnose convergence | [Convergence](convergence.md) |
| Scale to large data | [Large data](large-data.md) |
| Choose the marginal method (Laplace vs VA) | [Marginal: LA vs VA](marginal-la-vs-va.md) |
| Model variability as signal (location–scale) | [When variance carries signal](../tutorials/location-scale.md) |
| Change residual coupling with `rho12` | [Changing residual coupling with rho12](../tutorials/bivariate-coscale.md) |
| Robust continuous responses | [Robust continuous responses](../tutorials/robust-student.md) |
| Counts and extra zeros | [Count abundance and extra zeros](../tutorials/count-nbinom2.md) |
| Proportions and success rates | [Proportions and success rates](../tutorials/proportion-beta-binomial.md) |
| Phylogenetic / spatial / animal models | [Phylogenetic](../tutorials/phylogenetic-models.md) · [Spatial](../tutorials/spatial-models.md) · [Animal](../tutorials/animal-models.md) |
| Meta-analysis with known variances | [Meta-analysis](../tutorials/meta-analysis.md) |
| The full API reference | [Model specification](../reference/model-specification.md) · [Fitting & post-fit](../reference/model-fitting-and-postfit.md) |
| What's planned next | the [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md) |
