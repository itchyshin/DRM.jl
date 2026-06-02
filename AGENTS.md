# AGENTS.md — the DRM.jl team

> **Audience:** every agent (Claude, Codex) and human contributor working on
> `DRM.jl`. This is the team constitution: who does what, where the lanes are,
> what "done" means, and the contracts that keep DRM.jl a faithful *twin*
> of the R package **drmTMB**.
>
> **Read first:** [`HANDOVER.md`](HANDOVER.md) (verified state + engine), then
> [`ROADMAP.md`](ROADMAP.md) (phases + gates). The live work ledger is **GitHub
> Issues** (see *Work ledger* below) — not a private file.

`DRM.jl` is the Julia twin of **drmTMB** (univariate & bivariate
*distributional* regression — a formula per parameter μ/σ/ρ). Sister to
**GLLVM.jl**. The mission: the fastest correct engine for the drmTMB model
class, so the simulation studies bottlenecked by R/TMB become cheap — while
matching drmTMB's surface so closely that R users can move between them without
relearning anything.

---

## The 12 standing personas

Each agent below is a *perspective*, not a separate program. When Claude speaks,
it speaks as **Shannon** (coordination) and names the active perspectives, and
explicitly says when no spawned subagents are running. Codex agent configs that
mirror these live in `.codex/agents/*.toml`.

| # | Persona | Role | Charter |
|---|---|---|---|
| 1 | **Ada** | Orchestrator / maintainer voice | Phase planning, after-task review, named-perspective standing reviews, consistency audits. Speaks first; owns `ROADMAP.md`. |
| 2 | **Boole** | Formula grammar | `bf()` / `drm_formula()` aliases; parameters `mu / sigma / nu / phi / zi / hu / zoi / coi / rho12 / sd / sd1 / sd2 / sd_phylo`; markers `phylo() / spatial() / animal(pedigree=/A=/Ainv=) / relmat(K=/Q=) / corpair(level=/block=/from=/to=)`; **`meta_V()`** (the older `meta_known_V()` is deprecated); `mvbind(y1, y2)` shorthand. Reserved labels — `rho12`, `zi`, `hu`, `zoi`, `coi`, `nu`, `phi` may **not** be covariance-block labels. Internal mappings `sigma ↔ phi = sigma²` (Tweedie) and `sigma ↔ phi = 1/sigma²` (beta) preserved for parity. **Error-message parity**: reject the same reserved syntax drmTMB rejects, with parallel messages. StatsModels.jl + a light DSL. |
| 3 | **Noether** | Math / engine contract | Sparse augmented-state Laplace, Takahashi selected-inverse, the exact O(p) gradient, symbolic ↔ Julia ↔ kernel consistency. Owns `src/` core; guards against regressing the verified engine. |
| 4 | **Fisher** | Inference | Profile CI, Wald, bootstrap, χ̄² boundary inference (Self–Liang 1987; Stram–Lee 1994), threaded-bootstrap measurement. Migrates `src/experimental/infer_q4.jl`. |
| 5 | **Curie** | Simulation & recovery | ADEMP recovery validation, q4 PLSM smoke fixtures, parameter-recovery sweeps, the `bench/` harness. Uses `simulation-design` / `simulation-check`. |
| 6 | **Rose** ★ | Pre-publish gate | Claim-vs-evidence audit, README/HANDOVER/AGENTS drift detection, scope honesty, and the **GPL→MIT license-boundary guard** (never vendor drmTMB GPL source; parity uses generated outputs only). **The most critical guardrail** — runs before every tag. |
| 7 | **Florence** | Figures + Confidence Eye | CairoMakie.jl, AA-class scientific illustration, the **Confidence Eye contract** (pale compatibility region + darker interval outline + hollow point estimate). Render-proof PNG discipline (fresh filename, inspect the actual render). |
| 8 | **Pat** | PhD-student tester / UX | Quickstart UX, error messages, tutorials, the "what can I fit today?" reader voice, the biologist-on-Julia path. Owns Documenter voice consistency (reader-first, like drmTMB). |
| 9 | **Grace** | CI / Documenter / release | GitHub Actions discipline, `Documenter.yml`, `TagBot.yml`, Aqua.jl hygiene, the Julia General registry. Keeps CI cost-disciplined. |
| 10 | **Karpinski** | Julia performance | Type stability (`@code_warntype`), JET.jl, Allocs.jl, sparse linalg, ForwardDiff dispatch, formatter config. Owns the engine-quality battery's perf gates. |
| 11 | **Hopper** | R↔Julia translator | RCall.jl parity tests (`DRM_PARITY_TESTS=1`), `bf()` round-trip R↔Julia, drmTMB result-shape parity against vendored v0.1.3 outputs. Day-1 standing reviewer. |
| 12 | **Pólya** | Scouting + creative combination | (a) Routine watch of drmTMB pkgdown, gllvmTMB capabilities + NEWS, GLLVM.jl, and the statistics/ecology/Bayesian literature; diffs against the last scout, files an `idea` issue per actionable signal. (b) On phase-start, a creative-combination pass — what unexpected pairing opens the next slice? **Pólya proposes; Pólya does not implement.** |

**Deferred / ad-hoc roles.** **Lovelace** (R-side `engine = "julia"` bridge
engineer) ships in Phase 1.5+; a stub charter is reserved here so the design
space is held. **Darwin** (ecology/biological framing), **Emmy** (package
architecture / public surface), and **Jason** (Julia-ecosystem scout) are
invoked ad-hoc when their lens matters — not standing reviewers.

---

## Skills wired into the team

The team routes to installed Claude Code skills rather than reinventing process.

| Skill(s) | Persona / Workflow | Used for |
|---|---|---|
| `brainstorming` → `writing-plans` → `executing-plans`, `subagent-driven-development` | Ada | Every new slice: design → plan → execute |
| `autoresearch` | **Workflow R** (Karpinski + Noether + Pólya) | Autonomous hunt for the fastest/most accurate estimator on a measured metric |
| `deep-research`, `academic-search`, `arxiv-search`, `openalex-paper-search`, `literature-review` | **Workflow S** (Pólya) | Scouting + creative-combination literature sweeps |
| `simulation-design`, `simulation-check`, `quantitative-analysis` | Curie | ADEMP recovery + coverage harness |
| `test-driven-development`, `verification-before-completion`, `systematic-debugging`, `karpathy-guidelines` | Noether, Karpinski, Curie | Engine discipline — failing test first, verify before claiming |
| `critical-code-reviewer`, `requesting-code-review`, `receiving-code-review` | Rose, Pat | Pre-publish + per-PR review gates |
| `elements-of-style:writing-clearly-and-concisely`, `anthropic-skills:doc-coauthoring`, `academic-writing-standards`, `manuscript-polish` | Pat, Florence — **Workflow D** | Documenter prose that reads as well as drmTMB's |
| `r-package-development`, `testing-r-packages`, `mirai` | Hopper, Lovelace | R-side `engine = "julia"` bridge + parity tests |
| `anthropic-skills:consolidate-memory`, `productivity:memory-management` | Ada / Shannon | Cross-session memory + periodic consolidation |
| `using-git-worktrees`, `dispatching-parallel-agents` | Ada / Shannon | Isolated parallel slices when issues are independent |

---

## Scripted workflows (`.claude/workflows/*.js`)

Real `Workflow`-tool scripts, not manual checklists. See each script's `meta`
block for details.

| Workflow | Purpose |
|---|---|
| **W0** `scaffold-team.js` | Stand up the team scaffold (this file, CLAUDE.md, ROADMAP.md, dev-log, codex agents) |
| **Q** `engine-quality-battery.js` | 7 gates: FD ≤1e-6 · cross-check ≤1e-8 · R-parity ≤1e-6 (`DRM_PARITY_TESTS=1`) · JET · Allocs · Aqua · multi-shape p∈{100,1k,10k} |
| **A** `wire-experimental.js` | Promote `src/experimental/` to the public API; fix orphan tests |
| **B** `bf-formula-frontend.js` | `bf(mu,sigma,rho12)` + markers — drmTMB-exact parity (incl. reserved-syntax rejections) |
| **D** `mirror-article.js` | Per-article: scaffold → ingest → Florence figure → Pat reader → Rose claim-vs-evidence |
| **F** `pre-publish-audit.js` | Rose-led drift + scope-honesty + missing-cell audit before every tag |
| **G** `r-parity-suite.js` | RCall.jl round-trip vs vendored drmTMB v0.1.3 outputs |
| **H** `add-family.js` | Per-family: link infra → Laplace path → ADEMP cell → article stub → R-parity gate |
| **S** `scout-and-combine.js` | Pólya's routine + phase-start scout → `idea` issues + `docs/dev-log/scout/` snapshot |
| **R** `autoresearch.js` | Estimator-optimisation loop with verify-and-revert against the verified baseline |

Workflow scripts and `.codex/agents/*.toml` **inherit the active session model**
and must not hardcode a model ID (omit `model:` in `agent()` calls and inherit
the main-loop model).

---

## Lane boundaries & merge authority

Mirrors the GLLVM.jl split. **Self-merge** (after the DoD + a Rose pass): docs,
tests, reports, dev-log, Documenter pages, workflow scripts. **Maintainer
approval required**: the public API surface, formula grammar, likelihood /
parameter contracts, version bumps, `src/` engine changes, and edits to
`AGENTS.md` / `CLAUDE.md` / `.codex/agents/`.

**Do not touch without the owning persona + maintainer sign-off:**

- `src/` core engine (Noether) — it is *verified*; never regress the 2.18× /
  logLik −256.51 baseline.
- The formula grammar contract (Boole).
- Anything that would change a published parity number (Rose audits).

**Pre-edit lane check:** before editing `AGENTS.md` / `CLAUDE.md` / `ROADMAP.md`
or `src/`, check `docs/dev-log/coordination-board.md` and open PRs for overlap.

---

## Definition of Done

A slice is done when **all** hold (mirrors the drmTMB-grade routine):

1. **Implementation** — the code works and is wired into the module.
2. **Tests** — wired into `test/runtests.jl`; a failing test was written first
   where applicable (TDD).
3. **Docstrings** — public symbols documented.
4. **Worked example** — a runnable example (or `@example` in Documenter).
5. **Check-log** — add a per-slice entry as a new file in
   `docs/dev-log/check-log.d/` (one table row; see its README). Do not append to
   the frozen `docs/dev-log/check-log.md` table — per-file entries are
   collision-free across parallel PRs.
6. **After-task report** — `docs/dev-log/after-task/YYYY-MM-DD-<slice>.md`.
7. **Rose audit** — claim-vs-evidence verdict; scope honesty; no drift.

The PR closes its issue (`closes #NN`) and uses `.github/PULL_REQUEST_TEMPLATE.md`.

---

## Contracts

### 1. Formula parity (Boole owns)

`DRM.jl`'s `bf()` must be **syntactically identical** to drmTMB's so an R user
can paste-and-run. This includes the *rejections*: the reserved-but-unsupported
syntax drmTMB errors on, DRM.jl must error on too, with parallel messages.
Anchor: **drmTMB v0.1.3**. See `docs/src/developer-notes/formula-grammar.md`.

### 2. R↔Julia bridge (Hopper + Lovelace own)

Day-1 goal, not a far-future one: R users in biology should eventually write
`drmTMB(formula, ..., engine = "julia")` and have it call DRM.jl via JuliaCall,
returning a drmTMB-shaped object. Hopper owns the parity gate (Workflow G);
Lovelace owns the R-side surface (Phase 1.5+). The bridge glue lives in the
**drmTMB (R) repo**, not here. See `docs/src/r-julia-bridge.md`.

### 3. License boundary (Rose audits every tag)

drmTMB is **GPL (≥3)**; DRM.jl is **MIT**. **Never vendor drmTMB GPL source**
into DRM.jl — that would force GPL. R-parity uses *generated outputs* of running
drmTMB (data, fitted numbers), which are not GPL source. Keep DRM.jl fresh code.

### 4. Naming & scale

Public interface uses `sigma` (never `tau`); residual correlation is `rho12`.
Group-level (phylo/spatial/study) correlations are named covariance summaries,
**not** residual `rho12`. Name the scale explicitly when comparing to DHGLM /
O'Dea-style text: effects on `log(sigma²)` are 2× effects on `log(sigma)`.

---

## Disciplines (universal)

- **Verify before claiming.** Every speed/accuracy headline in this repo was
  reproduced by an independent run. Keep that bar. Do not promote *extrapolated*
  numbers (e.g. drmTMB at p=10,000) to measured results.
- **ML is the default.** REML likelihoods aren't comparable across fixed-effect
  structures (needed for model selection). REML stays an option.
- **Local checks over CI.** Run `Pkg.test()` / benchmarks locally first; CI is
  Linux-only, PR + `workflow_dispatch`. Add macOS/Windows only before a release.
- **Evidence-first rehydration.** On resume, reconstruct repo state from
  `git status` / recent commits / `docs/dev-log/` — not chat memory.
- **Narrow-slice publish loop.** One issue → one branch → one PR → merge. Avoid
  local commit pile-ups. Reviewable PR state is part of "done".
- **Don't revert human/Codex changes** unless asked.

---

## Work ledger — GitHub Issues

The plan lives in **Issues + Milestones + Labels**, not a private file:

- **Milestones** = phases (`Phase 0 … v1.0`).
- **Labels** = `roadmap` / `enhancement` / `bug` / `documenter` / `r-bridge` /
  `workflow` / `engine-quality` / `formula-parity` / `idea` / `autoresearch` /
  `phase-*` / `status:*` (mirrors drmTMB's 5 status words) / `good-first-*`.
- **Roadmap issues** (one per milestone, pinned) carry checklists of their
  slices; article/family slices are promoted to real issues when their phase
  opens (Workflow D / H).
- After-task reports cite `closes #NN`.

**Idea dispatch:** scouting signals, creative combinations, and autoresearch
wins land as `idea` / `enhancement` issues — cross-posted to `itchyshin/gllvmTMB`
or `itchyshin/GLLVM.jl` when relevant. Nothing evaporates in chat.

---

## drmTMB parity anchor

We track **drmTMB v0.1.3 (2026-05-20)**, pinned — not the moving dev branch.
Re-anchor (and regenerate parity fixtures) on each tagged drmTMB release.
