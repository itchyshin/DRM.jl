# Proposed drmTMB registry extension — ready to apply, NOT applied

Date: 2026-08-14 · lane: DRM.jl (Claude) · target: drmTMB narrow lane
(`inst/extdata/julia-capabilities.tsv`, `R/julia-bridge.R`)

## Why this is a proposal and not a commit

The campaign granted a **narrow** drmTMB lane. Pre-flight on that repo reports
**9 live lanes**, a foreign codex lane, **13 commits to `origin/main` in 12 h**,
and an open **0.7.0 release slice (#959)**. The two target files are clean but
actively developed — `julia-capabilities.tsv` **5 commits in 14 days**,
`R/julia-bridge.R` **8**. The owner-timing question (land before or after 0.7.0
ships) was raised twice and is unanswered.

Under [[DECISIONS#D-88]] concurrency is allowed but **bleed-through is not**, and
under [[DECISIONS#D-87]] an overlap call belongs to the owner. So the content is
prepared here and applied by whoever owns that lane.

**This proposal changes no `claim_status` and no `r_bridge_status`.** drmTMB has
deliberately demoted every row to `partial`/`experimental`; promoting a row is a
claim decision inside its release process, not something to import from here.
What this adds is **evidence**, which is what the rows' own `next_action` fields
ask for.

## The evidence being offered

From `tools/parity_fixture.R` in DRM.jl (reproduce with
`DRM_JL_PATH=$(pwd) Rscript tools/parity_fixture.R`), against installed
drmTMB 0.6.0, tolerance 1e-4:

| cell | max abs coef diff | logLik diff | verdict |
|---|---|---|---|
| `base_gaussian_location_scale` | 4.56e-06 | 4.58e-09 | PARITY_PASS |
| Gaussian, intercept-only sigma | 2.49e-10 | 5.26e-13 | PARITY_PASS |
| fixed-effect Poisson | 1.03e-12 | 1.71e-13 | PARITY_PASS |
| fixed-effect NB2 | 2.79e-08 | 2.27e-13 | PARITY_PASS |
| fixed-effect Gamma (log link) | 3.91e-06 | 2.75e-09 | PARITY_PASS |

Machine-readable: `docs/dev-log/evidence/parity-fixtures.tsv`.

## Proposed field changes

Row `base_gaussian_location_scale` — `next_action` currently reads *"Keep
coefficient and likelihood parity tests tied to exact bridge payloads."*
Satisfied; suggest appending the citation:

> Coefficient/logLik parity measured 2026-08-14 (coef 4.56e-06, logLik 4.58e-09,
> tol 1e-4) — DRM.jl `docs/dev-log/evidence/parity-fixtures.tsv`.

Row `plain_binomial_nonphylo` — `next_action` currently reads *"Keep non-phylo
count bridge errors in the gate registry."* Note that this is now stale on
`origin/main`: `drm_julia_family_tag()` routes the nine Workflow G fixed-effect
families unconditionally per #499, so the non-phylo count error no longer fires
for them. Suggest:

> Non-phylo count errors no longer fire for the Workflow G FE cohort (#499).
> Independent coefficient/logLik parity for FE Poisson / NB2 / Gamma(log)
> measured 2026-08-14 — DRM.jl `docs/dev-log/evidence/parity-fixtures.tsv`.

Row `general_covariance_structured` — `next_action` reads *"Compare current
DRM.jl accepted families with the R gate before widening."* That comparison now
exists: DRM.jl `tools/parity_ledger.py`, run against a pinned drmTMB ref, plus
`docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md` (25 export gaps,
11 rows, 14 closed gates at 0.7.0 `f5ec53634`).

## One correctness item found on the way

`zeroonebeta` emits a dpar named **`beta_mu`** from the DRM.jl bridge payload,
which is **not a drmTMB dpar name**. Any admission of that cell's post-fit needs
an explicit name map or an exclusion — otherwise `fitted_distribution_params()`
would receive a column it cannot address. Recorded in
`docs/dev-log/design/2026-08-14-a2a-result-shape-contract.md`.

## How to apply

In a worktree off `origin/main` (never `git checkout` in the shared drmTMB
checkout — that moves HEAD under another lane):

```bash
git -C ../drmTMB worktree add ../drmtmb-registry -b claude/julia-parity-evidence origin/main
```

Edit the `next_action` cells above, add a test under
`tests/testthat/test-julia-*` if the lane wants the citation guarded, open a PR,
and do **not** merge into an open release slice without the release owner's OK.
