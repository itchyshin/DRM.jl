# Conditional prediction and native selected-state repair — #563

The Julia bridge now retains the existing Gaussian ordinary mean random-intercept
BLUPs and first-seen group map at fit time. Stored `mu` predictions add those
conditional effects. Fresh-data predictions retain the established zero-RE
contract. Numeric/logical labels remain typed across transport; a grouping
column used as a numeric fixed predictor is not converted to a factor.

The admitted adapter is deliberately narrow: univariate Gaussian, one mean-side
`(1 | g)`, only mu/sigma formula entries, fixed-effect scale, no offsets,
structured/meta terms or additional random terms. Malformed/missing payloads
fail explicitly. Existing generic routes are otherwise unchanged. This receipt
validates three complete-data ML cases; it does not validate bridge REML,
missing-response behavior or all conditional prediction routes.

A separate native R bug was confirmed and corrected. TMB parList() defaults to
mutable last.par, which sdreport() can leave at a Hessian perturbation. Native
stored random effects were extracted from that perturbed state. The shared fit
constructor now supplies the already saved pre-SE full parameter snapshot,
without re-running optimization or mutating the returned TMB environment.

The pre-fix nonmutating diagnostic reproduces both default fits exactly.
Optimizer parameters are identical with/without SE. Clean snapshot predictions
match se=FALSE exactly; perturbed stored predictions differ by0.00176879 and
0.00176249. SE=false is only a diagnostic, never a reduced-work parity baseline.
Eight native regression fits cover twoML cells, a fixed-effect control and a
Gaussian REML neighbour; corrected predictions match dense conditioning and are
invariant to requesting SEs. The shared extraction also feeds missing-predictor
summaries and potentially marginalized coefficients; those broader routes are
not covered by this small regression set.

Final native/Julia run:19.423s, Julia1.10.0, Julia threads1, measuredBLAS1.
All24adapter outputs match an independent dense Gaussian conditional oracle
(maximum1.4433e-15). Independent fitted-model parity passes constant-scale and
numeric-group cases. Varying-scale newdata mu link/response remainFAIL:
1.085952654e-5 exceeds the unchanged4e-6 tolerance. Every other registered output
passes. This does not close full functional or performance parity.

Pure conditional, existing prediction-scale, newdata and bridge suites pass;
one existing live opt-in skip is excluded. The receipt checker recomputes24
comparisons, rejects6deliberately shifted conditional means and1missing row.
Eight subprocess outcomes verify valid/damaged/missing evidence under normal
and optimized Python. Rose independently reran those8outcomes and approved.

Retained failures include: initial checker read random SD from the wrong R slot;
old bridge lacks4storedmu outputs; numeric string labels cause2refusals;
malformed LSS guard regex caught before live use; native state regression red;
first green regression only mismatched oracle vector names. No fixture or
numerical tolerance was changed to hide a model failure. Generated-source string
assertions were removed; real numeric-group live behavior is the evidence.

Exact sources: source-provenance.json and conditional-green-002.json bind the
selected R bridge/fit files, native DLL, runner,86Julia source files and before/
after source checks. Julia src remains identical to f47789646f27221ba4fad29a8ba1b3b8a790b521.
The isolated candidate excludes all unfinished zero-one-beta changes. Historical
runners are archived against their original receipt hashes. Gate-log PATH text
is redacted in retained copies; raw local logs remain in the private task folder.
No remote compute, release, deployment, push, merge or worktree deletion occurred.

License-boundary walk-around: two agent parse logs echoed GPL R source. Raw logs were moved outside DRM.jl before publishing; this unpublished evidence commit was amended. Retained files contain only original SHA256, external local path and parse verdict. No GPL source echo remains in the retained parse logs.
