# Hopper — next DRM.jl fixture-only cell after #434 (2026-08-16)

**Role:** Hopper (R↔Julia translator). **Read-only** except this note.
**No `src/`.** No TSV `supported` flip. No drmTMB checkout. No GPL source.
**Lane taken:** `docs-next-after-biv-hopper` (new untracked evidence file).
**Preflight:** `FOREIGN LANE ACTIVE (claude direct-to-main)` · 10 live lanes.
Did not claim `#428` / `#425` / `#423` / `#429` / `#420` / `#406` / `#421` files.
**Nested Task subagents:** none.

**Recommend:** **NONE** — docs / inventory refresh is wiser than picking a
runner-up implement cell.

---

## What #434 actually landed (`b73d9241` on `origin/main`)

`git show b73d9241 --stat` + `git ls-tree origin/main`:

| Path | Role |
|---|---|
| `test/parity/q4-reml/biv-q4-phylo-reml/{data.csv,tree.newick,expected.toml,expected.meta.toml}` | same-target fixture **outside** Workflow G `fixtures/` glob |
| `test/parity/gen_biv_q4_phylo_reml.R` | generator (does not edit `gen_fixtures.R`) |
| `test/test_parity_biv_q4_phylo_reml.jl` | standalone test (does not touch `test/runtests.jl`) |
| `docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md` | after-task |
| `docs/dev-log/check-log.d/2026-08-16-biv-q4-phylo-reml-fixture.md` | check-log |
| `docs/dev-log/evidence/2026-08-16-biv-q4-{phylo-reml-recon,phylo-reml-schema,s5-rose-fence}.md` | recon / schema / Rose |
| `docs/dev-log/plan-actual/2026-08-16-biv-q4-phylo-reml-fixture.md` | plan-vs-actual |

After-task (`origin/main:docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md`):
claim stays **partial**; no TSV flip; logLik gap banked as `[tol]`
(`atol_loglik = 6.0`) because native TMB REML restricts **mean** FE while
DRM.jl `reml_q4` profiles **mean and scale**. Julia `converged=false`;
R `interval_status=wald_unavailable`. drmTMB **0.7.0**. 33/33 standalone.

That was the backlog's **only** same-target fixture-gap on an already-implemented
engine (ordered-backlog ord 1; S2 batch verdict: "Row 5 is the only … fixture-gap").
It is no longer missing.

---

## Twin TSV (read-only `git show`; tip SHA)

```
git -C "/Users/z3437171/Dropbox/Github Local/drmTMB" log origin/main -1 --oneline
# d9fddfa28 Merge pull request #1058 from itchyshin/cursor/interval-truth-owed
git -C "/Users/z3437171/Dropbox/Github Local/drmTMB" show origin/main:inst/extdata/julia-capabilities.tsv
```

**Tip:** `d9fddfa28` (same SHA as Arc 1 inventory / S3). Empty status change vs
eleven-rows `097bed1e2`. Zero rows `supported`. Split still 6 `partial` ·
4 `experimental` · 1 `unsupported`. `#434` did **not** edit this file.

`next_action` for remaining unsigned rows (quoted; TSV text unchanged after #434):

| capability_id | claim_status | next_action (abbrev.) |
|---|---|---|
| `base_gaussian_location_scale` | partial | Keep coef/logLik on exact bridge payloads |
| `biv_gaussian_residual` | partial | Keep rho12 result-shape; do not promote |
| `gaussian_phylo_mean` | partial | Keep first phylo-mean; do not widen to sigma-phylo |
| `gaussian_response_mask` | partial | Keep mask tests Gaussian-only |
| `biv_q4_phylo_reml` | partial | Bank fit-specific CI/status parity before release language |
| `plain_binomial_nonphylo` | partial | Keep Workflow G live R gate green |
| `phylo_count_large_p` | experimental | Keep phylo-count smoke + Workflow G FE; do not promote |
| `phylo_gamma_beta_binomial` | experimental | Add comparator or parity evidence before promoting |
| `general_covariance_structured` | experimental | Compare accepted families with the R gate (comparison now exists) |
| `cross_family_latent` | experimental | Resolve mixed-family API mismatch |
| `engine_control_surface` | unsupported | Design `engine_control` before relaxing |

`biv_q4_phylo_reml` `next_action` is **stale relative to the fixture**: CI/status
fields are now recorded (`expected.toml` `[status]`), but the TSV sentence was
not rewritten. That rewrite is a **drmTMB** claim, not a DRM.jl implement.

---

## Named candidates (fixture path · class · steal?)

Live `test/runtests.jl` owners this pass (`gh pr list`): **#428**, **#425**,
**#423**. Any implement that includes that file steals. Prefer new test paths.

### `phylo_gamma_beta_binomial`

| Field | Value |
|---|---|
| fixture | **EXISTS** (mixed): `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` (gamma FAIL · beta PASS · binomial `NO_NATIVE_COMPARATOR`) — S3 recon + ordered-backlog ord 2 |
| class | **TSV-claim** / smoke-only. Comparator already exists. `next_action` "add comparator" is **evidence-complete** (S3). Promotion is a drmTMB claim. Do not invent binomial+`phylo` (twin **NO**). |
| steal? | **YES if re-opened.** `#425` owns `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` + `src/binomial.jl` + `src/sparse_laplace_glmm.jl` + `test/runtests.jl`. |
| implement? | **No.** Backlog: "NOT implement / comparator exists." |

### `phylo_count_large_p`

| Field | Value |
|---|---|
| fixture | Julia smoke `test/test_poisson_phylo_laplace.jl` / `test/test_nb2_phylo_laplace.jl`. Workflow G FE (not phylo): `test/parity/fixtures/count-{poisson,nbinom2}/expected.toml`. **NONE** large-p same-target (`git ls-tree origin/main:test/parity` — no `*large*` / phylo-count `expected.toml`). Live twin in drmTMB is n_tip=24 Poisson @ 1e-2, not large-p (S3). |
| class | **smoke-only**. Large-p is the sparse *route*, not a missing family. TSV: keep / do not promote. |
| steal? | Soft: `#425` owns `src/sparse_laplace_glmm.jl`. New fixture paths would not steal if they stay off `runtests.jl` / that src. Still not Mac-easy (large-p). |
| implement? | **No.** Not a cheap fixture-only cell. |

### `general_covariance_structured`

| Field | Value |
|---|---|
| fixture | Gate-compare **EXISTS**: `docs/dev-log/evidence/2026-08-16-a9-general-covariance-audit.md`. Julia: `test/test_relmat_counts.jl`. **NONE** Workflow G `relmat` `expected.toml` (`ls-tree` fixtures/ has no `relmat*`). |
| class | **TSV-claim** (S3). `next_action` (family-vs-gate compare) is **done**. Widening / beta+`relmat` Δ is forbidden (D-94 / Rose fence). |
| steal? | Soft: `#423` owns `tools/parity_ledger.py`. New `expected.toml` paths would not steal that file. |
| implement? | **No.** Ledger does not ask for a new numeric cell. |

### `gaussian_response_mask`

| Field | Value |
|---|---|
| fixture | Julia `test/test_missing_listwise.jl` (cites `#49`). **NONE** Workflow G `miss_control` `expected.toml` (S2). |
| class | **parked-adjacent** + fixture-gap. Twin YES for `miss_control(response = "include")`. Predictor `mi()` / `impute` is `#49`. |
| steal? | Soft: `#425` owns missing-adjacent `src/binomial.jl`. `#49` **PARKED** (owner-named). |
| implement? | **No.** User + Rose: do not unpark `#49`. |

### Cheaper fixture-gap the backlog noted but ranked TSV-claim

`gaussian_phylo_mean` — S1: **NONE** committed `expected.toml` / `parity-fixtures.tsv` row; no `test/parity/fixtures/gaussian-phylo*` (`ls-tree` confirms). Live Route A already exists in drmTMB `tests/testthat/test-julia-tmb-parity.R`. Class **TSV-claim** (Phase 1.5 admitted). `next_action`: keep tests; do not widen to sigma-phylo. Workflow G runner is ML / no tree — a phylo `expected.toml` cannot join `fixtures/` glob (same reason #434 used `q4-reml/`).

This is the only leftover **NONE** same-target path that is not parked, owned, or large-p. It is **not** an honest next *implement* cell: the row is already admitted; adding a hermetic copy of Route A is inventory-class work (re-rank "NONE expected.toml + live R test"), not a missing engine. Ultra-plan Arc 1 Q2: first implement ≠ Phase 1.5 TSV promotion.

No other cheaper fixture-gap found that is **not** a TSV flip and **not** `#428`.
`cross_family_latent` = **owned** (`#428` files include `src/mixed_family*.jl`, `docs/src/cross-family.md`, `test/runtests.jl`). Skip.

---

## Why NONE (inventory refresh)

1. S2: the **only** same-target fixture-gap on an already-implemented engine was
   `biv_q4_phylo_reml`. `#434` closed that gap. Claim stays `partial`.
2. Remaining NONE paths are parked (`#49`), owned (`#428`), keep-tests
   (`gaussian_phylo_mean`), smoke/do-not-promote (`phylo_count_large_p`), or
   next_action-already-done (`general_covariance_structured`,
   `phylo_gamma_beta_binomial`).
3. The ordered backlog still ranks `biv_q4_phylo_reml` as ord 1 — **stale**
   after `b73d9241`. Re-ranking the 11 unsigned rows is the honest next docs
   cell. Picking a runner-up without that refresh invents work the TSV does
   not ask for.
4. TSV tip `d9fddfa28` is unchanged. A `supported` flip remains a drmTMB STOP
   GATE, not this tree.
5. Campaign stays **2026-08-14 admit-what-R-fits**. `#428` skip. `#49` PARKED.
   `#136` OPEN. D-111 OFF.

**Not recommended:** implement any of the four named candidates, or
`gaussian_phylo_mean`, as the next G0.

---

## Sources (do not re-derive)

- scratch `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`
- Dropbox `docs/dev-log/after-task/2026-08-16-ultra-plan-arc1.md`
- Dropbox `docs/dev-log/after-task/2026-08-16-ultra-plan-biv-q4-phylo-reml-fixture.md`
- `git show origin/main:` after-task / check-log / `expected.toml` / Rose S5
- scratch `2026-08-16-arc1-{batch-experimental,recon-s3,recon-s1,recon-s2,batch-partials-admitted,batch-partials-rest,batch-owned-fence,hopper-twin-map,lane-collisions,rose-fence}.md`
- drmTMB TSV via `git show origin/main:inst/extdata/julia-capabilities.tsv` @ `d9fddfa28`
- `gh pr list --repo itchyshin/DRM.jl --state open` (this pass)
- `git ls-tree origin/main:test/parity/fixtures` + `test/parity/q4-reml`
