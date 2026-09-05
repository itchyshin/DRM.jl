# S1 recon — `biv_q4_phylo_reml` same-target calls

**Date:** 2026-08-16 · **Persona:** Hopper (Shannon conducting) · no nested Task children
**Lane:** `claude/lane-biv-q4-phylo-reml` @ scratch `DRM.jl-biv-q4-phylo-reml`
**Issue:** #433
**Anchors:** DRM.jl `origin/main` `2209ecd8`. drmTMB `origin/main` `d9fddfa28` via `git show` — **no drmTMB checkout**. Shared tree stayed on leftover `claude/handover-freshness-0718`.
**License:** NEWS / man / test *names* only. No GPL source copied.

Sibling scout already on catchup (`2026-08-16-biv-q4-phylo-reml-fixture-scout.md`) is cited, not rewritten.

---

## Verdict (one line)

The twin is **native TMB** `drmTMB(..., REML = TRUE, engine = "tmb")` + four-axis labelled `phylo()` + `biv_gaussian()`, versus DRM.jl `drm(..., method = :REML, tree=)`. The halted `engine = "julia"` bridge is **not** this cell.

---

## Exact Julia call (public, already on tip)

From `test/test_reml_q4_allaxes.jl` (property test; no drmTMB numbers):

```julia
form = bf(mu1    = @formula(y1 ~ x + phylo(1 | species)),
          mu2    = @formula(y2 ~ x + phylo(1 | species)),
          sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
          sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
          rho12  = @formula(rho12 ~ 1))
frl = drm(form, Gaussian(); data = dat, tree = phy, method = :REML, q4_vcov = false)
```

`tree` may be an `AugmentedPhy` or a Newick string (`_as_augmented_phy`). Accessors: `loglik` / `reml_loglik`, `estimation_method` → `:REML`, `is_converged`, `coef` via `drm_coef_named` flat keys.

---

## Exact R call (native TMB; names from `git show`)

From `tests/testthat/test-reml-bivariate.R` (dense q4 admission + recovery-grade port). Shared label `p` on all four axes is the dense q4 layout:

```r
form <- bf(
  mu1    = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2    = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = sigma1 ~ 1 + phylo(1 | p | species, tree = tree),
  sigma2 = sigma2 ~ 1 + phylo(1 | p | species, tree = tree),
  rho12  = rho12 ~ 1
)
fit <- drmTMB(form, family = biv_gaussian(), data = dat,
              REML = TRUE, engine = "tmb",
              control = drm_control(optimizer_preset = "robust"))
```

Status names used in that test (do not vendor implementation): `fit$estimator`, `fit$opt$convergence`. TSV `next_action` wants fit-specific CI/status (`pdHess` / interval_status) recorded, not coverage.

---

## What drmTMB outputs exist (read-only)

| Surface | Finding |
|---|---|
| TSV `biv_q4_phylo_reml` | `claim_status=partial`, `r_bridge_status=experimental`, issue drmTMB#544. `claim_boundary` forbids same-target *bridge* parity, interval reliability, HSquared AI-REML. |
| `man/drmTMB.Rd` | `engine = "julia"` **halted**; not a supported REML route. Use native `engine = "tmb"`. |
| NEWS 0.7.0 | Native TMB bivariate Gaussian REML admits phylogenetic layouts including the **dense q4 block**. Recovery-grade wants roughly `n_tip >= 200`, `n_each >= 10`. That is a **different estimand** than this Mac-small same-target cell. |
| NEWS / #544 | Julia `REML=TRUE` *forwarding* for one q4 cell is bridge history. Man page now says that bridge is halted. **Do not** generate this fixture via `engine = "julia"`. |
| Workflow G fixtures | **NONE** `*q4*` / `*reml*` / `*phylo*`. Runner is ML / no `tree=`. New path required. |

---

## G0 compute (binding)

Mac-only small cell: **p≈16, n_each≈5, seed recorded**. If either side fails to converge, shrink/reseed and record. Do not silently jump to Totoro recovery-grade.

Risk (Curie / NEWS): dense q4 at p=16 can be `diagnostic_only` / non-converged on native TMB. A non-converged cell is not same-target evidence.

---

## Not this slice

TSV `supported` · `engine = "julia"` bridge rewrite · `test_bridge_q4_direct_export.jl` claim drop · AI-REML · interval coverage · `src/` · `runtests.jl` · Workflow G glob.

`PLATFORM: cursor | ON BRANCH: claude/lane-biv-q4-phylo-reml | LANE: feat-biv-q4-phylo-reml-fixture`
`OTHER LANES: #429 A12 · #428 A11 · #425 A10 · #423 A8 · #421 · #420 · #406 · main-direct · leftover docs/a3c-design · #432 merged`
