# After-Task Report: O(p) Sparse Exact Marginal LSS Engine (#551)

- **Date:** 2026-08-28
- **Issue:** #551 (closes #551)
- **Perspectives:** Shannon (Coordination), Noether (Math/Engine), Karpinski (Performance), Curie (Simulation & Recovery)

## Summary of Completed Work

1. **Engine Implementation (`src/gaussian_sparse_lss.jl`):**
   - Implemented `_fit_phylo_gaussian_lss_sparse` for phylogenetic location-scale-scale models (`sd(species, phylogenetic) ~ ...`).
   - Root-conditioned augmented tree precision $Q$ ($q = 2G - 2$ nodes, $O(p)$ nnz) and Takahashi selected inverse $\text{diag}(\text{takahashi\_selinv}(Q))$ for leaf variances $v_t$.
   - Zero-cancellation GMRF sum-of-squares quadratic form $\text{quad}_{\text{sos}} = (r - Z\hat{a})' W (r - Z\hat{a}) + \hat{a}' Q \hat{a}$, preventing numerical breakdown when $\sigma_e \to 0$.
   - Cholesky symbolic pattern reuse across iterations.
   - Exact analytic gradients for $\beta_\mu$, $\beta_\sigma$, and vector $\alpha$.
   - Full REML support via $p_\mu$ sparse Cholesky backsolves for $X_\mu' V^{-1} X_\mu$.

2. **Integration & Routing (`src/gaussian_lss.jl`, `src/gaussian_core.jl`, `src/DRM.jl`):**
   - Wired `_fit_phylo_gaussian_lss_sparse` into `DRM.jl`.
   - Enabled routing via `sparse = true`, `algorithm = :sparse`, `algorithm = :sparse_lbfgs`, or automatically when $G > 500$.

3. **Test Suite & Verification (`test/test_lss_sparse.jl`):**
   - Verified ML and REML against dense comparator `_fit_structured_gaussian_lss` on scalar and multi-column $\alpha$ linear predictors (tolerance $\le 10^{-5}$ on log-likelihood, parameter estimates $\hat{\theta}$, standard errors, and BLUPs).
   - Wired into `test/runtests.jl`. All 38 test assertions in `test_lss_sparse.jl` and all 221 tests in the full LSS test battery pass cleanly.
   - Verified test dependencies with `tools/check_test_deps.py` (0 missing dependencies).

4. **Performance Benchmark:**
   - Evaluated scaling across tree depths:
     - $G = 16$: 1.74 ms (1.43× vs dense)
     - $G = 32$: 2.73 ms (71.52× vs dense)
     - $G = 64$: 4.65 ms (1,094.80× vs dense)
     - $G = 128$: 13.31 ms (748.19× vs dense)
