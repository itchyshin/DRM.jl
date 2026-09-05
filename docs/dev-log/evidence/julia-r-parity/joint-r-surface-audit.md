# Native R missing-predictor contract audit

Read-only audit of drmTMB `HEAD 97b7eee37` for the first Gaussian response
with a Gaussian or Bernoulli missing predictor. This records the public
contract for a future bridge; it does not copy native implementation code.

## Admission and preparation

`miss_control()` defaults to response/predictor failure and accepts
`response = "include"` and `predictor = "model"` (`R/missing-data.R:3-45`).
`mi(x)` is admitted only with `missing = miss_control(predictor = "model")`
(`R/missing-data.R:620-647`). The imputation map must contain the named
predictor; a bare `x ~ z` is standardized as Gaussian, while finite-state
predictors use `impute_model(x ~ z, family = binomial())`
(`R/missing-data.R:81-123`, `:807-848`).

The preparation metadata is carried in `spec$missing_predictor`, including
`enabled`, `variable`, `family`, `formula`, `coef_names`, and the design/data
indices. Fixed coefficients are exposed as `mi_<variable>` with names equal to
`spec$missing_predictor$coef_names` (`R/drmTMB.R:21221-21249`). Gaussian
missing-predictor routes additionally expose `sigma_mi_<variable>` when the
imputation model has a modelled scale (`R/drmTMB.R:21379-21402`).

## Public result shape

The fitted object keeps the imputation metadata under `model$missing_predictor`
and the imputation coefficients in `coefficients[[paste0("mi_", variable)]]`.
The ordinary fitted response/prediction APIs continue to report the response
model; imputation coefficients are named auxiliary distributional parameters,
not an additional response column. The exported `imputed()` contract is a
separate row-level summary (`R/missing-data.R:5027-5120`). It returns columns
`variable`, `original_row`, `model_row`, `observed`, `estimate`, `std_error`,
`source`, and `uncertainty_status`. `rows = "missing"` returns only missing
predictor rows; `rows = "all"` retains model rows and labels observed values
with `source = "observed"` and `std_error = NA`.

For Gaussian predictors, `estimate` is the fitted conditional mode and
`source = "conditional_mode"`; its conditional standard error comes from the
TMB conditional covariance. The Gaussian tests verify these names, row
mapping, mode equality, and positive finite standard errors
(`tests/testthat/test-missing-predictor-gaussian.R:259-371`). `predict()` still
returns the fitted response mean (or requested distributional parameter)
through the usual Gaussian path (`R/methods.R:2804-2890`), while `fitted()`
delegates to that response path (`R/methods.R:2315-2317`).

For a Bernoulli imputation model, the predictor model is finite-state and its
likelihood contribution is built by `drm_build_bernoulli_missing_predictor_model`
(`R/missing-data.R:1373-1482`). `imputed()` reports the fitted conditional
probability in [0,1] with `source = "conditional_probability"`; with `se = TRUE`
the route-conditional `std_error` is `sqrt(p * (1 - p))`. With `se = FALSE`,
it is `NA` and the status records skipped standard errors. These contracts are
asserted in `tests/testthat/test-missing-predictor-binary.R:80-143`.

## Rejections and bridge implications

Missing predictor modelling without an imputation formula is rejected
(`R/missing-data.R:807-826`); multiple independent Gaussian predictors have a
separate setup and must each provide a matching imputation specification
(`R/missing-data.R:666-706`). Unsupported family/model combinations are
rejected by the family admission checks in `R/drmTMB.R:19670-19699` and by
the builder dispatch at `R/missing-data.R:1155-1241`.

The safest reusable R-side bridge boundary is the preparation/standardization
layer (`drm_standardize_impute_model()`, `drm_mi_setup_from_impute()`, and the
builder dispatch). A future bridge must preserve the `mi_*`, `sigma_mi_*`, and
`model$missing_predictor` names and distinguish Gaussian latent integration
from Bernoulli finite-state integration. It must not replace the marginal
response prediction with an imputed category or conditional plug-in value.

Supporting tests are the missing-predictor Gaussian tests under
`tests/testthat/` (search terms `mi(`, `missing_predictor`, and
`impute_model(`); exact test selection should be refreshed against the named
HEAD before implementation.
