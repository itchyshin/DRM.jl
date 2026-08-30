# Independent missing-predictor reference: first two native contracts

The frozen native ledger has 24 implemented missing-predictor axis cells, retained
with their original boundaries in missing-predictor-obligations.json. These are
not 24 interchangeable model cases. Gaussian predictor models include additional
grouped/structured variants; other predictor families use different integration
rules. Missing-response support is a separate axis and is not absent from Julia.

For the first prototype, derive the unweighted independent-row ML joint model
from its probability definition, with all parameters held fixed:

`x ~ Normal(m, tau²)` and `y | x ~ Normal(a + b*x, sigma²)`.

When x is missing and y observed, the marginal is
`Normal(a + b*m, sigma² + b²*tau²)`. When only y is missing, retain the observed
predictor density. When both are missing, the log contribution is zero. For a
Bernoulli predictor, replace continuous integration with the exact weighted sum
over x=0 and x=1, evaluated by log-sum-exp. Keep all normalization constants.

Rose approved these identities for the stated scope before the native probe.
The new R oracle is independently written test code, not copied package source
or a Julia fitting-engine implementation. It accepts no weights, random effects,
REML adjustment or predictor-dependent residual scale. Tests compare the Gaussian
closed form with numerical integration at every mask, check b=0, and compare
finite-state enumeration including probabilities0/1. A both-missing row matters:
an extra latent-normalizer constant would otherwise escape detection.

## Executed native reference

Two seeded n=160 native-R fits use `bf(y ~ z + mi(x), sigma ~ 1)`, an x~z
predictor model, and response="include"/predictor="model". Each contains 147
fully observed rows, three y-missing rows, nine x-missing rows and one both-missing
row. SE computation is disabled because this probes the likelihood, not inference
or performance. Native and oracle are evaluated at the same fitted parameters.

| Predictor | Absolute log-likelihood difference | Original rows/masks retained |
| --- | ---: | --- |
| Gaussian | 1.3074e-12 | yes |
| Bernoulli | 1.4779e-12 | yes |

The predeclared likelihood tolerance is1e-6. Both unlazy gates actually reran and
passed. Public `sigma_mi_x` is already a standard deviation, unlike the response
block's log-sigma coefficient. The first test adapter exponentiated it twice and
failed by99.75; that is an oracle-adapter error, not a native-engine defect. The
failed receipt remains beside the corrected one. The invalid timeout-units attempt
also remains; it executed no checks.

Logs, source hashes, parameter vectors and numerical receipts are retained in
missing-predictor-oracle/. The final receipt records the R version, package path/version, actual input
data and loaded DLL/R database fingerprints. The manifest verifies those MD5s
and adds SHA-256 hashes; this identifies the observed binary without establishing
a full reproducible source-to-binary build attestation. The Gaussian
native gradient maximum is2.87e-4 and Bernoulli6.70e-4: agreement at a common
parameter vector is not proof of high-accuracy optimizer convergence.

This does NOT establish Julia missing-predictor admission, parameter recovery,
conditional-summary parity, covariance/interval correctness, the remaining22
predictor cells, or grouped/structured/two-predictor extensions. Those remain
required work. No Julia src file was edited.

Rose independently verified the final source/artifact/runtime hashes and
recalculated both oracle values from the retained data within2e-13. Her verdict
approves this bounded same-parameter likelihood receipt, not the open programme.
