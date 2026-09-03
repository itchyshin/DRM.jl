# Warm-workflow registry — S12 (#563), root gate G5

G5: "every registered warm workflow wins, or the loss is retained and named." This is the
registry that gate is scored against. A workflow is **registered** only once it appears in
the table below with a fixed fixture, formula, and leg definition; nothing else counts.

Built by Curie (benchmarks lane) — harness + registry construction, smoke pre-run only.
**No full sweep has been run.** The verdicts below (WIN/LOSS/N/A) come from a 2-workflow,
1-thread, 1-rep smoke run only (§ Smoke pre-run) — they are NOT the G5 evidence. The full
grid (all 10 workflows × 3 legs × k=3 reps × threads {1,2,4,8}) is the conductor's run on
an idle Mac (§ Estimate).

## 1. What "warm" means here

Per `LOOP/GOAL.md`'s definition (private worktree, paraphrased in the S12 scout report):
prep + data transfer + model construction + the requested uncertainty surface + return
conversion, timed **after** JIT/DLL warm-up (cold startup is a separate, unmeasured
concern here), at 1/2/4/8 threads. This harness decomposes that into three separately
timed **legs** per workflow:

- **fit** — the model-fitting call itself (`drm(...)` / `drmTMB(...)`).
- **uncertainty** — the package's DEFAULT SE/CI surface: `confint(fit)` on both sides,
  default method (`:wald` in Julia, `"wald"` in drmTMB — confirmed identical default from
  each package's own signature, not assumed).
- **predict** — `predict(fit, <training data>)` on both sides (drmTMB's `predict()`
  defaults `newdata = NULL`, i.e. also the training design, but this harness passes the
  training frame explicitly on both sides so the comparison is symmetric and not reliant
  on the R-only default).

Each leg gets ONE untimed warm-up call (absorbs JIT compilation / first-call overhead),
then `k` timed repetitions; the harness reports median and min wall-clock seconds per leg
(mirrors `tools/bench_fit_h2h.R`'s `time_median` convention).

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

## 3. The registry (10 workflows)

| id | family / model shape | fixture size | mean formula | scale/other formulas | method |
|---|---|---|---|---|---|
| `gauss_mixed_phylo_mean` | Gaussian, mixed (iid group) + phylo mean | 16 tips × 6 = 96 obs, 4 study groups | `y ~ x + (1\|study) + phylo(1\|species)` | `sigma ~ 1` | ML |
| `gauss_lss_sd_group` | Gaussian LSS, `sd(g)` (non-phylo scale RE) | 30 groups × 20 = 600 obs | `y ~ x + (1\|g)` | `sigma ~ z`, `sd(g) ~ z` | ML |
| `gauss_lss_sd_phylo` | Gaussian LSS, `sd(species, phylogenetic)` | 64 tips × 3 = 192 obs | `y ~ x + phylo(1\|species)` | `sigma ~ x`, `sd(species, phylogenetic) ~ x` | ML |
| `biv_q4_phylo_ml` | Bivariate Gaussian, q4 phylo (mu1,mu2), ML | 16 tips × 3 = 48 obs | `mu1 = y1 ~ x + phylo(1\|p\|species)`, `mu2 = y2 ~ x + phylo(1\|p\|species)` | `sigma1 ~ 1`, `sigma2 ~ 1`, `rho12 ~ 1` | ML |
| `biv_q4_phylo_reml` | same fixture, REML | (same as above) | (same as above) | (same as above) | REML |
| `bernoulli_mixed` | Binomial (Bernoulli, 0/1), mixed | 25 groups × 20 = 500 obs | `y ~ x + (1\|g)` | — | ML |
| `poisson_mixed` | Poisson, mixed | 25 groups × 20 = 500 obs | `y ~ x + (1\|g)` | — | ML |
| `lognormal_locscale` | LogNormal, location-scale | n=400 | `y ~ x` | `sigma ~ z` | ML |
| `meta_analysis_meta_V` | Gaussian meta-analysis, `meta_V(v)` | k=300 studies | `y ~ x + meta_V(v)` | `sigma ~ 1` | ML |
| `large_sparse_lss_p2000` | Gaussian LSS, `sd(species, phylogenetic)`, large p | 2048 tips × 2 = 4096 obs | `y ~ x + phylo(1\|species)` | `sigma ~ x`, `sd(species, phylogenetic) ~ x` | ML |

### DRM.jl calls (Julia, native `drm()`, never the R bridge)

```julia
# gauss_mixed_phylo_mean
f = bf(@formula(y ~ x + (1 | study) + phylo(1 | species)), @formula(sigma ~ 1))
drm(f, Gaussian(); data, tree)

# gauss_lss_sd_group
f = bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ z), @formula(sd(g) ~ z))
drm(f, Gaussian(); data)

# gauss_lss_sd_phylo
f = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
       @formula(sd(species, phylogenetic) ~ x))
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
       @formula(sd(species, phylogenetic) ~ x))
drm(f, Gaussian(); data, tree)     # algorithm = :auto -> dispatches to the O(p) sparse
                                    # route automatically once G > 500 (#551)
```

### drmTMB calls (R, native `drmTMB(..., engine = "tmb")`, never `engine = "julia"`)

```r
# gauss_mixed_phylo_mean
drmTMB(bf(y ~ x + (1 | study) + phylo(1 | species), sigma ~ 1),
       family = gaussian(), data = d, tree = tree, engine = "tmb")

# gauss_lss_sd_group
drmTMB(bf(y ~ x + (1 | g), sigma ~ z, sd(g) ~ z), family = gaussian(), data = d, engine = "tmb")

# gauss_lss_sd_phylo
drmTMB(bf(y ~ x + phylo(1 | species), sigma ~ x, sd(species, level = "phylogenetic") ~ x),
       family = gaussian(), data = d, tree = tree, engine = "tmb")

# biv_q4_phylo_ml / biv_q4_phylo_reml
drmTMB(bf(mu1 = y1 ~ x + phylo(1 | p | species), mu2 = y2 ~ x + phylo(1 | p | species),
          sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
       family = biv_gaussian(), data = d, tree = tree, REML = FALSE, engine = "tmb")  # or TRUE

# bernoulli_mixed
drmTMB(bf(y ~ x + (1 | g)), family = stats::binomial(), data = d, engine = "tmb")

# poisson_mixed
drmTMB(bf(y ~ x + (1 | g)), family = stats::poisson(), data = d, engine = "tmb")

# lognormal_locscale
drmTMB(bf(y ~ x, sigma ~ z), family = drmTMB::lognormal(), data = d, engine = "tmb")

# meta_analysis_meta_V
drmTMB(bf(y ~ x + meta_V(v), sigma ~ 1), family = stats::gaussian(), data = d, engine = "tmb")

# large_sparse_lss_p2000
drmTMB(bf(y ~ x + phylo(1 | species), sigma ~ x, sd(species, level = "phylogenetic") ~ x),
       family = gaussian(), data = d, tree = tree, engine = "tmb")   # NO sparse fast path
       # on the R side for this route (the O(p) sparse solver is DRM.jl-only, #551) --
       # this cell is a genuine dense-vs-sparse comparison, not a matched-algorithm one.
```

Every drmTMB call above uses only top-level `drmTMB()`/`bf()` arguments already exercised
by `tools/bench_fit_h2h.R` or the `sd()`/`sd_phylo()` fixtures in `test/fixtures/lsss/README.md`,
**except**: (a) `REML = TRUE` on a q4-phylo bivariate fit, and (b) `meta_V(v)` and
`sd(g, level = "phylogenetic")` used together with `drmTMB(..., engine = "tmb")` end-to-end in
one call (each piece is independently attested — meta_V in `test/test_meta.jl`'s cross-engine
provenance note and `library(drmTMB)`'s exported `meta_V` symbol; `sd(..., level=...)` in the
`test/fixtures/lsss/README.md` reference numbers — but the exact R call text above was not
independently executed against a live drmTMB session in this slice). **Flagged as unconfirmed
in the after-task reply.**

## 4. Legs each family supports (n/a is not a loss)

All ten workflows support all three legs on both engines (`fit`, `uncertainty` via
`confint()`, `predict` via `predict()`) — there is no leg here that either engine's own
grammar refuses. (Contrast `tools/bench_fit_h2h.R`'s `tmb_rejects` cells — Gamma/Beta/
Binomial phylo — which have NO fit-only R comparator at all; none of those families are in
this registry, so this table currently has zero N/A rows by construction. If a future
registered workflow needs one of those families, its N/A leg goes here, named, not silently
dropped.)

## 5. Smoke pre-run (D-139)

Run 2026-09-02, Mac, Julia 1.10.0, R 4.6.0 / drmTMB 0.7.0, `--threads 1 --reps 1`, workflows
`lognormal_locscale` and `poisson_mixed` only (the two smallest/simplest — no phylogenetic
tree, no LSS scale-scale submodel). **Host was NOT idle** (`uptime` load average ~26–45,
many sibling agent worktrees active) — these numbers are for harness validation and
order-of-magnitude estimation only, not a citable G5 verdict.

| workflow | leg | threads | R median (s) | Julia median (s) | ratio (R/Julia) | verdict |
|---|---|---|---|---|---|---|
| lognormal_locscale | fit | 1 | 0.033 | 0.0006 | 53.2x | julia faster |
| lognormal_locscale | uncertainty | 1 | 0.003 | 0.00003 | 120.0x | julia faster |
| lognormal_locscale | predict | 1 | 0.001 | 0.0001 | 8.7x | julia faster |
| poisson_mixed | fit | 1 | 0.102 | 0.005 | 20.6x | julia faster |
| poisson_mixed | uncertainty | 1 | 0.003 | 0.00002 | 125.0x | julia faster |
| poisson_mixed | predict | 1 | 0.0 (rounded) | 0.0001 | ~0x, unmeasurable | R faster/tied (measurement floor, not a real result) |

G5 verdict from this smoke subset only: `lognormal_locscale` WIN (all 3 legs); `poisson_mixed`
LOSS on `predict` — but that LOSS is an artifact of R's `proc.time()` millisecond-resolution
floor at `n_reps=1` (both predict calls run in well under 1ms; R rounds to `0.000000`), not a
real timing result. **The full run must use `n_reps=3` minimum (already the harness default)
and should not trust any leg's ratio when either side's raw time is at that measurement floor**
— `tools/warm_timing_compare.jl` does not currently suppress this case; a human/registry-reader
should treat any row with a near-zero raw time on either side as inconclusive, not as evidence.
Loglik cross-check: `lognormal_locscale` agreed to 6 d.p. (−579.649631 both engines);
`poisson_mixed` agreed to ~2 d.p. (−789.738234 Julia vs −789.759163 R) — both converged, small
residual disagreement consistent with two different Laplace-approximation optimizer paths, not
investigated further here (out of scope for a timing harness; a correctness parity slice would
re-check this if the gap is not already explained elsewhere).

## 6. Estimate for the full run (D-139, NOT run)

Formula: `T(threads) ≈ Σ_workflows Σ_legs (median_time × reps) + warm-up_time_per_workflow + process_restart_overhead`,
summed separately per engine, then the 4 thread counts are 4 independent process invocations
(BLAS/OpenMP thread counts are not always safely re-settable mid-session) so total wall time
is roughly `4 × (T_R(threads) + T_Julia(threads) + restart_overhead)`.

From the smoke measurements, the 9 non-`large_sparse_lss_p2000` workflows are all small
(n ≤ 600, p ≤ 64) and — extrapolating from the two measured plus `tools/bench_fit_h2h.R`'s own
Stage-2 estimate for similarly-sized cells (2–30ms fits, "well under 10 minutes" for its whole
13-cell grid at `n_reps=3`) — should cost on the order of **10–60 seconds combined (both
engines, all 3 legs, `k=3`) per thread setting**, dominated by R/Julia process startup and TMB
DLL/JIT warm-up, not fit cost.

`large_sparse_lss_p2000` is the dominant unknown and was deliberately NOT run in this smoke
pass (task scope: "2 small workflows" only). Its Julia leg should stay fast (the whole point of
the #551 O(p) sparse route — dispatches automatically at G=2048 > 500). Its **R leg has no
sparse fast path** — drmTMB would build a dense 2048×2048 phylogenetic covariance and its TMB
AD tape at that size, which is untested here and could plausibly range from tens of seconds to
many minutes (unlike `report/comparison-grid.md §3`'s q4 bivariate O(p) scaling grid, where R
was found comparable/faster at p≥1000 — that is a DIFFERENT model class (residual bivariate,
not scale-scale LSS) and does not transfer).

Putting it together: **~1–3 minutes per thread count for the 9 small workflows** (both
engines, generously bounded) **+ an unmeasured large-p R-side term** that could be seconds or
could be double-digit minutes. Four thread counts: **roughly 5–15 minutes if the large-p R fit
is fast, but potentially well over the D-139 30-minute line if it is not** — this is exactly
why a SECOND, targeted pre-run test (R and Julia, `large_sparse_lss_p2000` alone, `--threads 1
--reps 1`, generous timeout) is recommended before committing to the full 4-thread-count sweep,
not assumed from this estimate.

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
the `n_reps=1` measurement-floor issue.

## 8. Files

- `tools/warm_timing_fixtures.jl` — fixture generator (this registry's source of truth for
  sizes/seeds).
- `tools/warm_timing.jl` — Julia harness.
- `tools/warm_timing.R` — R harness.
- `tools/warm_timing_compare.jl` — joins the two TSVs, Markdown table + G5 verdict per workflow.
- `docs/dev-log/evidence/julia-r-parity/warm-fixtures/` — generated fixtures (CSV + Newick),
  committed so a re-run reads the exact same data without regenerating it.
