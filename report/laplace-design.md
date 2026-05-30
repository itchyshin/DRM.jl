# Laplace wrapper design for DRM.jl v0.3+

**Audience.** Codex or Claude implementing DRM.jl v0.3.

GLLVM.jl (Gaussian-only) integrates random effects out in closed form via
the marginal MVN. That closed form does not exist for non-Gaussian
families. v0.3 needs one new piece of infrastructure: a TMB-like Laplace
wrapper. The rest (`bf()` parsing, design materialisation, parameter
packing, family blocks) ports from GLLVM.jl or `bf_sketch.jl`.

---

## 1. What Laplace approximation does

The model is

```
y_i  ~  family( g( X_i β + Z_i u ) )
u    ~  MVN( 0, Σ(θ) )
```

with fixed effects `β`, random-effect realisations `u`, variance-component
parameters `θ`, link `g`. The marginal likelihood is

```
p(y | β, θ)  =  ∫ p(y | β, u, θ) · p(u | θ) du
```

For Gaussian `y` with identity link this is closed form (what GLLVM.jl
exploits). For Student-t, Poisson, NB2, beta, ordinal, or any non-conjugate
link it must be approximated.

Laplace approximates the integrand as a Gaussian centred at the
conditional mode `û(β, θ) = argmax_u log p(y, u | β, θ)`, with curvature
given by the negative Hessian of the log joint at that mode:

```
log p_L(y | β, θ)  =  log p(y, û | β, θ)  -  0.5 · log det H(β, û, θ)
                                          +  0.5 · k · log(2π)
```

where `H = -∂²/∂u∂uᵀ log p(y, u | β, θ)` at `u = û` and `k = dim(u)`. The
approximation is exact for Gaussian conjugate likelihoods, good for
log-concave non-Gaussian ones when `u` is well-identified, and degrades
for heavy-tailed posteriors and zero-information levels.

---

## 2. What TMB does (and why Julia cannot copy it naively)

TMB ([Kristensen et al. 2016](https://doi.org/10.18637/jss.v070.i05))
implements Laplace as a feature of `MakeADFun()`. The C++ template
declares two parameter blocks:

```cpp
PARAMETER_VECTOR(beta);   // fixed effects
PARAMETER_VECTOR(u);      // random effects
```

The R call passes `random = "u"`:

```r
obj <- TMB::MakeADFun(data, parameters, random = "u", DLL = "drmTMB")
```

`MakeADFun` then (i) CppAD-reverse-modes the joint log-density to give
sparse `H`; (ii) inner-Newton iterates to find `û` on every outer call;
(iii) returns marginal `log p_L`; (iv) exposes gradients w.r.t. `β, θ`
via implicit differentiation `dû/dβ = -H_uu⁻¹ H_uβ`, also through CppAD.
Outer `nlminb` never sees `u`. drmTMB uses this directly —
`random = spec$random_names` at `R/drmTMB.R:225`, with `u_mu, u_sigma,
u_phylo, u_re_cov` declared as `PARAMETER_VECTOR` in
`src/drmTMB.cpp:123–134`.

Julia has no equivalent baked in. ForwardDiff/Enzyme/Zygote each do AD
well in isolation, but none ships a stock "inner-Newton + implicit
gradient" wrapper composable with arbitrary log-densities. Three Julia
packages live in the right neighbourhood (§3) but each has caveats.

---

## 3. The Julia path — three options, ranked

### (a) Hand-rolled Laplace via ForwardDiff + implicit-function theorem

Build from primitives. Each outer call `ℓ(β, θ)`:

1. **Inner optimisation.** Find `û` by Newton on `-log p(y, u | β, θ)` from
   `u = 0` (warm-started in production). ForwardDiff gives the inner
   gradient/Hessian over hand-written conditional log-densities.
2. **Marginal evaluation.** `log p_L = log p(y, û) - 0.5 log det H_uu + 0.5 k log(2π)`,
   reusing the Cholesky from the last Newton step.
3. **Outer gradient via implicit differentiation.** Stationarity
   `∇_u log p(y, û) = 0` gives `dû/dβ = -H_uu⁻¹ H_uβ`, similarly for θ.
   Then `∂ log p_L/∂β = ∂/∂β [log p(y, û) - 0.5 log det H_uu]` with `û`
   treated as a function of `β`. The implicit step replaces
   ForwardDiff-through-Newton.

**Effort.** 200–400 LOC of linear algebra plus per-family objectives (§4).
2 weeks for the core wrapper.

**Pros.** Pure Julia, no exotic deps, deterministic, full control over AD
nesting, easy to surface diagnostics. Tractable for the modal
block-diagonal `(1|g)` case.

**Cons.** AD-nesting care required. Type-stability traps real. Each
correctness step needs its own fixture.

### (b) ImplicitDifferentiation.jl + DifferentiationInterface.jl

[`ImplicitDifferentiation.jl`](https://github.com/JuliaDecisionFocusedLearning/ImplicitDifferentiation.jl)
automates step (a3): user supplies a forward map (inner Newton) and a
residual (`∇_u log p(y, û) = 0`), the package supplies gradients via
custom chain rules.
[`DifferentiationInterface.jl`](https://github.com/JuliaDiff/DifferentiationInterface.jl)
([Dalle & Hill 2024](https://arxiv.org/abs/2505.05542)) lets us swap
ForwardDiff/Enzyme without rewriting call sites.

**Effort.** ~100 LOC plus per-family objectives.

**Pros.** Less hand-rolled linear algebra. Clean separation of solve and
differentiated wrapper. Active maintainers; Blondel et al. 2022 backs the
design.

**Cons.** Younger packages; composition with all AD backends (especially
Enzyme over sparse Cholesky) needs verification. Sparse Hessians route
through SparseDiffTools.jl, less turnkey than TMB's CppAD. Worth a 3-day
spike against (a) before committing.

### (c) Wrap a third-party Julia Laplace package

[`MarginalLogDensities.jl`](https://github.com/ElOceanografo/MarginalLogDensities.jl)
(v0.4.5, Oct 2025) is explicitly "TMB-like functionality in pure Julia".
User supplies a joint log-density `f(u, data)` and index set `iw` to
marginalise; constructor returns a Laplace-approximated marginal. Sparse
Hessians via SparseDiffTools are documented.

**Critical caveat.** The docs state "At present we can't differentiate
through the Laplace approximation". Until that lands, DRM.jl's outer
optimiser cannot use LBFGS through this package — only gradient-free
outer search (NelderMead, finite-difference BFGS), which is a real
wall-clock regression vs GLLVM.jl. This rules (c) out as the primary
path. Revisit at v0.4+ if gradient support lands.

No `TMB.jl` or `RTMB.jl` Julia port exists as of May 2026.

**Recommendation.** Start with (a). Run a 3-day spike on (b) once one
family works in (a). Use (c) only as a sanity-check oracle.

---

## 4. Per-family integration

Each non-Gaussian family contributes one inner conditional log-density
`log p(y_i | u, β, θ)`. The inner objective is

```
J(u; β, θ) = -Σ_i log p(y_i | u, β, θ) + 0.5 · uᵀ Σ(θ)⁻¹ u
```

Each family file (`src/families/*.jl`) defines `logpdf_conditional(family, y, η)`
where `η = X β + Z u`. Coverage targets for v0.3:

| family | link | inner log-pdf core |
|---|---|---|
| `StudentT(ν)` | identity | `logpdf(TDist(ν), (y-μ)/σ)/σ` |
| `Poisson` | log | `y·η − exp(η) − lgamma(y+1)` |
| `NegBinomial2(φ)` | log | NB2 lgamma form |
| `Beta(φ)` | logit | logit-Beta with precision φ |
| `OrdinalCumulative(K)` | logit | `log(F(θ_k − η) − F(θ_{k−1} − η))` |

Coverage: Student-t with RE on `mu`; Poisson + `(1|id)`; NB2 + phylo;
Beta + `(1|id)`; ordinal + random intercept. Edge cases (zero counts in
NB2, boundary values in Beta) live in the family files. All five plug
into the same Laplace wrapper.

---

## 5. Integration with `bf()` and SharedRE blocks

`bf_sketch.jl` parses `(1 | p | id)` into a `SharedRE` whose label `p`
ties matching RE terms across `dpar`s into one structured covariance
block. `CovBlockSpec` (`bf_sketch.jl:284`) records block size `k`,
participating `dpar`s, and grouping factor.

For block `b` of size `k_b` with `n_b` levels of its grouping factor:

```
u_b ∈ ℝ^{k_b · n_b}     stacked as [u_b,1 ; u_b,2 ; ... ; u_b,n_b]
Σ_b = I_{n_b} ⊗ C_b(θ_b)    where C_b is the k_b × k_b log-Cholesky block
```

The full `u` is `vcat(u_b for b in blocks)` and `Σ` is block-diagonal
across labels:

```
Σ(θ) = blockdiag( I⊗C_p,  I⊗C_core,  Λ⊗C_phylo )

H_uu = blockdiag( per-id k=2 blocks,   # label p
                  per-id k=4 blocks,   # label core (mu1,mu2,σ1,σ2)
                  sparse Hadfield–Nakagawa pattern  # phylo, k=4 per node )
```

`Λ` is the inverse phylo-covariance (`Q_phylo`, `src/drmTMB.cpp:85`). The
wrapper builds `Σ(θ)⁻¹` once per outer step from per-block log-Cholesky
parameters and a precomputed inverse-phylo factor.

---

## 6. Sparsity exploitation

Two sparse paths must work day one.

**`(1|g)` and lme4-style REs.** `H_uu` is block-diagonal across levels of
`g`. Solving for `û` and `log det H_uu` costs `O(n_levels · k³)`, not
`O((n_levels · k)³)`. Inner Newton stores per-level Cholesky factors as
`Vector{Cholesky}`.

**`phylo()` REs.** `H_uu` inherits the Hadfield–Nakagawa sparse pattern
from `Q_phylo`. Port GLLVM.jl's `sparse_phy.jl`: species-axis precision
has nonzeros only on tree edges, sparse Cholesky bandwidth equals tree
depth, `log det H_uu` reads off its diagonal. Reuse `Q_phylo` and the
`log_det_Q_phylo` cache from drmTMB.

Both paths plug in by tag dispatch on block kind.

---

## 7. Convergence diagnostics

drmTMB does not surface these by default. DRM.jl should:

- **Inner Newton.** Per outer evaluation, log iteration count and final
  `‖∇_u log p(y, û)‖_∞`. Warn if iterations > 50 per block or grad norm
  > `1e-6 · k`.
- **Conditioning.** Report `cond(H_uu)` at `û` (cheap from the Cholesky).
  Flag any block with `cond > 1e10`.
- **Prior compatibility.** Sanity-check `diag(Σ(θ)) > 0` and finite.
  Refuse to compute `log p_L` if violated.

Surface all three in `fit_drm()$diagnostics`. Tests assert these fields
exist on each fixture.

---

## 8. Test-parity goal

Side-by-side with `drmTMB::drmTMB(..., family = ...)` on 10 fixtures:
2 × small-n (n=50; q=1, q=4 phylo); 2 × medium-n (n=500; dense IID RE,
sparse phylo); 2 × large-n (n=2000; NB2 + `(1|id)`); 2 × bivariate phylo
(q=4 location-scale); 1 × ordinal + RI; 1 × Beta + `(1|id)`.

Acceptance: `max |Δ logLik| < 1e-3` across all 10 (tightens to `1e-4`
once inner Newton tolerance is hardened to `1e-10`). One order of
magnitude looser than the Gaussian POC gate to absorb Laplace's `O(1/n)`
bias.

---

## 9. Effort estimate

| Task | Estimate | Parallelisable? |
|---|---|---|
| Hand-rolled core Laplace wrapper (option a) | 2 weeks | no |
| Option (b) spike — eval ImplicitDifferentiation.jl | 3 days | no |
| Per-family inner-objective files × 5 (3 days each) | 15 days | yes — 5 agents → 3 days wall-clock |
| Sparse phylo path port from GLLVM.jl | 4 days | partial overlap with families |
| Convergence diagnostics + tests | 3 days | yes |
| Test-parity vs drmTMB on 10 fixtures | 3 days | yes |
| **v0.3 wall-clock budget** | **4–6 weeks** | |

Solo developer: 6 weeks. With parallel agents on separate family files,
4 weeks wall-clock. Do not promise less.

---

## References

- Kristensen et al. (2016). TMB: Automatic differentiation and Laplace
  approximation. *JSS* 70(5). <https://doi.org/10.18637/jss.v070.i05>
- Blondel et al. (2022). Efficient and modular implicit differentiation.
  *NeurIPS 2022*. Backs ImplicitDifferentiation.jl.
- Dalle & Hill (2024). A common interface for automatic differentiation.
  <https://arxiv.org/abs/2505.05542>
- [ImplicitDifferentiation.jl](https://github.com/JuliaDecisionFocusedLearning/ImplicitDifferentiation.jl),
  [DifferentiationInterface.jl](https://github.com/JuliaDiff/DifferentiationInterface.jl),
  [MarginalLogDensities.jl](https://github.com/ElOceanografo/MarginalLogDensities.jl).
- `julia/bf_sketch.jl` — multi-formula parser, `CovBlockSpec`.
- `drmTMB/src/drmTMB.cpp` — TMB template; PARAMETER blocks at L. 123–137.
- `drmTMB/R/drmTMB.R:221` — `MakeADFun(..., random = spec$random_names)`.
