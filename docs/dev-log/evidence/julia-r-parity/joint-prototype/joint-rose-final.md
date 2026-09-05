# Rose final bounded S9 review

Verdict: **READY** for the Julia-only prepared Gaussian-response prototype. This is not full S9 completion or R bridge admission.

## Reviewed repairs

The Bernoulli likelihood now retains both normalized log weights; the Gaussian posterior mean uses ratio-weighted terms. Finite theta/control checks, guarded inverse-Hessian covariance, separate optimizer/covariance status, original-model snapshot, reserved coefficient-name rejection, and both-family derivative tests are present. The source remains the independently reviewed repaired implementation.

## Independent receipt checks

The final fit checker passed for both 160-row cases. All 13 intended damaged controls were rejected in normal and optimized Python modes. Native parameter admission remains a separate failed gate: Gaussian difference is below 4e-6; Bernoulli difference exceeds 4e-6. The common-parameter checker separately passed 320 row likelihoods and 640 conditional moments; all 11 controls passed in normal and optimized modes.

## Independent finite differences; no fitting

The numerical objective was rebuilt from original fixture x/y/z and masks using the independently written Python Gaussian closed form and Bernoulli state sum at each receipt fitted parameter vector. It did not use native fixed-parameter row likelihoods. Five-point coordinate gradients used h_j=1e-4*max(1,abs(theta_j)). Hessian-vector products used central differences of those independent gradients at theta +/- 1e-3*v, with v evenly spaced from -0.4 to 0.3 and fixed inner steps. Scaled error is abs(actual-expected)/max(1,abs(actual),abs(expected)); predeclared limits were 1e-6 for gradients and 1e-5 for Hessian directions. No tolerance or step was changed after observing results.

Elapsed derivative-check time: 0.013173 seconds.

```json
{
  "gaussian": {
    "status": "PASS",
    "gradient_abs_error": 2.2167945257223204e-10,
    "gradient_scaled_error": 2.2167945257223204e-10,
    "hessian_direction_abs_error": 1.3688918272691808e-05,
    "hessian_direction_scaled_error": 6.71398064934978e-07,
    "recorded_gradient_max": 6.738656299631884e-10,
    "independent_gradient_max": 7.105427357601001e-10,
    "independent_nll_abs_error": 0.0,
    "native_theta_max_abs_diff": 2.7546376548670537e-06,
    "gradient_recorded": [
      -4.1196157596345984e-10,
      -3.509129653522791e-10,
      -6.738656299631884e-10,
      -1.975218877348084e-10,
      -5.220111010117989e-10,
      -1.125427528947398e-10,
      -6.253764173180798e-11
    ],
    "gradient_independent": [
      -4.2632564145606006e-10,
      -1.8947806286936003e-10,
      -6.60935911983332e-10,
      -4.736951571734001e-11,
      -7.105427357601001e-10,
      -4.736951571734001e-11,
      -2.8421709430404e-10
    ],
    "hessian_direction_recorded": [
      -110.14027127094347,
      -94.65071599800216,
      -101.75926221482398,
      -12.725534789260793,
      26.5374529730064,
      63.78598103583733,
      88.832833427849
    ],
    "hessian_direction_independent": [
      -110.14027172961958,
      -94.65071656222788,
      -101.75926306221271,
      -12.725543333165962,
      26.537458192403086,
      63.78599276028277,
      88.83284711676727
    ],
    "coordinate_steps": [
      0.0001,
      0.0001,
      0.00011467257834471458,
      0.0001,
      0.0001,
      0.0001,
      0.0001
    ],
    "direction": [
      -0.4,
      -0.2833333333333334,
      -0.1666666666666667,
      -0.0500000000000001,
      0.0666666666666666,
      0.18333333333333335,
      0.2999999999999998
    ]
  },
  "bernoulli": {
    "status": "PASS",
    "gradient_abs_error": 1.9193454233364565e-10,
    "gradient_scaled_error": 1.9193454233364565e-10,
    "hessian_direction_abs_error": 1.7955872992914124e-06,
    "hessian_direction_scaled_error": 3.6449103962673764e-07,
    "recorded_gradient_max": 2.3506085966573664e-11,
    "independent_gradient_max": 1.8947806286936003e-10,
    "independent_nll_abs_error": 5.684341886080802e-14,
    "native_theta_max_abs_diff": 1.0015094105086941e-05,
    "gradient_recorded": [
      7.927769551940855e-12,
      2.4564794642856214e-12,
      1.3707368573534495e-11,
      6.179612377366084e-12,
      -2.3506085966573664e-11,
      -1.8421264513790447e-11
    ],
    "gradient_independent": [
      9.473903143468002e-11,
      -1.8947806286936003e-10,
      3.8913617662811455e-11,
      -4.736951571734001e-11,
      4.736951571734001e-11,
      -9.473903143468002e-11
    ],
    "hessian_direction_recorded": [
      -92.77301846237594,
      -55.77145404377793,
      -48.36420632633045,
      4.926284735709079,
      6.639253078071019,
      9.351037819781498
    ],
    "hessian_direction_independent": [
      -92.77301854145509,
      -55.77145458346421,
      -48.364206321415914,
      4.926286531296379,
      6.639253058438044,
      9.351037538370594
    ],
    "coordinate_steps": [
      0.0001,
      0.0001,
      0.00012172992017293112,
      0.0001,
      0.0001,
      0.0001
    ],
    "direction": [
      -0.4,
      -0.26,
      -0.12000000000000005,
      0.019999999999999907,
      0.15999999999999992,
      0.29999999999999993
    ]
  }
}
```

## Provenance

The fit receipt source manifest contains 87 files and matches current source bytes; the runner, reference, resource limits, original rows, and masks passed the explicit checker.

```json
{
  "joint-fit-002.toml": "1e23bcbaa6125001a22ec73c522910ba39a21c4980cc6223e8610454ad8f96ef",
  "test/fixtures/joint_missing_predictor/native_reference.toml": "4f7244d1cec6b76e76dece0967f1611f8e2a405b085cd42990576672d5aa2164",
  "src/joint_missing_predictor.jl": "e43463f973871992f0bcdc8f6829eb0c4e90d667f844f76b58eb910964887fba",
  "src/DRM.jl": "bdd0118fc4ec7c2c264b7371ce0008412a3e4cff6f1f246299ee4eaa8c1ef595",
  "test/test_joint_missing_predictor.jl": "b8b14c5fec6ee08151ff8c52a416b41b4b10b91e39b0d4504b07e47edeb291a9",
  "tools/check_joint_predictor_fit.jl": "ffe782dcb1e753c4b8c4115bfcbe95a7303ccfd15d749d38a371b5d258ac6bdc",
  "tools/check_joint_predictor_fit_receipt.py": "236c878e1a79a57fdd990cf3b4eb5c6cab1b09b008521180029aedcdbcd70d09",
  "tools/test_joint_predictor_fit_receipt.py": "422bd7b56f24e192b1c6de2cadbef7a036ff485b38be182624766c72a658ded9",
  "docs/src/reference/engine-internals.md": "0336620f390b788afe64cae8c08cbbac531a70684a250cb27aa532de7829aa1f"
}
```

## Documentation and limits

The developer example explicitly evaluates four rows at supplied parameters and does not fit them. It describes conditional variance as distinct from native imputed standard errors and shows optimizer/covariance status separately. The parent reports a strict 52-page/123-example Documenter source build; this reviewer did not rebuild docs. No live deployment, full-site theme verification, recovery, confidence-interval parity, or missing-predictor frontend/bridge admission is established. Current finite-difference evidence is local to these two nondegenerate fitted fixtures and does not certify all numerical regimes.
