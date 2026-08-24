# Bootstrap head-to-head: drmTMB engine="tmb" vs engine="julia" — Stage 1 (pre-run test)

Lane: Curie (performance), branch `parity/se-axis`.
Script: `tools/bench_bootstrap.R` (this repo).
Raw rows: `docs/dev-log/evidence/bootstrap-h2h.tsv`.

## Status: Stage 1 only — DO NOT cite the timing numbers below as a performance claim

Per a same-session coordinator amendment (2026-08-24), five sibling agents were running
concurrent R + Julia sessions on this machine while this test ran. The timing numbers
in this document are **PROVISIONAL** and must not be published or generalised. Stage 2
(the authoritative timing run on a quiet machine) has not been run yet.

## What this compares

drmTMB's own public bootstrap entry point, `stats::confint(fit, method = "bootstrap",
...)`, dispatched on the class of the fitted object — `drmTMB` (native TMB, via
`engine = "tmb"`) vs `drmTMB_julia` (via `engine = "julia"`, which forwards to
`DRM.drm_bridge` in this repo). **Both engines are driven through the identical public
drmTMB entry point** — this is a true same-target, bridge-included comparison, not a
bridge-vs-direct-call comparison. (`confint.drmTMB_julia()` currently supports
bootstrap only for the Gaussian phylogenetic SD target — see
`drmTMB/R/julia-bridge.R:2275` — so the DGP below is the phylogenetic Gaussian
regression drmTMB's own `tools/benchmark-r-julia-bootstrap-refits.R` already uses,
scaled down for a fast pre-run test.)

## DGP, n, B, seed

- Data: AVONET / Hackett phylogenetic tree, subset to the first `n_species` tree tips
  with complete AVONET records (deterministic subset, same selection logic as
  drmTMB's own benchmark script).
- Model: `bf(log_mass ~ hand_wing_z + beak_z + phylo(1 | species, tree = tree), sigma ~ 1)`,
  `family = gaussian()`.
- n_species = 100 (rows = 100).
- B = 5 (D-139 pre-run test size).
- seed = 20260824.
- Target: `sd:mu:phylo(1 | species)` (the phylogenetic SD on the mean axis) — the one
  target both engines' bootstrap paths currently support.

## Machine state (recorded at time of run — NOT quiet)

```
$ ps ax | grep -c "[R]script"    -> 2
$ ps ax | grep -c "[j]ulia"      -> 8
$ uptime                          -> load averages: 23.43 24.01 22.27  (20 cores, hw.ncpu=20)
$ sysctl -n machdep.cpu.brand_string -> Apple M1 Ultra
```

Load average >20 on a 20-core machine, concurrent with five sibling agents' own R/Julia
sessions (parity refresh, SE-axis build, phylo-gamma diagnosis, chip audit, and a
general fit-speed benchmark). Any wall-clock number below is contaminated by that
contention and is reported only to satisfy the D-139 pre-run-test requirement (confirm
both paths work, get *a* number to extrapolate cost from) — not as a performance
finding.

## D-139 pre-run test result (B = 5)

| engine | base_fit_s | bootstrap B=5 elapsed_s | sec/refit | used/failed | interval (95%) |
|---|---|---|---|---|---|
| tmb   | 0.292  | 2.263 | 0.453 | 5/0 | [1.300263, 1.300271] |
| julia | 12.486 (first call, includes JIT compile) | 4.170 | 0.834 | 5/0 | [1.300260, 1.300277] |

Julia one-time startup (`JuliaCall::julia_setup()`, measured separately, **excluded**
from the fit/bootstrap timings above): **3.360 s**. This is a real cost a user pays
once per R session and is reported here, not hidden.

Both engines: 5/5 successful refits, all finite, all in-range (SD > 0, as expected for
a boundary-honest interval on data with real phylogenetic signal).

**Provisional sec/refit ratio (tmb / julia) at this load: 0.543** — i.e. under this
particular (heavily contended) run, the TMB path was faster per refit, the opposite of
the owner's expectation. This is exactly why the number is not being published as a
finding: five other agents were consuming ~20+ of 20 cores throughout, and TMB (BLAS
via TMB's C++ Cholesky) vs Julia (openBLAS + JIT'd Julia refit path) likely respond
differently to core starvation. It says nothing yet about the uncontended case.

### Extrapolation to B = 200 (for planning only, not a scheduled run)

- TMB: 200 × 0.453 s ≈ 90.5 s (~1.5 min)
- Julia: 200 × 0.834 s ≈ 166.8 s (~2.8 min), plus ~3.4 s one-time startup

Both comfortably under the D-139 30-minute line even at this (contaminated) per-refit
rate, so a B = 200 authoritative run is not a long-running-job concern — the blocker is
purely machine quietness, not wall-clock budget.

## Interval agreement (this is the part unaffected by CPU load — treat as final)

| engine | lower | upper | width |
|---|---|---|---|
| tmb   | 1.300263 | 1.300271 | 8.3e-6 |
| julia | 1.300260 | 1.300277 | 1.7e-5 |

The two engines' bootstrap percentile intervals for `sd:mu:phylo(1 | species)` overlap
almost completely and agree to 5 decimal places at B = 5 — both intervals sit inside
roughly [1.30026, 1.30028]. Note both intervals are extremely tight because at n = 100
with strong phylogenetic signal, all 5 replicate refits under this seed land within
~2e-5 of each other; this is a property of this small pre-run sample (B = 5), not
necessarily representative of interval width at B = 200. At this sample size there is
no sign of engine disagreement — no scale mismatch, no boundary artefact, no divergent
refit behaviour.

(Aside: the Julia engine emits a one-time warning that the raw tree height is
113.25 — not 1 — and that the *internal* raw-branch-length `sd_phylo` representation is
therefore a factor sqrt(113.25) ≈ 10.64 away from R's correlation-scale
representation. This is purely an internal-representation note; the **reported**
`estimate`/`lower`/`upper` values above are already on the same response scale in both
engines, as the near-identical intervals confirm.)

## Driven through the bridge or direct JuliaCall?

Through the bridge. Every Julia-side number above comes from
`drmTMB(..., engine = "julia")` + `confint(fit, method = "bootstrap", ...)`, i.e. the R
package's own public Julia-engine entry point (`confint.drmTMB_julia()` in
`drmTMB/R/julia-bridge.R`), not a direct `JuliaCall::julia_call(...)` into
`DRM.bootstrap_*` bypassing the bridge. This is the true same-target comparison the
task asked for; it does **not** flatter Julia by stripping the bridge overhead.

## Verdict (Stage 1 only)

Correctness: PASS. Both engines produce non-empty, finite, in-range bootstrap output
through the identical public entry point, and their intervals agree closely at this n
and B.

Performance: NOT YET DETERMINED. The one number collected (ratio 0.543, TMB faster per
refit) was measured on a machine at >100% load from five concurrent sibling sessions
and must not be read as evidence either for or against the owner's "Julia should win
bootstrapping" expectation. Stage 2 — the authoritative timing run — is pending machine
quietness and coordinator go-ahead; it is not scheduled by this document.

If/when Stage 2 runs, per the coordinator's framing: the interesting question is not
whether Julia wins by roughly the single-fit ratio (expected, uninteresting) but
whether the bootstrap ratio *exceeds* the single-fit ratio — evidence that the Julia
path avoids some per-replicate marshalling cost the R↔TMB path pays every refit. This
run's `base_fit_s` values (tmb 0.292 s vs julia 12.486 s, the latter dominated by
one-time JIT, not representative of steady-state per-fit cost) are not a valid
single-fit baseline for that comparison; that comparison belongs to whatever
`base_fit_s` W2F-fit-speed measures on a quiet machine.
