# GOAL — #388 dual-Julia RNG CI exposure (IMMUTABLE — re-read every arc)
# Status: ACTIVE 2026-08-07 — G0 APPROVED via ultra-plan implement.

## Mission
Close or honestly disposition DRM.jl #388: dual-Julia (1.10 vs 1.x) RNG
exposure evidenced on a risk cohort; repair only proven fragile classes.

## Headline
Reuse HSquared 2026-08-04 playbook (CI stays RNG-free for recovery claims;
literal fixtures / env-gated sim). Do NOT blanket-add StableRNGs to main
Project.toml.

## G0 locked
- Sequence: #395 MERGED @ 26d39efe; branch `feat/388-ci-rng-exposure` from tip.
- Repair taxonomy: (1) env-gate / (2) literal fixtures; StableRNGs last resort.
- Arc 0 = named risk cohort, not immediate double full Pkg.test.

## Invariants
- No #136 / #49 / D-111 / tip-idle padding.
- Never stage `.worktrees/`.
- Rose: latent ≠ fixed; no suite-wide immunity claim from one cohort.

## Authoritative WHAT
`docs/dev-log/plans/2026-08-07-388-rng-ci-ultra-plan.md` (+ Cursor plan).

## Definition of done
- Dual-version cohort evidence retained
- Repair if red, else latent-OK with Rose honesty
- check-log.d + after-task + Rose; PR `closes #388`
