# 2026-08-18 — Noether Cox–Reid scoping probe (#441)

**Lane:** `cursor/lane-cox-reid-probe` @ `~/local-scratch/lanes/DRM.jl-cox-reid-probe`
**Role:** Noether. **Not a ship.** ML stays the default. AGHQ is not this G0.
**Hopper fence:** `docs/dev-log/evidence/2026-08-18-hopper-cox-reid-gllvm-fence.md`
**Reproduce:** `julia --project=. bench/cox_reid_probe.jl` → `bench/out/cox_reid_probe.txt`
**Captured:** 2026-08-18, Mac, ~66 s.

This note answers the punch-through question and records **this-engine** numbers.
drmTMB `cumulative_logit` −7.3 / −5.0 / −0.9 is cited only as drmTMB's. GLLVM
loading-matrix numbers do not transfer (scalar-per-cluster only).

---

## Alignment (symbolic ↔ this engine)

| Symbol | Contract | DGP / route | Recovery | This-engine truth |
|---|---|---|---|---|
| \(\ell_{\mathrm{ML}}(\theta)\) | `method` omitted / `:ML` | Poisson `(1\|g)` GHQ-32; Poisson `phylo(1\|species)` Laplace | `nll` on `DrmFit` | default, unchanged |
| \(\theta = [\beta_\mu(1:p_\mu);\;\log\sigma\ldots]\) | every `_fg` in `sparse_laplace_glmm.jl` | same | `coef(fit)` | \(\beta_\mu\) always leading |
| \(I_{\beta\beta} = \partial^2\mathrm{nll}/\partial\beta_\mu^2\) | FD of analytic \(g_{\beta}\) | `_glsp_reml_penalty(grad_fn, θ, pμ)` | \(0.5\log\det I_{\beta\beta}\) | Cell C rel-diff \(8.29\times10^{-4}\) vs value FD |
| \(\ell_{\mathrm{CR}} = \ell_{\mathrm{ML}} - \tfrac12\log\|I_{\beta\beta}\|\) | nll \(+\) penalty | `_glsp_reml_refit_clean` | \(\hat\sigma_{\mathrm{CR}}=\exp(\theta_{\mathrm{end}})\) | Gaussian reduction: Cell B |
| \(\sigma_b\) scalar-per-cluster | `(1\|g)` / `phylo(1\|species)` | \(b\sim N(0,\sigma_b^2)\) or \(u\sim N(0,\sigma^2 Q^{-1})\) | last θ block | Cell A \(\sigma_b=0.6\); Cell D \(\sigma=0.7\) |

Empty GLLVM-Λ / loading-matrix row on purpose: that estimand is out of lane.

---

## Hook location

**Attach after `_withnll(fit, nll, grad!)`.** Every sparse-Laplace fitter already
stores both closures. \(\theta\) layout is \([\beta_\mu(1:p_\mu);\;\log\sigma\ldots]\).
That is exactly the `(obj, grad_fn, pμ)` contract `_glsp_reml_penalty` /
`_glsp_reml_refit_clean` consume (`src/gaussian_locscale_phylo.jl:91–106, 222–261`).

Canonical returns (this tree):

| Route | File | `_withnll` |
|---|---|---|
| Poisson phylo / relmat / general | `src/sparse_laplace_glmm.jl` | `:555` (`_fit_poisson_general_laplace`) |
| Phylo mean (shared spine) | same | `:1171` (`_fit_phylo_mean_laplace`) |
| Poisson crossed intercepts | same | `:1780` |
| Poisson K-component Laplace | same | `:1956` |

Public `(1 | g)` is **not** this spine: `_fit_poisson_ranef` is GHQ-32
(`src/poisson.jl:98–101`). K=1 crossed Laplace **redirects** to that GHQ path
(`sparse_laplace_glmm.jl:1792–1794`). 1-point Laplace lives on phylo / relmat /
K≥2 crossed only.

Production attach (later implement-G0, not this probe): after ML, if opt-in
restricted, call `_glsp_reml_refit_clean(fit.nll, grad_fn, θ̂, pμ)` then
`_withreml`. Mean-block \(p_\mu\) only on loc-scale \(\theta=[\beta_\mu;\beta_\sigma;\log\sigma]\)
until a separate decision. Do not start AGHQ.

---

## Does `_withreml` punch through?

**Three layers — do not collapse them.**

| Layer | Punches through? | Why |
|---|---|---|
| `_withreml(fit, reml_ll, ml_ll)` (`gaussian_core.jl:180–182`) | **Yes, as a tag** | Family-agnostic metadata: sets `estim_method = :REML`, overwrites `loglik`. Computes nothing. |
| `_glsp_reml_penalty` / `_glsp_reml_refit_clean` | **Yes, as the estimator** | Generic over `(obj, grad_fn, pμ)`. Cell C called them **unmodified** on Poisson phylo Laplace. |
| Public `drm(::Poisson; method = :REML)` | **No** | `_reject_method_as_marginal` (`variational.jl:72–86`) accepts only `nothing` / `:ML`. `:REML` is "unknown … ML-only". |

Implement-G0 is therefore: admit `:REML` on scalar-per-cluster non-Gaussian
routes (narrow the reject), reuse the generic penalty/refit, tag with
`_withreml`. Not a new derivation. Not a q4 / `reml_q4.jl` / `gaussian_ranef.jl` edit.

---

## This-engine measurements (Mac, 2026-08-18)

Reproduce: `julia --project=. bench/cox_reid_probe.jl`.

**Cell B — Gaussian reduction anchor** (generic CR vs #440 Woodbury REML; read-only oracle).
G=12, n_each=5. \(\max|\hat\theta_{\mathrm{CR}}-\hat\theta_{\mathrm{REML}}| = 2.871\times 10^{-6}\).
The penalty is Patterson–Thompson where exact REML is known. Anchored, not ad hoc.

**Cell A — ML finite-cluster VC bias, Poisson `(1|g)`, GHQ-32, true \(\sigma_b=0.6\), 60 seeds.**
Integral error is already paid (32 nodes). Residual \(\hat\sigma\) bias is the ML lever.

| G | n_each | nrep | \(\hat\sigma_{\mathrm{ML}}\) | bias ML | \(\hat\sigma_{\mathrm{CR}}\) | bias CR |
|---|---|---|---|---|---|---|
| 10 | 6 | 58 | 0.5258 | **−12.37%** | 0.5894 | **−1.77%** |
| 20 | 6 | 60 | 0.5561 | **−7.32%** | 0.5903 | **−1.62%** |
| 40 | 6 | 60 | 0.6085 | +1.41% | 0.6263 | **+4.38%** |

Mechanism on *this* engine: ML downward bias shrinks with M; Cox–Reid removes
most of it at small M; **over-corrects at G=40**. That is why ML stays default
and Cox–Reid stays opt-in. 2/60 G=10 seeds hit the non-PD \(I_{\beta\beta}\)
sentinel — production needs that fallback, not an assume.

These are **not** drmTMB's −7.3 / −5.0 / −0.9 (different package, family, cell).

**Cell C — hook viability (Poisson phylo Laplace, one draw, true \(\sigma=0.7\)).**

- `fit.nllgrad !== nothing`
- `_glsp_reml_penalty` = 3.17639042 vs value-surface FD 3.17375941 (rel 8.29e-04)
- `_glsp_reml_refit_clean` converged, 5 LBFGS steps
- nll_ML = 184.936791, nll_CR = 188.075188
- one-seed \(\hat\sigma\): ML 0.95488, CR 0.99187 — **not a recovery claim**

**Cell D — cheap Laplace VC characterization (Poisson phylo, ntip=16, per=4, 12 seeds, true \(\sigma=0.7\)).**

- nrep=12, nfail=0
- \(\hat\sigma_{\mathrm{ML}}=0.7572\) (**+8.18%**), \(\hat\sigma_{\mathrm{CR}}=0.8219\) (**+17.41%**)

This cheap phylo cell does **not** show the drmTMB-style downward Laplace bias.
CR still moved \(\hat\sigma\) up (same direction as Cell A). The design is
underpowered for a Laplace-bias *sign* claim (16 tips, 12 seeds). Do not
headline Cell D as recovery. It is evidence the hook runs on the Laplace
spine, and that a later Laplace ADEMP needs a larger tree / more seeds.

---

## Cost model (implement-G0)

Penalty = \(2p_\mu\) analytic-gradient evals (central FD of \(g_\beta\)).
Clean refit gradient = exact ML grad + \(2\cdot n_{\mathrm{par}}\) penalty evals.
Cell C: \(p_\mu=2\), \(n_{\mathrm{par}}=3\), 5 LBFGS steps — Mac-cheap.
Clamps on \(\log\sigma\in[-8,3]\) and the `1e18` mode-failure sentinel can
poison FD \(I_{\beta\beta}\) near the boundary (Cell A G=10). Keep the finite
sentinel; do not return `Inf`.

---

## Go / no-go

**GO** for a later implement-G0 as a **wiring job**, not a derivation job.

1. First certified cell: Poisson scalar `(1|g)` GHQ — Cell A measured the lever.
2. Laplace phylo / relmat / K≥2 crossed: hook proven (Cell C); do not certify
   bias direction from Cell D.
3. Admit `method = :REML` only on those scalar-per-cluster routes; keep ML default.
4. Reuse `_glsp_reml_penalty` + `_glsp_reml_refit_clean`; tag `_withreml`.
5. Fence: no AGHQ, no q4 / `reml_q4.jl`, no `gaussian_ranef.jl` edit, no
   `runtests.jl`, no TSV, no "has non-Gaussian REML", no GLLVM Λ numbers,
   no GPL, no median-of-mixture, no k=1-as-quadrature.

**NO-GO** this G0: shipping the estimator, starting AGHQ, flipping a capability
chip, closing #136 / #11 / #49 / #439.

---

## Next G0s (order)

1. Implement opt-in Cox–Reid on Poisson `(1|g)` GHQ (narrow `_reject_method_as_marginal`).
2. Same wiring on Poisson phylo Laplace (hook already proven).
3. Other scalar-per-cluster families (Binomial / NB2 / Gamma / Beta) one at a time.
4. AGHQ (lever 2) — **after** Cox–Reid, not instead of it.
