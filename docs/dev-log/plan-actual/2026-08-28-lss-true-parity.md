# Melissa Plan vs Actual Reconciliation — LSS "True Parity + Better" Arc

**Date:** 2026-08-28
**Reconciler:** Melissa (Sonnet / Low)
**Scope:** Location-Scale-Scale (LSS) True Parity Arc (#558, #559, #551, Capability Row 12)

---

### Planned vs Actual Matrix

| Slice | Planned Deliverable | Planned Verification | Actual Result | Deviation Classification |
|---|---|---|---|---|
| **S1 (#558)** | Dense single & multi-component LSS REML in `src/gaussian_lss.jl` | `test/test_lss_reml.jl` proving $\hat{\sigma}_b \ge \hat{\sigma}_{b,\text{ML}}$ and finite SEs | Landed with normalized $-0.5 p_\mu \log(2\pi)$ convention, lifted refusals in `test_lss_phylo.jl` & `test_lsss_multi.jl`, 41/41 passing tests | Adaptive (exact fit with roadmap) |
| **S2 (#559)** | Missing response handling for LSS routes in `src/gaussian_core.jl` & `src/gaussian_lss.jl` | `test/test_lss_missing_response.jl` verifying `include` == `drop` and all-masked species | Landed with full-tree $Z_g$ derivation + observed row subsetting, dof guards, and glmmTMB drop warnings, 57/57 passing tests | Adaptive (complete coverage) |
| **S3a (#551a)**| Cancellation probe on sparse marginal quad form | Self-contained probe comparing $\sigma_e \to 0$ against `BigFloat` | Proved GMRF sum-of-squares formulation achieves $10^{-16}$ relative error across all $\sigma_e \in [1, 10^{-10}]$ where naive Woodbury subtraction lost all digits | Adaptive (derivation unblocked S3b) |
| **S3b (#551b)**| $O(p)$ sparse exact marginal LSS engine with Takahashi $\alpha$-gradients | `test/test_lss_sparse.jl` matching dense comparator to $\le 10^{-5}$ | Implemented in `src/gaussian_sparse_lss.jl` with Cholesky pattern reuse, analytic gradients, sparse REML, passing 38/38 tests and demonstrating up to 1,000× speedup at $G=64$ | Adaptive (superlinear speedup achieved) |
| **S4** | Update drmTMB R-side bridge & promote Capability Row 12 | `parity_ledger.py` reporting `CLOSURE: PASS` | Widened `drm_julia_reml_supported()`, promoted Row 12 to `covered`, regenerated TSVs, verified `CLOSURE: PASS` | Adaptive (parity closed) |

---

### Reconciliation Verdict

- **Scope:** 100% of planned slices completed without dropped requirements.
- **Safety & Gates:** Zero violations. Protected files (`.codex/agents/shannon-coordinator.toml`) remained untouched. No GPL source vendoring.
- **Verification Evidence:** All 221 LSS tests passing across 6 test suites; all imports declared in `test/Project.toml`.
- **Status:** **PASS — ARC COMPLETE**.
