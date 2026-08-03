---
name: drmTMB p scaling
overview: Open a GitHub issue, then measure paired drmTMB vs DRM.jl wall-clock on the q=4 PLSM nrep=4 model at p∈{100,1000,5000,10000} on Totoro, replace extrapolated “~12×” language with retained measured evidence, and stop at G0 for /goal execution.
todos:
  - id: s0-open-issue
    content: Open GitHub issue for measured q4 nrep=4 / p>100 drmTMB head-to-head (from e3b3b8a)
    status: pending
  - id: s1-harness
    content: "Build paired Julia+R harness (reuse run_scaling.jl generator; public drmTMB API; #372 timer protocol)"
    status: pending
  - id: s2-smoke
    content: "Local smoke at p=100: non-empty paired artifact + logLik sanity"
    status: pending
  - id: s3-totoro
    content: Totoro full grid p∈{100,1000,5000,10000}; retain evidence JSON/md
    status: pending
  - id: s4-docs
    content: Rewrite comparison-grid/HANDOVER/large-data/ROADMAP from measured artifact only
    status: pending
  - id: s5-dod-pr
    content: DoD (check-log.d, after-task, Rose) + PR closes issue
    status: pending
  - id: verify-reconcile
    content: Mechanical verify + Rose claim gate + Melissa plan-vs-actual
    status: pending
isProject: false
---

# G0: Measured drmTMB head-to-head (nrep=4 / p>100)

```
GOAL (paste-ready for a fresh /goal session)
PLATFORM: Cursor (planning chat stops at G0; execution via /goal — live R+Julia
  compute on Totoro per D-50; Codex may own the Totoro lane when /goal routes it)
DELIVERABLE: Open issue + merged PR that (1) adds a paired Julia/R harness for the
  q=4 PLSM biological per-dim-variance model at nrep=4, p∈{100,1000,5000,10000},
  (2) retains measured wall-clock (+ logLik sanity) for both arms or honest
  R-blocked cells, (3) rewrites comparison-grid / HANDOVER / large-data / ROADMAP
  so “~12× extrapolated” is retired only where measured.
HEADLINE: Kill the extrapolated drmTMB@p=10k claim with a retained paired artifact.
IN PARALLEL: issue scaffold + harness skeleton (Julia reuse run_scaling.jl generator;
  R public-API arm) while Totoro smoke is prepared.
DEFER: Registrator/D-111; GPL vendoring; src/ q4 core edits; #372 six-cell ratios as
  q4 evidence; threaded-bootstrap claims; CI heavy drmTMB sweeps; touching .worktrees/.
DISCIPLINE: smoke-first non-empty paired output → scale only after green;
  verify-before-claim; Rose claim-vs-evidence on every public sentence; leave
  .worktrees/ alone; no q4 regression of logLik −256.51 / 2.18× baseline.
```

## Context

- Tip idle: `origin/main` @ **`e3b3b8a`** after #370+#372+#375. Dirty only `?? .worktrees/`.
- #372 measured *bridge fixture* timings — **different estimand**; must not substitute.
- Gap lives in [ROADMAP.md](ROADMAP.md) L130, [HANDOVER.md](HANDOVER.md) “Do NOT oversell”, [report/comparison-grid.md](report/comparison-grid.md) §3, [docs/src/model-guides/large-data.md](docs/src/model-guides/large-data.md).
- Julia O(p) arm already exists: [bench/run_scaling.jl](bench/run_scaling.jl). drmTMB arm at same nrep=4 / p>100 does **not**.
- Recon: [DRM head-to-head recon](a92691f5-e543-4ced-ac69-8d7a1c19519d) → **build fresh**, no resume branch.

## Sweep receipt (Phase 0.25)

| Surface | Evidence | Finding | Call |
|---|---|---|---|
| repo git | `git status -sb`; `branch_drift_check.sh`; HEAD=`e3b3b8a` | tip idle; `.worktrees/` only | build-the-gap |
| twin | drmTMB `bench/large-phylo-location.R` | different estimand (location / large rows) | co-opt smoke→scale protocol only |
| brain | `search_notes` + greps `extrapolat\|nrep\|p>100\|head-to-head\|comparison-grid` on AGENT_LOG/DECISIONS/journal/deep-research | D-111 registry fence; D-50 Totoro/DRAC; gap still open | build measured gap |
| Verdict | — | reuse #372 Rose timing protocol; new issue + paired harness | **reuse protocol / build gap** |

## Locked decisions (Phase 0.4 defaults — “use your judgment”)

| Decision | Lock |
|---|---|
| Compute | **Totoro** for retained grid (p≥1000); local laptop for harness smoke only |
| Grid | **p ∈ {100, 1000, 5000, 10000}**, nrep=4, balanced tree, same Λ model as `run_scaling.jl` |
| Model | q=4 PLSM biological per-dimension-variance (not #372 bridge cells; not Poisson phylo) |
| R version | Record installed drmTMB version honestly (prefer pin awareness; do not pretend 0.1.3 if timing is 0.6.x) |
| R-blocked cells | Allowed — per-cell “R failed/timeout — no claim”; never invent ratios |
| Engine | **No `src/` q4 core edits** unless a harness-only bug forces a tiny fix (then Noether + maintainer) |
| Registry | **D-111 OFF** |
| Worktrees | Leave `.worktrees/` alone / never stage |

## Approach

```mermaid
flowchart LR
  openIssue[Open_GitHub_issue] --> harness[Paired_harness_Julia_plus_R]
  harness --> smoke[Local_smoke_p100]
  smoke --> totoro[Totoro_full_grid]
  totoro --> evidence[Retained_evidence_JSON_plus_md]
  evidence --> docs[Rewrite_claim_surfaces]
  docs --> rose[Rose_audit_DoD_PR]
```

1. **Open issue** from idle tip (template mirrors #372 G0): measured paired wall-clock; closes via PR; fences listed above.
2. **Harness** (bench-only):
   - Julia: reuse generator/fit path from [bench/run_scaling.jl](bench/run_scaling.jl) (or thin wrapper `bench/head_to_head_q4_scaling.jl`).
   - R: new `bench/R/head_to_head_q4_scaling.R` calling **public** drmTMB API on exported fixtures (CSV + Newick) — **no GPL source vendored**.
   - Protocol (from #372): BLAS/OMP=1; 1 warmup + N timed reps; median/min/max; machine/versions; JSON/TOML + `docs/dev-log/evidence/YYYY-MM-DD-<issue>-q4-scaling-h2h.md`.
3. **Smoke** local at p=100: both arms non-empty, logLik sane, timer fields present.
4. **Totoro** full grid; abort/scale-down only after documented R failure (honest cell).
5. **Docs rewrite** only from artifact: [report/comparison-grid.md](report/comparison-grid.md) §3/§7, [HANDOVER.md](HANDOVER.md), [docs/src/model-guides/large-data.md](docs/src/model-guides/large-data.md), ROADMAP open-research bullet → done/partial, [docs/src/r-julia-bridge.md](docs/src/r-julia-bridge.md) cross-link if needed. Keep **2.18× p=100 real-data** cell distinct from synthetic nrep=4 scaling ratios.
6. **DoD**: tests if any harness helpers are package-visible; check-log.d; after-task; Rose claim-vs-evidence; PR `closes #NN`.

## Slice table

| Slice | Member | Model+effort | Bar | Time | Detail | Dep |
|---|---|---|---|---|---|---|
| RECON (done) | Ada/scout | Composer/Grok low | Cursor Models | done | tip + gap map | — |
| S0 Open issue | Ada | Composer med | Cursor Models | ~10m | `gh issue create` from G0 body | — |
| S1 Harness Julia+R | Curie | Terra/Sonnet med | Other Models or Codex | ~1–2h | fixtures export + timers; public R API | S0 |
| S2 Local smoke p=100 | Curie | Terra med | Codex | ~20m | non-empty paired artifact | S1 |
| S3 Totoro full grid | Curie | Terra/Codex high | hand off Codex+Totoro | ~2–6h wall | p∈{100,1k,5k,10k}; retain JSON | S2 |
| S4 Docs rewrite | Pat/Rose | Sonnet med | Other Models | ~45m | comparison-grid, HANDOVER, large-data, ROADMAP | S3 |
| S5 DoD + PR | Grace/Ada | Composer med | Cursor Models | ~30m | check-log.d, after-task, PR | S4 |
| MECHANICAL-VERIFY | Scout | Grok/Composer low | Cursor Models | ~15m | artifact non-empty; links; no GPL paths staged | S5 |
| VERIFY Rose | Rose | Claude/Opus or Auto high | Other Models | ~20m | claim-vs-evidence; fences | S5 |
| RECONCILE Melissa | Melissa | Sonnet med | Other Models | ~15m | plan-vs-actual → `docs/dev-log/plan-actual/` | close |

**Fan-out budget:** checkpoint=`drm-h2h-p-scaling` · children ≤6 · scout=1 · build=3–4 · ceiling=0–1 (Rose only if claim gate) · LUNA/scout suitability: **yes** (RECON + MECHANICAL-VERIFY).

**Estimate:** ~half-day harness+smoke; Totoro wall-clock dominates (drmTMB at p=10k unknown — may timeout → honest cell). Fits one `/goal` session with Totoro handoff; not one planning chat.

**Members plan-review (pre-exec):** Rose confirms sweep receipt non-vacuous + claim fence; Noether confirms no `src/` regression path.

## Fences (hard)

- **D-111** — no Registrator / Julia General
- **No GPL** — fixtures + public drmTMB API only
- **No q4 regression** — do not change verified engine; keep −256.51 / 2.18×
- **Leave `.worktrees/` alone**
- **No GHA** for the heavy grid (D-50)
- Do not promote #372 bridge ratios as q4 scaling

## Search / grounded NotebookLM

Not required for this measurement arc (internal harness + clock). Offer declined by default.

## After G0 — paste-ready `/goal`

```
/goal Measured drmTMB head-to-head nrep=4 p∈{100,1000,5000,10000}

PLATFORM: Cursor /goal (Totoro compute lane: Codex if needed)
BASE: origin/main @ e3b3b8a
ISSUE: <fill after S0>
BRANCH: feat/<issue>-q4-scaling-h2h

GOAL: Retained paired Julia vs drmTMB wall-clock on q=4 PLSM biological
per-dim-variance model (nrep=4). Replace extrapolated ~12× language only
where measured. Honest R-blocked cells OK.

ARCS:
0 — Open/confirm issue; branch from e3b3b8a; leave .worktrees/ alone
1 — Harness (reuse run_scaling.jl generator; R public API; #372 timer protocol)
2 — Local smoke p=100 (non-empty JSON + logLik sanity)
3 — Totoro full grid; write docs/dev-log/evidence/…-q4-scaling-h2h.md
4 — Rewrite comparison-grid §3, HANDOVER, large-data note, ROADMAP bullet
5 — DoD (check-log.d, after-task, Rose) + PR closes #<issue>

FENCES: D-111; no GPL; no src/ q4 core regression; no GHA heavy runs;
leave .worktrees/; never cite #372 six-cell ratios as this evidence.

VERIFY: smoke non-empty before Totoro; Rose claim-vs-evidence before merge;
Pkg.test only if package surface touched (prefer bench-only).

STOP at L2: irreversible publish/tag/registry; unexpected src/ engine edit need.
```

## STOP

**This planning chat ends at G0 approval.** Do not start Phase 3 here. After you approve, run the `/goal` block above in a fresh execution chat.
