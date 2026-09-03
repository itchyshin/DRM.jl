# Warm-workflow registry — S12 (#563), root gate G5

G5: "every registered warm workflow wins, or the loss is retained and named." This is the
registry that gate is scored against. A workflow is **registered** only once it appears in
the table below with a fixed fixture, formula, and leg definition; nothing else counts.

Built by Curie (benchmarks lane) — harness + registry construction, smoke pre-run only.
**No full sweep has been run.** The verdicts below (WIN/LOSS/N/A) come from a 2-workflow,
1-thread smoke run only (§ 5) — they are NOT the G5 evidence. The full grid (all 10
workflows × 3 legs × k=3 reps × threads {1,2,4,8}) is the conductor's run on an idle Mac
(§ 6).

**2026-09-02 revision**: two measurement bugs found and fixed after the first smoke run —
see § 1 (timer floor) and § 1 (cached uncertainty). Both harnesses were re-run on the same
two workflows; the corrected numbers are in § 5. This same validation pass also surfaced and
fixed four R-side formula-grammar mistakes in the original draft (§ 3 lists the corrected
calls) — every registered R call in § 3 has now been executed against a live drmTMB session
at least once (the one exception, `large_sparse_lss_p2000`'s R leg, is noted where it applies).

## 1. What "warm" means here, and what each leg actually measures

Per `LOOP/GOAL.md`'s definition (private worktree, paraphrased in the S12 scout report):
prep + data transfer + model construction + the requested uncertainty surface + return
conversion, timed **after** JIT/DLL warm-up (cold startup is a separate, unmeasured
concern here), at 1/2/4/8 threads. This harness decomposes that into three separately
timed **legs** per workflow — **fit**, **uncertainty**, **predict** — each with ONE untimed
warm-up call (absorbs JIT compilation / first-call overhead) before timing.

### Timer floor

A single `time_ns()`/`proc.time()` call around one invocation is unreliable once a leg
finishes in microseconds (predict; uncertainty on small fixtures) — system-clock and
scheduler noise dominate, and `proc.time()` on this host is additionally **millisecond-
floored** (confirmed empirically: successive calls only ever differ by whole 0.001s steps).
Both harnesses now time each leg as a **loop**: repeat the call until cumulative wall time
≥ 0.25s (minimum 1 call), report **per-call = total / calls**. `k` (`--reps`) such loops run
per leg; `median_s`/`min_s` are the median/min of the `k` per-call numbers, and the new
**`calls`** TSV column is the mean calls-per-loop (rounded) — a sanity check that a leg
finishing in ~20µs needed thousands of calls to reach the 0.25s floor, while a multi-second
fit needed only 1.

R uses `microbenchmark::get_nanotime()` (nanosecond resolution; the package is installed on
this host, confirmed 2026-09-02) rather than `proc.time()`, with an automatic fallback to
`Sys.time()` differences (microsecond-ish, measured ~1–10µs between successive calls on this
host) if `microbenchmark` is absent — the harness prints which one it used at startup.

### Uncertainty leg — forced recomputation, not a cached read

The first smoke run's `uncertainty` numbers were **not real** — an artifact of both packages
caching their covariance matrix:

- **Julia**: `vcov(fit::DrmFit) = fit.vcov` (`src/gaussian_core.jl`) just reads a field
  computed ONCE inside `drm()` and stored in the `DrmFit` struct. `confint(fit)` calls
  `vcov`/`stderror` on that same cached field. Timing `confint(fit)` measures a struct-field
  read, not the Hessian computation.
- **R**: `vcov.drmTMB`/`confint.drmTMB` read `object$sdr$cov.fixed` —
  `object$sdr` is a `TMB::sdreport()` result computed ONCE inside `drmTMB()` and cached on the
  fit object. Same problem.

Fix, verified 2026-09-02:

- **Julia**: where the fitted objective closure is available and differentiable
  (`fit.nll !== nothing`), the harness calls `ForwardDiff.hessian(fit.nll, fit.theta)` then
  `DRM._vcov_from_hessian(...)` — the exact two steps the fitter itself used to produce
  `fit.vcov` in the first place (confirmed **byte-identical** to the cached `fit.vcov` on
  every workflow where it runs). **Two workflow families cannot be recomputed this way**:
  `biv_q4_phylo_ml`/`_reml` and `large_sparse_lss_p2000` build a **Float64-only sparse
  Cholesky inside `fit.nll`** (SuiteSparse does not accept `ForwardDiff.Dual` numbers), so
  `ForwardDiff.hessian` throws a `TypeError`/`MethodError` for those three — their `vcov` is
  computed by a specialised, non-AD internal path, genuinely inseparable from `fit()` itself
  (not skippable, not a caching artifact). **For those three, `uncertainty` is reported as
  N/A** (no TSV row is written; `tools/warm_timing_compare.jl` reports the missing row as
  such) rather than faked — the `fit` leg for those workflows already includes the covariance
  computation.
- **R**: the harness calls `TMB::sdreport(fit$obj)` directly — `fit$obj` is the live TMB
  ADFun object every drmTMB fit carries; calling `sdreport()` on it fresh re-invokes TMB's own
  C++ AD Hessian/covariance computation and was confirmed to reproduce `fit$sdr$cov.fixed` to
  machine precision. Unlike the Julia side, this is **generic** — it works on the compiled
  ADFun regardless of family/route, so all 10 R workflows get a genuine forced-recompute
  `uncertainty` leg (7 confirmed directly during this pass; `large_sparse_lss_p2000`'s R leg
  was **not** independently re-verified, for cost reasons — see § 6).

Net effect: **7 of 10 workflows get a real, forced `uncertainty` leg on both engines**
(`gauss_mixed_phylo_mean`, `gauss_lss_sd_group`, `gauss_lss_sd_phylo`, `bernoulli_mixed`,
`poisson_mixed`, `lognormal_locscale`, `meta_analysis_meta_V`). The remaining 3
(`biv_q4_phylo_ml`, `biv_q4_phylo_reml`, `large_sparse_lss_p2000`) get a real `uncertainty`
leg **on R only**; Julia reports N/A for the reason above, with the cost already folded into
`fit`.

### The three legs, precisely

- **fit** — the model-fitting call itself (`drm(...)` / `drmTMB(...)`).
- **uncertainty** — forced covariance recomputation, per above — NOT `confint()`'s own
  (negligible) arithmetic on top of a covariance matrix; that part is not separately
  measured because it is cheap relative to the covariance computation itself.
- **predict** — `predict(fit, <training data>)` on both sides (drmTMB's `predict()`
  defaults `newdata = NULL`, i.e. also the training design, but this harness passes the
  training frame explicitly on both sides so the comparison is symmetric and not reliant
  on the R-only default).

## 2. Fixtures

Written once by `tools/warm_timing_fixtures.jl` to `docs/dev-log/evidence/julia-r-parity/
warm-fixtures/` (CSV + Newick per phylogenetic workflow) — **both harnesses read these same
files; neither regenerates data independently.** Trees are synthetic balanced binary
trees (NOT `ape::rcoal`), built and documented in the generator: every branch length
`1/depth`, giving unit root-to-tip path length and pairwise covariance = (shared
root-to-MRCA path length)/depth. This is a deliberate, dependency-free, deterministic
substitute for `ape::rcoal` (no R call needed to produce the fixture) — chosen so the
SAME generator process (Julia, one run) can emit both the CSV and the Newick text that
implies the exact covariance the response was simulated from. It is not meant to look like
a real phylogeny; both `ape::vcv.phylo(read.tree(...))` (R) and `DRM.augmented_phy(...)` on
this same generated Newick text recover the identical covariance either way — that identity
is what "matched" requires here, not that the tree be biologically realistic.

**`sd()` predictors must be constant within each level of the grouping factor** (both
engines refuse otherwise: `drm()` raises `ArgumentError`, `drmTMB()` the equivalent). Found
during this validation pass: the first draft of `gauss_lss_sd_group` and `gauss_lss_sd_phylo`
wrongly reused an observation-level covariate as the `sd()` predictor. Fixed — the fixtures
now carry a dedicated group-level column (`zg`, one value per `g`, broadcast to its
observations) and species-level column (`xs`, one value per `species`) for this.

## 3. The registry (10 workflows)

| id | family / model shape | fixture size | mean formula | scale/other formulas | method |
|---|---|---|---|---|---|
| `gauss_mixed_phylo_mean` | Gaussian, mixed (iid group) + phylo mean | 16 tips × 6 = 96 obs, 4 study groups | `y ~ x + (1\|study) + phylo(1\|species)` | `sigma ~ 1` | ML |
| `gauss_lss_sd_group` | Gaussian LSS, `sd(g)` (non-phylo scale RE) | 30 groups × 20 = 600 obs | `y ~ x + (1\|g)` | `sigma ~ z` (obs-level), `sd(g) ~ zg` (group-level) | ML |
| `gauss_lss_sd_phylo` | Gaussian LSS, `sd(species, phylogenetic)` | 64 tips × 3 = 192 obs | `y ~ x + phylo(1\|species)` | `sigma ~ x` (obs-level), `sd(species, phylogenetic) ~ xs` (species-level) | ML |
| `biv_q4_phylo_ml` | Bivariate Gaussian, q4 phylo (mu1,mu2), ML | 16 tips × 3 = 48 obs | `mu1 = y1 ~ x + phylo(1\|p\|species)`, `mu2 = y2 ~ x + phylo(1\|p\|species)` | `sigma1 ~ 1`, `sigma2 ~ 1`, `rho12 ~ 1` | ML |
| `biv_q4_phylo_reml` | same fixture, REML | (same as above) | (same as above) | (same as above) | REML |
| `bernoulli_mixed` | Binomial (Bernoulli, 0/1), mixed | 25 groups × 20 = 500 obs | `y ~ x + (1\|g)` | — | ML |
| `poisson_mixed` | Poisson, mixed | 25 groups × 20 = 500 obs | `y ~ x + (1\|g)` | — | ML |
| `lognormal_locscale` | LogNormal, location-scale | n=400 | `y ~ x` | `sigma ~ z` | ML |
| `meta_analysis_meta_V` | Gaussian meta-analysis, `meta_V` | k=300 studies | `y ~ x + meta_V(v)` (Julia, positional) / `y ~ x + meta_V(V = v)` (R, named — see note) | `sigma ~ 1` | ML |
| `large_sparse_lss_p2000` | Gaussian LSS, `sd(species, phylogenetic)`, large p | 2048 tips × 2 = 4096 obs | `y ~ x + phylo(1\|species)` | `sigma ~ x` (obs-level), `sd(species, phylogenetic) ~ xs` (species-level) | ML |

**Grammar differs between the two engines in three places** (found and fixed during this
validation pass, every corrected call below was executed against a live session — drmTMB
0.7.0 / DRM.jl `origin/main` — except the one noted exception):

1. `phylo()`'s tree argument: Julia takes `tree=` as a separate keyword to `drm()`
   (`phylo(1 | species)`, then `drm(f, ...; tree = phy)`); **R takes it INLINE in the
   formula** (`phylo(1 | species, tree = tree)`) — `drmTMB(f, ..., tree = tree)` as a
   top-level argument does NOT work and errors with `phylo() requires a single named tree
   argument`.
2. `meta_V`: Julia takes it positional (`meta_V(v)`); **R requires the named argument**
   (`meta_V(V = v)`) — `meta_V(v)` alone errors with `` `meta_V()` requires exactly one
   argument named `V` ``.
3. `sd()`/`sd_phylo()` grouping-level spelling: Julia's non-phylo form is `sd(g)`, its phylo
   form `sd(species, phylogenetic)`; R's non-phylo form is the same `sd(g)`, but its phylo
   form is `sd(species, level = "phylogenetic")` (confirmed against `test/fixtures/lsss/
   README.md`'s cross-engine reference numbers, and now against a live run here).

### DRM.jl calls (Julia, native `drm()`, never the R bridge)

```julia
# gauss_mixed_phylo_mean
f = bf(@formula(y ~ x + (1 | study) + phylo(1 | species)), @formula(sigma ~ 1))
drm(f, Gaussian(); data, tree)

# gauss_lss_sd_group
f = bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ z), @formula(sd(g) ~ zg))
drm(f, Gaussian(); data)

# gauss_lss_sd_phylo
f = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
       @formula(sd(species, phylogenetic) ~ xs))
drm(f, Gaussian(); data, tree)

# biv_q4_phylo_ml / biv_q4_phylo_reml
f = bf(mu1 = @formula(y1 ~ x + phylo(1 | p | species)),
       mu2 = @formula(y2 ~ x + phylo(1 | p | species)),
       sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1), rho12 = @formula(rho12 ~ 1))
drm(f, Gaussian(); data, tree, method = :ML)    # or :REML

# bernoulli_mixed
drm(bf(@formula(y ~ x + (1 | g))), Binomial(); data)

# poisson_mixed
drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data)

# lognormal_locscale
drm(bf(@formula(y ~ x), @formula(sigma ~ z)), LogNormal(); data)

# meta_analysis_meta_V
drm(bf(@formula(y ~ x + meta_V(v)), @formula(sigma ~ 1)), Gaussian(); data)

# large_sparse_lss_p2000
f = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
       @formula(sd(species, phylogenetic) ~ xs))
drm(f, Gaussian(); data, tree)     # algorithm = :auto -> dispatches to the O(p) sparse
                                    # route automatically once G > 500 (#551)
```

### drmTMB calls (R, native `drmTMB(..., engine = "tmb")`, never `engine = "julia"`) —
### VERIFIED against a live drmTMB 0.7.0 session, 2026-09-02

```r
# gauss_mixed_phylo_mean
drmTMB(bf(y ~ x + (1 | study) + phylo(1 | species, tree = tree), sigma ~ 1),
       family = stats::gaussian(), data = d, engine = "tmb")

# gauss_lss_sd_group
drmTMB(bf(y ~ x + (1 | g), sigma ~ z, sd(g) ~ zg), family = stats::gaussian(), data = d, engine = "tmb")

# gauss_lss_sd_phylo
drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ x, sd(species, level = "phylogenetic") ~ xs),
       family = stats::gaussian(), data = d, engine = "tmb")

# biv_q4_phylo_ml / biv_q4_phylo_reml
drmTMB(bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
          mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
          sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
       family = biv_gaussian(), data = d, REML = FALSE, engine = "tmb")  # or TRUE

# bernoulli_mixed
drmTMB(bf(y ~ x + (1 | g)), family = stats::binomial(), data = d, engine = "tmb")

# poisson_mixed
drmTMB(bf(y ~ x + (1 | g)), family = stats::poisson(), data = d, engine = "tmb")

# lognormal_locscale
drmTMB(bf(y ~ x, sigma ~ z), family = drmTMB::lognormal(), data = d, engine = "tmb")

# meta_analysis_meta_V
drmTMB(bf(y ~ x + meta_V(V = v), sigma ~ 1), family = stats::gaussian(), data = d, engine = "tmb")

# large_sparse_lss_p2000
drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ x, sd(species, level = "phylogenetic") ~ xs),
       family = stats::gaussian(), data = d, engine = "tmb")
       # NO sparse fast path on the R side for this route (the O(p) sparse solver is
       # DRM.jl-only, #551) -- this cell is a genuine dense-vs-sparse comparison, not a
       # matched-algorithm one. The fit call above was NOT independently executed in this
       # pass (cost -- p=2048 dense phylo covariance; see § 6); every other call in this
       # section was.
```

## 4. Legs each family supports (n/a is not a loss)

All ten workflows support `fit` and `predict` on both engines. `uncertainty` is genuine on
both engines for 7/10 workflows; for `biv_q4_phylo_ml`, `biv_q4_phylo_reml`, and
`large_sparse_lss_p2000` it is genuine on R only — Julia reports N/A for a documented
mechanical reason (§ 1), not a refused/unsupported grammar combination and not a loss (the
cost is already inside `fit` for those three). Contrast `tools/bench_fit_h2h.R`'s
`tmb_rejects` cells (Gamma/Beta/Binomial phylo), which have NO fit-only R comparator at all —
none of those families are in this registry.

## 5. Smoke pre-run (D-139)

Run 2026-09-02, Mac, Julia 1.10.0, R 4.6.0 / drmTMB 0.7.0, `--threads 1 --reps 3`, workflows
`lognormal_locscale` and `poisson_mixed` only (the two smallest/simplest — no phylogenetic
tree, no LSS scale-scale submodel). **Host was NOT idle** (`uptime` load average ~26–45,
many sibling agent worktrees active) — these numbers are for harness validation and
order-of-magnitude estimation only, not a citable G5 verdict. Timer: loop-until-0.25s
(§ 1); R timer = `microbenchmark::get_nanotime()`; uncertainty leg = forced recompute
(§ 1), not `confint()`.

| workflow | leg | R calls | R median (s) | Julia calls | Julia median (s) | ratio (R/Julia) | verdict |
|---|---|---|---|---|---|---|---|
| lognormal_locscale | fit | 8 | 0.032059 | 1028 | 0.000241 | 133.0x | julia faster |
| lognormal_locscale | uncertainty | 33 | 0.007710 | 6742 | 0.000037 | 208.4x | julia faster |
| lognormal_locscale | predict | 1059 | 0.000233 | 14182 | 0.000018 | 12.9x | julia faster |
| poisson_mixed | fit | 3 | 0.101843 | 55 | 0.004471 | 22.8x | julia faster |
| poisson_mixed | uncertainty | 15 | 0.017334 | 966 | 0.000255 | 68.0x | julia faster |
| poisson_mixed | predict | 1034 | 0.000239 | 12714 | 0.000020 | 12.0x | julia faster |

G5 verdict from this smoke subset: **`lognormal_locscale` WIN, `poisson_mixed` WIN** — both
clean, all legs, no measurement-floor artifacts this time (contrast the first smoke run,
which showed a spurious `poisson_mixed` `predict` "loss" that was a `proc.time()` rounding
artifact at `n_reps=1`, and `uncertainty` numbers ~10–100× too fast on both engines because
they were reading cached results — both fixed, see § 1).

Loglik cross-check: `lognormal_locscale` agreed to 6 d.p. (−579.649631 both engines);
`poisson_mixed` agreed to ~2 d.p. (−789.738234 Julia vs −789.759163 R) — both converged, small
residual disagreement consistent with two different Laplace-approximation optimizer paths, not
investigated further here (out of scope for a timing harness; a correctness parity slice would
re-check this if the gap is not already explained elsewhere).

## 6. Estimate for the full run (D-139, NOT run)

Formula: `T(threads) ≈ Σ_workflows Σ_legs (median_time × reps, each rep itself looping to the
0.25s floor) + warm-up_time_per_workflow + process_restart_overhead`, summed separately per
engine, then the 4 thread counts are 4 independent process invocations (BLAS/OpenMP thread
counts are not always safely re-settable mid-session) so total wall time is roughly
`4 × (T_R(threads) + T_Julia(threads) + restart_overhead)`.

The 0.25s-floor timer changes this estimate's shape versus the pre-fix version: a leg that
used to report in 1 raw call now loops until 0.25s of *wall time* have elapsed regardless of
how many calls that takes — so **every leg now costs at least ~0.25s of wall time per rep**,
not the sub-millisecond number the raw computation might take. With `reps=3`, that is a floor
of **~0.75s per leg**, and up to 3 legs per workflow (fewer for the 3 N/A-uncertainty
workflows) — so the 9 non-`large_sparse_lss_p2000` workflows now cost on the order of
**9 workflows × ~2.25s (3 legs × 0.75s floor) × 2 engines ≈ 40s**, plus process
startup/warm-up overhead (Julia JIT ~10–20s per invocation, R/TMB DLL load ~2–5s) — call it
**~1–2 minutes per thread count** for those 9, a similar order of magnitude to the pre-fix
estimate but now for a principled reason (the floor, not the fit cost) rather than an
extrapolation from a handful of unreliable microsecond readings.

`large_sparse_lss_p2000` is the dominant unknown and was deliberately NOT run in this smoke
pass (task scope: "2 small workflows" only) — its R `fit` leg specifically was also not run
during the grammar-validation pass above, for the same cost reason. Its Julia `fit`+`uncertainty`
combined leg should stay fast (the whole point of the #551 O(p) sparse route — dispatches
automatically at G=2048 > 500; `predict` and the N/A-uncertainty bookkeeping add negligible
cost). Its **R `fit` leg has no sparse fast path** — drmTMB would build a dense 2048×2048
phylogenetic covariance and its TMB AD tape at that size, untested here, and under the new
floor timer its `reps=3` measurement would need AT LEAST 3 × (one single R fit's wall time) —
if that single fit takes, say, 30s, the measurement alone costs 1.5 minutes on top of the fit
cost itself, not 0.25s-floor-dominated like the small workflows. Unlike
`report/comparison-grid.md §3`'s q4 bivariate O(p) scaling grid (R comparable/faster at
p≥1000), this is a DIFFERENT model class (LSS scale-scale, not residual bivariate) and does
not transfer.

Putting it together: **~1–2 minutes per thread count for the 9 small workflows** (both
engines, now floor-dominated rather than extrapolated) **+ an unmeasured, potentially large,
`large_sparse_lss_p2000` term** (its R `fit` leg's true cost is still the single biggest
unknown in this whole estimate). Four thread counts: **roughly 5–10 minutes if the large-p R
fit is fast, but potentially well over the D-139 30-minute line if it is not** — a SECOND,
targeted pre-run test (R and Julia, `large_sparse_lss_p2000` alone, `--threads 1 --reps 1`,
generous timeout) is still recommended before committing to the full 4-thread-count sweep.

## 7. Usage

Generate fixtures once:

```
julia --project=. tools/warm_timing_fixtures.jl --out docs/dev-log/evidence/julia-r-parity/warm-fixtures
```

Run the matched sweep, one Julia process and one R process per thread count (four each):

```
julia --project=. -t 1 tools/warm_timing.jl --threads 1 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-julia-t1.tsv
julia --project=. -t 2 tools/warm_timing.jl --threads 2 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-julia-t2.tsv
julia --project=. -t 4 tools/warm_timing.jl --threads 4 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-julia-t4.tsv
julia --project=. -t 8 tools/warm_timing.jl --threads 8 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-julia-t8.tsv

OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript tools/warm_timing.R --threads 1 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-r-t1.tsv
OMP_NUM_THREADS=2 OPENBLAS_NUM_THREADS=2 Rscript tools/warm_timing.R --threads 2 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-r-t2.tsv
OMP_NUM_THREADS=4 OPENBLAS_NUM_THREADS=4 Rscript tools/warm_timing.R --threads 4 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-r-t4.tsv
OMP_NUM_THREADS=8 OPENBLAS_NUM_THREADS=8 Rscript tools/warm_timing.R --threads 8 --reps 3 --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures --out docs/dev-log/evidence/julia-r-parity/warm-timing-r-t8.tsv
```

Then compare, per thread count:

```
julia --project=. tools/warm_timing_compare.jl --julia docs/dev-log/evidence/julia-r-parity/warm-timing-julia-t1.tsv --r docs/dev-log/evidence/julia-r-parity/warm-timing-r-t1.tsv
```

(and likewise for t2/t4/t8).

**Both engines must run on the same host and the same Julia MINOR version.** The Mac runs
Julia 1.10.0; Totoro's Julia is 1.12.6 (a different minor version) per the S12 scout's
`compute-readiness.md` read — never pool Mac and Totoro numbers into one G5 comparison.
**The host must be idle** (re-check `uptime` / concurrent-agent count immediately before
running, exactly as `tools/bench_fit_h2h.R`'s own Stage-1 doc insists) — this smoke run's own
host was NOT idle (see § 5) and its numbers are not citable for that reason, independent of
the timer-floor/caching issues already fixed.

## 8. Files

- `tools/warm_timing_fixtures.jl` — fixture generator (this registry's source of truth for
  sizes/seeds).
- `tools/warm_timing.jl` — Julia harness (loop-until-0.25s timer; forced `ForwardDiff`-based
  covariance recompute where supported, N/A otherwise — see § 1).
- `tools/warm_timing.R` — R harness (same timer discipline; forced `TMB::sdreport()`
  recompute).
- `tools/warm_timing_compare.jl` — joins the two TSVs, Markdown table (now with `calls`
  columns) + G5 verdict per workflow.
- `docs/dev-log/evidence/julia-r-parity/warm-fixtures/` — generated fixtures (CSV + Newick),
  committed so a re-run reads the exact same data without regenerating it.
