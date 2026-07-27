# Phylogenetic location–scale models: putting a tree on `sigma`

*A worked-example guide to DRM.jl's univariate Gaussian σ-phylo subsystem.*

Most phylogenetic comparative models let related species share a **mean**. Closely
related birds tend to have similar body sizes; that shared signal is the
phylogenetic random effect on the mean. But species can also share how *variable*
a trait is — its residual scatter, not just its average. A clade might be
consistently more variable around its own mean than its sister clade, for reasons
that themselves track the tree.

A **location–scale** model lets you write a regression for the residual scale `σ`
just as you write one for the mean `μ`. A **phylogenetic** location–scale model
puts the *tree* on that scale formula, so the residual variability is allowed to
covary across the phylogeny. DRM.jl now fits the Gaussian case of this model
directly. This article shows the exact syntax, the three ways you can wire the
tree onto the two axes, how to read the confidence intervals honestly when a
variance component collapses to zero, and a small simulated example you can run.

Everything here is **maximum likelihood (ML)**, which is the default and the only
estimator currently wired for this route. REML is planned but not yet available
for σ-phylo models (see *REML* near the end).

---

## The model in one paragraph

For observation *i* in species *s(i)*:

```
y_i  =  μ_i  +  ε_i,        ε_i ~ Normal(0, σ_i²)
μ_i      = Xμ_i · βμ  +  u_μ[s(i)]         (mean, optionally with a phylo RE)
log σ_i  = Xσ_i · βσ  +  u_σ[s(i)]         (log scale, optionally with a phylo RE)
```

The two species-level effects `u_μ` and `u_σ` are each drawn from a multivariate
normal whose **correlation structure is the phylogeny** (built from the tree) and
whose **scale** is a variance component the model estimates: `sd_mu` for the
mean axis and `sd_sigma` for the log-scale axis. The scale axis uses a log link,
so a phylo effect there multiplies the residual SD up or down for a whole clade.

The capability is genuinely new relative to the R twin drmTMB: drmTMB models a
phylogenetic SD of the **mean** random-effect block, but it does not put a phylo
random effect on the **residual log-σ axis**. That residual-scale tree is what
this subsystem adds.

---

## The syntax

You build the model with `bf()` — one formula per distributional parameter — and
fit it with `drm(..., Gaussian())`, passing the tree.

```julia
using DRM

fit = drm(
    bf(@formula(y ~ x + phylo(1 | species)),     # mean μ: fixed effect x + phylo RE
       @formula(sigma ~ phylo(1 | species))),    # log-scale σ: phylo RE
    Gaussian();
    data = data,
    tree = tree,
)
```

Three things to get right:

1. **The first formula is the response and the mean.** `y ~ x + phylo(1 | species)`
   sets the response `y`, the mean predictor `x`, and (here) a phylogenetic random
   intercept on the mean. The mean is `μ`; you never write `mu ~ …`.

2. **The scale parameter is named `sigma`** — always, never `tau`. The second
   formula `sigma ~ …` is what makes this a location–scale model. Put the
   tree marker on its right-hand side: `sigma ~ phylo(1 | species)`. If you omit
   the `sigma` formula entirely, it defaults to `sigma ~ 1` (a constant residual
   scale) and you are back to an ordinary phylogenetic mean model.

3. **`phylo(1 | species)`** is the tree marker. The grouping factor (`species`)
   must be a column in `data` whose levels match the tips of the tree you pass as
   `tree = …`. The tree can be an `AugmentedPhy` object (e.g. from
   `random_balanced_tree` or `augmented_phy`) or a Newick string.

A small but important syntax note: `bf()` takes **formulas as positional
arguments** with the parameter name on each formula's left-hand side
(`sigma ~ …`). It does **not** take keyword arguments like
`bf(mu = …, sigma = …)` for univariate models — the keyword form of `bf()` is
reserved for the *bivariate* (two-response) front end. Write
`bf(@formula(y ~ …), @formula(sigma ~ …))`, not `bf(mu = …, sigma = …)`.

---

## The three blocks: separate, asymmetric, coupled

Once you decide to model the scale phylogenetically, you have a structural choice
about how the tree touches the two axes. DRM.jl picks the block automatically
from your formulas — you do not pass a "block" argument; you express the block by
where you put the `phylo()` markers.

### Separate (the default, and the headline capability)

Put `phylo(1 | species)` on **both** `mu` and `sigma`:

```julia
bf(@formula(y ~ x + phylo(1 | species)),
   @formula(sigma ~ phylo(1 | species)))
```

This fits two phylogenetic random effects — one on the mean, one on the log-scale
— that are treated as **uncorrelated**. The species-level mean effect `u_μ` and
the species-level scale effect `u_σ` each follow the tree, but the model does not
estimate a correlation between them. You get two variance components, `sd_mu` and
`sd_sigma`, each with its own confidence interval.

**Use this when** you want to ask, independently, "does the mean track the tree?"
and "does the residual scatter track the tree?" — and you have no specific
hypothesis that the two tree effects move together. It is the most common,
most identifiable, and the recommended starting point. It is also the exact model
drmTMB cannot fit.

### Asymmetric (scale-only)

Put `phylo()` on `sigma` but leave `mu` as ordinary fixed effects:

```julia
bf(@formula(y ~ x),                          # mean: fixed effects only
   @formula(sigma ~ phylo(1 | species)))     # scale: phylo RE
```

Here only the **residual scale** carries a tree; the mean is a plain regression.
This is the cleanest test of "is there phylogenetic signal in the variability,
holding the mean structure fixed?"

**Use this when** your mean model is well-described by covariates alone and the
scientific question is specifically about heteroscedasticity that tracks the
phylogeny. One practical caveat: a scale-only phylogenetic effect needs
**replication within species** to be identifiable — at least two observations per
tip (`m ≥ 2`). With a single observation per species the σ-axis variance
component is unbounded below and the fit will not pin it down. (The mean axis does
not have this restriction; the separate block above tolerates fewer replicates on
the mean side.)

### Coupled (correlated mean ↔ scale effects)

The engine also implements a **coupled** block, in which the mean-axis and
scale-axis phylogenetic effects share a free 2×2 covariance — i.e. the model
estimates a correlation between "this clade runs high" and "this clade is more
variable." This is a genuinely interesting biological quantity (do larger-mean
clades also scatter more?).

**Status, stated honestly:** the coupled fitter exists and is tested at the
engine level, but it is **not yet reachable through the `drm()` front door** in
this release. The public routing always fits the separate (uncorrelated) block
when `phylo()` is on both axes. Reaching the coupled block currently requires the
internal entry point `DRM._fit_gaussian_locscale_phylo(...; coupled = true)`
with hand-built design and tree-precision inputs, which is not part of the
supported surface. Treat coupled as "implemented, front-end pending." If your
question needs the mean↔scale correlation, note that and watch for the front-end
wiring.

| You want to ask…                                              | Put `phylo()` on… | Block      | Front-end? |
|---------------------------------------------------------------|-------------------|------------|------------|
| Mean and scale each track the tree, independently             | `mu` and `sigma`  | separate   | ✅ yes      |
| Only the residual scale tracks the tree                       | `sigma` only      | asymmetric | ✅ yes      |
| Mean and scale tree effects are *correlated*                  | both, coupled     | coupled    | ⏳ engine only |

---

## Reading the results

After fitting, the model returns a `DrmFit`. The fixed-effect tables read the
usual way:

```julia
loglik(fit)          # maximised log-likelihood (ML)
is_converged(fit)    # did the optimiser converge?
coeftable(fit)       # Wald table: μ coefficients, log-σ coefficients, and the
                     # phylo SD components, each on its working scale
```

The two phylogenetic variance components — the quantities the model exists to
estimate — come out of a dedicated accessor:

```julia
sds = gaussian_locscale_phylo_sds(fit)
sds.sd_mu      # phylogenetic SD on the mean axis (0.0 for the asymmetric block)
sds.sd_sigma   # phylogenetic SD on the log-scale axis
```

These are reported on the **SD scale** (already exponentiated from the internal
log-SD parameters). For the asymmetric (scale-only) block, `sd_mu` is returned as
`0.0` by construction, since the mean carries no phylo effect there.

> Note: the generic `re_sd(fit)` accessor does **not** surface these components —
> it reads a differently-named block. For σ-phylo location–scale fits, use
> `gaussian_locscale_phylo_sds(fit)`.

---

## Boundary-aware confidence intervals (read these honestly)

Variance components live on a boundary: an SD cannot go below zero. When a clade's
residual scatter carries **no** real phylogenetic signal, the maximum-likelihood
estimate of `sd_sigma` sits at or near zero — and at that boundary the usual
Wald standard error breaks down (the information matrix is singular there, so a
symmetric ± 1.96·SE interval is meaningless or fails outright). This is exactly
the situation where naïve software either crashes or reports a falsely confident
interval.

DRM.jl handles this with an **opt-in, boundary-aware profile-likelihood CI**.
Turn it on with `profile_ci = true`:

```julia
fit = drm(bf(@formula(y ~ x + phylo(1 | species)),
              @formula(sigma ~ phylo(1 | species))),
          Gaussian(); data = data, tree = tree, profile_ci = true)

ci_sigma = fit.scales[:profile_ci_sd_sigma]   # [lower, upper] on the SD scale
ci_mu    = fit.scales[:profile_ci_sd_mu]       # only present for the separate block
```

How to read them:

- **A bounded interval**, e.g. (illustrative) `[0.31, 0.94]`, means the
  phylogenetic scale effect is identified and significantly different from zero:
  the lower endpoint is above the boundary.

- **An interval whose lower endpoint is exactly `0.0`**, e.g. (illustrative)
  `[0.0, 0.22]`, is the *honest* answer when the data carry no scale-phylo signal.
  The boundary **is** the result. This is not a failure — it is the profile
  likelihood correctly reporting that zero is compatible with the data. Read it as
  "no detectable phylogenetic signal in the residual scale; the effect, if any, is
  no larger than the upper endpoint."

- **An infinite upper endpoint (`Inf`)** means the upper side of the profile never
  crossed the likelihood threshold within the searched range — the component is
  effectively unbounded above given these data. Treat the size of the effect as
  poorly constrained from above.

The profile CI re-optimises the model's own likelihood at each trial value of the
variance component, so it is more expensive than the point fit. That is why it is
opt-in. For the σ-axis in particular — the component most prone to collapsing — it
is worth the cost whenever you intend to *report* a `sd_sigma` estimate or claim
phylogenetic signal in variability.

The numbers in this section are **illustrative placeholders to show the shape of
the output**, not results from any specific fit. Run the example below to see real
values on your own simulated data.

---

## A small simulated example you can run

This simulates a separate-block dataset — phylogenetic signal on **both** the mean
and the residual scale — fits it, and reads back the two variance components with
boundary-aware CIs. It mirrors the pattern in the package's own recovery tests.

```julia
using DRM
using Random, LinearAlgebra

Random.seed!(20260612)

# --- 1. A tree and its phylogenetic correlation matrix --------------------
p = 128                                   # number of species (tips)
m = 4                                     # observations per species (need m ≥ 2)
n = p * m
phy = random_balanced_tree(p; branch_length = 0.30)   # an AugmentedPhy
C   = sigma_phy_dense(phy; σ²_phy = 1.0)              # phylo correlation (p×p)
LC  = cholesky(Symmetric(C)).L                        # for drawing correlated effects

# --- 2. Species-level effects that FOLLOW the tree ------------------------
sd_mu_true    = 0.70                       # phylo SD on the mean axis
sd_sigma_true = 0.60                       # phylo SD on the log-scale axis
u_mu    = sd_mu_true    .* (LC * randn(p)) # correlated mean effects
u_sigma = sd_sigma_true .* (LC * randn(p)) # correlated log-scale effects

# --- 3. Build the response -------------------------------------------------
species = repeat(1:p, inner = m)
x  = randn(n)
βμ = [0.5, 0.3]                            # mean intercept, slope on x
βψ = [0.2]                                 # baseline log-σ
y  = [βμ[1] + βμ[2]*x[i] + u_mu[species[i]] +
      exp(βψ[1] + u_sigma[species[i]]) * randn() for i in 1:n]

data = (; y, x, species)

# --- 4. Fit the SEPARATE block (phylo on both axes), ML, with profile CIs --
fit = drm(
    bf(@formula(y ~ x + phylo(1 | species)),
       @formula(sigma ~ phylo(1 | species))),
    Gaussian();
    data = data, tree = phy, profile_ci = true,
)

# --- 5. Read the results ---------------------------------------------------
is_converged(fit)                          # should be true
loglik(fit)                                # maximised log-likelihood

sds = gaussian_locscale_phylo_sds(fit)
sds.sd_mu                                  # estimate near sd_mu_true    = 0.70
sds.sd_sigma                               # estimate near sd_sigma_true = 0.60

fit.scales[:profile_ci_sd_sigma]           # [lower, upper] for sd_sigma
fit.scales[:profile_ci_sd_mu]              # [lower, upper] for sd_mu
```

Because both axes carry real signal in this design, you should see both profile
CIs bounded away from zero, with the point estimates inside their own intervals.
(Exact values depend on the random draw; the point of the example is the
workflow, not specific numbers.)

To see the **honest boundary** behaviour, change the data-generating process so
the scale is constant (drop `u_sigma` from `y` and set `sd_sigma_true = 0`), then
fit the **asymmetric** block:

```julia
fit0 = drm(
    bf(@formula(y ~ x),                       # mean: fixed effects only
       @formula(sigma ~ phylo(1 | species))), # scale: phylo RE
    Gaussian();
    data = data0, tree = phy, profile_ci = true,
)
fit0.scales[:profile_ci_sd_sigma]             # lower endpoint should be exactly 0.0
```

With no phylogenetic signal in the variance, the lower endpoint of the σ-scale CI
comes back as exactly `0.0` — the boundary is the answer, reported without a crash
or a spurious standard error.

---

## REML

REML is a named priority but is **not yet available on this route**. In the
current release, `method = :REML` is implemented only for the *fixed-effect*
Gaussian location–scale model (no random effects, no phylo/structured terms). If
you pass `method = :REML` to a σ-phylo model, the fit raises a clear error rather
than silently giving you an ML fit in disguise. For phylogenetic location–scale
models, use the default `method = :ML`. ML is also the right choice when you plan
to **compare** models with different fixed-effect structures, since REML
likelihoods are not comparable across changes in the mean model.

---

## Scope and caveats, in one place

- **Family:** Gaussian only. The non-Gaussian location–scale σ-phylo families
  (NB2, Gamma, Beta, BetaBinomial) are a separate, in-progress effort and are not
  reached by this Gaussian route.
- **Blocks via `drm()`:** separate (both axes) and asymmetric (scale-only) are
  wired. Coupled (correlated mean↔scale) is implemented in the engine but not yet
  exposed through `drm()`.
- **Identifiability:** the scale-only (asymmetric) block needs `m ≥ 2`
  observations per species.
- **Estimator:** ML only on this route; REML is planned.
- **Standard errors:** the point-fit Wald covariance comes from a finite-
  difference Hessian of the analytic gradient. For variance components near the
  boundary, prefer the profile-likelihood CIs (`profile_ci = true`) over the Wald
  SEs.
- **Confidence intervals:** the profile CIs are boundary-aware and will report
  `[0.0, …]` (no signal) or `[…, Inf]` (unconstrained above) honestly; read those
  endpoints as information, not as errors.

---

*Source of truth for the routing and the fitter: `src/gaussian_core.jl`
(the `drm(::Gaussian)` method, structured-σ routing) and
`src/gaussian_locscale_phylo.jl` (`_fit_gaussian_locscale_phylo`, the separate /
asymmetric / coupled blocks and the boundary-aware profile CI). The accessor is
`gaussian_locscale_phylo_sds`. Recovery and boundary behaviour are exercised in
`test/test_gaussian_locscale_phylo.jl` and
`test/test_gaussian_locscale_phylo_boundary.jl`.*
