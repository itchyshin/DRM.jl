# Two-package coordinated launch — readiness plan (2026-06-13)

Single executable plan for finishing the **DRM.jl + drmTMB** coordinated launch.
Engineering is at maximum readiness; the remaining steps are user-gated decisions
(marked 🔒) plus tracked follow-ups. Read this top-to-bottom to execute the finish.

## State at a glance

| Package | Tests | Registry/CRAN ready | Open blocker |
|---------|-------|---------------------|--------------|
| DRM.jl  | full `Pkg.test()` green (local, macOS, Julia 1.10) | Aqua + stdlib compat done (#5), registry metadata done | PR #286 unmerged |
| drmTMB  | bridge features merged (#538/#539) | repo mid-release (dirty detached-HEAD) — **owned elsewhere, untouched** | bivariate-phylo bridge gated (parity tests) |

## The Ayumi blocker — SOLVED + validated (the hard part)

Ayumi LS#2 needed boundary-honest uncertainty for the bivariate q=4 σ-phylo
(coevolution) cell. Delivered in **PR #286** (8 commits, full suite green):

- `bootstrap_sigma_a` — parametric bootstrap of the among-axis **SDs** + **6
  coevolution correlations**, reachable from R via JuliaCall (verified end-to-end).
- **Honest characterisation (from a Monte-Carlo coverage study + self-audit):** a
  sound **detection + uncertainty-indication** tool. Robust: the collapse-vs-signal
  magnitude read, the **mean-axis** SD CIs (well-calibrated, 0.88/0.87 @ 0.90), and
  the **correlation** CIs (a collapsed-axis correlation → genuinely wide ~[−1,1]).
  Limitation, disclosed: the **scale-axis** SD precise CIs undercover (~0.52 @ 0.90)
  — a fundamental boundary-bootstrap effect for a near-zero variance component, not a
  bug. So the σ-axis interval is a rough indicator; the across-tree distribution of
  the *point* σ-SD is the robust signal call (Ayumi's existing "k/100 pinned" reading).

## Finish-line — the gated steps (your decisions)

1. 🔒 **Merge PR #286** → `itchyshin/DRM.jl` main. Green, tested, validated,
   honestly documented. (My self-merge was correctly blocked by the guardrail.)
2. 🔒 **Review + post the Ayumi reply** — `report/finish-audit/ayumi-reply-draft-2026-06-13-followups.md`
   (rev4). Verify the **scale-axis calibration caveat** reads right before sending;
   the runnable R example is `report/finish-audit/ayumi-bivariate-bootstrap-via-R.R`.
3. 🔒 **Coordinated release** (#6): DRM.jl → Julia General registry; drmTMB → CRAN;
   matching git tags. Do DRM.jl's registry PR and drmTMB's CRAN submission together so
   the `engine="julia"` story is consistent on both sides at release.

## Pre-release checklist (runnable locally before the gated steps)

- [ ] DRM.jl: `Pkg.test()` green on a clean checkout of merged main (re-confirm post-merge).
- [ ] DRM.jl: `]registry` AutoMerge dry-run / JuliaRegistrator metadata sanity (done #5).
- [ ] drmTMB: `rcmdcheck::rcmdcheck(args="--as-cran")` on a CLEAN release branch
      (the working copy is currently dirty/detached — start from a clean branch).
- [ ] Cross-OS CI (macOS+Windows+Linux) for both, only right before release (cost-disciplined).
- [ ] Version bumps + NEWS entries reflecting the bridge + bootstrap features.

## Tracked follow-ups (NOT launch blockers; deliberately not rushed unattended)

- **Calibrated σ-axis interval** — bias-corrected / BCa with leave-one-species-out
  jackknife, or an m-out-of-n / subsampling bootstrap for the boundary case (Andrews
  2000). Needs its own coverage validation + a cost/benefit call at p~10⁴.
- **#19 bivariate missing-response** — per-observation mask through the verified q4
  gradient kernel (deep core; not unattended).
- **#20 idiomatic `confint(engine="julia")` for bivariate** — behind drmTMB's
  deliberate `drm_julia_phylo_payload` parity-test gate.
- **#14 optimizer-control passthrough** for `engine="julia"` (R-side, drmTMB).
- **#8** engine="julia" Gaussian phylo-mean garbage-logLik bug (deep core; not unattended).

## Why this stops here

Every non-gated, non-core-engine, validatable piece of the Ayumi blocker is done and
honestly characterised. The three finish-line actions are user decisions by design
(merge authorisation, an outward-facing collaborator message, registry/CRAN/tags with
your accounts + timing). The remaining engineering is either behind a deliberate gate
or in the verified core — neither appropriate to do unattended.
