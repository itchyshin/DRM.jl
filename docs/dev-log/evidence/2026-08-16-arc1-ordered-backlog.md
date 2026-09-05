# Arc 1 ordered backlog — refresh after #434 (2026-08-16)

**Lane:** `docs-arc1-backlog-after-434` · Ada refresh (S1) + Rose (S3) +
count (S4).
**Platform:** Cursor Grok. No Opus/Sol/Other Models. No Task children.
**Docs-only refresh.** No `src/`. No TSV `supported` flip. No new
recommended implement. Implement of any row = **new G0**.

Phrase: *refresh the Arc 1 backlog after #434; fixture banked; 11 rows
still unsigned.* Also still true: *export-gap countdown at 0; 11 rows
still unsigned.* Zero rows are `supported`. Split: 6 `partial` · 4
`experimental` · 1 `unsupported`.
drmTMB TSV tip this pass: `origin/main` `d9fddfa28` (cited; not re-run
`parity_ledger.py` after `b73d9241` — COUNTDOWN 0 is **UNVERIFIED** as a
fresh script). DRM.jl exports 154. COUNTDOWN 0 ≠ parity complete.

This file **replaces** the #432 inventory text on the same path. It does
**not** re-hunt the 11 rows. Sources: #432 backlog + #434 after-task
`2026-08-16-biv-q4-phylo-reml-fixture.md` + Rose fence
`2026-08-16-next-after-biv-rose.md` (planning pass) +
`2026-08-16-biv-q4-s5-rose-fence.md`. Class vocabulary from the #432
ultra-plan.

---

## After #434 — no remaining fixture-gap implement

**#434** (`b73d9241`, closes #433) banked the **only** same-target
fixture-gap on an already-implemented engine (`biv_q4_phylo_reml`).
Fixture lives at `test/parity/q4-reml/biv-q4-phylo-reml/` (outside the
Workflow G `fixtures/` glob). Standalone test
`test/test_parity_biv_q4_phylo_reml.jl` is **not** in `test/runtests.jl`
(WAIT: `#423` + `#428` own that file; `#425` merged 2026-08-16).

`claim_status` stays **`partial`**. `r_bridge_status` stays
**`experimental`**. The logLik gap is a declared `[tol]`
(`atol_loglik=6.0`, `d≈−5.63`) because native TMB REML restricts **mean**
fixed effects while Julia `reml_q4` profiles **mean and scale**. Not a
1e-3 Workflow G twin. No TSV `supported` flip.

**This refresh does not name a new recommended implement.** Remaining
unsigned rows are TSV-claim, smoke-only with `next_action` already
answered, parked (`#49`), owned (`#428`), or a design fence. Forcing
`phylo_gamma_beta_binomial` (or large-p / relmat) invents work the
ledger does not ask for. Next implement G0 only when (a) the
`runtests.jl` wait clears, or (b) the owner names a new same-target gap.

**Not this slice:** `#428` / `cross_family_latent` (owned skip) · `#136`
VA (OPEN) · `#49` (PARKED) · `engine_control_surface` (fence) · a TSV
`supported` flip · include-in-`runtests.jl`.

---

## Ordered list (same 11 IDs as #432; ord 1 no longer a fixture-gap)

Order is *what a later implement G0 should look at*, not a claim that
any row is `supported`, and **not** a recommended-implement ranking
after #434.

| ord | capability_id | claim_status | class | twin | fixture | next_action (abbrev.) | why this rank |
|---|---|---|---|---|---|---|---|
| 1 | `biv_q4_phylo_reml` | partial | **fixture-banked** (still TSV-claim) | YES | **banked** `test/parity/q4-reml/biv-q4-phylo-reml/` (#434); `[tol]` = measured mean-vs-mean+scale gap (`atol_loglik=6.0`, `d≈−5.63`); Julia REML exists (`test/test_reml_q4_allaxes.jl`); bridge export still refuses parity (`test/test_bridge_q4_direct_export.jl`) | Bank fit-specific CI/status parity before release language — **cell banked**; promotion is a drmTMB TSV claim | Same-target fixture shipped. `claim_status` still `partial`. Not a recommended implement. |
| 2 | `phylo_gamma_beta_binomial` | experimental | **smoke-only** (S3 recon also: **TSV-claim** — comparator already exists) | YES/NO | `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` (gamma FAIL · beta PASS · binomial NO_NATIVE_COMPARATOR) | Add comparator — **evidence-complete**; promotion is a drmTMB claim | Not an implement slice. Do not re-open “add comparator”. Do not invent binomial-phylo. |
| 3 | `phylo_count_large_p` | experimental | **smoke-only** | YES | Julia smoke `test/test_poisson_phylo_laplace.jl` / `test/test_nb2_phylo_laplace.jl`; FE Workflow G `test/parity/fixtures/count-{poisson,nbinom2}/expected.toml`; **NONE** large-p same-target | Keep smoke + FE; do not promote | Smoke exists; large-p is evidence, not a missing family. |
| 4 | `general_covariance_structured` | experimental | **smoke-only** (S3 recon also: **TSV-claim** — gate-compare done) | YES | Audit `docs/dev-log/evidence/2026-08-16-a9-general-covariance-audit.md`; **NONE** Workflow G `relmat` expected.toml | Compare families vs R gate — **done**; do not widen | `next_action` already answered. Do not invent beta+`relmat` Δ. |
| 5 | `gaussian_response_mask` | partial | **parked-adjacent** (S2 recon also: **fixture-gap**; do not unpark `#49`) | YES | Julia `test/test_missing_listwise.jl` (cites `#49`); **NONE** Workflow G `miss_control` expected.toml | Keep mask tests Gaussian-only | Fixture/audit gap, but `#49` PARKED — do not unpark. |
| 6 | `base_gaussian_location_scale` | partial | **TSV-claim** | YES | `test/parity/fixtures/gaussian-locscale/expected.toml`; `docs/dev-log/evidence/parity-fixtures.tsv` PARITY_PASS | Keep coef/logLik on exact payloads | Phase 1.5 admitted. Promotion = drmTMB TSV claim. |
| 7 | `biv_gaussian_residual` | partial | **TSV-claim** | YES | `test/parity/fixtures/gaussian-bivariate-rho12/expected.toml` | Keep rho12 result-shape; do not promote | Phase 1.5 admitted. Not cross-family. |
| 8 | `gaussian_phylo_mean` | partial | **TSV-claim** | YES | `test/test_bridge.jl` result-shape; **no** Workflow G phylo `expected.toml` | Keep first phylo-mean; do not widen to sigma-phylo | Phase 1.5 admitted. Widening invents a different row. |
| 9 | `plain_binomial_nonphylo` | partial | **TSV-claim** | YES | `test/parity/fixtures/binomial-trials/expected.toml` | Keep Workflow G live R gate green | Fixture exists; not CRAN-default. `#425` merged (binomial structured-marker refusal); not a collision on this docs path. |
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

## S3 — Rose pass (claim-vs-evidence; not a ship)

**Verdict:** **clean-with-limitations.** This note is a backlog *refresh*,
not a parity claim and not an implement approval.

**Accepts**

- Phrase *refresh the Arc 1 backlog after #434; fixture banked; 11 rows
  still unsigned.*
- Phrase *export-gap countdown at 0; 11 rows still unsigned.*
- Per-row `claim_boundary` quoted, not rewritten as a tighter/looser
  public claim.
- Ord 1 fixture line is **banked**, not **NONE**. `claim_status` still
  `partial`.
- **No** new recommended implement named.
- `#428` classified owned-skip. `#136` not closed. `#49` not unparked.
- `engine_control_surface` left `unsupported`.
- Two scoreboards not merged: A = TSV/ledger; B = `capability-status.md`.
- `#434` cell: logLik gap is a declared `[tol]` (TMB mean-only REML vs
  Julia mean+scale), not a 1e-3 Workflow G twin.

**Would block (none present in this note)**

- "R–Julia parity complete" / "caught up" / "D-111 ready"
- One PR that "clears the 11 rows"
- A TSV `supported` flip from this tree
- Naming a new recommended implement (`phylo_gamma_beta_binomial`, etc.)
- Stealing `#428` or closing `#136`
- Invented twin Δ (beta+`relmat`, binomial+`phylo`)
- Treating `atol_loglik=6.0` as a defect to fix in `src/`
- Wiring the #434 test into `runtests.jl` under a docs title
- Ordinary-RE REML / `:natgrad` / VA / AGHQ as Arc 1

**Limitation:** this pass does not re-run `parity_ledger.py` or `Pkg.test`.
It classifies from cited TSV + on-disk fixture paths + the #434 after-task.
Workflow G metas still record drmTMB **0.6.0**; this cell is **0.7.0**
REML + tree — say the split; do not silently re-anchor. COUNTDOWN 0 is
**UNVERIFIED** as a fresh script after `b73d9241`.

Fence copied from the planning-pass Rose note
`docs/dev-log/evidence/2026-08-16-next-after-biv-rose.md` (Dropbox leftover;
not rewritten here) and the in-PR S5
`docs/dev-log/evidence/2026-08-16-biv-q4-s5-rose-fence.md`.

---

## S4 — count check

| Check | Result |
|---|---|
| Unique `capability_id` count | **11** |
| Each ID once in the ordered table | **yes** (ords 1–11) |
| Each ID once in claim_boundary list | **yes** (1–11) |
| Every row has class + citation | **yes** (class column + fixture path or NONE) |
| Stale **NONE** same-target on `biv_q4_phylo_reml` | **gone** — fixture **banked** |
| New recommended implement named | **no** |
| Recommended ≠ `#428` / `#136` / `#49` / `engine_control_surface` / TSV flip | **n/a** (no recommended implement) |

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

## What this refresh did NOT do

- Implement any row. Flip any `claim_status`. Edit `src/` or
  `capability-status.md`.
- Name a new recommended implement.
- Steal `#428`. Unpark `#49`. Close `#136`. Design `engine_control`.
- Include `test/test_parity_biv_q4_phylo_reml.jl` in `test/runtests.jl`.
- Checkout drmTMB. Stage `shannon-coordinator.toml`. Run `Pkg.test` /
  recovery.
