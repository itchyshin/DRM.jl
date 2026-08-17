# S2 schema — `biv_q4_phylo_reml` fixture layout

**Date:** 2026-08-16 · **Personas:** Boole + Hopper · no nested Task children
**Lane:** `claude/lane-biv-q4-phylo-reml` · **Issue:** #433
**Depends on:** S1 recon. Grammar mirrors `test/test_reml_q4_allaxes.jl` (reserved labels stay reserved; tree is a Newick sidecar, not a formula rewrite).

---

## Path (outside Workflow G glob)

`test/parity/runparity.jl` globs `test/parity/fixtures/*/expected.toml` and fits **ML, no tree**. This cell must not land there.

```
test/parity/q4-reml/biv-q4-phylo-reml/data.csv
test/parity/q4-reml/biv-q4-phylo-reml/tree.newick
test/parity/q4-reml/biv-q4-phylo-reml/expected.toml
test/parity/q4-reml/biv-q4-phylo-reml/expected.meta.toml
test/parity/gen_biv_q4_phylo_reml.R
test/test_parity_biv_q4_phylo_reml.jl
```

---

## `data.csv`

Columns: `y1`, `y2`, `x`, `species`. `species` matches Newick tip labels (`sp_1` … `sp_p`). p≈16, n_each≈5 (G0). No `tau`. No `rho12` as a data column.

---

## `tree.newick`

One Newick string ending in `;` (Julia `augmented_phy` requires the semicolon). Tips = `species` levels. Written by `ape::write.tree` in the generator; Julia reads the file as a string and passes `tree=`.

---

## `expected.toml`

```toml
[fit]
family = "biv_gaussian"
formula = "mu1 = y1 ~ x + phylo(1 | species); mu2 = y2 ~ x + phylo(1 | species); sigma1 = sigma1 ~ 1 + phylo(1 | species); sigma2 = sigma2 ~ 1 + phylo(1 | species); rho12 = rho12 ~ 1"
method = "REML"
loglik = <restricted logLik>
n = <nobs>
engine = "tmb"

[coef]
"mu1_(Intercept)" = …
"mu1_x" = …
# … name-matched to drm_coef_named / drmTMB flat_coef

[status]
converged = true
pdHess = true          # TMB sdr$pdHess or NA if absent
interval_status = "wald_finite" | "wald_unavailable" | "not_requested"
# no coverage / reliability numbers

[tol]
atol_loglik = 1e-3
atol_coef = 1e-3
rtol_coef = 1e-3
```

`[vcov]` is optional. This Mac-small cell may omit it (Julia property test uses `q4_vcov = false`). Status fields are required even when vcov is omitted.

Widen `[tol]` only if a measured same-target run shows the 1e-3 Workflow G default is too tight. Record the measured gap; do not invent equality.

---

## `expected.meta.toml`

```toml
drmtmb_version = "0.7.0"   # installed packageVersion; say the 0.6.0 Workflow G split
generated_on = "2026-08-16"
r_call = "drmTMB(bf(...), family = biv_gaussian(), data = dat, REML = TRUE, engine = \"tmb\", ...)"
seed = 20260816
n_tip = 16
n_each = 5
note = "Generated outputs only; no drmTMB source vendored. Workflow G fixtures remain 0.6.0 / ML / no tree. This cell is 0.7.0 REML + tree, outside the fixtures/ glob. Not a TSV supported flip. Not interval coverage or AI-REML."
```

---

## Grammar contract (Boole)

- Parameters: `mu1`, `mu2`, `sigma1`, `sigma2`, `rho12` (never `tau`).
- Residual correlation stays `rho12 ~ 1` — not a phylo block label.
- Julia marker: `phylo(1 | species)` + `tree=` kwarg.
- R marker: `phylo(1 | p | species, tree = tree)` with the **same** label `p` on all four axes (dense q4).
- Do not invent `rho12` as a covariance-block label.

---

## Test contract

Standalone `test/test_parity_biv_q4_phylo_reml.jl`. Run:

```bash
julia --project=. -e 'using DRM, Test; include("test/test_parity_biv_q4_phylo_reml.jl")'
```

Do **not** edit `test/runtests.jl`. Compare name-matched coef + `loglik`/`reml_loglik` within `[tol]`. Assert status keys exist and are recorded. Do not assert coverage.

`PLATFORM: cursor | ON BRANCH: claude/lane-biv-q4-phylo-reml | LANE: feat-biv-q4-phylo-reml-fixture`
