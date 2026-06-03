# Decision: variational (VA / ELBO) marginal for random-effect models

- **Date:** 2026-06-02
- **Issue:** #136 (DRM.jl)
- **Status:** Accepted — design only; no `src/` or `test/` changes in this note.
- **Voice:** Shannon, naming Noether (engine contract), Fisher (inference), Curie
  (recovery validation). No subagents are running; this is a single planning pass.
- **Lane:** Claude (design) → ENGINE/Codex (conjugate + GHQ kernels) → Claude
  (front-end threading + report).

This note is a precise blueprint for the engine implementer. It fixes the
algorithm, the interface surface, the verification anchors, and the phased
rollout so that Phase 2+ can proceed without re-litigating scope.

---

## 1. Motivation

The verified DRM.jl marginal for non-Gaussian random-effect models is the
**Laplace approximation (LA)** — a second-order expansion of the integrand at the
inner mode (`src/sparse_laplace_glmm.jl`, the `_*_ranef` / `_*_crossed_laplace`
families; `src/poisson.jl` uses Gauss–Hermite for the single-RE case). LA is fast
and, for the q=4 PLSM, accurate enough to beat drmTMB 2.18× at the same logLik
(`HANDOVER.md` §2). But LA's accuracy is **uneven across the parameter classes**:
it is good on the conditional-mean fixed effects and weak exactly where the
integrand is most skewed — **dispersion / shape / zero-inflation / RE-variance**
parameters. The curvature-at-the-mode assumption misses the mass in the tail of a
skewed latent posterior, and that bias lands on the very nuisance parameters the
distributional-regression program is built to estimate.

**The sister-package evidence (GLLVM.jl).** GLLVM.jl carries both an LA path and a
variational (VA / ELBO) path precisely because LA mis-estimates these classes:

- **Gamma shape α biased ~7× low under LA** — the Gamma log-density is sharply
  skewed in `η = log μ`; the Laplace curvature understates the integral and the
  outer optimiser compensates by collapsing the shape. VA (closed-form `E_q` for
  the Gamma kernel) recovers α.
- **ZINB π ↔ β_c multimodality** — the zero-inflation probability π and the count
  intercept β_c trade off; the LA marginal develops a near-degenerate multimodal
  surface, and the recovered **count-intercept sign flips across OS / BLAS**
  (Linux/MKL vs macOS/OpenBLAS) — a non-reproducibility symptom, not a
  convergence-tolerance one. The VA bound is smoother on this surface and stable
  across BLAS.

These are the documented failure modes that justify a second marginal at all. The
reference implementation to mirror is **`GLLVM.jl/src/families/variational*.jl`**
(the per-family `E_q[log p]` kernels and the inner posterior solve); DRM.jl
reuses the *structure*, not the code (fresh MIT code — see the license boundary in
`AGENTS.md` §Contracts).

---

## 2. Scope

VA earns its cost **only where there is a latent integral to approximate** — i.e.
random-effect (mixed) models. Concretely:

- **In scope:** non-Gaussian RE models — the `_*_ranef`, `_*_corr_ranef`, and
  `_*_crossed_laplace` paths for Poisson / NB / Beta / Gamma / Binomial /
  Beta-binomial. These have a `q(z)` to fit.
- **Out of scope (must ignore `method`):**
  - **Fixed-effect-only** fits (`_fit_poisson`, `_fit_*` with no RE term) — no
    integral, nothing to vary; the likelihood is exact already.
  - **Gaussian distributional regression** (`gaussian_core.jl`,
    `gaussian_bivariate.jl`, `gaussian_meta.jl`, and the Gaussian RE path in
    `gaussian_ranef.jl`) — the marginal is **closed-form** (the q=4 PLSM uses the
    sparse Laplace because of the *non-linear scale* dependence, but the
    Gaussian-response location models integrate the latent in closed form). VA
    would only add error and cost.
  - The verified q=4 PLSM engine (`sparse_aug_plsm.jl`, `fit_q4_sparse_tmb.jl`)
    is **not** in the first VA rollout; it keeps its exact-gradient Laplace.

**Posture.** VA is **opt-in, never the default.** It is **slower than LA**
(an inner per-site optimisation each outer evaluation; GHQ kernels add nodes).
The default stays `method = :LA`, preserving the verified baseline byte-for-byte.
VA is the tool you reach for when LA's nuisance-parameter bias is suspected — and
the verification plan (§5) gives the user a way to *check* that on their own fit.

---

## 3. Interface contract

### 3.1 Method-selection surface (added on branch `va-scaffold`)

A new file `src/variational.jl` introduces the marginal-method type lattice and
the symbol → type resolver. This is **pure scaffolding** — types and a selector,
no kernels — so it can land in parallel with this note (Phase 1).

```julia
abstract type MarginalMethod end
struct Laplace      <: MarginalMethod end   # the verified default
struct Variational  <: MarginalMethod end   # opt-in ELBO marginal

_marginal_method(:LA) = Laplace()
_marginal_method(:VA) = Variational()
_marginal_method(m::MarginalMethod) = m
# anything else → a clear error listing :LA / :VA
```

### 3.2 User-facing keyword

```julia
drm(bf(...), Family(); data, method = :LA)   # default; verified baseline
drm(bf(...), Family(); data, method = :VA)   # opt-in variational marginal
```

`method` accepts `:LA` / `:VA` (or a `MarginalMethod` instance). It is threaded
from `drm(...)` down into the family dispatch and on into the RE fitters.

### 3.3 Which `_fit_*` entry points gain a VA path

The RE fitters that will dispatch on `method` (i.e. grow a `Variational` branch
alongside the existing Laplace/GHQ branch):

| Family | random-intercept | corr (intercept+slope) | crossed/multiple |
|---|---|---|---|
| Poisson | `_fit_poisson_ranef` | `_fit_poisson_corr_ranef` | `_fit_poisson_crossed_laplace` |
| Neg-binomial | `_fit_negbin2_ranef` | `_fit_negbin2_corr_ranef` | `_fit_nb2_crossed_laplace` |
| Beta | `_fit_beta_ranef` | `_fit_beta_corr_ranef` | `_fit_beta_crossed_laplace` |
| Gamma | `_fit_gamma_ranef` | `_fit_gamma_corr_ranef` | `_fit_gamma_crossed_laplace` |
| Binomial | `_fit_binomial_ranef` | — | `_fit_binomial_crossed_laplace` |
| Beta-binomial | `_fit_betabinomial_ranef` | `_fit_betabinomial_corr_ranef` | — |

(The `_fit_*_fixed_crossed_laplace` fixed-dispersion variants share the
`_fit_crossed_mean_laplace` spine in `sparse_laplace_glmm.jl`; they inherit the VA
path through that spine, not through a separate branch.)

**Explicit non-threading.** Fixed-effect fitters and all Gaussian paths **accept
and silently ignore** `method` (they may warn once if `:VA` is passed to a
closed-form/fixed model, but must not error and must not change their result).
This keeps `method` a uniform `drm` keyword without forcing every path to branch.

### 3.4 Result tagging

A VA fit records its marginal in the result object so downstream code,
`summary`, and reports can distinguish the two. The `DrmFit` carries a
`marginal::Symbol` (`:LA` / `:VA`) tag (added in Phase 4); `logLik` on a VA fit is
the **ELBO** (a lower bound), and `summary`/printing must label it as such so it
is never silently compared against an LA logLik in model selection.

---

## 4. Algorithm

Fit a diagonal-Gaussian variational posterior over the latent effects and
maximise the evidence lower bound (ELBO).

### 4.1 The bound

For latent `z` (the RE vector) with prior `z ~ N(0, Σ_θ)` and approximating
family `q(z) = N(m, diag(v))` (mean-field, one `(m_j, v_j)` per latent
coordinate):

```
ELBO(θ, m, v) = Σ_i  E_q[ log p(y_i | η_i) ]  −  KL( q(z) ‖ p(z) )
```

where `η_i = x_iᵀβ + z_{g(i)}` (and `+ z_slope · x_i` for the corr case). The
outer optimiser maximises `ELBO` over `θ = (β, dispersion/shape, log σ_RE)`; the
inner step profiles `(m, v)` (see §4.4). The marginal returned to `drm` is
`-ELBO` as the objective (we *minimise* `nll = -ELBO`, matching the existing
`nll(θ)` convention in the Laplace fitters).

The KL term for diagonal Gaussian vs the RE prior is closed-form (standard
Gaussian–Gaussian KL); for the scalar-intercept case with prior variance
`σ_RE² = exp(2·logσ)` it is the familiar
`½ Σ_j [ v_j/σ² + m_j²/σ² − 1 − log(v_j/σ²) ]`. The corr case uses the
`L Lᵀ` prior covariance already parameterised in `_*_corr_ranef`.

### 4.2 Closed-form `E_q` kernels (conjugate-ish families)

When `log p(y|η)` is **linear in `η` and in `e^{±η}`**, the Gaussian expectation
is analytic via the moment-generating function `E_q[e^{cη}] = exp(c·m + ½c²v)`:

- **Poisson** — `log p = y·η − e^η − log y!`, so
  `E_q[log p] = y·m − exp(m + ½v) − log y!`. Fully closed-form.
- **Gamma** (log link) — `log p ∝ −α·η − α·y·e^{−η} + …`, so
  `E_q` needs `E_q[η] = m` and `E_q[e^{−η}] = exp(−m + ½v)`. Closed-form. This is
  the kernel that fixes the ~7× shape bias.
- **Delta-Gamma** (the Tweedie-style zero-plus-Gamma hurdle in `tweedie.jl`) —
  the positive part is the Gamma kernel above; the Bernoulli "is-positive" part
  uses the GHQ path (§4.3) unless its link is also `e^{±η}`-linear, in which case
  it too is closed-form. Treated as a Gamma-kernel reuse.

These are the **Phase 2** kernels (ENGINE lane).

### 4.3 1-D Gauss–Hermite kernels (everything else)

For families whose `log p(y|η)` is **not** linear in `e^{±η}` — **Binomial**
(logit), **Negative-binomial** (NB2 `log(r+μ)`), **Beta** (digamma/loggamma in
`μφ`) — `E_q[log p]` has no closed form. Compute it by **1-D Gauss–Hermite
quadrature** over the *univariate* `q(z_j)`:

```
E_q[log p(y_i|η_i)] ≈ Σ_k w_k · log p( y_i | m + √(2v)·t_k )
```

reusing the existing `_gauss_hermite(K)` nodes/weights already used in
`_fit_poisson_ranef` (K≈12–32). This is 1-D per site because `q` is mean-field
diagonal — *not* the tensor `K²` grid the Laplace corr path falls back to. The
per-family `log p` evaluators already exist as `_laplace_value(Val{:binomial})`,
`Val{:nb2_fixed}`, `Val{:beta_fixed}` in `sparse_laplace_glmm.jl`; the VA kernel
calls the same value functions at the GHQ abscissae. These are the **Phase 3**
kernels (ENGINE lane).

### 4.4 Inner posterior solve

Per outer `θ`-evaluation, the per-site `(m_j, v_j)` are profiled by an **inner
optimisation** maximising the ELBO over `(m, v)` with `θ` fixed (an analogue of
the inner Newton mode-finder `_poisson_laplace_mode` / `_crossed_mean_mode` in
the Laplace path). Because `q` is mean-field and the groups are disjoint, the
inner problem **factorises per group**, so it is a sequence of low-dimensional
solves (scalar `(m,v)` per intercept group; 2-D `(m, v)` blocks per corr group).
Use the previous outer iteration's `(m, v)` as a warm start (the Laplace path
already warm-starts `b` via `last_b`). Parameterise `v = exp(ρ)` to keep it
positive. The closed-form kernels admit cheap Newton steps; the GHQ kernels use
the same outer AD (ForwardDiff) through the quadrature sum, matching the existing
fully-differentiable GHQ fitters.

### 4.5 Reuse / build map

- **Reuse:** `_gauss_hermite`, the `_laplace_value(...)` per-family `log p`
  evaluators, the RE design helpers (`_group_index`, `_laplace_re_design`),
  `_withformula` / `_withnll`, the `DrmFit` assembly and `Optim.LBFGS` outer loop.
- **Build:** `E_q[log p]` kernels (closed-form + GHQ), the diagonal-Gaussian KL,
  the per-group inner `(m,v)` solver, and the `Variational` dispatch branch in
  each RE fitter listed in §3.3.

---

## 5. Verification plan (deterministic anchors)

The point of these anchors is that they **need no full real dataset and no
external truth** — each is a structural identity that must hold exactly (or as a
provable inequality), so they make good `@test`s. They replace the `@test_skip`s
in `test/test_variational.jl` (the placeholder test file that lands with the
`va-scaffold` scaffold).

| # | Anchor | Why it holds | Concrete test (replaces a `@test_skip`) |
|---|---|---|---|
| a | **RE variance → 0 ⇒ ELBO = independent log-likelihood (exact).** Fit with `σ_RE` (or the corr loadings) driven to ~0. | With no latent spread, `q` collapses to a point mass at 0, `KL→0`, `E_q[log p]→log p(y|Xβ)`. The model degenerates to the fixed-effect GLM, whose likelihood is exact. | `@test elbo_at_zero_var ≈ loglik(fixed_effect_fit) atol=1e-8` — fit `_fit_*_ranef` with the RE variance clamped to ~`exp(-8)` (the existing `-8` clamp floor) and compare to the matching `_fit_*` fixed fit. |
| b | **ELBO ≤ dense Gauss–Hermite quadrature marginal (lower-bound property).** At low latent dimension, compute the true marginal by dense GHQ. | The ELBO is a *variational lower bound* on `log p(y|θ)` by Jensen; a sufficiently fine GHQ approximates the true marginal from above the bound. | `@test elbo(θ) ≤ dense_ghq_marginal(θ) + 1e-6` on a tiny fixture (1 group, K=64 reference GHQ), swept over a few `θ`. |
| c | **Family limits: NB r→∞ ⇒ Poisson-VA.** The NB2 GHQ kernel must converge to the Poisson closed-form kernel as the size parameter grows. | NB2 → Poisson as `r→∞` pointwise in `log p`; the VA kernels inherit the limit. | `@test elbo_nb_va(r=1e6) ≈ elbo_poisson_va atol=1e-4` on a shared fixture. (Companion: Beta φ→∞ concentration, Binomial single-trial sanity.) |

**Bias-recovery validation (report, not a unit test).** Reproduce the two GLLVM
failure modes on `drm` and compare LA vs VA, written up as a `report/` entry
(e.g. `report/va-vs-laplace-bias.md`):

1. **Gamma shape recovery** — simulate a Gamma-response RE model with known α;
   show LA recovers α ~7× low and VA recovers α near truth.
2. **ZINB stability** — simulate the π ↔ β_c trade-off; show LA's count-intercept
   sign-flips across BLAS/OS while VA stays stable and on-sign.

This report is the evidence that flips the docs from "planned" to "implemented"
(Phase 5) and is gated by Rose (claim-vs-evidence).

---

## 6. Phased rollout & lane ownership

| Phase | Deliverable | Lane | Depends on |
|---|---|---|---|
| **1 — Scaffold** | `src/variational.jl`: `MarginalMethod`/`Laplace`/`Variational`, `_marginal_method`; `test/test_variational.jl` with `@test_skip` placeholders for anchors a/b/c. Branch `va-scaffold`. | **Claude** | — (parallel with this note) |
| **2 — Conjugate kernels** | Closed-form `E_q` for **Poisson, Gamma** (and Delta-Gamma reuse); diagonal KL; per-group inner solve; wire `Variational` branch into the Poisson/Gamma `_*_ranef`/`_*_corr_ranef`/crossed fitters. Make anchor (a) pass for Poisson/Gamma. | **ENGINE / Codex** (Noether) | Phase 1 |
| **3 — GHQ kernels** | 1-D GHQ `E_q` for **Binomial, NB, Beta** (+ Beta-binomial); wire the `Variational` branch into their RE fitters. Make anchors (b) and (c) pass. | **ENGINE / Codex** (Noether) | Phase 2 |
| **4 — Front-end threading** | `drm(...; method = :LA/:VA)` keyword threaded into family dispatch and the RE fitters; `DrmFit.marginal` tag; `summary`/print label the ELBO; fixed-effect & Gaussian paths ignore `method`. | **Claude** (Boole front end + Fisher result shape) | Phases 2–3 |
| **5 — Bias-validation + docs** | `report/va-vs-laplace-bias.md` (Gamma-shape + ZINB cases, LA vs VA); flip docs from "planned" to "implemented"; Rose audit. | **Claude** (Curie recovery + Rose gate) | Phase 4 |

Phase 1 is independent and already in flight on `va-scaffold`. Phases 2→3 are
strictly ordered (GHQ kernels reuse the Phase-2 KL + inner-solve plumbing).
Phase 4 needs both kernel phases so every advertised family actually has a VA
path. Phase 5 is the evidence gate.

---

## 7. Risks

- **Slower than LA.** The inner `(m,v)` solve runs each outer evaluation and the
  GHQ kernels add K nodes per site. Mitigation: warm-start `(m,v)` from the prior
  iteration; keep VA strictly opt-in so the verified-baseline timings never move.
- **Inner-solve convergence.** The per-group inner optimisation can stall on
  skewed posteriors (the same surfaces LA struggles with). Mitigation: reuse the
  Laplace path's robust pattern — damped Newton with a step-halving line search
  and a zero-restart fallback (`b0 = zeros` retry in `_*_mode`).
- **Interaction with structured effects (#80).** Phylo/spatial/correlated
  group structures break the mean-field "disjoint groups factorise" assumption
  the inner solve relies on. VA must stay opt-in and **not** be offered for
  structured-effect models until a structured `q` is designed; the q=4 PLSM keeps
  its exact-gradient Laplace. Flag any `method=:VA` request on a structured model
  as unsupported.
- **Bound, not likelihood.** The ELBO is a lower bound; comparing a VA `logLik`
  to an LA `logLik` in model selection is invalid. Mitigation: the `marginal` tag
  + labelled `summary` output (§3.4) and a guard against cross-marginal AIC/LRT.
- **Must stay opt-in.** Any change that makes VA a default, or that routes a
  fixed-effect/Gaussian path through it, regresses the verified engine. Hard line.

---

## 8. Proposed sub-issues under #136

One bullet per phase; open these as sub-issues of #136.

- **#136a — VA scaffold: `MarginalMethod` lattice + `_marginal_method` + skip-tests.**
  Lane: **Claude.** Dependency: none (branch `va-scaffold`, parallel).
- **#136b — VA conjugate kernels (Poisson, Gamma, Delta-Gamma): closed-form `E_q`, diagonal KL, inner (m,v) solve; anchor (a).**
  Lane: **ENGINE / Codex.** Dependency: #136a.
- **#136c — VA Gauss–Hermite kernels (Binomial, NB, Beta, Beta-binomial); anchors (b) and (c).**
  Lane: **ENGINE / Codex.** Dependency: #136b.
- **#136d — Front-end `method = :LA/:VA` threading + `DrmFit.marginal` tag + ELBO-labelled summary; fixed/Gaussian ignore `method`.**
  Lane: **Claude.** Dependency: #136b, #136c.
- **#136e — Bias-recovery report (`report/va-vs-laplace-bias.md`): Gamma-shape + ZINB LA-vs-VA; flip docs to "implemented"; Rose audit.**
  Lane: **Claude (Curie + Rose).** Dependency: #136d.
</content>
