# After-Task Report: Fast Newton REML for the σ-phylo location-scale route

**Branch:** `shannon/land-sigma-phylo` (worktree `DRM-integrate`). **Local only — not pushed.**

## ⚠ CORRECTION (post adversarial verification, 2026-06-12)

An adversarial verification workflow (26 agents) found **12 confirmed bugs** in the
observed-information Newton slice below — including a **BLOCKING crash** and a **HIGH
correctness bug** my own benign-fixture tests missed:

- **Crash:** `drm(method=:REML)` crashed near the variance boundary (homoscedastic data,
  σ-phylo SD→0) with an unguarded LineSearches `AssertionError` (~5–8% of seeds; reproduced
  on seeds 7, 39).
- **β-coupling bias:** the Newton's block-coordinate `refit_β!` minimised only the ML
  objective over β, omitting the penalty's β-dependence → a non-stationary, biased σ-SD
  flagged converged (negligible for intercept models, ~3% at pμ=6/pψ=2).
- Plus boundary garbage-SE, a convergence-flag regression, and several doc overclaims.

**Resolution:** the production `drm(method=:REML)` path is now the **jointly-correct,
boundary-robust clean-gradient LBFGS** (`_glsp_reml_refit_clean`: finite penalty + guarded
line search + substance-based flag). The observed-information **Newton is demoted to
EXPERIMENTAL** (kept + characterised, not wired). Added the Wald-V PD guard, the coupled-route
REML error guard, and a boundary regression test (4 seeds, was-crashing 7/39). The
crash-free + correctness fixes are verified; the speed comparison below was the Newton's and
is now an experimental note, **not** the production claim.

## Scope

Replace the slow, substance-judged FD-REML refit on the Gaussian σ-phylo location-scale
route with a fast, clean-flag Newton REML, and extend it from the asymmetric (σ-only, K=1)
case to the separate both-axes block (K=2). The goal was the handover's "beat ASReml" speed
milestone — a few-step REML with O(p)-per-step cost on the Julia side.

## The headline finding (a genuine negative result)

The literal **average-information (AI) data-quadratic is INVALID as the Newton metric for
this augmented-state Laplace model.** An adversarial derivation panel (5 agents; 4
independent derivation lenses unanimously *endorsed* the candidate, the reconciler refuted
it with Monte-Carlo numbers) established:

- Candidate `AI = ½ (∂P_k â)ᵀ H⁻¹ (∂P_l â)`. The Gilmour–Thompson–Cullis identity
  `E[(∂P â)ᵀH⁻¹(∂P â)] = tr(H⁻¹∂P H⁻¹∂P)` holds only **in expectation** over `â ~ N(0,H⁻¹)`.
- But the realised inner mode `â` is the **shrunk BLUP** — its covariance is *not* `H⁻¹` — so
  the single realised quadratic is a high-variance, ~5×-too-small sample of the trace.
- Measured at the test optimum: candidate **10.0** vs observed Hessian **22.2** vs
  expected-info trace **51.8**; MC `E[½(∂P a)ᵀH⁻¹(∂P a)]` over `a~N(0,H⁻¹)` = **51.7** (≈
  trace, confirming the identity holds only in expectation). The undersized metric →
  oversized Newton steps → 20-iteration divergence (18% off).

This breaks the "O(p) AI data-quadratic trick replaces the O(p²) trace" premise *for this
model* — it works in the textbook LMM because `Py` is the full projected residual with
covariance `V`, but the augmented `â` is shrunk.

## The fix (verified)

Use the **observed information**: a central FD of the *exact O(p)* marginal + penalty REML
score (analytic gradient + Takahashi + one clean penalty FD). O(Kp) per Newton step. The
score itself (incl. the `t_adj` implicit-mode term and the prior `trLP`) was already correct
and shipped in `locscale_grad.jl`; only the curvature object was wrong.

- `_glsp_reml_newton(obj, grad, θ̂_ml, pμ, vidx; …)` — route-agnostic, K variance components,
  block-coordinate (conditional fixed-effect re-fit + PD-projected K×K Newton step).
- `_glsp_reml_newton_asym` retained as the K=1 wrapper.
- Wired into `drm(method=:REML)` for both the asymmetric and separate routes, with the
  clean-gradient LBFGS refit (`_glsp_reml_refit_clean`, renamed from the misleading
  `_glsp_aireml_refit`) as a robustness fallback.

## Verification (anchor: FD-REML)

- Asymmetric (K=1): **3 steps on seed 808** (fixture-specific — see Robustness; not a bound),
  σ-SD 0.5706 vs FD-REML 0.5704 (2e-4), clean flag.
- Separate both-axes (K=2): **3 steps on seed 909**, μ-SD 0.5849 / σ-SD 0.3637 — both match
  FD-REML to ~5 dp, clean flag.
- End-to-end `drm(method=:REML)` (existing 12/12 anchor test): **still 12/12, and the
  end-to-end fit dropped 77s → 17s (~4.5×)** with identical estimates.
- `test/test_reml_newton_sigma_phylo.jl` (12 assertions across 3 testsets) + the previously
  orphan `test/test_reml_sigma_phylo.jl` are now wired into `runtests.jl`.

### Robustness (benchmark-driven — the safeguarded step)

A scaling benchmark (`bench/bench_reml_newton.jl`) exposed that the FIRST cut of the Newton
was **not robust**: the unguarded step **diverged at p≥120** (σ-SD ran away to ≈7, conv=false)
and the step count was **fixture-dependent** (3 at p=60 but 11 at p=24) — so the headline
"3 steps" was fixture-luck, not a property. Two fixes:

1. **Backtracking line search** — accept the Newton step only if the restricted objective
   `nll_ML + ½logdet S` *decreases*; otherwise halve. Monotone descent ⇒ the iterate cannot
   diverge even when the FD curvature is unreliable at large p.
2. **Scale-free convergence** — judge convergence on the **step size in the log-SD chart**
   (O(1)), not the raw score (which scales with n, making the absolute tol unreachable at
   large p). This mirrors the engine's "mean-objective, scale-invariant across p" discipline.

After the fix (`bench/check_newton_robust.jl`): p = 60 / 120 / 250 all converge (1–4 steps)
to sane estimates (μ-SD ≈0.6, σ-SD ≈0.37–0.45, no runaway); small-p still matches FD-REML to
~5 dp. The `drm()` fallback to the clean-gradient LBFGS remains for any residual
non-convergence (so production is correct regardless).

**Large-p correctness, measured** (`bench/check_p120_match.jl`): at p=120 the safeguarded
Newton matches FD-REML to **<1%** (σ-SD 0.3684 vs 0.3671, μ-SD 0.5677 vs 0.5731), conv=true in
1 step, **16.5× faster (14.7s vs 242s)**. The internal speedup vs the old FD-REML refit *grows
with p* (4.5× at p=24 → 16.5× at p=120) — the FD-REML LBFGS crawl scales badly while the Newton
stays at 1–4 steps. (This is vs DRM.jl's own FD-REML; the cross-engine ASReml/glmmTMB number is
still pending — no native R baseline for σ-phylo location-scale.)

## Honest accounting (Rose)

- The "average-information / AI-REML" framing is **dropped** — it was mathematically invalid
  here. The verified method is observed-information Newton; it delivers the speed goal
  (**≈1–4 steps** depending on p, O(Kp)/step) — but only after the safeguarded-step fix; the
  first cut diverged at scale (see Robustness above). Functions/tests/docstrings renamed for
  honesty.
- The expected-info trace `½ tr(H⁻¹∂P_k H⁻¹∂P_l)` *is* a valid metric (panel-verified, 14
  steps) but needs off-pattern `H⁻¹` via factored solves and is slower; not pursued.
- **Speed-vs-ASReml is not yet measured** — the open-baseline (glmmTMB/lme4) benchmark is the
  next step; only the *step count* (≈3) and the per-step O(p) structure are verified so far.
- Coupled K=3 route and the general boundary behaviour (use the profile/χ̄² CI, not inv(AI),
  near τ→0) remain follow-ups.

Panel transcript: workflow `wf_06f3bd17-848` (result in the session tasks dir).
