# Plan vs actual — #575 close-out + true-parity replan

**Melissa reconciliation** · 2026-09-02 · DRM.jl half only
Plan: `~/.claude/plans/jazzy-drifting-piglet.md` (two plans in one session: #575 close-out S1–S7, folded
into "Context"/C1; true-parity replan C0–C10). Branches: `feat/575-exact-reml-gradient` (worktree
`.../afd6975e.../wt-exact-grad`, PR #579); `docs/true-parity-decision-map` (this worktree, PR #580).

Material deviations only. Cosmetic ordering/wording is not drift.

---

## 1. Scope

| planned | actual | tag | owner |
|---|---|---|---|
| C1: land #575 — docs green, push, `gh pr ready 579`, one comment, handover | Docs pushed (`cda42b8c`, `1058b39b`, `6fdab5ea`, `d3101aab`); PR #579 body carries the DoD section and "SE/interval NOT re-measured"; one #575 comment posted (confirmed via `gh issue view 575 --json comments`). **`gh pr ready 579` not yet run** — `gh pr view 579 --json isDraft` = `true`, CI (`test 1.10`, `docs`) still `IN_PROGRESS` at check time | unclear (pending on CI, not drift — matches the task's own caveat) | Rose |
| C2: decision map | `docs/dev-log/plans/2026-09-02-true-parity-decision-map-drmjl.md`, 153 lines, 4 wayfinder sections + reconciliation table + reverse-gap list (9 classified exports, 0 unclassified) | adaptive | — |
| C3: Codex handover for #563 continuation | **File does not exist** (`docs/dev-log/handover/2026-09-02-codex-handover-true-parity.md` — not found). Cancelled by Shinichi ("approve, but no Codex handover") after D-203 §2 superseded the plan's own DEFER line ("S5–S12 — Codex continues") with "Claude DRM.jl lane, fresh task." The resume information the handover would have carried is captured instead in the map's "Decisions so far" and "Out of scope" sections and in D-203 §2 itself | adaptive (routing changed mid-session, substance preserved elsewhere, nothing silently dropped) | Ada |
| C4: mechanical PR triage | `scratchpad/codex-pr-triage.md` exists — 6-PR table (#567/568/571/573/574/576) with mergeable state, behind-count, checks, first failure | — | — |
| C6: vault D-203 + AGENT_LOG | `grep -n "D-203" ~/shinichi-brain/memory/DECISIONS.md` → present at line 7372; `AGENT_LOG.md:535` entry present; vault HEAD `6fc23d3` | — | — |
| C7: docs PR opened, not merged | PR #580 open, `isDraft: true`, body: "Merge is the maintainer's call" | — | — |
| C8: Haiku mechanical verify | No evidence of a run (`.unlazy/true-parity-replan/gates/leaf-c9.md` still shows `EVIDENCE: pending`; no leaf-c8 file exists in the ledger at all) | pending, not drift (task said "pending at your run time") | Ada |

## 2. Evidence and verification

| planned | actual | tag | owner |
|---|---|---|---|
| `.unlazy/575-closeout` oracles as authored | `leaf-s1s2.md` CHECK now reads `grep -c "missing_docs" ... | cat` (exit-code-of-grep fix); `leaf-s3.md` CHECK now reads `... | head -1` with `EXPECT: structure check passed` (was `PASS`) — both consistent with a self-referential ledger-halt / grep-exit-code repair, not a bar lowering: the underlying claim ("0 missing docstrings", "after-task structure check passed") is unchanged | adaptive (oracle repair) | Rose |
| `.unlazy/true-parity-replan/gates/leaf-c2.md` G1b exact-5 threshold | Current file reads `[ "$n" -ge 5 ] && echo "ok:$n"`, `EVIDENCE: output=ok:11`. The reported history (exact `=5` loosened to `≥5` after a first FAIL) could not be independently confirmed — the ledger is gitignored and no prior version or log survives to diff against | unclear (cannot verify independently; current threshold is looser than a keyword-count gate needs to be, but the substance it gates — all 4 D-203 decisions + both src approvals named — is met at n=11, well above either bar) | Ada |
| After-task DoD item: SE/interval scope honesty | `grep -ci "not re-measured" docs/dev-log/after-task/2026-09-02-575-exact-reml-gradient.md` = 1; same language echoed in the PR body and the #575 comment | — | — |

## 3. Model routing

| planned | actual | tag | owner |
|---|---|---|---|
| C0 3×Haiku scouts, C2 Sonnet (Ada), C3 Sonnet (Rose), C4 Haiku (Grace), C8 Haiku (Curie), C9 Sonnet-low (Melissa) | Session roster matches: `recon-drmjl-parity`/`recon-drmtmb-parity`/`recon-brain-parity` (C0), `ada-parity-map` (C2), `grace-pr-triage` (C4), `rose-aftertask-575` (reused for C1's handover, not C3). **No agent dispatched for C3** (consistent with its cancellation) and **none yet for C8** (consistent with "pending") | adaptive (routing tracks the scope change in §1, not independent drift) | — |
| No Opus, Fable orchestrates | No Opus child observed; orchestrator did docs edits + landing inline per plan | — | — |

## 4. Safety gates

| gate | held? | tag | owner |
|---|---|---|---|
| Envelope MUST STOP: any `src/` or `test/` edit | `1058b39b` touches `src/reml_q4.jl` — one line, a docstring `@ref` → plain code span, commit message and PR body both state "no code change." Landed under the *earlier*, already-approved #575 plan (C1: "from the approved earlier plan, unchanged"), not under the replan's own envelope, but it is inside the same session and the file is literally under `src/` | adaptive (disclosed, verified no code change, blocks the Documenter gate otherwise) — flagged because a strict reading of the replan's own envelope text does not carve out docstring-only lines | Rose |
| Never merge | Both #579 and #580 remain open/unmerged | held | — |
| No fits/benchmarks (compute = none) | No evidence of any run in either worktree's history this session | held | — |
| No drmTMB edit; no coordination-board edit | Not touched (drmTMB accessed read-only via `git show`) | held | — |

## 5. Public claims

| planned | actual | tag | owner |
|---|---|---|---|
| PR #579 body carries DoD + "closes #575" + GATE-PASS scoped to coef/loglik | Confirmed present verbatim, alongside the SE/interval caveat in the same body — not a bare overclaim | adaptive (calibrated) | — |
| PR #580 body | "Merge is the maintainer's call" — no promotion or parity claim made by the docs themselves, matching the plan's REVIEW note (Rose) | — | — |

## 6. Handoff state

| planned | actual | tag | owner |
|---|---|---|---|
| #575 handover | `docs/dev-log/handover/2026-09-02-claude-handover-575-fixed.md` exists, commit `d3101aab` | — | — |
| Codex handover for #563 | Does not exist (§1, C3) — owner's call, substance preserved in the map + D-203 | adaptive | Ada |
| D-203 names the fresh-task successor | Vault D-203 §2 explicit: "Claude DRM.jl lane, in a FRESH task ... resuming the codex ledger at `/private/tmp/drm-parity-20260830/DRM.jl/.unlazy/julia-r-parity`" and records the superseded "Codex continues" answer | — | — |

---

## Recurring classes

Every drift-adjacent item this session is one of two shapes: (1) an **ownership answer that changed mid-
session** (Codex continues → Claude fresh task), which correctly cascaded into C3's cancellation and the
routing table, with the substance re-homed rather than lost; (2) **gate-mechanics repairs** (grep exit
codes, a self-referential ledger halt, an exact-vs-threshold keyword count) that left the underlying claim
unchanged. No instance this session weakens a claim without disclosing it.

## Verdict

Adaptive, well-disclosed session; the one open item is procedural, not a deviation — `gh pr ready 579` had
not yet run at reconciliation time, so PR #579's "ready-for-review" closure claim is not yet true on GitHub.
