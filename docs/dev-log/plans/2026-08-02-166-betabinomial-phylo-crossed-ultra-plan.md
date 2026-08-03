# Ultra-plan — DRM.jl #166: beta-binomial phylo/crossed RE route

**Status:** Phases 0–2, READ-ONLY. **STOP at G0.** No implementation has started; no `src/`
file has been touched by this plan. Written by Shannon/Ada per Shinichi's 2026-08-02 request to
open the next DRM.jl lane after #189/#367.

---

## 🎯 GOAL (paste-ready — copy verbatim into a fresh session to resume this plan)

```
SOLO PLATFORM: Cursor (this session is running in Cursor; execution after G0 hands to /goal).

DELIVERABLE: Close DRM.jl #166 — add the beta-binomial derivative kernel to the sparse-Laplace
GLMM engine and route `drm(bf(cbind(s,f) ~ x + phylo(1|species)), BetaBinomial(); tree=...)`
and the crossed `(1|g)+(1|h)` analogue, constant-sigma (overdispersion) first.

HEADLINE: Generalize the already-verified Beta family analytic kernel
(`src/beta.jl` `_laplace_v123(::Val{:beta_fixed}, …)` in `src/sparse_laplace_glmm.jl`) to
beta-binomial's discrete (known-trials) data term — shifted digamma/trigamma/polygamma
arguments (s+a, n-s+b, n+a+b) replace Beta's (a, b). This is a mechanical kernel
generalization, not a new derivation or a q4-engine change.

IN PARALLEL (cheap, independent slices): design note + symbolic check of the shifted-argument
kernel; test scaffolding (recovery fixture + FD-gradient harness) can be written before the
kernel lands, following the existing `test_beta_phylo_laplace.jl` / `test_binomial_phylo_laplace.jl`
shape.

DEFER (fenced, do not touch): Registrator/Julia General (D-111); `:natgrad`/AI-REML or any #291
acceleration follow-on; drmTMB R-bridge edits; GPL vendoring; `.worktrees/` (leave untracked);
nonconstant-sigma beta-binomial (tracked separately per the issue's own acceptance bar); the
verified q=4 engine core (`src/fit_q4_sparse_tmb.jl`, `src/sparse_aug_plsm.jl`, Takahashi
selected-inverse) — #166 touches only the general non-Gaussian Laplace file
`src/sparse_laplace_glmm.jl` + `src/betabinomial.jl`, never the q4 files.

DISCIPLINE: verify by parameter-recovery + analytic-vs-FD gradient ≤ 1e-6 (the engine bar,
per CLAUDE.md); compute target = local Julia (`Pkg.test()`), no Totoro/DRAC needed (this is a
small analytic-kernel + unit-test slice, not a simulation campaign); closure = PR `closes #166`
with tests + docstring + worked example + check-log.d entry + after-task + Rose audit (DoD per
AGENTS.md).
```

---

## Phase 0 — Orient

**One-sentence goal:** add the missing beta-binomial phylo/crossed-RE derivative kernel so
`BetaBinomial()` reaches the sparse-Laplace engine the same way Poisson/NB2/Gamma/Beta/Binomial
already do, closing #166.

**Tip state (confirmed idle after #189/#367).**

```
$ git fetch origin && git status -sb
## main...origin/main
?? .worktrees/                      ← untracked, fenced, expected (leave alone)

$ git log --oneline -3
89e050a docs(loop): tip idle after #189 merge
b7893c9 feat(#189): q=4 coevolution from relmat/animal/spatial (#367)
7fe1001 docs: hand off DRM tip after #291 arcs (#366)
```

`LOOP/checkpoint.md` reads: `TIP: IDLE. … remain idle unless Shinichi opens a DRM.jl G0.` —
**this session is that G0 request**, per Shinichi's explicit 2026-08-02 instruction.

## Phase 0.25 — Prior-work sweep (RECEIPT)

| Surface | Command / query run | Finding | Call |
|---|---|---|---|
| **Repo git state** | `git fetch origin; git status -sb; git branch -a; git worktree list; git stash list` | Tip clean at `89e050a` (== `origin/main`); only untracked `.worktrees/` (fenced by GOAL.md, leave alone); no branch/worktree/stash named `166` or `betabinomial`; existing benchmark branches exist for Poisson/NB2/Gamma-Beta/Binomial phylo (`codex/*-phylo-benchmark`) but **none for beta-binomial** — confirms the gap is real and unclaimed | Nothing to resume — build fresh |
| **Twin (drmTMB, R)** | Read #166's own issue body (cites the prior Codex R↔Julia handover) | *"the R-side worktree can fit beta-binomial phylo, but Julia needs a beta-binomial derivative kernel before public routing"* — **R already has this capability; Julia is the follower**, textbook fit for [[D-94]] (R-first, Julia catches up) | Reuse the R-confirmed capability contract; Julia-side build is the genuine gap, not new-to-both-halves innovation |
| **Brain** (`search_notes`, `search_all_projects: true`) | `"DRM.jl next issue after #189 beta-binomial phylo #166 Phase 3 articles #7"` then `"D-94 R-first sequencing DRM.jl idleness deliberate"` | **D-94** (2026-07-27, accepted): *"R halves are sequenced FIRST for the drmTMB/DRM.jl pair… do not propose reviving them ahead of their R twin."* **D-111**: no Registrator until the twin is ready. `FOR-DRM-LANE-0.7.0-hold` is a **drmTMB-side** RE-SD-coverage hold (`sd()`/SCALE+INTERVALS lane) — it binds R release tagging, not a Julia family-parity kernel slice; does not gate this issue. No note anywhere proposes #202 or #7 as "the" next slice | D-94 is the deciding fact: #166 is R-confirmed catch-up (safe); a capability drmTMB has **not** yet shown (see #202 below) would put Julia ahead of its twin, which D-94 forbids by default |
| **External prior art** | N/A — not commissioned | This is a mechanical generalization of DRM.jl's own already-verified Beta-family analytic kernel (`src/beta.jl`, `_laplace_v123(::Val{:beta_fixed}, …)`), not a new statistical method or a novelty claim | No `/notebook` sweep needed; the "prior art" is in-repo |

**Verdict:** **build-the-gap.** #166 is genuinely new Julia-side code (the beta-binomial
derivative kernel is absent from `src/sparse_laplace_glmm.jl`), scoped tightly by reusing (a) the
Beta family's existing analytic-kernel shape and (b) the Poisson/Binomial/Beta phylo+crossed
routing plumbing already in `src/betabinomial.jl`'s siblings. Nothing to resume; nothing to
re-derive from scratch.

### Candidates considered and why #166 wins

Ada's default after #189: **prefer the highest twin-mission, DRM.jl-only leverage among open
issues.** Full open-issue sweep (`gh issue list --state open`, 15 issues) and the candidates
actually weighed:

| # | Title | Verdict | Why |
|---|---|---|---|
| **#166** | Beta-binomial phylo/crossed RE route | **PICKED** | Bounded, well-precedented (mirrors 5 sibling families), **R-confirmed already exists on the twin** — exactly the D-94 "Julia follows" shape. No fence contact. |
| #202 | Non-Gaussian phylo location-scale (μ **and** log σ RE) | RETRACTED (for now) | Newly *unblocked* — its stated blocker #165 (exact non-Gaussian outer gradient) closed today along with #164/#291 — but nothing on record shows drmTMB has this capability yet. Building it now would put DRM.jl **ahead of** its R twin, which [[D-94]] explicitly asks Ada not to do by default. Worth a Boole/Pólya design pass once the R side is confirmed or Shinichi explicitly overrides D-94 for this item. |
| #7 | Phase 3: fill 26 Documenter articles | RETRACTED | Real debt, but low *engine* leverage and not one bounded "lane" — it is ~20 independent doc slices better run as a batch/loop of its own, not this G0's pick. Candidate for the **next** lane after #166. |
| #186 | Epic: bivariate coevolution (parent of #189) | RETRACTED | All three sub-issues (#187/#188/#189) are now closed — this is a one-line administrative close, not a new lane. Flagged for housekeeping, not picked. |
| #327 | Hutchinson stochastic-trace REML | RETRACTED | Sits directly adjacent to the just-fenced `:natgrad`/AI-REML / #291-acceleration boundary (GOAL.md explicitly forbids "#291 acceleration follow-on"). Too close to the fence to pick without a fresh, explicit go-ahead. |
| #269/#270 | Pagel's λ; kernel/sparse-GP `relmat` | RETRACTED | Pólya scouting/`idea`-labelled — design-phase, not execution-ready; "Pólya proposes, Pólya does not implement." |
| #227 | Scout backlog (meta-issue of ideas) | RETRACTED | Not a single actionable slice. |
| #280 | Per-response-column family dispatch | RETRACTED | Coordination issue with **GLLVM.jl** — not DRM.jl-only. |
| #136 | VA/ELBO marginal alternative | RETRACTED | Open-ended research surface (marginal accuracy), `idea`-labelled, larger design decision than a single G0 slice. |
| #49 | Missing-data FIML/EM | RETRACTED | `idea`-labelled, needs its own design pass before a bounded slice exists. |
| #336 | Makie plotting extension | RETRACTED | Legitimate but lower twin-mission leverage (visualization, not model-class parity). |

## Phase 0.3 / 0.3b — Model roster + Cursor two-bar check

Per `~/.cursor/skills/ultra-plan/SKILL.md` §Phases 0–2: **glance Settings → Usage for the two
Cursor Ultra bars (Cursor Models · Other Models) before dispatching Phase 3 sub-agents** — this
agent cannot read that dashboard itself; Shinichi should glance it at G0 approval. Routing table
below assumes the ordinary split (scout → Composer/Grok on Cursor Models; judgment/build → Auto
Cost or pinned Claude/GPT on Other Models; orchestration/verify → hand off to Claude Opus).
`MODEL-ROUTING.md` roster used: Claude Haiku(scout)/Sonnet(build,**default**)/Opus(verify,
orchestrate); Cursor Composer 2.5/Grok 4.5 (Cursor-Models bar, scout/bounded-agentic); Auto Cost
/ pinned Claude-GPT (Other-Models bar, judgment).

## Phase 0.4 — Team raised (attributed; light per Shinichi's "you pick" instruction)

```
TEAM RAISED
  Noether — sparse_laplace_glmm.jl is the GENERAL non-Gaussian Laplace file (Poisson/NB2/Gamma/
            Beta/Binomial already live there); it is NOT the fenced q4 core (fit_q4_sparse_tmb.jl /
            sparse_aug_plsm.jl / Takahashi). #166 is safe to build there. Recommendation: reuse the
            beta_fixed kernel shape exactly; do not invent a new aux-struct convention.
  Boole    — BetaBinomial()'s formula-grammar surface (cbind(), sigma slot, single-RE-on-mean
             restriction) is already correct and unchanged by #166 — this is a routing addition,
             not a grammar change. No bf()/reserved-syntax work needed.
  Rose     — Watch the acceptance bar literally: recovery test + analytic-vs-FD ≤1e-6 for BOTH
             phylo and crossed, constant-sigma only (per the issue's own text). Do not let
             nonconstant-sigma or a coevolution-style extension creep in under this issue number.
  Ada      — Synthesis: #166 is the correct next lane — bounded, twin-confirmed, fence-clean.
             #202 is a live idea for the lane AFTER this one, gated on either an explicit
             Shinichi override of D-94 or R-side confirmation.
```

No blocking question for Shinichi here — the issue pick was Ada's to make per this session's
instructions, and the acceptance bar is already written into #166 itself.

## Phase 1 — Decompose into slices

| Slice | Input | Output | Depends on |
|---|---|---|---|
| S1 Design note | `src/beta.jl` `_laplace_v123(::Val{:beta_fixed})`, `src/sparse_laplace_glmm.jl` binomial/beta phylo+crossed fitters | `docs/dev-log/plans/2026-08-02-166-betabinomial-kernel-design.md` — shifted-argument kernel math (digamma/trigamma/polygamma at s+a, n-s+b, n+a+b) | none |
| S2 Kernel (TDD, failing test first) | S1 design | `_laplace_v123(::Val{:betabinomial_fixed}, …)` + `_laplace_v123_nuisance(::Val{:betabinomial_fixed}, …)` + aux fields (`s`, `ntr`, `logchoose`) in `src/sparse_laplace_glmm.jl`; FD-gradient unit test | S1 |
| S3 Fitters + routing | S2 | `_fit_betabinomial_phylo_laplace` / `_fit_betabinomial_crossed_laplace` in `src/sparse_laplace_glmm.jl`; `drm(f, BetaBinomial())` phylo/crossed dispatch in `src/betabinomial.jl` (mirrors `binomial.jl`/`beta.jl`) | S2 |
| S4 Tests | S3 | `test/test_betabinomial_phylo_laplace.jl`, `test/test_betabinomial_crossed_laplace.jl` — parameter recovery + analytic-vs-FD ≤1e-6, wired into `test/runtests.jl` | S3 |
| S5 Docs + DoD | S4 green | docstring update in `betabinomial.jl`; worked example (extend `docs/src/tutorials/proportion-beta-binomial.md` or `phylogenetic-models.md`); `check-log.d/2026-08-0X-166-betabinomial-phylo.md`; `after-task/2026-08-0X-166-betabinomial-phylo-crossed.md` | S4 |
| S6 Rose audit | S5 | claim-vs-evidence pass in the after-task; confirms constant-sigma-only scope held | S5 |
| S7 PR | S6 green | PR `closes #166` | S6 |

**Parallel:** {S1} can start immediately; S4's test *scaffolding* (fixture shape, FD harness) can
be drafted in parallel with S2/S3 since it follows the existing `test_beta_phylo_laplace.jl` /
`test_binomial_phylo_laplace.jl` template. **Sequential:** S2←S1, S3←S2, S4←S3 (real assertions),
S5←S4, S6←S5, S7←S6.

## Phase 2 — Plan table (roles · models · Bar · estimate · review)

| Slice | Member | Model + effort | Dispatch | Bar (Cursor) | Time | Files | Dep |
|---|---|---|---|---|---|---|---|
| RECON | Ada (scout) | Composer 2.5 / Grok 4.5, low | native/explicit | **Cursor Models** | 15 min | grep confirm no partial #166 work; re-read `beta.jl`/`binomial.jl` routing | — |
| S1 Design | Noether | Sonnet, medium | native/explicit | Other Models (hand to Claude) | 30 min | `docs/dev-log/plans/…kernel-design.md` | RECON |
| S2 Kernel (TDD) | Noether | Sonnet, high (crosses an AD/analytic-derivative boundary) | native/explicit | Other Models | 45–60 min | `src/sparse_laplace_glmm.jl` | S1 |
| S3 Fitters+routing | Noether/Boole | Sonnet, medium | native/explicit | Other Models | 45 min | `src/sparse_laplace_glmm.jl`, `src/betabinomial.jl` | S2 |
| S4 Tests | Curie | Sonnet, medium | native/explicit | Other Models | 30 min | `test/test_betabinomial_*_laplace.jl`, `test/runtests.jl` | S3 |
| S5 Docs+DoD | Pat | Sonnet, low–medium | native/explicit | Other Models | 20 min | docstring, tutorial, check-log.d, after-task | S4 |
| MECHANICAL-VERIFY | Ada (scout) | Composer/Grok or Haiku, low | native/explicit | **Cursor Models** | 10 min | re-run `Pkg.test()`, confirm files non-empty, check-log row present | S5 |
| S6 Rose audit | Rose | Opus, high | hand off | **hand off — Claude Opus** | 20 min | after-task claim-vs-evidence pass | MECHANICAL-VERIFY |
| S7 PR | Ada | Sonnet, medium | native/explicit | Other Models | 10 min | PR body, `closes #166` | S6 |
| RECONCILE | Melissa | Sonnet, low–medium | native/explicit | Other Models | 15 min | `docs/dev-log/plan-actual/2026-08-0X-166-betabinomial-phylo.md` | S7 |

**Fan-out budget:** ≤6 new children, ≤1 Sol/Opus child (Rose's S6 audit is the one ceiling use;
justified — it is the pre-publish claim gate, not routine implementation). **Luna suitability:**
yes for RECON + MECHANICAL-VERIFY (both bounded/read-only/mechanical) — route through Composer/
Grok on the Cursor-Models bar (Cursor has no native Luna equivalent; Composer/Grok is this
session's scout tier). **No ultra effort.** **Context brake:** not yet relevant — this plan has
not executed.

**Members plan-review (before execution, done here):** Rose confirms the sweep receipt above is
non-vacuous (every row cites its command/query); Noether confirms S2/S3 do not touch
`fit_q4_sparse_tmb.jl` / `sparse_aug_plsm.jl` / Takahashi. Both hold.

## Fences (carried into LOOP/GOAL.md verbatim at G0)

- No Registrator / Julia General (D-111).
- No `:natgrad` / AI-REML; no #291 acceleration follow-on.
- No drmTMB R-bridge edits; never vendor GPL source.
- Do not edit `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi selected-inverse.
- Nonconstant-sigma beta-binomial is **out of scope** for #166 (tracked separately per the issue).
- Leave `.worktrees/` untracked/unstaged.
- One DRM.jl lane; no nested multitask fork.

## Acceptance (= #166's own bar, restated)

1. `drm(bf(cbind(s,f) ~ x + phylo(1 | species)), BetaBinomial(); tree = …)` fits and routes
   through the sparse-Laplace engine (not GHQ).
2. The crossed analogue `(1 | g) + (1 | h)` also routes through the sparse-Laplace engine.
3. Parameter-recovery test for both phylo and crossed, constant-sigma only.
4. Analytic-vs-FD outer gradient ≤ 1e-6 for both routes (the CLAUDE.md engine bar).
5. Full DoD: implementation wired into `src/DRM.jl`, tests in `test/runtests.jl`, docstring,
   worked example, `check-log.d/` entry, after-task report, Rose audit.
6. PR `closes #166`.

---

## Post-G0 section (NOT executed now) — loop-context-hygiene scaffold + `/goal` handoff

**Do not write these to `LOOP/` on disk until Shinichi approves G0.** The three templates below
are prepared here, ready to paste onto disk the moment he says "approve G0" — this satisfies
step 4 of his request (*prepare, don't overwrite yet*).

### `LOOP/GOAL.md` (to write at G0 — content prepared)

```markdown
# GOAL — issue #166 beta-binomial phylo/crossed RE route (IMMUTABLE — re-read at the top of EVERY arc)

## Mission
Close DRM.jl #166: add the beta-binomial derivative kernel to the sparse-Laplace GLMM engine;
route `drm(bf(cbind(s,f) ~ x + phylo(1|species)), BetaBinomial(); tree=...)` and the crossed
`(1|g)+(1|h)` analogue through it. Constant-sigma (overdispersion) first; PR `closes #166`.

## Headline
Generalize the verified Beta-family analytic kernel (`_laplace_v123(::Val{:beta_fixed}, …)`) to
beta-binomial's discrete known-trials data term — shifted digamma/trigamma/polygamma arguments,
not a new derivation. Reuse the Poisson/Binomial/Beta phylo+crossed routing plumbing verbatim.

## Invariants
- One DRM.jl lane; leave `.worktrees/` unstaged.
- No Registrator / Julia General (D-111).
- No `:natgrad` / AI-REML; no #291 acceleration follow-on.
- No drmTMB R-bridge edits; never vendor GPL source.
- Do not edit `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi core.
- Nonconstant-sigma beta-binomial out of scope (tracked separately).
- Twin doctrine: R already has this capability (per #166 body) — Julia is following, per D-94.

## Authoritative WHAT
`LOOP/ultra-plan.md` (frozen copy of this approved #166 ultra-plan).

## Definition of done
1. Phylo and crossed beta-binomial routes both reach the sparse-Laplace engine (not GHQ).
2. Parameter-recovery + analytic-vs-FD gradient ≤1e-6 for both routes, constant-sigma only.
3. Docs + DoD artifacts (tests, docstring, worked example, check-log.d, after-task, Rose).
4. PR closes #166.
```

### `LOOP/arcs.md` (to write at G0 — content prepared)

```markdown
# Arcs — #166 beta-binomial phylo/crossed RE route

| Arc | Status | Gate | Deliverable |
|---|---|---|---|
| 0 Design | PENDING | none | kernel design note (shifted-argument digamma/trigamma math) |
| 1 Kernel (TDD) | PENDING | FD-gradient unit test green | `_laplace_v123(::Val{:betabinomial_fixed})` + nuisance variant |
| 2 Fitters+routing | PENDING | none | `_fit_betabinomial_phylo_laplace` / `_fit_betabinomial_crossed_laplace` + `drm()` dispatch |
| 3 Tests | PENDING | recovery + FD ≤1e-6 both routes | `test_betabinomial_phylo_laplace.jl`, `test_betabinomial_crossed_laplace.jl` |
| 4 Close | PENDING | PR merge | docs, DoD, Rose, PR closes #166 |
```

### `LOOP/checkpoint.md` (to write at G0 — initial content prepared)

```markdown
GOAL: #166 beta-binomial phylo/crossed RE route — see LOOP/GOAL.md.
ARCS DONE (verified): none yet.
ARC IN PROGRESS: Arc 0 (design) — not started.
NEXT: Arc 0 → kernel design note, then Arc 1 (TDD kernel).
OPEN GATES: G0 approval itself (this plan) — resolves the moment Shinichi approves.
TRUTH LIVES IN: this plan file
(`docs/dev-log/plans/2026-08-02-166-betabinomial-phylo-crossed-ultra-plan.md`); no branch cut yet.
RESUME: read AGENTS.md → LOOP/GOAL.md → this checkpoint → `/goal` with the prompt below.
```

### `LOOP/ultra-plan.md` (to write at G0 — frozen-plan pointer, content prepared)

```markdown
# Ultra-plan freeze — DRM.jl #166 (G0 approved 2026-08-0X)

Platform: Cursor `/goal` execution.
Deliverable: close #166 — beta-binomial phylo/crossed RE route via the sparse-Laplace engine.
Headline: generalize the verified Beta-family kernel to beta-binomial's known-trials data term.
Fence: D-111; no `:natgrad`; no #291 accel; no drmTMB R edits; no GPL vendor; no `.worktrees/`;
nonconstant-sigma out of scope; no q4-engine-core edits.

## Locked decisions
- Constant-sigma (overdispersion) only for #166; nonconstant tracked as a follow-on issue.
- Reuse `beta_fixed` kernel shape and aux-struct convention exactly (no new dispatch pattern).
- Both phylo and crossed routes land in one PR (mirrors how #189 landed all three providers).

## Acceptance
See `LOOP/GOAL.md` Definition of done.
```

### Paste-ready `/goal` prompt (use this after G0 approval)

```
/goal Close DRM.jl #166 — beta-binomial phylo/crossed RE route. Read LOOP/GOAL.md, LOOP/arcs.md,
LOOP/checkpoint.md, and the frozen plan at
docs/dev-log/plans/2026-08-02-166-betabinomial-phylo-crossed-ultra-plan.md first. Follow the
slice table there (S1 design → S2 kernel/TDD → S3 fitters+routing → S4 tests → S5 docs/DoD → S6
Rose audit → S7 PR closes #166). Checkpoint LOOP/checkpoint.md after every arc. Fences: no
Registrator, no :natgrad/AI-REML, no drmTMB R-bridge edits, no GPL vendoring, no
q4-engine-core edits (fit_q4_sparse_tmb.jl / sparse_aug_plsm.jl / Takahashi), nonconstant-sigma
beta-binomial out of scope, leave .worktrees/ alone. Verify bar: parameter recovery +
analytic-vs-FD gradient ≤1e-6 for both phylo and crossed routes, per CLAUDE.md. Stop and ask if
you hit a genuinely new design decision; otherwise run the arcs to PR.
```

---

## VERIFY / CONSOLIDATE / RECONCILE (for Phase 4/4.5 after execution — not run yet)

- **VERIFY:** `Pkg.test()` green; analytic-vs-FD ≤1e-6 both routes; Rose claim-vs-evidence pass.
- **CONSOLIDATE:** PR `closes #166`; update `docs/src/capabilities.md` if it lists family×RE-route
  coverage; `LOOP/checkpoint.md` → idle after merge (mirrors the #189 pattern).
- **RECONCILE:** Melissa, Sonnet/Terra, effort low–medium, at PR close →
  `docs/dev-log/plan-actual/2026-08-0X-166-betabinomial-phylo.md`.
