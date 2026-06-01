# Review-thread & backlog status

*Generated 2026-06-01 from the live GitHub API (`itchyshin/DRM.jl`), not from
chat memory. Authoritative as of `main` @ `2ffa44a`.*

> Note on provenance: an earlier pass in this session assumed a pre-existing
> scaffold report and reported "0 PRs / 0 issues" — both were wrong (the GitHub
> tools had not actually run). This file supersedes that. Everything below is a
> real API read.

---

## TL;DR

- **Open review threads: 0.** The only open PR (#83) has no reviews, no review
  comments, and no conversation comments. Nothing is waiting on a reply.
- **Open PRs: 1** — #83, **mergeable (`clean`)**, CI green. Ready to merge on the
  maintainer's say-so.
- **Open issues: 21** — a clean, well-labelled roadmap backlog (no stale review
  debt hiding in them).

---

## Open pull requests (1)

| PR | Title | Author | Draft | Threads | CI | Mergeable |
|---|---|---|---|---|---|---|
| **#83** | AIC / BIC / dof: information criteria for model selection | itchyshin (OWNER) | no | **0** | ✅ `documenter/deploy` success | **clean** |

Details:
- Branch `feat-aic-bic` → `main`; +52 / −2 across 6 files, 3 commits.
- Adds `dof` / `aic` / `bic` on the StatsAPI generics; exported; works per family.
- Verification claimed in the PR body: `test/test_aic_bic.jl` 7/7; merged current
  `main` (incl. #82) cleanly.
- **No open review threads.** `mergeable_state = clean`. **Flagged mergeable** —
  not merged (owner's PR; awaiting explicit go-ahead).

## Open review threads (0)

Across all open PRs there are **zero** review threads (resolved or unresolved),
zero reviews, and zero PR comments. There is no review backlog to triage.

---

## Open issues (21) — grouped

**Roadmap / phase epics**
- #3 Phase 1.0 — Hygiene + wire `experimental/`
- #4 Phase 1.1 — `bf()` front end + R parity
- #5 Phase 1.5 — R-side `engine="julia"`
- #6 Phase 2 — Family expansion
- #7 Phase 3 — Articles to mirror drmTMB
- #8 v0.1.0 release gate · #9 v1.0 (full twin)

**Wire `src/experimental/` into the public API (Phase 1.0)**
- #10 `infer_q4.jl` (Wald + bootstrap)
- #11 `reml_q4.jl` (Laplace-REML; ML stays default)
- #12 `location_only.jl` (conjugate EM)
- #13 `fit_em_natgrad.jl` (natural-gradient EM)

**Q-gates (engine quality)**
- #14 FD-vs-exact gradient ≤ 1e-6
- #15 Allocs.jl zero-alloc inner mode-finder loop
- #16 multi-shape sweep (balanced + caterpillar, p ∈ {100, 1k, 10k})
- #17 R-parity vs vendored drmTMB v0.1.3 outputs

**Engine core / new algorithms (Codex lane)**
- #76 Codex lane brief (fast estimators + new algorithms)
- #80 Extend crossed/structured RE Laplace (more families, structured effects, exact gradient)
- #49 Missing-data: FIML / EM

**Post-fit & bridge**
- #73 `ranef()` per-level conditional estimates (BLUPs)
- #19 phylo-tree + R-object marshalling

**Docs / parity**
- #1 Reconcile `meta_V()` / `meta_known_V()` wording (has 1 comment)

---

## What we can do from here

1. **Merge #83** when ready — it is clean, CI-green, and has no open threads.
   (Left to the maintainer; not auto-merged.)
2. **No new issues needed for the recent action items.** The work surfaced by
   `report/comparison-grid.md`'s "needs human review" list is *already tracked*:
   REML scale-axis / exact gradient → #11; inference + threaded bootstrap → #10;
   FD-gradient gate → #14; scaling sweep → #16; R-parity/license → #17; meta_V
   wording → #1. Filing more would duplicate the ledger.
3. **Next on the critical path** is Phase 1.0 (#3): wire `experimental/` (#10–#13)
   and stand up the Q-gates (#14–#17). #80 is the active engine-lane algorithm.

*Source: GitHub API reads on 2026-06-01. Re-run before relying on these counts.*
