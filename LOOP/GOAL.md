# GOAL — ship opt-in Cox–Reid `method = :REML` on Poisson `(1 | g)`, one cell, ML still default

**IMMUTABLE for this run.** Re-read this file at the top of EVERY arc, before anything else.

Issue: https://github.com/itchyshin/DRM.jl/issues/443
Base: `origin/main` @ `e161c165` (probe PR #442 merged; REML #440 merged).
This is the **wiring** G0. The scoping probe is DONE — do not re-run it, do not reopen it.

## Definition of done

- [x] `drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data, method = :REML)` returns a fit
      with `estimation_method(fit) === :REML`, and ML is byte-identical to before.
- [x] Failing test written first, then the implementation (TDD red → green).
- [x] Standalone `test/test_cox_reid_poisson_ranef.jl`, **not** registered in `runtests.jl`.
- [x] Every other Poisson route errors on `:REML` naming `(1 | g)` — never a silent ML fit.
- [x] Docstring: opt-in, the over-correction caveat, ML-default.
- [x] Worked example (docstring + test-file header).
- [x] Check-log entry in `docs/dev-log/check-log.d/`.
- [ ] After-task report.
- [ ] PR open, `closes #443`.

## The one correction this lane made to its brief

The brief named the hook `sparse_laplace_glmm.jl:555`. That is
`_fit_poisson_general_laplace` — the **phylo/relmat Laplace** spine (probe Cell C, Go
item **#2**). The certified first cell, Poisson `(1 | g)` GHQ-32, is
`_fit_poisson_ranef` in `src/poisson.jl`; the probe note says in as many words that
public `(1 | g)` is *not* the `:555` spine. The brief also said "the Poisson `(1|g)`
hole only", which is the constraint that decides it. `(1|g)` carries no analytic
gradient closure, so `grad_fn = θ -> ForwardDiff.gradient(nll, θ)` feeds the generic
helpers — the same quantity probe Cell A used.

## Invariants (never violate, even to finish faster)

- **ML stays the default.** Cox–Reid over-corrects at larger G (+4.38% at G=40 vs
  −12.37% ML at G=10). Opt-in forever; no default flip.
- **Scalar-per-cluster only.**
- Reuse `_glsp_reml_penalty` / `_glsp_reml_refit_clean` / `_withreml` — a wiring job,
  not a derivation. `_withreml` is a TAG; it computes nothing.
- Cite −7.3 / −5.0 / −0.9 as **drmTMB's** (`cumulative_logit`), never as DRM.jl recovery.
- Verification means reading the LOG and inspecting the ARTEFACT, never the exit code.
- A narrow or negative search is not proof.

## Out of scope (the fence — do NOT drift here)

- **No AGHQ.** Lever 2, and it waits on GLLVM honesty. Nodes plateau at the VC-bias floor.
- **No q4 / `src/reml_q4.jl`.** No `src/gaussian_ranef.jl` edit. No REML #440 redo.
- **No bivariate.** No `test/runtests.jl` registration (waits on the Option A sibling).
- No TSV, no capability chip, no "has non-Gaussian REML" sentence.
- No GLLVM Λ / loading-matrix numbers as DRM.jl recovery. No GPL vendoring.
- Does **not** close #136 / #11 / #49 / #441.
- Leftover `docs/a3c-design` is a different subject — do not touch it.
