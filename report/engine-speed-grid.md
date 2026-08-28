# engine="julia" vs engine="tmb" — the comprehensive warm-fit grid

*Run 2026-08-28 on the v0.7.0-candidate state (owner-requested efficiency check). Instrument:
`tools/engine_speed_grid.R`; banked rows: `docs/dev-log/evidence/engine-speed-grid.tsv`. Method:
one R process, per cell 1 warm-up + 5 timed fits per engine, medians; one-time Julia startup
measured separately (6–13 s) so it cannot masquerade as engine slowness. The `coefdiff` column is
a positional sanity check only — name-matched parity lives in the parity harnesses at 1e-6..1e-8.*

## The diagnostic and its verdict

The owner's rule: at parity, warm per-fit Julia time should not lose badly on any route — a wide
warm loss is an anomaly to investigate as a defect until measured innocent. Verdict: **Julia wins
14 of 15 comparable cells (2.3×–42×), and the rule caught exactly one anomaly, whose mechanism was
found and fixed the same day.**

| cell | tmb med | julia med | speedup |
|---|---|---|---|
| gaussian_locscale n=120 | 0.021 s | 0.001 s | **21×** |
| gaussian_locscale n=5000 | 0.293 s | 0.007 s | **42×** |
| biv_gaussian rho12 n=400 | 0.037 s | 0.004 s | **9.3×** |
| gaussian_phylo_mean ntip=64 | 0.145 s | 0.018 s | **8.1×** |
| poisson_phylo p=100 | 0.105 s | 0.044 s | **2.4×** |
| poisson_phylo p=1000 | 1.077 s | 0.479 s | **2.3×** |
| nb2_phylo p=300 | 2.032 s | 0.052 s | **39×** |
| gamma_phylo 12×6 | 0.115 s | 0.014 s | **8.2×** |
| binomial_phylo 24×5 | 0.138 s | 0.005 s | **28×** |
| beta_phylo 12×6 | 0.283 s | 0.009 s | **31×** |
| gaussian_relmat G=25 | 0.110 s | 0.006 s | **18×** |
| nbinom2_relmat G=25 | 0.318 s | 0.016 s | **20×** |
| gamma_relmat G=25 | 0.187 s | 0.019 s | **9.8×** |
| binomial_trials FE | 0.026 s | 0.002 s | **13×** |
| biv_q4_phylo_reml ntip=16 | 1.204 s | 2.631 s → **1.279 s** | 0.46× → **0.94×** |

(poisson_relmat: harness cell used `sigma ~ 1`, which drmTMB refuses for Poisson — harness
limitation, not an engine result; the route's parity is banked in parity-classc.tsv.)

## The anomaly, investigated as the rule demands

`biv_q4_phylo_reml` was the single warm loss (0.46×). Mechanism, measured rather than guessed: the
route's inner (u, β) alternation carried a strict 1e-6 exit that **never fires** at genuine optima
— `delta_b` sits in a flat ~6.2e-6 limit cycle — so every outer objective evaluation burned all 15
alternations where ~2 suffice. The loop now also exits at the same calibrated relative criterion
the #526 convergence flag reports (`1e-4·(1+‖β‖)`, after ≥2 alternations). Result: 2.63 s →
1.28 s (2.1×), the cell at ~parity (0.94×), q4 affected tests 83/83, parity fixture numbers
unchanged. The residual to a clean win is the exact REML outer gradient (`lc_metric`, the
consciously-deferred Wave 3 item) — TMB gets its outer gradient from AD; this route still pays
finite differences over an inner-solved objective.

## Honest boundaries

Single machine (the Mac every prior benchmark used), warm medians, one seed per cell, toy-to-mid
sizes; the large-p scaling story lives in `report/speed-per-family.md` and the phylo benchmarks.
First-call startup (6–13 s here) is real for one-shot R users and is reported, not hidden.
