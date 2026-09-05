# Authoritative benchmarks — and a bootstrap correctness finding

**Date:** 2026-08-24 · **Branch:** `parity/se-axis` · **Issue:** #457
**Machine:** Apple M1 Ultra, 20 cores · **R** 4.6.0 · **drmTMB** 0.7.0 (installed) ·
**Julia** 1.10.0 · **JuliaCall** 0.17.6

Supersedes the provisional figures in `2026-08-24-fit-speed-h2h.md` and
`2026-08-24-bootstrap-h2h.md`, which were measured under heavy contention.

## Load conditions (recorded, not assumed)

Not a pristine machine. One orphaned `Pkg.test()` pinned a single core throughout;
19 of 20 cores were free, and `busy procs (>50% cpu) = 1` before each run. Load
averages read 14–25, dominated by a decaying 15-minute average. This is materially
different from the earlier contaminated window (8 concurrent `julia` processes,
load ~23), but it is **not** an idle machine, and every number below should be read
with that caveat. Absolute times are milliseconds; ratios are the durable part.

## 1. Single-fit head-to-head — the owner's expectation CONFIRMED

`tools/bench_fit_h2h.R`, installed drmTMB 0.7.0, median of 3 reps, both engines
driven through the same `drmTMB(engine = "tmb" | "julia")` entry point.

| cell | n | p | tmb (s) | julia (s) | ratio | logLik |
|---|---|---|---|---|---|---|
| Gaussian location-scale | 100 | — | 0.0150 | 0.0020 | **7.5×** | agree |
| Gaussian location-scale | 1000 | — | 0.0250 | 0.0020 | **12.5×** | agree |
| Bivariate Gaussian (rho12) | 100 | — | 0.0140 | 0.0020 | **7.0×** | agree |
| Bivariate Gaussian (rho12) | 1000 | — | 0.0250 | 0.0050 | **5.0×** | agree |
| Biv Gaussian q2 phylo | 36 | 12 | 0.0510 | 0.0230 | **2.2×** | agree |
| Poisson phylo | 72 | 12 | 0.0250 | 0.0030 | **8.3×** | agree |
| Poisson phylo | 240 | 40 | 0.0320 | 0.0060 | **5.3×** | agree |
| NegBinomial2 phylo | 72 | 12 | 0.0760 | 0.0070 | **10.9×** | agree, Δ=1.7e-06 |
| Bivariate lognormal (direct) | 500 | — | 0.0220 | 0.0030 | **7.3×** | Δ=7.4e-12 |
| Bivariate Student-t (direct) | 800 | — | 0.0500 | 0.0090 | **5.6×** | Δ=1.0e-09 |

**DRM.jl is faster on every comparable cell, by 2.2× to 12.5×**, and the two engines
land on the same logLik everywhere. The owner's expectation — "Julia is faster for
almost everything" — is supported by this grid.

Read the caveats with it:

- **Absolute times are 2–76 ms.** At that scale fixed overheads matter and the
  ratios should not be extrapolated to large problems. The largest cell here is
  n=240/p=40. A ratio measured at milliseconds is not evidence about an hour-long fit.
- **Julia's one-time startup is real and excluded from these figures:** 3.7–8.1 s
  per session. A user fitting one model pays it; a user fitting many does not.
- **Three cells have NO native comparator:** Gamma, Beta and Binomial with `phylo()`
  are refused by native TMB ("structured-effect syntax is planned, not implemented").
  DRM.jl fits all three. That is a capability gap in the R twin, not a speed result,
  and it is kept out of the ratio table rather than folded in as a win.
- **The last two rows bypass the bridge** (direct DRM.jl call), which removes
  marshalling cost from the Julia side and therefore flatters it. Labelled
  `julia_direct` in the TSV.
- **The mechanism is still unattributed.** `fit$bridge$iterations` is `NA` for every
  Julia cell, so iteration counts do not cross the bridge. TMB reports 5–55
  iterations. Both sides are gradient-based quasi-Newton (nlminb vs LBFGS), so this
  is **not** an optimizer-family contrast, and the "better optimizers" hypothesis
  remains untested. Until iteration counts are exposed, the honest statement is that
  DRM.jl is faster here, not *why*.
- One cell emitted a DRM.jl warning worth noting: NegBinomial2 phylo reported
  *"finite-difference Hessian is not positive definite at the optimum; reported SEs
  are not trustworthy"* (`sparse_laplace_glmm.jl:123`). Timing unaffected; relevant
  to the SE axis.

## 2. Bootstrap head-to-head — NOT a speed win, and a correctness finding

`tools/bench_bootstrap.R`, B=200, seed 20260824, n_species=100, target
`sd:mu:phylo(1 | species)` — the only target `confint.drmTMB_julia()` supports for
bootstrap (`drmTMB/R/julia-bridge.R:2275`).

| engine | bootstrap elapsed | sec/refit | interval | width |
|---|---|---|---|---|
| tmb | 16.40 s | 0.0820 | [1.027252, 1.450820] | **0.4236** |
| julia | 23.20 s | 0.1160 | [1.300189, 1.300442] | **0.000253** |

**TMB is 1.41× faster per refit here** — the opposite of the single-fit result, and
the owner's bootstrap expectation is **not** supported by this measurement.

**But the speed comparison is the less important half.** The intervals do not agree:

```
TMB   interval width       0.423568
Julia interval width       0.000253      ->  1674x narrower
implied replicate SD  tmb  ~ 0.108
implied replicate SD  julia ~ 6.45e-05
```

Same data, same B, same seed, same target, same point estimate (1.30027 vs
1.300259). A parametric bootstrap of a phylogenetic SD at n=100 producing a CI of
width 2.5e-4 is not plausible; DRM.jl's bootstrap replicates are barely varying.

**This is a correctness finding, not a performance one, and it is the reason this
slice refuses to report a bootstrap speed headline.** A faster bootstrap that does
not reproduce the sampling distribution is not faster at the same thing. Mechanism
not yet established — filed for investigation rather than diagnosed here.

## 3. A methodological defect found while doing this

`tools/bench_bootstrap.R` originally called `devtools::load_all(drmtmb_path)`,
loading drmTMB **from the source tree** rather than the installed package. That tree
sits on branch `claude/handover-freshness-0718` with 102 uncommitted files, and a
different lane was concurrently running `devtools::test()` against it — so the code
under measurement could change mid-run. The banner printed `drmTMB: 0.6.0.9000`
while the installed package was 0.7.0.

Fixed to `library(drmTMB)`, matching every other parity script in this repo, and the
run above is against the installed 0.7.0. The contaminated run is retained in
`bootstrap-h2h.tsv` history but must not be cited.

Related, fixed in the same pass: `tools/parity_fixture.R` **hardcoded** the string
`"drmTMB 0.7.0"` into its evidence note rather than measuring it. It now records
`packageVersion("drmTMB")`. A TSV that asserts a version it never checked would have
recorded "0.7.0" throughout the window in which 0.6.0.9000 was on the path.

## What may and may not be claimed

**May:** DRM.jl fits 2.2–12.5× faster than drmTMB on the ten cells above, at n≤1000
and p≤40, with logLik agreement, on this machine, at these sizes.

**May not:** any general "Nx faster" headline; any extrapolation to large problems;
any attribution to the optimizer; any bootstrap speed claim; any statement that the
two bootstrap implementations agree.

---

## UPDATE (same day) — the bootstrap defect in §2 is FIXED

§2 above reported the bootstrap intervals disagreeing by 1674× and TMB winning on
speed. Both statements described a real measurement, and both are now superseded.

**Two stacked defects, the first hiding the second.**

1. **#459 — the simulator was conditional.** `_bootstrap_result` called
   `simulate(fit0)`, which returns `fit.means[:mu] .+ sigma .* randn(n)`, and
   `fit.means[:mu]` already contains the fitted BLUPs. Every replicate re-used the
   same realised random effects, so the refitted variance component never moved.
   Fixed by `_marginal_simulator`, which redraws the random effects and adds them to
   the *fixed*-effect mean — the pattern `bootstrap_q4_phylo.jl` already used.
2. **#461 — a degenerate optimum reported convergence.** With one row per group the
   Gaussian likelihood is unbounded as the residual scale → 0; `Optim.converged`
   returns `true` at `sigma = 7.5e-15`, `loglik = 6.8e13`, `sd_phylo = 22980`. This
   was invisible until (1) was fixed, because the degenerate simulator made every
   refit converge trivially. Fixed by checking degeneracy in `is_converged`.

**Final state on the same cell (B=200, seed 20260824, installed drmTMB 0.7.0):**

| engine | interval | width | sec/refit | used / failed |
|---|---|---|---|---|
| tmb | [1.027252, 1.450820] | 0.4236 | 0.0581 | 200 / 0 |
| julia | [1.045239, 1.416228] | 0.3710 | 0.0572 | 190 / 10 |

Width ratio **0.88**, per-refit speed ratio **1.017**. So the corrected reading is:
**the bootstrap implementations agree, and per-refit speed is at parity** — not the
"TMB 1.41× faster, intervals 1674× apart" recorded in §2.

The 10 dropped replicates are degenerate refits, now excluded *and counted* rather
than silently admitted.

**§1 (single-fit speed) is unaffected** — those numbers stand as measured.
