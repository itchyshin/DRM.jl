# #336 DRMMakieExt — Arc Card + Ultra Plan (G0)

**Speak as Shannon.** Active perspectives: Ada (orchestrate), Florence (figures / Confidence Eye), Pat (docs UX), Karpinski (Julia package hygiene / weakdeps), Rose (claims). No nested subagents for this plan-only turn.

**Plan mode:** read-only through Phase 2. Do **not** implement, commit, push, or open a PR until owner G0 sign-off. After approval, run via `/goal` in a fresh Agent chat.

**Platform:** Cursor (this session).

---

## ARC CARD — #336 DRMMakieExt (prepare-data → Makie)

**Mode:** size  
**Requested outcome:** not quantified — ship a HSquared-pattern Makie drawing extension for existing `visualization.jl` preparers; close [#336](https://github.com/itchyshin/DRM.jl/issues/336)  
**Mechanism authority:** `Project.toml` weakdeps/extensions; new `src/plotting_ext.jl` stub; `ext/DRMMakieExt.jl`; CI stub tests (Makie **out** of default CI); docs honesty + DoD; **no** q=4 / family / VA / FIML / R-bridge edits; never stage `.worktrees/`; no GPL vendoring  
**Recommended arc:** **3.0 hours** (range 2.5–3.5 h)  
**Time contract:** ceiling ~3.5 h  
**Estimate confidence:** **inferred** (HSquaredMakieExt analogue ~346 lines + measured house pattern; DRM has only 3 preparers → smaller surface)  
**Arc 0 outcome:** PR that adds `DRMMakieExt` drawing the three preparers + stub CI gate + docs; `closes #336`  
**State transition:** `no ext/ · plot-data only` → `weak-dep Makie(+AoG) extension with stub-tested dispatcher`  
**Executable rung and evidence:** local stub tests green; optional local CairoMakie smoke (not CI); Rose PASS (no claim that CI draws figures); PR open

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 3.0 h | `DRMMakieExt` + stub CI + docs + PR `closes #336` | Start after G0 |
| Rung 1 | ~45–90 min | AoG polish for faceted corpairs / richer Confidence Eye variants | Only if Arc 0 under-runs **and** owner wants polish in-lane; else separate issue |
| Integrate/close | in Arc 0 | DoD + Rose | Always |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 20 | Tip `6c224a6c`; re-read preparers + HSquared stub/ext pattern |
| Core | 110 | Project.toml weakdeps; stub; ext with 3 kinds; wire export |
| Verify | 30 | Stub tests in `Pkg.test()`; optional local CairoMakie smoke |
| Repair reserve | 20 | Compat pin / MethodError message / load issues |
| Closeout | 20 | check-log.d + after-task + PR |
| **Total** | **200** (~3.3 h; report as **3.0 h** with 20 min slack in repair) | |

**In scope:**  
- `[weakdeps]` Makie + AlgebraOfGraphics (match HSquared house convention; compat pins aligned with HSquared: Makie `"0.24"`, AoG `"0.13"` unless tip evidence forces bump)  
- `[extensions] DRMMakieExt = ["AlgebraOfGraphics", "Makie"]`  
- `src/plotting_ext.jl`: method-less `function drm_figure end` (+ optional thin `plot_*` aliases that call preparers then `drm_figure`)  
- `ext/DRMMakieExt.jl`: kinds for `:profile` ← `profile_curve`, `:parameter_surface` ← `parameter_surface`, `:corpairs` ← `corpairs_data`  
- Florence: **Confidence Eye** on `:profile` (pale region + darker outline + hollow estimate)  
- CI: stub only (`isempty(methods(drm_figure))` + MethodError without Makie/AoG) — **Makie out of CI**  
- Docs: `reference/visualization.md`, `simulation-plot-grammar.md`, `capabilities.md` honesty (extension present; CI does not draw)  
- DoD + PR `closes #336`

**Not in this arc:** q=4 core; #136 VA; #49 FIML; R `engine="julia"`; full AoG redesign of every figure; DocumenterVitepress gallery rewrite; GLLVM.jl #168; tip-idle SHA padding.

**Evidence used:** tip `origin/main` = `6c224a6c` (Merge #397, #7 CLOSED); no `ext/` yet; `visualization.jl` exports `profile_curve` / `parameter_surface` / `corpairs_data`; HSquared `ext/HSquaredMakieExt.jl` + `src/plotting_ext.jl` + CI stub pattern; journal 2026-07-06 (#336 posted, no code); brain notes on HSquaredMakieExt / house plotting convention.

**Risk branch:** If Makie 0.24 / AoG 0.13 fail to resolve on Julia 1.10 tip, stop drawing work and return a compat probe receipt (do not expand into engine work).

**Done when:** PR open (`closes #336`), stub tests green in local `Pkg.test()`, Rose PASS on claims, inventory of three kinds retained in evidence/after-task.

**First action (post-G0):** `git fetch && git checkout main && git pull && git checkout -b feat/336-makie-ext`

**HAND TO ULTRA PLAN:** Arc 0 = #336 DRMMakieExt (~3 h), HSquared pattern, Makie+AoG weakdeps, 3 figure kinds + Confidence Eye on profile, stub CI only; fence engine/#136/#49/R-bridge; PR `closes #336`.

### Actuals (complete at close)
*(empty until `/goal` execution)*

---

## Ultra Plan — Phases 0–2 (STOP at G0)

### GOAL (paste-ready)

```
PLATFORM: Cursor (workbench)
DELIVERABLE: Close DRM.jl #336 — add DRMMakieExt weak-dep drawing layer for
 existing visualization.jl preparers, HSquared-pattern, from tip origin/main
 @ 6c224a6c.
HEADLINE: Prepare-data stays in src/; Makie+AoG only in ext/; CI gates the
 method-less stub (Makie OUT of CI). Draw :profile (Confidence Eye),
 :parameter_surface, :corpairs.
IN PARALLEL: none required (single UX/package slice).
DEFER / FENCE: #136 VA; #49 FIML; R-bridge live round-trip; q=4 core;
 simultaneous phylo×spatial engine; GLLVM.jl #168; D-111/Registrator;
 GPL vendoring; never stage .worktrees/.
DISCIPLINE: verify before claiming · one issue → one branch → one PR ·
 stub tests in Pkg.test · optional local CairoMakie smoke not claimed as CI ·
 Rose claim-vs-evidence · Florence Confidence Eye contract on :profile.
```

### ARC PROGRAM

Size mode · Arc 0 ≈ 3 h DRMMakieExt ship · Rung 1 = AoG faceting polish (optional / separate) · no padding.

### PHASE 0.25 — SWEEP RECEIPT

| Surface | Evidence ran | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb`; `origin/main` = `6c224a6c`; `branch_drift_check` main 0/0; no open ship PR | Tip **IDLE** after #397/#7 | **build-the-gap** on fresh `feat/336-makie-ext` from updated main |
| **twin / sister** | HSquared `Project.toml` weakdeps Makie+AoG; `ext/HSquaredMakieExt.jl` (~346 lines); `src/plotting_ext.jl` stub `hsquared_figure`; CI stub `isempty(methods(...))` | House pattern complete in HSquared | **co-opt** HSquared pattern; do not reinvent |
| **brain** | `search_notes` “DRM.jl #336 Makie…”; `grep` AGENT_LOG/DECISIONS/OPEN_QUESTIONS/journal for 336/Makie | Journal 2026-07-06: #336 posted, no code; HSquaredMakieExt notes exist; no decision blocking #336 | **build** DRM gap; **reuse** HSquared design |
| **repo docs/src** | `visualization.jl` 3 preparers; `docs/src/reference/visualization.md` data-only; capabilities claim CairoMakie gallery in **docs**, not package ext | Package still has no drawing backend | **build extension**; fix capability wording if it overclaims package-shipped Makie |
| **Verdict** | | Genuinely new: DRMMakieExt + stub + docs. Not new: preparers, HSquared pattern | **co-opt HSquared → build DRM gap** |

### WHAT THE BRAIN / REPO ALREADY KNOWS

- Tip idle @ `6c224a6c`; #7 closed; #336 was the pre-ranked next ship G0.
- Preparers already exist; only the drawing layer is missing.
- House convention: prepare-data in core + Makie(+AoG) weak-dep extension; Makie out of CI.

### WHAT SHINICHI TOLD US

- Asked `/arc-creation` then `/ultra-plan` for #336 here after #7 merge.

### WHAT THE TEAM RAISED

```
TEAM RAISED
 Florence — Arc 0 must ship Confidence Eye on :profile (pale lens + outline +
   hollow estimate); inspect a real local PNG if smoke runs. · Rec: Eye in Arc 0.
 Karpinski — Match HSquared Project.toml shape; pin Makie/AoG compat; keep
   Makie out of [deps] and out of default test target. · Rec: weakdeps only.
 Pat — Docs must say “load CairoMakie + AoG to draw”; update reference +
   simulation-plot-grammar; don’t leave readers wiring from scratch. · Rec: docs in PR.
 Rose — Do not claim CI renders figures; capabilities.md “CairoMakie figures”
   must stay docs-gallery / opt-in smoke honest. · Rec: Rose PASS gate.
 Ada — AoG in weakdeps day-1 (house match); heavy AoG faceting can be Rung 1.
   · Rec: lock Makie+AoG weakdeps; raw Makie OK for surface/Eye.
```

### ADA'S RECOMMENDATION

**Execute Arc 0 as HSquared-twin DRMMakieExt** with three kinds + Confidence Eye on profile + stub CI. Prefer public dispatcher name **`drm_figure`** (mirror `hsquared_figure`) plus thin drmTMB-named `plot_*` convenience wrappers if cheap.

### DECISIONS LOCKED (pending G0)

1. Arc 0 = **#336** from tip `6c224a6c` / branch `feat/336-makie-ext`.  
2. Weakdeps: **Makie + AlgebraOfGraphics** (HSquared match).  
3. CI: **stub only**; Makie out of default test env.  
4. Fence: no engine / #136 / #49 / R-bridge.  
5. Plan-only until G0; then `/goal` (not Phase 3 in this chat).  
6. Durable plan copy on execution: `docs/dev-log/plans/2026-08-07-336-makie-ext-ultra-plan.md`.

### QUESTIONS STILL OPEN (max 2)

**Q1.** Public entry API: **`drm_figure(data; kind)`** (HSquared twin) vs only drmTMB-named `plot_corpairs` / `plot_parameter_surface` / `plot_profile`?  
**Recommendation / IF YOU DO NOT MIND:** **`drm_figure` + thin `plot_*` aliases**.  
**WHAT CONTINUES:** reversible plan until you answer or say “use your judgment.”

**Q2.** Put **AlgebraOfGraphics** in Arc 0 weakdeps (load-gated with Makie, even if Arc 0 drawings are mostly raw Makie), or Makie-only first and AoG in a follow-up issue?  
**Recommendation / IF YOU DO NOT MIND:** **AoG in Arc 0 weakdeps** (house convention; matches HSquared extension gate). Fancy faceted AoG polish can still be Rung 1.

---

## Slice table (post-G0 `/goal` execution)

| Slice | Member | Bar | Model | Time | Detail | Dep |
|---|---|---|---|---|---|---|
| Orient + HSquared mirror map | Ada/Karpinski | Cursor Models | Composer | 20m | Project.toml + stub + ext skeleton | — |
| Implement DRMMakieExt (3 kinds + Eye) | Florence/Karpinski | Cursor Models | Composer | 90m | `ext/DRMMakieExt.jl`, Confidence Eye on `:profile` | orient |
| Stub tests + export wire | Karpinski | Cursor Models | Composer | 25m | `test/test_makie_ext_stub.jl` or runtests include; `DRM.jl` export | impl |
| Docs honesty | Pat | Cursor Models | Composer | 25m | visualization.md, simulation-plot-grammar, capabilities | impl |
| Rose + DoD + PR | Rose/Grace | Other Models / judgment | Auto Cost | 25m | check-log.d, after-task, PR `closes #336` | docs+tests |
| MECHANICAL-VERIFY | Grace | Cursor Models | Composer | 10m | stub tests; no Makie in Project.toml deps | PR |
| RECONCILE | Melissa | Other Models | light | 5m | plan-actual if material close | PR |

**LUNA SUITABILITY:** yes for HSquared file mirror / Project.toml scout.  
**FAN-OUT BUDGET:** 0–1 scout child optional; single build lane preferred.  
**ESTIMATE:** ~3 h wall-clock; one session; one PR.  
**VERIFY:** `Pkg.test()` stub green; Rose PASS; optional local CairoMakie smoke recorded as opt-in only.  
**CONSOLIDATE:** after-task + check-log.d; capabilities honest.

---

## Execution sketch (only after G0)

1. `git checkout main && git pull` → `feat/336-makie-ext`.  
2. Copy durable ultra-plan to `docs/dev-log/plans/2026-08-07-336-makie-ext-ultra-plan.md`.  
3. Add weakdeps/extensions; `src/plotting_ext.jl` stub; wire include/export.  
4. Implement `ext/DRMMakieExt.jl` for three kinds; Confidence Eye on `:profile`.  
5. Stub tests (no Makie in test Project.toml targets).  
6. Docs + DoD + PR `closes #336`.  
7. Stop; do not start #136/#49.

---

## Paste-ready `/goal` prompt (after you approve G0)

```
/goal DRM.jl #336 DRMMakieExt (HSquared-pattern Makie drawing layer)

PLATFORM: Cursor Agent from tip origin/main @ 6c224a6c (pull main first).

DELIVERABLE: One PR that adds DRMMakieExt and closes #336.
HEADLINE: prepare-data stays in src/visualization.jl; drawing in
 ext/DRMMakieExt.jl; Makie+AlgebraOfGraphics weakdeps; CI stub-only
 (Makie OUT of CI). Kinds: :profile (Confidence Eye), :parameter_surface,
 :corpairs. Public API: drm_figure + thin plot_* aliases (unless G0 says otherwise).

IN SCOPE: Project.toml weakdeps/extensions; src/plotting_ext.jl stub;
 ext/DRMMakieExt.jl; stub tests; docs honesty (visualization +
 simulation-plot-grammar + capabilities); check-log.d + after-task;
 PR closes #336.

FENCE: no src/ q=4 engine / families; no #136/#49/R-bridge; never stage
 .worktrees/; no GPL vendoring; do not add Makie to [deps] or default CI.

FIRST ACTION: git fetch && git checkout main && git pull &&
 git checkout -b feat/336-makie-ext

PLAN REF: Cursor plan "336 Makie Ext"; on start write durable copy to
 docs/dev-log/plans/2026-08-07-336-makie-ext-ultra-plan.md

DONE WHEN: PR open (closes #336), stub tests green, Rose PASS.
STOP: do not start VA/FIML/R-bridge in the same PR.
```

---

**Await G0 sign-off; do not execute.**
