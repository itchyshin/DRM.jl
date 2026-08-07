# Evidence — Phase 3 / #7 inventory (2026-08-07)

**Lane:** `docs/7-phase3-closeout` · tip base `f3d8ce7d` (Merge #396)  
**Perspectives:** Shannon · Pat · Rose. No nested subagents.

## Claim under test

Issue [#7](https://github.com/itchyshin/DRM.jl/issues/7) listed 26 drmTMB-target
Documenter slugs as Phase 3 fill work. Closing #7 as *articles milestone done*
is honest **iff** all 26 paths exist and the only non-Stable leftovers are named
carve-outs (not missing pages).

## Method

Re-ran the #7 slug list against `docs/src/` on branch tip after
`git checkout main && git pull` @ `f3d8ce7d`.

## Result — 26/26 OK

| Section | Slugs present |
|---|---|
| Model Guides (6) | `model-map`, `which-scale`, `distribution-families`, `model-workflow`, `convergence`, `large-data` |
| Tutorials (12) | `location-scale`, `robust-student`, `count-nbinom2`, `proportion-beta-binomial`, `bivariate-coscale`, `meta-analysis`, `structural-dependence`, `animal-models`, `phylogenetic-models`, `spatial-models`, `relmat-known-matrices`, `phylogenetic-spatial` |
| Diagnostics (4) | `figure-gallery`, `implementation-map`, `testing-likelihoods`, `simulation-plot-grammar` |
| Developer (3) | `formula-grammar`, `adding-families`, `source-map` |
| Entry (1) | `get-started` |

**Counts:** OK=26 · MISS=0 · TOTAL=26.

## Honesty banners (carve-outs — not missing fills)

| Page | Status banner | Meaning |
|---|---|---|
| `docs/src/tutorials/phylogenetic-spatial.md` | **Theory + roadmap** | Each structured effect fits alone today; simultaneous phylo×spatial is planned (engine later — not this PR) |
| `docs/src/model-guides/marginal-la-vs-va.md` | **Planned (#136)** | LA is today's marginal; VA/ELBO is design-only (#136 open) |

These pages exist and are intentionally non-Stable. Closing #7 must **not**
imply the joint phylo×spatial fit or VA are shipped.

## What this receipt does *not* claim

- No new article content invented in this closeout.
- No capability-status promotion of phylo×spatial joint or `method=:VA`.
- #336 Makie, #49 FIML, R-bridge live round-trip — out of fence.

## Rose gate input

Inventory supports **CLOSE #7 with carve-outs named** in ROADMAP + issue
comment. Missing-slug risk branch from the ultra-plan was **not** taken.
