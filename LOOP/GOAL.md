# GOAL — issue #291 Arc 0: REML baseline ladder (IMMUTABLE — re-read at the top of EVERY arc)

## Mission
Execute only the approved Arc 0 for issue #291: document the Gaussian q4 REML
acceleration design boundary and add a reproducible small-fixture harness that
compares ML with the existing baseline REML route. Leave the issue branch ready
for review; do not implement or expose an accelerated solver.

## Headline
Produce an auditable baseline before any acceleration claim: point estimates,
objective, convergence, timing, and interval status stay together.

## Invariants
- One issue, one branch: `feat/291-reml-baseline-ladder`; do not touch
  `.worktrees/`, issue #136, bridge APIs, General, or Registrator (D-111).
- ML remains the default; REML is opt-in. `lc_metric` is infrastructure only.
  Do not expose `:natgrad`, AI-REML, an engine-control API, or a public speed claim.
- Do not edit `src/` or experimental prototypes. Do not run 10k or other heavy work.
- Preserve the verified q4 engine baseline (logLik about −256.51); never vendor
  drmTMB GPL source.
- Gates: pause before merge, publish, a public claim, or heavy compute.

## Authoritative WHAT
`LOOP/ultra-plan.md` freezes the approved issue #291 Arc 0 plan.

## Definition of done
1. A design-boundary note names the supported Gaussian q4 REML objective,
   baseline and future-candidate boundary, and explicitly excludes a public
   AI-REML claim.
2. A small-fixture ML-vs-baseline-REML harness records SHA, dirty state, Julia,
   threads, BLAS, timing, convergence, objective, estimates, and CI/status.
3. A test covers the harness’s reproducible report contract and is wired into
   `test/runtests.jl`.
4. Local relevant tests and the harness are run; their logs/artifacts are read.
5. A worked note, check-log entry, after-task report, and Rose audit are present.
6. Scoped commits are made and pushed; opening a PR is an OPEN GATE.
