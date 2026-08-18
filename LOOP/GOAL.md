# GOAL — aghq-lever-2 (IMMUTABLE — re-read at the top of EVERY arc)

**IMMUTABLE for this run.** Re-read this file at the top of EVERY arc, before anything else.

## Mission

Land **one** GitHub issue, **one** scratch worktree off `origin/main` (`d04ba994` or newer), and **one** PR that ships a **DRM-native 1-D Liu–Pierce AGHQ kernel** around existing `_gauss_hermite`, plus a Poisson `(1|g)` opt-in path: `marginal=:AGHQ`, `nAGQ=5`. Default `:LA` stays today's GHQ-32. The capability row stays **missing**. Finish line: a mergeable PR with AGENTS.md Definition of Done; merge itself is a **human gate**.

## Headline

A. AGHQ port (lever 2) — 1-D adaptive Gauss–Hermite around `_gauss_hermite`. Not a GLLVM quadrature-claim copy. Not a tensor port onto phylo Laplace. k=1 ≡ 1-point Laplace is **plumbing**, not a quadrature or recovery headline.

## Invariants

- One lane: `aghq-lever-2` on `claude/lane-aghq-lever-2` at `~/local-scratch/lanes/DRM.jl-aghq-lever-2`. Do not touch leftover trees (`docs/a3c-design`, `docs/arc1-inventory`, cox-reid-*, `handover/2026-08-18-cursor`) or dirty PRs #420 / #406.
- Never push, merge, or publish from the loop — those are HUMAN GATES (`src/` + public `marginal` = Noether + maintainer; PR merge).
- Verification means reading the **LOG** and inspecting the **artefact**, never the exit code.
- Q1/Q2 defaults (G0): Poisson `(1|g)` opt-in 1-D AGHQ; public `marginal=:AGHQ` + `nAGQ=5`; chip stays missing.
- Twin = drmTMB. Cite −7.3/−5.0/−0.9 as **drmTMB's**. Never headline GLLVM Λ. Never vendor drmTMB GPL (`R/aghq-coxreid.R`) or GLLVM `aghq_grid.jl`.
- ML stays default. `:REML` stays opt-in and is **not** wired to `:AGHQ` this slice.
- Do not relabel GHQ-32 `:LA` as AGHQ. Do not treat QuadGK / VA 12-node / `(1+x|g)` 12² as AGHQ.
- k=1 agreement ≠ quadrature. Never summarise a mixture with a median. Never cite a reference fitter as engine evidence.
- Never `git add -A`. Never stage `.codex/agents/shannon-coordinator.toml`. Never mutate GLLVM `LOOP/GOAL.md`.
- D-111 Julia General OFF. #49 PARKED. No q4 / `reml_q4.jl`. No Cell D / Totoro ADEMP.

## Authoritative WHAT

`LOOP/ultra-plan.md` (approved G0). This file wins on "what must never be lost"; the plan wins on slice detail.

## Definition of done

- [ ] One new issue (AGHQ 1-D Liu–Pierce / lever 2); one branch; one PR `closes #NN`
- [ ] `src/aghq_1d.jl` (name flexible): 1-D Liu–Pierce wrapper; fail-loud if dim ≠ 1; k=1 identity test
- [ ] TDD: `test/test_aghq_1d.jl` (red then green); smoke: adaptive k≈5 nll **agrees** with GHQ-32 on a tiny Poisson `(1|g)` fixture — agreement, not recovery
- [ ] `marginal=:AGHQ` + `nAGQ=5` on Poisson `(1|g)` only; default `:LA` unchanged; fail-loud elsewhere listed in the plan
- [ ] Mac-local `Pkg.test` log read; numbers recorded
- [ ] Docstrings + worked example; capability row **still missing**; check-log.d + after-task + Rose claim-vs-evidence
- [ ] DoD (AGENTS.md); no `_fit_poisson_general_laplace` REML/tensor hunk; no capability-chip flip

## Out of scope (the fence — DEFER B)

- Do **not** edit `_fit_poisson_general_laplace` for Cox–Reid or tensor AGHQ
- No q4, no #49, no #420/#406 steal, no GLLVM LOOP/GOAL.md, no GPL vendoring, no capability-chip flip, no GLLVM Λ numbers
