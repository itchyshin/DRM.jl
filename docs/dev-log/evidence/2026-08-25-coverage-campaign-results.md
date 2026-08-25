# Interval-coverage campaign — RESULTS (issue #468), Totoro

**Date:** 2026-08-25 · **Authorised:** Shinichi, *"run the coverage campaign on Totoro"* (the D-139 go/no-go).
**Machine:** Totoro, 150 cores (D-143 cap, enforced by the driver, which refuses above it).
**Code:** DRM.jl `feat/drmtmb-catchup` @ `6f52d179`, Julia 1.10.10. Runner: `bench/coverage_campaign.jl`.
**Per-target summary:** `2026-08-25-coverage-campaign-results.tsv` (36 rows).
**Certification (timings, tree-scale audit):** `2026-08-25-totoro-campaign-certification.md`.

> **THE FENCES ARE NOT REMOVED BY THIS DOCUMENT.** Both
> `interval_status != "coverage_claimed"` assertions stay exactly as they are. This is the
> measurement; whether any of it justifies moving a fence is a separate decision, and §5 argues
> that for most targets it does not.

## 1. What ran

| cell | shape | n_sim | wall |
|---|---|---|---|
| **U** (univariate) | `bf(y ~ x + phylo(1\|species), sigma ~ 1)`, Gaussian ML | 1000 × {ntip 16, 32, 64} | 22 s per rung |
| **B** (bivariate) | `biv-q4-phylo-reml` five-formula shape, Gaussian REML, `q4_vcov = true` | **917 of 1000** | stopped at 17 min |

Truth: β₀ = 0.3, β₁ = 0.25, σ_phy = 0.7, σ_resid = 0.5 (Cell U); the generator parameter set with
`Lam` as the among-axis phylo covariance (Cell B). Failed fits and failed intervals **stay in the
denominator** (Williams 10b); non-finite interval endpoints are recorded as `covered = 0`, never dropped.

Cell B convergence: **885/917 = 96.5 %** — the pre-run warned this cell's Optim flag was `false`;
#484's automatic warm restart, which landed after the pre-run was written, changed that.

## 2. Cell U — the mean block is well calibrated

n = 1000 per rung, MCSE ≈ 0.007.

| target | ntip 16 (N=64) | ntip 32 (N=128) | ntip 64 (N=256) |
|---|---|---|---|
| `mu:x` wald | 0.941 | **0.950** | **0.950** |
| `mu:x` profile | 0.946 | **0.953** | **0.952** |
| `mu:(Intercept)` wald | 0.905 | **0.952** | 0.933 |
| `mu:(Intercept)` profile | 0.930 | **0.959** | 0.942 |
| `resd:species` profile | 0.918 | 0.937 | 0.944 |
| `sigma:(Intercept)` profile | 0.810 | 0.914 | 0.947 |

**The slope `mu:x` is nominal at every rung it should be** — 0.950 / 0.950 at N ≥ 128, against a
nominal 0.95 at MCSE 0.007. The intercept and the variance components under-cover at N = 64 and
converge upward, which is ordinary small-sample behaviour for variance components.

Zero non-converged fits and zero interval failures across all 3000 Cell U reps.

## 3. The `sigma` result is a SOLVER bug, not a calibration failure (#493)

`sigma:(Intercept)` profile reads 0.810 / 0.914 / 0.947 — apparently badly miscalibrated at small n.
It is not. In a measured fraction of fits the **upper profile endpoint equals the point estimate
exactly**, making the interval one-sided. Splitting the same reps on that condition:

| ntip | clean arms | **coverage, clean** | MCSE | collapsed | coverage, collapsed |
|---|---|---|---|---|---|
| 16 | 757 | 0.917 | 0.010 | 243 (24.3 %) | **0.477** |
| 32 | 894 | **0.951** | 0.007 | 106 (10.6 %) | 0.604 |
| 64 | 981 | **0.950** | 0.007 | 19 (1.9 %) | 0.789 |

**When the endpoint search succeeds, coverage is nominal.** When it collapses, coverage is ≈ 0.48 —
the arithmetic signature of a one-sided interval, since the truth lies above the estimate about half
the time. Filed as **#493**.

Reported as a marginal number alone, this would have read as *"DRM.jl's sigma profile intervals
under-cover"* and sent someone to look at the likelihood. The defect is in the root-find.

Residual, stated honestly: clean-arm coverage at ntip = 16 is 0.917 (MCSE 0.010), still ≈ 3.3 MCSE
below nominal. There is *some* genuine small-sample under-coverage at N = 64 on top of the collapse.

## 4. Cell B — a clean structural split

n = 917, MCSE 0.006–0.013.

| group | targets | coverage |
|---|---|---|
| phylocov **diagonal** | L11, L22, L33, L44 | 0.947, 0.943, 0.963, **0.985** |
| phylocov **off-diagonal** | L21, L31, L32, L41, L42, L43 | 0.874, 0.891, **0.846**, 0.883, 0.877, **0.810** |
| mu slopes | mu1:x, mu2:x | 0.940, 0.927 |
| mu intercepts | mu1, mu2 | 0.909, 0.907 |
| sigma intercepts | sigma1, sigma2 | 0.895, 0.881 |
| rho12 | profile / wald | **0.965** / 0.937 |

The diagonal log-Cholesky entries are at or above nominal — L44 at 0.985 is **conservative**, not
merely adequate. The off-diagonals under-cover by 5–11 MCSE.

That split is interpretable rather than mysterious: these are **Wald** intervals on **log-Cholesky**
parameters, a nonlinear reparameterisation, and Wald on a transformed scale is expected to behave
worse for the off-diagonal (less well-identified, more skewed) entries. The campaign does not
establish *why*; it establishes *that*, with n = 917 behind it.

`rho12` — the one axis with a profile interval on this cell — is **0.965 profile vs 0.937 Wald**.
Profile is slightly conservative, Wald slightly liberal, both within ~2–3 MCSE of nominal.

## 5. What this does and does not license

**Supports a calibration statement** (nominal, MCSE ≈ 0.007): Cell U `mu:x` Wald and profile at
N ≥ 128; Cell U `sigma` profile **conditional on a non-collapsed upper arm** at N ≥ 128; Cell B
phylocov diagonals and `rho12`.

**Does not support one:** every Cell U target at N = 64; Cell B phylocov **off-diagonals** (0.81–0.89,
far outside Monte Carlo error); Cell B `sigma1`/`sigma2`; and Cell U `sigma` **marginally**, until
#493 is fixed.

**So the fences should not be lifted wholesale.** A defensible narrower move would gate on the
specific well-calibrated cells; that is the owner's call, and it should follow #493 rather than
precede it.

## 6. Honest limits

- **Cell B is 917 of 1000 reps, and the missing 83 are not random.** They are exactly the seeds where
  the `rho12` profile **runs away** — spinning at 99.9 % CPU, 0 rows in 90 s, 17+ minutes against a
  47.6 s per-rep cost. Stopped under D-139's overrun rule. 22 reproducing seeds are listed in
  **#494**. Every Cell B number is therefore implicitly conditioned on *"not runaway-prone"*, and that
  conditioning **cannot be checked from inside this dataset**. MCSE is unaffected; selection is not.
- **One family, one DGP, one tree shape per cell.** No misspecification, no unbalanced designs.
- **Bootstrap intervals were not measured** — deferred by the design (cost), still unmeasured.
- **Cell B's truth uses a corrected DGP.** The committed fixture generator draws
  `U <- L %*% Z %*% t(chol(Lam))`, whose column covariance is **not** `Lam` (`(R Rᵀ)[1,1] = 0.30`
  against a nominal 0.25). Harmless for the fixture's own point-estimate parity, which never invokes
  truth; fatal for coverage. The runner uses the textbook matrix-normal draw instead, verified to
  reproduce `Lam`. **The committed R generator still has this quirk** and is worth a separate look.
