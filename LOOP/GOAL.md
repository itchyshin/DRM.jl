# GOAL — #202 locscale closeout (IMMUTABLE — re-read every arc)
# Status: ACTIVE 2026-08-05 — G0 APPROVED via /goal (judgment defaults).

## Mission
Close or honestly re-scope open #202 by landing the remaining **PUBLIC**
surface + evidence for non-Gaussian phylogenetic location–scale (NB2 primary;
Gamma already engine-gated), then DoD PR (`closes #202` or splits remainder).

## Headline
Tip already has `src/locscale_*.jl` + Gamma phylo recovery via private
`_fit_locscale` — this lane is CLOSEOUT / public API / ledger honesty, **not**
a greenfield q=2 kernel rebuild.

## G0 locked (judgment defaults)
- **Grammar B:** public acceptance =
  `bf(y ~ x + (1|p|phylo(species)), sigma ~ 1 + (1|p|phylo(species)))`
  Dual issue-text `phylo(1|sp)` on both axes is **out of cohort** (document;
  do not implement alias unless under-run).
- **D-94:** ship public phylo locscale; defer `nbinom2-locscale` R fixture until
  drmTMB supports coupled `(1|p|species)` (cite R q=1 NB2 structured-σ as
  scale-axis existence cover).

## Invariants
- One lane: branch `feat/202-locscale-closeout` from tip after #394.
- Reuse `locscale_*`; **no q=4 verified core edits**.
- D-111 OFF; leave `.worktrees/` alone; never stage them.
- No GPL vendoring; no #49 / #136; no tip-idle SHA-churn padding.
- ML default; Rose claim-vs-evidence; one issue → one PR.

## Authoritative WHAT
`LOOP/ultra-plan.md` (= `docs/dev-log/plans/2026-08-05-202-locscale-closeout-ultra-plan.md`).

## Definition of done
- Public NB2 phylo locscale fits via grammar B; recovery + FD ≤1e-6 evidenced
- Gamma public path honest (test or documented parity with private gate)
- capability-status row + tutorial/docs; stale “waits on #209” comment fixed
- check-log.d + after-task + Rose; PR open `closes #202` (or close+split)
