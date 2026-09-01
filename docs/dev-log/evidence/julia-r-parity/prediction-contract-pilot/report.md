# S10 prediction adapter checkpoint

2026-08-30; programme https://github.com/itchyshin/DRM.jl/issues/563 remains open.

## Result

The selected R prediction repair passes its adapter check: all32 stored/newdata, mu/sigma, link/response outputs equal native R evaluated at the same Julia coefficients (largest absolute difference0, required<1e-12). This is an adapter oracle, not a replacement for independently fitted models.

Independent native/Julia fit parity: three of four Gaussian fixed-effect cases pass4e-6; the factor case fails six outputs, max6.260969154237017e-6. Its native gradient diagnostic is0.0015332952939461908 despite convergence0. This suggests stopping-accuracy investigation; no optimizer, estimator, data, or tolerance was changed to obtain a pass. Full functional/numerical parity is NOT achieved.

The four cases are numeric mean/scale, factor mean/scale, omitted default scale, and known sampling variance meta_V(V=v). Fixtureversion2 adds known variance without removing any original case. All32 observations and convergence statuses are retained. Final run003 took19.455s on this Mac, Julia1.10.0, Julia threads1, BLAS threads explicitly set/measured1. No timing-speedup claim and no remote compute.

## Repair

Reconstruct fixed-effect distributional predictors from retained formula/data/coefficients and canonical native links. Gaussian sigma now supports newdata; lognormal mu uses log-location, not raw median; scale is not reconverted into shape/precision. Remove ordinary/structured random terms and known-sampling markers from newdata design. Preserve no-intercept/factor names and only infer omitted formulas from exactly named intercept coefficients. Refuse nonfinite/missing inputs, offset payloads not supported by this adapter, ambiguous family metadata, and stored conditional predictions whose random-effect modes are absent.

Meta_V is a known covariance marker, not a random effect. Tests cover its deprecated alias and varying heterogeneity sigma. Legacy cross-family methods retain their narrower contract. R documentation no longer calls this prediction method halted future work.

## Source and controls

The candidate is HEAD f3d872cd9376e78391501b1f771976ed03a54b66 with ONLY the prediction/helper section replaced. Other zero-one-beta admission/constructor edits remain excluded. It is not a git checkout: runtime R_head is null intentionally; candidate-provenance.json supplies the source commit and candidate hash. Other R files and the unchanged DLL were linked to the original checkout. The final loaded bridge hash is9e7b2edad435d0fcd423866ef388426842002c67b40a288e5977fd05fc8d6ad1. Julia source remains unchanged.

Independent Rose approved this selected patch and matching hashes;26 new assertions and15 existing prediction assertions pass, one explicit live opt-in test skipped. Root also ran122 existing bridge assertions and the separate cross-family pure regression suite. No skipped live test is numerical evidence.

The negative wrapper shifts every Julia prediction by+0.1 while leaving native and same-coefficient oracle predictions intact. It ran19.366s and rejected all32 outputs (FAIL/FAIL). The separate executable negative-control check confirms each adapter error is0.1 within1e-12.

Retained failures: first runtime lacked Julia depot-lock permission; original implementation returned sigma on response scale when link requested and refused newdata sigma; first fourth-case run002 used invalid positional meta_V(v), corrected to named V without removing the case. The original three-case result remains separately retained. Gate logs redact local PATH strings only; all fit-output JSONs and numerical logs are intact.

## Limits and next work

Stored conditional RE prediction remains a real open capability: ordinary and q2/q4 bridge outputs generally omit latent modes; general-covariance payloads may also omit matrices. Refusal prevents a false answer but does not satisfy full parity. Quantile prediction, offsets, missing-row restoration, uncertainty propagation and the full family/provider grid remain open. Canonical rho prediction versus raw correlation accessors needs complete cross-surface parity evidence; this slice does not certify it. The factor-case optimizer discrepancy remains registered. Protected Julia source edits still await previously requested approval. No release, push, merge, cleanup deletion or external message.

Local R checkpoint: `058bf6b2983df47af8cc8371d3ea5777cc84ff51`; committed R bridge bytes match the tested candidate exactly (`committed-source.json`).
