# 2026-08-18 — Cox–Reid wiring: opt-in `method = :REML` on Poisson phylo/relmat Laplace (#450)

**Lane:** `claude/lane-phylo-laplace-cox-reid` @ `~/local-scratch/lanes/DRM.jl-phylo-laplace-cox-reid`
(branch name is `lane_launch.sh`'s fixed prefix; this S5 session is **Cursor / Shannon+Pat**).
**Base of the wiring:** `origin/main` then S3/S4 to `8084532e`.
**Personas:** Shannon (lane) · Pat (docs/UX) · Rose (claim-vs-evidence, this note).
**No spawned subagents** this S5 slice.
**Closes #450** (when the sibling opens the PR). Does **not** close #448 / #443 / #136 / #11 / #49 / #441.

## What landed (S3–S5)

Opt-in restricted (Cox–Reid) estimation on the callers of `_fit_poisson_general_laplace`:
`phylo(1 | grp)` and `relmat` / `animal` / precomputed spatial. Public `(1 | g)` GHQ-32
stays on `_fit_poisson_ranef` (#443) and was not re-punched.

| Change | File | What it does |
|---|---|---|
| lift structured reject | `src/poisson.jl` (S4) | Admits `:REML` on phylo/relmat/animal/precomputed-spatial; keeps rejecting coordinate-spatial estimated-ρ, crossed, slopes, VA, FE-only |
| thread `reml` | `src/sparse_laplace_glmm.jl` (S4) | After `_withnll`, reuse `_glsp_reml_refit_clean` / `_glsp_reml_vcov` / `_withreml` (#444 helpers, unmodified) |
| reject copy | `src/variational.jl` (S4) | Names the two wired Poisson cells (#443 + #450) |
| standalone test | `test/test_cox_reid_poisson_phylo.jl` (S3) | 27 assertions. **Not** in `runtests.jl` |
| public docstring | `src/poisson.jl` `Poisson()` (S4) | Worked phylo `:REML` example + Cell D / over-correction warnings. S5 did **not** re-edit `src/` — the warning was already there |
| this ledger | `LOOP/` + check-log.d + this after-task (S5) | Honesty + resume pointer. No chip |

**Nothing was derived.** Same helpers as #444. This spine already has an analytic `grad!`.

## Honesty ledger (Rose)

- **Cell D is not a recovery result.** Probe ntip=16 / 12 seeds: ML **+8.18%**, CR **+17.41%**.
  Underpowered for a Laplace-bias *sign* claim. Tests assert direction and mechanism only
  (σ̂_CR > σ̂_ML per seed; `reml_loglik ≠ ml_loglik`; uncertified routes error). Evidence:
  `docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md`.
- **Twin = drmTMB** (mechanism only: `½ log|I_ββ|`, ML default). drmTMB's −7.3 / −5.0 / −0.9
  stay attributed to drmTMB (`cumulative_logit`, different package / family / cell).
  **Never vendor drmTMB GPL source.**
- **No GLLVM Λ.** Hopper fence: DRM.jl REs are scalar-per-cluster; GLLVM loading-matrix
  numbers do not transfer (`docs/dev-log/evidence/2026-08-18-hopper-cox-reid-gllvm-fence.md`).
- **No ADEMP this G0.** Larger-tree recovery is a follow-on. Do not headline bias-sign
  from Cell D. Do not write a recovery sentence.
- **This is one cell, not a capability.** No TSV row, no capability chip, no
  "DRM.jl has non-Gaussian REML". Binomial / NB2 / Gamma / Beta stay ML-only
  *by construction*. Crossed / slopes / estimated-ρ / VA / FE-only still error.
- **ML remains the default.** `:REML` is opt-in on phylo/relmat Laplace (and the
  already-wired GHQ `(1 | g)` cell). Over-correction is possible.

## Verification

- **27/27** on standalone `test/test_cox_reid_poisson_phylo.jl`, **verified twice**
  during S3/S4. Command:
  `julia --project=. -e 'include("test/test_cox_reid_poisson_phylo.jl")'`.
- This S5 slice did **not** re-run the suite (S6 already that verify). Did not
  run default `Pkg.test()` as a coverage claim — the file is outside `runtests.jl`.
- Public docstring already present at S4 tip `8084532e`; S5 confirms no further
  `src/` punch was needed.

## Fence held

No AGHQ worktree / PR #449 files. No second AGHQ issue. No `test/runtests.jl`.
No capability chip. No q4 / `src/reml_q4.jl`. No `src/gaussian_ranef.jl`.
No GLLVM Λ numbers. No GPL vendoring. No default flip. No ADEMP. No `gh pr create`.
No `gh pr merge`. `docs/a3c-design` / catchup / handover leftover untouched.

## Lane coordination (Shannon)

Pre-flight this S5: `PLATFORM: cursor` · `ON BRANCH: claude/lane-phylo-laplace-cox-reid` ·
`LANE: phylo-laplace-cox-reid / #450`. Census printed **2 lanes live** (main-direct +
worktree×35). **Foreign = AGHQ PR #449** (`~/local-scratch/lanes/DRM.jl-aghq-lever-2`) —
not touched. Coordination board is committed on `origin/main`. Silence is weak
evidence (D-87). Overlap with A is `src/poisson.jl` dispatch: B's hunks stay off
`marginal = :AGHQ`.

## Next

S7 — sibling opens the PR (`closes #450`). **Human merges.** This worker does not
`gh pr create` / `gh pr merge`. Then S8 Melissa plan-vs-actual.
