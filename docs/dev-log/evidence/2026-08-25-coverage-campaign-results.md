# Interval-coverage campaign — RESULTS (issue #468), Totoro

**Date:** 2026-08-25 · **Authorised:** Shinichi, *"run the coverage campaign on Totoro"* (the D-139 go/no-go).
**Machine:** Totoro, 150 cores (D-143 cap, enforced by the driver). **Julia** 1.10.10.
**Per-target summary:** `2026-08-25-coverage-campaign-results.tsv` (36 rows, marginal *and* conditional).
**Certification:** `2026-08-25-totoro-campaign-certification.md`.

> **THE FENCES ARE NOT REMOVED BY THIS DOCUMENT.** Both `interval_status != "coverage_claimed"`
> assertions stand. This is the measurement; §5 argues it does not license lifting them.

**This is the SECOND run.** The first exposed two solver bugs (#493, #494) which were then fixed; those
fixes change what the campaign measures, so it was re-run in full. §6 records what moved and why.

## 1. What ran

| cell | n_sim | wall | convergence |
|---|---|---|---|
| **U** — `bf(y ~ x + phylo(1\|species), sigma ~ 1)`, Gaussian ML | 1000 × {ntip 16, 32, 64} | 22 s/rung | 1000/1000 |
| **B** — `biv-q4-phylo-reml` five-formula, Gaussian REML, `q4_vcov=true` | **1000/1000** | 705 s | **965/1000 = 96.5 %** |

Truth: β₀=0.3, β₁=0.25, σ_phy=0.7, σ_resid=0.5 (Cell U); the generator's `Lam` (Cell B). Failed fits and
failed intervals **stay in the denominator** (Williams 10b); a non-finite endpoint is `covered = 0`.

**Cell B is now the complete grid.** The first run lost 83 reps to the #494 runaway and every figure was
conditioned on *"not runaway-prone"* — a selection caveat that could not be checked from inside the data.
That caveat is now **retired**.

## 2. The result splits into two different questions

Reporting one number per target conflates *"are the intervals calibrated?"* with *"does the solver
produce an interval at all?"*. They have different answers and different owners, so both are given.

## 3. Calibration — good, once you condition on getting an interval

**Cell U, conditional on a successful interval:**

| ntip | mu (n=2000) | resd | sigma |
|---|---|---|---|
| 16 | 0.938 | 0.944 (n=956) | 0.936 (n=687) |
| 32 | **0.956** | 0.938 (n=999) | **0.954** (n=868) |
| 64 | 0.947 | 0.944 (n=1000) | **0.950** (n=976) |

Every entry is within ~2 MCSE of nominal 0.95. **The intervals DRM.jl produces on Cell U are
calibrated**, including at N=64.

**Cell B, conditional (n≈980 per target unless noted):**

| group | conditional coverage |
|---|---|
| `mu1`/`mu2`, both axes | 0.930 – 0.938 |
| `sigma1`/`sigma2` | 0.903 / 0.917 |
| `rho12` Wald | 0.937 |
| `rho12` profile (n=777) | 0.973 |
| **phylocov DIAGONAL** (n=3936) | **0.974** |
| **phylocov OFF-DIAGONAL** (n=5910) | **0.876** |

## 4. The structural finding, now beyond doubt

The diagonal/off-diagonal split in the phylo covariance is **0.974 vs 0.876** at MCSE 0.003–0.004 —
roughly **25 MCSE apart**, on ~4k and ~6k intervals. This is not Monte Carlo noise.

Both directions are calibration failures:

- **Off-diagonals under-cover**: `L43` 0.827, `L32` 0.859, `L21` 0.880. A nominal 95 % interval that
  covers 83 % of the time understates uncertainty.
- **Diagonals over-cover**: `L44` covers **1.000** (MCSE 0.000 — it covered every single time) and `L33`
  0.995. An interval that always contains the truth is not a 95 % interval; it is uninformatively wide.
  Over-coverage is a calibration failure, not a safe margin.

**SHARPENED after checking the axis mapping (#495).** "Diagonal vs off-diagonal" was how I first read
this, and it is the coarser story. The axes are `(:mu1, :mu2, :sigma1, :sigma2)`
(`src/gaussian_bivariate.jl:123`), and grouping by how much the **scale** axes participate gives an
ordered gradient:

| group | n | coverage | MCSE |
|---|---|---|---|
| diagonal, **mean** axes (L11, L22) | 1989 | **0.951** | 0.005 |
| diagonal, **scale** axes (L33, L44) | 1947 | **0.997** | 0.001 |
| off-diagonal, mean × mean (L21) | 995 | 0.880 | 0.010 |
| off-diagonal, mean × scale (×4) | 3935 | 0.888 | 0.005 |
| off-diagonal, **scale × scale** (L43) | 980 | **0.827** | 0.012 |

That reframes it as **two defects, not one**. The mean-axis variances are *correctly calibrated* —
0.951 at MCSE 0.005 on ~2000 intervals — which is the control proving the machinery can hit nominal on
this very fit. The scale-axis variances over-cover to uselessness, and every covariance under-covers,
worst where both axes are scales.

These are **Wald** intervals on **log-Cholesky** parameters — a nonlinear reparameterisation, with the
diagonal entries on a log scale (bounded below) and the off-diagonals not. The campaign establishes
*that* the gradient exists and its size; it does not establish *why*, and cannot separate "Wald on a
transformed scale" from "these components are genuinely hard to identify at N = 128". The discriminating
test — profile vs Wald on the same fits — is proposed in #495.

## 4b. Decomposed with zero new compute — and the over-coverage hides a bias (#495, #496)

The discriminating test proposed in #495 (profile vs Wald) turned out **not to be runnable**:
`profile_result(fit; parm = :phylocov)` throws `ArgumentError: matrix contains Infs or NaNs`, and `parm`
selects by *block* not coefficient, so a three-target design cannot be expressed. A D-139 pre-run caught
that before ~20 CPU-h were spent.

The question was answerable from the banked 1000 reps instead. For a 95 % Wald interval the reported SE
is `(upper − lower) / (2 × 1.96)`, which decomposes miscoverage into **bias**, **wrong SE**, and **SE
that fails to adapt**:

| entry | axes | truth | mean(est) | bias | emp SD | mean(SE) | SE/empSD | coverage |
|---|---|---|---|---|---|---|---|---|
| L11 | mu1×mu1 | −0.6931 | −0.7849 | −0.092 | 0.326 | 0.269 | 0.825 | 0.949 |
| L22 | mu2×mu2 | −0.7803 | −1.0483 | −0.268 | 0.508 | 0.408 | 0.802 | 0.953 |
| **L33** | s1×s1 | −0.9549 | −1.8299 | **−0.875** | 1.054 | 1.604 | **1.522** | 0.995 |
| **L44** | s2×s2 | −0.9534 | **−2.8055** | **−1.852** | 1.243 | **3.498** | **2.815** | **1.000** |
| L43 | s2×s1 | 0.0619 | 0.0461 | −0.016 | 0.228 | 0.188 | 0.827 | 0.827 |

**The scale-axis over-coverage is concealing a severe bias (#496).** `L44`'s mean estimate is −2.81
against a truth of −0.95 — a phylo SD of ≈0.06 where the truth is ≈0.39, i.e. the component collapses
toward the boundary. Its SE is 2.8× the empirical SD, which is what a log-scale Wald SE does near a
boundary, and the two errors cancel: the interval contains the truth **986 times out of 986 while being
centred in the wrong place**. Read from coverage alone, `L44` looks like the best-behaved parameter on
the fit. It is the worst. §4's "uninformatively wide" was too generous a description.

**The under-coverage is an SE that does not adapt.** Correlation between `|estimate − truth|` and the
reported SE, per rep: **L11 +0.702, L44 +0.786, L43 +0.032**. That is why `L11` covers nominally despite
an SE averaging 17 % below the empirical SD — it tracks each rep's error — while `L43`'s SE carries
essentially no information about the error and under-covers at 0.827. The off-diagonal defect is not
"SE too small" but "SE **uninformative**", which is a different problem with a different fix.

So the single finding in §4 is really **two defects with unrelated fixes**: a point-estimate bias on the
scale axes (#496) and uninformative covariance SEs (#495). Interval work cannot touch the first.

## 5. What this licenses

**Supports a calibration statement:** Cell U `mu` at every rung and `sigma`/`resd` conditional on a
successful interval; Cell B `rho12` (both methods).

**Does not:** Cell B phylocov, in **either** direction — the off-diagonals under-cover by 5–11 MCSE and
the diagonals over-cover to the point of being uninformative. Nor Cell B `sigma1`/`sigma2` (0.903/0.917).

**And no marginal number licenses anything yet**, because the failure rates below are the binding
constraint, not the calibration.

## 6. Solver failure is now the dominant defect, and it is measured

The #493 fix converts a fabricated bound into an honest failure, so failures are visible for the first
time. They are not rare:

| target | interval failures / 1000 |
|---|---|
| Cell U `sigma` profile, ntip=16 | **313** |
| Cell U `sigma` profile, ntip=32 | 132 |
| Cell U `sigma` profile, ntip=64 | 24 |
| Cell U `resd` profile, ntip=16 | 44 |
| Cell B `rho12` profile | **223** |
| Cell B Wald targets | 1 – 39 |

**Marginal coverage therefore FELL** where it looks worst — Cell U `sigma` reads 0.643 / 0.828 / 0.927
against the first run's 0.810 / 0.914 / 0.947. That is not a regression. Before the fix a degenerate arm
returned a finite bogus bound that happened to contain the truth about half the time; now it is scored
`covered = 0`. The new number is lower and true.

**`rho12` is the sharpest case.** First run: 0.965, 7 failures — apparently the best-calibrated target
on Cell B. Complete run: **0.756 marginal with 223 failures, 0.973 conditional**. Its excellence was
real *and* its reliability was not, and only separating the two shows both.

`resd` failing 44 times at ntip=16 is a **new** finding: the degenerate-endpoint bug was not confined to
the `sigma` axis the first run happened to look at.

## 7. Honest limits

- **One family, one DGP, one tree shape per cell.** No misspecification, no unbalanced designs.
- **Bootstrap intervals still unmeasured** — deferred by the design on cost.
- **Cell B truth uses a corrected DGP.** The committed fixture generator draws
  `U <- L %*% Z %*% t(chol(Lam))`, whose column covariance is **not** `Lam` (`(R Rᵀ)[1,1] = 0.30` against
  a nominal 0.25). Harmless for the fixture's own point-estimate parity, which never invokes truth;
  fatal for coverage. The runner uses the textbook matrix-normal draw. **The committed R generator still
  has this quirk.**
- **Conditional coverage conditions on solver success**, which is not random — it correlates with the
  fits where the profile surface is hard. The conditional numbers describe *"intervals DRM.jl actually
  returns"*, which is the user-relevant quantity, but they are not unconditional calibration.
