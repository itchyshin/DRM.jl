# A12 — recovery for the bivariate known-V meta path, and the cost of omitting `V`

Date: 2026-08-16 · lane: DRM.jl (Claude, arc-loop) · complements A8 (PR #423)

A8 shipped with two kinds of evidence — cross-implementation parity against
drmTMB 0.7.0, and an independent dense-MVN log-likelihood anchor. Neither asks
the question the model exists to answer: **does it recover the heterogeneity, and
does `rho12` stay separated from the known sampling correlation?** This does.

50 replicates per cell. Truth: `sigma1 = 0.45`, `sigma2 = 0.55`, mean slope 0.5;
the sampling correlation inside `V` is set to a *different* value, and in one
cell the *opposite sign*, from the heterogeneity correlation.

## Recovery with `V` consumed

| cell | `sigma1` bias | `sigma2` bias | `rho12` bias | slope bias | conv |
|---|---|---|---|---|---|
| n=120, ρ=−0.35, sampling +0.6 | −0.0061 (1.2 MCSE) | −0.0096 (1.7) | **−0.0045 (0.4)** | −0.0098 (2.1) | 50/50 |
| n=120, ρ=+0.25, sampling −0.4 | −0.0063 (1.3) | −0.0095 (1.6) | **+0.0023 (0.2)** | −0.0098 (2.1) | 50/50 |
| n=300, ρ=−0.35, sampling +0.6 | −0.0023 (0.9) | +0.0015 (0.5) | **−0.0033 (0.4)** | +0.0025 (0.6) | 50/50 |

The heterogeneity correlation — the parameter this model exists to isolate — is
recovered to well under one Monte-Carlo standard error in every cell, with either
sign, against a sampling correlation of the opposite sign. The variance
components carry a small downward bias at n=120 (1–2 MCSE) that **shrinks with
studies**: exactly the maximum-likelihood behaviour expected, not a defect.

## The cost of omitting `V` — a bias that does not shrink

Each replicate was also fitted **without** `V`, everything else identical:

| cell | true ρ | `rho12` without `V` | pulled by |
|---|---|---|---|
| n=120, sampling **+0.6** | −0.35 | −0.2591 | **+0.0909** |
| n=120, sampling **−0.4** | +0.25 | +0.1865 | **−0.0635** |
| n=300, sampling **+0.6** | −0.35 | −0.2599 | **+0.0901** |

Three things make this the important half of the study:

1. **The pull is toward the sampling correlation, in both directions.** Positive
   sampling correlation drags `rho12` up; negative drags it down. That is the
   mechanism, demonstrated rather than asserted.
2. **It does not shrink with more studies** — `+0.0909` at n=120 versus `+0.0901`
   at n=300. More data buys nothing, because this is bias, not noise. Tripling
   the study count makes the wrong answer *more precise*.
3. **Nothing about the fit looks wrong.** All 50 replicates converge, the
   estimate is plausible, and there is no diagnostic that flags it. The failure
   is entirely silent.

An analyst reporting `rho12 = -0.26` here would be reporting a number roughly a
quarter of which is an artefact of the study design — the two outcomes having
been measured on the same animals — rather than a between-study finding.

## Why this matters for the guide's claim

`docs/src/model-guides/meta-analysis.md` tells readers, in the strongest terms
the page has: *"If you omit `V`, `rho12` absorbs the sampling correlation … That
failure is silent."* Until now that was a statement from the model's structure.
It is now a measurement, with a magnitude (≈0.09 on a 0.6 sampling correlation)
and the crucial detail that **more data does not rescue it**.

## Scope and limits

- **50 replicates**, three cells. Enough to resolve a ~0.09 bias against MCSE
  ≈0.012; not a coverage study.
- **Point recovery only.** No interval coverage for `rho12` or the variance
  components — that is a separate and larger piece of work.
- **Correctly-specified `V`.** This says nothing about a *misspecified* sampling
  correlation, which is the more common practical hazard (analysts often guess
  `cor12`). A sensitivity sweep over an assumed `cor12` is the natural follow-up.
- **Gaussian both axes, intercept-only heterogeneity**, matching the A8 slice.
- No claim about drmTMB's estimator: both engines were shown to agree in A8, but
  this study is DRM.jl only.
