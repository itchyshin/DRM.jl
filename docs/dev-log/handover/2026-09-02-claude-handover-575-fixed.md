# Handover — #575 exact q4 REML gradient fixed, PR #579 awaiting merge (2026-09-02)

**Author:** Claude (Rose; no subagents running). Worktree
`scratchpad/wt-exact-grad`, branch `feat/575-exact-reml-gradient`.

## `handoff_gate.sh` verdict (verbatim, run against this worktree)

```
PR #579 OPEN: feat(reml-q4): exact REML gradient — closes #575
  XX   wt-exact-grad: acceptance ledger .unlazy/575-closeout/gates/leaf-s1s2.md -- GATES UNMET
  XX   wt-exact-grad: acceptance ledger .unlazy/575-closeout/gates/leaf-s3.md -- GATES UNMET
  XX   wt-exact-grad: acceptance ledger .unlazy/575-closeout/gates/leaf-s5.md -- GATES UNMET
  XX   wt-exact-grad: acceptance ledger .unlazy/575-closeout/gates/leaf-s6.md -- GATES UNMET
  XX   wt-exact-grad: acceptance ledger .unlazy/575-closeout/gates/leaf-s7.md -- GATES UNMET

GATE FAIL -- 5 acceptance ledger(s) have UNMET gates.
The repo(s) may be perfectly landed; that is a different question. Unmet gates mean the
WORK is not finished, and a handoff written now would hand over a half-done slice with a
confident report attached. Finish the slice, or mark the gate ABANDONED with its handoff
note (an honest state) -- then re-run.
```

This is quoted, not paraphrased, per the coordinator's instruction. The gate
tool's own framing distinguishes "landed" from "gates met" — the paragraphs
below report what is actually landed and pushed, and separately do not claim
the `.unlazy/575-closeout` acceptance ledgers (leaf-s1s2, s3, s5, s6, s7) are
satisfied; whoever owns that ledger needs to either close those gates or mark
them ABANDONED with its own handoff note. This handover does not attempt to
resolve them.

## Landed (on `feat/575-exact-reml-gradient`, PR #579)

Commit chain (`git log --oneline origin/main..HEAD`, run in this worktree):

```
6fdab5ea docs(dev-log): #575 after-task report and check-log row (Definition of Done 5–6)
1058b39b docs(reml): drop an unresolvable @ref from the reml_nll_exact docstring (#575)
cda42b8c docs(reml): surface the exact-gradient entry points and the derivation note (#575)
c1773e21 chore(reml): wire the #575 tests, correct the fixture tolerance note (#575)
35201b00 test(reml): #575 target test passes on the cold-start public route
f5f8a600 fix(reml): certify q4 REML convergence on the exact gradient (#575)
12f758ec feat(reml): exact O(p) gradient of the q4 REML objective (#575)
7a05a7ca test(reml): RED — exact q4 REML gradient vs tight central difference (#575)
11e13860 docs(reml): derivation note for the exact q4 REML gradient (#575)
```

- **Exact q4 REML gradient** (`11e13860`→`c1773e21`): derivation note
  (`docs/src/developer-notes/reml-q4-exact-gradient.md`), RED→GREEN exact
  O(p) gradient (`reml_nll_exact`, `reml_nll_and_exact_grad`,
  `_reml_joint_newton` in `src/reml_q4.jl`), certification + wiring into
  `fit_q4_reml`'s `fg!`, target test flipped from `@test_broken` to `@test`,
  Rose D-43 remediations (test wiring into `test/runtests.jl`, fixture
  tolerance-note correction). Full detail, numbers, and citations:
  `docs/dev-log/after-task/2026-09-02-575-exact-reml-gradient.md`.
- **Docs wiring** (`cda42b8c`): fixed PR #579's Documenter `:missing_docs`
  CI failure by adding an `## 4. API` `@docs` block to the derivation note,
  a nav entry in `docs/make.jl`, and a `reml_q4.jl` row in
  `docs/src/developer-notes/source-map.md`.
- **Docstring `@ref` fix** (`1058b39b`): dropped an unresolvable `@ref` from
  the `reml_nll_exact` docstring.
- **Definition-of-Done ledgers** (`6fdab5ea`): the after-task report and
  check-log row for #575
  (`docs/dev-log/after-task/2026-09-02-575-exact-reml-gradient.md`,
  `docs/dev-log/check-log.d/2026-09-02-575-exact-reml-gradient.md`).
- Local Documenter build reported green (0 `missing_docs`, 0 errors) as of
  `cda42b8c`/`1058b39b`. **CI's own docs check on `6fdab5ea` was not yet
  resolved when this handover was written** — `gh pr view 579
  --json isDraft,state,statusCheckRollup` (run in this worktree) shows PR
  #579 as **`isDraft: true`, `state: OPEN`**, with `test (1)`, `test (1.10)`,
  and `docs` all `IN_PROGRESS` (`scaling-sweep` `SKIPPED`) on commit
  `6fdab5ea` at report time — treat as pending, not pass, until re-checked.
- `git status --porcelain` is clean and `git log --oneline
  origin/feat/575-exact-reml-gradient..HEAD` is empty: everything above is
  pushed, nothing local is ahead of the remote branch.

## OWED next (in order)

1. **Maintainer merge of PR #579** (src/ engine change, per `AGENTS.md`) —
   closes #575 on merge. PR is currently a **draft**; it will need to be
   marked ready for review (or a maintainer review requested directly) once
   CI on `6fdab5ea` resolves green.
2. **`rtol_coef` re-derivation** on
   `test/parity/q4-reml/biv-q4-phylo-reml/expected.toml [tol]`, but only
   **after** the drmTMB lane's Wald-SE receipt exists at
   `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.md`
   on drmTMB branch `claude/rev-parity-q4-se-receipt` (that receipt pins
   DRM.jl at `cda42b8c`). Do not re-derive the tolerance ahead of that
   receipt landing.
3. **#577** (ML-path `prior_precision` structural-zero degeneracy) and
   **#578** (`_reml_border_blocks` missing-response mask consistency,
   untested) stay **OPEN** — neither is fixed by this slice.

## Known residue (deliberate)

- **SE/interval axis was NOT re-measured** for #575; `interval_status` is
  unchanged. Full detail: `docs/dev-log/after-task/2026-09-02-575-exact-reml-gradient.md`
  §10.
- **#575's receipts live on drmTMB branch `codex/rebase-julia-optimizer-controls`
  (PR #1112, lands first per Shinichi 2026-09-02)**, not on drmTMB main.
- **The local `main` checkout of DRM.jl is 89 commits behind `origin/main`.**
  Read files against the remote tip with `git show origin/main:<path>`, and
  do work in a worktree rather than the stale local checkout.
- **The codex parity lane (#563) continues the remaining DRM.jl parity
  slices** (Shinichi, 2026-09-02) — #575 is one slice of that lane, not its
  close-out.

## CARRIED-OVER

| branch | head | why not landed | resume command |
|---|---|---|---|
| `feat/575-exact-reml-gradient` | `6fdab5ea` | PR #579 is a **draft**, `OPEN`, awaiting maintainer review/merge (src/ engine change, per `AGENTS.md`); CI (`test (1)`, `test (1.10)`, `docs`) was `IN_PROGRESS` on this commit at report time, not yet confirmed green | `gh pr checks 579` to re-check CI; `gh pr ready 579` once green and reviewable; `gh pr view 579` for current state |

Nothing else is carried over: `git status` is clean and nothing is unpushed
(both confirmed above).

## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-02-claude-handover-575-fixed.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
