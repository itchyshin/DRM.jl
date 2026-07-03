# After Task: q2 Known-Precision Provider Contract

## 1. Goal

Make the q2 known-precision bridge primitive provider-scoped before any R-side
formula or slope work uses it as a target.

## 2. Implemented

`drm_bridge_q2_known_precision()` now accepts `structured_type` and
`precision_source` keyword arguments. The accepted provider/source pairs are
deliberately narrow:

- `structured_type = "relmat"` with `precision_source = "Q"`;
- `structured_type = "animal"` with `precision_source = "Ainv"`.

The primitive still consumes the supplied matrix through
`make_coevo_problem_from_precision()` and still returns the q2
residual-correlation point-export payload. The payload now records the exact
provider and source instead of always labelling the fit as relmat `Q`.

This slice also adds `_bridge_q2_known_precision_status()`,
`_bridge_q2_known_precision_schema()`, and
`_bridge_q2_validate_known_precision_status()` so the two private direct
precision rows are machine-checkable.

## 3a. Decisions and Rejected Alternatives

I kept the route private and direct. It is a Julia-side precision payload target
for complete-response exact-Gaussian ML q2 fixtures, not a formula bridge and
not structured slope support.

I rejected accepting arbitrary provider labels because that would make a single
precision primitive look like broad structured bridge support. The two admitted
providers match the current precision-source blockers: relmat `Q` and animal
`Ainv`.

## 4. Files Touched

- `src/bridge.jl`
- `test/test_bridge_q2_direct_export.jl`
- `docs/dev-log/check-log.d/2026-06-26-q2-known-precision-provider-contract.md`
- `docs/dev-log/after-task/2026-06-26-q2-known-precision-provider-contract.md`

## 5. Checks Run

```sh
julia --project=. test/test_bridge_q2_direct_export.jl
julia --project=. test/test_bridge.jl
julia --project=. test/test_bridge_q4_direct_export.jl
Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-q2-known-precision-provider-contract.md')"
julia tools/build_check_log.jl >/tmp/drmjl-check-log-provider-contract.txt
git diff --check
```

The focused q2 direct-export file passed 177/177 assertions. The new provider
status contract contributes 20 assertions. The expanded precision primitive test
contributes 32 assertions and checks both the default relmat `Q` path and the
animal `Ainv` path against the same direct precision fit.

The bridge boundary regression passed 51/51 assertions and the q4 direct-export
regression passed 36/36 assertions. The after-task structure check passed.
`tools/build_check_log.jl` exited successfully while still reporting older
malformed check-log.d entries already present on the stacked base. `git diff
--check` was clean.

## 6. Tests of the Tests

The provider status test mutates the animal row to use the wrong precision
source and verifies that the validator fails. The primitive test checks
unsupported provider and mismatched provider/source combinations, along with the
pre-existing malformed response and non-positive-definite precision failures.

## 7a. Issue Ledger

No issue was edited. This branch is stacked on DRM.jl#299, which is stacked on
DRM.jl#298 and DRM.jl#297.

## 8. Consistency Audit

The status rows use `route = "direct_drmjl_private"` and
`bridge_status = "private_diagnostic"`. Claim boundaries explicitly reject
R-via-Julia formula support, structured slope support, broad q2 bridge support,
q2 REML, q4, AI-REML, interval reliability, and coverage.

## 9. What Did Not Go Smoothly

The first patch used a relmat-only claim string and one long status row. I
rewrote the text as provider-scoped payload language before running the focused
test.

## 10. Known Residuals

This does not add `animal(Ainv)` or `relmat(Q)` formula support in the R bridge.
It does not add one-slope structured q-series runtime support in DRM.jl. It also
does not change any q4, REML, interval, coverage, non-Gaussian, or public
optimizer-control boundary.

The next bridge-facing step is still row-specific R-side preflight once the
stack below this branch is accepted. The next runtime blocker for one-slope
cells remains a slope-capable structured route or separate exact slope fixture
primitive.

## 11. Team Learning

Provider identity needs to be payload data, not just prose. The same numerical
precision primitive can serve relmat `Q` and animal `Ainv`, but the support
claim has to stay cell-specific until formula routing and slope support catch
up.
