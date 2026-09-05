# 2026-08-24 capability-status.md chip audit (Rose)

Scope: every row in `docs/design/capability-status.md` that is not
`implemented` -- the 4 `missing`, 1 `planned`, 1 `rejected` rows, per the
document's own ladder (implemented = source + a registered test; rejected =
explicit guard; planned = tracked documented stub; missing = no
implementation found). Owner authorised chip flips this session, narrowed by
Mission Control's standing warning: do not flip `missing` -> `implemented`
without code + tests. This file is the code+test verification and the
row-by-row reasoning; `docs/design/capability-status.md` carries the
resulting edits.

## Row-by-row

| Row | Old status | Source cite | Test cite | Ladder verdict | New status | Reason |
|---|---|---|---|---|---|---|
| AGHQ adaptive-quadrature marginal estimator | missing | `src/aghq_1d.jl`, included `src/DRM.jl:74`; public front end `marginal=:AGHQ` on `drm()` for Poisson `(1\|g)`, `src/poisson.jl:35-37,176-177` | `test/test_aghq_1d.jl`, registered `test/runtests.jl:177` | Meets the ladder: source wired in + registered test | **implemented** | PR #449 (commit `93c3db6b`, merged 2026-08-18) landed both source and test in one PR; the same PR's own doc edit is what is being corrected. Owner explicitly authorised this flip today, superseding a prior "do not flip" note. |
| Cross-family bivariate | missing | `src/mixed_family.jl` (`src/DRM.jl:101`) + `src/mixed_family_postfit.jl` (`src/DRM.jl:102`); formula front end `drm(f::BivariateDrmFormula, fams::Tuple; …)` (commit `0095fefd`) | `test/test_mixed_family.jl`, `test/test_mixed_family_postfit.jl`, `test/test_cross_family_formula.jl` — all registered (`test/runtests.jl:281,350,352`) | Meets the letter of the ladder (source + registered test) | **missing (unflipped)** | `docs/dev-log/check-log.d/2026-08-16-a11-cross-family-formula.md` records an explicit decision the same week the formula front end landed: *"No promotion — the row stays `experimental`; this removes its stated blocker, which is drmTMB's call to act on."* That is a deliberate non-advertisement call tied to R<->Julia parity governance (the whole point of this file), not a stale chip. It has not been revisited. Today's authorization named AGHQ specifically, with a PR number and commit hash; it did not name this row. Corrected the stale "single `gaussian_bivariate.jl` source file" citation in the doc regardless — that claim is now false. Flagging for the owner as a separate decision rather than deciding it myself. |
| Missing-response handling (native, per fitted route) | missing | Two mechanisms, neither previously cited fully: (1) `_fit_observed_response_rows` (`src/gaussian_core.jl:717`), a shared auto-drop-with-warning helper used inside `drm()` itself by 12 family files (beta/betabinomial/binomial/cumulative/gamma/gaussian_core/lognormal/negbinomial/poisson/tweedie/student/zeroonebeta); (2) `leaf_nll(u,y1,y2,…,o1,o2)` (`src/sparse_aug_plsm.jl:37`), per-cell masked partial likelihood in the flagship q4 bivariate phylo engine, wired via `src/fit_q4_sparse_tmb.jl` (`src/DRM.jl:40`) | `test/test_missing_response.jl`, `test/test_missing_response_nongaussian.jl` (14 families), `test/test_missing_response_bivariate.jl` (FD-vs-exact gradient with masked cells + MAR fit check) — registered `test/runtests.jl:48-50` | Native code + registered tests exist for many routes; mechanism (1) is auto-triggered listwise deletion (same operation as `drm_listwise`, just automatic), only mechanism (2) is a true masked likelihood | **missing (unflipped)** | Issue #49 is explicitly open/parked; `missing_data.jl`'s own header states FIML for missing responses is out of scope. drmTMB's named row means masked likelihood across 18 fitted routes; DRM.jl's per-route native handling is mostly automatic deletion (real and native, but the *same* operation as the already-known `drm_listwise` utility) except for the one true masked-likelihood exception in the q4 bivariate engine. Corrected two citation errors in the doc: `missing_data.jl` is included at `src/DRM.jl:131`, not `:101` (`:101` is `mixed_family.jl`); and "listwise deletion only" undercounted the auto-drop mechanism used by 12 families plus the genuine masked-likelihood exception. Status stays `missing` because #49 remains open/parked and today's authorization did not name this row. |
| Missing-predictor imputation (`mi()`) | missing | none found | n/a | No implementation anywhere in `src/` | **missing (unflipped, unchanged)** | `grep -rn "mi("` across `src/*.jl` (excluding `min`/`missing`/`admi`/`semi` false hits) returns nothing. `missing_data.jl`'s header explicitly puts predictor imputation out of scope under #49. Straightforward, no stale claim to correct. |
| Variational (VA/ELBO) marginal estimator | planned | `src/variational.jl`; public front end `marginal=:VA` works (not just the generic `_fit_va` stub) for Poisson/Binomial/NegBinomial2/Gamma/Beta `(1\|g)` — `src/poisson.jl:26`, `src/binomial.jl:38`, `src/negbinomial.jl:69`, `src/gamma.jl:34`, `src/beta.jl:35` | `test/test_variational.jl`, `test/test_va_poisson_elbo.jl`, `test/test_va_frontend_families.jl`, `test/test_variational_binomial.jl`, `test/test_variational_nb2.jl`, `test/test_variational_gamma.jl` — all registered `test/runtests.jl:170-176` | Ladder's "planned" definition (tracked stub + open issue) still literally applies since #136 is open; but "asserts only plumbing, not a working VA fit" is false — anchors exercise real ELBO fits | **planned (unflipped)** | `docs/dev-log/check-log.d/2026-08-09-136-va-rung2-3.md`: *"Guide banner Experimental not Planned... Does not close #136."* Five families work under an explicit "Experimental" banner, but #136 stays open (phylo, crossed, correlated slopes, zi/hu, 136e unwired). Task guidance explicitly named "VA/#136 is Experimental and open" as a row to treat with the same care as `:natgrad` — do not upgrade past what the open issue supports. Corrected the false "plumbing only" claim in the doc without changing the status word. |
| Natural-gradient EM (`algorithm = :natgrad`) | rejected | `src/lc_metric.jl` (Fisher metric only, not a solver); `fit_em_natgrad` stays unexposed | n/a (deliberate fence) | Explicit, measured decision-gate FAIL, not a mistake | **rejected (unchanged)** | Confirmed against `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md`: #13 decision gate measured `fit_em_natgrad` stalling vs `fit_q4_sparse_tmb` on `q4_p100` (2026-08-01). This is the textbook deliberate fence — do not upgrade because code exists. No change made. |

## Flips made

- `AGHQ adaptive-quadrature marginal estimator`: `missing` -> `implemented`.

## Flips deliberately NOT made (with why)

- `Cross-family bivariate`: source + registered tests exist and technically meet the ladder, but a dated, explicit "No promotion... drmTMB's call to act on" decision (2026-08-16) governs this specific row and has not been revisited. Corrected the stale single-source-file citation; left the status word alone; flagged for the owner.
- `Missing-response handling (native, per fitted route)`: native, wired, tested code exists (auto-drop across 12 families + true masked likelihood in the q4 bivariate engine), more than the doc credited, but #49 is explicitly open/parked and the underlying mechanism for most routes is still deletion, not drmTMB's named masked-likelihood capability. Fixed two stale citations; left status alone.
- `Missing-predictor imputation (mi())`: no code found; nothing to flip.
- `Variational (VA/ELBO) marginal estimator`: five families work under an explicit "Experimental" (not "Planned") banner per the project's own 2026-08-09 check-log, but issue #136 stays open and today's authorization did not name this row. Corrected the false "plumbing only" claim; left status alone.
- `Natural-gradient EM (:natgrad)`: deliberate, measured rejection (#13 decision gate); not touched.

## New tally

41 `implemented`, 1 `rejected` (`:natgrad`), 1 `planned` (VA), 3 `missing`
(cross-family bivariate, native missing-response handling, `mi()`) = 46
total. (Was 40/1/1/4.)

## HARD CLAIM FENCE check

Diff: `git diff -- docs/design/capability-status.md`.

```
grep -n '^+' <diff> | grep -iE "faster|×|[0-9]+\.?[0-9]*x |speed|accura|coverage|recover(s|ed|y)? to|atol|rtol|percent|%|CI (width|coverage)|calibrat"
```

No matches. A second, broader pass for `recover|parity|1e-|≤|<=|≈` matched
one line, which reads "Gaussian x Poisson and Gaussian x Gaussian
recovery-style tests" — naming a test *category* (mirroring the existing
document's own pre-existing style, e.g. "NB2 recovery + Gamma smoke"), not a
numeric accuracy/coverage/speed claim. No tolerance numbers, percentages,
speed ratios, or "faster than" language were introduced anywhere in the
diff. The pre-existing 2.18×, O(p), and 60/60 bootstrap claims elsewhere in
the document were not touched.
