# 2026-08-24 — Interval-coverage campaign PRE-RUN (issue #468): smoke, reachability, D-139 estimates

**Lane:** Curie (simulation & recovery), isolated worktree off `origin/main` (`8d45b651`).
**This is the PRE-RUN ONLY. It stops here for a go/no-go.** No campaign was run, no job
array submitted, no fence touched, and **no coverage claim of any kind is made in this
document** — a 1-rep cover indicator is a bit, not a rate.

Fences intact and out of scope for this slice:
`test/test_parity_gaussian_phylo_mean.jl:77` and `test/test_parity_biv_q4_phylo_reml.jl:72`
both still assert `interval_status != "coverage_claimed"` (re-confirmed against this
checkout; also re-checked as GF1 in `docs/dev-log/check-log.d/2026-08-24-parity-wave1.md`).

## 1. What the existing scope (#454) already settles — reused, not re-derived

`docs/dev-log/plans/2026-08-19-cell-d-ademp-pre-run.md` (merged PR #454) already fixes,
and this pre-run inherits unchanged:

- **The D-139 template**: estimate → smoke → STOP; a run that overruns its estimate stops
  and re-reports (applied twice below, §3).
- **The DGP spine**: `random_balanced_tree(ntip; branch_length = 0.25)` +
  `_poisson_phylo_setup` tree precision Q (generic, not Poisson-specific), simulate
  `u = σ · L⁻¹ z` on the *same* Q the fitter uses; probe constants β₀ = 0.3, β₁ = 0.25,
  σ_phy = 0.7.
- **The failure-mode list**: JIT-vs-warm timing trap; tree-scale trap (partition DGP scale
  vs estimator before any grid); `include`-runs-`main()` trap; private-refit vs public-API
  trap; failed fits stay in the denominator (Williams 10b).
- **The n_sim doctrine**: n_sim from MCSE, not folklore 1000; #454 already stated coverage
  is expensive ("n_sim ≥ 200 for MCSE ≲ 1.5% at 95%", "coverage-grade 500–1000 is a third
  conversation"). **Issue #468 is that conversation.**
- **What stays out**: AGHQ (rejects phylo — measured 2026-08-19), capability-chip flips,
  drmTMB numbers quoted as DRM.jl.

**What #468 changes relative to #454 (re-targeted, not rewritten):** the estimand. #454's
Cell D was *bias of the Poisson phylo SD* (ML Laplace vs Cox–Reid). The two standing
fences gate *interval coverage* on two **Gaussian** cells — the univariate phylo
location-scale cell and the bivariate q4 phylo REML cell — so the campaign that can
remove them must measure coverage on those two cell shapes. The Cell D bias campaign
remains a separate, already-scoped G0.

Note: the task brief named `docs/dev-log/scout/2026-08-24-parity-wait1.md`; no such file
exists in this checkout (closest: `docs/dev-log/check-log.d/2026-08-24-parity-wave1.md`).
The #457/#458 interval-trio evidence (`2026-08-24-interval-trio-parity.md`,
`2026-08-24-se-axis.md`, `parity-intervals.tsv`, `parity-se.tsv`) settles that all three
interval methods now *agree between engines* wherever both are reachable (Wald ~1e-08,
profile 1.2e-06, bootstrap width-ratio 0.88 post-#461) — which is precisely why the only
remaining question is calibration against truth, i.e. this campaign.

## 2. ADEMP structure of the proposed campaign (for approval — NOT run)

- **A (aims):** measure empirical coverage of nominal 95% intervals produced by DRM.jl's
  public interval API on the two fenced cell shapes, with Monte Carlo SE small enough to
  support a calibration statement. Secondary: convergence rate, interval-failure rate,
  wall time per rep. NOT an aim: removing the fences in the same PR that runs the
  campaign (measurement first, fence PR second, Rose audit between).
- **D (data-generating mechanisms):**
  - **Cell U** (univariate fenced shape): `bf(y ~ x + phylo(1|species), sigma ~ 1)`,
    Gaussian ML. Truth: β₀ = 0.3, β₁ = 0.25, σ_phy = 0.7, σ_resid = 0.5. Tree
    `random_balanced_tree(ntip; branch_length = 0.25)`, u simulated on the engine's own Q
    (probe spine). Grid: ntip ∈ {16, 32, 64} × per = 4 → N ∈ {64, 128, 256}.
    Tree-scale audit (one unit-height 1-seed vs branch_length = 0.25) BEFORE the grid,
    per #454.
  - **Cell B** (bivariate fenced shape): the `biv-q4-phylo-reml` five-formula model,
    Gaussian REML, `q4_vcov = true` (see finding F3), fixture-sized (ntip as committed,
    N = 128), truth taken from a fixed generator parameter set written down with the
    runner (the committed fixture's generator `test/parity/gen_biv_q4_phylo_reml.R`
    documents the shape; the Julia runner re-simulates natively on the engine's Q).
- **E (estimands):** the true generating values of, per cell:
  Cell U — β₀, β₁, log σ_resid, log σ_phy. Cell B — β per mu block, the two log-scale
  intercepts, rho12 intercept (profile target), phylo-covariance axes via their Wald rows.
- **M (methods = interval procedures, all public API):**
  - Cell U: **Wald × {mu block only}** and **profile × {all four axes}**. Wald on the
    sigma/resd axes is *undefined by route* (finding F2) — excluded by design, not
    silently NA.
  - Cell B: **Wald × all 17 axes** (finite under `q4_vcov = true`, finding F3) and
    **profile × {rho12}** only (full-profile is a measured runaway, finding F4).
    Bootstrap is deferred: the #459/#461 fix admits it, but B ≥ 999 per rep multiplies
    cost by ~three orders of magnitude; it needs its own estimate if wanted.
- **P (performance measures):** empirical coverage per target × method, with
  MCSE = sqrt(p̂(1−p̂)/n_sim); non-coverage decomposed into {fit failed, interval failed,
  truth outside}; failed fits stay in the denominator; convergence and Optim-flag rates
  reported per cell (the biv fixture cell records `julia_converged = false` as its known
  Mac-small behaviour — the campaign must report, not hide, that rate).

### Replicates — the number that drives the cost

Coverage MCSE at nominal 95%: n_sim = 200 → 1.54 pp; 500 → 0.97 pp; **1000 → 0.69 pp**;
2500 → 0.44 pp. To state "consistent with 95%" and be able to *detect* a ±2 pp
miscalibration at ≳3×MCSE, MCSE must be ≤ ~0.67 pp → **n_sim = 1000 per cell** is the
recommended campaign size (pilot at 200 first). This single number drives everything in §5.

## 3. Toy smoke — one cell, tiny n, 1 rep (measured, this Mac, 1 thread)

Runner: scratchpad `coverage_smoke.jl` (not promoted to `bench/` in this slice, per #454
precedent). `pathof(DRM)` confirmed = this worktree's `src/DRM.jl`.

**Cell U unit, seed 20260824, ntip = 16, per = 4, N = 64:**
converged = true, method = ML, loglik = −57.6855.
`coef(:mu)` = [0.2529, 0.2773] (truth 0.3, 0.25); `re_sd` = 0.762 (truth 0.7) — logged,
not headlined. Profile: 4/4 attempted, 0 failed.

TSV output (the exact per-rep row the campaign writes), **validity gate PASS** — 6 rows,
all finite, lower < estimate < upper, truth finite, cover ∈ {0,1}:

```
seed      conv param  coef        method  estimate  lower     upper    truth     covered t_fit_s
20260824  1    mu     (Intercept) wald    0.252881  -0.478758 0.98452  0.3       1       3.407
20260824  1    mu     x           wald    0.277298  0.164464  0.390132 0.25      1       3.407
20260824  1    mu     (Intercept) profile 0.252881  -0.538154 1.04428  0.3       1       3.407
20260824  1    mu     x           profile 0.277298  0.162719  0.393106 0.25      1       3.407
20260824  1    sigma  (Intercept) profile -0.774521 -0.961031 -0.562287 -0.693147 1      3.407
20260824  1    resd   species     profile -0.272126 -0.665537 0.168067 -0.356675 1       3.407
```

**The gate caught a real all-NA path on its first run (F2):** the first smoke wrote Wald
rows for the sigma-intercept and phylo-SD axes and the gate FAILED them — `stderror(fit)`
= [0.373, 0.0576, **Inf, Inf**] on this route, so those Wald intervals are (−Inf, Inf).
"It ran" was not "it worked". The method × target matrix in §2 encodes this; the re-run
with the corrected matrix passed. This is exactly the guard-blocked-NA failure mode the
issue text predicted.

**Cell B timing anchors (fixture data, 1 fit each; staged logs in scratchpad):**

| stage | q4_vcov = false (fixture setting) | q4_vcov = true (public default) |
|---|---|---|
| fit cold (JIT) | 63.5 s | 48.1 s |
| fit warm | 3.3 s | **2.7 s** |
| wald (17 rows) | 2.84 s — **all (−Inf, Inf)** (F3) | 3.63 s — **17/17 finite** |
| profile all targets | **>12 min, killed** (F4) | not attempted |
| profile parm=:rho12 | **84.8 s**, finite CI [−0.171, 0.301], 0 failed | — |

Findings:
- **F3:** `q4_vcov = false` (the fixture's setting) yields no vcov → every Wald row is
  (−Inf, Inf) *without error*. `q4_vcov = true` costs nothing at warm (2.7 vs 3.3 s) and
  makes all 17 rows finite. The campaign must fit Cell B with `q4_vcov = true`.
- **F4:** `profile_result` over all 17 biv targets is a runaway (>12 CPU-min per rep;
  killed under D-139 overrun rule). Per-target cost is ~85 s → the design profiles
  rho12 only.
- The biv fixture cell's Optim flag is false (its recorded known state, cf. the fixture
  test comment); reml_loglik = −225.2431 finite. The campaign reports this rate.

## 4. Compute reachability (both via existing ControlMaster sockets; no Duo triggered)

Discipline used: `ssh -O check <host>` first (liveness without a new login), then the
command with `-o ControlMaster=no` so a dead socket could never escalate to a fresh
authentication. All sockets at `~/.ssh/cm-*` (the `cm-` prefix), per D-64.

| target | socket | result |
|---|---|---|
| **Totoro** `snakagaw@totoro.biology.ualberta.ca` | alive (pid 74689) | **OK** — `nproc` = 384, load ≈ 0.05, up 129 d |
| **DRAC tamia** (`drac` alias) | alive (pid 41143) | **OK** — 64 cores/node, account **`aip-snakagaw`**, partitions `cpubase_*` up to 1-day walltime, 8 CPU nodes total (small cluster) |
| **DRAC narval** | alive (pid 41575) | **OK** — account **`def-snakagaw_cpu`** (+`_gpu`), `/project/def-snakagaw` exists, `julia/1.10.0` module available (matches this repo's 1.10 toolchain) |

No socket was absent or expired; no fresh login was opened anywhere.

## 5. Wall-clock estimates per target — derived from the smoke, not guessed

Measured per-rep costs (warm, 1 core, Apple Silicon Mac):
- **Cell U:** fit 0.004 s + wald ~0 s + profile(4 axes) 0.021 s ≈ **0.025 s/rep** at
  ntip = 16. (ntip = 32/64 scale-up is AGENT-INFERRED ×4–×20 from the sparse-Laplace
  q ≈ 2·ntip−1 growth — to be re-derived from a 3-seed warm pair on the target machine
  before the grid, per #454's rule.)
- **Cell B:** fit(q4_vcov = true) 2.7 s + wald 3.6 s + profile(rho12) 84.8 s ≈
  **91 s/rep**. Worker cold-start (JIT) ≈ 50–65 s, paid once per worker process.

Campaign totals at n_sim = 1000 (the §2 replicate count):
- Cell U, full ntip ladder: ≲ 1 CPU-h **total** (measured 25 core-s at ntip = 16;
  inferred ≤ ~10 core-min at ntip = 64).
- Cell B: 1000 × 91 s ≈ **25.3 CPU-h** — this is the campaign; everything else is noise.
- (Cluster cores are typically ~1.5–2.5× slower per-core than this Mac; the DRAC/Totoro
  numbers below carry a ×2 safety factor on per-rep cost.)

| target | what runs there | wall-clock estimate |
|---|---|---|
| **Totoro** (150 cores cap, D-143; `OPENBLAS_NUM_THREADS=1`) | pilot: n = 200 both cells + 3-seed timing re-derivation | **~15–25 min wall** (200 × ≤182 s / 150 + ~1 min JIT/worker + setup) |
| **Totoro** (same cap) | full n = 1000, both cells | **~40–70 min wall** (1000 × ≤182 s / 150 ≈ 20 min compute + JIT + orchestration) |
| **DRAC narval** (`--account=def-snakagaw_cpu`) | full n = 1000 as a SLURM array `--array=0-99`, 10 seeds per `$SLURM_ARRAY_TASK_ID`, 1 core + 4 GB each | per-task ≈ 50 s JIT + 10 × ≤182 s ≈ **~32 min compute → `--time=01:00:00`**; end-to-end wall = queue-dependent (not estimable in advance — stated plainly), typically same-day |
| local Mac, for contrast | full campaign | ≈ 26 CPU-h single-core (≈ 3.3 h at 8-way) — **≫ 30 min ⇒ D-139 forbids without approval** |

DRAC placement rules baked into the design: Julia depot (`JULIA_DEPOT_PATH`) and results
under `/project/def-snakagaw/`, never `/scratch` (purged ~60 d, no backup); nothing runs
on a login node — `sbatch` only, always with `--time` and `--account`. Tamia is reachable
but small (8 CPU nodes) and its `aip-` allocation is better saved for GPU work; narval is
the right array target.

## 6. Recommended split (for approval)

Totoro takes the pilot: the tree-scale audit, the 3-seed warm-pair re-timing on target
hardware, and n = 200 of both cells at ≤150 cores — everything needed to certify the full
grid's estimate, in under half an hour of wall time. Narval then takes the certified full
grid as a 100-task job array (10 seeds per task, one core each, depot and outputs on
`/project/def-snakagaw`), which decouples the 25-CPU-hour bill from any interactive
session and gives per-seed restartability. Honest caveat: the measured grid is small
enough that Totoro alone could absorb all of it in ≈ 1 h wall — DRAC earns its place only
if the owner widens the grid (bootstrap axis, more biv profile targets, ntip ladder for
Cell B, or n_sim = 2500); if no widening is wanted, a Totoro-only campaign is the simpler
and equally defensible choice.

## 7. Go / no-go recommendation

**GO — Totoro pilot (n = 200, both cells) now; narval full grid (n = 1000) only after the
pilot re-certifies the per-rep timings on cluster hardware.** The harness demonstrably
writes valid rows, both compute targets are reachable without Duo, and the driving cost
(25 CPU-h) is modest.

The honest case against: (i) the biv cell's per-rep cost is dominated by a single 85-s
rho12 profile — if the owner actually wants profile coverage on *more* biv axes, cost
scales linearly at ~85 s per axis per rep and the estimate above no longer holds;
(ii) the biv cell's Optim convergence flag is false on the fixture shape — if that rate
is high across seeds, the campaign yields a conditional-on-convergence coverage number
plus a large "fit failed" bucket, which may not be the clean fence-removal evidence
hoped for; (iii) Cell U's larger-ntip costs are inferred, not measured — the pilot's
first job is to replace them. None of these blocks the pilot; (ii) is a reason to run
it before committing to the full grid.

## Boundaries of this document

No coverage claim is made or implied anywhere above. The two `coverage_claimed` fences
are untouched. No job was submitted to any cluster. Extrapolated numbers are labelled
AGENT-INFERRED and are not promoted to measured. The full campaign requires Shinichi's
explicit go on: n_sim (1000 proposed), the Cell B profile-target set (rho12-only
proposed), the split (§6), and whether bootstrap coverage is in scope (proposed: out).

