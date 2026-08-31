# Coefficient labels and inference selectors — validated local patch

## 1. Goal

Address Ayumi's transformed-term and selector report in
[the validation comment](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/28#issuecomment-5472354858).
Keep each public coefficient name attached to its fitted value, covariance
coordinates and requested profile/bootstrap target. Programme #563 remains
active; this report does not close its wider parity or performance requirements.

## 2. Implemented

The development bridge records versioned public/raw label metadata, renders
factor interactions from their typed components, and uses collision-safe
temporary columns. The R adapter validates the map before inference startup and
preserves it for prediction and selectors. Tests cover punctuation, numerical
coordinate order, LSS prefixes, missing responses and ordinal intercept removal.
Source and owned-only candidate verification passed; scoped code commits are
Julia `6d35b133` and R `2cd1f2ce3`. Their source blobs match the executed candidates. The source hash is
`269937e0fd5a88f4db973759a7f03c91e288da2e9a7a9f65f1ec74e61072cfaf`.
This report certifies the bounded local patch; it does not claim a deployed
package or complete programme integration.

## 3a. Decisions and Rejected Alternatives

Rejected global punctuation replacement: factor levels may contain the same
characters used to separate terms. Preserve raw numerical column enumeration;
compare engines by complete coefficient identity, rather than relabeling values
to force identical textual order. Preserve legacy behavior only for objects
without versioned metadata; invalid versioned maps fail explicitly.

The arithmetic formatter must use generated native R references, not a few
threshold examples. No GPL engine source is copied into DRM.jl: the numeric
fixture contains generated R outputs, and its generator remains in drmTMB.

## 4. Files Touched

- Julia: `src/bridge.jl`, `test/runtests.jl`, new
  `test/test_bridge_formula_labels.jl`, `test/test_bridge_materialization_collision.jl`,
  and actual transformed-SD/direct-Julia `test/test_bridge_lss_labels.jl`.
- Julia verification: `tools/check_coefficient_labels.jl`,
  `tools/run_coefficient_label_checks.py`,
  `tools/check_coefficient_label_receipt.py`, and the `coefficient-labels/` evidence
  directory under `docs/dev-log/evidence/julia-r-parity/`.
- Reader documentation: `docs/src/r-julia-bridge.md` and R's
  `vignettes/julia-engine.Rmd`.
- R: narrow owned hunks in `R/julia-bridge.R`, new
  `R/julia-coefficient-labels.R`, `tests/testthat/test-julia-bridge-coef-labels.R`,
  `tools/probe-julia-coefficient-labels.R`,
  `tools/run-julia-coefficient-labels-public.R`,
  `tools/check-julia-coefficient-labels-receipt.R`,
  `tools/generate-julia-numeric-label-fixture.R`,
  `tools/generate-julia-nested-label-fixture.R`,
  `tools/generate-julia-scalar-label-fixture.R`,
  `tools/generate-julia-conditional-label-fixture.R` and retained R evidence.
- Programme checkpoint, ignored leaf ledger and this report. Mission Control
  changed only its four owned NOW fields in local vault commit `4f6edef`;
  served values matched, and that lease was released.

Foreign S5 and ZOB changes are preserved and excluded from scoped staging.

## 5. Checks Run

Final owned-only public008 passed seventeen Gaussian point cases and twelve
public/direct profile/bootstrap operations in49.48seconds. It checks coefficient
names/values, likelihood, full parameter consistency and observed-Hessian
covariance against independent R matrix/OLS calculations; maximum named mean
coefficient error4.85445e-13. Its checker independently re-derived the oracles
and rejected13damaged receipts. No tolerance was loosened.

Combined005 passed1061assertions plus the actual reader example in89.3627seconds,
with108unchanged inputs, Julia1.10.0, one Julia thread and one BLAS thread.
The focused source run passed819labels/49translation assertions. The R candidate
without foreignZOB passed62metadata/prediction assertions. Julia receipt controls
reject11damages under normal and optimized Python modes. Exact commands and
current input hashes are retained in the receipts and leaf ledger.

The paired candidate checkouts exclude foreignZOB and S5 wiring entirely.
Existing R DLL was reused only to load the package; this is not a new native
compilation or full nativeTMB qualification. Runtime checks used independent
R matrix/OLS calculations and actual Julia fits. Historical runs follow.

All fits were small local checks, with estimates and process limits. No remote
campaign ran. Public004 passed ten Gaussian mean/name/likelihood cases and
twelve inference operations in 42.486 seconds. Public005 added complete
coefficient/covariance transport and observed-Hessian checks and passed in
43.561 seconds. These are retained historical candidates, not final source
qualification. Public007 then passed twelve point cases and twelve inference operations in
44.462 seconds. Its checker linked the full parameter vector to the independently
checked mean and likelihood and rejected all thirteen damaged receipts.
Combined004 passed987 assertions and the reader example in76.634 seconds, with
106 unchanged inputs. These are historical source cb1039fe results: Rose withheld
final approval for a remaining scalar-expression provenance defect.

Julia combined001 recorded 301 passing assertions and one error in 71.91 seconds,
with all 103 input hashes unchanged. It caught rejection of a previously
supported nested expression. R metadata/prediction checks passed 62 assertions;
existing inference unit checks passed with four live tests explicitly skipped.
The generated numeric fixture has 317 values from R 4.6.0 with `scipen = 0`.

## 6. Tests of the Tests

The original public quadratic/factor/interaction selector failures are retained
in probe001. Collision-red001 reproduces input-column overwrite: six passes,
seven failures and a matrix-dimension error. The numeric boundary RED has
66 passes and four failures. The broader generated grid and nested-expression
RED are retained. Thirteen independently damaged public receipts were rejected for public007.
Final public008 repeated these controls against the17-case candidate. The
13-row conditional fixture also covers nondegenerate Boolean branches; its
earlier four-row version is retained. Prior success never substitutes for
current-source qualification.

## 7a. Issue Ledger

[DRM.jl #563](https://github.com/itchyshin/DRM.jl/issues/563) remains the programme
ledger. Neither Ayumi's issue29 nor her validation comment is closed or edited.
Whole-tree profiling, native canonical-tree qualification, controls/gradient
diagnostics and larger bootstrap evidence remain distinct obligations.

## 8. Consistency Audit

Reviewed actual R list-to-OrderedDict conversion: unchanged saved payloads have
deterministic synthetic allocation. This is not a guarantee across translator
changes or manually changed payloads. Bivariate formula objects retain their
formula fields; prepared joint-model routes without labels do not enter the new
mapper. A real ordinal-intercept regression was identified and repaired.

Memory receipt: this continues the already routed ultra-plan/unlazy/ask-brain
programme; no new broad brain search or Codex memory write was needed. The
relevant 25 R and six Julia missing refs were checked; the article's additional
missing-ref audit found no lost overlapping repair. The Golden Set was not
rerun for this bounded source slice; that is not a completed programme audit.

## 9. What Did Not Go Smoothly

Review caught Cartesian interaction mislabeling, coordinate-order checks that
accepted permutations, LSS prefix ambiguity, an ordinal intercept mismatch,
arithmetic source spelling and the nested-transform regression. Early numeric
formatting fixes overfit examples; a generated grid replaces those assumptions.
Public003 failed during Julia startup under restricted cache access; its raw
log is retained, and independent startup001 succeeded in 13.62 seconds with
existing cache access. One empty in-flight log snapshot was copied early; its
completed contents are retained under a separate `-completed` filename.
The positional-only Python runner accidentally executed when called with
`--help`; its successful bounded receipt is preserved unchanged as combined003.
The argparse correction exits before Julia for help or invalid arguments, and
combined004 tested the corrected runner. Rose then caught the same parenthesis
loss around scale(), because the initial source capture covered I() only.

## 10. Known Residuals

Bounded source repair, current-source checks, Rose approval and Melissa
reconciliation passed. Scoped commit and subsequent programme integration are
recorded in LOOP/checkpoint.md; no merge or deployment is claimed here. All programme G0–G8
remain open. The strict 4e-6 coefficient gate is unchanged. The two denied
Gaussian engine files are untouched; their gradient/performance work still
requires fresh authorization. No releases, registration, deployment, worktree
retirement, stash disposal or collaborator messages occurred.

## 11. Team Learning

Rose independently approved finalsource269937e0 and checked the retained runtime
oracles. She caught an optimized-Python bypass in the new receipt checker before
closure; explicit errors replace assert, with11damagecontrols passing in both
modes. Melissa (the existing Terra/high child) reconciled obligations, identified
stale records and missing closure artifacts, and root corrected them. This was
an obligation audit; independent scientific/source review remained with Rose.

Public labels are part of numerical identity, not decoration. Generate labels
from typed columns, preserve the same coordinate order for values and both
covariance axes, and test scalar formatting against native outputs across a
grid. Successful focused tests need existing admission neighbours alongside
them. Parent actual routing: Sol/medium; builder Terra/high, Rose Sol/high,
scout Luna/low. Active agent-hours were not instrumented.

## 12. Cross-Product Coverage

The bounded candidate checks cover ordinary Gaussian mean coefficient identity,
small public/direct profile and bootstrap selector dispatch, covariance
transport, pure R prediction behavior and selected existing bridge neighbours.
The slice does NOT cover all native-R models, interval coverage, arbitrary
direct-Julia new-data reconstruction, whole-tree profile speed, an automatic
thread policy, canonical polytomy integration, all missing-predictor cases or
the complete rendered/deployed documentation site. Existing broad obligations
remain required; none is removed by this report.
