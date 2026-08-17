# S2 schema — `gaussian_phylo_mean` Route A hermetic fixture

**Date:** 2026-08-17 · **Personas:** Boole + Hopper · **Lane:**
`claude/lane-gaussian-phylo-mean` (scratch
`DRM.jl-gaussian-phylo-mean`). Consumed sibling S1
(`2026-08-17-gaussian-phylo-mean-s1.md`) and morning Rose fence.
**Did not claim:** `src/` · `test/runtests.jl` · TSV · `#423`/`#428` files.

G0 LOCKED: Mac-small live Route A clone (`n_tip=18`, seed `111`,
`n_each=1`); standalone test; formula
`bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`, ML.

---

## Slug (outside Workflow G)

```
test/parity/phylo-mean/gaussian-phylo-mean/
  data.csv
  tree.newick
  expected.toml
  expected.meta.toml
```

`test/parity/runparity.jl` globs `fixtures/*/expected.toml` and fits
`drm(bundle, fam; data = data)` — ML, **no `tree=`**. This cell cannot
join that glob (same reason `#434` used `q4-reml/`).

Generator: `test/parity/gen_gaussian_phylo_mean.R` (new file; do **not**
edit `gen_fixtures.R`).
Test: `test/test_parity_gaussian_phylo_mean.jl` (standalone; do **not**
edit `test/runtests.jl`).

---

## `expected.toml`

```toml
[fit]
family = "gaussian"
formula = "y ~ x + phylo(1 | species); sigma ~ 1"
method = "ML"
engine = "tmb"
loglik = <native TMB logLik>
n = 18

[coef]
"mu_(Intercept)" = …
"mu_x" = …
"sigma_(Intercept)" = …
# only name-matched FE keys from drmTMB::coef(); do not invent phylocov / resd

[status]
converged = true
pdHess = <bool or recorded>
# optional interval_status if cheap; not a coverage claim

[tol]
# tight ML tols — NOT #434's atol_loglik=6.0
# start from live Route A (logLik 1e-6, coef 1e-5); loosen only if a
# measured same-data gap requires it, and record the measurement
atol_loglik = 1e-6
atol_coef = 1e-5
rtol_coef = 1e-5
```

## `expected.meta.toml`

| key | value |
|---|---|
| `drmtmb_version` | `"0.7.0"` (installed; say the Workflow G **0.6.0** split) |
| `generated_on` | ISO date |
| `r_call` | `drmTMB(bf(y ~ x + phylo(1 \| species, tree = tree), sigma ~ 1), family = gaussian(), data = dat, engine = "tmb")` |
| `seed` | `111` (Route A clone; record if reseeded) |
| `n_tip` | `18` |
| `n_each` | `1` |
| `with_x` | `true` |
| `note` | generated outputs only; not a TSV flip; not last fixture-gap; ML / `sigma ~ 1` |

## Julia call (sidecar tree)

```julia
drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
    Gaussian(); data = dat, tree = tree_newick)
```

R puts `tree=` inside `phylo()`. Julia puts `tree=` on `drm()`.
Do not rewrite the formula to `sigma ~ phylo(...)`.

## Payload

**coef + logLik** (name-matched). Fit-status recorded if cheap. Not
coverage. Not R-via-Julia bridge admission.

## Fallback (only if seed 111 fails to converge)

Record the attempt. Next: `n_tip=16`, `n_each=4`, new seed — still
Mac-small. Do **not** silently escalate to Totoro/DRAC.

## Fence

No `src/` · no TSV `supported` · no `runtests.jl` · no `#434` numbers ·
no `atol_loglik=6` · inventory class stays TSV-claim.
