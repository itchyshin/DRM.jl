# Decision: drmTMB 26-article → DRM.jl page map (#7)

**Date:** 2026-06-02 · **Resolves (tracks):** #7 · **Owner:** Shannon / Ada (Workflow D `mirror-article`)

drmTMB ships **26 pkgdown articles** across five navbar groups (Get started,
Model Guides, Tutorials, Diagnostics, Developer). DRM.jl mirrors that navbar in
`docs/make.jl`. This decision records the slug-by-slug map from each drmTMB
article to its DRM.jl page under `docs/src/`, with a status determined by
**reading / `wc -l` + grepping each file** (not by assumption).

**Status legend.** **FILLED** = substantive mirror with a "Status" admonition and
real DRM.jl-today content. **stub** = 6-line `Phase 0 stub — filled via Workflow
D` placeholder. **missing** = no page exists.

## Map

| # | drmTMB article slug | Group | DRM.jl page (`docs/src/…`) | Lines | Status |
|---|---|---|---|---:|---|
| 1 | `get-started` (`drmTMB.html`) | Get started | `get-started.md` | 71 | **FILLED** |
| 2 | `model-map` | Model Guides | `model-guides/model-map.md` | 89 | **FILLED** |
| 3 | `which-scale` | Model Guides | `model-guides/which-scale.md` | 51 | **FILLED** |
| 4 | `distribution-families` | Model Guides | `model-guides/distribution-families.md` | 106 | **FILLED** |
| 5 | `model-workflow` | Model Guides | `model-guides/model-workflow.md` | 107 | **FILLED** |
| 6 | `convergence` | Model Guides | `model-guides/convergence.md` | 90 | **FILLED** |
| 7 | `large-data` | Model Guides | `model-guides/large-data.md` | 73 | **FILLED** |
| 8 | `location-scale` | Tutorials | `tutorials/location-scale.md` | 80 | **FILLED** |
| 9 | `robust-student` | Tutorials | `tutorials/robust-student.md` | 54 | **FILLED** |
| 10 | `count-nbinom2` | Tutorials | `tutorials/count-nbinom2.md` | 155 | **FILLED** |
| 11 | `proportion-beta-binomial` | Tutorials | `tutorials/proportion-beta-binomial.md` | 102 | **FILLED** |
| 12 | `bivariate-coscale` | Tutorials | `tutorials/bivariate-coscale.md` | 59 | **FILLED** |
| 13 | `meta-analysis` | Tutorials | `tutorials/meta-analysis.md` | 48 | **FILLED** |
| 14 | `structural-dependence` | Tutorials | `tutorials/structural-dependence.md` | 26 | **FILLED** |
| 15 | `animal-models` | Tutorials | `tutorials/animal-models.md` | 41 | **FILLED** |
| 16 | `phylogenetic-models` | Tutorials | `tutorials/phylogenetic-models.md` | 52 | **FILLED** |
| 17 | `spatial-models` | Tutorials | `tutorials/spatial-models.md` | 50 | **FILLED** |
| 18 | `relmat-known-matrices` | Tutorials | `tutorials/relmat-known-matrices.md` | 50 | **FILLED** |
| 19 | `phylogenetic-spatial` | Tutorials | `tutorials/phylogenetic-spatial.md` | 71 | **FILLED** |
| 20 | `figure-gallery` | Diagnostics | `diagnostics-and-validation/figure-gallery.md` | 96 | **FILLED** |
| 21 | `implementation-map` | Diagnostics | `diagnostics-and-validation/implementation-map.md` | 6 | **stub** |
| 22 | `testing-likelihoods` | Diagnostics | `diagnostics-and-validation/testing-likelihoods.md` | 70 | **FILLED** |
| 23 | `simulation-plot-grammar` | Diagnostics | `diagnostics-and-validation/simulation-plot-grammar.md` | 6 | **stub** |
| 24 | `formula-grammar` | Developer | `developer-notes/formula-grammar.md` | 127 | **FILLED** |
| 25 | `adding-families` | Developer | `developer-notes/adding-families.md` | 127 | **FILLED** |
| 26 | `source-map` | Developer | `developer-notes/source-map.md` | 70 | **FILLED** |

**Tally: 24 FILLED · 2 stub · 0 missing** (24/26 = 92% filled).

### Notes on classification

- `structural-dependence.md` (26 lines) is short but **FILLED**: status
  "Stable", a marker table, the closed-form GLS marginal, and cross-links. Short
  ≠ stub. The only true stubs carry the literal `*Phase 0 stub — filled via
  Workflow D (mirror-article)*` line and are 6 lines long.
- `get-started` is drmTMB's `drmTMB.html` landing article; DRM.jl splits the
  pkgdown landing into `index.md` (home) + `get-started.md` (first fit). The map
  above counts `get-started.md` as the article mirror.
- The DocumenterVitepress sidebar in `docs/make.jl` also carries **Reference**
  pages (autodocs) and `r-julia-bridge.md` / `rosetta.md`. Those are DRM.jl
  navigation aids, **not** drmTMB pkgdown *articles*, so they are excluded from
  the 26-article parity count. (`r-julia-bridge.md` and three Reference pages —
  `deprecated-marker-internals.md` etc. — are themselves still Phase 0 stubs but
  are out of scope for #7's article parity.)

## Remaining gap for #7

Two of the 26 articles are still Phase 0 stubs:

1. **`implementation-map`** (`diagnostics-and-validation/implementation-map.md`)
   — needs the verified-engine map written out (it currently points at
   `report/q4-sparse-status.md` but does not mirror the drmTMB content).
2. **`simulation-plot-grammar`** (`diagnostics-and-validation/simulation-plot-grammar.md`)
   — needs the DRM.jl simulate/plot grammar mirror (depends on the plotting /
   simulation surface landing).

Both are in the **Diagnostics** group. Each is a single `mirror-article`
(Workflow D) pass.

## Is #7 near-closeable?

**Yes — near-closeable, not yet closeable.** 24/26 article mirrors are FILLED;
the navbar, slugs, and cross-links are all in place. Closing #7 requires only the
two Diagnostics stubs above (`implementation-map`, `simulation-plot-grammar`) to
be filled via Workflow D. Recommend keeping #7 open with a checklist of those two
slugs; once both are FILLED and pass a Rose link/scope audit, #7 closes. No new
pages need to be created — there are **zero missing** article slugs.
