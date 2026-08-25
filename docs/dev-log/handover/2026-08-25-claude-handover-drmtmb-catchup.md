# Session Handoff: drmTMB catch-up — SIX capability rows moved, three PRs awaiting the owner

Meta: 2026-08-25 · from **Claude Code** (Shannon) · TARGET **claude** · AUTHOR **claude**

You are **Claude Code**, picking up **DRM.jl** with **no chat context**. Rehydrate from this repository
and current git state. Classify every item **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only
`OWED`.

**Supersedes as DRM.jl START HERE:**
[`2026-08-24-claude-handover-parity-merged.md`](2026-08-24-claude-handover-parity-merged.md). Keep it;
treat as historical.

## Critical Context

1. **The owner named a G0 and then went away overnight**: *"catch up with drmTMB, then complete the
   package"*, with instructions to keep going autonomously. This session ran Waves 1–2 unattended.
2. **NOTHING IS MERGED. Both repos' `main` are untouched** — DRM.jl `origin/main` @ `8d45b651`,
   drmTMB @ `fb8e6c1a5`. Three PRs are open and awaiting **his** decision. Do not merge them for him:
   `AGENTS.md` requires maintainer approval for `src/`, the formula grammar, and `AGENTS.md` itself, and
   all three are touched.
3. **The drmTMB EDITING fence is open; the RELEASE hold is not.** He was asked directly and chose the
   D-164 reading; it is **recorded**, not asserted — a clarification block inside D-164 in
   `~/shinichi-brain/memory/DECISIONS.md` @ `ed5132b`. Still forbidden: `submit_cran`, upload, tag,
   announcement. **And do not re-ask the submission question** (D-163/D-164; CI-17 moves silently).
4. **`supported` IS NOT A STATUS.** The governing vocabulary (drmTMB `docs/design/168`) is
   `covered > partial > experimental > planned > unsupported`. The old countdown counted
   `claim_status != 'supported'` and printed "N unsupported rows" — `len(caps)` by construction, unable
   to register progress. Fixed in `d265d876`. Promotion means `experimental → partial` or
   `partial → covered`.

## What Was Accomplished

**Six capability rows moved** (drmTMB#1082, unmerged):

```
before: 0 covered · 6 partial · 4 experimental · 1 unsupported
after:  4 covered · 4 partial · 2 experimental · 1 unsupported     CLOSURE: PASS
```

**Six rows moved in total** — that is the maximum reachable without you. Of the five that did not:
`gaussian_response_mask` and `engine_control_surface` **must not move** (no working path; deliberately
rejected); `cross_family_latent` is **unsatisfiable by construction** (no native comparator exists);
`biv_q4_phylo_reml` and `phylo_gamma_beta_binomial` need **your decisions** (#478 scope narrowing, #473
reinstall).

| row | move | evidence |
|---|---|---|
| `biv_gaussian_residual` | → covered | coef 9.861e-07 (7/7 name-matched), SE 9.176e-08, logLik 1.307e-11 |
| `plain_binomial_nonphylo` | → covered | SE 1.268e-09 — tighter than all three Gaussian cells |
| `base_gaussian_location_scale` | → covered | SE 1.499e-07 + live parity finally run (ΔlogLik 6.257e-09) |
| `gaussian_phylo_mean` | → covered | phylo SD 1.50e-08 across 3 tree heights, **after reseeding** — the old seed's parameter was unidentifiable (#483) |
| `general_covariance_structured` | → partial | all four claimed families measured; SE axis added |
| `phylo_count_large_p` | → partial | p = 20/300/1000/3000 PARITY_PASS; TMB measured **O(p^1.27)**, not O(p³) (#486) |

**Merged into the lane** (DRM.jl#485, draft): #465 orphan tests · #466 `niterations` · #467 bridge
formula constructs · #468 coverage pre-run · #470 bivariate q=2 REML · #471 LogNormal structured markers ·
#479 a shipped bootstrap bug.

**Measured results worth keeping:**
- #470 recovery: REML cuts variance-component bias vs ML at G=8 — mu1 **0.0603 → 0.0216**, mu2
  **0.0563 → 0.0226**, 60/60 converged.
- #471: bit-identical θ̂/Σ_a across tree heights **0.5 / 1.2 / 3.0**.
- **q4 REML constant-offset prediction HOLDS** on a converged fit: predicted `(n_β/2)·log(2π)` =
  **5.513631**, measured **5.504981**, residual **0.008650** (13× smaller than non-converged).

## Current Working State

- **Working:** `feat/drmtmb-catchup`, **72 commits ahead**, pushed. Full suite **VERIFIED: 324 testsets,
  0 failures, 0 errors**, run to completion on this tree. `check_test_deps` OK · `parity_ledger`
  CLOSURE: PASS · all 39 parity TOML parse.
- **In progress: nothing.** All background agents completed and their work is merged.

## Key Decisions & Rationale

- **Deliberate refusals, all of which should survive review:** `poly()` stays rejected (R defaults to
  `raw = FALSE`, QR-orthogonal; a raw-power version would silently disagree). Bivariate **Student**
  markers stay rejected (no closed-form marginal under a Gaussian group RE). `niterations` keeps an honest
  `-1` where no optimiser call is attributable. `V` + REML permanently refused (residual-only route
  marginalises nothing).
- **`gaussian_response_mask` must NOT be promoted** — measured (#482): masks work for **non-phylo Gaussian
  only**; mean-phylo fails the opt-in `include` *and* the **default** `drop`.
- **No row claims interval coverage.** Both `interval_status != "coverage_claimed"` fences intact.

## Landing State

| Artifact | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `feat/drmtmb-catchup` (56 commits) | y | y | **DRM.jl#485 READY** | **CARRIED-OVER** — suite-verified; needs maintainer approval (touches `src/`, the formula grammar, and `AGENTS.md`) |
| drmTMB `claude/julia-fixef-profile-bootstrap-460` | y | y | **#1080 OPEN** | **CARRIED-OVER** — #460 fix, repaired after adversarial review |
| drmTMB `claude/ledger-biv-gaussian-residual-covered` | y | y | **#1082 OPEN** | **CARRIED-OVER** — the six row moves |
| Vault D-164 clarification `ed5132b` | y | n/a (D-37 local-only) | none | **LANDED** |
| Mission Control `status/drmTMB.json` `6f492da` | y | n/a | none | **LANDED** |
| `.codex/agents/shannon-coordinator.toml` | n | n | none | **PROTECTED — never stage** |
| 37 unpushed on ~22 stale branches | y | n | none | **CARRIED-OVER** — pre-existing |

## Next Immediate Steps

1. **OWED — rehydrate.** `~/shinichi-brain/tools/lane_preflight.sh`, `git fetch origin`,
   `git status -sb`, `~/shinichi-brain/tools/handoff_gate.sh "$PWD"`.
2. **OWED — re-confirm the suite** if anything has changed since:
   `julia --project=test --startup-file=no test/runtests.jl` (~35 min). Baseline **318 testsets, 0
   failures, 0 errors**. DRM.jl#485 is already marked ready for review — **do not merge it**.
3. **STOP. The rest is his.** Do not merge any PR; do not run the coverage grid; do not reinstall drmTMB;
   do not re-ask the CRAN submission question.

## Every finding raised this session — final disposition

**Fixed on the lane (18):** #465 orphan tests · #466 niterations · #467 bridge formulas · #470 q=2 REML ·
#471 LogNormal markers · #472 EM fenced honestly · #474 `readdlm` column typing · #475 public `parm`
kwarg · #476 parity helpers isolated · #477 REML convention documented · #479 + #480 bootstrap threads
`K`/`A`/`tree` · #482 mean-phylo missing response · #483 fixture reseeded where the parameter is
identifiable · #484 warm restart in the public REML path · #487 SE-vs-p settled · #488 `vcov_guard`
extended to sparse-Laplace · #489 `runparity.jl` reaches the bridge fixtures.

**Recorded, not fixed (3):** #473 comparator provenance · #481 reverse ledger pass (**half-closed** — it
cannot see capability divergence under an already-matched name, which is the case that motivated it) ·
#486 native TMB is O(p^1.27), not O(p³).

**Needs the owner (3):** #468 coverage go/no-go · #478 scope narrowing · the three merges.

**#484 changed the picture for `biv_q4_phylo_reml`:** `drm(..., method = :REML)` now converges through
public kwargs alone (`g_residual = 5.295e-4 < g_tol = 1e-3`), and the converged fit reproduces the
`(n_β/2)·log(2π)` constant to a residual of **0.001938** — 4.5× tighter than the manual recipe, 60×
tighter than non-converged. The fixture's `status.julia_converged = false` and its `[tol]` are
**deliberately left stale**; re-deriving a fixture inside the change that fixes the thing it measures
would make evidence and code circular. That re-derivation is the natural next task.

## Late findings (after the first draft of this handover)

- **#477 is sharper than filed — DRM.jl is internally inconsistent about REML.** I filed it as "we omit a
  constant lme4/glmmTMB/TMB include". Verified from source, it is **route-specific**: the univariate
  fixed-effect and mean `(1|g)` REML paths DO add `(pμ/2)·log(2π)` (`src/gaussian_core.jl:905,955`); the
  bivariate q4 and q2 routes do not. So `reml_loglik(fit)` means different things depending on which route
  produced the fit — a user comparing a univariate against a bivariate REML fit *within DRM.jl* is
  comparing different scales. Documented in four places; **no value changed** — unifying it moves a
  published number and is the owner's call. If unified, move the BIVARIATE routes: the univariate ones
  already match the ecosystem.
- **#489: all five `bridge-*` fixtures were broken under the generic runner**, in two modes — three
  crashed, and **two fitted silently and wrongly**: `(x+z)^2` became an elementwise power rather than R's
  degree-2 crossing (df 3 vs 5). That is precisely what #467's retained rejection asserted would happen,
  now measured rather than argued. Fixed by routing `bridge-*` through `drm_bridge` (11 pass/2 fail/3
  error → 16 pass).
- **#488: `vcov_guard` does not cover the sparse-Laplace route.** The guard that warns "these SEs are not
  trustworthy" cannot fire there — `src/sparse_laplace_glmm.jl` computes `vcov` inline via
  `try inv() catch identity`. Silently catching a singularity and returning the identity is the strongest
  case for a warning and currently produces none, on the route backing every non-Gaussian phylo family.
- **#487: SE parity loosens ~196x from p=300 to p=1000 and does NOT track conditioning** (rcond worsens
  only 3.2x there, and SE parity *improves* p=1000→3000 while rcond worsens further). The benign
  "different factorisations rounding differently" explanation is refuted. Unexplained.

## Blockers / Open Questions — all need the owner

- **#468 interval-coverage go/no-go.** Pre-run says GO. n_sim = 1000/cell (MCSE 0.69 pp), **~25 CPU-h**,
  Totoro pilot 15–25 min then 40–70 min at the 150-core cap; Totoro *and* DRAC reachable, no Duo
  triggered. **Honest caveat against the instruction to use DRAC:** at this grid size Totoro alone
  absorbs it in ~1 h. **Case against:** the bivariate cell's convergence flag is false on the fixture
  shape, and **all 25 CPU-h is that one cell** — the univariate is 0.007 CPU-h.
- **#478** — two `claim_boundary` criteria unsatisfiable as written; one rewrite **narrows** a row's scope,
  which is his call.
- **#473** — reinstalling drmTMB from `origin/main` would move the comparator under every banked number at
  once. **Record `tools/drmtmb_provenance.R` output first, then re-run the harnesses.**

## Gotchas & Failed Approaches

- **A grep for a LONGER phrase cannot prove the absence of a SHORTER one.** I reworded an error message,
  "verified" no test matched by grepping `has no random`, and broke `occursin("no random", …)`. The suite
  caught it. Tests match short substrings.
- **`.unlazy` gate state:** `check-after-task.R` reports **unapproved** gates as UNMET, which reads as
  "verified failing" when it means "not verified". `--status` said ALL MET; `--reverify` said UNMET 22 —
  every one of them "reverify not run".
- **Merging two green branches can produce a bug in neither.** #470 and #471 conflicted in
  `bivariate_lognormal.jl`; HEAD passed `reml_loglik` **unshifted** while #470 had just made REML
  reachable there.
- **Same bytes.** `Random.seed!(s); randn(n)` ≠ `set.seed(s); rnorm(n)`. Export R data to CSV.
- **`re_sd` for phylo is against the RAW covariance** (diagonal = tree height), not the normalised
  correlation. Invisible at height 1 — always round-trip several heights.
- **`Pkg.test()` is BROKEN here** ("can not merge projects"). Use
  `julia --project=test --startup-file=no test/runtests.jl`.
- **Run `python3 tools/check_test_deps.py` before any test push.**
- **A failing test ABORTS the suite**, so a low testset count means truncation, not progress.

## Live environment

- **Working directory:** `/Users/z3437171/Dropbox/Github Local/DRM.jl`
- **Toolchain:** Julia 1.10.0 · R 4.6.0 · drmTMB **0.7.0 installed, built 2026-08-15** (16 shipped commits
  behind `origin/main` — #473) · JuliaCall 0.17.6. `timeout` does not exist (macOS).
- **Safe verification (no writes):** `python3 tools/parity_ledger.py --drmtmb
  "/Users/z3437171/Dropbox/Github Local/drmTMB" --ref origin/main` · `python3 tools/check_test_deps.py` ·
  `python3 tools/check_capability_citations.py` · `Rscript tools/drmtmb_provenance.R`
- **Must not stage:** `.codex/agents/shannon-coordinator.toml`, `.worktrees/`, `.unlazy/`.

## How to Resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-25-claude-handover-drmtmb-catchup.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Read order: `AGENTS.md` → `CLAUDE.md` → this file → `docs/dev-log/coordination-board.md` →
`docs/dev-log/evidence/2026-08-24-promotion-readiness.md` →
`docs/dev-log/after-task/2026-08-24-drmtmb-catchup-wave1.md`.
