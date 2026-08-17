# GOAL — docs-arc1-backlog-after-434 (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Refresh the Arc 1 ordered backlog on a new scratch branch from `origin/main`
after #434: fixture **banked**; `claim_status` still **partial**; stale
**NONE** line gone; 11 IDs once; no new recommended implement. Land
after-task + check-log + Rose. One issue → one unarmed PR that closes it.

## Headline

Docs-only — re-rank the 11 unsigned rows now that #434 shipped. Do not
implement a ledger row.

## Invariants

- One lane: `docs-arc1-backlog-after-434` @
  `~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434`.
- Do **not** use Dropbox leftover `docs/a3c-design`,
  `~/local-scratch/lanes/DRM.jl-catchup`, or
  `~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml`.
- New LOOP kit only (this directory). Do not reuse #432 / #434 / catchup kits.
- `src/` frozen. No `test/runtests.jl`. No TSV `supported` flip.
- Do not touch `#423` / `#425` / `#428` / `#429` / `#420` / `#406` / `#421` files.
- `#136` stays OPEN. `#49` PARKED. D-111 OFF. Never checkout drmTMB.
- Never stage `.codex/agents/shannon-coordinator.toml`.
- Phrase: *refresh the Arc 1 backlog after #434; fixture banked; 11 rows
  still unsigned.* Do not write "R–Julia parity complete." Do not name a
  new recommended implement.
- Quote `claim_boundary`. D-94 = behind drmTMB, not GLLVM.
- Grok only. No auto-start implement after this PR.

## Authoritative WHAT

`LOOP/ultra-plan.md` (copy of
`docs/dev-log/after-task/2026-08-16-ultra-plan-next-after-biv-q4.md`).
G0 approved defaults: docs-only; defer `runtests.jl` include; stop after
this PR.

## Definition of done

- [ ] `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md` no longer
      says fixture **NONE** for `biv_q4_phylo_reml`; `claim_status` still
      `partial`; no new recommended implement named
- [ ] 11 unique `capability_id`s, each once
- [ ] after-task + check-log + Rose verdict on this refresh
- [ ] one GitHub issue; one unarmed PR that `closes #NN`
- [ ] `git diff origin/main` has no `src/`, no `runtests.jl`, no TSV,
      no `capability-status.md`
- [ ] STOP after the docs PR — do not start an implement row
