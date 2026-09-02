# Decision map — true R↔Julia parity (DRM.jl half), 2026-09-02

Date: 2026-09-02
Owner lane: Claude, DRM.jl (worktree `docs/true-parity-decision-map`, off `origin/main` `d6519d21`)
Twin document: drmTMB `docs/dev-log/2026-09-02-true-parity-decision-map.md` (branch `claude/rev-parity-handover`)
Status: a map, not a build plan — records what is decided, what is fog, what is out
Vault: D-203 (written this session, vault commit `e7fc8d8`), cross-ref D-202 (`~/shinichi-brain/memory/DECISIONS.md:7339`)

## Destination

Every native drmTMB capability admissible under D-179/D-181 is reachable in Julia directly and
through `engine = "julia"`, with same-target point **and SE** receipts on both engines
(`~/.claude/plans/jazzy-drifting-piglet.md`, DECISION MAP). `engine = "julia"` shows the coefficient
names `engine = "tmb"` shows — base-R canonical, DRM.jl echoes (#467 construct suite 7/7). A
cross-engine dispute is settled by committed functions on both sides (`objective_at()` in R ↔
`reml_objective_at` in Julia). Every registered warm workflow beats R (`LOOP/GOAL.md`'s "every
registered warm full-workflow benchmark must beat a comparably configured R baseline") or the loss
is retained and named (#563 G5). The scoreboard's bridge axis (`docs/src/drmtmb-parity.md`) carries
`partial`/`covered` only where receipts exist, promoted by draft PR + owner merge. Releases and
registration stay owner ceremonies (D-164, D-183). This reconciles the jazzy-drifting-piglet plan's
DECISION MAP with `LOOP/GOAL.md`'s "Immutable choices": one destination, described twice by two
lanes that had not yet compared notes.

## Decisions so far


> **Standing rule vs this arc's scope (D-204, drmTMB session, 2026-09-02):** Shinichi: *"both ways for user-facing; keep the legacy rewrite; file the issues."* The standing principle is parity **both ways for user-facing capabilities**; D-203 §1's "one-directional" is the **scope of this DRM.jl arc**, not the principle. The drmTMB lane is filing the four user-facing reverse-gap issues from the AHEAD-OF list below. **D-203 §5 (same day):** the supported `(payload, φ)` bridge entry is approved PR-gated → PR #587.

| decision | date | who | where recorded |
|---|---|---|---|
| Cross-family permanent boundary; intervals capability-parity not coverage; `mi()` fenced; #471 Student-only out (D-179 #1–4) | 2026-08-27 | Shinichi | vault D-179 |
| `mi()` fenced for v1.0; intervals permanent-permanent; #471 out-documented; registration open (D-181 #1–4) | 2026-08-28 | Shinichi | vault D-181 |
| v1.0 waves M/Q/I/A/R decisions 1–3 adopted as recommended; #4 (registration) open | 2026-08-28 | Shinichi | vault D-180; `docs/dev-log/plans/2026-08-28-v1.0-roadmap.md` |
| Twin versioning, v0.7.0 tagged unregistered | 2026-08-28 | Shinichi | vault D-183 |
| #563 full native-R parity programme approved; immutable choices fixed | 2026-08-30 | Shinichi (Codex task `01a05261-cd5c-7ca3-a654-cebea9f187fb`) | `LOOP/GOAL.md`, `docs/dev-log/plans/2026-08-30-julia-r-parity.md` |
| drmTMB reverse-parity: push 18 branches; #1112 first; `cov.fixed` conditioning + unpenalised `objective_at()` confirmed; naming authority = base-R (D-202) | 2026-09-02 | Shinichi (drmTMB lane) | `~/shinichi-brain/memory/DECISIONS.md:7339`; drmTMB `docs/dev-log/2026-09-02-rev-parity-owner-decisions.md` |
| Four decisions below (D-203) | 2026-09-02 | Shinichi (this session) | this map; vault `memory/DECISIONS.md` D-203 (commit `e7fc8d8`) |

**D-203 — the four decisions of this session, verbatim in substance:**

1. **Direction.** Parity is **one-directional** (R → Julia) for this arc. The reverse gap (Julia
   capabilities with no drmTMB counterpart) becomes a drmTMB **issue list**, drafted below, filed by
   the drmTMB lane after Shinichi sees it — not work performed here.

2. **Ownership of the remaining DRM.jl-side #563 slices (S5–S12).** The **Claude DRM.jl lane**, in
   a **fresh task** after this 2026-09-02 close-out, **resuming** the codex ledger at
   `/private/tmp/drm-parity-20260830/DRM.jl/.unlazy/julia-r-parity` (149 met / 46 unmet, measured
   this session — see Three programmes below) rather than rebuilding it. Context: no Codex or Cursor
   lane is running (Shinichi, 2026-09-02, this session); an earlier answer in the same session read
   "Codex continues" and is **superseded** by this one.

3. **Both protected `src/` edits APPROVED, PR-gated** (each its own PR, failing test first,
   Noether + Rose review, Shinichi merges): (a) the S5a sparse-precision replacement — two identical
   edits, `src/gaussian_structured.jl` `_phylo_aug_comp` and `src/gaussian_sparse_lss.jl`'s precision
   initialisation, per `s5a.md`'s proposed patch (`Qs = dropzeros!(sparse(Symmetric(Q, :U)))`); (b)
   the label-map echo in `src/bridge.jl` — payload-supplied base-R names echoed under
   `bridge_formula_labels_v1` (design 258 §7 on drmTMB branch `claude/rev-parity-c2-label-producer`
   @ `af1790492` (supersedes `5b77eb691` after an adversarial pass; R now rejects any returned map whose public names are not its per-dpar `coef_labels` verbatim and in order), on origin: payload `coef_labels` per dpar; echo = `coef_label_contract` /
   `coef_names` / `raw_coef_names` / `coef_name_map` / `vcov_names`; the R half is implemented and
   fail-closed). The drmTMB lane's handoff memo for the Julia half:
   `docs/dev-log/2026-09-02-drmjl-lane-handoff.md` on `claude/rev-parity-drmjl-findings`.

4. **Promotion authority** on the bridge axis (scoreboard `docs/src/drmtmb-parity.md`) = a
   Rose-scanned draft PR + Shinichi's merge. No per-row sentence.

**Julia-side facts settling two drmTMB fog tickets** (from the drmTMB map's "Not yet specified"
table): DRM.jl already emits `coef_label_contract = "bridge_formula_labels_v1"`
(`src/bridge.jl:1276`) — the remaining half (decision 3b above) is echoing payload-supplied names
rather than reconstructing them. "Non-Gaussian phylogenetic location-scale (μ + log σ)"
(`src/locscale_*.jl`) is **implemented** in DRM.jl (`closes #202`;
`docs/dev-log/decisions/2026-06-06-nongaussian-phylo-location-scale.md`;
`docs/design/capability-status.md:78`) — **unprojected** on drmTMB's 12-row
`inst/extdata/julia-capabilities.tsv`; the drmTMB lane decides its own board row from its own
`cells.tsv` (its map records drmTMB natively covers this only for `nbinom2`/`zero_one_beta`, the
rest `rejected_by_design`).

## Three programmes, one ledger view

| programme | owner | plan / ledger paths | measured state today (2026-09-02) |
|---|---|---|---|
| **#563 full native-R parity** | Codex lane `01a05261`, resumed per D-203 §2 by Claude DRM.jl lane | `docs/dev-log/plans/2026-08-30-julia-r-parity.md`; `/private/tmp/drm-parity-20260830/DRM.jl/LOOP/GOAL.md`, `arcs.md`; `.unlazy/julia-r-parity` | `gate-check --status --scope julia-r-parity`: **149 met / 46 unmet**, root gates `GATES:G0`–`G8` all still open; S5a **PROPOSAL ONLY, now approved** (D-203 §3a); PRs #567–#576 per triage table below |
| **drmTMB reverse-parity** | Claude lane drmTMB2 | `~/.claude/plans/piped-dancing-floyd.md`; decision map + D-202 on `claude/rev-parity-handover` | 18 branches pushed; draft PR #1114 "after #1112"; **44/55** gates met, 11 HELD; S4 = q4 Wald-SE receipt (pins DRM.jl `cda42b8c`) |
| **DRM.jl v1.0 roadmap** | this lane | `docs/dev-log/plans/2026-08-28-v1.0-roadmap.md` (waves M/Q/I/A/R; D-180); `.unlazy/lss-true-parity` (main checkout) | LSS true-parity arc **4/4 met** (G1–G4, `GATES.md`); #575 fixed on PR #579; scoreboard PR #576 — 12 rows, every bridge row `experimental` by construction, 10 `covered`/1 `partial` (permanent, D-179 #3)/1 `unsupported` by design |

### Codex PR triage (copied from `scratchpad/codex-pr-triage.md`)

| PR | Title | Head | Mergeable / State | Behind main | src?/test? | Checks | First failure |
|:--:|-------|------|-------------------|:-----------:|:----------:|--------|---------------|
| 567 | fix: retain location-scale SD inference targets | codex/sigma-phylo-inference-contract | MERGEABLE / BEHIND | 3 | y/y | test(1.10) OK, docs OK, test(1) OK | — |
| 568 | docs: clarify sparse phylogenetic LSS capacity | codex/lss-sparse-capacity-guidance | MERGEABLE / BLOCKED | 0 | y/y | test(1.10) **FAIL** | test_locscale_profile_threads.jl:52 |
| 571 | fix: stabilize public LSS fit before threaded profiling | codex/profile-thread-fit-budget | MERGEABLE / CLEAN | 0 | y/y | all OK | — |
| 573 | feat(bridge): export route-aware convergence diagnostics | codex/julia-bridge-route-diagnostic | MERGEABLE / CLEAN | 0 | y/y | **NO CHECKS REPORTED** | CI run 33529843385 FAIL |
| 574 | Fix sparse phylogenetic variance boundary | codex/loconly-numerical-boundary | MERGEABLE / BLOCKED | 0 | y/y | test(1.10) **FAIL**, test(1) **FAIL** | test_bootstrap_marginal.jl:136 |
| 576 | docs: R↔Julia parity scoreboard | docs/drmtmb-parity-scoreboard | MERGEABLE / CLEAN (DRAFT) | 0 | n/n | all OK | — |

#567 and #571 are green and mergeable (567 needs a rebase). #573 and #574 share the same
`test_bootstrap_marginal.jl:136` assertion failure (`res.failed > 0` evaluates `0 > 0` — a degenerate
optimum not reported as converged), suggesting one root cause in location-only/sparse-phylo boundary
handling. #568 fails a separate finite-check assertion in threaded profiling. #576 is green and
draft.

## Not yet specified

| ticket | kind | default |
|---|---|---|
| Reverse-gap list contents (below) | task, drafted here | file as drmTMB issues by the drmTMB lane, on confirmation — not here |
| `rtol_coef = 10%` re-derivation on `biv-q4-phylo-reml` `[tol]` — the drmTMB S4 receipt now exists (`claude/rev-parity-q4-se-receipt` @ `996870366`, `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.{md,R}`, engine pinned `cda42b8c`: coef + logLik agree, \|Δ\| 1.9e-05, 7/7 names; TMB Wald SEs finite). The Julia bridge `vcov()` on this route is all-NaN (`uncertainty$status = "unavailable"`) — that is the fixture's **recorded fence** `interval_status = "wald_unavailable"` (`expected.meta.toml:22`), not a new defect; the tolerance was always sized from drmTMB's own Wald SEs (`reml_restriction_note`), so the receipt unblocks the re-derivation | task, this lane (fresh task, C10) | decide the fraction (1% per #483's exact-gradient precedent vs the withdrawn 10%), edit `[tol]`, rerun the 33-assertion fixture test + #575 tests, own PR |
| Red codex PRs #568 (test 1.10 fail) / #574 (test 1.10 + test 1 fail); #573 (no checks reported, CI run failing) | task, Codex lane / D-203 §2 successor | repair or close; #567/#571 merge when green (Shinichi merges) |
| Is #563's G5 "every warm workflow wins" still the bar, or is a retained loss acceptable for v0.7.1? | decide-with-Shinichi, **not blocking** | keep #563's wording (a loss keeps the programme open) |

## Out of scope

- **Two-directional parity** — D-203 §1 fixes this arc as one-directional; the reverse direction is
  an issue list, not work.
- **DRM.jl engine slices S5–S12 of #563** — belong to the #563 executor (D-203 §2: Claude DRM.jl
  lane, fresh task, after this close-out).
- **`mi()`, interval coverage campaigns, cross-family native TMB, #471** — permanent/fenced
  boundaries (D-179, D-181).
- **Releases and registration** — owner ceremonies untouched here (D-164, D-183).
- **Any edit to drmTMB** — a live foreign lane; read-only via `git show` in this session.
- **Coordination-board append** — divergent refs across the three lanes.
- **Merging anything** — #579, the docs PR from this map, or any codex PR: owner's call.

## Reverse gap (drafted, not filed) — the AHEAD-OF list

Per the shared direction page (drmTMB2 → all four lanes, 2026-09-02, point 5), Julia-only user-facing
exports are listed as **AHEAD-OF** with a written reason; this table is that list for DRM.jl.

Nine DRM.jl-exported, user-facing functions (`src/DRM.jl` `export` block) verified against drmTMB's
`NAMESPACE` `export()` list (`git -C drmTMB show origin/main:NAMESPACE`) — none of the nine names
appears there. `reml_objective_at`, named as a candidate in the destination text, is **not** in
DRM.jl's export list and is excluded (it is an internal/committed function, not a public export, so
it is not a reverse-gap candidate here). All nine below classify cleanly; **0 unclassified**.

| Julia name | what it does | suggested drmTMB issue title |
|---|---|---|
| `chibar_pvalue` | Chi-bar-square (χ̄²) boundary-corrected upper-tail p-value for a variance-component LRT statistic — corrects the naive χ²(q) reference, which is conservative at a boundary (`src/chibar.jl`) | Add chi-bar-square boundary-corrected p-value for variance-component LRTs (`chibar_pvalue`) |
| `lrt_boundary` | Boundary-corrected likelihood-ratio test for `q` variance components = 0, comparing two nested ML-fitted models (`src/chibar.jl`) | Add boundary-corrected LRT for variance-component-zero tests (`lrt_boundary`) |
| `heritability` | Phylogenetic heritability/signal (λ / H²) of a structured-Gaussian fit — share of total variance carried by one structured component (`src/heritability.jl`) | Add phylogenetic heritability/signal accessor (`heritability`) |
| `icc` | Intraclass correlation / repeatability for one grouping factor, `σ²_component / (σ²_component + σ²_resid)` (`src/heritability.jl`) | Add intraclass-correlation accessor (`icc`) |
| `repeatability` | Alias for `icc`; adjusted repeatability for the chosen grouping factor (`src/heritability.jl`) | Add repeatability accessor (alias of `icc`) |
| `aicc` | Corrected AIC — small-sample second-order correction to `aic`, `AICc = AIC + 2k(k+1)/(n-k-1)` (`src/comparison.jl`) | Add small-sample-corrected AIC (`aicc`) |
| `coevolution_cor` | Among-axis correlation matrix of a q=4 phylogenetic bivariate location-scale ("coevolution") fit — the 4×4 group-level correlation between `(mu1, mu2, sigma1, sigma2)` (`src/coevo_accessors.jl`) | Add among-axis correlation accessor for q=4 coevolution fits (`coevolution_cor`) |
| `coevolution_vc` | Per-axis phylogenetic variance components of a q=4 coevolution fit — diagonal of the group-level covariance and matching SDs (`src/coevo_accessors.jl`) | Add per-axis variance-component accessor for q=4 coevolution fits (`coevolution_vc`) |
| `coevolution_summary` | Tidy summary of a q=4 coevolution fit's among-axis structure, combining `coevolution_vc` and `coevolution_cor` into long-form vectors (`src/coevo_accessors.jl`) | Add tidy summary accessor for q=4 coevolution fits (`coevolution_summary`) |

Per D-203 §1, this list is **drafted for Shinichi's review here**; filing these as drmTMB issues is
the drmTMB lane's action, not performed by this session.

## Sweep receipt

| surface | evidence it ran | finding | call |
|---|---|---|---|
| DRM.jl git/ledgers | Haiku scout `recon-drmjl-parity` (`gh` issue/PR lists, `git show origin/main:…`, `.unlazy/*`); `branch_drift_check.sh` (local main 89 behind) | LSS arc closed 4/4; scoreboard 12 rows all-experimental on bridge axis; 13 open parity issues (#563 umbrella, #546, #467, #527, #569, #578…) | **resume** #563, don't rebuild |
| codex programme | `LOOP/GOAL.md`, `arcs.md`, `checkpoint.md` (tail), `gate-check --status --scope julia-r-parity` → 149/46; `s5a.md` | approved programme with waves A–E, gates G0–G8; S5a needed owner src approval; 2 PRs red | **reuse** its ledger as the DRM.jl parity ledger; D-203 §2 names the successor |
| drmTMB | Haiku scout `recon-drmtmb-parity`; `git show claude/rev-parity-handover:docs/dev-log/2026-09-02-{true-parity-decision-map,rev-parity-owner-decisions}.md`; design 258 on `claude/rev-parity-c1-naming-spec` | map + D-202 exist; fog: direction, promotion authority, NG-phylo-LSS row, label echo, `rtol_coef` | **co-opt** the map; answer the Julia-side tickets |
| brain semantic | `search_notes("R Julia true parity programme drmTMB DRM.jl bridge engine julia capability status decision", all projects)` | bridge after-tasks 2026-06; hsquared bridge-compat matrix (pattern) | reuse pattern only |
| brain grep | Haiku scout: `grep -in "true parity" memory/AGENT_LOG.md` (0); DECISIONS D-111/D-58/D-94/D-164/D-183; OPEN_QUESTIONS (0); journal (3, none on-topic); dr-notes (REML bias only) | no "true parity" decision beyond D-183 twin versioning; D-202 written today by drmTMB2 | build-the-gap = one map |
| session dialogue | AskUserQuestion 2026-09-02 (this session) | 4 answers, D-203 §1–4; ownership (§2) corrected mid-session — see note in §2 | locked |

## Execution log (appended 2026-09-02, same session, after the owner moved the #563 remainder to this lane)

| slice | PR | state |
|---|---|---|
| S5a sparse precision (two conversion sites) | **merged** as #591 (`d1c7de73`; draft #581 closed, GraphQL-budget reason) | RED→GREEN test, five neighbour files green, after-task + check-log; ledger `.unlazy/563-s5a` all met |
| `[tol]` re-derivation, `biv-q4-phylo-reml` (10% → 1%, from receipt `996870366`) | **merged** as #588 (`57bd251d`; draft #582 closed — GraphQL budget blocked undrafting, same branch) | 33/33, 1/1, 12/12; #579 merged first (`f930e8bf`, closes #575) |
| `capabilities.md` drift (six false claims) | **merged** as #592 (`5583e176`; draft #583 closed, same reason) | corrected in place with dated strike-throughs; flags `mi` export (`src/DRM.jl:195`) vs D-181 #1 for the owner |
| bridge names = base-R (measurement) + stale fixtures re-keyed | **merged** as #593 (`a929e7af`; draft #584 closed, same reason) | DRM.jl's own rendering already matches base R on all ten design-258 constructs (20/20); the six `bridge-*` fixtures were keyed by pre-`62c4e6a2` names → re-keyed, 1/7 → 7/7 under `DRM_PARITY_TESTS=1`. **Design 258 §2 row 7 is wrong** (nine-name full-dummy list; base R gives six, reduced coding) — reported to the drmTMB lane |
| label echo (`coef_labels` → `bridge_formula_labels_v1` verbatim, fail-closed on count) | **merged** as #594 (`be7b7ce5`; draft #585 closed, same reason) | wire field = `options["coef_labels"]` (drmTMB `a17306295`); RED 5 cases → GREEN 28/28, neighbours 819/819 and 20/20; `<dpar>_<name>` form confirmed against R's `drm_julia_bridge_check_coef_labels()` (`f0b7c4da9`) |
| codex PR triage | comments on #568, #573, #574 | #568 pre-existing on `main` (merge #571 first); #574's `_loconly_resolvable_scales` guard turns the #461 degenerate fixture away before the refit stage (`res.failed > 0` → `0 > 0`) — a guard-vs-guard contract decision for Noether/Fisher + owner; #573 inherits it (contains `ff12403f`) |
| `reml_objective_at` diagnostic primitive (cross-engine objective at a point) | **merged** as #589 (`5f9e4b8e`; draft #586 closed, same reason). Pins re-derived on the exact-gradient head first: Julia's own point −219.614005, TMB-point value −219.620508 unchanged, the mode-finder inequality inverts (5/5) | needed by drmTMB A4/A5 (`claude/rev-parity-a4-objective-at-bridge` @ `1291772bc`, pinned to `dc3ce190`); their 2×2 receipt reproduces the #575 mode-finder gap (DRM.jl at TMB point −219.620688 vs TMB −219.613986). Pins to re-run after #579. **Proposed, not built (owner sign-off needed):** one supported bridge entry `(payload, φ)` so R stops depending on five DRM.jl private names (#569 territory) |
| `drm_bridge_objective_at` — supported bridge entry (payload + β, Λ, ρ12) | **merged** as #590 (`e4647333`; draft #587 closed, GraphQL-budget reason; Julia-point pin re-derived to −219.614005 first, 17/17) | RED → GREEN 17/17; reproduces the A5 receipt at both points (atol 2e-4); equals the private path at 1e-8; neighbours 5/5, 819/819, 188/188; drmTMB shim can drop its five private-name dependencies (R replacement call sent) |

**Merge sequence, 2026-09-02 (Shinichi's order):** #579 → #588 → #589 → #590, then #591 → #592 → #593 → #594, then this map. Every draft that could not be marked ready over REST (GraphQL budget exhausted) was closed and recreated ready on the same branch and commit; numbers above are the merged PRs.
