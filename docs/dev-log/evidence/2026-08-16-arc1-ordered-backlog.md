# Arc 1 ordered backlog — 11 unsigned ledger rows (2026-08-16)

**Lane:** `docs-arc1-inventory` · Ada consolidate (S5) + Rose (S6) + count (S7).
**Platform:** Cursor Grok. No Opus/Sol/Other Models. No Task children (conductor recon).
**Inventory only.** No `src/`. No TSV `supported` flip. Implement of any row = **new G0**.

Phrase: *export-gap countdown at 0; 11 rows still unsigned.*
Zero rows are `supported`. Split: 6 `partial` · 4 `experimental` · 1 `unsupported`.
drmTMB TSV tip this pass: `origin/main` `d9fddfa28`. Unchanged vs eleven-rows
`097bed1e2` (empty TSV diff). DRM.jl exports 154. COUNTDOWN 0 ≠ parity complete.

Sources: S1–S4 batch notes plus parallel recon `2026-08-16-arc1-recon-s{1,3,4}.md` (no s2 — covered by `batch-partials-rest`); eleven-rows; Rose fence; Hopper
twin-map; Shannon collisions. Class vocabulary from the approved ultra-plan.

---

## Recommended first *later* implement slice

**`biv_q4_phylo_reml`** — class `fixture-gap`.

**Why:** the q4 REML engine is already implemented (Scoreboard B;
`test/test_reml_q4_allaxes.jl`). The ledger row is `partial` because there is
**no native-vs-Julia same-target bridge fixture** (coef + logLik +
fit-specific CI/status). `test/test_bridge_q4_direct_export.jl` currently
asserts `"no R-via-Julia q4 bridge parity"`. That is a DRM.jl cell, not a
drmTMB TSV flip.

**Not this slice:** `#428` / `cross_family_latent` (owned skip) · `#136` VA
(OPEN) · `#49` (PARKED) · `engine_control_surface` (fence) · rows 1–3 or 6
(TSV-claim) · a TSV `supported` flip.

**Requires a new G0.** This inventory does not implement it.

---

## Ordered list (cheapest honest next cell first; owned/fence last)

Order is *what a later implement G0 should look at first*, not a claim that
any row is `supported`.

| ord | capability_id | claim_status | class | twin | fixture | next_action (abbrev.) | why this rank |
|---|---|---|---|---|---|---|---|
| 1 | `biv_q4_phylo_reml` | partial | **fixture-gap** | YES | **NONE** same-target; Julia REML exists (`test/test_reml_q4_allaxes.jl`); bridge export refuses parity (`test/test_bridge_q4_direct_export.jl`) | Bank fit-specific CI/status parity before release language | Already-implemented engine; missing same-target fixture. Recommended later slice. |
| 2 | `phylo_gamma_beta_binomial` | experimental | **smoke-only** (S3 recon also: **TSV-claim** — comparator already exists) | YES/NO | `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` (gamma FAIL · beta PASS · binomial NO_NATIVE_COMPARATOR) | Add comparator — **evidence-complete**; promotion is a drmTMB claim | Not an implement slice. Do not re-open “add comparator”. Do not invent binomial-phylo. |
| 3 | `phylo_count_large_p` | experimental | **smoke-only** | YES | Julia smoke `test/test_poisson_phylo_laplace.jl` / `test/test_nb2_phylo_laplace.jl`; FE Workflow G `test/parity/fixtures/count-{poisson,nbinom2}/expected.toml`; **NONE** large-p same-target | Keep smoke + FE; do not promote | Smoke exists; large-p is evidence, not a missing family. |
| 4 | `general_covariance_structured` | experimental | **smoke-only** (S3 recon also: **TSV-claim** — gate-compare done) | YES | Audit `docs/dev-log/evidence/2026-08-16-a9-general-covariance-audit.md`; **NONE** Workflow G `relmat` expected.toml | Compare families vs R gate — **done**; do not widen | `next_action` already answered. Do not invent beta+`relmat` Δ. |
| 5 | `gaussian_response_mask` | partial | **parked-adjacent** | YES | Julia `test/test_missing_listwise.jl` (cites `#49`); **NONE** Workflow G `miss_control` expected.toml | Keep mask tests Gaussian-only | Fixture/audit gap, but `#49` PARKED — do not unpark. |
| 6 | `base_gaussian_location_scale` | partial | **TSV-claim** | YES | `test/parity/fixtures/gaussian-locscale/expected.toml`; `docs/dev-log/evidence/parity-fixtures.tsv` PARITY_PASS | Keep coef/logLik on exact payloads | Phase 1.5 admitted. Promotion = drmTMB TSV claim. |
| 7 | `biv_gaussian_residual` | partial | **TSV-claim** | YES | `test/parity/fixtures/gaussian-bivariate-rho12/expected.toml` | Keep rho12 result-shape; do not promote | Phase 1.5 admitted. Not cross-family. |
| 8 | `gaussian_phylo_mean` | partial | **TSV-claim** | YES | `test/test_bridge.jl` result-shape; **no** Workflow G phylo `expected.toml` | Keep first phylo-mean; do not widen to sigma-phylo | Phase 1.5 admitted. Widening invents a different row. |
| 9 | `plain_binomial_nonphylo` | partial | **TSV-claim** | YES | `test/parity/fixtures/binomial-trials/expected.toml` | Keep Workflow G live R gate green | Fixture exists; not CRAN-default. Soft collision `#425`. |
| 10 | `cross_family_latent` | experimental | **owned** | UNKNOWN | **NONE** on this branch; live `#428` | Resolve mixed-family API mismatch | **OWNED SKIP `#428`.** Do not steal. |
| 11 | `engine_control_surface` | unsupported | **fence** | NO | **NONE** | Design `engine_control` before relaxing | Leave `unsupported`. Not a port. |

### claim_boundary quotes (do not tighten or loosen)

1. `base_gaussian_location_scale` — Phase 1.5 Hopper admitted cell (Route C): offline result-shape + optional live TMB parity; CRAN readers still use TMB — vignette keeps Julia deferred/experimental.
2. `biv_gaussian_residual` — Phase 1.5 Hopper admitted cell (Route B): residual rho12 result-shape + optional live logLik parity; not a phylo or cross-family claim.
3. `gaussian_phylo_mean` — Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (`sigma ~ 1`) marshalling/result-shape + optional live TMB parity; not loc-scale phylo or non-Gaussian phylo.
4. `gaussian_response_mask` — Gaussian-only response masks; missing predictors and non-Gaussian response masks remain gated.
5. `biv_q4_phylo_reml` — Requires the full four-axis phylogenetic location-scale grammar; native TMB has separate q4 recovery evidence, but this Julia row does not establish same-target bridge parity, interval reliability, or HSquared AI-REML support.
6. `plain_binomial_nonphylo` — Live R Workflow G binomial-trials cell vs DRM.jl `expected.toml`; still experimental, not a CRAN default.
7. `phylo_count_large_p` — Large-p phylogenetic random-intercept route; Workflow G FE count cells also route via live `expected.toml` parity (#499).
8. `phylo_gamma_beta_binomial` — Finite-and-sane bridge smoke evidence only; no native TMB parity or non-phylo binomial bridge promotion.
9. `general_covariance_structured` — Requires covariance/relatedness matrix `K` and `sigma ~ 1`; beta, precision `Q`, and sigma predictors stay gated.
10. `cross_family_latent` — Latent-rho development route; public docs must not present rho12 formulas or release-ready cross-family inference.
11. `engine_control_surface` — Do not document user-selectable Julia optimizer controls until a real R API is designed.

---

## S6 — Rose pass (claim-vs-evidence; not a ship)

**Verdict:** **clean-with-limitations.** This note is an inventory backlog, not
a parity claim and not an implement approval.

**Accepts**

- Phrase *export-gap countdown at 0; 11 rows still unsigned.*
- Per-row `claim_boundary` quoted, not rewritten as a tighter/looser public claim.
- Recommended later slice = `biv_q4_phylo_reml` fixture, not a TSV flip.
- `#428` classified owned-skip. `#136` not closed. `#49` not unparked.
- `engine_control_surface` left `unsupported`.
- Two scoreboards not merged: A = TSV/ledger; B = `capability-status.md`.
- Sweep receipt non-vacuous (TSV `git show`, empty diff vs `097bed1e2`,
  fixture path grep, `gh pr list`, twin-map, collisions).

**Would block (none present in this note)**

- "R–Julia parity complete" / "caught up" / "D-111 ready"
- One PR that "clears the 11 rows"
- A TSV `supported` flip from this tree
- Stealing `#428` or closing `#136`
- Invented twin Δ (beta+`relmat`, binomial+`phylo`)
- Ordinary-RE REML / `:natgrad` / VA / AGHQ as Arc 1

**Limitation:** this pass does not re-run `parity_ledger.py` or `Pkg.test`.
It classifies from cited TSV + on-disk fixture paths. Workflow G metas still
record drmTMB **0.6.0**; campaign anchor is **0.7.0** — say the split; do not
silently re-anchor.

---

## S7 — count check

| Check | Result |
|---|---|
| Unique `capability_id` count | **11** |
| Each ID once in the ordered table | **yes** (ords 1–11) |
| Each ID once in claim_boundary list | **yes** (1–11) |
| Every row has class + citation | **yes** (class column + fixture path or NONE) |
| Recommended slice | `biv_q4_phylo_reml` |
| Recommended ≠ `#428` / `#136` / `#49` / `engine_control_surface` / TSV flip | **yes** |

IDs (sorted, for mechanical verify):

```
base_gaussian_location_scale
biv_gaussian_residual
biv_q4_phylo_reml
cross_family_latent
engine_control_surface
gaussian_phylo_mean
gaussian_response_mask
general_covariance_structured
phylo_count_large_p
phylo_gamma_beta_binomial
plain_binomial_nonphylo
```

---

## What this inventory did NOT do

- Implement any row. Flip any `claim_status`. Edit `src/` or `capability-status.md`.
- Steal `#428`. Unpark `#49`. Close `#136`. Design `engine_control`.
- Checkout drmTMB. Stage `shannon-coordinator.toml`. Run `Pkg.test` / recovery.
