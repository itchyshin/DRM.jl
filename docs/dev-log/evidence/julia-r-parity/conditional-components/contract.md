# S10 ordinary Gaussian conditional-components contract

## Admitted estimator cell

This adapter adds stored-row conditional `mu` prediction only for a
Julia-engine univariate `gaussian()` fit whose random effects occur only on
the mean. It uses one existing DRM.jl fit and the modes returned by
`DRM.ranef(fit)`; it neither refits nor reconstructs a covariance solve in R.

The admitted ordinary components are, in formula order:

1. scalar `(1 | g)`, with loading `z_i = 1`;
2. scalar `(0 + x | g)`, with finite numeric loading `z_i = x_i`;
3. exactly one correlated `(1 + x | g)`, with loading row `(1, x_i)`;
4. two or more independent scalar components only when every grouping-column
   name is distinct.

For stored row `i`, component `j` has first-seen level index `k_ij`. The added
estimand is

\[
  \eta^{cond}_{\mu,i} = X_{\mu,i}\hat\beta_\mu +
  \sum_{j \in \mathrm{scalar}} z_{ij}\hat b_{j,k_{ij}} +
  \sum_{j \in \mathrm{correlated}} (1,x_{ij})\hat b_{j,k_{ij},\cdot}.
\]

For Gaussian `mu`, response and link values are both this `eta`. Supplying
`newdata` remains the existing population-level, zero-random-effect
prediction. Fixed `sigma` is unchanged.

## Fit-time payload

The versioned `gaussian_mu_ordinary_components_v2` payload contains, for each
component, the group-column name, typed first-seen group values, row `gidx`,
the loading source and realized finite loading values, and natural-scale modes.
Scalar modes have length `G`; correlated modes are exactly `G x 2` in
`[intercept, slope]` order. R validates all serialized training-row inputs
before adding a component. An absent, malformed, reordered, duplicate, or
non-finite payload is an error; it never falls back to fixed effects.

Numeric and logical group values retain their Julia `Real` representation at
serialization and are canonicalized with R `as.character()` for the
training-row check. Categorical values serialize as strings.

## Established source contracts and boundaries

`DRM._group_index` establishes first-seen row order. Scalar and correlated
ordinary Gaussian modes are returned in natural random-effect units by
`DRM.ranef(fit)`. For correlated blocks the fitted covariance parameters are
`recov_g:L11`, `L22`, `L21`, with
\(L = [\exp(a)\ 0; c\ \exp(b)]\); prediction uses the returned modes, not
an R reconstruction from these covariance parameters.

The multi-component fitter evaluates both the residual linear predictor and
each random-effect log-SD with a `[-30, 30]` clamp, and computes its returned
BLUPs on that same clamped path. The payload records when the residual-sigma
clamp was active. For a validated v2 multi-component **stored** prediction,
this adapter also returns `pmin(pmax(X_sigma beta_sigma, -30), 30)` on the
sigma link scale and its exponential on the response scale. Fresh `newdata`
remains the existing unconstrained fixed-effect reconstruction. This preserves
DRM.jl semantics, but native R parity for an extreme clamp-active fit is an
open compatibility obligation. It must not be hidden by rejecting a valid
admitted formula.

Excluded and still counted capability gaps: repeated components for one group
(including desugared `||` forms), multiple correlated blocks, correlated
blocks with more than one slope, random effects outside `mu`, structured or
known-sampling-variance markers, offsets, and weights. Untrusted payloads remain mandatory refusals,
not missing capabilities to admit.
The multi fitter keys its public modes by group, so a repeated grouping name
overwrites an earlier component and cannot be recovered without Julia-source
work.

## Pure-test scope

The acceptance tests exercise scalar intercept, scalar slope, one correlated
intercept/slope block, and multiple distinct-group scalar components from
hand-built typed payloads. They also exercise rejection controls. They do not
run Julia or establish native-vs-Julia numerical parity; the independent
dense-oracle comparison remains the next gate.

## Retained pure-test receipt (2026-08-30)

The initial contract test intentionally failed before the adapter existed:
`pure-components-red-001.log` records the missing components admission helper
and v1-only stored-prediction refusal. The final focused pure run records
`S10_COMPONENTS_PURE_PASS` in `pure-components-green-004.log`. It covers the
four admitted shape classes and payload rejection for changed loading, level
order, row index, non-finite modes, and an unknown payload kind.

The retained compatibility run records
`S10_COMPONENTS_REGRESSION_PASS` in
`pure-components-regression-green-002.log` for the pre-existing v1 conditional
payload and prediction-scale tests. `r-parse-components-green-002.log` records
an R parse check and `git diff --check`. These are R-only checks; no Julia
session, numerical fit, or native-parity claim occurred in this slice.

The executable leaf `.unlazy/julia-r-parity/gates/leaf-S10-components-pure.md`
was approved and re-run after the retained logs. Its three checks are recorded
as `ALL MET`: focused components, pre-existing pure regressions, and R parse
plus whitespace validation.

The post-setup repair is recorded in `components-setup-failure-001.log`
(the one-expression JuliaCall parse failure) and the rerun pure checks in
`pure-components-green-006.log`, `pure-components-regression-green-004.log`,
and `r-parse-components-green-005.log`. The setup repair wraps the generated
function and legacy alias in one Julia `begin ... end` expression.

## Integrated numerical checkpoint

The root-owned final four-case pilot passed all 32 adapter/native prediction
comparisons and four independent dense likelihood comparisons. See summary.json,
components-green-002.json and source-verification.json. The original three RI
cases remain separate: all 24 adapter checks pass but the prior varying-scale
native-fit discrepancy persists. Rose approved the exact isolated candidate
1b43bcd7c3a57ef8125b191c155472f71b768e312bdd82f152fbddcb189aa3db.
