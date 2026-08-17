# S3 — experimentals minus `#428` (rows 7–9)

**Persona:** Hopper (conductor recon on Cursor Grok; no Task child).
**Date:** 2026-08-16. **Read-only.** Skip `cross_family_latent` ownership (S4).
**TSV:** drmTMB `origin/main` `d9fddfa28` (unchanged vs `097bed1e2`).

## 7. `phylo_count_large_p`

| Field | Value |
|---|---|
| claim_status | `experimental` |
| class | **smoke-only** |
| claim_boundary | "Large-p phylogenetic random-intercept route; Workflow G FE count cells also route via live `expected.toml` parity (#499)." |
| next_action | Keep phylo count smoke + Workflow G FE parity tests; do not promote beyond experimental. |
| existing fixture | Julia smoke: `test/test_poisson_phylo_laplace.jl`, `test/test_nb2_phylo_laplace.jl`. Workflow G FE (not phylo): `test/parity/fixtures/count-poisson/expected.toml`, `test/parity/fixtures/count-nbinom2/expected.toml`. **NONE** as a large-p same-target phylo-count fixture. |
| twin map | **YES** (`poisson()` / `nbinom2()` + `phylo()`). Capability-and-limits: structured count `mu` is recovery-only, not a coverage twin. |
| collision | Soft: `#425` touches sparse Laplace / binomial. Do not edit those files. |
| later implement? | No — smoke + FE fixtures exist; large-p evidence is not a missing family port. Not cheaper than the q4 REML fixture-gap. |

## 8. `phylo_gamma_beta_binomial`

| Field | Value |
|---|---|
| claim_status | `experimental` |
| class | **smoke-only** (comparator started; do not promote) |
| claim_boundary | "Finite-and-sane bridge smoke evidence only; no native TMB parity or non-phylo binomial bridge promotion." |
| next_action | Add comparator or parity evidence before promoting beyond experimental. |
| existing fixture | `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` + `tools/parity_phylo_nongaussian.R` + `docs/dev-log/evidence/2026-08-15-a5-nongaussian-phylo-parity.md`. Measured: `phylo_gamma` **PARITY_FAIL** (ll\|d\| 1.016e-04 vs tol 1e-4); `phylo_beta` **PARITY_PASS**; `phylo_binomial` **NO_NATIVE_COMPARATOR** (drmTMB refuses structured binomial). Julia: `test/test_gamma_beta_phylo_laplace.jl`, `test/test_binomial_phylo_laplace.jl`. |
| twin map | **YES / NO split** — Gamma/beta + `phylo()` YES; public fitted `binomial()` + `phylo()` **NO**. Do not invent a binomial-phylo twin. |
| collision | Soft: `#425` binomial structured-marker refusal. drmTMB `#1048` is upstream, not this lane. |
| later implement? | No for *first* later slice. Comparator already exists and is mixed (fail / pass / no twin). Promoting would invent a binomial-phylo Δ. Candidate #2 only after the q4 fixture, and only for Gamma/beta within tolerance — new G0. |

## 9. `general_covariance_structured`

| Field | Value |
|---|---|
| claim_status | `experimental` |
| class | **smoke-only** (family-vs-gate audit exists; widening is a claim) |
| claim_boundary | "Requires covariance/relatedness matrix `K` and `sigma ~ 1`; beta, precision `Q`, and sigma predictors stay gated." |
| next_action | Compare current DRM.jl accepted families with the R gate before widening. Comparison now exists: `docs/dev-log/evidence/2026-08-16-a9-general-covariance-audit.md` + `tools/parity_ledger.py`. |
| existing fixture | Audit note above. Julia structured q4/relmat tests: `test/test_gaussian_bivariate_q4_structured.jl`. **NONE** as a Workflow G `expected.toml` for `relmat()`. |
| twin map | **YES** (`relmat()`; vignette `relmat-known-matrices`). TSV neighbours `beta` / `Q` / `sigma ~ x` stay gated. Audit found DRM.jl beta+`relmat` fits while drmTMB refuses — do **not** invent that twin. |
| collision | none of the open PRs own this ID. |
| later implement? | No. Audit already answers `next_action`. Widening or a beta+relmat "Δ" is forbidden (D-94 / Rose fence). |

## Batch verdict

No row here is the recommended first later implement. `#428` ownership is S4.
