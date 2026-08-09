# GOAL — drm-136e-va-bias-report (IMMUTABLE — re-read at the top of EVERY arc)

## Mission
Land one PR from `origin/main` @ `cc113cbb` that writes `report/va-vs-laplace-bias.md`:
an ADEMP comparison of public Gamma `(1 | g)` Laplace vs VA on shape
**α = 1/σ²**. Docs stay **Experimental**. Issue **#136 stays OPEN**.

## Headline
Measure the public path honestly. If simple Gamma RI does not reproduce
GLLVM’s ~7× two-part (Delta-Gamma) cell, say so (Rose). That still closes
136e-as-scoped.

## Invariants
- One DRM.jl ship lane. drmTMB sibling = other repo; do not start from here.
- Public path only: `drm(...; Gamma(); marginal=:LA|:VA)` with `sigma ~ 1` + `(1 | g)`.
- Estimand: `α = exp(-2 · coef(fit, :sigma)[1])`. ELBO ≠ logLik — do not compare as IC.
- No `src/` kernel rewrite unless smoke proves a kernel bug.
- No ZINB / Delta-Gamma / `zi`/`hu`×RE in this PR.
- Do **not** flip Experimental → Implemented. Do **not** `closes #136`.
- D-111 OFF. No q=4. No GPL. Never stage `.worktrees/`.
- Compute: local smoke first; Totoro only if n-ladder after a material α gap.
- Authoritative WHAT: `LOOP/ultra-plan.md`.

## Definition of done
- `report/va-vs-laplace-bias.md` exists with ADEMP + measured smoke numbers +
  explicit “not ZINB / not two-part / Experimental held / #136 open”
- Docs cite the report; Experimental banner unchanged
- check-log.d + after-task + Rose PASS
- PR open **without** `closes #136`; owner merges
