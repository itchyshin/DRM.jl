# `phylo_gamma` loglik margin — diagnosis (2026-08-24)

**Question.** `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` row `phylo_gamma`
passes at `loglik_diff = 2.8986e-05` against `tolerance = 1e-04` (~3.4× inside the
bar), 4–6 orders of magnitude looser than its siblings (`phylo_beta`
`3.89e-10`; `parity-fixtures.tsv` cells `1e-09`–`1e-13`). `max_abs_coef_diff`
for the same row is `6.32e-08` — coefficients agree far more tightly than the
logLik does. Diagnose whether the gap is a real engine difference, optimiser
noise, or a loose fixture.

**Method.** All runs used `tools/parity_phylo_nongaussian.R`'s exact
`make_fixture()` (unmodified), invoked from a scratch copy that never wrote to
the shared TSV. R 4.6.0 / drmTMB 0.7.0 / Julia 1.10.0.

1. Reran the `phylo_gamma` and `phylo_beta` cells at 8 seeds (411, the
   committed seed, plus 101/202/303/404/505/606/707) inside one R/Julia
   session.
2. At seed 411, extracted drmTMB's full reported parameter vector — mu
   coefficients, `sigma` (log-CV), and `sdpars$mu["phylo(1 | species)"]` (the
   fitted phylo SD) — mapped it into DRM.jl's internal θ layout, and called
   DRM.jl's own (unexported) marginal-Laplace objective
   `DRM._phylo_mean_laplace_nuisance_fg(Val(:gamma_fixed), …)` directly on
   that θ, bypassing any refit. This evaluates *Julia's* likelihood formula at
   *drmTMB's* exact reported optimum.

**Result 1 — distribution.** `phylo_gamma` `loglik_diff` across the 8 seeds:
min 5.5e-12, median 4.25e-11, **max 2.899e-05 (seed 411 only)** — every other
seed is ~1e-11 to 1.5e-10, i.e. essentially machine precision. 0/8 crossed
`1e-4`. Seed 411 reproduced the committed value to full displayed precision
(2.8985964e-05 vs the committed 2.89859641071644e-05) — fully deterministic,
not run-to-run noise. So 2.9e-05 is **not typical**; it is a property of that
one fixture draw, roughly 3 orders of magnitude above every other draw tried.

**Result 2 — same-parameter-vector test.** At seed 411, drmTMB's fitted phylo
SD is `4.577e-06`; DRM.jl's own fitted phylo SD is `1.000e-06` — the two
engines land on *different* points, a ~4.6× discrepancy in that one
parameter, while mu agrees to 6e-08. Evaluating DRM.jl's objective at
drmTMB's exact θ (mu, sigma, log(4.577e-06)) gives loglik **-72.63028**,
which matches DRM.jl's own reported optimum (-72.63028) to **7.8e-12** — and
is *not* close to drmTMB's reported -72.63025 (that gap is the same 2.899e-05
already seen). **This rules out a formula/constant/Jacobian discrepancy**:
the two engines' likelihood expressions agree to near machine precision at a
shared point. The gap instead comes from both engines converging to
different (but likelihood-equivalent) values of a phylo-variance parameter
that has collapsed to near-zero — a boundary/near-degenerate case where the
marginal likelihood is essentially flat in that direction, so a ~4.6×
difference in the near-zero SD estimate moves logLik by only 2.9e-05.
`phylo_beta` at the canonical seed-411 draw shows a well-identified phylo SD
(no collapse) and agrees to 3.89e-10; a beta fit generated at seed 411 with a
perturbed RNG stream (not the canonical row) also showed an elevated
`loglik_diff` (1.58e-4) — consistent with the boundary explanation being
about the *data draw*, not the Gamma family specifically.

**Verdict on the UNVERIFIED `1.016e-04` claim.** Not reproduced. All 8 gamma
reps, including the exact committed seed, topped out at 2.899e-05 — the same
value already in the TSV, deterministically reproduced. No run produced
anything near 1.016e-04 for `phylo_gamma`. That number does not match this
cell in this environment; it may be a misattribution to a nearby beta result
(which independently does cross `1e-4` under a related near-boundary draw) or
came from a different code/package state. Treat it as refuted for this cell
absent further evidence.

**Recommendation (no fix applied).** The row is a real, reproducible,
deterministic result — not noise — but the size of the margin is driven by a
near-zero/boundary phylo-variance estimate, not a likelihood bug. Two
non-mutually-exclusive options for the fixture owner to consider (not
executed here): (a) note in the fixture/claim_boundary that this seed
produces a near-degenerate phylo variance for Gamma and the margin should not
be read as "engines nearly disagree on the likelihood," or (b) pick/average
over a seed where the phylo variance is well away from the boundary (as
seeds 101–707 all are) if a tighter, more representative margin is wanted for
this cell. Do not tighten `tolerance` based on this diagnosis alone — the
mechanism (flat likelihood ridge near a variance-component boundary) can in
principle produce a larger gap under a different unlucky draw or optimizer
tolerance change, so the pass is fragile in exactly the way the coefficient
diff cannot reveal.
