# 2026-08-18 — G0 (APPROVED): Cox–Reid scoping probe for non-Gaussian variance components

**Issue:** https://github.com/itchyshin/DRM.jl/issues/441
**Lane:** `cursor/lane-cox-reid-probe` @ `~/local-scratch/lanes/DRM.jl-cox-reid-probe`, base `origin/main` `5e392c6e` (post-#440).
**Platform:** Cursor (Opus, owner-directed). **Speaking as Shannon.** No nested subagents spawned.
**Status:** G0 approved by owner; executing. This file replaces the stale #434 kit that
`origin/main`'s `LOOP/` carried into the worktree — that plan is a different subject.

> Note: this kit was scaffolded by `lane_launch.sh`, which seeds `LOOP/` from the base
> commit. The four files inherited the 2026-08-16 `next-after-#434` plan verbatim. All four
> are overwritten here. Do not read the inherited content as this lane's plan.

---

## 🎯 GOAL

See `LOOP/GOAL.md` (immutable). One line: **decide, on measured DRM.jl evidence, whether
Cox–Reid for non-Gaussian variance components is a small patch or a real build** — then hand
the implement-G0 a decision it does not have to re-derive.

---

## PREFLIGHT (Phase 0.2)

```
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** `** FOREIGN LANE ACTIVE (claude direct-to-main) **`

```
ME              : cursor   (foreign = claude codex · a 2nd cursor lane counts too)
ON BRANCH       : docs/a3c-design            (leftover; 0 ahead — do NOT build here)
OPEN PRs        : #429 #428 #423 #420 #406
origin/main     : 7 commit(s) in last 12h · 6 NON-MERGE straight to main
   !! 5e392c6e Merge pull request #440 from itchyshin/claude/lane-mean-re-reml
LOCAL BRANCHES  : claude/lane-mean-re-reml   (foreign: claude)
LANE CENSUS     : ** 9 LANES LIVE **
COORD BOARD     : docs/dev-log/coordination-board.md -- COMMITTED to origin/main ✅
```

**Lane claimed:** `PLATFORM: cursor | LANE: cox-reid-probe (non-Gaussian VC scoping) | FOREIGN LANE: claude (direct-to-main, #440 mean-RE REML) + sibling cursor Shannon ef50c121 (PR debris #423/#428/#429)`

**Branch renamed** `claude/lane-cox-reid-probe` → `cursor/lane-cox-reid-probe`. `lane_launch.sh`
hardcodes a `claude/` prefix, and `lane_preflight.sh` infers platform from that prefix; leaving
it would have made a future census misattribute this Cursor lane to Claude. That is exactly the
signal corruption this role exists to prevent.

**No overlap with the foreign lanes.** #440 (Claude) added Gaussian `(1|g)` REML in
`src/gaussian_ranef.jl`; this lane **reads that as an oracle and never edits it**. The sibling
Cursor lane owns `test/runtests.jl` via #423/#428/#429; this lane writes no registered test.

---

## SWEEP RECEIPT (Phase 0.25 — default-closed)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `lane_preflight.sh` on Dropbox DRM.jl | FOREIGN LANE ACTIVE (claude direct-to-main); 9 live lanes; board committed to `origin/main` | New scratch lane; rename branch prefix; claim only the Cox–Reid subject |
| **brain** | MCP `search_notes` ×3, `search_all_projects: true`: "Cox-Reid adjusted profile likelihood variance component bias", "AGHQ … plateau", "Cox-Reid REML non-Gaussian GLMM bigger lever than AGHQ 1.7" | Canonical page found: `Two-lever fix for small-cluster non-Gaussian variance-component bias (AGHQ + Cox-Reid REML) — cross-repo map`, sourced **MEASURED** on drmTMB mc-0227 | **reuse** the diagnosis; do not re-derive; cite as drmTMB's numbers, not ours |
| **deterministic grep** | `rg -il 'Cox.?Reid' ~/shinichi-brain` | 30+ hits incl. `DECISIONS.md`, `LESSONS.md`, `WHAT-WORKS.md`, drmTMB ng-reml honesty notes | Cross-repo map is the single load-bearing page; others are downstream |
| **cross-repo status** | the map's SOURCE-CONFIRMED table (2026-07-18) | drmTMB ✗ (non-Gaussian REML **banned**, ledger mc-0243) · gllvmTMB ✗ (aborts non-Gaussian) · **HSquared.jl ✓ BUILT** (`fit_laplace_reml`, Gaussian-validated) | DRM.jl starts where drmTMB starts. HSquared.jl proves the lever is buildable in Julia — but **port later, not now** |
| **engine** | `rg -i reml src/sparse_laplace_glmm.jl` | **zero matches** — the non-Gaussian sparse-Laplace path is ML-only | Confirms the gap is real, not already half-built |
| **hook candidates** | `rg 'function .*reml\|_withreml' src/` | `_glsp_reml_penalty` / `_glsp_reml_refit_clean` / `_glsp_reml_vcov` (`src/gaussian_locscale_phylo.jl`) are generic over `(obj, grad_fn, pμ)`; `_withreml` (`src/gaussian_core.jl:169`) is family-agnostic | **The punch-through candidate.** Verify by CALLING it, not by reading it |
| **gradient contract** | read `_phylo_mean_laplace_fg`, `_poisson_crossed_laplace_fg` | Every route: `θ = [βμ(1:pμ); logσ…]`, exact analytic gradient, `_withnll(fit, nll, grad!)` stores BOTH closures on the `DrmFit` | The `(obj, grad_fn, pμ)` signature is already satisfied — post-hoc refit is possible from a finished ML fit |
| **integral path** | read `_fit_poisson_ranef` (`src/poisson.jl:149`) | Simple `(1\|g)` non-Gaussian uses **32-node Gauss–Hermite**, not 1-point Laplace | **Reframes the probe:** on that route the AGHQ lever is already paid, so residual σ̂ bias is *pure* ML bias — the cleanest possible isolation of the Cox–Reid lever |
| **oracle availability** | `rg 'Woodbury' src/gaussian_ranef.jl`; `gh pr view 440` | #440 (merged today) added exact Gaussian `(1\|g)` REML = ML Woodbury + `½logdet(Xμ′V⁻¹Xμ)` | A validated REML oracle exists **in-repo** for the reduction anchor. Read-only |
| **issue hygiene** | `gh issue view 136/11/49/439/440` | #136 CLOSED · #11 CLOSED · **#49 OPEN (PARKED)** · #439 CLOSED · #440 MERGED | New issue #441 opened; none of the above touched |
| **PR locks** | preflight `gh pr list` | #429 / #428 / #423 all own `test/runtests.jl` | Write **no** registered test; standalone file only |
| **compute (D-139)** | estimate before running | 3 cells × 60 seeds of small GHQ Poisson fits on Mac | **≤15 min, below the 30-min line ⇒ just run it.** No Totoro, no DRAC |
| **Verdict** | — | Genuine, unowned, evidence-backed work with an in-repo oracle and a named hook | **Proceed. Probe by measurement, not by reading.** |

---

## DECISION LOCK

**This G0 is a SCOPING PROBE. It measures and decides; it does not ship an estimator.**

The probe is designed so that three cheap cells settle the whole question:

- **Cell B — the reduction anchor.** Apply a *generic* Cox–Reid penalty `½logdet(I_ββ)` to a
  Gaussian `(1|g)` ML objective and compare against #440's independently validated exact
  REML. For a Gaussian LMM, `I_ββ = Xμ′V⁻¹Xμ` and Cox–Reid **is** Patterson–Thompson REML,
  so agreement here means the penalty is anchored rather than ad hoc. *This is the cell that
  converts "plausible" into "derived".*
- **Cell A — the clean bias isolation.** Poisson `(1|g)` runs GHQ-32, so integral error is
  already negligible; residual σ̂ bias is the ML finite-cluster effect alone. Sweep `G` to
  confirm the vault's *mechanism* (bias shrinks with M) on **our** engine, and check whether
  the penalty removes it.
- **Cell C — hook viability where it matters.** Call the wired Gaussian
  `_glsp_reml_penalty` / `_glsp_reml_refit_clean` **unmodified** against a non-Gaussian
  *sparse-Laplace* fit (Poisson phylo — the route #441 actually names). This is the
  difference between "a wiring job" and "a derivation job".

**Why Cox–Reid and not AGHQ:** the vault's node sweep converges by `nq≈5` then plateaus dead
flat at −5.0%; nodes cannot cross the variance-bias floor. Cox–Reid is the ~1.7× lever. And
on DRM.jl's `(1|g)` routes the integral lever is *already* paid at 32 nodes, which makes the
AGHQ-first ordering worse here than it was in drmTMB.

---

## SLICE TABLE

| ID | Arc | Lens | files / detail | dep |
|---|---|---|---|---|
| S0 | 0 | Shannon | Pre-flight; issue #441; `lane_launch.sh … --base origin/main`; rename branch prefix | — |
| S1 | 1 | Shannon | Overwrite the inherited `LOOP/` kit; commit | S0 |
| S2 | 2–3 | Noether | Map `sparse_laplace_glmm.jl`; name the hook; confirm the `(obj, grad_fn, pμ)` contract | S0 |
| S3 | 4–6 | Noether | `bench/cox_reid_probe.jl` — cells B, A, C; capture output to `bench/out/` | S2 |
| S4 | 7 | Curie | Standalone characterization test; **not** registered in `runtests.jl` | S3 |
| S5 | 8 | Noether + Pat | `docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md` — hook, cost, risks, go/no-go | S3 |
| S6 | 9 | Rose | After-task + check-log; claim-vs-evidence audit; next-G0 ordering | S5 |
| S7 | 10 | Shannon | PR against `main`; merge if CI green and Rose-clean | S6 |

**FAN-OUT:** 0 children. The probe is small and the lenses are cheap to hold in one session;
spawning would cost more context than it saves.
**COMPUTE:** Mac only. D-139 estimate ≤15 min, measured ~65 s per full probe run.
**MODELS:** Opus, owner-directed for this lane (overrides the usual two-bar default).

---

## Allowed paths (this lane only)

```
bench/cox_reid_probe.jl
bench/out/cox_reid_probe.txt
test/test_cox_reid_characterization.jl        # standalone; NOT added to runtests.jl
docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md
docs/dev-log/after-task/2026-08-18-cox-reid-scoping-probe.md
docs/dev-log/check-log.d/2026-08-18-cox-reid-scoping-probe.md
LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md
```

## File fence (must not include)

- `src/**` — no engine change in a scoping probe
- `test/runtests.jl` (#423 / #428 / #429 — sibling Shannon lane `ef50c121`)
- `src/reml_q4.jl`, bivariate q4, `test/parity/**`, every parity TSV
- `src/gaussian_ranef.jl` (#440, read-only oracle)
- `docs/dev-log/coordination-board.md` (#406)
- `docs/design/capability-status.md` — no capability chip flips from a probe

---

## ROSE PLAN-REVIEW

**What Rose blocks**

- Any sentence implying DRM.jl *has* non-Gaussian REML / Cox–Reid. It has a probe.
- Promoting drmTMB's `−7.3% → −5.0% → −0.9%` as DRM.jl measurements. Different package,
  different family, different cell. Cite them as drmTMB's.
- Coverage, calibration, or interval-reliability claims — none were measured.
- Flipping a capability chip, closing #136/#11/#49/#439, or touching D-111.
- Treating a favourable single-seed result as recovery evidence.

**What Rose accepts**

- *"A scoping probe on DRM.jl's scalar-per-cluster routes measured the ML
  variance-component bias, showed a generic Cox–Reid penalty reduces to the validated
  Gaussian REML, and identified the hook point."*
- An explicit go/no-go with its own caveats attached.

---

## DEFER (fenced)

- Cox–Reid **implement** G0 (the next one) · AGHQ port (the one after)
- HSquared.jl `fit_laplace_reml` kernel port · coverage / recovery certification
- `#136` VA · `:natgrad` · `#49` PARKED · `#11` · `#439`
- `runtests.jl` include · TSV flips · D-111 / Registrator · GPL vendoring · Totoro / DRAC
