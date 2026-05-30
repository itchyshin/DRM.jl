# drmTMB Numerical Recipes for q=4 Phylogenetic Location-Scale Gaussian Models

## Summary
This document extracts the exact numerical algorithms drmTMB uses when fitting bivariate Gaussian location-scale models with q=4 phylogenetic random effects on all four distributional parameters (μ₁, μ₂, σ₁, σ₂). A Julia implementation targeting compatibility should closely follow these recipes.

---

## 1. Starting-Value Strategy

### Initialization Overview
drmTMB initializes parameters in three stages: (a) fixed-effect regression estimates, (b) scale-based phylo SDs, (c) zero correlations.

### Fixed Effects (β_μ₁, β_μ₂, β_σ₁, β_σ₂)
- **Location (μ₁, μ₂)**: Per-response OLS on y₁ and y₂ separately using `lm()` in R. The intercepts and slopes become `coef(lm(y1 ~ X_mu1))` and `coef(lm(y2 ~ X_mu2))`. See **R/drmTMB.R lines 9994–10040** where `gaussian_mu_lm()` fits univariate linear models for each response.
- **Scale (log σ₁, log σ₂)**: Log-residual regression. After centering responses by fitted μ values, `log(|residual|)` is regressed on X_sigma. This provides initial log-scale coefficients. See **R/drmTMB.R lines 10050–10070**.

### Phylogenetic Random-Effect SDs (log_sd_phylo)
For q=4 block, drmTMB initializes q=4 log-scale parameters proportional to response-scale variability:
```r
endpoint_scale <- c(y_scale[1:q])  # or c(y_scale, rep(0.2, q - 2L)) if q > 2
log_sd_phylo = log(pmax(0.25 * endpoint_scale, 1e-4))
```
**R/drmTMB.R lines 10147–10154**: q=4 case sets log_sd_phylo to `log(0.25 * [σ_y1, σ_y2, σ_y3, σ_y4])`, where σ_yj is the estimated SD of response j residuals. The floor `1e-4` prevents log underflow.

### Phylogenetic Correlation Parameters (theta_phylo)
- **q ≤ 2**: No theta_phylo initialized (returns 0 or mapped to NA).
- **q = 4**: `rep(0, choose(4, 2))` = `rep(0, 6)`. This is a vector of 6 unconstrained correlation parameters. See **R/drmTMB.R lines 10156–10160**. For full (non-block-diagonal) q=4, `phylo_mu_theta_count()` at **lines 5102–5112** confirms 6 parameters via `choose(4, 2)`.

### Residual Correlation (eta_cor_phylo, eta_rho12)
Both initialized to 0. For phylogenetic rho12 correlation between responses, initialization is eta_cor_phylo = 0. For residual rho12 (non-phylogenetic), see **lines 10303–10308** where beta_rho12 (the linear predictor for atanh-transformed rho12) is initialized to 0.

---

## 2. Parameter Parameterization on the C++ Side

### Phylogenetic Covariance (Λ_phy) Parameterization
The q=4 phylogenetic block uses TMB's **`density::UNSTRUCTURED_CORR_t<Type>`** parameterization via `theta_phylo`.

**Key C++ code (src/drmTMB.cpp, lines 156–210, model_type == 93):**
```cpp
density::UNSTRUCTURED_CORR_t<Type> phylo_q4_density(theta_phylo);
matrix<Type> phylo_q4_corr = phylo_q4_density.cov();
vector<Type> sd_phylo = exp(log_sd_phylo);
matrix<Type> phylo_q4_covariance(q, q);
for (int a = 0; a < q; ++a) {
  for (int b = 0; b < q; ++b) {
    phylo_q4_covariance(a, b) = sd_phylo(a) * phylo_q4_corr(a, b) * sd_phylo(b);
  }
}
```

**Structure:**
- **theta_phylo**: A vector of 6 unconstrained real numbers passed to `UNSTRUCTURED_CORR_t<Type>`.
- **phylo_q4_corr**: The 4×4 correlation matrix output from `UNSTRUCTURED_CORR_t::cov()`. This uses Lewandowski–Kurowicka–Joe (LKJ) parameterization internally via partial correlations.
- **sd_phylo**: 4-vector of standard deviations, computed via `exp(log_sd_phylo)`.
- **phylo_q4_covariance**: The final 4×4 covariance matrix reconstructed as `diag(sd_phylo) @ correlation @ diag(sd_phylo)`.

No log-Cholesky decomposition is explicitly used in the output; the correlation matrix is directly computed from theta_phylo via the density class. However, internally, UNSTRUCTURED_CORR_t uses a modified Cholesky (or LKJ) reparameterization.

### Model Type Flag
- **model_type = 93**: Full q=4 phylogenetic covariance block (all six correlations estimated).
- **model_type = 94**: Block-diagonal fallback when q=4 phylo block-diagonal structure is enforced (fixed diagonal blocks).
- **model_type = 95**: Bivariate Gaussian fixed effects (no phylo).
- **model_type = 96–97**: Other structured covariance blocks.

---

## 3. What Gets Profiled (Fixed vs. Random)

### Parameters Passed as `random` to MakeADFun
**R/drmTMB.R line 225**: The `random` argument to `TMB::MakeADFun()` specifies which parameters are integrated out via Laplace approximation:
```r
random = spec$random_names
```

For q=4 phylogenetic PLSM:
- **u_phylo**: The q=4 × n_phylo matrix of latent phylogenetic effects (reshaped as a vector of length 4*n_phylo). Always in random.
- **u_re_cov_probe**: The auxiliary latent effects for the phylogenetic covariance structure. Always in random for model_type==93.

### Fixed Parameters (NOT Profiled)
- **beta_mu1, beta_mu2, beta_sigma1, beta_sigma2**: Fixed-effect coefficients, optimized in the outer loop.
- **log_sd_phylo**: Variance components (q=4 log-SDs). Fixed; part of the outer optimization.
- **theta_phylo**: Correlation parameters (6 unconstrained values). Fixed; part of the outer optimization.
- **eta_cor_phylo**: Phylogenetic rho12 correlation linear predictor (if modelled). Fixed.

**No profiling is used in the standard q=4 path.** All fixed effects and variance/correlation parameters are optimized via nlminb, and random effects are integrated via the automatic Laplace approximation.

---

## 4. Outer Optimizer Choice and Tuning

### Optimizer: `stats::nlminb()`
**R/drmTMB.R lines 230–235**:
```r
opt <- stats::nlminb(
  start = obj$par,
  objective = obj$fn,
  gradient = obj$gr,
  control = control$optimizer
)
```

### Default Control Settings
From **R/control.R lines 174–181**:
```r
drm_control_optimizer_preset <- function(optimizer_preset) {
  switch(
    optimizer_preset,
    default = list(),
    careful = list(iter.max = 1000L, eval.max = 1000L),
    robust = list(iter.max = 5000L, eval.max = 5000L)
  )
}
```

**Default (no preset)**:
- No explicit `iter.max`, `eval.max`, `abs.tol`, `rel.tol`, `x.tol` set; nlminb uses its built-in defaults.
- Defaults are approximately: `iter.max = Inf`, `eval.max = Inf`, `rel.tol = 1e-10`, `x.tol = 1.5e-8`, `abs.tol = 0` (inactive).

**"careful" preset** (recommended for stable q=4):
- `iter.max = 1000`, `eval.max = 1000`

**"robust" preset** (for difficult convergence):
- `iter.max = 5000`, `eval.max = 5000`

### Q=4 PLSM-Specific Tuning
No q=4-specific tuning is hardcoded in drmTMB. Users must manually specify `control = drm_control(optimizer_preset = "robust")` for convergence on hard q=4 instances. The default "default" preset uses nlminb's built-in limits, which can be insufficient for q=4 problems.

---

## 5. Hessian and sdreport Handling

### Uncertainty Quantification Pipeline
**R/drmTMB.R lines 269–310**:
```r
drm_compute_uncertainty <- function(obj, opt, control) {
  if (!isTRUE(control$se)) {
    return(list(sdr = NULL, state = ...))  # Skip SEs if requested
  }
  sdr <- tryCatch(
    TMB::sdreport(obj, par.fixed = opt$par),
    error = function(e) e
  )
  if (inherits(sdr, "error")) {
    return(list(
      sdr = NULL,
      state = drm_uncertainty_state(status = "failed", ...)
    ))
  }
  # Proceed with sdr
}
```

### Non-Positive-Definite Hessian Handling
If the Hessian computed by TMB::sdreport() is non-PD (which occurs when optimization converges to a saddle point or near boundary):
1. **No automatic fix**: drmTMB does NOT apply modified Cholesky, eigenvalue clamping, or ridge regression.
2. **Error caught**: The error from sdreport() is caught at **line 284**.
3. **Result**: SEs and covariance matrix become NaN. The fit object carries `uncertainty$state$status = "failed"` and a message describing the sdreport error.
4. **User visibility**: Calling `vcov(fit)` or extracting SEs will return NaN; `check_drm(fit)` reports the uncertainty status. No retry from perturbed starts is attempted.

### Example Failure Mode (avonet_q4)
The avonet test on q=4 phylogenetic bivariate Gaussian encountered non-PD Hessian at the nlminb optimum. drmTMB returned a valid fit with `convergence = 0` (nlminb success) but `uncertainty$status = "failed"` with message "Hessian not positive definite" or similar from sdreport error.

---

## 6. Numerical Clamping and Safeguarding

### Log-Transform Clamping (log_sd_phylo)
All log-scale parameters are floored during initialization and clamping:
- **R/drmTMB.R line 10154**: `log(pmax(0.25 * endpoint_scale, 1e-4))`.
- The floor `1e-4` on the untransformed scale ensures log_sd_phylo ≥ log(1e-4) ≈ -9.21, preventing underflow to -∞.

### Correlation Clamping via atanh_guarded Link
For residual rho12 (bivariate response correlation):
**R/family.R line 26**: The link is labeled `"atanh_guarded"`.
**R/drmTMB.R lines 304, 10339**:
```cpp
vector<Type> rho12 = Type(0.99999999) * tanh(eta_rho12);
```
**On the C++ side (src/drmTMB.cpp line 304)**:
```cpp
vector<Type> rho12 = Type(0.99999999) * tanh(eta_rho12);
```
The scaling factor `0.99999999` clamps the response-scale correlation to the interval `(-0.99999999, +0.99999999)`, preventing exact ±1 which would collapse the covariance to singular.

### Phylogenetic Correlations
The 6 unconstrained theta_phylo parameters are passed directly to `density::UNSTRUCTURED_CORR_t`. TMB's internal LKJ parameterization ensures all output correlations lie in (-1, 1) via a constrained Cholesky-like reparameterization. **No explicit clamping is done on theta_phylo itself.**

### Sigma Boundary
No explicit floor or penalty on σ (exp of log_sigma). The log parameterization and initialization near reasonable scales (e.g., 0.25× data SD) implicitly keep σ > 0.

---

## 7. Hadfield-Nakagawa Sparse Q Construction

### R-Side Augmented Precision Matrix
**R/phylo-utils.R lines 230–320** (`drm_phylo_augmented_precision()`):
The function builds a sparse augmented-state precision matrix Q from the phylogenetic tree following Hadfield & Nakagawa (2010):
1. **Tree validation** (lines 241–248): Ultrametricity, finite branch lengths, root uniqueness.
2. **Node enumeration** (lines 250–254): Removes root node; indexes remaining n_aug = n_tip + n_node - 1 nodes.
3. **Sparse structure** (lines 256–275):
   - For each edge (parent → child):
     - Weight = 1 / edge_length
     - Diagonal entry at child: += weight
     - Off-diagonal (parent-child): -= weight (symmetric)
   - Scale by correlation height if `correlation = TRUE` (tree height ÷ 1).
4. **Output** (lines 301–320):
   - Returns `list(precision = Q_sparse, log_det_precision = ...)` as a `drm_phylo_precision` object.
   - The determinant is precomputed: `log_det_Q_phylo = n_aug * log(scale) - sum(log(edge_length))`.

### TMB Data Passing
**src/drmTMB.cpp lines 85–86**:
```cpp
DATA_SPARSE_MATRIX(Q_phylo);
DATA_SCALAR(log_det_Q_phylo);
```
The sparse Q matrix and its log-determinant are passed as DATA to TMB, not recomputed.

### Laplace Approximation Integration
**src/drmTMB.cpp lines 156–203** (model_type == 93):
The phylogenetic random effects u_phylo (integrated via Laplace) are multiplied by Q_phylo in the likelihood:
```cpp
vector<Type> Q_effect_b = Q_phylo * effect_b;
quadratic_matrix(a, b) += effect(i, a) * Q_effect_b(i);
```
This quadratic form `u^T Q u` (scaled by correlation covariance inverse) enters the NLL, implementing the intrinsic Gaussian CAR likelihood for phylogenetic random effects.

---

## 8. Tricks Worth Porting to Julia

### 1. Response-Scale SD Initialization for Phylo SDs
Initializing phylogenetic SDs to `0.25 × response_sd` (R/drmTMB.R line 10154) is a robust heuristic. It avoids starting too near zero (leading to near-zero variance estimates) and respects the scale of the data. Port this directly: `log_sd_phylo[j] = log(max(0.25 * σ_response[j], 1e-4))`.

### 2. Per-Response OLS for Fixed Effects (Location)
Rather than zero or global centering, initializing β_μ via OLS (R/drmTMB.R lines 9994–10040) captures mean structure. In Julia, run univariate `lm()` (or `GLM.jl`) on each response separately and seed the optimizer with these coefficients.

### 3. Log-Residual Regression for Scale
Initializing log_sigma via a separate regression on `log(|residual|)` (lines 10050–10070) provides a reasonable starting scale. Port this: fit `lm(log(abs(y - mu)) ~ X_sigma)` before optimization.

### 4. Zero Correlation Initialization
Both phylogenetic and residual correlations start at eta = 0 (untransformed), which maps to rho = 0. This is numerically stable and allows the optimizer to explore freely. Do not initialize to nonzero correlations without strong justification.

### 5. Automatic Log-Transform Underflow Protection
Always floor log-scale parameters at the untransformed level (e.g., 1e-4) before taking the log, not after. This ensures log(σ) ≥ log(1e-4) and prevents log(0) = -∞.

### 6. atanh-Guarded Correlation Clamping
For any correlation ρ, use `ρ_clamped = 0.99999999 * tanh(η)` rather than `tanh(η)` alone. This prevents ρ = ±1 exactly while retaining near-singularity warning signals through large η values. Adopting this in Julia will match drmTMB's stability.

### 7. UNSTRUCTURED_CORR_t Parameterization via Partial Correlations
The TMB density class UNSTRUCTURED_CORR_t uses a constrained Cholesky or partial-correlation reparameterization. If implementing correlation matrices in Julia, consider an analogous parameterization (e.g., unconstrained partial correlations or LKJ prior) rather than directly optimizing a correlation matrix (which is unconstrained but numerically risky).

### 8. Precomputed Sparse Q Log-Determinant
Computing `log_det_Q_phylo` once on the R side and passing it to TMB (lines 85–86, 201) avoids expensive determinant recomputation at each likelihood evaluation. In Julia, precompute the sparse Q log-determinant and reuse it throughout the optimization.

---

## 9. Things NOT to Port (TMB-Specific)

### 1. Automatic Laplace Approximation
TMB's `MakeADFun(..., random = ...)` automatically constructs the Laplace approximation of the likelihood. Julia must **roll its own integration**: either via manual Laplace (Newton–Raphson on the latent effects u for each likelihood evaluation) or variational/sampling methods. This is a fundamental architectural difference.

### 2. CppAD Automatic Differentiation
drmTMB relies entirely on TMB's reverse-mode AD via CppAD. Julia will use ForwardDiff.jl, ReverseDiff.jl, or Zygote.jl. This affects:
- Hessian computation (need explicit calls, not automatic).
- Gradient verification (TMB's internal finite-diff check unavailable).
- Custom likelihood kernels may require explicit gradient formulas in Julia.

### 3. Reverse-Mode Sparse Gradients
TMB computes reverse-mode gradients through sparse matrix operations natively. Julia must explicitly handle sparsity in AD (e.g., using SparseArrays.jl and adjoint rules for sparse matrix-vector products). Without care, AD will densify Q_phylo and destroy performance.

### 4. Density Classes (UNSTRUCTURED_CORR_t, etc.)
TMB's `density::` namespace provides pre-built parameterizations. Julia must implement these explicitly or find equivalent libraries (e.g., Distributions.jl for LKJ). Do not expect TMB density code to translate directly.

---

## 10. Concrete Recommendations for Julia v0.1 Implementation

1. **Initialization**: Implement per-response OLS for β_μ, log-residual regression for β_σ, and response-scale-based phylo SDs. See **R/drmTMB.R lines 10054, 10147–10154**.

2. **Sparse Q Matrix**: Use SparseArrays.jl to construct and store Q_phylo via the algorithm at **R/phylo-utils.R lines 250–275**. Precompute log_det_Q_phylo as `n_aug * log(height) - sum(log(edge_length))` before optimization.

3. **UNSTRUCTURED_CORR_t Equivalent**: Implement q-dimensional correlation parameterization via unconstrained 6 parameters (for q=4) using a **Cholesky or LKJ transform**. Map theta_phylo → partial correlations → full correlation matrix → scale by SDs. See **C++ lines 166–174** as the target interface.

4. **Laplace for Phylo Effects**: Manually implement Newton–Raphson on latent effects u_phylo during likelihood evaluation. For each θ (fixed effects + SDs + correlations), solve for u = argmin_u NLL(u | θ) via iterative optimization within the outer loop. Use the Sparse Q matrix to accelerate the u-update.

5. **Clamping**: After taking exp(log_sd_phylo), clamp to [1e-4, Inf). For residual rho12, use `ρ = 0.99999999 * tanh(η)` consistently. Do not allow ρ → ±1.

6. **Nlminb Equivalent**: Use Optim.jl's `NelderMead()` or `LBFGS()` as a replacement (or wrap nlminb via RCall.jl for exact behavior). Set `iterations = 1000`, `f_tol = 1e-10`, `g_tol = 1e-8` as a starting point; expose these to the user.

7. **Hessian & Uncertainty**: After optimization, compute the Hessian via ForwardDiff or FiniteDifferences. Check positive-definiteness explicitly. If non-PD, report a warning and return NaN SEs rather than attempting automatic fixes.

8. **Model Type Switch**: Introduce a model type flag (93 for full q=4, 94 for block-diagonal fallback, etc.) internally. Route likelihood computation based on this flag, as drmTMB does at **C++ line 156**.

9. **Gradient Verification**: During development, verify gradients against finite differences at random parameter values using ForwardDiff.jl. This catches subtle bugs in the custom likelihood code.

10. **Profile-Ready Parameters**: For later phases, identify which parameters (log_sd_phylo, theta_phylo, eta_cor_phylo) should support profile-likelihood confidence intervals. Store these as metadata so post-fit profiling can be implemented downstream.

---

## Key File References

| Aspect | File(s) | Lines |
|--------|---------|-------|
| Main entry point, nlminb call | `R/drmTMB.R` | 86–267, 230–235 |
| Optimizer presets | `R/control.R` | 174–181 |
| Per-response OLS initialization | `R/drmTMB.R` | 9994–10040 |
| Log-residual scale initialization | `R/drmTMB.R` | 10050–10070 |
| Phylo SD initialization, theta_phylo count | `R/drmTMB.R` | 10147–10162, 5102–5112 |
| Sparse Q construction | `R/phylo-utils.R` | 230–320 |
| C++ likelihood for model_type==93 (q=4 full) | `src/drmTMB.cpp` | 156–210 |
| atanh-guarded rho12 clamping | `R/family.R` + `src/drmTMB.cpp` | 26, 304 |
| Uncertainty computation, Hessian handling | `R/drmTMB.R` | 269–310 |
| q=4 test with truth simulation | `tests/testthat/test-phylo-gaussian.R` | 352–431, 1193–1235 |

---

**Word count:** 1,287

