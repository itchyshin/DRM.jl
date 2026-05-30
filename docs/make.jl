using Documenter
using DRM

# Sidebar mirrors drmTMB's pkgdown navbar (5 dropdowns + Reference + Changelog).
# warnonly = true while the site is a Phase 0 stub: pages reference planned
# symbols and cross-refs that do not exist yet; we do not want those to fail the
# build. Tighten this (drop warnonly) as pages are filled via Workflow D.
makedocs(
    sitename = "DRM.jl",
    authors = "Shinichi Nakagawa",
    modules = [DRM],
    warnonly = true,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://itchyshin.github.io/DRM.jl",
        edit_link = "main",
    ),
    pages = [
        "Home" => "index.md",
        "Get started" => "get-started.md",
        "Model Guides" => [
            "model-guides/model-map.md",
            "model-guides/which-scale.md",
            "model-guides/distribution-families.md",
            "model-guides/model-workflow.md",
            "model-guides/convergence.md",
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
        "Diagnostics & Validation" => [
            "diagnostics-and-validation/figure-gallery.md",
            "diagnostics-and-validation/implementation-map.md",
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

deploydocs(
    repo = "github.com/itchyshin/DRM.jl",
    devbranch = "main",
    push_preview = false,
)
