# Hopper twin-map — Arc 1 (11 non-`supported` ledger rows)

Date: 2026-08-16 · persona: **Hopper** (read-only) · no spawned subagents
Lane: scratch `DRM.jl-catchup` evidence only. drmTMB read via `git show origin/main:…` — **no checkout**, no worktree.

## Command / anchor

```bash
cd /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
python3 tools/parity_ledger.py \
  --drmtmb "/Users/z3437171/Dropbox/Github Local/drmTMB" \
  --ref origin/main
```

drmTMB **0.7.0** @ `origin/main` `097bed1e2`. Twin checkout stayed on leftover `claude/handover-freshness-0718` (untouched).

Ledger phrase **"11 unsupported capability rows"** = `claim_status != "supported"` (6 partial · 4 experimental · 1 unsupported). Zero rows are `supported`. Same 11 IDs as `docs/dev-log/evidence/2026-08-16-arc1-eleven-rows.md`.

Question per row: does drmTMB 0.7.0 have a **public** surface (exported function / pkgdown vignette / NEWS) that a Julia twin would need to match? Do not invent support. **UNKNOWN** if the ledger row does not clearly map onto that surface.

## One line each (11)

1. `base_gaussian_location_scale` (partial) — **YES**: `drmTMB()` + `bf(y ~ x, sigma ~ z)` + `gaussian()`; vignettes `location-scale`, `location-scale-scale`, `drmTMB`; man `drmTMB` / `drm_formula`.
2. `biv_gaussian_residual` (partial) — **YES**: `biv_gaussian()` + `rho12()` + `bf(mu1=, mu2=, sigma1=, sigma2=, rho12=)`; vignette `bivariate-coscale`; man `biv_gaussian` / `rho12`.
3. `gaussian_phylo_mean` (partial) — **YES**: `phylo()`; vignettes `phylogenetic-models`, `structural-dependence`; man `phylo`; capability-and-limits lists Gaussian phylo `mu` as inference-ready.
4. `gaussian_response_mask` (partial) — **YES**: `miss_control(response = "include")`; vignette `missing-data`; man `miss_control`. Predictor `mi()` / `impute` is a different surface (#49 PARKED) — not this row.
5. `biv_q4_phylo_reml` (partial) — **YES**: `drmTMB(..., REML = TRUE)` + four-axis `phylo()` + `biv_gaussian()`; man `drmTMB` REML; vignettes `phylogenetic-models` / `bivariate-coscale`; NEWS 0.7.0 records Julia `REML=TRUE` forwarding for one q4 cell. TSV: native TMB q4 REML ≠ this Julia row; do not invent AI-REML / interval coverage as the twin.
6. `plain_binomial_nonphylo` (partial) — **YES**: `stats::binomial()` via `drmTMB()`; vignette `proportion-beta-binomial`; NEWS 0.7.0 binomial links + Workflow G `engine = "julia"` FE gate (#499).
7. `phylo_count_large_p` (experimental) — **YES**: `poisson()` / `nbinom2()` + `phylo()`; vignettes `count-nbinom2`, `phylogenetic-models`, `large-data`; capability-and-limits: structured count `mu` is recovery-only (not a coverage twin).
8. `phylo_gamma_beta_binomial` (experimental) — **YES** for Gamma/beta + `phylo()` (formula-grammar, `phylogenetic-models`, NEWS Arc 3a recovery gates); **NO** public fitted `binomial()` + `phylo()` route (capability-and-limits: binomial structured "not generally available"; NEWS first-slice structured binomial unsupported). Do not invent a binomial-phylo twin.
9. `general_covariance_structured` (experimental) — **YES**: `relmat()`; vignette `relmat-known-matrices`; man `relmat`. TSV neighbours `beta` / `Q` / `sigma ~ x` stay gated — documented as limits, not as fitted twins.
10. `cross_family_latent` (experimental) — **UNKNOWN** whether this row twins native staged association (`associate_pairs()` / `association()` / `latent_normal()`; vignette `cross-family`; NEWS 0.7.0) or a future joint `c(gaussian(), poisson())` fit. `rho_latent()` man: legacy extractor only; NEWS: Julia xfam fitting deferred. Do not invent equivalence.
11. `engine_control_surface` (unsupported) — **NO** public surface to match: no exported `engine_control()` (not in NAMESPACE); `julia-engine` vignette does not document it; `drm_control()` is TMB/`nlminb` only. Reserved/gated in `R/julia-bridge.R` + TSV ("no R surface by design"). Needs an R API first — not a Julia port.

## Counts

| Verdict | n | IDs |
|---|---|---|
| YES (public twin target) | 8 | rows 1–7, 9 |
| YES / NO split inside one row | 1 | `phylo_gamma_beta_binomial` (Gamma/beta yes; binomial+phylo no) |
| UNKNOWN | 1 | `cross_family_latent` |
| NO | 1 | `engine_control_surface` |

**11 rows mapped.** Promoting any row to `supported` remains a drmTMB TSV claim (STOP GATE), not a DRM.jl export. COUNTDOWN 0 is export-name honesty, not a public twin claim.

Sources (all `git show origin/main:…`): `inst/extdata/julia-capabilities.tsv`, `NAMESPACE`, `_pkgdown.yml`, `NEWS.md`, `man/{drmTMB,drm_formula,drm_control,biv_gaussian,rho12,phylo,miss_control,relmat,rho_latent}.Rd`, vignettes named above. No GPL source copied.
