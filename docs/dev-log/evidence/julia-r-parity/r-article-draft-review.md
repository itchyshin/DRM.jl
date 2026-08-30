# Julia engine article draft — 2026-08-30

Source worktree: `/private/tmp/drm-parity-20260830/drmTMB`, branch `codex/julia-r-parity`,
base `b35642b4560072cadba7e595e66e00209ebdeb40`. Changes remain local and uncommitted.

- `_pkgdown.yml`: current backend labelled “Julia engine”; removed “future support”.
- `vignettes/julia-engine.Rmd`: general ordinary-regression introduction, source-checkout
  setup, complete example data, group and phylogenetic LSS, explicit ML interval example,
  narrow current limitations and distinction between 5,000 observations and species.
- Removed unsupported universal speed, tridiagonal precision, unbiasedness and post-fit claims.
- Rose source review (Sol/high requested) accepted after adding `ape` installation and explicit
  noninteractive-script opt-in. Source review is not executable-example evidence.
- `knitr::purl` then `parse` printed `ARTICLE_R_SYNTAX_PASS`.
- `rmarkdown::render` printed `ARTICLE_RENDER_COMPLETE`; artifact
  `/private/tmp/drm-parity-20260830/render/julia-engine.html`.
- In-app browser inspected standalone desktop render; mobile viewport checked at390x844,
  document width390, but this is not the full pkgdown navigation/theme review.
- `git diff --check` passed.

Still required: execute exact seeded examples with pinned R/Julia builds, verify convergence
and interval statuses, build full pkgdown and Documenter sites, inspect all responsive/theme
states and deployed URLs. Current draft does NOT cover those gates.

Neighbour finding: R help for live bridge methods retains halted/deferred wording. Include
source roxygen and regenerated help in S13; do not interpret stale prose as missing methods.
