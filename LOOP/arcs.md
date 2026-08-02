# Issue #291 Arc list

| Arc | Scope | Status | Verification / gate |
|---|---|---|---|
| 0 | Gaussian q4 REML design boundary and small ML-vs-baseline-REML harness | **done / merged** | [#361](https://github.com/itchyshin/DRM.jl/pull/361) → `main` |
| 1 | Baseline FD bottleneck note + candidate gates | **done / merged** | [#362](https://github.com/itchyshin/DRM.jl/pull/362) → `main` |
| 2 | Sparse-first characterization: report-only accounting + warm/order harness + H²/Szymek framing | **done / merged** | [#363](https://github.com/itchyshin/DRM.jl/pull/363) → `main` @ `5c251c8` |
| 3 | Intermediate p=16/nrep=3 deterministic warm-harness rung | **done / PR open** | [#365](https://github.com/itchyshin/DRM.jl/pull/365): fixture contract + read artifact; `diagnostic_only` because timed REML fits did not converge |

## Arc 2 acceptance

- Structural accounting fields in harness Markdown (`n_outer_phi`, `structural_evals_per_gradient_request`).
- Warm/order protocol with `evidence_class` ∈ {`diagnostic_only`, `warm_comparable`}.
- Framing note without invented Szymek quote.
- Focused contract test; Rose + Melissa closeout; scoped PR related to #291.
