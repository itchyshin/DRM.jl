# GOAL — issue #291 Arc 2: sparse-first REML characterization (IMMUTABLE)

## Mission
Characterize the existing sparse Gaussian q4 baseline REML route with
report-only evaluation accounting and a warm/order-safe harness protocol.
Frame any future AI/observed-information work against that sparse baseline.
Do not implement or expose an accelerated solver.

## Headline
Do not assume AI-REML is a speed win: measure and report the sparse baseline
honestly before writing another optimizer.

## Invariants
- One lane on `feat/291-reml-sparse-first` (stacked on Arc 1 tip). Leave
  `.worktrees/`, #136, bridge APIs, General, and Registrator (D-111) alone.
- No `src/` edits. No `:natgrad`, AI-REML public API, or 10k/heavy runs.
- Timing may be compared across methods only when warm/order metadata marks
  the pass as comparable; otherwise evidence is diagnostic-only.
- Do not invent a Szymek quotation; attribute the “AI-REML not necessarily
  faster than sparse” premise as owner/planning input unless a vault source
  is retrieved.
- Preserve the verified q4 engine baseline; never vendor drmTMB GPL source.
- Gates: pause before merge, publish, a public speed claim, or heavy compute.

## Authoritative WHAT
`LOOP/ultra-plan.md` freezes the approved sparse-first plan.

## Definition of done
1. Harness reports structural baseline accounting (outer φ dimension and
   central-FD evaluation upper bound) without changing `src/reml_q4.jl`.
2. Warm/order protocol distinguishes compilation/cold first-pass timing from
   warm timed passes and records fit order.
3. Framing note distinguishes H² exact-Gaussian AI-REML from DRM q4
   restricted-Laplace REML and states non-claims.
4. Fixed small-fixture artifact is read and classified
   (`diagnostic_only` or `warm_comparable`).
5. Focused contract test, check-log, after-task/Rose, and Melissa
   plan-actual land; scoped PR related to #291.
