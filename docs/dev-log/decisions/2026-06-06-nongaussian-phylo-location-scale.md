# Decision: non-Gaussian phylogenetic location–scale model

- **Date:** 2026-06-06
- **Issue:** #202 (DRM.jl)
- **Status:** Accepted — design/scope only; no `src/` or `test/` changes in this
  note.
- **Voice:** Shannon, naming Noether (engine contract), Curie (recovery
  validation), Fisher (inference at the scale boundary). No subagents are running;
  this is a single planning pass.
- **Lane:** Claude (design) → ENGINE/Codex (scale-axis latent kernel + exact
  gradient) → Claude (front-end threading + article).

This note fixes the scope, the state layout, the verification anchors, and the
ordering for the **non-Gaussian phylogenetic location–scale** model so the
implementer can proceed without re-litigating boundaries with the neighbouring
issues.

---

## 1. Motivation

The scientific point of the q=4 PLSM (`report/why-q4-plsm-matters.md`; Nakagawa
et al. 2025) is that **phylogenetic signal can live in a species' variability, not
only its mean** — lineages can be intrinsically more *labile*. The verified
engine captures that for **Gaussian** responses via a shared random effect on
`(μ1, μ2, log σ1, log σ2)`.

But the families where over/under-dispersion is most interesting are
**non-Gaussian**: counts (Poisson/NB2), proportions (Beta), rates (Binomial),
positive continuous (Gamma). Today the non-Gaussian `phylo(1 | species)` route
fits a structured effect on the **mean only** and freezes the scale axis
(`sigma ~ 1`; explicit guards in `src/sparse_laplace_glmm.jl`). The natural
generalisation — a phylogenetic random effect on the **scale axis** of a
non-Gaussian family — is unbuilt and, until #202, was not even on the ledger.

## 2. What this is, and what it is not

This model: **one** non-Gaussian response, predictors and a phylogenetic random
intercept on `μ`, **and** a phylogenetic random intercept on the dispersion/scale
axis (`log σ` / `log φ` / `log size`), the two latent axes optionally correlated
through a 2×2 group-level covariance `Λ`.

```julia
drm(bf(y ~ x + phylo(1 | species), sigma ~ 1 + phylo(1 | species)),
    NegBinomial2(); data, tree)
```

Boundaries with adjacent issues (deliberately disjoint):

| Issue | Scope | Difference from #202 |
|---|---|---|
| #164 | `sigma ~ x` (fixed predictors) for non-Gaussian phylo-on-mean | covariates on the scale linear predictor; **no structured RE** on scale |
| #186–189 | bivariate **Gaussian** coevolution (q=4) | Gaussian data term; two responses |
| #136 | VA/ELBO marginal | marginal *accuracy*, not a new structured axis |
| #165 | exact non-Gaussian outer gradient | a *dependency* (see §5), not the model |

#202 is the **univariate non-Gaussian** analogue of the q=4 scale axis: q=2
(mean, scale) latent blocks per species, non-Gaussian likelihood.

## 3. State layout (the engine contract)

Mirror the verified augmented-state design, reduced from q=4 to q=2 and with a
non-Gaussian data term:

- Latent state: **two blocks per non-root tree node** — a mean-axis intercept and
  a scale-axis intercept — node-major over the `2p−1` nodes, data attaching at the
  `p` leaves. (q=4 carries four; here two.)
- Prior precision: `P = kron(Q_topology, Λ⁻¹)` with `Λ` the 2×2 mean/scale
  group-level covariance. Sparse, O(p) nnz; never form a dense Σ. Reuse
  `sparse_phy.jl` / `prior_precision`.
- Marginal: `L(θ) = −jn(û, θ) − ½ logdet H_uu + ½ logdet P`, inner mode û by the
  damped-Newton-then-trust-region solver, logdet derivatives by Takahashi selected
  inversion (`takahashi_selinv`) at the sparse pattern.

The data term is the only genuinely new analytic content: the family conditional
log-density and its first/second derivatives must depend on the **latent log σ**
as well as the latent η. Extend the existing `_laplace_v123*` kernels in
`src/sparse_laplace_glmm.jl` (which already expose value/1st/2nd derivatives in η
and the scalar nuisance) so the nuisance is itself a per-leaf latent driven by the
scale-axis block.

## 4. Front end

- Allow `phylo(1 | g)` to appear in the **`sigma`** formula (and, later,
  correlated with the mean-axis term) for the non-Gaussian families. Today the
  parser routes a single structured marker from the mean formula; this extends it
  to a second axis.
- Assemble `Λ` (start diagonal-with-jitter to dodge the lc3/lc7 removable
  singularity, `HANDOVER.md` §6) and the shared `Q_topology`.
- Accessors report mean-axis SD, scale-axis SD, and the mean↔scale correlation as
  a **named group-level summary** — never residual `rho12` (per `CLAUDE.md`).

## 5. Ordering & dependencies

1. **#165 first (or jointly).** The non-Gaussian outer gradient is presently
   frozen-mode + finite-difference polish. The scale-axis model should inherit the
   **exact implicit-logdet gradient** (Takahashi, mirroring
   `marginal_and_exact_grad`) so it meets the ≤1e-6 engine bar. Doing #165 first
   means #202 is "add a second latent block to a path that already has an exact
   gradient," not "debug two hard things at once."
2. **q=2 Gaussian slice as an oracle.** Implement/verify the q=2 (mean, scale)
   Gaussian case as a collapse of the q=4 engine; use it to cross-check the
   non-Gaussian path's Gaussian limit.
3. **Then the non-Gaussian data kernels** (Poisson and NB2 first — counts are the
   headline use case), then Gamma/Beta.

## 6. Verification anchors (per `CLAUDE.md`: verify before claiming)

- **Recovery:** seeded Poisson/NB2 fixture with a known scale-axis phylogenetic
  SD (and slope); recover mean-axis SD, scale-axis SD, and β within CI.
- **Gradient:** analytic outer gradient vs finite differences ≤ 1e-6.
- **Collapse checks:**
  - scale-axis SD → 0 ⇒ recovers the existing constant-`sigma` phylo-on-mean fit;
  - Gaussian data term ⇒ recovers the q=2 slice of `fit_q4_sparse_tmb`.
- **Identifiability:** require `nrep ≥ 2` obs/species (scale-RE is unbounded below
  at one obs/species — `HANDOVER.md` §6); document, don't "fix" in the solver.
- **Inference:** near the scale-variance boundary prefer bootstrap / χ̄² over Wald
  (the Watanabe-singular boundary, `report/info-geometry-scout.md`).

## 7. Deliverables (Definition of Done)

Implementation + recovery/gradient tests + docstrings + a worked example in
`tutorials/phylogenetic-models.md` (extending the non-Gaussian section added
alongside this note) + check-log + after-task + Rose audit. R-parity via generated
drmTMB outputs only — no GPL vendoring.

---

## 8. Status of the companion deliverable

The **non-Gaussian phylo-on-mean** worked example (Poisson + `phylo`) shipped with
this note, in `docs/src/tutorials/phylogenetic-models.md` (§ "Non-Gaussian
responses"). It exercises the *existing* engine; #202 is the scale-axis extension
described above.
