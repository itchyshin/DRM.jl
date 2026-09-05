# After Task: Paired Website Reader Journey

## 1. Goal

Give a first-time reader a direct Julia route from the DRM.jl home page to the Gaussian location-scale tutorial and a reciprocal, accurately bounded R companion.

## 2. Implemented

The home-page hero now presents **Fit a Gaussian location-scale model** as its primary action while retaining Get started, the model map, and GitHub. The location-scale tutorial links to the `drmTMB` companion beside its explicit residual-SD and residual-variance interpretation.

## 3. Mathematical Contract

No likelihood, parameterization, formula grammar, transformation, estimator, or model code changed. The existing interpretation remains: exponentiating a log-`sigma` contrast gives a residual-SD ratio, and exponentiating twice that contrast gives a residual-variance ratio. The reciprocal note states that the two packages have distinct APIs, fitting implementations, diagnostics, and route-specific evidence.

## 3a. Decisions and Rejected Alternatives

The slice uses the existing Gaussian location-scale tutorial rather than adding a new route or page. It retains all existing secondary actions. Navigation configuration, route changes, model-capability claims, and a claim of R/Julia API or evidence parity were rejected.

## 4. Files Touched

- `docs/src/index.md`
- `docs/src/tutorials/location-scale.md`
- this after-task report
- `docs/dev-log/check-log.d/2026-09-05-paired-website-reader-journey.md`

## 5. Checks Run

- Full `julia --project=docs docs/make.jl` DocumenterVitePress build: PASS with unchanged `warnonly = false`.
- Rendered home and guide at 1440, 1280, 1024, and 390 CSS pixels: PASS; no body-level horizontal overflow, clipped search control, or hidden primary action.
- Keyboard entry and primary-action tab order: PASS; the visible skip link receives first focus and the primary action is reachable.
- Reciprocal-link and exact-label checks: PASS.
- Independent reviewer: APPROVE, no P0-P2 findings.

## 6. Tests of the Tests

This was a documentation-only slice, so model tests were not added. The strict full documentation build exercised all doctests and page generation with warnings treated as errors by Documenter.

## 7a. Issue Ledger

No issue, comment, pull request, push, merge, or deployment was created; the approved task required local commits only.

## 8. Consistency Audit

The source diff changes no capability map, status ledger, license text, navigation configuration, route, API, generated site, workflow, model code, or test. Existing Julia-direct, R-bridge, default-R-engine, route-specific evidence, and MIT/GPL boundary wording remains unchanged. The new companion note explicitly rejects an identical-API or identical-evidence reading.

## 9. What Did Not Go Smoothly

The documented Julia environment first needed `Pkg.develop` and `Pkg.instantiate` in this fresh worktree. A sandboxed build then hit Julia cache permission errors; the exact strict command passed outside that sandbox. The build remained below the stated 30-minute estimate.

## 10. Known Residuals

The live public Julia site could not be captured reliably through the browser during baseline inspection, so its baseline was retained from source and route checks; the complete local candidate received the rendered four-width audit. No public site was deployed.

## 11. Team Learning

Reciprocal companion links should name both the shared reporting scale and the package-specific inference boundary. That keeps the reader journey connected without turning two implementations into a parity claim.

## 12. Cross-Product Coverage

The paired `drmTMB` home, guide, and CSS changes were reviewed from `/Users/z3437171/.codex/worktrees/5da0/drmTMB`. The R home uses the same primary action label, and each guide links to the other beside the SD/variance-ratio interpretation. The R site passed its focused article build, final full pkgdown build/check, and the same four-width rendered audit. Both public reciprocal URLs returned HTTP 200.

This slice does NOT cover any model, estimator, REML, penalty, engine, missing-data, aggregation, API, capability, evidence-tier, route, workflow, or deployment change in either package.

## Next Actions

Review the two local commits together. Push, pull requests, merging, and deployment remain separate explicit actions.
