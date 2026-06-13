# Recovery checkpoint — σ-phylo REML Newton (autonomous session, 2026-06-12 evening)

**Worktree:** `DRM-integrate` → branch `shannon/land-sigma-phylo`. **Nothing pushed.**
**Goal in effect:** "finish the plan, work autonomously till ~5am, hold questions."

## ⚠ LATEST (read first — supersedes the Newton framing below)

The adversarial verification (the gate noted as "pending" below) **completed and found 12
confirmed bugs** in the observed-info Newton — a BLOCKING boundary crash + a HIGH β-coupling
correctness bug my benign tests missed. **All fixed + committed (`ff7df6c`):** the production
`drm(:REML)` path is now the **jointly-correct, boundary-robust clean-gradient LBFGS**; the
observed-info **Newton is demoted to EXPERIMENTAL**. Added: penalty-finite + guarded line
search (crash 0/40), Wald-V PD-guard, coupled-route :REML error guard, a boundary regression
test, doc honesty. Verified: boundary 12/12, end-to-end 12/12, p=120 match confirmed earlier.
A **focused re-verification** then caught a bug MY fix introduced: the Inf→1e18 boundary-crash
fix made the penalty sentinel finite, so it leaked −1e18 into reml_loglik/AIC/BIC on a
collinear (rank-deficient) mean design. **Fixed (`522180a`)**: sanitize reml_nll (sentinel→NaN,
consistent with the Wald-V path) + a collinear regression test; all other 11 findings confirmed
addressed. The REML slice is now through TWO verification passes, fully verified.
Commits: a5bcb3f, f2ee141, 10286dc, 2a95229, ff7df6c, a2667ac, (checkpoint), **522180a**.
Everything below describes the Newton as production — that was BEFORE the verification; the
clean-LBFGS is now production.

## State: what is DONE + VERIFIED (local commits)

- `a5bcb3f` — fast **observed-information Newton REML** for the σ-phylo location-scale model.
  - Replaces the slow substance-judged FD-REML refit; wired into `drm(method=:REML)` for the
    asymmetric (K=1) and separate (K=2, both axes) routes, with a clean-gradient LBFGS fallback.
  - **Finding (panel-proven):** the literal average-information data-quadratic is INVALID here
    (`â` is the shrunk BLUP, ~5× too small) → the metric is the OBSERVED information (central
    FD of the exact O(p) score). "AI-REML" naming dropped throughout.
  - Verified: K=1 & K=2 match FD-REML to ~5 dp in 3 steps; end-to-end `drm(:REML)` 12/12, 4.5×
    faster (77s→17s) at p=24.
- `f2ee141` — **safeguarded** the Newton after a benchmark caught a robustness bug.
  - The unguarded Newton **diverged at p≥120** (σ-SD → ≈7) and step count was fixture-dependent.
  - Fixes: (1) backtracking line search (monotone descent ⇒ no divergence); (2) scale-free
    convergence (step size in log-SD, not the n-scaling score).
  - Verified: p=60/120/250 all converge (1–4 steps) to sane σ-SD; K=1/K=2 still match; 12/12.

Records: `docs/dev-log/after-task/2026-06-12-observed-info-newton-reml.md` (the full write-up).
Bench: `bench/bench_reml_newton.jl` (the catch), `bench/check_newton_robust.jl`, `bench/check_p120_match.jl`.

## Running at checkpoint time (background — will notify)

- `b4p07o02p` — p=120 FD-REML-vs-Newton large-p MATCH check (FD-REML half is ~4.5 min).
- `wn3x9fobp` — adversarial verification workflow over the slice (correctness / robustness /
  integration / scope-honesty), each finding adversarially re-checked. **Reconcile its findings.**

## Pending / next (in priority order)

1. **Reconcile the verification workflow findings** — address any confirmed blocking/high items;
   the robustness fix already covers the "maxit cap-out / divergence" class.
2. **Confirm the p=120 match** (b4p07o02p) — expect Newton σ-SD ≈ FD-REML σ-SD (same objective,
   monotone descent ⇒ same optimum). If a real gap, tighten the step tol.
3. **Coupled K=3 route** — the general `_glsp_reml_newton` already handles K≥1; the coupled
   branch of `_fit_gaussian_locscale_phylo` has NO reml wiring yet (secondary capability).
4. **Cross-engine benchmark** — BLOCKED: σ-phylo location-scale has no native R baseline;
   glmmTMB here is TMB-version-mismatched (1.9.17 vs 1.9.21). Speed story is the O(p) Julia
   engine + few-step Newton (measured internally). ASReml comparison genuinely pending.

## ★ Ayumi R↔Julia bridge — MISSING VALUES (standing user requirement, 2026-06-12)

User: "the R-Julia bridge for Ayumi needs to include missing values (responses — if not hard;
predictors — we need to build all of them at some point)." So the Ayumi delivery is now:
**σ-phylo Gaussian REML (now production-correct on this branch) + missing values, reachable
from R via `engine="julia"`.** Priority: **missing RESPONSES first** (largely built already on
branch `codex/missing-response-bridge` — Gaussian + non-Gaussian response-missing + the
`drm_bridge` primitive), **missing PREDICTORS later** (FIML / latent integration per
`report/fiml-missing-data-design.md` + `~/.claude/memory/design-missing-data-drmtmb-gllvmtmb.md`
— build "all of them at some point"). Key integration fact: the σ-phylo REML lives on
`shannon/land-sigma-phylo`; the missing-response bridge on `codex/missing-response-bridge` — the
two must combine, and the drmTMB `reml_supported` gate (julia-bridge.R ~98) must be relaxed for
the σ-phylo cell. A scout workflow (`w89utibd1`) is mapping the exact gap + a parallel build plan.

## Held — USER-GATED (do NOT do autonomously)

`git push`; the Ayumi reply; the GLLVM cross-pollination brief. All wait for explicit go-ahead.
(Building the bridge + missing-value support LOCALLY is not gated — only the push / Ayumi post.)

## Honesty notes

- The "3 steps / 4.5×" headline is **fixture-specific** (small p); at large p it's 1–4 steps and
  the speedup vs the old FD-REML is larger but the cross-engine number is unmeasured.
- The dashboard widget (`/tmp/drm-dashboard`, port 8765) is kept current with this state.
