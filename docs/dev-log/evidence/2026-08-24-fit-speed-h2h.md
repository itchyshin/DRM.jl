# Fit-speed head-to-head: drmTMB engine="tmb" vs engine="julia" — Stage 1 (pilot)

**Status: STAGE 1 PILOT ONLY. Every number below is PROVISIONAL and CONTAMINATED
by concurrent load** (5 sibling agents running R/Julia sessions on the same
machine at the time of this run — `uptime` load average ~18–22 during the runs
below on an M1 Ultra). **Do not cite these numbers as a headline finding.**
This document exists to (a) prove the harness plumbing works end-to-end and
(b) size Stage 2. The authoritative run happens on a quiet machine per the
Stage-2 go-ahead (see bottom).

Harness: `tools/bench_fit_h2h.R`. Invocation:
```
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/DRM.jl" Rscript tools/bench_fit_h2h.R          # full grid
BENCH_PILOT=1 DRM_JL_PATH=... Rscript tools/bench_fit_h2h.R                                       # pilot subset, n_reps=1
```

## Machine / versions (this pilot run)

- CPU: Apple M1 Ultra (`sysctl -n machdep.cpu.brand_string`)
- R 4.6.0, drmTMB 0.7.0, Julia 1.10.0, JuliaCall 0.17.6
- `DRM_JL_PATH` = this repo's working tree
- Timing: `proc.time()[["elapsed"]]`, one untimed warmup rep (absorbs Julia
  JIT / TMB DLL compile) + `n_reps` timed reps, **median** reported.
  Pilot used `n_reps = 1` (BENCH_PILOT=1) — a single timed draw, explicitly
  not a median; Stage 2 uses the default `n_reps = 3`.
- Seeds: per-cell, fixed in `tools/bench_fit_h2h.R` (see `*_fixture()`
  functions — e.g. `gauss_locscale_fixture(100, 20260814)`).

## Pilot results (4 bridge cells + 1 direct cell; n_reps=1, PROVISIONAL)

| cell_id | family | n | p | tmb median (s) | julia median (s) | ratio tmb/julia | loglik agree (\|Δ\|) |
|---|---|---:|---:|---:|---:|---:|---:|
| gauss_locscale_n100 | Gaussian location-scale | 100 | – | 0.021 | 0.002 | **10.5×** | 3.0e-9 ✓ |
| biv_gaussian_rho12_n100 | Bivariate Gaussian (rho12) | 100 | – | 0.017 | 0.002 | **8.5×** | 4.8e-9 ✓ |
| poisson_phylo_p12x6 | Poisson, phylo(1\|species) | 72 | 12 | 0.029 | 0.003 | **9.7×** | 1.1e-10 ✓ |
| gamma_phylo_p12x6 | Gamma(log), phylo(1\|species) | 72 | 12 | **NO_NATIVE_COMPARATOR** | 0.007 | n/a | n/a |
| biv_lognormal_n500 (direct-bridge cell) | Bivariate lognormal | 500 | – | 0.019 | 0.003 | **6.3×** | 7.4e-12 ✓ |

Raw TSV: `docs/dev-log/evidence/fit-speed-h2h.tsv`. All logLik differences are
≤5e-9 for cells with a real comparator — well inside the 1e-4 correctness
threshold; **no logLik-disagreement flags in this pilot.**

At these tiny n / p the absolute times are milliseconds either side, so the
ratios above are noisy by construction (a 0.002s vs 0.020s draw on a loaded
20-core box has real jitter) — treat the ratio *magnitudes* as illustrative
only. What IS solid even under load: every cell converged on both sides where
both sides could run, and every same-target logLik pair agreed to <1e-8.

## Finding #1 (capability, not speed) — the `gamma_phylo` cell

**`engine = "tmb"` does not merely lose to `engine = "julia"` on
Gamma+phylo — it cannot run the model at all.** Native TMB rejects
`phylo()` random intercepts for Gamma (and, per drmTMB's own test suite,
Beta and Binomial): *"structured-effect syntax is planned, not implemented"*
on the TMB side (`tests/testthat/test-julia-phylo-nongaussian.R`, drmTMB
repo). Poisson and NB2 phylo random intercepts, by contrast, ARE natively
implemented in TMB (`tests/testthat/test-nbinom2-location-scale.R`,
`test-control.R`) — so those two *do* have a real same-target comparator.

This means the harness's phylo cells split into two different kinds of
evidence, and the full-grid report (Stage 2) must keep them separate:
- **Real speed comparison** (both sides fit the identical model):
  Gaussian, biv_gaussian, Poisson-phylo, NB2-phylo.
- **No comparison possible** (TMB structurally cannot fit it):
  Gamma-phylo, Beta-phylo, Binomial-phylo. DRM.jl being fast here is true
  but beside the point — the honest claim is "DRM.jl is the only engine
  that fits this at all," not "DRM.jl is faster."

`tools/bench_fit_h2h.R` already encodes this distinction (`tmb_rejects = TRUE`
per cell → `NO_NATIVE_COMPARATOR` status, not folded into a ratio).

## Finding #2 (early mechanism read) — does NOT obviously track "better optimizer"

Both engines are gradient-based quasi-Newton solvers (TMB: `nlminb`; DRM.jl:
`Optim.jl` LBFGS on drmTMB's own exact analytic gradient) — this is not an
optimizer-*family* difference (e.g. no derivative-free vs gradient-based
contrast), so a raw "better optimizer" story doesn't fit the pilot's shape.
Iteration counts on the TMB side are visible (`fit$opt$iterations`: 5–15
across the pilot cells) but **the Julia bridge fit object does not currently
expose an iteration count through `fit$bridge$iterations`** for any of the
pilot cells (`iterations` column reads `NA` for every `engine="julia"` row in
the TSV) — so iteration-for-iteration comparison is not yet possible from the
R side with this harness. That gap itself is worth fixing before Stage 2's
mechanism claim can be made quantitatively; until then this is a documented
limitation, not a null result.

What the pilot DOES support directionally (consistent with `HANDOVER.md`'s
own framing, not new evidence): the timing gap shows up **even on tiny,
cheap-either-way fits** (n=72–500, both sides well under 30ms), where nlminb
vs LBFGS iteration-count differences would plausibly be swamped by fixed
per-call overhead — R's `TMB::MakeADFun`/`nlminb` dispatch machinery vs a
JuliaCall round-trip into an already-warm Julia session. This is consistent
with the owner's stated mechanism (optimizer) being **one of several
candidate explanations, not obviously the dominant one** at small n — it is
equally consistent with call-marshalling / AD-backend overhead on the TMB
side. **Stage 2, at more reps and larger n (n=1000, p=40), and with the
iteration-count gap fixed, is needed before this can be stated as a finding
rather than a hypothesis.**

## Harness status

- Both cell types work: **bridge cells** (same `drmTMB(..., engine=)` call,
  timed both ways) and **direct cells** (`engine="tmb"` vs a raw
  `JuliaCall::julia_call("drmTMB_drm_bridge", ...)`, needed for
  `biv_lognormal`/`biv_student` since drmTMB's own gate never routes those
  families through `engine="julia"` at all — same convention as
  `tools/parity_fixture.R`'s `biv_cells`).
- One bug found and fixed during Stage 1: `add_row()` crashed
  (`data.frame(...)`: "differing number of rows: 1, 0") on the
  `biv_lognormal` direct cell because the raw JuliaCall return object didn't
  expose the field `fit_info()` expected, producing a zero-length value.
  Fixed by routing every column through a `sc()` scalar-coercion helper so a
  missing/malformed field degrades to `NA` instead of crashing the whole run
  — this is a general harness-robustness fix, not specific to one family.
- Full cell registry in the script (11 bridge cells + 2 direct cells =
  13 total, ≥8 required): `gauss_locscale` ×{n=100,1000}, `biv_gaussian_rho12`
  ×{n=100,1000}, `biv_gaussian_q2_phylo` (p=12), `poisson_phylo`
  ×{p=12,p=40}, `nbinom2_phylo` (p=12), `gamma_phylo`/`beta_phylo`/
  `binomial_phylo` (p=12, all `tmb_rejects`), `biv_lognormal` (n=500),
  `biv_student` (n=800). The pilot above exercised a 4-cell + 1-direct-cell
  subset (`BENCH_PILOT=1`); the other 8 cells are implemented but not yet
  run even once — Stage 2 is their first execution, not just a repeat at
  higher reps.

## Stage-2 cost estimate (D-139)

Pilot per-fit costs (both engines) are 2–30ms; the two size-varied cells at
n=1000 and the p=40 phylo cell are the only ones expected to take
meaningfully longer, and even a 50–100× slowdown on those (generous, given
O(p)/O(n) scaling reported in `HANDOVER.md`) keeps them under a few seconds
each. **Estimate: full grid (13 cells × 2 engines × [1 warmup + 3 reps]) ≈
2–4 minutes of fit compute**, plus the one-time ~1–2 minute JuliaCall/Julia
startup paid once per R session (already amortized — the harness batches all
cells into one session as instructed). **Total estimated Stage-2 wall time:
well under 10 minutes**, far under the 30-minute D-139 line — no plan
revision or grid-size cut needed on cost grounds alone. The gating constraint
is not runtime, it's a **quiet machine** (see below).

## Machine-quiet check (must be re-run immediately before Stage 2, not reused from here)

At pilot time: `ps ax | grep -c "[R]script"` = up to 5 concurrent R/Julia
processes observed across the three pilot runs; `uptime` load average
17.9–22.5 on a machine whose core count is high enough that this may or may
not indicate contention — **not independently confirmed quiet**. Before
Stage 2 fires, re-run both checks fresh and record the numbers in this
document; do not infer quietness from this pilot's timestamp.

## STOP

Stage 1 complete: harness built, pilot run 3 times (1 crash + fix + clean
rerun), plumbing proven end-to-end on both bridge and direct-call paths, one
correctness/capability finding recorded (Gamma/Beta/Binomial phylo has no
TMB comparator), one harness gap recorded (Julia-side iteration counts not
exposed). **Awaiting orchestrator go-ahead for Stage 2** (full 13-cell grid,
n_reps=3, on a machine independently re-verified quiet).
