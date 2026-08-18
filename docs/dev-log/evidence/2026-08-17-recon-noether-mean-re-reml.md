# Noether recon — ordinary Gaussian mean-RE REML (locked G0)

**Date:** 2026-08-17
**Role:** Noether (read-only). No `src/` edits. No implementation.
**G0:** opt-in `method = :REML` for Gaussian mean `(1 | g)` only; ML stays default;
replace the `gaussian_core.jl` guard with a real path on the Woodbury spine in
`gaussian_ranef.jl`. Fence: no σ-RE, no slopes, no non-Gaussian REML, no q4 touch.
Do not regress logLik −256.51 / 2.18×.

Named perspectives: Noether (this note). No spawned subagents.

---

## 1. Current guard (exact `ArgumentError` text + call sites)

**Univariate Gaussian router** — `src/gaussian_core.jl:413-423`. After the
σ-phylo early-return (which already threads `reml = method === :REML` at
`gaussian_core.jl:364-369` into `_fit_gaussian_locscale_phylo`), any remaining
`method === :REML` with a random / structured / meta term throws:

```
drm: method = :REML is currently implemented only for the fixed-effect Gaussian location–scale model (no random effects, no structured / phylo / meta terms). Use method = :ML (the default) for those models.
```

Predicate (`gaussian_core.jl:419-420`):

```
(isempty(re) && isempty(sigma_re) && structured === nothing && metav === nothing &&
 length(_collect_structured(rhs[:mu])) == 0)
```

`method` itself is validated first at `gaussian_core.jl:301-302`
(`:ML` / `:REML` only). Default is `:ML` (`gaussian_core.jl:298`).

**Call sites that never receive `method` today** (ML-only; the guard fires
before they run when `method === :REML`):

| Route | Call | File:line |
|---|---|---|
| mean `(1 \| g)` / `(0 + x \| g)` | `_fit_ranef_gaussian(...)` — **no `method`/`reml` kwarg** | `gaussian_core.jl:547` → `gaussian_ranef.jl:94` |
| correlated `(1 + x \| g)` | `_fit_correlated_ranef_gaussian` | `gaussian_core.jl:539` |
| crossed `(1\|g)+(1\|h)` | `_fit_multi_ranef_gaussian` | `gaussian_core.jl:554` |
| σ-RE `(1 \| g)` on `sigma` | `_fit_sigma_ranef_gaussian` (GHQ; not Woodbury) | `gaussian_core.jl:454` |

**FE REML already lives past the guard** when `re` is empty:
`gaussian_core.jl:529-530` → `_fit_fixed_gaussian_reml`.

**Existing test that encodes the rejection** — `test/test_reml.jl:121-128`:

```julia
@test_throws ArgumentError drm(bf(@formula(y ~ 1 + (1 | g)), @formula(sigma ~ 1)),
                               Gaussian(); data = d2, method = :REML)
```

**Capability-status row** — `docs/design/capability-status.md:102` is
`rejected`. The prose at `:124-129` cites `src/gaussian_core.jl:407`; the
throw is at **413-423** (line-number drift; text of the `ArgumentError` matches).

**Other REML guards (do not loosen):**

- Bivariate residual / q=2: `gaussian_bivariate.jl:167-184` (q=4 only).
- Coupled mean–σ phylo: `gaussian_core.jl:379-380`, `gaussian_locscale_phylo.jl:801-802`.
- Non-Gaussian: `test/test_bivariate_lognormal.jl:68`, `test/test_bivariate_student.jl:69`.

---

## 2. Woodbury ML spine (functions, inputs, what REML would change)

File header (`gaussian_ranef.jl:1-7`): for a mean random effect the marginal is
exactly Gaussian

```
y ~ N(Xβ, V),  V = D + σ_b² Z Zᵀ,  D = diag(σ_i²)
```

Never form `V`. Matrix-determinant lemma + Woodbury → O(n) accumulations plus a
diagonal G×G capacitance.

**Function:** `_fit_ranef_gaussian(fam, y, Xμ, Xσ, gidx, G, w, nmμ, nmσ, grp, g_tol)`
(`gaussian_ranef.jl:92-158`).

**θ layout** (`:93`): `[β_μ; β_σ (log σ); log σ_b]`.

**ML objective** (`:98-125`) — cited, not re-derived:

- `S[k] = Σ w_i² / D_i`, `C[k] = Σ w_i r_i / D_i`, `q1 = rᵀ D⁻¹ r`, `logdetD = Σ 2 ησ_i`
- `M_k = 1/σ_b² + S[k]` (Woodbury capacitance, diagonal)
- `q2 = Σ C[k]² / M_k`, `logdetCap = Σ log(1 + σ_b² S[k])`
- `nll = 0.5 * (logdetV + quad) + 0.5 * n * log(2π)` with `quad = q1 - q2`,
  `logdetV = logdetD + logdetCap`

Optimiser: LBFGS + ForwardDiff on that `nll` (`:134`). vcov = inverse Hessian of
**ML** `nll` (`:136`). BLUPs `b̂_k = C_k / M_k` at `θ̂` (`:143-155`). Packaging:
`_withnll` + `_withranef`; **no `_withreml`**. `estim_method` stays `:ML`.

**`w`:** `_re_kind` (`:64-80`) — `(1 | g)` → `w_i = 1`; `(0 + x | g)` → `w_i = x_i`.
Same fitter serves intercepts **and** independent slopes. G0 fence: intercept
only (`w ≡ 1`). Do not open the slope branch.

**What REML would change on this spine (from in-tree analogues, not new math):**

1. Restricted objective = ML `nll` plus the Patterson–Thompson / Harville
   determinant already written for FE REML
   (`gaussian_core.jl:777-782`, `832`) and for the stale all-routes helper
   (`shannon/reml-gaussian` `_reml_penalty` comment, commit `c38bdc47`):

   `ℓ_REML(θ) = ℓ_ML(θ) − ½ logdet(Xμᵀ V(θ)⁻¹ Xμ) + (pμ/2) log 2π`

   i.e. add `+ ½ logdet(Xμᵀ V⁻¹ Xμ) − (pμ/2) log 2π` to `nll`.

2. `Xμᵀ V⁻¹ Xμ` is the same Woodbury identity the quadratic already uses on
   residuals (`gaussian_ranef.jl:103-122`), applied to the columns of `Xμ`
   instead of `r`. Equivalent (conjugate-Gaussian identity, already stated on
   `c38bdc47`) to `∂² nll_ML / ∂β_μ²`. Prefer forming it on the existing
   `S`/`M` accumulators rather than a generic Hessian wrapper.

3. Optimise the **restricted** objective (variance comps + optionally profile
   `β_μ` as GLS at each trial, matching `_fit_fixed_gaussian_reml`'s
   `profile_bmu`). At the REML variance, `β̂_μ` is the GLS estimate ML would
   give at those variances (FE comment `gaussian_core.jl:793-794`).

4. Package with `_withreml(fit, reml_ll, ml_ll)` (`gaussian_core.jl:166-171`)
   so `loglik` = restricted, `ml_loglik` = ML at `θ̂_reml`,
   `estim_method = :REML`. vcov from the **restricted** Hessian (σ-phylo
   contract `gaussian_locscale_phylo.jl:108-110`), not the ML Hessian at the
   REML point.

5. Router: thread `reml` into `_fit_ranef_gaussian` only when
   `length(re)==1 && kind===:intercept && isempty(sigma_re) && structured===nothing`.
   Narrow the `413-423` guard; do **not** delete it.

**ML tests already on this spine:** `test/test_gaussian_ranef.jl:8-26`
(recovery of `β`, residual `σ`, `re_sd(fit)[:g]`; default `method=:ML`).
Slope recovery `:28-48` is out of G0 — leave as ML-only.

---

## 3. Existing REML analogues — reuse vs do not copy

| Analogue | Where | What it is | Reuse | Do not copy |
|---|---|---|---|---|
| **FE loc-scale REML** | `_fit_fixed_gaussian_reml` `gaussian_core.jl:770-886`; tests `test/test_reml.jl` | Exact PT for `V = D` (no RE): profile `β_μ` by WLS, `nll_reml = s + const + ½ logdet(Xμ'W Xμ) − ½ pμ log 2π` (`:825-832`). `_withreml`. Defining test: `σ²_REML / σ²_ML ≈ n/(n−pμ)` (`test_reml.jl:32-44`). | Formula, `_withreml` metadata, model-selection guard (`comparison.jl:126-140`, `gaussian_core.jl:1576-1586`), “ML default / REML opt-in”. | Do not route `(1\|g)` through this fitter. `W = diag(σ_i⁻²)` is **not** `V⁻¹` once `σ_b² ZZᵀ` is present. |
| **σ-phylo REML** | `_glsp_reml_penalty` / `_glsp_reml_refit_clean` `gaussian_locscale_phylo.jl:85-275`; tests `test/test_reml_sigma_phylo.jl` | Laplace-marginal + `0.5·logdet(S)`, `S = FD of analytic β_μ-gradient` (`:85-105`). Production restricts `β_μ` **and** `β_ψ` (`test_reml_sigma_phylo.jl:2-5`). | Same `method=:REML` threading pattern (`gaussian_core.jl:364-394`); finite 1e18 barrier when `S` not PD (`:100-104`). | Do **not** copy FD-of-gradient / Newton–LBFGS polish. Mean `(1\|g)` is **exact** Gaussian; no Laplace, no tree `Q`. Do not touch this file. |
| **q4 REML** | `src/reml_q4.jl` (do not edit). Header `:12-16`: `L_REML(φ) = L_ML(φ, β̂) − ½ logdet(X̃' H_uu⁻¹ X̃)`. Bordered augmented state; profiles μ **and** σ FE. Wired `DRM.jl:52-55`. Tests `test/test_reml_q4_allaxes.jl`. | Documents the Schur form of PT on the sparse engine. | **Do not copy** bordered `H_uu`, `cond_newton_beta`, or all-axes restriction. **Do not edit** `reml_q4.jl` or any q4 engine file. Ordinary `(1\|g)` is not q4. |
| **Stale generic helper** | `c38bdc47` on `shannon/reml-gaussian`: `_reml_penalty` / `_reml_optimize` — `Hββ = ForwardDiff.hessian(βμ → nll_ml(vcat(βμ, rest)))`, then `+½ logdet(Hββ) − ½ pμ log 2π`. | Math comment is the conjugate-Gaussian identity. | **Do not resume** the branch (see §8). Do not apply that helper to σ-RE (GHQ, not conjugate) or slopes. |

`report/reml-wiring-design.md` is historical (#11): Slice 2 = FE only; ordinary
RE was explicitly out of scope (`:789-792` in `gaussian_core.jl` still says so).

---

## 4. Math contract (one paragraph)

For Gaussian mean `(1 | g)` the ML spine already evaluates the exact marginal
`y ~ N(Xμ β_μ, V)` with `V = D + σ_b² ZZᵀ` by Woodbury / det-lemma
(`gaussian_ranef.jl:3-7, 98-125`). Patterson–Thompson / Harville restricted
likelihood on that same `V` is the in-tree FE formula
(`gaussian_core.jl:777-782`) with `W` replaced by `V⁻¹`:
`ℓ_REML = ℓ_ML(β̂_μ(V), θ_var) − ½ logdet(Xμᵀ V⁻¹ Xμ) + (pμ/2) log 2π`,
where `β̂_μ` is GLS at the current `V`. Equivalently (identity stated on
`c38bdc47` and used by σ-phylo as `S = ∂² nll_marginal / ∂β_μ²` at
`gaussian_locscale_phylo.jl:86-90`), `Xμᵀ V⁻¹ Xμ` is the `β_μ` Hessian of the
existing ML `nll`. Form it with the same capacitance `M_k = 1/σ_b² + S[k]`
already in the quadratic; do not introduce a new estimator class, Laplace, or
q4 Schur-on-`H_uu`. ML remains the default; REML is opt-in; REML log-likelihoods
are not comparable across mean structures (`comparison.jl:126-138`).

Uncertainty: this note does **not** invent a new closed form. It only identifies
the FE / shannon / σ-phylo statements already in the repo with the Woodbury `V`
this fitter already uses.

---

## 5. Files that MUST change vs MUST NOT touch

**MUST change (G0 src + test):**

- `src/gaussian_core.jl` — narrow `:413-423` so a single mean `(1 | g)` is
  admitted; thread `reml` into the `:543-547` call. Keep the throw for σ-RE,
  slopes, correlated, crossed, structured, meta.
- `src/gaussian_ranef.jl` — `_fit_ranef_gaussian` only: restricted objective,
  `_withreml`, restricted vcov. Do not change `_fit_sigma_ranef_gaussian`,
  `_fit_correlated_ranef_gaussian`, or `_fit_multi_ranef_gaussian`.
- `test/test_reml.jl:121-128` — **must** invert or split: that `@test_throws`
  is already in `test/runtests.jl:39`. Leaving it as-is will fail the moment
  the guard is lifted.
- New `test/test_reml_ordinary_ranef.jl` (recommended G0: standalone file;
  default-suite include can wait — but `test_reml.jl` still has to move).

**SHOULD change (docs / card, not src+test effort):**
`docs/design/capability-status.md:102` `rejected` → `implemented` after the
test exists; fix the L407 citation.

**MUST NOT touch:**

- `src/reml_q4.jl`, `src/fit_q4_sparse_tmb.jl`, `src/sparse_aug_plsm.jl`,
  `src/sparse_em_fit.jl`, `src/fit_ml_q4.jl`, `src/fisherz_q4.jl`
- `src/gaussian_locscale_phylo.jl` (σ-phylo REML already wired)
- `_fit_fixed_gaussian_reml` / FE path (`gaussian_core.jl:529-532, 770-886`)
- `src/gaussian_bivariate.jl` q4 REML branches
- `src/location_only.jl` (loc-only phylo REML / AI-REML fence)
- `_fit_sigma_ranef_gaussian` (σ-RE fence)
- slope / correlated / multi-RE fitters
- `test/test_reml_q4_allaxes.jl`, `test/test_reml_sigma_phylo.jl`,
  `test/test_reml_newton_sigma_phylo.jl` except as regression runs
- `test/runtests.jl` include list if following the 2026-08-17 recommended G0
  (do not wait-gate on that for `test_reml.jl` itself — it is already included)

---

## 6. Regression fences

| Fence | How it is held | Evidence |
|---|---|---|
| **FE REML** | Do not edit `_fit_fixed_gaussian_reml`. Keep `test/test_reml.jl` ML-default / `σ²_REML > σ²_ML` / FD-grad / lrtest guard sets. | `test_reml.jl:22-119` |
| **σ-phylo REML** | Do not edit `gaussian_locscale_phylo.jl`. Re-run `test/test_reml_sigma_phylo.jl` + `test_reml_newton_sigma_phylo.jl`. | already on `runtests.jl:276-277` |
| **q4 −256.51 / 2.18×** | Do not include or edit `reml_q4.jl` or the sparse q4 engine. ML default on `fit_q4_sparse_tmb` unchanged. | `reml_q4.jl:41`; `report/comparison-grid.md`; `test_reml_q4_allaxes.jl` |
| **ML `(1 \| g)`** | Default `drm(...)` without `method` must stay byte-comparable to `method=:ML` (same pattern as `test_reml.jl:22-29`). | `test_gaussian_ranef.jl:8-26` |
| **Slopes / σ-RE / non-Gaussian** | Guard still throws (or never reaches a REML path). | invert only the mean-intercept cell in `test_reml.jl:121-128`; add explicit throws for `(0+x\|g)` and `sigma ~ (1\|g)` |

---

## 7. Recommended first failing test

**Invert the existing rejection** in `test/test_reml.jl:121-128` (or move that
block into a new file and leave a residual-reject set behind). Small balanced
Gaussian mean `(1 | g)`, `sigma ~ 1`, `method = :REML`:

1. **Today (red after you write the assertion you want):**
   `estimation_method(fit) === :REML` and `isfinite(reml_loglik(fit))` —
   currently throws the §1 `ArgumentError`.
2. **Defining property (once the path exists):**
   `re_sd(freml)[:g] ≥ re_sd(fml)[:g]` and residual `σ_REML ≥ σ_ML`
   (same “less downward-biased variance” as `test_reml.jl:32-40` /
   `test_reml_q4_allaxes.jl`). Do **not** claim the exact `n/(n−pμ)` ratio —
   that identity is FE-homoscedastic only (`test_reml.jl:42-44`).
3. **Metadata:** `loglik == reml_loglik`, `ml_loglik` finite,
   default/`method=:ML` unchanged vs current `test_gaussian_ranef.jl`.
4. **Fence tests in the same file:** `@test_throws ArgumentError` for
   `method=:REML` + `(0 + x | g)`, + `sigma ~ (1 | g)`, + a non-Gaussian family.

TDD: change the assertion first; implement until it passes. Optional later:
lme4 numeric oracle (`3611ff8f` / `test/test_reml_parity.jl` lives on
`shannon/RELEASE-drm`, **not** on `main` — do not treat as in-tree).

---

## 8. Verdict: **build-the-gap** (do not resume a branch)

| Branch | What it actually is | Resume? |
|---|---|---|
| **`shannon/reml-gaussian`** (`c38bdc47`, 2026-06-11) | **Did** implement ordinary mean-RE REML (and slopes, crossed, σ-RE, structured, bivariate, `meta_V`) via generic `_reml_optimize` on each ML `nll`. **Not in `main`** (`c38bdc47` is not an ancestor). Stale vs current `DrmFit.marginal`, σ-phylo REML, q4 all-axes, multi-RE clamp/vcov hardening. Scope **violates** the G0 fence (σ-RE + slopes). | **No.** Cherry-pick the *identity* (`Hββ = XᵀV⁻¹X`), not the branch. |
| **`claude/wire-reml-11`** | FE loc-scale REML only (`_fit_fixed_gaussian_reml` + `test_reml.jl`). Already on `main` as #11. | **No** — already landed; this G0 is the hole it left. |
| **`feat/291-reml-*`** (arc1 / arc3 / baseline-ladder / sparse-first) | q4 REML **acceleration / fixtures / docs**. No ordinary `(1 \| g)` path. | **No.** q4 fence. |
| **`origin/claude/wire-reml-11`** | same as `claude/wire-reml-11` (FE). | **No.** |

**Verdict: build-the-gap** from `origin/main`. New issue (not `closes #11`,
not `closes #136`, not `closes #291`). Narrow guard + Woodbury PT on
`_fit_ranef_gaussian` only.

---

## 9. Effort guess (src + test only)

**~90 minutes** for a failing-test-first slice: invert `test_reml.jl:121-128`,
narrow the guard, add `+½ logdet(XμᵀV⁻¹Xμ)` on the existing `S`/`M` loop,
`_withreml`, plus fence throws for slopes/σ-RE.

- Lower (~45–60 min) if the implementer copies the `c38bdc47` `_reml_penalty`
  pattern **only** onto `_fit_ranef_gaussian` (Hessian-of-ML-nll ≡ `XᵀV⁻¹X`
  here) and does not form `XᵀV⁻¹X` by hand.
- Higher (~2–3 h) if they also chase lme4 numeric parity or restricted-vcov
  FD gates in the first PR — out of G0; defer.

Does **not** include Documenter, `runtests.jl` include politics, or a
capability-status card flip.
