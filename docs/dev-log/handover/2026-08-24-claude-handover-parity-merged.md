# Session Handoff: parity catch-up MERGED — interval axis landed, three engine defects fixed

Meta: 2026-08-24 · from **Claude Code** (Shannon) · TARGET **claude** · AUTHOR **claude**

You are **Claude Code**, picking up **DRM.jl** with **no chat context**. Rehydrate from this
repository + current git state. Classify every item **`OWED` · `DONE` · `RETRACTED` ·
`PROTECTED`**; execute only `OWED`.

**Supersedes as DRM.jl START HERE:**
[`2026-08-24-claude-handover.md`](2026-08-24-claude-handover.md) — that one described a
vacation STOP with the lane IDLE. That STOP was **lifted by the owner the same day**. Keep the
file; treat it as historical.

## Critical Context

1. **`origin/main` @ `acf3d4fb3`** — Merge of [#458](https://github.com/itchyshin/DRM.jl/pull/458)
   (20 commits, 65 files). Confirm with `git fetch origin && git rev-parse --short origin/main`.
2. **The lane is NOT idle and the old fence is lifted.** Mission Control's `do_not_repeat` used
   to say *"Do not start the 11 capability rows"*. Shinichi lifted that on 2026-08-24 by naming
   R↔Julia parity as the G0 and authorising DRM.jl chip flips. The MC entry has been corrected
   in place (a dated `SUPERSEDED 2026-08-24` line prepended; nothing deleted).
3. **A SECOND DRM.jl LANE OPENED at ~21:30 on 2026-08-24, while this handover was being
   written** (`drm-jl-2b`, owner-confirmed). **Treat this repo as MULTI-LANE (D-88).** Before
   claiming any shared file, run `~/shinichi-brain/tools/lane_preflight.sh --file <path>` and
   `tools/lane_lease.sh --claim DRM.jl --paths <...>`. A **REFUSED** lease means it is not safe
   to run concurrently — narrow the paths or go sequential, never bypass it. If the lanes
   genuinely overlap, surface it to Shinichi; ownership is his call, not yours (D-87).

   Two separate things will both look like "a foreign lane", so distinguish them by timestamp:
   `git log --format='%h %ad %s' --date=format:'%H:%M' -5 origin/main`.
   - A tip at **`acf3d4fb3`** (the #458 merge) is *this handover's author*. `lane_preflight.sh`
     flags it as `FOREIGN LANE ACTIVE (direct-to-main)` only because every commit here carries
     Shinichi's identity and the tool cannot tell one author from another.
   - **Anything newer than `acf3d4fb3` is the other lane, and is real.** Do not dismiss it.
4. **drmTMB — CORRECTED 2026-08-24 ~24:00, read this carefully; the original text was wrong
   in one part and is DISPUTED in another.**

   - **VERIFIED FACT (measured, corrected):** drmTMB is now **CLEAN — 0 dirty files.** The 102
     uncommitted files this handover originally reported were committed by a Codex lane to
     `codex/rescue-claude-handover-freshness-0718-20260824` (branch confirmed to exist). The
     dirty-set hash pinned above, `0c7636897a95929a…`, is **STALE**; the tree now hashes to the
     empty-set value `e3b0c44298fc1c14…`. Do not use the old hash as a tamper check.
   - **DISPUTED, NEEDS OWNER CONFIRMATION:** this handover originally said *"Do NOT edit
     drmTMB — CRAN prepare-only quiesce."* The concurrent lane `drm-jl-2b` reports that
     **Shinichi lifted that in its session**, on the [[DECISIONS#D-164|D-164]] reading that the
     hold is on **submission**, not on the package ("reversible work on drmTMB continues as
     normal"), and that **both repos are in scope** for its G0.
     **This author could not verify that** — it is a peer's report of an owner instruction given
     in another session, and a peer cannot grant an escalation. So: **do not treat drmTMB as
     open on the strength of this paragraph.** Confirm with Shinichi first. What is NOT in
     dispute either way: no `submit_cran`, no tag, no release announcement — D-164's hold on
     *release* stands regardless.

## What Was Accomplished

- **An SE / interval axis the harness never had.** `compare_se` + optional `[se]` fixture block,
  wired into `compare_fit` and `compare_bridge`, parsed by `loadfixture.jl`, plus
  `tools/parity_se.R`. This is the axis drmTMB's own q4 `claim_boundary` names as blocking
  ("interval reliability"). Agreement 2.17e-06 / 1.84e-06 / 4.98e-07 across three cells.
- **Four capability rows gained live same-target evidence:** `plain_binomial_nonphylo`
  (2.48e-13), `phylo_count_large_p` (Poisson + NB2 at p=300), `general_covariance_structured`,
  `biv_gaussian_residual`.
- **All 11 canonical fixtures re-measured at drmTMB 0.7.0** (were frozen at 0.6.0), seeds
  preserved: **zero drift**.
- **The interval trio measured:** Wald at parity through the bridge (width ratio exactly 1.000);
  profile agreeing **1.2e-06** natively; bootstrap now agreeing (width ratio 0.88, from 1674×).
- **Speed:** DRM.jl 2.2–12.5× faster across ten fit cells, logLik agreeing.
  `fit$bridge$iterations` now crosses the bridge (was `NA` everywhere).
- **Three engine defects found by the measurement and fixed:** #459, #461, #462.
- **Three latent harness bugs fixed:** `compare_fit` discarding declined SE names,
  `gen_fixtures.R` destroying hand-written `[tol]` overrides, `parity_biv_meta.R` broken on
  paths containing a space.
- **New tools:** `tools/parity_crosscheck.py`, `tools/parity_intervals.R`,
  `tools/parity_classc.R`, `tools/bench_fit_h2h.R`, `tools/bench_bootstrap.R`,
  `tools/check_test_deps.py`.

## Current Working State

- **Working:** `main` @ `acf3d4fb3`. Full suite **304 testsets, zero failures**. CI green on
  both Julia versions. `tools/parity_ledger.py` → `0 export gaps · 11 rows · 14 gates`,
  **CLOSURE: PASS**. `tools/check_test_deps.py` → clean, 178 files.
- **In progress:** nothing. Everything is merged — #458 (`acf3d4fb3`) and this handover kit
  itself (#463, `04a69c2a5`). *(The original wording "no branch of this session is unlanded" was
  written while #463 was still open; resolved by that merge.)*
- **Concurrent lane:** `drm-jl-2b` opened ~21:30 on branch `feat/drmtmb-catchup`, G0 = *"catch up
  with drmTMB, then complete the package"*. It has **confirmed no overlap** with anything in this
  handover's What Was Accomplished, and reports claiming: **#460**, the **interval-coverage
  campaign** (Totoro **and DRAC**, SLURM job arrays, D-139 smoke-then-approve), **`niterations`**
  in the remaining fitters, plus DRM.jl-side gaps this session did not touch (bivariate `:REML`
  and coupled phylo REML; structured markers for bivariate Student/LogNormal; 9 orphan test
  files; bridge formula functions `I()`/`poly()`/`scale()`/`factor()`/`(...)^k`).
  **So the three "candidates" listed under Next Immediate Steps below are CLAIMED — do not
  start them without checking with that lane or Shinichi (D-87).**
- **Blocked:** [#460](https://github.com/itchyshin/DRM.jl/issues/460) — profile and bootstrap
  CIs for ordinary fixed effects through `engine = "julia"`. Both engines implement them and
  agree natively, so it is **bridge routing in drmTMB's `confint.drmTMB_julia()`**, blocked by
  CRAN quiesce. Not DRM.jl work.

## Key Decisions & Rationale

- **Evidence, not promotion.** No capability row is `supported` anywhere. Each promotion becomes
  a one-line TSV edit backed by a measured number, later — in drmTMB, when quiesce lifts.
- **No coverage claim.** SE *agreement* between two engines is not interval *coverage*. Both
  `interval_status != "coverage_claimed"` assertions in `test/test_parity_*.jl` are intact and
  **must stay**. A coverage claim needs a simulation campaign, not a day.
- **`is_converged` is now STRICTER than `fit.converged`** (#461). It rejects a degenerate
  optimum — residual scale below 1e-6 × response SD — because the Gaussian likelihood is
  unbounded as σ → 0 and `Optim.converged` returns `true` there. A fit that previously reported
  `true` at such a point now reports `false`. That is intended. `fit.converged` still exposes
  the raw optimiser flag.
- **The bootstrap simulator asks `predict(fit, data)` for the fixed-effect mean** rather than
  unpicking `fit.means[:mu]`. Whether that field is conditional or marginal varies by route and
  does **not** track whether BLUPs exist (measured: phylo = BLUPs + conditional; relmat = no
  BLUPs + marginal; ordinary `(1|g)` = BLUPs + marginal). Do not "simplify" this back to a rule.
- **AGHQ chip flipped `missing → implemented`** on the ledger's own criterion (source + a
  registered test) after #449, with scope narrowed in prose: Poisson `(1|g)` only, `:REML` not
  wired to `:AGHQ`. Tally 40/1/1/4 → **41/1/1/3**.

## Landing State

`handoff_gate.sh` output at time of writing, annotated:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `acf3d4fb3` | y | y | #458 **MERGED** | **LANDED** |
| `parity/se-axis` (20 commits) | y | y | #458 merged | **LANDED** |
| Issues #457, #459, #461, #462 | — | — | closed | **LANDED** |
| Mission Control `status/drmTMB.json` | y (vault `f8c3872`) | n/a — vault is local-only (D-37) | none | **LANDED** |
| [#460](https://github.com/itchyshin/DRM.jl/issues/460) | — | — | open | **CARRIED-OVER** — drmTMB-side bridge routing; blocked by CRAN quiesce. Resume: only when the owner says quiesce is lifted, then work in the **drmTMB** repo, not here. |
| #420 / #406 | y | y | open, **DIRTY** | **CARRIED-OVER** — leave OPEN per scout #455. Do not rebase. |
| 36 unpushed commits on ~22 stale branches | y | n | none | **CARRIED-OVER** — pre-existing, predates this session. Ignore unless the owner names one. |
| `.codex/agents/shannon-coordinator.toml` | n | n | none | **PROTECTED** — never stage. |
| drmTMB 102 dirty files on `claude/handover-freshness-0718` | n | n | none | **CARRIED-OVER (other repo)** — not ours; flagged to the owner. |

## Next Immediate Steps

1. **OWED — rehydrate.** `cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"`, then
   `~/shinichi-brain/tools/lane_preflight.sh` (read §Critical Context 3 before reacting to its
   verdict), `git fetch origin && git status -sb && git log --oneline -5 origin/main`, and
   `~/shinichi-brain/tools/handoff_gate.sh "$PWD"`.
2. **OWED — confirm state.** `origin/main` ≥ `acf3d4fb3`; `python3 tools/parity_ledger.py
   --drmtmb "/Users/z3437171/Dropbox/Github Local/drmTMB" --ref origin/main` → CLOSURE: PASS;
   `python3 tools/check_test_deps.py` → OK.
3. **STOP and ask.** There is no owner-named next G0. Do not start #460 (drmTMB-side, quiesced),
   do not unpark #49/#136, do not touch #420/#406.

**Candidates to offer the owner, none started:**
- **Interval coverage**, the honest next frontier — a simulation campaign on Totoro, since
  agreement between engines is not calibration against truth. This is the only remaining route
  to removing the `coverage_claimed` fences.
- Wire `niterations` into the remaining family fitters (currently only Gaussian and bivariate
  Gaussian record it; everything else honestly returns `-1`).
- Binomial Cox–Reid draft (`docs/dev-log/plans/2026-08-19-lever-extension-next-g0.md`).
- Cell D Totoro ADEMP campaign (plan #454).

## Blockers / Open Questions

- **#460 needs drmTMB, which is quiesced.** Owner decision required before any work there.
- **Is the `1e-6 × response SD` degeneracy threshold right?** It is a judgment call I picked, not
  derived. Defensible and scale-free, but a legitimate near-zero-residual Gaussian fit would now
  be rejected. Worth an owner opinion if anyone hits it.
- **No fully independent agent reviewed the final state.** The planned Opus adversarial verifier
  was folded into inline orchestrator work. Recorded in the reconciliation rather than claimed as
  equivalent.

## Gotchas & Failed Approaches

- **A cross-engine numerical comparison must fit the SAME BYTES.** `Random.seed!(s); randn(n)` in
  Julia does **not** reproduce `set.seed(s); rnorm(n)` in R. I nearly filed a false bug against
  the profile CI on this — the implied half-width looked exactly like a 90%-vs-95% error to three
  significant figures. Export the R data to CSV and read it into Julia, as the committed fixtures
  already do.
- **`re_sd` for a phylo term is defined against the RAW covariance** `sigma_phy_dense(phy)`
  (diagonal = tree height), **not** the normalised correlation `_resolve_structured_matrix`
  returns. Using the correlation matrix under-disperses by √height — invisible on a height-1 tree.
  Round-trip across several tree heights before trusting any change here.
- **Do not guess whether `fit.means[:mu]` is conditional or marginal.** See Key Decisions. Use
  `predict(fit, data)`.
- **Local green ≠ CI green.** `julia --project=test test/runtests.jl` resolves from
  `test/Manifest.toml`; CI's `Pkg.test()` builds a fresh env from `test/Project.toml`. A test
  file importing an undeclared package passes locally and breaks CI. Run
  `python3 tools/check_test_deps.py` before pushing test changes. **`@formula` comes from
  `using DRM`** — do not `using StatsModels` in a test file.
- **`Pkg.test()` does not work on this machine** — it fails with `ERROR: can not merge projects`
  before running anything (pre-existing Project/Manifest issue). Use
  `julia --project=test --startup-file=no test/runtests.jl` (~45 min).
- **A grep loose enough to match a testset title is not a failure detector.** Two testsets are
  *named* "…error…" and pass; a naive count reports them as failures. Match `^Test Failed` or
  `Some tests did not pass`.

## Live environment

- **Working directory:** `/Users/z3437171/Dropbox/Github Local/DRM.jl`
- **Toolchain (all local, verified):** Julia 1.10.0 · R 4.6.0 · drmTMB **0.7.0 installed** ·
  JuliaCall 0.17.6. `timeout` does **not** exist (macOS/zsh).
- **Live R↔Julia bridge invocation:**
  `DRM_JL_PATH="$PWD" Rscript tools/parity_fixture.R`
- **Safe verification (no writes):**
  `python3 tools/parity_ledger.py --drmtmb "/Users/z3437171/Dropbox/Github Local/drmTMB" --ref origin/main`
  and `python3 tools/check_test_deps.py` and `python3 tools/parity_crosscheck.py`
- **Offline parity replay:**
  `DRM_PARITY_TESTS=1 julia --project=test --startup-file=no -e 'include("test/parity/runparity.jl")'`
- **Must not stage:** `.codex/agents/shannon-coordinator.toml`, `.worktrees/`, `.unlazy/`.

## How to Resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-24-claude-handover-parity-merged.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Read order: `AGENTS.md` → `CLAUDE.md` → this file → `docs/dev-log/coordination-board.md` →
`docs/dev-log/after-task/2026-08-24-parity-catchup.md` (+2 addenda) →
`docs/dev-log/plan-actual/2026-08-24-parity-catchup.md`.
