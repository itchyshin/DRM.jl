# Ultra-plan freeze — DRM.jl #166 (G0 approved 2026-08-02)

Platform: Cursor `/goal` execution.
Deliverable: close #166 — beta-binomial phylo/crossed RE route via the sparse-Laplace engine.
Headline: generalize the verified Beta-family kernel to beta-binomial's known-trials data term.
Fence: D-111; no `:natgrad`; no #291 accel; no drmTMB R edits; no GPL vendor; no `.worktrees/`;
nonconstant-sigma out of scope; no q4-engine-core edits.

## Locked decisions
- Constant-sigma (overdispersion) only for #166; nonconstant tracked as a follow-on issue.
- Reuse `beta_fixed` kernel shape and aux-struct convention exactly (no new dispatch pattern).
- Both phylo and crossed routes land in one PR (mirrors how #189 landed all three providers).

## Acceptance
See `LOOP/GOAL.md` Definition of done.

## Full plan
See `docs/dev-log/plans/2026-08-02-166-betabinomial-phylo-crossed-ultra-plan.md` (frozen source,
read-only reference — this file is the durable pointer copy for the arc loop).
