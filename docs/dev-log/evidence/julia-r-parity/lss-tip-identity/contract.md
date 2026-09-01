# Direct LSS tip-identity contract

Approved programme #563, existing S6/S7/S10 frontend obligation. This leaf fixes
both phylogenetic observation mappings, not a likelihood/estimator redesign.

For tree-tip order t and observation label s_i, j_i=match(s_i,t). The incidence
matrix Z has Z[i,j_i]=1. Species SD a_j=exp(W_j alpha), residual variance
D_e[i,i]=exp(2 X_sigma[i,:] beta_sigma). The model covariance is
V = D_e + Z diag(a) K diag(a) Z'. Any additional IID component contributes its
own incidence/diagonal covariance independently. Permuting observations by P
must give V_new=P V P', X_new=P X and y_new=P y, leaving likelihood unchanged.
Reordering data must not reorder the tree or assign a species another tip's
covariance. Group SD covariates W are compressed into tree-tip order.

Rose approved the mapping design for shipped AugmentedPhy/Newick inputs.
Integer groups keep the established positional1:p convention; strings match
literal tree names. All tips must be represented before response masking; an
entirely masked tip remains in the full group design. Missing/unknown names and
within-tip varying SD predictors are refusal neighbours. IID indexing is unchanged.
No in-repo custom provider exists, but arbitrary third-party sigma_phy_dense
extensions are not qualified by this repair. Avoid a misleading q4-only type error.

Independent Gaussian ML oracle uses named observation covariance. REML oracle
uses GLS residuals and logdet(V)+logdet(X' inv(V) X)+(n-p)log(2pi). Tests must
exercise asymmetric covariance, repeated/shuffled species and species-varying
SDs, with dense/sparse and multi-component routing. No estimator or tolerance
change is authorized to hide an indexing failure.

Separate required inference work discovered by Rose: inference.jl marginal
simulator still assigns first-seen group indices before tree-order K and Zg.
Frontend fitting repair alone does not qualify unsorted marginal bootstrap.
Profile nuisance result status is also dropped before outer endpoint decisions;
retain the measured256tip termination failure as an open correctness gate.
Neither denied gaussian_structured.jl nor gaussian_sparse_lss.jl may be edited
or bypassed. Full programme G0-G8 remain open.

## Reproduced public failure before implementation

R public-red-001 (22.512seconds, sources unchanged) returned converged fits
in native R, the bridge and direct Julia, yet failed four of eight checks.
Native and bridge named-covariance likelihood errors were <7e-14; direct Julia's
error was0.8405699. Native/direct coefficient differences were0.03216(mu),
0.06052(sigma),0.12536(sd_phylo), with loglikdifference0.48947. This is an
actual12tip72row unsorted-input fit, not a source-only suspicion. No tolerances
were changed. The earlier pure test red001 failed on invalid table metadata
and is retained as a harness error, not claimed as evidence of the fitting bug.
Corrected pure red002 retained194passes/10failures with covariance and
ordered/shuffled coefficient failures on dedicated and multi-component routes.

## Additional inference obligations from source audit

`bootstrap_result(fit::DrmFit{Gaussian};...)` creates refits without carrying
`estimation_method(fit)`; REML can silently become the ML default. This already
belongs to approved S11 estimator propagation. `_marginal_simulator` also selects
a single group when both IID and phylogenetic mean effects exist; its LSS branch
chooses one SD block, so a multi-component model needs a joint draw contract.
These are source-grounded findings, not independent runtime reproductions here.
Before claiming corrected LSS bootstrap, reproduce estimator preservation,
every random-effect contribution, tree-label mapping, and serial/threaded RNG
semantics. The current frontend leaf does not close those inference obligations.
