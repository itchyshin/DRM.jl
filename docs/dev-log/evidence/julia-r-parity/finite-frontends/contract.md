# Finite-state frontend/bridge implementation contract

Gaussian response with one ordinal/categorical missing predictor, fixed imputation
model, all four masks. The prepared likelihood is shared by direct Julia and R.
No estimator or optimizer-default changes. Existing native-default fit losses stay
at unchanged4e-6 until independently resolved. No whole capability cell closes here.

Julia frontend: CumulativeLogit() predictor or predictor-only CategoricalLogit(),
explicit level order for text ordinal data, deterministic categorical levels,
K>=3 native frontend admission and observed-category/row adequacy. State mean
design includes ordinal polynomial or categorical treatment contrasts. Ordinal
predictor design removes intercept, including zero-width design. Wrapper retains
raw coordinates/covariance; native public cutpoint summaries remain distinct.

R retains its existing native parser/preparation. Versioned payload
joint_missing_finite_v1 carries y,x statecodes,masks,levels,full X_mu,flat
X_mu_state with declared row_then_state layout,X_sigma,X_predictor,allnames,
originalrows,options. Julia validates dimensions, labels, observed-state design
agreement and options. Results carry rawtheta and covariance in explicitnative
order, posterior probabilities, actualimputedSD/status, levels and rowmetadata.
Natural cuts use fullJacobian whenever covariance is transformed; no coordinate
may silently change meaning. Native public coefficient/covariance cut handling
was checked against the retained native fit before implementing result adapters.

No GPL implementation copied into MIT Julia. Only mathematical contracts and
native-generated numerical reference outputs cross that boundary.

Required gaps: no-intercept direct mean with another categorical fixed covariate; raw direct-Julia versus native-public R accessor coordinates; full native output/argument denominator and strict default-fit parity.
