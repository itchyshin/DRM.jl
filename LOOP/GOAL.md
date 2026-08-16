# GOAL — feat-biv-q4-phylo-reml-fixture (IMMUTABLE — re-read at the top of EVERY arc)

Read this first, every cycle. Auto-compact eats messages, not this file.

## Mission

Add one measured same-target DRM.jl↔drmTMB fixture for the `biv_q4_phylo_reml`
cell (coef + logLik + fit-specific CI/status), plus a standalone Julia test,
check-log, after-task, and Rose claim fence. One issue → one branch → one PR.

## Headline

One same-target fixture for `biv_q4_phylo_reml` within the row's declared
tolerance. Not "R–Julia parity complete."

## Invariants

- One lane: `feat-biv-q4-phylo-reml-fixture` on `claude/lane-biv-q4-phylo-reml`
  in `~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml`. Not Dropbox leftover
  `docs/a3c-design`. Not `#432` catchup worktree.
- Mac-only small cell (p≈16, nrep≈5, seed recorded). Do not silently escalate
  to Totoro/DRAC. If either side fails to converge, shrink/reseed and record.
- Standalone `test/test_parity_biv_q4_phylo_reml.jl`. Do **not** touch
  `test/runtests.jl`.
- Payload: coef + logLik + fit-specific CI/status (`converged`, `pdHess` /
  Julia equivalent, `interval_status`). No coverage, reliability, or AI-REML
  claims.
- `src/` frozen. No TSV `claim_status` → `supported`. No capability-status flip.
- Do not edit `test/parity/runparity.jl`, `gen_fixtures.R`, `runparity_bridge.jl`.
- Do not touch `#423/#428/#429/#425/#420/#406` files. `#136` stays OPEN.
  `#49` PARKED. D-111 OFF.
- Never stage `.codex/agents/shannon-coordinator.toml`. Never `git add -A`.
- Never checkout the shared drmTMB tree (read-only `git show` / generated
  outputs only). License: generated outputs, not GPL source.
- Claim sentence only: *this PR adds a native-vs-Julia same-target fixture for
  `biv_q4_phylo_reml` within the row's declared tolerance.*
- Do not rewrite `test_bridge_q4_direct_export.jl`'s "no R-via-Julia q4 bridge
  parity" (this slice is native `drm()`, not the bridge).
- Never push, merge, or publish without an OPEN GATE. Auto-merge last or leave
  unarmed (owner default unarmed).
- HANDS TO Codex if live `Rscript` / Julia REML fit needs the toolchain; STOP
  at that gate. HANDS TO Claude only if an unexpected `src/` bug appears —
  then STOP, new G0.
- Easy on Mac CPU — no full `Pkg.test`.

## Authoritative WHAT

`LOOP/ultra-plan.md` (copy of
`docs/dev-log/after-task/2026-08-16-ultra-plan-biv-q4-phylo-reml-fixture.md`).
G0 approved 2026-08-16 with Q1–Q3 defaults: Mac-only; standalone test; coef +
logLik + CI/status, no coverage.

## Definition of done

- [ ] Fixture dir exists with data + tree + expected.toml + expected.meta.toml
      (drmTMB **0.7.0**, r_call, seed)
- [ ] Standalone test exists and was run; Julia re-fit matches within `[tol]`
- [ ] Status fields recorded (converged / pdHess-or-equiv / interval_status)
- [ ] No `src/` diff; no `runtests.jl`; no TSV `supported` flip
- [ ] Check-log + after-task + Rose section + plan-actual
- [ ] One GitHub issue; PR `closes #NN`
- [ ] Claim fence held
