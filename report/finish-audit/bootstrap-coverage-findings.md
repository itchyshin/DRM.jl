# bootstrap_sigma_a — coverage validation findings (2026-06-13)

Monte-Carlo coverage study for the q4 among-axis SD percentile bootstrap
(`report/finish-audit/bootstrap_coverage_study.jl`). M datasets generated from a
KNOWN Σ_a (identified true SDs 0.8 / 0.6 / 0.5 / 0.4, mild coevolution off-diagonals)
on a fixed tree; each fit + bootstrapped; per-axis fraction of datasets whose 90%
percentile CI covers the true SD.

## Results (nominal 0.90)

| axis       | true SD | p=20, M=40 | p=60, M=30 |
|------------|---------|------------|------------|
| sd_mu1     | 0.8     | 0.846      | 0.900      |
| sd_mu2     | 0.6     | 0.846      | 0.867      |
| sd_sigma1  | 0.5     | 0.641      | 0.700      |
| sd_sigma2  | 0.4     | 0.795      | 0.700      |

MC s.e. on each coverage ≈ 0.05.

## Two findings (both fed into the Ayumi reply + the claim wording)

1. **Mean-axis (μ1, μ2) SD CIs are ~calibrated** and improve to nominal by p=60
   (a small-sample effect; expected to be fine at Ayumi's p ~ 10⁴).

2. **Scale-axis (σ1, σ2) SD CIs are anti-conservative** (~0.70 at nominal 0.90)
   and the miss PERSISTS at p=60 — it is not purely small-sample. The log-σ phylo
   SD is intrinsically harder to pin, and the percentile interval is too narrow
   there. Since the σ axes are exactly Ayumi's scale-phylo question, the reply must
   NOT claim a calibrated precise CI on them; the precise width is anti-conservative.

## Consequence for how to read the output (corrected guidance)

- An among-axis **SD is a boundary parameter** (≥ 0): the percentile bootstrap of
  a non-degenerate fit essentially NEVER returns a lower bound of exactly 0 (the
  verified σ2-collapse gave `sd_sigma2 = 0.065 [0.02, 0.26]`, lower > 0). So a
  "fraction of trees whose CI excludes 0" test is the WRONG discriminator — it is
  trivially almost always true. The robust read is **magnitude**: a collapsed axis
  has a small SD with a small CI sitting near the floor (upper ~0.2-0.3), an
  identified axis a clearly elevated SD + CI (lower well above 0, e.g. > 0.4) — the
  two do not overlap. This is Ayumi's existing "pinned to ~1e-3-1e-6 → no signal"
  reading; the bootstrap adds calibrated-ish uncertainty for the μ axes and an
  honest (if anti-conservative) interval for the σ axes.

- The **across-tree** summary should therefore be the distribution of the per-tree
  point SD (fraction of trees where the σ axis pins to the floor), NOT a per-tree
  "CI excludes 0" vote. Because the σ-axis per-tree CI is anti-conservative, a
  strict signal threshold is warranted.

- The **correlation** CIs (`cor_summary`) are robust in the way that matters: a
  collapsed-axis correlation is genuinely unidentified and the bootstrap returns
  ~[−1, 1] — a wide interval is the CORRECT report there, unaffected by the SD
  width miscalibration.

## Follow-up (not done here)

- A **BCa** (bias-corrected accelerated) interval would respect the SD ≥ 0 boundary
  AND correct the skew/bias that drives the σ-axis under-coverage. The acceleration
  needs a leave-one-species-out jackknife (p extra refits per fit) — practical for a
  single reported fit, prohibitive inside the coverage loop, so it is a scoped
  follow-up, not shipped in PR #286.
