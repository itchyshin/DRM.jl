using Documenter
using DocumenterVitepress
using DRM

# Sidebar mirrors drmTMB's pkgdown navbar (5 dropdowns + Reference + Changelog).
# The site uses the DocumenterVitepress backend (a VitePress/Vue build, the
# docs.makie.org look). Node is supplied by NodeJS_20_jll — no system install.
# warnonly = true while some pages are stubs that reference planned symbols /
# cross-refs that do not exist yet; tighten this as those pages are filled.
makedocs(
    sitename = "DRM.jl",
    authors = "Shinichi Nakagawa",
    modules = [DRM],
    warnonly = true,
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/itchyshin/DRM.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
        "Getting started" => "getting-started.md",
        "Get started" => "get-started.md",
        "Capabilities" => "capabilities.md",
        "Model Guides" => [
            "model-guides/model-map.md",
            "model-guides/which-scale.md",
            "model-guides/distribution-families.md",
            "families.md",
            "model-guides/model-workflow.md",
            "model-guides/model-selection.md",
            "model-guides/convergence.md",
            "model-guides/marginal-la-vs-va.md",
            "model-guides/cross-family-methods.md",
            "model-guides/large-data.md",
        ],
        "Tutorials" => [
            "tutorials/location-scale.md",
            "tutorials/robust-student.md",
            "tutorials/count-nbinom2.md",
            "tutorials/proportion-beta-binomial.md",
            "tutorials/bivariate-coscale.md",
            "tutorials/meta-analysis.md",
            "tutorials/structural-dependence.md",
            "tutorials/animal-models.md",
            "tutorials/phylogenetic-models.md",
            "tutorials/spatial-models.md",
            "tutorials/relmat-known-matrices.md",
            "tutorials/phylogenetic-spatial.md",
        ],
        "Cross-family bivariate" => "cross-family.md",
        "Diagnostics & Validation" => [
            "diagnostics-and-validation/figure-gallery.md",
            "diagnostics-and-validation/prediction-and-postfit.md",
            "diagnostics-and-validation/profile-likelihood.md",
            "diagnostics-and-validation/implementation-map.md",
            "diagnostics-and-validation/exact-gaussian-diagnostics.md",
            "diagnostics-and-validation/testing-likelihoods.md",
            "diagnostics-and-validation/simulation-plot-grammar.md",
        ],
        "Developer Notes" => [
            "developer-notes/formula-grammar.md",
            "developer-notes/adding-families.md",
            "developer-notes/source-map.md",
        ],
        "Reference" => [
            "reference/package.md",
            "reference/model-specification.md",
            "reference/structured-effect-markers.md",
            "reference/deprecated-marker-internals.md",
            "reference/model-fitting-and-postfit.md",
            "reference/visualization.md",
        ],
        "R ↔ Julia bridge" => "r-julia-bridge.md",
        "Rosetta (R ↔ Julia)" => "rosetta.md",
        "Changelog" => "changelog.md",
    ],
)

# Use DocumenterVitepress.deploydocs (NOT Documenter's): it flattens the VitePress
# build output (build/1/*) into the version root on gh-pages and rewrites the site
# `base`. Plain Documenter.deploydocs deploys build/ verbatim → the site lands as
# build/1/ and every asset/nav link 404s (the bug this site hit). Mirrors GLLVM.jl.
DocumenterVitepress.deploydocs(;
    repo = "github.com/itchyshin/DRM.jl.git",
    target = joinpath(@__DIR__, "build"),
    devbranch = "main",
    branch = "gh-pages",
    push_preview = false,
)
