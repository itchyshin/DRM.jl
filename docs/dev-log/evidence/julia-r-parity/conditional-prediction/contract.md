# S10 conditional Gaussian random-intercept prediction contract

This is a narrow R-side bridge adapter, not a general conditional-prediction
claim.

## Admitted fit

Only a univariate `gaussian()` Julia-engine fit with exactly one ordinary
mean-side `(1 | g)` term is eligible. The scale formula is fixed-effect only.
The adapter refuses slopes, multiple bars, structured markers, `meta_V()`,
offsets, weights, and unrecognised formula shapes. New-data prediction keeps
the established zero-random-effect contract.

At fit time the R JuliaCall setup wrapper may use the existing private
marshalling sequence (`DRM._bridge_data`, `DRM._bridge_formula`,
`DRM._bridge_family`, `DRM._bridge_fit`) and exported `DRM.ranef(fit)`. It
serializes the grouping column name, the first-seen labels used by
`DRM._group_index`, group indexes, and the returned BLUP vector alongside the
ordinary flattened bridge result. No Julia source is changed.

## Stored prediction estimand

For training row \(i\), with `k = gidx[i]`, the only added estimand is

\[
  \eta^{cond}_{mu,i} = X_{mu,i}\hat\beta_{mu} + \hat b_k,
  \qquad
  \mu^{cond}_i = \eta^{cond}_{mu,i}.
\]

`sigma` remains `exp(X_sigma beta_sigma)`. This follows the existing
Gaussian identity mean link and mean-side random intercept; it does not define
conditional scale, slope, structured, non-Gaussian, q2, or q4 predictions.

The R extractor validates the stored training labels against the serialized
first-seen levels and indexes before using any BLUP. A malformed, missing, or
shape-incompatible payload is an error, never a fixed-effect fallback.

## TDD receipt

The new focused pure test was run before the adapter code existed. It failed
as intended with exit 1 because `predict()` reported that it did not retain a
random-effect payload. After the adapter, the same focused test and the
existing prediction-scale pure suite both exited 0. Neither command starts
Julia or fits a model:

```sh
Rscript -e 'pkgload::load_all("/private/tmp/drm-parity-20260830/drmTMB", quiet=TRUE); testthat::test_file("/private/tmp/drm-parity-20260830/drmTMB/tests/testthat/test-julia-conditional-prediction.R", reporter="summary", stop_on_failure=TRUE)'
Rscript -e 'pkgload::load_all("/private/tmp/drm-parity-20260830/drmTMB", quiet=TRUE); testthat::test_file("/private/tmp/drm-parity-20260830/drmTMB/tests/testthat/test-julia-prediction-scales.R", reporter="summary", stop_on_failure=TRUE)'
```

The red failure was specifically the first link-scale expectation of
`stored Gaussian ordinary random-intercept mu uses validated BLUPs`, before
the payload-aware stored prediction path was present. This receipt does not
claim native or Julia runtime parity; that gate remains separate.

Raw retained console captures are `pure-focused-red.log`,
`pure-focused-green.log`, and `pure-prediction-scales-green.log` in this
directory. They record outcomes only; no assertion total is claimed here.

## Numeric and logical group-label repair

`DRM._group_index` receives numeric R grouping columns as Julia `Float64`
values. Serializing every label with Julia `string()` changed `1` to `"1.0"`,
which could make the otherwise valid stored-prediction validator reject its
own payload when R compared it with `as.character(training_group) == "1"`.
The conditional wrapper now retains Julia `Real` labels as typed values and
only stringifies categorical labels. The R decoder canonicalizes both its
returned levels and the retained training column with `as.character()` before
checking first-seen order. This is linear in the training rows and leaves the
original grouping column unchanged, including when it is also a fixed `mu`
predictor.

The first test added for this repair failed before the generated-wrapper helper
existed (`pure-numeric-label-red.log`). The corrected pure test covers numeric
groups used as a `mu` predictor and logical groups; it passed alongside the
existing prediction-scale suite with an explicit aggregate of testthat
failures/errors:

```sh
Rscript -e 'pkgload::load_all(".", quiet=TRUE); r <- testthat::test_file("tests/testthat/test-julia-conditional-prediction.R", reporter="summary"); bad <- any(unlist(lapply(r, function(test) vapply(test$results, function(result) inherits(result, "expectation_failure") || inherits(result, "expectation_error"), logical(1))), use.names=FALSE)); if (bad) quit(status=1L); cat("PURE_NUMERIC_LABEL_PASS\\n")'
Rscript -e 'pkgload::load_all(".", quiet=TRUE); r <- testthat::test_file("tests/testthat/test-julia-prediction-scales.R", reporter="summary"); bad <- any(unlist(lapply(r, function(test) vapply(test$results, function(result) inherits(result, "expectation_failure") || inherits(result, "expectation_error"), logical(1))), use.names=FALSE)); if (bad) quit(status=1L); cat("PURE_PREDICTION_SCALES_NUMERIC_LABEL_PASS\\n")'
```

The retained fresh outputs are `pure-numeric-label-red.log`,
`pure-numeric-label-green.log`, and
`pure-prediction-scales-numeric-label-green.log`. These are pure R checks;
they do not establish the separate live Julia/native prediction comparison.

Final coordinator verification supersedes the early green filenames: conditional-pure-final-gate-001.log records both final candidate pure gates. The earlier pure-focused-green.log was overwritten by the LSS regex failure; its red contents are preserved as pure-focused-lss-regex-red.log. No claim is based on that filename. Final live and scope verdicts are in report.md.
