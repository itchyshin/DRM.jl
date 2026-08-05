# Refresh original six Workflow G fixtures → drmTMB 0.6.0 — ultra-plan (STOP at G0)

Shannon · Ada · Hopper · Rose. Platform = **Cursor**.
Phases 0–2 read-only; no Phase 3 until G0 approval + `/goal`.

---

## GOAL (paste-ready — first)

```
SOLO PLATFORM: Cursor (this planning chat STOPs at G0; execution via /goal
— this chat or fresh; not Codex by default).

DELIVERABLE: Regenerate the original six Workflow G parity fixtures
(gaussian-locscale, gaussian-bivariate-rho12, robust-student, count-nbinom2,
proportion-beta, meta-analysis-V) against local installed drmTMB **0.6.0**
via gen_fixtures.R (same seeds/DGPs). Re-verify DRM_PARITY_TESTS=1 native +
bridge (11 cells). Update GENERATING.md / parity README / r-julia-bridge.md
provenance language so the cohort is not split 0.1.3 vs 0.6.0. Open issue +
PR (closes #NN).

HEADLINE: Coef pins for the original six still say drmTMB v0.1.3 while +4 FE,
nbinom2-dispersion, and both timing arms already use 0.6.0 — close the twin
version split.

IN PARALLEL (cheap): merge desk gate for #390 if still OPEN when execution
starts; record packageVersion("drmTMB") exactly (expect 0.6.0).

DEFER / FENCE: re-time #372/#389; Lovelace R-side engine="julia"; #202/#49;
D-111 Registrator; src/ engine redesign; inventing new families; xfam;
nbinom2_locscale RE guard; tip-idle SHA-churn; .worktrees/; claiming a
drmTMB CRAN/tag status beyond recorded packageVersion.

DISCIPLINE: same seeds as gen_fixtures.R (do not redesign DGPs); MIT-clean
generated outputs only; soft [tol] only with measured Δ + Rose note; verify
native 11 + bridge 11/11; AGENTS.md parity-anchor wording needs maintainer
sign-off if changed (lane rule); ML default; closure = fixtures + docs +
check-log.d + after-task + Rose + PR.
```

---

## Arc Card (from /arc-creation)

**Mode:** size · **Recommended:** 90–150 min · **Confidence:** measured
(analogue #383/#385 fixture regen + #370 parity verify).

**State transition:** original six `expected.meta.toml` `drmtmb_version`
`"0.1.3"` → `"0.6.0"` with refreshed numbers; docs no longer claim a split pin.

**Outcome:** one issue → one PR; Workflow G numeric anchor unified at recorded
0.6.0 for all eleven admitted cells.

**Mechanism authority:** run `DRM_PARITY_ONLY=<six>` + `gen_fixtures.R`; commit
`data.csv` / `expected.toml` / `expected.meta.toml` only; update docs strings;
run `DRM_PARITY_TESTS=1`. No `src/` unless a Dual/fit bug appears (then STOP).

---

## Phase 0.25 — Sweep receipt (gate)

| Surface | Evidence run | Finding | Call |
|---|---|---|---|
| **repo git** | `origin/main` tip; #390 | tip **`a956dbd`**; #390 OPEN (docs+1.10 green; test(1) still in progress at plan write) | **Land or stack after #390**; do not reopen timing |
| **fixtures** | six `expected.meta.toml` | all six `drmtmb_version = "0.1.3"`, `generated_on = 2026-06-03` | **regen** |
| **+5 cohort** | count-poisson meta etc. | already `"0.6.0"` (#383/#385) | **leave alone** unless regen accidentally touches |
| **generator** | `gen_fixtures.R` + `DRM_PARITY_ONLY` | six generators present; filter works | **reuse** |
| **local R** | `packageVersion("drmTMB")` | **0.6.0** (matches +4 FE meta) | **record exactly** |
| **docs/AGENTS** | grep `0.1.3` | GENERATING/README/bridge/AGENTS still say v0.1.3 pin | **update docs**; **AGENTS.md = maintainer-gated** |
| **brain** | AGENT_LOG / D-111; MCP | D-111 OFF; twin timing/coef already on 0.6.0 for newer cells; note: drmTMB tag/CRAN narrative ≠ local Version — record packageVersion only | **reuse** license fence; **no tag claim** |
| **Verdict** | — | Genuine gap = six fixtures + provenance docs | **reuse generator / build regen gap** |

---

## WHAT THE BRAIN ALREADY KNOWS

- License: generated numbers only; never vendor GPL.
- D-111 OFF.
- #372/#389 timing used drmTMB 0.6.0 R arm against (partly) 0.1.3 coef fixtures —
  this arc fixes the coef pin split.
- AGENTS.md currently pins formula/parity narrative to v0.1.3; re-anchor is an
  explicit allowed operation (“on each tagged release”) — be honest if 0.6.0 is
  installed Version without asserting CRAN/tag status.

## WHAT SHINICHI TOLD US

- Next arc for R↔Julia parity = refresh original six → 0.6.0.
- Request: write ultra-plan and show it (STOP at G0).

## ADA'S RECOMMENDATION

Approve. Smallest useful parity honesty arc after #389/#390. Prefer merge #390
first so tip is clean, then branch from new main.

## DECISIONS LOCKED (pending your G0)

- Cohort = original six only (not re-regen +5 unless a shared bug forces it).
- Keep existing seeds/DGPs in `gen_fixtures.R`.
- Soft `[tol]` allowed only with measured Δ documented (nbinom2-dispersion precedent).
- Docs updated to “all eleven fixtures recorded against drmTMB 0.6.0” (or exact
  `packageVersion` string).
- AGENTS.md parity-anchor edit only with maintainer approval in the PR body.

## QUESTIONS STILL OPEN

None load-bearing. Optional: whether to also rename testset strings
`R-parity vs drmTMB v0.1.3` → `… 0.6.0` in `runtests` messaging (yes if fixtures move).

Reply **`G0 APPROVED`** or adjust.

---

## ARC PROGRAM

Size · 90–150 min · Arc0 desk+#issue → Rung1 regen six → Rung2 parity verify →
Rung3 docs → Closeout PR.

## SLICE TABLE

| Slice | Member | Bar | Time | Detail | Dep |
|---|---|---|---|---|---|
| Arc0 | Ada | Cursor Models | 15m | Merge #390 if green; issue #NN; branch from tip; confirm drmTMB 0.6.0 | — |
| Rung1 | Hopper | Cursor Models | 30m | `DRM_PARITY_ONLY=<six>` regen; inspect meta versions + Δ vs old | Arc0 |
| Rung2 | Hopper/Curie | Cursor Models | 40m | `DRM_PARITY_TESTS=1` native 11 + bridge 11; soft-tol if needed | Rung1 |
| Rung3 | Pat/Hopper | Cursor Models | 25m | GENERATING.md, parity README, r-julia-bridge.md; AGENTS if approved | Rung2 |
| Closeout | Grace/Rose | Cursor Models | 20m | check-log.d + after-task + Rose + PR closes #NN | Rung3 |

**LUNA SUITABILITY:** yes for regen+verify. **ULTRA EFFORT:** no.  
**FAN-OUT:** ≤2. **RECONCILE:** light Melissa optional.

## ESTIMATE

~90–150 min · 1 session · fits `/goal` after G0.

## VERIFY

1. All six `expected.meta.toml` show `drmtmb_version = "0.6.0"` (or exact installed).
2. `DRM_PARITY_TESTS=1` native 11 + bridge 11/11 green (log, not exit code alone).
3. Docs no longer claim original six are v0.1.3 numbers.
4. No GPL source; `.worktrees/` unstaged; D-111 OFF; no `src/` unless STOP.
5. Rose: no inflated speed claims; version claim = recorded packageVersion only.

## STOP at G0

**Approve?** Reply `G0 APPROVED`. Then:

```text
/goal

Ultra-plan G0 approved. Refresh original six fixtures → drmTMB 0.6.0.
REPO: /Users/z3437171/Dropbox/Github Local/DRM.jl
PLAN: docs/dev-log/plans/2026-08-05-refresh-six-fixtures-060-ultra-plan.md
Prefer tip after #390 MERGED. Fences: D-111; .worktrees/; no Lovelace;
no invent families; AGENTS.md edit needs maintainer OK; record packageVersion only.
```
