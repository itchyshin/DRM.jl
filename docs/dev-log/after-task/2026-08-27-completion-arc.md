## 1. Goal

Execute the DRM.jl completion roadmap (D-179, all six owner decisions answered 2026-08-27 in one
sitting): close the R↔Julia capability ledger completely, run Waves A (ledger blockers), B (engine
hygiene), and D (speed table, README, tag prep), and stage the v0.2.0 close-out tag.

## 2. Implemented

- **The capability ledger is complete.** drmTMB PR #1087 promoted `phylo_gamma_beta_binomial` and
  `general_covariance_structured`; #1089 gave `cross_family_latent` its permanent owner-signed
  boundary (with a retraction — the route IS reachable from R via `drmTMB_julia_xfam_bridge`,
  test-covered; the old "unreachable" verdict had inspected the wrong layer); #1091 promoted
  `phylo_count_large_p` and `gaussian_response_mask`. Final board: **9 covered + 1 permanent
  boundary + 1 unsupported-by-design = all 11 rows at their final state**, every promotion backed by
  SE-grade parity on a stamped comparator build.
- **Wave A engine (DRM.jl #517):** (a) #491 — the sparse-Laplace `converged` flag answers a fixed
  relative criterion (mean per-observation gradient ≤ 1e-6), short-circuit removed; (b) the
  Gaussian phylo-mean cell accepts masked responses as observed-rows + full tree, after measuring
  drmTMB's own `include` ≡ `drop` byte-identical; (c) the large-p SE gap was diagnosed as the FD
  noise floor and fixed with an n-aware step — re-banked SE parity p=1000 **3.99e-06** (was
  1.178e-03), p=3000 **4.53e-06** (was 9.01e-04).
- **Wave B:** #509 — q4 `converged` gated on Λ admissibility, smoke fixture de-saturated (#518);
  #472 — `mstep_Lambda`'s measured descent wired as a characterisation tripwire (#519);
  `src/experimental/` per-file verdicts README (#520). #470 discovered already done; #467 tail
  confirmed deliberately open.
- **Wave D:** `report/speed-per-family.md` (#521) consolidating every engine-vs-engine timing with
  caveats in the table (first-call latency; the modest Poisson-phylo edge), including a fresh
  timing run for the three cells whose old benchmarks predate drmTMB's phylo support; README sweep
  (REML sentence was three routes stale); NEWS completion-arc entries (#523); tag annotation
  drafted; version bump held for the owner's word, which came: **v0.2.0**.
- **Bridge integrity forced by the honest flag:** drmTMB's `drm_julia_bridge_options` now requests
  DRM.jl's native `g_tol = 1e-8` on non-Gaussian phylo routes (the 1e-4 smoke tolerance's own
  comment said it stood "until their own parity fixtures justify a route-specific change" — they
  now do), while Gaussian σ-phylo routes keep their verified 1e-4; the binomial live fixture gained
  per-tip replication (it sat unidentified on the zero-variance boundary); a live
  include≡drop bridge test landed in `test-julia-missing.R`.
- **Infrastructure:** a dynamic merge-queue driver that walks every armed PR through DRM.jl's
  strict branch protection; Mission Control board updated three times; the Road-to-v0.1.0 artifact
  updated with the decisions.

## 3a. Decisions and Rejected Alternatives

- **All six roadmap decisions adopted as recommended (owner, verbatim: "Answer decisions 1-6 with
  your recommendations"; vault D-179):** #491 relative criterion at 1e-06; mask wrapper if
  measured-equal (it was); cross_family permanent boundary over bridge wiring; fences Option 1
  (permanent, documented — no coverage campaigns); #471 deferred past the tag; tag when Wave A
  closes with the D-111 carve-out on #8.
- **One drmTMB PR per ledger event** (promotions #1087/#1091, boundary #1089) rather than
  row-per-PR: follows the #1085 precedent and avoids serialized conflicts on the same four files.
- **Rejected: promoting `phylo_gamma_beta_binomial` on coef/logLik evidence alone.** The plan's
  "SE cells (~5 min)" had never been banked; the harness was extended with SE columns and the cells
  measured *before* the ledger claimed them.
- **Rejected: an `Inf`-style strictness for the σ-phylo bridge tolerance.** The first cut of the
  g_tol change swallowed the Gaussian σ-phylo routes into 1e-8 and flipped a previously-green REML
  fit; scope was regained (family-split mapping) rather than loosening the flag.
- **Rejected: fixing the Workflow G robust-student live failure inside the promotions PR.** It is
  pre-existing on clean main (verified by stash), filed as drmTMB #1090.
- **v0.2.0 over re-tagging v0.1.0:** tags v0.1.0–v0.1.2 already exist; the decision-#6 letter
  collided with history, surfaced to the owner, who picked v0.2.0.

## 4. Files Touched

DRM.jl (branches → PRs #515–#523 + evidence branches): `src/sparse_laplace_glmm.jl`,
`src/gaussian_core.jl`, `src/gaussian_bivariate.jl`, `src/experimental/README.md` (new),
`test/test_phylo_count_largep_gate.jl`, `test/test_gaussian_phylo_mean_missing_response.jl`,
`test/test_gaussian_bivariate_q4_structured.jl`, `test/test_lambda_p100.jl`, `test/runtests.jl`,
`tools/parity_phylo_nongaussian.R`, `docs/dev-log/evidence/parity-classc.tsv`,
`docs/dev-log/evidence/parity-phylo-nongaussian.tsv`, `report/speed-per-family.md` (new),
`README.md`, `NEWS.md`, `docs/dev-log/plans/2026-08-27-completion-roadmap.md` (new),
`docs/dev-log/plans/2026-08-26-promotion-arc.md` (landed), this report.
drmTMB (PRs #1087, #1089, #1091): `R/julia-bridge.R`, `inst/extdata/julia-capabilities.tsv`,
`docs/dev-log/dashboard/julia-capabilities.tsv`, `tests/testthat/test-julia-gate-vs-engine.R`,
`tests/testthat/test-julia-missing.R`, `tests/testthat/test-julia-phylo-nongaussian.R`,
`tests/testthat/test-julia-sigma-phylo-reml.R`.
Vault: `memory/DECISIONS.md` (D-179), Mission Control `status/drmTMB.json` (×3).
Scratchpad only: diagnostic scripts (A1 sweep, fixture exports, timing runs), tag annotation draft.

## 5. Checks Run

- DRM.jl full suite in an ISOLATED worktree at the Wave A tip: **exit 0, zero failures, 326
  testsets** (`julia --project=test --startup-file=no test/runtests.jl`).
- `python3 tools/check_test_deps.py` → OK, every import declared.
- `python3 tools/parity_ledger.py --ref origin/main` → **CLOSURE: PASS**, re-verified after #1087
  (7 covered) — final 9-covered verification pending #1091's merge, in the ping.
- Targeted: gate 26→31/31; sparse-Laplace affected set 135/135; q4 affected set 126/126; the #482
  mask file 44/44; drmTMB julia-facing live certification: **16 of 17 files green** (975+
  assertions), the one failure being pre-existing #1090.
- Fresh measurements behind every claim: the A1 step-size × inner-start sweep at p = 300/1000/3000
  vs TMB on identical exported data; the include-vs-drop byte-identity experiment; the per-family
  timing run; the failing-fixture gradient measurements (relgrad 2.3e-6 boundary vs 2.4e-8
  replicated).

## 6. Tests of the Tests

- Every behavioural change was red-first: the "converged is not for sale" gate failed against the
  old short-circuit before the fix; the include==drop testset failed against the refusal; the #509
  admissibility testset failed against the old flag (with the identified fixture as positive
  control so the gate separates regimes).
- The #472 characterisation is an inverted tripwire by design: repairing `mstep_Lambda` FAILS it.
- The regression guard for the plain FE masked path caught a real regression I introduced
  mid-development (the `else` swallowed the structure-free case) — the guard did its job before any
  push.
- Negative controls retained: `parity-se.tsv`'s perturbed-SE control; the #509 saturated fixture
  kept as the admissibility gate's negative control.

## 7a. Issue Ledger

Closed this arc: DRM.jl #491 (honest flag), #509 (admissibility + fixture), #472
(characterisation); ledger rows via drmTMB #1087/#1089/#1091. Discovered already closed: #470.
Filed: drmTMB #1090 (Workflow G robust-student marshalling, pre-existing). Deliberately open:
DRM.jl #467 (newdata reconstruction — fails loudly, correct), #495 (finding recorded; fences are
permanent per D-179 #4), #9 (v1.0 — speed table lands its per-family half), #8 (closes with the
tag). Deferred by decision: #471, #136, #13-adjacent backlog.

## 8. Consistency Audit

- All eight `_finite_hessian` call sites updated together (the class, not the instance); verified
  n in scope at each.
- Both q4 constructors (structured AND phylo) got the Λ-admissibility gate.
- The g_tol change was audited against every payload arm — and the audit caught its own first cut
  over-reaching (σ-phylo). The unit test now pins both arms of the mapping.
- Fixture-saturation sweep across q4 test fixtures (`4G ≥ 2n`): only the deliberately-kept negative
  control remains saturated; the gate itself now polices this permanently.
- Public-text sweep: README's REML sentence, experimental/ paragraph, and engine paragraph brought
  in line with the promoted ledger; NEWS carries the arc; the gate test's forbidden-pattern list
  re-ran green (142).
- The stale-armed auto-merge on deliberately-open PRs #406/#420 (a latent accidental-merge hazard
  surfaced by the dynamic queue driver) was disarmed.

## 9. What Did Not Go Smoothly

- **I ran the full suite against a working tree I then edited mid-run** — third bite of this
  session-family's shared-tree lesson. Killed, re-ran in an isolated worktree (which then needed
  its own `Pkg.develop` wiring).
- **The first monitor parsed `gh pr checks` with whitespace-splitting awk**, mis-reading spaced
  check names and declaring "ALL CI FINISHED" while three checks ran. Caught by direct
  verification; re-armed tab-parsed.
- **drmTMB #1087 merged while its R CMD check still ran** — `--auto` on a repo with no required
  checks merges immediately. Reported to the owner at once; the check later passed. #1091 used an
  explicit green-gated merge instead.
- **My own truncation habits** (`tail -3` on diagnostic output) hid the certification failure list
  once and cost a full re-run.
- **The g_tol first cut over-reached** (σ-phylo routes) and **the roadmap listed #470 stale** —
  both caught by this repo's own tests / the prior-work sweep rather than by review.

## 10. Known Residuals

- drmTMB #1090: the live Workflow G robust-student cell errors in DRM.jl's `_bridge_formula`
  (univariate Student read as bivariate) — pre-existing, filed, unfixed.
- A cross-file state-leakage flake in the single-session certification harness (predict-newdata's
  `model.frame` once picked up a leaked `x`); not reproducible solo, not chased.
- `phylo_count_large_p`'s p=10,000 O(p) claim remains single-engine — recorded in the row boundary
  as a deliberate non-goal.
- The interval fences are PERMANENT by decision, not evidence: coverage remains unclaimed
  everywhere, and the #495 scale-axis finding stands unresolved (documented, not scheduled).
- v0.2.0 tag pending the merge queue draining (in flight at time of writing).

## 11. Team Learning

Memory receipt: hub `AGENTS.md` + repo `CLAUDE.md`/`AGENTS.md` loaded; D-116/D-139/D-164/D-111/
D-88 shaped routing throughout; lane preflight ran on both repos before claiming work (drmTMB's
codex lane active — zero file overlap maintained across their #1086/#1088 merges). The brain was
queried (semantic + deterministic grep) before the speed-doctrine answer and before D-179's
numbering (claim-by-committing honoured).

Golden Set: not in scope this arc (no known-mistake-class replay was triggered); the arc's own
recurrent catches are recorded below instead.

The durable lesson, filed for promotion: **an honest flag is a lever, not just a report** — making
`converged` answer a fixed question immediately exposed a sloppy bridge tolerance, an unidentified
live fixture, and a scoping error in its own rollout; each "regression" it caused was a defect it
found. Corollary bitten four times now (#483, #509, binomial live, smoke fixture): **when a
boundary/saturated fixture argues with a gate, reseed the fixture, never the gate.**

## 12. Cross-Product Coverage

The #491 converged criterion covers ✓ every family on the sparse-Laplace univariate path (Poisson,
NB2, Gamma, Beta, Binomial, BetaBinomial; phylo, relmat, crossed) and, via the bridge g_tol change,
✓ their engine="julia" cells. It does NOT cover the Gaussian σ-phylo/locscale routes (own
criterion, deliberately kept at 1e-4 — pinned by unit test), the q4 bivariate routes (their flag is
the #509 Λ-admissibility gate), or Optim-based non-Laplace fitters.
The n-aware FD step covers ✓ all eight sparse-Laplace vcov sites; it does NOT cover the q4 routes'
vcov (different machinery) nor `_finite_hessian` callers outside sparse_laplace_glmm.jl (none
exist today — checked).
The mask wrapper covers ✓ exactly the Gaussian phylo-MEAN cell (sigma ~ 1); it does NOT cover
relmat/animal/spatial means, ordinary REs, meta_V, non-constant sigma designs, missing predictors,
or non-Gaussian response masks — all still refuse loudly, and the leak-guard tests assert it.
The ledger completion covers ✓ capability claims on all 11 rows; it does NOT cover interval
coverage (permanent fences, D-179 #4), the p=10,000 scale versus a native comparator, or CRAN/
registration surfaces (D-164, D-111).
