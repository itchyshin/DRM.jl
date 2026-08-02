# Issue #291 Arc list

| Arc | Scope | Status | Verification / gate |
|---|---|---|---|
| 0 | Gaussian q4 REML design boundary and small ML-vs-baseline-REML harness | **done** | PR [#361](https://github.com/itchyshin/DRM.jl/pull/361) |
| 1 | Baseline FD bottleneck note + candidate gates | **done** | PR [#362](https://github.com/itchyshin/DRM.jl/pull/362) (stacked) |
| 2 | Sparse-first characterization: report-only accounting + warm/order harness + H²/Szymek framing | **done** | Focused test 23/23; warm artifact `warm_comparable`; Rose PASS; PR [#363](https://github.com/itchyshin/DRM.jl/pull/363) |

## Arc 2 acceptance

- Structural accounting fields in harness Markdown (`n_outer_phi`, `structural_evals_per_gradient_request`).
- Warm/order protocol with `evidence_class` ∈ {`diagnostic_only`, `warm_comparable`}.
- Framing note without invented Szymek quote.
- Focused contract test; Rose + Melissa closeout; scoped PR related to #291.
