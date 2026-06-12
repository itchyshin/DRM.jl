# DRM.jl — Independent Code & Docs Review (companion to FINISH-BOTH-PACKAGES)

**Date:** 2026-06-12
**Type:** read-only, multi-perspective audit (no files changed)
**Scope:** DRM.jl v0.1.0 — architecture, numerics, **R↔Julia parity**, inference, docs, tests/CI
**Relationship to the existing effort:** complements `report/FINISH-BOTH-PACKAGES.md` and the
one on-disk finish-audit dimension (`6-testing-and-verification.md`). The FINISH plan flags
that most dimensions are *reconstructed from primary evidence, not independently audited* —
this pass supplies that independent read for the code/numerics/parity/inference/docs
dimensions. Produced by 6 reviewers via Claude Code. A companion review of the R twin
(`drmTMB`) lives at `drmTMB/docs/dev-log/2026-06-12-drmtmb-full-audit-handoff.md`.

---

## 0. The headline: three *silent* twin divergences

The single most important result for a coordinated launch — two independent reviewers
(parity + numerics) converged on it: **DRM.jl and drmTMB disagree on three model definitions,
and the disagreements are invisible because the parity suite is gated off and compares
pre-transformed numbers.** These are the things that make "the twin gives the same answer" a
claim you can't currently stand behind.

| # | Quantity | DRM.jl | drmTMB (the parity anchor) | Where it hides |
| --- | --- | --- | --- | --- |
| **P1** | residual `rho12` link | `ρ = tanh(ηr)` (`gaussian_bivariate.jl:166,210`) | `ρ = 0.99999999·tanh(η)` (`drmTMB.cpp:335,2755`; `docs/CONTRACT.md:25` pins it and says "drmTMB uses the same") | diff ~1e-9 at moderate ρ, **invisible to the `atol 1e-3` fixture**, grows as \|ρ\|→1 |
| **P2** | NB2 `sigma` | `coef(:sigma)=log θ`, θ=size, `Var=μ+μ²/θ` | `coef(:sigma)=log σ`, size`=1/σ²`, `Var=μ+σ²μ²` ⇒ `coef_jl = −2·coef_R` | the NB2 parity fixture **pre-transforms** the number to make it pass |
| **P3** | Student `nu` link | `ν = exp(η)` (admits ν∈(0,2], infinite variance) | `ν = 2+exp(η)` (ν>2, variance always exists) | Rosetta lists `student()↔Student()` as equivalent, no link note |

**P1 is also a live numerical bug, not just a contract drift:** the same plain-`tanh` path
(`gaussian_bivariate.jl:164-170`) lets a line-search step drive `|ηr|≳19`, so `tanh→±1.0`
exactly → `1-ρ²=0` → `log(0)`/division-by-zero → **NaN gradient/Hessian** through ForwardDiff
on the primary user-facing bivariate route. Fixing P1 with a shared
`_rho_guard(η)=0.99999999*tanh(η)` (in the likelihood **and** in `scales[:rho12]`/`corpairs`)
closes both the parity gap and the NaN at once.

---

## 1. Fix-first (HIGH, across lenses)

| # | Lens | Item |
| --- | --- | --- |
| 1 | parity/numerics | **P1 — residual `rho12` plain `tanh`**: contract violation + NaN-gradient on the main bivariate path. Use the guarded link everywhere (likelihood + reported `rho12`). |
| 2 | parity | **P2 — NB2 `sigma` convention inverted** vs drmTMB; the parity fixture pre-transforms it. Either adopt `size=1/σ²` or document the `coef_jl=−2·coef_R` inversion and transform it in the bridge. |
| 3 | parity | **P3 — Student `nu = exp(η)`** admits infinite variance that drmTMB forbids (`2+exp(η)`). Align or document as non-comparable. |
| 4 | numerics | **`gaussian_structured.jl:73` `cholesky(Symmetric(K))` with `check=true`** on a user relatedness/phylo matrix → raw `PosDefException` instead of a clear diagnostic. Use `check=false` + actionable error. |
| 5 | architecture | **`se` not forwarded** for beta/gamma/binomial crossed-Laplace (`sparse_laplace_glmm.jl:2087-2150`, default `se=false`): `drm(...,(1\|g)+(1\|h),Beta(); se=true)` silently returns an **all-NaN vcov** (Poisson/NB2 forward it correctly). |
| 6 | tests | **4 stdlib deps (`LinearAlgebra`, `Printf`, `Random`, `SparseArrays`) have no `[compat]`** (`Project.toml:20-29`) → **General-registry AutoMerge will reject v0.1.0**. Add `= "1.10"` (or `"1"`). |
| 7 | tests | **Correctness tests not wired into `runtests.jl`** — Takahashi selinv (`test_step1_sparse.jl`) and q4 FD-gradient (`check_sparse_tmb.jl`) among **10 orphan files; 4 are structurally un-wireable** (zero `@test`, `include()` non-existent paths — dead scripts masquerading as coverage). |
| 8 | docs | **`rosetta.md` stale in 3 rows** (`rho12`/`weights`/`summary` are exported & defined but listed "planned/parity gap"), and **`get-started.md:78` ships a broken `phylo(1 \| species, tree)` example** (tree goes via `drm(...; tree=tree)`, not inside the marker). |
| 9 | inference | **`heritability(...; method=:profile)` is mislabeled** — it fixes all nuisances at the MLE (a constrained *slice*, not a profile), so it mis-covers exactly near the boundary the docstring recommends it for; and the **bivariate `pinv(H)` fallback** (`gaussian_bivariate.jl:197`) returns over-narrow Wald CIs where the package elsewhere honestly returns NaN. |

### Reassuring counterweight (verified solid)
- **The engine is numerically trustworthy where it's wired.** Analytic outer gradients pass
  FD-vs-exact gates at ≤1e-6 (phylo Poisson/NB2/Gamma/Binomial, q4 Q-gate) and ≤1e-4 (q2
  location-scale); Takahashi selected-inverse validated against dense inverse to 1e-8;
  ForwardDiff compatibility is handled deliberately (no Dual-breaking mutation in AD paths).
- **Inference is honest.** Wald = true observed information; genuine profile likelihood
  (Venzon–Moolgavkar, full nuisance re-optimization) with structurally ordered endpoints and
  honest `±Inf`; Dunn–Smyth randomized quantile residuals correct per family; AIC/BIC/AICc and
  the **REML LRT guard** (errors on cross-mean-structure REML comparison) are correct;
  parametric bootstrap is sound and seed-reproducible.
- **Docs are coherent**: all 39 Documenter pages exist, every `@docs` symbol resolves, and the
  headline performance numbers are internally consistent across index/README/HANDOVER/NEWS.
- **CI exists and is cost-disciplined** (`.github/workflows/CI.yml`: Julia 1.10 + `1`, Linux,
  PR + dispatch, plus a Documenter build) — dim-6 never credited this.
- Most family parameterizations **do** match drmTMB (Gaussian/LogNormal `sigma=SD`, Gamma
  `sigma=CV`, Tweedie `sigma=√φ` + power `1+logistic(η)`, Beta/BB/ZOI `φ=1/σ²`, identity/log/
  logit mean links) — the divergences are the three specific cases in §0.

---

## 2. Findings by lens

### 2A. Architecture & families
Root cause: **families are empty marker structs with no shared supertype/interface**, so generic
code enumerates concretes instead of dispatching.
- HIGH — `simulate()` is a 70-line `fam isa X` tower (`gaussian_core.jl:1225-1297`); a missing
  branch silently hits `error("not supported")`. Define `abstract type AbstractFamily` + a
  per-family `_simulate(::Poisson,...)` method.
- HIGH — mean-link classification hard-coded **three times** (`gaussian_core.jl:927-994`); add
  `mean_link(::Family)` and implement each link once.
- HIGH — the 1-D (32-node) and 2-D (12×12) Gauss–Hermite random-effect marginals are
  byte-identical across **7 family files** (~600 duplicated lines) except the `logpdf` line.
  Extract `_ghq_ranef(loglik_i, …)` taking a per-obs density closure.
- HIGH — `se` not forwarded for beta/gamma/binomial crossed-Laplace (Fix-first #5).
- MED — no `AbstractFamily` supertype; `Binomial` supports only `(1|g)` and errors on
  `(1+x|g)` while every sibling implements it; core numeric helpers (`_logistic`,
  `_logfactorial`, GHQ nodes) live in arbitrary family files so **include order is load-bearing
  and undocumented** (`DRM.jl:32`); NLL closures allocate a `K`-vector per group per eval under
  Duals (hoist/online-logsumexp).
- MED — **`src/experimental/` (15-16 files, ~190 KB) is shipped but never `include`d** — dead
  code with duplicate `fit_ml_q4.jl`/`location_only.jl` that shadow the promoted copies. Move
  out of the released tree.
- LOW — inconsistent `import Distributions` vs `using Distributions:` across family files;
  auxiliary state (`:ordinal_eta`, `:trials`, `:sigma` whose meaning varies per family)
  smuggled through `fit.scales` with no schema; per-family magic-number η clamps (±30/±20/±15)
  with no shared rationale.

### 2B. Numerics & optimization
(HIGH items: P1 ρ NaN; `K` Cholesky guard.)
- MED — **Takahashi selinv + q4 FD-gradient correctness tests are not in `runtests.jl`** (see
  2F) — the most important sparse-linalg invariants aren't exercised by `Pkg.test()`.
- MED — `sparse_aug_plsm.jl:254-271`: `estep_mode` discards the ridge magnitude; `laplace_ll`
  then computes `logdet(Hobs+λI)` while *labeling* it `logdet(Hobs)` → a silent (bounded) bias
  in the Laplace objective when a mode is accepted at an indefinite-Hessian stall. Return λ and
  reject/flag when `λ>0`.
- MED — log-Cholesky diagonals `exp(v[1])`/`exp(v[3])` unclamped (`locscale_inner.jl:27`,
  `fit_ml_q4.jl:13`) → `Inf` Λ on optimizer excursions; `fit_ml_q4.jl`/`locscale_fit.jl`
  **discard inner-mode convergence flags** so a failed inner solve feeds a bad point (and
  `g!` returns a literal zero gradient → false convergence). `gaussian_meta.jl` doesn't
  validate `vv[i] ≥ 0` (negative/zero sampling variance → silent `NaN`/`-Inf`).
- LOW — beta/gamma response-domain not validated (`y∈{0,1}`/`y=0` → silent `-Inf`);
  `location_only.jl:131,133` one-shot jitter uses `cholesky` without `check=false` (can throw);
  a couple of `logdet(chP)` paths lack the `issuccess` guard the q2 path has.
- **Verified-good:** convergence is surfaced into `DrmFit.converged` at all 69 `Optim` sites;
  `sparse_phy.jl` validates branch lengths/binarity; η clamped to [-30,30] in GLMM kernels.

### 2C. Inference & statistics
(HIGH items in Fix-first #9.)
- LOW — main Gaussian `inv(Hessian)` (`gaussian_core.jl:467`) has no `try/catch`, so an exactly
  singular Hessian **errors the whole fit** instead of returning NaN SEs like the locscale path.
- LOW — `heritability` `:profile` returns `bias=0.0` (implies unbiased when no bias assessment
  was done); `dof = length(theta)` is the naive parameter count (no boundary/effective-df
  adjustment — same choice as drmTMB, so parity not regression, but worth a caveat);
  README/NEWS "valid CIs where drmTMB's Hessian is singular" should read "valid Wald SEs on the
  identified directions" (the `pinv` path can hand a finite SE to the singular direction).
- **Verified-sound:** observed-information Wald, genuine profile likelihood, Dunn–Smyth
  residuals (per-family parameter maps checked), AIC/BIC/AICc/LRT, the REML guard, second-order
  bias-correction (Thorson–Kristensen), and the parametric bootstrap.

### 2D. Docs & web pages
(HIGH items in Fix-first #8.)
- MED — `weights(fit)` exists but returns `ones(nobs)` — a stub; label it "placeholder", not
  "planned". `rosetta.md:53/:23` vs `NEWS.md:30` **contradict each other** on whether drmTMB
  has a standalone `binomial()`. `ROADMAP.md:99-102` lists "R-bridge functional" as a shipped
  v0.1.0 deliverable while everywhere else marks the bridge Experimental/Not-yet-wired.
- LOW — `index.md` "Thirteen families" enumerates 12; "Stable" status badge on a v0.1.0 page
  whose own README warns of 0.x breaking changes; the O(p)-to-p=10,000 and at-scale-vs-drmTMB
  numbers are presented without the "extrapolated / synthetic model" caveat that
  `comparison-grid.md`/`HANDOVER.md` carry; bridge described as "planned" in `index.md` but
  "experimental (exists)" elsewhere — pick one word; `make.jl` `warnonly=true` may now be
  tightenable (all pages/`@docs` resolve).
- **Verified-good:** Documenter nav complete; examples (except the phylo one) runnable;
  terminology matches the twin (`sigma` not `tau`, `rho12` = residual correlation).

### 2E. (folded into §0/§1 — parity)

### 2F. Tests, reproducibility, CI — *building on dim-6*
Dim-6 already covers: macOS profile stall (A1/A2), parity gated-off + Gaussian-only floor
(B1-3), `{family}×{structure}×{axis}` sweep being one slice (C1), χ̄² boundary-LRT unbuilt
(C2/C3), the σ-phylo core + regression test gap (D1), orphan engine tests (E1), `experimental/`
untested (E2), Aqua/JET/perf-gate absence (F1/F2). **This review adds:**
- HIGH — **stdlib `[compat]` gap blocks registration** (Fix-first #6); Aqua would have caught it
  automatically.
- HIGH — **orphan count is 10, not 6**, and **4 are structurally un-wireable** (zero `@test`,
  `include()` non-existent PoC paths, fixtures at `../../fixtures` that don't exist). Delete or
  rewrite as real `@testset`s; `check_sparse_tmb.jl` is redundant with the wired q4 gate.
- MED — **CI exists and is sane** (correcting dim-6's silence) — but parity is skipped
  (`DRM_PARITY_TESTS` unset) and the matrix is Linux-only; add a parity job (fixtures are
  pre-generated TOML, no R needed at run time) and macOS/Windows before tagging.
- MED — committed `meta-analysis-V` / `robust-student` parity fixtures are **silently
  unreachable** (`runparity.jl` `@test_skip`s what it can't reconstruct, and `meta_V` is never
  wired into the fit) → a fixture can contribute zero verification undetected. Make it error,
  not skip.
- MED — reproducibility rests on `Random.seed!` (not `StableRNGs`) under a two-Julia-version CI
  matrix → latent flake on tight-tolerance recovery tests; FD-vs-analytic gates exist **only**
  for the μ-axis on phylo/crossed — spatial, relmat/animal, every σ-axis structured route, and
  random-slope paths have analytic gradients with **no standing FD gate**.
- LOW — bench headline numbers (`logLik −256.51`, `2.18×`, O(p)) have **zero `@test`** guarding
  them; add one cheap regression assert. `Manifest.toml` is correctly git-ignored (library
  convention) — **not** a finding, noted to pre-empt a wrong "fix".

---

## 3. Cross-cutting themes
1. **The twin parity layer is thinner than it looks** (§0). Three model-level divergences
   survive because the parity suite is gated off, single-family, and compares pre-transformed
   numbers. This is the #1 launch risk and it spans both repos.
2. **No shared abstraction.** Families (no supertype), links (3× hard-coded), GHQ marginals
   (×7), guard constants, and include order are all duplicated/implicit — extending one family
   means editing many files. An `AbstractFamily` + link objects + a shared GHQ helper dissolves
   a large fraction of 2A/2B.
3. **Honest-where-wired, silent-where-not.** The engine refuses to over-report CIs on its
   audited paths, but several *un-audited* paths (bivariate `pinv`, beta/gamma `se`,
   indefinite-Hessian ridge, un-wired correctness tests) silently degrade. Wire the tests and
   propagate the honesty to those paths.
4. **Registry/release hygiene** is a few concrete, cheap blockers: stdlib `[compat]`, orphan
   tests, Aqua, `experimental/` shipping.

## 4. Suggested triage for the twin launch
1. **P1–P3 parity** (§0) — the launch-blocking model divergences; fix or explicitly document
   as non-comparable, then make the parity suite default-on and assert the conventions directly.
2. **Registration blockers** — stdlib `[compat]`, delete/rewrite the 4 dead test scripts, add
   Aqua.
3. **The HIGH numerical/API guards** — `K` Cholesky, beta/gamma `se` forwarding, wire Takahashi
   + q4 FD-gradient tests.
4. **Doc accuracy** — the 3 stale `rosetta` rows, the broken phylo example, the
   bridge/"Stable"/family-count overclaims.
5. **The shared-abstraction refactor** (theme 2) — highest maintainability leverage, post-launch
   if needed.

*Read-only audit — no DRM.jl code, docs, or config were changed. Severities are reviewer
judgments against v0.1.0 HEAD; the parity items (§0) are the ones to confirm against drmTMB
before acting.*
