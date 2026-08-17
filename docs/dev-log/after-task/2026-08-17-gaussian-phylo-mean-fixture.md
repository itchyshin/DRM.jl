# 2026-08-17 — `gaussian_phylo_mean` Route A same-target fixture

**Lane:** `feat-gaussian-phylo-mean-fixture` on `claude/lane-gaussian-phylo-mean`
in `~/local-scratch/lanes/DRM.jl-gaussian-phylo-mean`.
**Personas:** Shannon (conductor) · Hopper · Boole · Curie · Rose · Ada · Melissa.
**Nested Task subagents:** none (conductor ran S1–S8 on Cursor Grok; consumed
sibling S1 / S5 / morning Rose fence from catchup evidence).
**closes:** #437

This PR adds a same-target fixture for `gaussian_phylo_mean` within the
row's declared tolerance. `claim_status` stays **partial**;
`r_bridge_status` stays **experimental**. No TSV `supported` flip.
#136 stays OPEN. #49 stays PARKED. Does not widen to `sigma ~ phylo(...)`.
Does not claim "R–Julia parity complete," "last fixture-gap," or close #136.
Quote: first phylo-mean (sigma ~ 1) marshalling/result-shape + optional live
TMB parity; not loc-scale phylo or non-Gaussian phylo.

Inventory class stays **TSV-claim / Phase 1.5 admitted**. After #434 the
`#432` `fixture-gap` class is empty; this PR banks the missing hermetic
Route A artefact. Direct DRM.jl evidence is not R-via-Julia bridge support.
Workflow G metas stay drmTMB **0.6.0**; this cell records **0.7.0**.

## What landed

- Generator `test/parity/gen_gaussian_phylo_mean.R` (does not edit `gen_fixtures.R`)
- Fixture `test/parity/phylo-mean/gaussian-phylo-mean/` (outside the Workflow G glob)
- Standalone `test/test_parity_gaussian_phylo_mean.jl` (does not touch `runtests.jl`)
- Evidence: sibling S1 recon, S2 schema, sibling S5 Rose fence, morning Rose fence

## Worked example

```julia
using DRM, Test
include("test/test_parity_gaussian_phylo_mean.jl")
```

Public call (same grammar as `test/test_bridge.jl`):

```julia
fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
          Gaussian(); data = dat, tree = tree)
```

## S4 Curie smoke (log, not exit code)

Native TMB `drmTMB(..., engine = "tmb")` on Mac (generator log):

| kind | seed | n_tip | n_each | conv | logLik |
|---|---|---|---|---|---|
| **route_a** | **111** | **18** | **1** | **0** | **−13.2682815489054** |

First attempt (live Route A clone) converged. No reseed. No Totoro/DRAC.

R status recorded: `converged=true`, `pdHess=true`,
`interval_status=wald_unavailable` (Wald warning on the phylo SD boundary;
not a coverage claim). drmTMB **0.7.0**. n=18.

Julia re-fit on the same CSV + Newick (log, 2026-08-17):

```
julia_loglik=-13.268281551632521
tmb_loglik=-13.268281548905353
d_loglik=-2.727167824900789e-9
julia_converged=true method=ML
mu_(Intercept) d=-5.500733202268293e-11
mu_x           d=-2.5129343050878106e-12
sigma_(Intercept) d=8.491656600106978e-9
```

Declared `[tol]`: `atol_loglik=1e-6`, `atol_coef=1e-5`, `rtol_coef=1e-5`
(live Route A class; **not** #434 `atol_loglik=6.0`). Measured gap is
orders of magnitude inside. Standalone test: **27 passed / 0 failed**.

Julia warned that the raw `rcoal` tree height is 1.684 (sd_phylo scale
differs from drmTMB's `ape::vcv(..., corr=TRUE)`). This cell compares
**FE coef + logLik only** (`:resd` / phylocov skipped). No scale rewrite.

## S5 Rose

Consumed sibling `docs/dev-log/evidence/2026-08-17-gaussian-phylo-mean-s5-rose.md`
and morning `2026-08-17-morning-rose-fence.md`.

Sweep: no "parity complete"; no "last fixture-gap"; no TSV flip; no
sigma-phylo widen; GPL = generated outputs only; taxonomy split stated;
`#136` OPEN; `#49` PARKED; D-111 OFF; D-94 = behind drmTMB not GLLVM.

## Fence held

No `src/` · no `test/runtests.jl` · no TSV · no Workflow G harness ·
no `#423`/`#428`/`#429`/`#420`/`#406` files · no drmTMB checkout ·
LOOP/ on `origin/main` left untouched (leftover campaign kit; this PR
is fixture-only).
