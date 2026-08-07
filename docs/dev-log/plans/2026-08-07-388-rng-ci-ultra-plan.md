# Ultra-plan — #388 dual-Julia RNG CI exposure

Phases 0–2 only. **STOP at G0.** After approval, hand to `/goal` (do not execute Phase 3 in this chat).

---

## GOAL

```
PLATFORM: Cursor (workbench) · live Julia dual-version verify on this machine (or Totoro if full Pkg.test)
DELIVERABLE: Close or honestly disposition DRM.jl #388 — dual-Julia (1.10 vs 1.x) RNG exposure
  evidenced on a risk cohort; repair only proven fragile classes; DoD PR or latent-OK close.
HEADLINE: Reuse HSquared 2026-08-04 playbook (CI stays RNG-free for recovery claims;
  literal fixtures / env-gated sim) — do NOT blanket-add StableRNGs to the main Project.toml.
IN PARALLEL: none required for Arc 0; optional read of HSquared after-task while dual-version
  Julia jobs run.
DEFER / FENCE: #136 VA; #49 FIML; #336 Makie; D-111/Registrator; tip-idle SHA-churn padding;
  rewriting ~154 RNG test files; promoting StableRNGs beyond the existing test/ dep unless a
  residual MC-probe class demands it; stacking commits onto feat/202-locscale-closeout.
DISCIPLINE: verify before claiming · merge #395 first · one issue → one branch → one PR ·
  never stage .worktrees/ · Rose claim-vs-evidence (latent ≠ fixed).
```

---

## ARC PROGRAM

From Arc Creation (size mode, ~2 h ceiling 3 h):

- **Arc 0 (45–60 min):** risk-cohort dual-version probe + triage receipt
- **Rung 1 (45–90 min):** first divergent class → deterministic fixture or `DRM_*` env-gate
- **Rung 2 (30–45 min):** second class / short CI-RNG policy note (only if Rung 1 finishes early)
- **Closeout (20–30 min):** check-log.d + after-task + Rose; PR `closes #388` or latent-OK close with retained hashes

Under-run → pull Rung 2 forward or close early; do not pad with tip-idle.

---

## PHASE 0.25 — SWEEP RECEIPT (gate for decompose)

| Surface | Evidence ran | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb`; branch `feat/202-locscale-closeout`; `branch_drift_check.sh` → **4 ahead / 0 behind** `origin/main`; no `388`/`rng` branch | Active ship = **#202 / [PR #395](https://github.com/itchyshin/DRM.jl/pull/395)** (CI **green**: test 1.10 + test 1 + docs). No #388 WIP to resume | **Land #395 first**, then **build-the-gap** on fresh `feat/388-ci-rng-…` from post-merge tip |
| **twin / sister** | HSquared `docs/dev-log/after-task/2026-08-04-ci-rng-fragility-fix-and-s5-freeze.md`; decision `2026-06-13-rng-recovery-test-harness.md` (“CI stays RNG-free”); handovers citing DRM #388 / GLLVM #182 | Same matrix; same failure class; repair = env-gate + literal fixtures (StableRNGs last) | **co-opt HSquared policy**; do not reinvent |
| **brain** | `search_notes` “#388 RNG CI StableRNGs HSquared”; `grep DECISIONS/AGENT_LOG/OPEN_QUESTIONS/deep-research` for `388`/`StableRNG`/`MersenneTwister` | No DRM decision locking #388; HSquared activity logged 2026-08-04; no prior DRM ship for this | **new DRM slice**; reuse twin evidence |
| **repo code** | Explore recon: 154 files / ~1122 RNG sites; `StableRNGs` **only** in [test/Project.toml](test/Project.toml) + [test/test_mixed_family.jl](test/test_mixed_family.jl); CI matrix `['1.10','1']` in [.github/workflows/CI.yml](.github/workflows/CI.yml); risk cohort listed (phylo locscale, mixed_family, two_structured_*, nb2_phylo_laplace, coverage_engine, …); safer patterns = bridge/parity fixtures + `DRM_PARITY_TESTS` | Exposure **latent** (both CI legs green on #395); gap = triage + policy, not a hot red | **build public evidence + harden only if red** |
| **Verdict** | | Genuinely new: dual-version **retained** probe + disposition of #388. Not new: failure mechanism or repair taxonomy | **reuse HSquared → probe DRM gap → repair only proven classes** |

---

## WHAT THE BRAIN / REPO ALREADY KNOWS

- Tip idle after #393 preferred owner-named G0; #202 was that G0 and is PR-ready (CI green).
- HSquared already paid for the lesson: seeded DGP + atol recovery is not CI-safe across Julia minors.
- DRM already has partial escapes: parity fixtures, `DRM_PARITY_TESTS`, one `StableRNGs` import in mixed-family.

## WHAT SHINICHI TOLD US

- Asked for next suitable arc → Arc Card picked **#388**.
- Asked `/ultra-plan` on that arc → this plan.
- No separate instruction to delay for tip-idle hygiene.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Grace  — CI matrix already green on #395 for both Julia legs; #388 is latent until a
           dual-hash probe. Full double Pkg.test may be hours — start with risk cohort.
           · Rec: Arc 0 = named-file probe; escalate only if needed.
  Curie  — Recovery tests with locked seeds (phylo locscale, structured locscale, q4) are
           the exact HSquared failure shape.
           · Rec: those files first; record hash(y)/pass between 1.10 and 1.12.
  Rose   — Closing #388 as “fixed” without a divergent class is claim drift; latent-OK needs
           retained dual-version evidence. Do not claim suite-wide immunity after one cohort.
           · Rec: disposition honesty in same PR as any repair.
  Ada    — Sequence: merge #395 (L2) → new branch from tip → #388. Do not stack on #202 branch.
```

## ADA'S RECOMMENDATION

Approve G0 for **#388 after #395 merge**. Defaults locked below (HSquared (1)+(2); risk cohort first; StableRNGs not the headline fix).

## DECISIONS LOCKED (pending your G0)

1. **Sequence:** Owner merges [PR #395](https://github.com/itchyshin/DRM.jl/pull/395) first; #388 branch from post-merge `origin/main` only.
2. **Repair taxonomy:** Prefer (1) env-gated / out-of-CI stochastic recovery and (2) literal deterministic fixtures. Use `StableRNGs` only for residual estimator-internal MC probes if a class still fails after data is fixed — do not add it to the main [Project.toml](Project.toml).
3. **Arc 0 scope:** Named risk cohort under `julia +1.10` and `julia +1.12` (or `+1`), not an immediate double full `Pkg.test`.
4. **Platform:** Cursor `/goal` after G0; live Julia verify local (Totoro only if cohort forces full-suite).
5. **Fences:** no q=4 core edits; D-111 OFF; never stage `.worktrees/`.

## QUESTIONS STILL OPEN

None blocking G0 — defaults above cover taxonomy and sequencing. Owner may rename under-run (e.g. also file GLLVM #182 twin) outside this DRM lane.

---

## SLICE TABLE

| Slice | Member | Model+effort | Bar | Dispatch | Time | Detail | Dep |
|---|---|---|---|---|---|---|---|
| RECON (done in plan) | Ada+scout | Composer/low | Cursor Models | native | 0 | Sweep receipt above | — |
| S0 Merge gate | Shannon | — | hand off | human | L2 | Merge #395 when ready | owner |
| S1 Arc 0 probe | Curie/Grace | Composer medium | Cursor Models | `/goal` Agent | 45–60m | Dual-version risk cohort; write `docs/dev-log/evidence/2026-08-*-388-rng-probe.md` | S0 |
| S2 Repair (if red) | Grace+Curie | Composer/Sonnet | Cursor / Other | `/goal` | 45–90m | Fixture or env-gate for first divergent class; re-probe both Julias | S1 |
| S3 Policy note (if under-run) | Pat/Grace | Composer | Cursor Models | `/goal` | 30m | Short CI-RNG note in test README or #388 comment linking HSquared decision | S1/S2 |
| S4 DoD + PR | Rose+Ada | Auto Cost / Claude | Other Models | `/goal` | 20–30m | check-log.d + after-task + Rose; `gh pr create` closes #388 | S1–S3 |
| MECHANICAL-VERIFY | Grace | Composer | Cursor Models | `/goal` | in S1/S2 | Re-read probe log; both versions agree on disposition | S1/S2 |
| RECONCILE | Melissa | Sonnet/medium | Other Models | post-close | 10m | `docs/dev-log/plan-actual/2026-08-*-388-rng.md` or N/A if tiny latent close | S4 |

**LUNA SUITABILITY:** yes — RECON/MECHANICAL-VERIFY are cohort inventory + log compare (already done for plan; redo lightly at execute).  
**FAN-OUT BUDGET:** checkpoint=`388-rng` · children ≤3 · ceiling=0 · no Sol unless Rose claim fight.  
**ULTRA EFFORT:** no.  
**ESTIMATE:** ~2 h wall-clock after #395 merge; 1 session via `/goal`; handoff only if full-suite forced.  
**REVIEW (plan):** Rose — receipt non-vacuous; claim honesty for latent-OK. **PASS for G0.**

---

## VERIFY / CONSOLIDATE

- Dual-version cohort log retained (pass/fail + at least one `hash` or fitted snapshot on divergence).
- If repaired: both Julia legs green on the touched file(s).
- Rose: no “suite hardened” claim beyond evidenced cohort; no GPL; no `.worktrees/`.
- Melissa: plan-vs-actual after close (or `RECONCILE: N/A` only if pure latent close &lt;30 min with no code).

---

## PASTE-READY `/goal` (after G0)

```text
/goal DRM.jl #388 dual-Julia RNG CI exposure

Read AGENTS.md + this ultra-plan (docs/dev-log/plans/ when written) + Arc Card.
Precondition: origin/main includes merged PR #395 (#202). If not merged, STOP and ask owner.

Branch: feat/388-ci-rng-exposure from origin/main.
Arc 0: OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 — run risk cohort under julia +1.10 and +1.12
  (files: test_phylo_locscale, test_public_phylo_locscale, test_locscale_structured,
   test_gaussian_locscale_phylo, test_mixed_family, test_two_structured_gaussian_sparse,
   test_nb2_phylo_laplace, test_coverage_engine). Retain evidence markdown.
If red: HSquared (1)+(2) repair — not blanket StableRNGs in Project.toml.
If green: latent-OK close with Rose-honest wording + retained hashes.
DoD: check-log.d + after-task + Rose; PR closes #388. Pause for owner merge.
Fences: no #136/#49/D-111; never stage .worktrees/; no tip-idle padding.
```
