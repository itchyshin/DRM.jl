# Handover to Cursor — DRM.jl `engine = "julia"` catch-up lane

**Date:** 2026-08-16 · **Author:** Claude (arc-loop session, 2026-08-15 → 08-16)
· **Target:** a fresh Cursor agent in this repository
· **Repo tip at writing:** `origin/main` = `0a4c2dc9` (merge of #419)

You are Cursor, picking up the DRM.jl catch-up lane. You inherit **no chat
context** — this document plus `AGENTS.md` and the current git state are the
authoritative record. Read all three before acting.

---

## Mission (the durable "why")

**G0, named by the owner on 2026-08-14:** *catch up with drmTMB's capability so
`engine = "julia"` admits what an R user actually fits.*

Close the **measured** drmTMB parity gaps in DRM.jl, each backed by a
native-vs-Julia parity fixture, **never claiming more than the R twin does**.
Anchor: **drmTMB 0.7.0** (`f5ec53634`, installed locally).

DRM.jl is MIT; drmTMB is GPL(≥3). **Never vendor drmTMB source.** Parity uses
generated outputs only.

---

## Headline: the countdown reached zero

```
COUNTDOWN: 0 export gaps (17 raw, 17 accounted for) · 11 unsupported capability rows · 14 closed gates
CLOSURE: PASS
```

Re-run it yourself — this is the lane's own scoreboard and it must be re-measured,
not trusted:

```bash
python3 tools/parity_ledger.py --drmtmb "/Users/z3437171/Dropbox/Github Local/drmTMB" --ref origin/main
```

The campaign opened at *22 export gaps*. That number was an **overcount**: 9 were
already implemented under other export names, 7 were deliberately-not-ported
(missing-data → #49 PARKED; geospatial prep → R-side), and 6 were genuinely owed.
All 6 have now shipped. A4e added a `deliberately-not-ported` class and a
name-alias map to the ledger so the count reads honestly rather than
alarmingly.

**Do not read "0" as "parity complete."** It means *no drmTMB export lacks a
DRM.jl twin*. The 11 unsupported capability rows remain, each carrying a written
`claim_boundary`. That is the next frontier, not a finished one.

---

## Mission control

| Repo | Branch / state | CI | What shipped | Next by leverage |
|---|---|---|---|---|
| **DRM.jl** | `main` @ `0a4c2dc9` | green | A4c…A6 merged (#414–#419); ledger at 0 | Watch the 9 open PRs land |
| **DRM.jl** | #420–#429, nine PRs open | **two real failures fixed** | A8–A12, rosetta fix, loop items, handover | #423's dead-`@ref` fixed; #420/#425 `gh-pages` race re-run |
| **DRM.jl** | `src/`-touching work | — | A11 cross-family formula (#428) | **Owner call — auto-merge deliberately unarmed** |
| **drmTMB** | narrow 3-file lane | — | #1032, #1038 merged | **#1049, #1050 open — STOP GATE, never merge unattended** |

---

## What was accomplished

Merged to `main` this session (#414 → #419):

| PR | Arc | What |
|---|---|---|
| #414 | A4c | `drm_phylo_penalty` + `_sweep` — penalized-MAP phylo variance components |
| #415 | A4d | `profile_targets` + `structured_effects`; two ports **refused with written reasons** |
| #416 | A4e | ledger honesty — report what is genuinely owed separately from what is accounted for |
| #417 | — | `check_drm` reports a partial covariance instead of crashing on NaN |
| #418 | A5 | native comparator `phylo_gamma_beta_binomial` parity |
| #419 | A6 | `phylo_tree_height` + fit-time tree-scale warning |

Upstream in drmTMB (narrow lane — `R/julia-bridge.R`, `tests/testthat/test-julia-*`,
`vignettes/julia-engine.Rmd` only):

- **#1036 filed and fixed (merged as #1038)** — `obj$report()` was being called at
  `last.par` rather than `last.par.best`, so a converged fit reported numbers from
  an off-optimum parameter vector. Proven with an `se=TRUE`/`se=FALSE` toggle
  showing the *same fit* reporting different values.
- **#1048 filed** — binomial responses did not accept a phylogenetic random
  effect. Fix is on **#1049, open and deliberately unmerged.**

---

## Current working state

### Working (landed, verified)

Everything through #419. `main` is green.

### CARRIED-OVER — every branch now has a PR

All nine PRs are open and pushed; nothing is at risk of loss.

| PR | Branch | What | Auto-merge |
|---|---|---|---|
| #429 | `feat/a12-biv-meta-recovery` | recovery for the known-`V` meta path + `cor12` sweep — **stacked on #423**, retargets to `main` when it merges | no |
| #428 | `feat/a11-cross-family-formula` | `drm(f::BivariateDrmFormula, fams::Tuple; …)` — mixed-family bivariate | **no — touches `src/`** |
| #427 | `docs/overnight-close-out` | plan-vs-actual for the overnight run | no |
| #426 | `handover/2026-08-16-cursor` | this document | armed |
| #425 | `fix/a10-boundary-polish` | boundary polish for a collapsed variance component (#422) + Binomial structured-marker refusal | armed |
| #424 | `docs/a9-covariance-audit` | `general_covariance_structured` — the family comparison the row asks for | armed |
| #423 | `feat/a8-biv-meta-vknown` | bivariate meta-analysis with known sampling covariance | armed |
| #421 | `fix/rosetta-corpair` | `corpair` is a formula *marker*, not a post-fit accessor | armed |
| #420 | `docs/loop-items-1-4` | tree scale surfaced; binomial × phylo wired upstream | armed |

**#428 is deliberately unarmed** — it touches `src/`, and the coordination board
pauses auto-merge on engine changes. That one is the owner's call.

**#423 was pushed to after auto-merge was already armed** — the exact
anti-pattern this document warns about below. It is recorded rather than hidden:
the PR was red and could not merge without the fix, so the push was mandatory
rather than a silent amendment. If a PR must change after arming, say so on the
PR.

**#406 (`docs/github-auto-merge`, `DIRTY`) is a pre-existing FOREIGN PR.** It was
not touched this session and must not be. It carries the durable auto-merge
decision file.

### Stale local branches (declared, not landed)

`tools/handoff_gate.sh` reports ~18 local branches with unpushed commits
(`codex/local-qgate-fd-gradient`, `shannon/*`, `ranef-slope-*`,
`worktree-agent-*`, …). **These are pre-existing and predate this session** —
they are not this lane's work and were not created or advanced here. They are
declared CARRIED-OVER for visibility only. Do not attempt to land them without
asking the owner; several belong to other lanes.

---

## Key decisions & rationale

1. **`cor_sd` penalises `atanh(cor)`, not `L21`** (A4c). drmTMB penalises the
   unconstrained correlation `eta_cor_phylo`; DRM.jl's only correlated cell
   parameterises the Cholesky off-diagonal `L21`. Penalising `L21` would be a
   *different prior*. Recovering `cor = L21/√(L21²+L22²)` and penalising
   `atanh(cor)` reproduces drmTMB's exact prior and stays closed-form
   differentiable, so the analytic gradient survives.
2. **The penalty got real `DrmFit` fields, not a `scales` key.** `sigma()`
   returns a bare vector only when `scales` has exactly one key — adding a key
   would have silently broken it. A 19-arg compatibility constructor kept ~70
   construction sites across 20 family files unchanged.
3. **Route B's Wald `V` is now the *penalized* curvature** — correct for MAP, and
   said so explicitly in the docstring rather than left implicit.
4. **Two ports were refused, in writing** (A4d): export-name gaps are not
   capability gaps, and the ledger now records the reason rather than the
   absence.
5. **Cross-family bivariate refuses `rho12 ~ …`** (A11) — cross-family ρ is a
   latent scalar, not a linear-predictor target.
6. **Deferring PRs to spare the CI queue was the wrong call, and it hid a real
   bug.** Finished work was pushed as bare branches on the reasoning that CI is
   PR-triggered, so a branch costs zero queue. That is true and it was still
   wrong: a red build is *information*, and declining to trigger it meant #423's
   dead-`@ref` sat undiagnosed while the session concluded "nothing is wrong
   with them." Cheap CI is not a reason to avoid CI.

---

## Files created / modified

Session diff for the tip arc (`git diff --name-only origin/main...feat/a12-biv-meta-recovery`):

```
LOOP/checkpoint.md
docs/dev-log/check-log.d/2026-08-16-a12-biv-meta-recovery.md
docs/dev-log/check-log.d/2026-08-16-a8-biv-meta-vknown.md
docs/dev-log/evidence/2026-08-16-a12-biv-meta-recovery.md
docs/dev-log/evidence/parity-biv-meta.tsv
docs/make.jl
docs/src/model-guides/meta-analysis.md
docs/src/rosetta.md
src/DRM.jl
src/gaussian_bivariate.jl
src/meta_vcov_bivariate.jl
test/runtests.jl
test/test_meta_vcov_bivariate.jl
tools/parity_biv_meta.R
tools/parity_ledger.py
tools/recovery_biv_meta.jl
tools/sensitivity_biv_meta_cor12.jl
```

New source files across the whole session:

- `src/phylo_penalty.jl` (A4c) · `src/meta_vcov_bivariate.jl` (A8)
- touched: `src/gaussian_core.jl`, `src/inference.jl`, `src/sparse_phy.jl`,
  `src/gaussian_bivariate.jl`, `src/sparse_laplace_glmm.jl`, `src/mixed_family.jl`,
  `src/location_only.jl`, `src/gaussian_locscale_phylo.jl`, `src/DRM.jl`

New tools: `tools/parity_phylo_penalty.R`, `tools/parity_phylo_nongaussian.R`,
`tools/parity_biv_meta.R`, `tools/recovery_binomial_phylo.jl`,
`tools/recovery_biv_meta.jl`, `tools/sensitivity_biv_meta_cor12.jl`

New docs: `docs/src/model-guides/meta-analysis.md`; 15 check-log entries and 6
evidence notes under `docs/dev-log/` dated 2026-08-15/16.

Written by this handover: this file, plus the Active-Lane-Split refresh in
`docs/dev-log/coordination-board.md`.

drmTMB (narrow lane): `R/drmTMB.R:634` (#1038 — `report(last.par.best)`) and
`R/drmTMB.R` ~20028 (#1049 — real `has_phylo_mu` fields instead of hard-coded `0L`).

---

## Next immediate steps (OWED — do these, in this order)

1. **Run lane preflight before claiming anything.**
   `python3 ~/shinichi-brain/tools/route.py DRM.jl` and
   `bash ~/shinichi-brain/tools/lane_preflight.sh DRM.jl`. Do what it prints.
   The last census saw **8 live lanes plus a foreign direct-to-main lane** in
   this repo. Name the one you take.
2. **Check what is actually red, and read the log before classifying it.**

   ```bash
   gh pr list --state open --json number,mergeStateStatus
   gh run list --workflow=Documenter --limit 10
   ```

   Seven of the nine PRs carry auto-merge and land themselves on green. If a
   Documenter job is red, `gh run view <id> --log-failed` down to the *failing
   process* — this session had one dead-`@ref` defect and two `gh-pages` push
   races that looked identical from the PR list.

3. **#428 needs an owner decision.** It touches `src/` (the A11 cross-family
   formula front end), so auto-merge is deliberately unarmed. Do not arm it
   yourself.

4. **#429 is stacked on #423.** It retargets to `main` automatically once #423
   merges. Do not rebase it onto `main` by hand — that would duplicate A8.

5. **Re-run the ledger** after each merge and record the countdown. It is the
   lane's scoreboard; a merge that moves it silently is a merge nobody can audit.

6. **Then, and only then**, pick up the 11 unsupported capability rows — that is
   the next real frontier.

Do **not** start new engine work before 1–5 are clear.

---

## Blockers / open questions

- **The `BLOCKED` PRs had two different causes, and the first reading of them was
  wrong.** They were initially written up as queue saturation with nothing
  actually broken. The Documenter logs said otherwise:
  - **#423 had a real defect.** `docs/src/model-guides/meta-analysis.md` linked
    to `` [`meta_vcov_bivariate`](@ref) ``, but that function appeared in no
    `@docs` block anywhere in the manual. Documenter runs `warnonly = true`, so
    the unresolved cross-reference was demoted to a warning and a literal
    `./@ref` went into the built page; VitePress then found a dead link and
    exited 1. A missing reference entry surfaced as an opaque npm process
    failure two stages downstream. **Fixed** — `meta_vcov_bivariate` and
    `MetaVcovBivariate` added to
    `docs/src/reference/structured-effect-markers.md`, beside `meta_V`.
  - **#420 and #425 failed on `git push upstream HEAD:gh-pages` exiting 1** —
    concurrent PR-preview deploys racing on `gh-pages`. Infrastructure, not
    code. Both re-run.

  **Carry this forward:** "the queue is busy" is not a diagnosis. `warnonly =
  true` means Documenter will **not** fail on a broken `@ref` — VitePress fails
  later, with a message naming npm rather than the link. Read the log down to
  the actually-failing process before classifying a red docs job.
- **drmTMB #1049 and #1050 are open and deliberately unmerged.** That tree
  carries 9 live lanes, a foreign codex lane, and the open 0.7.0 release slice
  #959. Merging there is **owner-gated**.
- **#422 root cause is understood but the fix is unmerged** (#425): DRM.jl's own
  objective was lower at drmTMB's optimum by 7.3e-05; mixed-vector attribution
  put the whole deficit in β coordinates.

---

## Gotchas / failed approaches (read this — several cost real time)

1. **The tree-scale trap, walked into twice in one day.** `ape::vcv(corr=TRUE)`
   gives unit tip variance; raw Newick branch lengths give tip variance = tree
   height `h`. A simulation DGP that ignores this produces a convincing ~30%
   "variance-component bias" that is entirely your own error. It was caught by
   checking the magnitude against the `√h` mechanism: predicted −29.3%, observed
   −29.4%. **If you see a clean ~30% bias in a phylo variance component,
   suspect your DGP before the engine.**
2. **`drm_pin_tmb_object_to_optimum()` MUTATES `obj$env$last.par`.** Using it to
   fix drmTMB #1036 caused three regressions (FAIL 3 vs a baseline of FAIL 0).
   Only a *concurrently run baseline check* made that attributable. Pass the
   parameter vector instead — a read, not a side effect.
3. **Julia top-level `for` loops don't close over outer scalars.** `conv += 1`
   became a local while `push!` mutated the shared vector, producing
   "0/30 converged" alongside 30 summary values. Caught by the internal
   contradiction, not by any test.
4. **`$` in a Julia docstring interpolates.** `tree$edge.length` in a docstring
   became `UndefVarError: edge not defined`, caught only by the FULL suite, not
   by targeted tests. Escape it.
5. **Never define a function as `f(x) = …` inside multiple branches** — that is
   method overwriting and fails precompilation. Use a local lambda.
6. **Do not arm auto-merge and then push again.** This happened on #425. One
   branch per arc; **auto-merge is the LAST action on a branch.**
7. **Backticks in commit messages get executed by the shell** — one silently
   deleted a clause. Use a quoted heredoc, and re-read what actually committed.
8. **Do not split test specs on `|`** — it collides with `(1|species)` and
   produced three bogus "REFUSED" lines in an audit.
9. **`check_drm` returns a key tuple that a test asserts exactly.** Adding a key
   (`penalized_map`, then `vcov_complete`) breaks that test *and* the docstring.
   Update all three together.
10. **Tolerances must be MEASURED across seeds**, never fitted to one run. This
    is a repo contract, not a preference.

---

## How to resume — environment and commands

**Working directory** — use the lane worktree, not the Dropbox checkout:

```bash
cd /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
export PATH="$HOME/.juliaup/bin:$PATH"
```

**Never `git checkout` in the shared drmTMB tree** (`/Users/z3437171/Dropbox/Github Local/drmTMB`)
— it carries 9 live lanes. Use a temporary worktree if you need a different ref there.

**Safe verification** (targeted; the full suite is ~40–56 min and is CI's job):

```bash
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test(test_args=["meta_vcov_bivariate"])'
```

**Parity fixtures that must not regress:**

```bash
DRM_JL_PATH=$(pwd) Rscript tools/parity_fixture.R     # must stay 7/7
DRM_JL_PATH=$(pwd) Rscript tools/parity_associate.R   # must stay 5/5
```

**Any change to `bf()` / formula grammar makes `DRM_PARITY_TESTS=1` mandatory**,
and its output must be attached to the PR. That rail replaces human grammar review.

**Files you must NEVER stage:** `.worktrees/`, `.codex/agents/shannon-coordinator.toml`.
**Never `git add -A`** — stage explicit paths only.

---

## Standing fences (PROTECTED — do not violate)

- **Issue #136 stays OPEN.** Never put `close`/`fix`/`resolve` next to that number.
- **drmTMB is a STOP GATE.** Open PRs there; **never merge unattended.** #1049
  and #1050 are open by design.
- **#49 / FIML / missing data is PARKED** — this also holds `categorical`.
- **No Registrator / Julia General registration** (D-111).
- **No GPL vendoring.** drmTMB is GPL(≥3); DRM.jl is MIT.
- **Never regress the verified q=4 core** (2.18×, logLik −256.51).
- **Go easy on this Mac's CPU** — the owner asked explicitly. Prefer targeted
  tests over full suites; let CI carry the long runs.
- One issue → one branch → one PR; **auto-merge armed last**.
- Auto-merge is OFF-limits for: `src/` engine, formula grammar, version bumps,
  `AGENTS.md`, `CLAUDE.md`, an unfinished epic, or a foreign lane.

---

## Definition of Done (from `AGENTS.md`)

impl + tests + docstrings + worked example + `docs/dev-log/check-log.d/` entry +
after-task report + Rose audit.

---

## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-16-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
