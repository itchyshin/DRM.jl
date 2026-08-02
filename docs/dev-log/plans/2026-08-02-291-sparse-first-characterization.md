# #291 Arc 2 — sparse-first REML characterization

**Scope:** report-only accounting and warm/order-safe harness framing for the
existing sparse Gaussian q4 baseline REML route. No `src/` optimizer change.
No AI-REML implementation.

## Why sparse-first

Issue #291 contemplates REML acceleration, including ideas inspired by
HSquared.jl's exact-Gaussian AI-REML path. Two constraints block a naive
transplant:

1. **Estimand mismatch.** DRM q4 REML uses a mode-dependent restricted Laplace
   objective (`docs/dev-log/plans/2026-08-02-291-gaussian-q4-reml-acceleration-boundary.md`).
   H²'s AI quadratic is for exact Gaussian LMM/MME cells. Reusing selected-inverse
   / sparse-factor discipline is fine; copying the update formula is not.
2. **Speed is not assumed.** Owner planning input from conversations with
   Szymon M. Drobniak (Szymek) on H² work is that AI-REML is **not**
   automatically faster than a good sparse route. A vault `/ask-brain` sweep
   (2026-08-02) retrieved the collaborator note and H² performance triage, but
   **did not** retrieve a note with that exact wording — so this document does
   **not** invent a quotation. Treat the premise as a falsifiable framing:
   characterize the sparse baseline before writing another optimizer.

The reusable H² lesson from `HSquared perf triage — A-inverse is fast; the gap
is hsquared's missing native engine` is to locate the real sparse-path cost
before changing algorithms.

## What this arc measures

Harness protocol `:warm_bidirectional` in `bench/reml_baseline_ladder.jl`:

- Structural accounting (report-only): for the fixture, `n_outer_phi = 11` and
  `structural_evals_per_gradient_request = 23` (central-FD upper bound before
  line search; see Arc 1 bottleneck note).
- Warm/order metadata: discard a compile/warmup ML+REML pair; time REML→ML and
  ML→REML; mark `evidence_class` as `:warm_comparable` only when timed fits
  converge.
- Cold `:cold_ml_first` remains available and is always `:diagnostic_only`.

## Evidence classification

| Class | Meaning |
|---|---|
| `diagnostic_only` | Do not rank methods or claim sparse-vs-AI speed. |
| `warm_comparable` | Warm seconds may be compared **within this fixture**; still not a public headline and not an AI-REML result. |

Intervals remain `not_evaluated` in this harness.

## Arc 3 — intermediate fixture rung

`REML_BASELINE_LADDER_INTERMEDIATE_FIXTURE` fixes the next reproducible local
rung at `p=16`, `nrep=3`, `seed=291`. It uses the same balanced-tree generator,
Gaussian q4 formula, seed family, structural accounting, and
`:warm_bidirectional` protocol as the p=8 smoke fixture.

The recorded p=16 artifact at `/tmp/reml-arc3-intermediate.md` was
`diagnostic_only`: its timed baseline REML fits did not report convergence.
That is useful harness evidence, but it **does not** support a timing
comparison, a failure-generalization claim, or an optimizer change. The
intermediate rung remains available for repeatable local checks and for a
separately approved convergence/acceleration investigation.

## Non-claims

- No public AI-REML or `:natgrad` API.
- No claim that sparse “beats” AI-REML from one laptop fixture.
- No 10k / Ayumi speed headline.
- No Julia General / Registrator work (D-111).
- No change to `src/reml_q4.jl` in this arc.
- No p=16 method ranking while its evidence class is `diagnostic_only`.

## Next authorized slice (not this PR)

Live call counters inside the optimizer, or any candidate replacing central FD,
need a separate approved arc and Gates 1–3 from the Arc 1 bottleneck note.
