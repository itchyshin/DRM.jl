# Hopper S1 recon — `gaussian_phylo_mean` Route A fixture

**Date:** 2026-08-17 · **Persona:** Hopper · no spawned subagents · **read-only**
**Lane taken:** `hopper-recon-gaussian-phylo-mean-s1` (this catchup evidence file only).
**Did not claim:** `#428` / `#423` / `#429` / leftover `docs/a3c-design` / `src/` / `test/runtests.jl` / TSV.
**drmTMB:** `git show origin/main:…` only. **Never checked out** the shared tree
(still leftover `claude/handover-freshness-0718`; dirty; left untouched).
**No GPL source** copied. Public names + test *call signatures* + TSV fields only.

**Anchors**

| Surface | This pass |
|---|---|
| DRM.jl tip | `origin/main` `5ddaffa9` (merge `#425`; `#434` already in history) |
| drmTMB tip | `origin/main` `d9fddfa28` (DESCRIPTION **0.7.0**) |
| Prior pick | scratch `2026-08-16-next-arc-hopper-pick.md` |
| Prior S1 | scratch `2026-08-16-arc1-recon-s1.md` §3 (NONE fixture — still true) |
| Pattern donor | `#434` `test/parity/q4-reml/biv-q4-phylo-reml/` (outside Workflow G glob) |

`PLATFORM: cursor | LANE: hopper-recon-gaussian-phylo-mean-s1 | OTHER LANES: #429 #428 #423 #421 #420 #406 + leftover docs/a3c-design + leftover catchup LOOP + claude/lane-arc1-backlog-after-434`

Deepens (does not replace) the 2026-08-16 pick. This note is the **call-path + size** recon for a Route A hermetic-fixture ultra-plan.

---

## 1. Existing Julia gaussian phylo-mean path (already wired)

Public surface — **mean phylo + constant scale**. Scoreboard B:
`Gaussian phylogenetic random intercept (mean)` = **implemented**.
`algorithm = :auto` is the all-node sparse L-BFGS cell.

```julia
fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
          Gaussian(); data = dat, tree = phy)
```

Witnesses (same grammar; **no R numbers**):

| File | Size | Role |
|---|---|---|
| `docs/src/tutorials/phylogenetic-models.md` | `G` tips × `m=4` | reader call |
| `test/test_bridge.jl` | **G=16, m=4, n=64** | native `drm` ↔ `drm_bridge` result-shape + profile/bootstrap smoke |
| `test/test_conjugate_em.jl` | **G=64, m=4, n=256** | `:auto` ≡ `:sparse_lbfgs`; `:em` / `:gls` same surface on a *balanced* tree |
| `docs/src/r-julia-bridge.md` | — | first Gaussian `phylo(1 \| species)` mean + constant `sigma` is the admitted bridge cell |

Dispatch (`src/gaussian_core.jl` `drm(::DrmFormula, ::Gaussian)`):

| Step | Symbol | What happens |
|---|---|---|
| Guard | `structured_sigma === nothing` | `sigma ~ phylo(...)` is a **different** row (loc-scale). Do not take that branch. |
| Cell | `structured[1] === :phylo` + `sigma ~ 1` + no extra RE | first phylo-mean |
| Default | `algorithm in (:auto, :sparse_lbfgs)` | `_fit_structured_gaussian_sparse_lbfgs` in `src/location_only.jl` |
| Opt-in | `algorithm = :em` | `_fit_structured_gaussian_em` (same file; NaN vcov) |
| Legacy | `:gls` / `:lbfgs` | dense `_fit_structured_gaussian` via `_phylo_correlation` |
| Tree | `tree=` on `drm()` | `AugmentedPhy` or Newick `AbstractString` → `augmented_phy` |

`:auto` on this cell is **ML** (default). Univariate Gaussian `method = :REML` **throws** when any structured/phylo term is present (`gaussian_core.jl` guard). Do not reuse `loconly-gaussian-phylo-reml-v1` (G=6, n_per=2, supplied-variance REML diagnostic) or `#434` q4 REML numbers.

**Not this cell:** `src/gaussian_locscale_phylo.jl` / `test/test_gaussian_locscale_phylo.jl` (`sigma ~ phylo`); `test/test_gaussian_bivariate_phylo.jl` (q=4); non-Gaussian `_fit_phylo_mean_laplace_*` in `src/sparse_laplace_glmm.jl`.

---

## 2. Parity fixtures — still NONE

`git ls-tree origin/main:test/parity`:

| Location | `gaussian_phylo_mean`? |
|---|---|
| `test/parity/fixtures/` | **NONE**. Dirs are the eleven Workflow G FE/loc-scale/biv-rho12/meta/… cells. No `gaussian-phylo*`. |
| `test/parity/q4-reml/` | only `biv-q4-phylo-reml` (`#434`) |
| `docs/dev-log/evidence/parity-fixtures.tsv` | **no phylo rows** (`base_gaussian_*`, FE families only) |
| `test/parity/runparity.jl` | globs `fixtures/*/expected.toml`; **ML; no tree**. A phylo `expected.toml` **cannot** join that glob (same reason `#434` sat outside). |
| `test/parity/{README,gen_fixtures.R,runparity.jl,runparity_bridge.jl}` | no `phylo` / `tree` |

Julia has **result-shape** (`test/test_bridge.jl`) and **solver-agreement** (`test/test_conjugate_em.jl`). What is missing is a committed **same-target** `data.csv` + `tree.newick` + `expected.toml` (native TMB coef + logLik + fit-status) so CI does not depend on the live skip-guard.

`#434` pattern to copy: new slug **outside** `fixtures/`; new generator (do **not** edit `gen_fixtures.R`); standalone Julia test (do **not** edit `test/runtests.jl` while `#423`/`#428` own it); do **not** edit `tools/parity_ledger.py`.

Suggested slug (not minted here): `test/parity/phylo-mean/gaussian-phylo-mean/`.

---

## 3. drmTMB twin call (Route A) — `git show` only

TSV row `gaussian_phylo_mean` @ `d9fddfa28` (quoted):

| Field | Value |
|---|---|
| route | `phylo` |
| syntax | `bf(y ~ x + phylo(1 \| species, tree = tree), sigma ~ 1), family = gaussian(), engine = "julia"` |
| claim_status | `partial` |
| claim_boundary | Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (`sigma ~ 1`) marshalling/result-shape + optional live TMB parity; **not** loc-scale phylo or non-Gaussian phylo. |
| next_action | Keep first phylo-mean result-shape and Route A parity tests; **do not widen to sigma-phylo**. |
| issue | drmTMB#544 |

Live skip-guarded twin — `tests/testthat/test-julia-tmb-parity.R`
`drm_parity_fit_route_a()` +
`test_that("engine='julia' == engine='tmb' to <=1e-6 on Gaussian phylo-mean (Route A)")`:

```r
set.seed(111L)
n <- 18L
tree <- ape::rcoal(n)
species <- tree$tip.label
dat <- data.frame(
  species = sample(species),
  x = seq(-1, 1, length.out = n)
)
phy <- stats::setNames(stats::rnorm(n, 0, 0.45), species)
dat$y <- 0.4 + 0.7 * dat$x + phy[dat$species] + stats::rnorm(n, 0, 0.35)
form <- drmTMB::bf(
  y ~ x + phylo(1 | species, tree = tree),
  sigma ~ 1
)
ft <- drmTMB::drmTMB(form, family = stats::gaussian(), data = dat, engine = "tmb")
fj <- drmTMB::drmTMB(form, family = stats::gaussian(), data = dat, engine = "julia")
```

Live tols (already claimed by that test; **not** re-measured this pass):
logLik `|TMB − Julia| < 1e-6`; coef `max|Δ| < 1e-5`; all three of TMB / direct-bridge / `engine="julia"` converged.

Grammar (Hopper): R puts `tree=` **inside** `phylo()`; Julia puts `tree=` on `drm()`.
No shared q4 label `1 | p | species` — that is `#434`. Unlabelled `phylo(1 | species)` is this cell.

For a **hermetic** fixture, generate against **native `engine = "tmb"`** (generated outputs only). `engine = "julia"` is the live skip-guard, not the committed oracle. Campaign metas: Workflow G still records drmTMB **0.6.0**; this cell should record **0.7.0** (say the split).

---

## 4. Mac-safe sizes

| Cell | n_tip | n_each | n | Tree | Verdict |
|---|---|---|---|---|---|
| **Live Route A** | **18** | **1** | **18** | `ape::rcoal`, seed `111` | **Mac-tiny. Clone first.** Already the live 1e-6 twin. |
| Julia bridge smoke | 16 | 4 | 64 | `random_balanced_tree` | Mac-tiny fallback if 1-obs/tip is too thin |
| Tutorial / EM reject | 24 | 4 | 96 | balanced | still Mac-easy |
| Julia EM/LBFGS anchor | 64 | 4 | 256 | balanced (needed for EM≡GLS β) | Mac-ok but heavier than a fixture needs |
| `#434` q4 REML | 16 | 8 | 128 | `ape::rcoal`, seed `20260822` | Mac-small **but wrong model** (biv + REML). Do not reuse numbers. |
| loconly REML v1 | 6 | 2 | 12 | balanced | **wrong estimand** (supplied-variance REML) |
| AVONET bench | 9,993 | 1 | 9,993 | Hackett | **not** this slice |
| Recovery-grade phylo | ≥200 | ≥10 | ≥2,000 | — | Totoro/DRAC; not Mac fixture |

**Recommend:** bank the live Route A sizes (`n_tip=18`, `n_each=1`, seed `111`, `ape::rcoal`) unless TMB fails to converge on a committed re-run — then fall back to **n_tip=16, n_each=4, n=64** (bridge-smoke class). Stay ≤256 rows. Do **not** force a balanced tree just to match `:em`/`:gls`; the twin is TMB ML ↔ Julia `:auto` sparse L-BFGS, and Route A already uses `rcoal`.

Unlike `#434`, this cell has **no structural mean-vs-mean+scale REML gap**. Expect Workflow G-class tols (`atol_loglik ≈ 1e-6` … `1e-3`) unless a measured gap appears. Do not pre-declare `atol_loglik=6.0`.

---

## 5. Fence (for the ultra-plan)

- Fixture + standalone test only. **No TSV `supported` flip** (`#1049` OPEN).
- Do not widen to `sigma ~ phylo(...)`, loc-scale, non-Gaussian phylo, or q4.
- Do not edit `gen_fixtures.R` / `runparity.jl` / `test/runtests.jl` / `tools/parity_ledger.py`.
- Generated outputs only (MIT). Never vendor drmTMB source. Never checkout the shared drmTMB tree to generate — use an **installed** drmTMB on a maintainer machine, write into DRM.jl only.
- Rose-allowed claim: *this PR adds a same-target fixture for `gaussian_phylo_mean` within the row’s declared tolerance* — not “R–Julia parity complete.”
- Soft collision: `#425` just merged (`5ddaffa9`); it owned binomial/sparse Laplace, not this Gaussian mean cell. Still do not touch `src/sparse_laplace_glmm.jl`.

---

## Sources

- `git show origin/main:src/gaussian_core.jl` dispatch + `src/location_only.jl` `_fit_structured_gaussian_{sparse_lbfgs,em}`
- `test/test_bridge.jl` (G=16×4); `test/test_conjugate_em.jl` (G=64×4)
- `git ls-tree origin/main:test/parity/{fixtures,q4-reml}`
- `git show origin/main:docs/dev-log/evidence/parity-fixtures.tsv` (no phylo rows)
- `git show origin/main:inst/extdata/julia-capabilities.tsv` @ drmTMB `d9fddfa28` (via `git -C … show`; no checkout)
- `git show origin/main:tests/testthat/test-julia-tmb-parity.R` Route A (`drm_parity_fit_route_a`, n=18, seed 111)
- `#434` `expected.meta.toml` (n_tip=16, n_each=8) — pattern only
- scratch `2026-08-16-{next-arc-hopper-pick,arc1-recon-s1,arc1-hopper-twin-map}.md`
