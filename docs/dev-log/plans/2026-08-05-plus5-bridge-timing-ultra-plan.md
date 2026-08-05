# Tip → +5 bridge timing — ultra-plan (STOP at G0)

Shannon · Ada · Curie · Rose · Hopper. Platform = **Cursor** (this chat).
Plan mode unavailable — Phases 0–2 read-only; no Phase 3 until G0 + `/goal`.

---

## GOAL (paste-ready — first)

```
SOLO PLATFORM: Cursor (this chat may /goal after G0; not Codex by default).

DELIVERABLE: Measure warm wall-clock for the five admitted-but-untimed
bridge cells — count-poisson, positive-gamma, binomial-trials,
positive-lognormal, nbinom2-dispersion — via reuse of the #372 harness
(Julia drm_bridge vs local drmTMB). Retain evidence artifact + update
docs/src/r-julia-bridge.md claim surface from that artifact only.
Open issue + PR (closes #NN).

HEADLINE: Bridge docs still say “no timing claim” for +4 FE / nbinom2-
dispersion while coef parity is already green — close the Rose no-claim
gap with the same protocol as #372.

IN PARALLEL (cheap): Arc-0 one-cell smoke (Julia + R) on count-poisson;
confirm local drmTMB version (expect 0.6.0).

DEFER / FENCE: re-time original six (#372 artifact stands); fixture 0.6.0
refresh of v0.1.3 six; q4 2.18× / #376; #202/#49; Lovelace R edits;
D-111 Registrator; src/ engine; inventing general “Nx faster”; .worktrees/;
tip-idle SHA-churn.

DISCIPLINE: verify tip @ a956dbd (or newer); reuse #372 protocol
(1 warmup + 5 timed; BLAS/OMP=1; median R/J); record machine + versions;
honest block per cell if R fails — never invent timings; Rose scoped
ratios only; ML default; closure = evidence + docs + check-log.d +
after-task + Rose + PR.
```

---

## Arc Card (from /arc-creation)

**Mode:** size · **Recommended:** 60–90 min · **Confidence:** measured
(analogue #372 six-cell timing).

**State transition:** five cells timing no-claim → retained measured artifact
(or honest per-cell block) + docs claim surface updated.

**Outcome:** PR merges measured +5 evidence; bridge docs no longer say
no-claim for those five.

**Mechanism authority:** extend existing `bench/bridge_six_cell_timing.{jl,R}`
(or sibling `bench/bridge_plus5_timing.*`); write evidence under
`docs/dev-log/evidence/`; update `docs/src/r-julia-bridge.md` from artifact
only. No `src/` unless a Dual/fit bug blocks a cell (then STOP / new G0).

---

## Phase 0.25 — Sweep receipt (gate)

| Surface | Evidence run | Finding | Call |
|---|---|---|---|
| **repo git** | `git log -1 origin/main`; status | tip **`a956dbd`** (#387 tip-idle MERGED); `?? .worktrees/` only | **new branch** from main; leave `.worktrees/` |
| **#372 harness** | `bench/bridge_six_cell_timing.jl` + `.R`; evidence `…-372-six-cell-timing.md` | Protocol + Rose fence ready; COHORT hardcoded to six; R `fit_cell` lacks +5 | **reuse / extend** — do not rebuild |
| **fixtures** | `test/parity/fixtures/{count-poisson,…}` | All five present; formulas/families known; drmTMB **0.6.0** numbers | **reuse** |
| **docs gap** | `docs/src/r-julia-bridge.md` L28–35 | Explicit no-claim for +4 FE + nbinom2-dispersion | **build** measurement + claim update |
| **brain / logs** | MCP + `DECISIONS` D-111; AGENT_LOG grep timing | D-111 OFF; #372 pattern is the twin | **reuse** fence; **build** +5 gap |
| **local R** | `packageVersion("drmTMB")` | **0.6.0** | Record on R arm (same as #372) |
| **Verdict** | — | Genuine gap = +5 cells only | **reuse #372 / build +5 evidence** |

---

## WHAT THE BRAIN ALREADY KNOWS

- #372 protocol + Rose fence (scoped ratios; not general Nx; not q4 2.18×).
- D-111 OFF; never vendor GPL; `.worktrees/` protected.
- Tip IDLE after #387; owner named G0 **1** = this timing slice.

## WHAT SHINICHI TOLD US

- Pick credible G0 **1**: time +4 FE / `nbinom2-dispersion`.
- May run this G0 in **this** chat (after tip-idle goal closed).

## ADA'S RECOMMENDATION

Approve. Smallest useful ship: extend #372 harness to five cells; one issue →
one PR. Do not remeasure the original six unless a harness bug forces it.

## DECISIONS LOCKED (pending your G0)

- Cohort = exactly those five (not xfam; not re-time six).
- Protocol = #372 identical (warmup+5; threads=1; median).
- Prefer extend existing bench scripts with `DRM_372_CELLS` / new default cohort
  flag, or sibling `bridge_plus5_*` — execution picks smallest diff.
- R constructors from `gen_fixtures.R` public API shapes only.
- Docs claim update only from retained artifact.

## QUESTIONS STILL OPEN

None load-bearing. Reply **`G0 APPROVED`** or adjust.

---

## ARC PROGRAM

Size · 60–90 min · Arc 0 probe → Arc 1 measure both arms → Arc 2 evidence+docs
→ Closeout PR.

## SLICE TABLE

| Slice | Member | Bar | Time | Detail | Dep |
|---|---|---|---|---|---|
| Arc0 | Curie | Cursor Models | 10m | Issue #NN; branch; smoke one cell J+R | — |
| Rung1 | Curie | Cursor Models | 25m | Extend harness R `fit_cell` + cohort; run J+R all five | Arc0 |
| Rung2 | Ada/Pat | Cursor Models | 20m | Evidence md + TOML/JSON twins; update r-julia-bridge.md | Rung1 |
| Closeout | Grace/Rose | Cursor Models | 15m | check-log.d + after-task + Rose + PR closes #NN | Rung2 |

**LUNA SUITABILITY:** yes for harness extend. **ULTRA EFFORT:** no.  
**FAN-OUT:** ≤2. **RECONCILE:** light Melissa optional.

## ESTIMATE

~60–90 min · 1 session · fits `/goal` here after G0.

## VERIFY

1. Evidence file lists all five cells with median_s both arms (or honest FAIL).
2. `r-julia-bridge.md` no longer says no-claim for those five; scoped only.
3. No `src/` unless STOP'd with owner.
4. `.worktrees/` unstaged; D-111 OFF.
5. Ratios ≠ claimed as general Nx; ≠ q4 2.18×.

## STOP at G0

**Approve?** Reply `G0 APPROVED`. Then in this chat (or fresh):

```text
/goal

Ultra-plan G0 approved. +5 bridge timing (reuse #372).
REPO: /Users/z3437171/Dropbox/Github Local/DRM.jl
PLAN: docs/dev-log/plans/2026-08-05-plus5-bridge-timing-ultra-plan.md
Tip origin/main @ a956dbd. Cohort: count-poisson, positive-gamma,
binomial-trials, positive-lognormal, nbinom2-dispersion.
Fences: D-111; .worktrees/; no invent timings; no src/ unless STOP;
do not re-time original six.
```
