# Engine internals and advanced constructors

!!! warning "Developer reference"
    This appendix records docstrings for the sparse, coevolution, bridge, and
    marginal-likelihood implementation surface. Names beginning with `_` are
    nonpublic implementation helpers. Exported advanced constructors are
    included for source coverage, not as a claim that every combination is a
    supported `drm(...)` route. Start with the model guides and capability
    matrix for ordinary fitting.

## Marginal-method and association internals

```@docs
DRM.AGHQ
DRM.Laplace
DRM.Variational
DRM.MarginalMethod
DRM.LatentNormal
DRM._aghq_1d_logint
DRM._aghq_require_1d
DRM._assoc_logdiffexp
DRM._poisson_group_aghq_logint
```

## Augmented phylogeny and sparse linear algebra

```@docs
DRM.AugmentedPhy
DRM.Vinv_mul
DRM.build_M
DRM.exact_traces
DRM.logdetV_val
DRM.make_phy
DRM.make_problem_from_Q
DRM.q4_marginal_diagnostic
DRM.takahashi_diag
DRM.takahashi_selinv
DRM.theta_len
DRM.unpack_theta
DRM.pack_theta
```

## q=4 and Fisher-z evaluators

```@docs
DRM.beta_widths
DRM.fit_q4_reml
DRM.fit_q4_sparse_fisherz
DRM.fz_DRD
DRM.fz_R
DRM.fz_R_chol
DRM.fz_init_from_Sigma
DRM.fz_marginal_and_grad
DRM.fz_marginal_nll
DRM.fz_psi_len
DRM.fz_psi_to_theta
DRM.fz_unpack_psi
DRM.marginal_and_exact_grad
```

## Coevolution and phylogenetic interaction kernels

```@docs
DRM.coevo_marginal_cov
DRM.coevo_pack
DRM.coevo_unpack
DRM.cov_to_lc
DRM.fit_coevolution
DRM.fit_coevolution_q2_reml
DRM.fit_coevolution_q2_residual
DRM.fit_phylo_interaction
DRM.lc_len
DRM.lc_metric
DRM.make_coevo_problem
DRM.make_coevo_problem_from_covariance
DRM.make_coevo_problem_from_precision
DRM.phylo_interaction_nll
DRM.simulate_coevolution
```

## Bridge and mixed-family payload helpers

```@docs
DRM._bridge_dpars
DRM._bridge_dpars_newdata
DRM._bridge_meta_parts
DRM._bridge_trials
DRM.drm_bridge_q2_known_precision
DRM.drm_bridge_q2_phylo
DRM.fit_mixed_family
DRM._mf_nparams
```

## Location-scale and structured-fit kernels

```@docs
DRM._fit_bivariate_q4_structured
DRM._fit_corr_locscale
DRM._fit_fixed_gaussian_reml
DRM._fit_gaussian_locscale_phylo
DRM._fit_locscale
DRM._fit_ranef_gaussian
DRM._fit_sigma_axis_re
DRM._general_cov_setup
DRM._ls_components
DRM._ls_marginal_grad
DRM._ls_marginal_nll
DRM._ls_obs_information
DRM._ls_profile_ci
DRM._phylo_mean_laplace_hetero_fg
DRM._phylo_mean_leaf_index
DRM._reml_normalise
DRM._vcov_from_hessian
DRM.q2_reml_phi_len
```

## Non-Gaussian sparse-Laplace kernels

```@docs
DRM._fit_beta_relmat_laplace
DRM._fit_betabinomial_crossed_laplace
DRM._fit_betabinomial_phylo_laplace
DRM._fit_gamma_relmat_laplace
DRM._fit_nb2_relmat_laplace
DRM._fit_poisson_crossed_laplace
DRM._fit_poisson_phylo_laplace
DRM._fit_poisson_relmat_laplace
DRM._fit_poisson_spatial_coord
DRM._poisson_crossed_laplace_fg
DRM._poisson_phylo_laplace_fg
```

## Helpers referenced by source docstrings

These nonpublic helpers have no source docstrings; the descriptions below keep
references from the documented kernels navigable without creating new APIs.

### [_group_index](@id _group_index)

Maps observation labels to integer group indices in first-seen order and
returns the indices together with the number of distinct groups.

### [_fit_phylo_mean_laplace_nuisance](@id _fit_phylo_mean_laplace_nuisance)

Prepares a tree's root-conditioned precision and observation-to-leaf map,
then delegates to the general-precision mean-effect Laplace fitter.

### [_fit_crossed_mean_laplace_nuisance](@id _fit_crossed_mean_laplace_nuisance)

Fits the crossed mean-effect Laplace objective for a supplied family and
nuisance-parameter specification, using the prepared group indices.
