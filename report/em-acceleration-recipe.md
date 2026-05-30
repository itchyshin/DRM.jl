# Fast EM for q=4 location-scale PLSM — the "never-combined" recipe

From the deep-scout (PX-EM, conjugate-split, Fisher-scoring, natural-gradient,
SQUAREM). Goal: turn the EM's linear convergence (300+ iters) into ~5–8 iters,
monotone + PD-by-construction. Honest ceiling: ~5–8× over TMB's nlminb on a
SINGLE fit (not 100× — both are O(p); the 100× lives in the threaded pipeline).

## Hybrid-Block-Accelerated EM (the synthesis)

Exploit the structure NOBODY exploits: μ random effects are CONJUGATE-Gaussian
(closed-form), only log-σ effects are non-conjugate. Split the 4×4 Λ:
  Λ = [Λ_μμ  Λ_μσ ; Λ_σμ  Λ_σσ]

Per iteration:
1. **E-step** (Laplace): mode û + posterior cov via sparse Newton + `takahashi_selinv` (O(p)). [have this]
2. **M-step, Λ_μμ (conjugate)**: closed-form Gaussian update `(1/N)·E[u_μ u_μ' | y]` — exact, fast, O(p). [like GLLVM.jl's exact phylo EM]
3. **M-step, Λ_σσ (non-conjugate)**: ONE **Fisher-scoring** step (expected information, sparse O(p) with Q) — 2–4 iters to converge, more stable than observed-Newton; line-search/EM fallback for monotonicity.
4. **M-step, Λ_μσ (off-diag, 6 params)**: small dense Newton (O(1)).
5. **PX-EM** rescaling (φ): the single biggest accelerator (5–50×), monotone.
6. **SQUAREM** 3-point extrapolation wrapper (3–5× on top), monotone.
7. **PD preservation**: log-Cholesky or natural-gradient parametrization → PD by construction (no projection).

Per-iter O(pn); expected ~5–8 iters; monotone; PD-safe.

## Implementation order (Tier 1 first)
1. **Conjugate block split** — Λ_μμ closed-form + Λ_σσ Fisher-scoring + Λ_μσ
   Newton. (This alone fixes the finite-diff slowness AND the overshoot.)
2. **PX-EM** φ-rescaling on the covariance update.
3. **SQUAREM** wrapper (port `em_squarem.jl`).
4. (Tier 2) natural-gradient Cholesky for Λ_σσ if ill-conditioned.

Key sources: Liu-Rubin-Wu 1998 (PX-EM); Gilmour-Thompson 1995 (Fisher/AI);
Lee-Nelder 2006 + Rönnegård hglm (DHGLM block split); Amari 1998 +
arXiv:2109.00375 (natural-gradient Cholesky); Varadhan-Roland 2008 (SQUAREM).

## Why this is the innovation
Engines treat all variance components uniformly. This recipe uses **closed-form
where the model is conjugate (μ) and scoring where it isn't (σ)** — combined
with PX-EM + SQUAREM + sparse-O(p) + warm-start + threading. That combination
isn't in any package; it's the candidate "fastest correct location-scale
mixed-model fit," and it pairs with the threaded pipeline for the 100× target.
