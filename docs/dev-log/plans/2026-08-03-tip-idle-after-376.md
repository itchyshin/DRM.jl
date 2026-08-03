---
name: Tip idle after 376
overview: "Docs-only tip-idle hygiene after #376/#377: refresh stale LOOP/, write a post-376 handover mirroring #375, open a docs PR only, stop at owner G0. No ship work, no .worktrees/, D-111 OFF."
todos:
  - id: s1-persist-plan
    content: Write docs/dev-log/plans/2026-08-03-tip-idle-after-376.md (blocked in Plan mode now)
    status: completed
  - id: s2-loop-refresh
    content: "Refresh LOOP/GOAL.md, checkpoint.md, arcs.md to tip idle after #376/#377"
    status: completed
  - id: s3-handover
    content: Write tip-idle handover after-376 from after-372 template
    status: completed
  - id: s4-docs-pr
    content: "Open docs PR docs/tip-idle-after-376 (pattern #375; no issue)"
    status: completed
  - id: verify-rose
    content: Mechanical verify + Rose scope (docs-only; D-111; no .worktrees/)
    status: completed
isProject: false
---

# Tip-idle after #376/#377 (ultra-plan → STOP at G0)

**Persisted:** this file is the durable copy of the approved tip-idle ultra-plan (G0 approved; executed via Cursor `/goal` on 2026-08-03).

---

## GOAL (paste-ready)

```
GOAL (tip-idle hygiene after #376/#377)
PLATFORM: Cursor (this planning chat STOPs at G0; execution later via /goal in Cursor — not Codex by default)
BASE: origin/main @ ae4e67d (feat(#376) squash via #377)
DELIVERABLE: Refresh stale LOOP/* + write post-376 tip-idle handover so tip is IDLE
  and next session waits for owner G0. Docs PR only (pattern #375). No ship work.
HEADLINE: LOOP/checkpoint still says “awaiting merge #377” while tip already has #376/#377 — fix ledger drift.
IN PARALLEL: none needed (tiny serial docs slice)
DEFER / FENCE: .worktrees/; D-111 Registrator/Julia General; src/ engine; inventing next twin G0;
  claim rewrites beyond pointing at already-merged #376 evidence; no new Totoro/compute.
DISCIPLINE: verify tip SHA + PR #377 merged before claiming IDLE; leave .worktrees/ unstaged;
  mirror handover template after-372; Rose scope = docs-only.
```

---

## Sweep receipt (Phase 0.25) — gate passed

| Surface | Evidence | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb` → `main...origin/main` + `?? .worktrees/` only; HEAD=`ae4e67d` = `origin/main`; `branch_drift_check.sh` → **0 ahead / 0 behind**; `git log` tip = `feat(#376)…(#377)` then `docs(loop): tip idle after #370+#372 (#375)` | Tip **ship-idle**; dirty only untracked `.worktrees/`; many stale local branches/worktrees (fence: leave alone) | **build-the-gap** = LOOP/handover refresh only |
| **LOOP/** | Read `LOOP/GOAL.md`, `checkpoint.md`, `arcs.md`, `ultra-plan.md` | All still describe **#376 in flight** (`STATE: PR #377 opened; awaiting merge`; arcs Arc 5 IN PROGRESS) | **Must refresh** (stale vs tip) |
| **template** | Read `docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle-after-372.md` | Pattern for tip-idle handover after twin landings; superseded prior idle note | **Reuse** as template for `…-after-376.md` |
| **prior pattern** | `git show e3b3b8a` (#375) | Docs PR touched `LOOP/{GOAL,arcs,checkpoint}.md` + new handover; message `docs(loop): tip idle after #370+#372` | **Resume pattern** — docs PR, no issue |
| **claims / extrapolation** | grep `~12×|extrapolat|p=10,000` on ROADMAP/HANDOVER/comparison-grid/LOOP | HANDOVER “Do NOT oversell” + ROADMAP open-research bullet already **retired/#376 done**; evidence file on tip; LOOP still talks as if gap open | **No claim rewrite needed** beyond LOOP idle + handover pointer to #376 evidence |
| **twin** | n/a for docs hygiene (drmTMB already measured via #376 public API) | Sister work done on tip | **n/a** |
| **brain** | MCP `search_notes` hybrid `DRM.jl tip idle after 376 OR … after 375` (`search_all_projects: true`) → older tip-idle / Phase 1.5 / #353 hits; **no post-376 tip-idle note yet**. Deterministic vault greps: `memory/DECISIONS.md` → **D-111 accepted**; `AGENT_LOG.md` → **no** `#376`/`tip idle` lines; `journal/` → DRM worktree noise; `projects/deep-research/README.md` → drmTMB arcs (not this hygiene) | D-111 fence live; tip-idle after 376 not yet logged | **reuse** D-111 + #375 pattern; **build** LOOP/handover gap |
| **Verdict** | — | Ship work done; ledger stale | **reuse #375 docs-PR pattern / build LOOP+handover gap** |

Phase 0.3b two-bar: **not read this session** (Settings → Usage). Route scout/docs on Cursor Models; Rose/judgment on Other Models if used. `AGENT-INFERRED` from 2026-08-01 MODEL-ROUTING row.

---

## Locked decisions

| Decision | Lock |
|---|---|
| Scope | **Docs-only** tip-idle hygiene |
| Issue | **No new GitHub issue** (recommend docs PR like #375) |
| Worktrees | Leave **`.worktrees/`** alone / never stage |
| Registry | **D-111 OFF** — no Registrator / Julia General |
| Engine | **No `src/` edits** |
| Claims | Do **not** rewrite measured ratios; only point at merged #376 evidence already on tip |
| Next ship | Do **not** invent next twin G0 |
| Platform | **Cursor** executes after G0 via `/goal` |

---

## Slice table

| Slice | Member | Model+effort | Bar | Time | Detail | Dep |
|---|---|---|---|---|---|---|
| RECON (done) | Ada | Composer low | Cursor Models | done | tip ae4e67d; LOOP stale; claims already retired | — |
| S1 Persist plan | Ada | Composer low | Cursor Models | ~2m | Write `docs/dev-log/plans/2026-08-03-tip-idle-after-376.md` (blocked in this Plan-mode chat) | — |
| S2 LOOP refresh | Ada/Pat | Composer med | Cursor Models | ~15m | `LOOP/GOAL.md` → DONE/IDLE; `checkpoint.md` tip idle; `arcs.md` all DONE; retire or archive #376 ultra-plan body to historical | S1 |
| S3 Handover | Shannon/Ada | Composer med | Cursor Models | ~15m | New `docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle-after-376.md` from after-372 template; supersedes after-372 as START HERE | S2 |
| S4 Docs PR | Grace/Ada | Composer med | Cursor Models | ~15m | Branch `docs/tip-idle-after-376`; PR title like `docs(loop): tip idle after #376+#377`; no `closes #NN` needed | S3 |
| MECHANICAL-VERIFY | Scout | Grok/Composer low | Cursor Models | ~10m | tip SHA; LOOP no “awaiting merge”; `.worktrees/` unstaged; no `src/` | S4 |
| VERIFY Rose | Rose | Auto/Claude med | Other Models | ~10m | scope honesty; no claim inflation; D-111 | S4 |
| RECONCILE | Melissa | — | — | — | **N/A** — tiny docs hygiene (record in after-task one-liner) | — |

**Estimate:** ~45–60 min wall; one `/goal` session; no compute.

**Members plan-review:** Rose — sweep receipt non-vacuous; docs-only fence. Ada — no issue needed.

---

## After G0 — paste-ready `/goal`

```
/goal DRM.jl tip-idle hygiene after #376/#377

PLATFORM: Cursor
BASE: origin/main @ ae4e67d
BRANCH: docs/tip-idle-after-376
PLAN: docs/dev-log/plans/2026-08-03-tip-idle-after-376.md  (write this file first if missing)

GOAL: Refresh LOOP/* to tip IDLE + write handover
  docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle-after-376.md
  (template: …-after-372.md). Open docs PR only (pattern #375). No ship work.

ARCS:
0 — Confirm tip ae4e67d / #377 merged; persist plan file if absent
1 — LOOP/GOAL + checkpoint + arcs → idle/DONE; point at #376 evidence
2 — New tip-idle handover; supersede after-372 as START HERE
3 — Docs PR; mechanical verify; short Rose scope pass

FENCES: leave .worktrees/; D-111 OFF; no src/; no inventing next twin G0;
  no claim changes beyond pointing at already-merged #376 evidence.

STOP at L2: do not merge without owner; do not open Registrator.
```

---

## STOP

**This planning chat ends at G0.** Do not execute LOOP edits, handover, branch, or PR here. Approve this plan, then paste the `/goal` block in a fresh Cursor execution chat.
