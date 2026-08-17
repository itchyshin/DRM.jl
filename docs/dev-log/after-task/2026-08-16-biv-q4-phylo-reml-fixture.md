# 2026-08-16 — `biv_q4_phylo_reml` same-target fixture

**Lane:** `feat-biv-q4-phylo-reml-fixture` on `claude/lane-biv-q4-phylo-reml`
in `~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml`.
**Personas:** Shannon (conductor) · Hopper · Boole · Curie · Rose · Ada · Melissa.
**Nested Task subagents:** none (conductor ran S1–S7 on Cursor Grok).
**closes:** #433

This PR adds a native-vs-Julia same-target fixture for `biv_q4_phylo_reml`
within the row's declared tolerance. `claim_status` stays **partial**;
`r_bridge_status` stays **experimental**. No TSV `supported` flip.
#136 stays OPEN. Direct DRM.jl evidence is not R-via-Julia bridge support.
Does not claim interval reliability, coverage, AI-REML, or "R–Julia parity complete."
Quote: this Julia row does not establish same-target bridge parity, interval
reliability, or HSquared AI-REML support.

## What landed

- Generator `test/parity/gen_biv_q4_phylo_reml.R` (does not edit `gen_fixtures.R`)
- Fixture `test/parity/q4-reml/biv-q4-phylo-reml/` (outside the Workflow G glob)
- Standalone `test/test_parity_biv_q4_phylo_reml.jl` (does not touch `runtests.jl`)
- Evidence: recon, schema, sibling Rose fence
- LOOP/ kit for this G0 (not the #432 inventory kit)

## Worked example

```julia
using DRM, Test
include("test/test_parity_biv_q4_phylo_reml.jl")
```

Public call (same grammar as `test_reml_q4_allaxes.jl`):

```julia
form = bf(mu1    = @formula(y1 ~ x + phylo(1 | species)),
          mu2    = @formula(y2 ~ x + phylo(1 | species)),
          sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
          sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
          rho12  = @formula(rho12 ~ 1))
drm(form, Gaussian(); data, tree, method = :REML, q4_vcov = false)
```

## S4 Curie smoke (log, not exit code)

Native TMB `drmTMB(..., REML = TRUE, engine = "tmb")` on Mac:

| seed | n_tip | n_each | conv | logLik |
|---|---|---|---|---|
| 20260816 | 16 | 5 | 1 | −132.75 |
| 20260817 | 16 | 5 | 1 | −181.46 |
| 20260820 | 16 | 5 | 1 | −119.35 |
| 20260821 | 16 | 5 | 1 | −144.52 |
| 20260818 | 16 | 8 | 1 | −205.62 |
| **20260822** | **16** | **8** | **0** | **−219.6139863046289** |

Reseed + n_each 5→8 stayed Mac-small. Did not escalate to Totoro/DRAC.

R status recorded: `converged=true`, `pdHess=true`, `interval_status=wald_unavailable`.
drmTMB **0.7.0**. n=128.

Julia re-fit on the same CSV + Newick (log, 2026-08-16):

```
julia converged=false method=REML
julia loglik=-225.24313853493464
r    loglik=-219.6139863046289  dloglik=-5.629152230305749
max |d_coef| ≈ 0.032 (sigma2 intercept); mu1_x Δ ≈ 4e-6
```

Standalone test after declaring that measured `[tol]`: **33 passed / 0 failed**.

Restriction difference (do not hide): native TMB REML restricts **mean** fixed
effects; DRM.jl `reml_q4` profiles **mean and scale**. logLik is not a 1e-3
Workflow G twin. The declared tolerance is this measured gap.

## S5 Rose

See `docs/dev-log/evidence/2026-08-16-biv-q4-s5-rose-fence.md` (sibling refresh).
Sweep: no "parity complete"; no TSV; no coverage/AI-REML; no bridge-export rewrite;
GPL = generated outputs only; `#136` OPEN; D-111 OFF.

## S7 mechanical

- Fixture dir exists; meta has 0.7.0 + r_call + seed 20260822
- Test file exists and was run (33/33)
- `git diff origin/main -- src/ test/runtests.jl test/parity/runparity.jl test/parity/gen_fixtures.R` empty
- No TSV / capability-status edit
- No drmTMB checkout (read-only `git show` + installed library)
- No full `Pkg.test`

## What this did NOT cover

The other 10 unsigned rows. TSV `supported`. `runtests.jl` include. Workflow G
glob. Interval coverage / reliability. AI-REML. R-via-Julia bridge admission.
`src/` engine changes. Totoro recovery-grade (p≳200). `#428` / `#136` / `#49`.
