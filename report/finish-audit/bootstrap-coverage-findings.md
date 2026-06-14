# bootstrap_sigma_a — coverage validation findings (2026-06-13, corrected)

Monte-Carlo coverage study for the q4 among-axis SD percentile bootstrap
(`report/finish-audit/bootstrap_coverage_study.jl`). M datasets generated from a
KNOWN Σ_a (identified true SDs 0.8 / 0.6 / 0.5 / 0.4, mild coevolution off-diagonals)
on a fixed tree; each fit + bootstrapped at the **same nominal level**; per-axis
fraction of datasets whose CI covers the true SD.

## Correction note (self-audit)

An earlier pass of this study called `bootstrap_sigma_a` WITHOUT passing `level`, so
it computed **95%** CIs while labelling them "nominal 0.90" — the reported numbers
(≈0.85/0.85/0.64/0.80) were 95%-CI coverages, and they UNDERSTATED the scale-axis
problem. Fixed: `level` is now passed through; the numbers below are true 90%-CI
coverages over M = 60 datasets (MC s.e. ≈ 0.04).

## Results — true 90% CIs, M = 60, p = 40

| axis       | true SD | coverage @ 0.90 |
|------------|---------|-----------------|
| sd_mu1     | 0.8     | 0.883           |
| sd_mu2     | 0.6     | 0.867           |
| sd_sigma1  | 0.5     | 0.533           |
| sd_sigma2  | 0.4     | 0.517           |

## Finding

- **Mean-axis (μ1, μ2) SD CIs are well-calibrated** (0.88 / 0.87 ≈ nominal 0.90).
- **Scale-axis (σ1, σ2) SD CIs severely undercover** (~0.52 at nominal 0.90). The
  cause is bias, not MC noise: ML shrinks a weak log-σ variance component downward,
  the parametric bootstrap simulates from the shrunk Σ̂, so the interval is centred
  too low and misses the truth on the high side about half the time. A plain
  bias-corrected (BC) percentile adjustment did NOT reliably fix it in a side
  experiment (it helped σ1, hurt a small-M μ2 run).

## What this means for the deliverable (honest framing)

The percentile bootstrap is a sound **detection + uncertainty-indication** tool, not
a calibrated precise-CI tool for the scale axes:

1. **Detection is robust.** An among-axis SD is a boundary parameter, so its CI
   essentially never includes 0; the discriminator is **magnitude** — a collapsed
   axis gives a small SD with a small interval near the floor (`sd_σ2 = 0.07
   [0.02, 0.26]`), an identified axis a clearly elevated one (`sd_μ1 = 1.14
   [0.74, 1.51]`); they do not overlap. The severe σ-axis undercoverage is about the
   precise WIDTH on identified axes, NOT the collapse-vs-signal call, and it does NOT
   create false positives at a true-zero axis (whose interval correctly sits near 0).
2. **The mean-axis CIs are usable** as calibrated 90% intervals.
3. **The scale-axis precise CIs are NOT trustworthy** as calibrated intervals
   (~0.52 coverage). Report the σ-axis interval only as a rough uncertainty
   indicator + the collapse/no-collapse magnitude read; for the across-tree summary
   use the distribution of the per-tree POINT σ-SD (Ayumi's "k/100 pinned" reading),
   not the per-tree CI.
4. **The correlation CIs are robust** in the way that matters: a collapsed-axis
   correlation is genuinely unidentified and the bootstrap returns ~[−1, 1].

## Follow-up (not done here — tracked)

A calibrated scale-axis interval needs to correct the variance-component shrinkage
bias: a **bias-corrected / double bootstrap**, a **BCa** interval with a proper
leave-one-species-out jackknife acceleration (tree-dropping refit, p extra fits —
practical for a single reported CI, not inside the coverage loop), or **REML-based
estimation** to reduce the bias before bootstrapping. Scoped, not shipped in PR #286.
