# 2026-08-16 — Arc 1 inventory (docs only)

**Lane:** `docs-arc1-inventory` · Shannon / Ada / Hopper / Rose (named
perspectives; **no spawned Task subagents** — conductor recon on Cursor Grok).
**Branch:** `docs/arc1-inventory` from `origin/main` in
`~/local-scratch/lanes/DRM.jl-catchup`.
**closes:** (docs PR; issue number assigned at open if any)

## What landed

Ordered claim-fenced backlog of the 11 `claim_status ≠ supported` ledger rows,
plus one recommended first *later* implement slice.

- Backlog: `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`
- Batches: `2026-08-16-arc1-batch-{partials-admitted,partials-rest,experimental,owned-fence}.md`
- Prior evidence copied onto the branch: eleven-rows, Rose fence, Hopper twin-map, Shannon collisions
- LOOP/ kit for this inventory run (GOAL / arcs / checkpoint / ultra-plan)

## Recommended later slice

`biv_q4_phylo_reml` (same-target fixture-gap on an already-implemented q4 REML
path). **New G0 required.** Not a TSV flip. Not `#428` / `#136` / `#49` /
`engine_control_surface`.

## Verify

- 11 unique IDs, once each (S7 in the backlog)
- Rose: no "parity complete"; no TSV flip; `#428` not stolen
- TSV tip `d9fddfa28` unchanged vs eleven-rows `097bed1e2`

## What this did NOT cover

Implementation of any row. `src/` edits. Capability-status chip flips.
`Pkg.test`. drmTMB checkout. Coordination-board edit.
