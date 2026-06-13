# After-Task Report: Fast Newton REML for the σ-phylo location-scale route

**Branch:** `shannon/land-sigma-phylo` (worktree `DRM-integrate`). **Local only — not pushed.**

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

- Asymmetric (K=1): **3 Newton steps**, σ-SD 0.5706 vs FD-REML 0.5704 (2e-4), clean flag.
- Separate both-axes (K=2): **3 Newton steps**, μ-SD 0.5849 / σ-SD 0.3637 — both match
  FD-REML to ~5 dp, clean flag.
- End-to-end `drm(method=:REML)` (existing 12/12 anchor test): **still 12/12, and the
  end-to-end fit dropped 77s → 17s (~4.5×)** with identical estimates.
- `test/test_reml_newton_sigma_phylo.jl` (12 assertions across 3 testsets) + the previously
  orphan `test/test_reml_sigma_phylo.jl` are now wired into `runtests.jl`.

## Honest accounting (Rose)

- The "average-information / AI-REML" framing is **dropped** — it was mathematically invalid
  here. The verified method is observed-information Newton; it still delivers the speed goal
  (≈3 steps, O(Kp)/step). Functions/tests/docstrings renamed for honesty.
- The expected-info trace `½ tr(H⁻¹∂P_k H⁻¹∂P_l)` *is* a valid metric (panel-verified, 14
  steps) but needs off-pattern `H⁻¹` via factored solves and is slower; not pursued.
- **Speed-vs-ASReml is not yet measured** — the open-baseline (glmmTMB/lme4) benchmark is the
  next step; only the *step count* (≈3) and the per-step O(p) structure are verified so far.
- Coupled K=3 route and the general boundary behaviour (use the profile/χ̄² CI, not inv(AI),
  near τ→0) remain follow-ups.

Panel transcript: workflow `wf_06f3bd17-848` (result in the session tasks dir).
