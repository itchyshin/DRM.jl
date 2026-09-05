# Arc 1 inventory — 11 non-`supported` capability rows (2026-08-16)

Date: 2026-08-16 · read-only · scratch `DRM.jl-catchup` · `tools/parity_ledger.py --drmtmb drmTMB --ref origin/main`
drmTMB **0.7.0** @ `origin/main` (`097bed1e2`) · DRM.jl exports **154**

## Countdown

COUNTDOWN: 0 export gaps (18 raw, 18 accounted for) · 11 unsupported capability rows · 14 closed gates

CLOSURE: PASS — every one of 11 capability rows is supported or carries a written claim_boundary; all 14 closed gates carry evidence + review_due

The ledger phrase **"11 unsupported capability rows"** means `claim_status != "supported"` (6 partial · 4 experimental · 1 unsupported). Zero rows are `supported`.

## The 11 rows

| # | capability_id | claim_status | claim_boundary |
|---|---|---|---|
| 1 | `base_gaussian_location_scale` | partial | Phase 1.5 Hopper admitted cell (Route C): offline result-shape + optional live TMB parity; CRAN readers still use TMB — vignette keeps Julia deferred/experimental. |
| 2 | `biv_gaussian_residual` | partial | Phase 1.5 Hopper admitted cell (Route B): residual rho12 result-shape + optional live logLik parity; not a phylo or cross-family claim. |
| 3 | `gaussian_phylo_mean` | partial | Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (`sigma ~ 1`) marshalling/result-shape + optional live TMB parity; not loc-scale phylo or non-Gaussian phylo. |
| 4 | `gaussian_response_mask` | partial | Gaussian-only response masks; missing predictors and non-Gaussian response masks remain gated. |
| 5 | `biv_q4_phylo_reml` | partial | Requires the full four-axis phylogenetic location-scale grammar; native TMB has separate q4 recovery evidence, but this Julia row does not establish same-target bridge parity, interval reliability, or HSquared AI-REML support. |
| 6 | `plain_binomial_nonphylo` | partial | Live R Workflow G binomial-trials cell vs DRM.jl `expected.toml`; still experimental, not a CRAN default. |
| 7 | `phylo_count_large_p` | experimental | Large-p phylogenetic random-intercept route; Workflow G FE count cells also route via live `expected.toml` parity (#499). |
| 8 | `phylo_gamma_beta_binomial` | experimental | Finite-and-sane bridge smoke evidence only; no native TMB parity or non-phylo binomial bridge promotion. |
| 9 | `general_covariance_structured` | experimental | Requires covariance/relatedness matrix `K` and `sigma ~ 1`; beta, precision `Q`, and sigma predictors stay gated. |
| 10 | `cross_family_latent` | experimental | Latent-rho development route; public docs must not present rho12 formulas or release-ready cross-family inference. |
| 11 | `engine_control_surface` | unsupported | Do not document user-selectable Julia optimizer controls until a real R API is designed. |

`claim_boundary` from `git show origin/main:inst/extdata/julia-capabilities.tsv` (drmTMB). Same 11 rows as `docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md`; drmTMB tip moved `9e42d2c94` → `097bed1e2` with no status flip.

## What Arc 1 is

Arc 1 is the inventory of these 11 rows turned into an ordered backlog — not a claim that R↔Julia parity is complete.
