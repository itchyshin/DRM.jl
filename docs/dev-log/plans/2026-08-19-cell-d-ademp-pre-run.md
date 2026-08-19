# 2026-08-19 — Cell D ADEMP pre-run (scope + stop)

**Lane:** `cell-d-ademp-scope` (Cursor / Shannon).
**This file is item 2 of the 2026-08-19 honesty sequence.** Item 1 (AGHQ chip still
`missing`; honesty in capability-status + after-task #449/#451) is DONE. Items 3–5
wait. **Item 2 is scope + stop, not the campaign.**

Cite: Morris, White & Crowther (2019) ADEMP; Williams et al. (2024) reporting items.
Twin = **drmTMB**. Do not cite −7.3 / −5.0 / −0.9 as DRM.jl. No GLLVM Λ.

---

## What this item is / is not

| This slice | Not this slice |
|---|---|
| Write what a Cell D ADEMP *would* be | Start a Totoro ADEMP campaign |
| Time-guesstimate (D-139) before any run | Flip capability-status AGHQ or Cox–Reid rows |
| A local harness-exists smoke ≤30 min | Headline Cell D as recovery |
| STOP for Shinichi before Totoro | Silent continuation of #449 / #451 |
| Docs-only (this plan + ledger) | `src/` rewrite, q4, #49, #420, #406 |

No equivalent plan existed (`docs/dev-log/plans/` had no `*cell-d*` / `*ademp*`
file for this cell). The 2026-08-18 AGHQ ultra-plan explicitly **deferred** Cell D
ADEMP; it is not a substitute for this note.

---

## What #451 already said (“Cell D is not recovery”)

PR [#451](https://github.com/itchyshin/DRM.jl/pull/451) after-task
(`docs/dev-log/after-task/2026-08-18-cox-reid-poisson-phylo-laplace.md`), Rose
honesty ledger, verbatim:

> **Cell D is not a recovery result.** Probe ntip=16 / 12 seeds: ML **+8.18%**,
> CR **+17.41%**. Underpowered for a Laplace-bias *sign* claim.

Same after-task, fence:

> **No ADEMP this G0.** Larger-tree recovery is a follow-on. Do not headline
> bias-sign from Cell D. Do not write a recovery sentence.

Handover (`docs/dev-log/handover/2026-08-18-cursor-handover.md`):

> **Cell D is not recovery.** Do not headline it.

Public `Poisson()` docstring already carries the same warning (`src/poisson.jl`).
This plan does not reopen that sentence as a result.

Evidence file for the cheap cell:
`docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md` (Cell D: nrep=12,
nfail=0, \(\hat\sigma_{\mathrm{ML}}=0.7572\) / **+8.18%**,
\(\hat\sigma_{\mathrm{CR}}=0.8219\) / **+17.41%**, true \(\sigma=0.7\)).

---

## Existing scripts (harness exists; none of these *are* Cell D ADEMP)

| Path | What it is | Use for a later G0? |
|---|---|---|
| `bench/cox_reid_probe.jl` `cell_d` | Cheap Laplace VC characterization (12 seeds, ntip=16). **`include` runs `main()`** — Cells A+B+C+D, historically **~66 s** Mac | Spine + DGP recipe only. Do not `include` the file as the campaign runner |
| `test/test_cox_reid_poisson_phylo.jl` | Direction / mechanism (σ̂_CR > σ̂_ML; `reml_loglik ≠ ml_loglik`). Not in `runtests.jl` | Keep as unit fence, not ADEMP |
| `tools/recovery_binomial_phylo.jl` | **Binomial** phylo, unit-height tree, nrep=30, G∈{40,80,160} | Other family. Do not paste as Poisson Cell D |
| `tools/recovery_biv_meta.jl` | A12 bivariate meta | Other cell |
| `tools/xfam-ademp-sweep.jl` | Cross-family sweep | Other cell |
| `bench/va_vs_laplace_bias.jl` | Gamma `(1\|g)` VA vs LA smoke | Other family / estimator |

There is **no** `sim/` Cell D runner and **no** Totoro/DRAC sbatch for this cell.

---

## What Cell D *would* be (ADEMP)

A later, **named** G0 — not this slice.

### A — Aims

**Primary:** on *this* engine, measure bias (and MCSE) of the phylogenetic
variance-component \(\sigma\) for Poisson counts under 1-point Laplace, and
whether opt-in Cox–Reid moves that bias in a *certified* direction on a tree
large enough that ntip=16 / 12 seeds is not the design.

**Secondary:** convergence / Heywood rate; wall time per fit (feeds the next
D-139 estimate). Coverage is optional and expensive (n_sim ≥ 200 for MCSE
≲ 1.5% at 95%); do not add it silently.

Not an aim: flip a capability chip. Not an aim: import drmTMB
`cumulative_logit` −7.3 / −5.0 / −0.9.

### D — Data-generating mechanism

Same spine as `cell_d` / Cell C, **after** a scale audit (see failure modes):

- Family: **Poisson**, log link.
- Formula: `y ~ x + phylo(1 | species)` (`bf(@formula(...))`, public `drm`).
- Tree: `random_balanced_tree(ntip; branch_length = ·)` then the engine's
  `_poisson_phylo_setup` → \(Q\). Simulate \(u = \sigma\, L^{-1} z\) on that
  **same** \(Q\) (the cheap probe already does this).
- Linear predictor: \(\eta = 0.3 + 0.25\, x + u_{\mathrm{leaf}}\) (probe constants).
- True \(\sigma = 0.7\).
- **Cheap cell (already run, not ADEMP):** ntip=16, per=4 → **N = 64**, 12 seeds.
- **Campaign cell (proposed, not run):** ntip \(\in \{32, 64\}\) (optional 128),
  per=8 → N \(\in \{256, 512\}\) (1024). n_sim from MCSE on bias, not folklore
  1000: start at **n_sim = 50** for a Totoro pilot, **200** if the owner wants
  a bias headline with a stated MCSE. Coverage-grade 500–1000 is a third
  conversation.

**Tree-scale trap** (coordination board + handover): `ape::vcv(corr=TRUE)` is
unit tip variance; raw Newick tip variance is height \(h\). A clean ~30% phylo
VC “bias” is often the DGP. `tools/recovery_binomial_phylo.jl` already uses a
unit-height tree for that reason. The cheap Cell D DGP shares \(Q\) with the
fitter, which *should* match scales — still **partition scale vs estimator**
before any Totoro grid (one unit-height 1-seed vs `branch_length = 0.25`).

### E — Estimands

| Estimand | Truth | Estimator output |
|---|---|---|
| phylo SD \(\sigma\) | 0.7 | `exp(coef(fit)[end])` (probe) or `re_sd` if the later runner standardises on the public accessor — pick **one** and lock it |
| (optional) \(\beta_0, \beta_1\) | 0.3, 0.25 | `coef(fit, :mu)` |

Failed fits stay in the denominator (Williams 10b). Do not drop them and then
quote bias.

### M — Methods (estimators)

| Estimator | Public call | In-scope for Cell D? |
|---|---|---|
| **ML Laplace** | `drm(..., Poisson(); tree=..., method = :ML)` (default) | **Yes** — this *is* `_fit_poisson_general_laplace` |
| **REML Cox–Reid** | `drm(..., Poisson(); tree=..., method = :REML)` (#450 / #451) | **Yes** — opt-in; ML stays default |
| **AGHQ** | `marginal = :AGHQ` | **No.** `#448` / `#449` path is Poisson `(1 \| g)` only. Public AGHQ **rejects phylo** (measured 2026-08-19; see PRE-RUN). `:REML` × `:AGHQ` also errors. A `(1\|g)` AGHQ ADEMP would be a **different cell**, not Cell D |

Do not run the probe's private `_glsp_reml_refit_clean` as the campaign
estimator. The campaign uses the **public** `method = :REML` that #451 wired.

### P — Performance measures

Required: bias, relative bias %, RMSE, MCSE of the mean, convergence rate,
wall time. Optional later: 95% coverage (needs n_sim ≫ 50).

Every aggregate ships with MCSE (`sd / √n_rep` on the mean). Target: the
smallest difference you want to *call* (e.g. “CR reduces |bias| vs ML”) must
exceed \(3\times\) MCSE. The cheap Cell D gap (CR more positive than ML by
~9 percentage points on \(\sigma\)) is **not** certified at ntip=16 / n=12.

---

## Time guesstimate (D-139) — Totoro vs local

**Stated before any run this slice.**

| Run | Estimate | Basis | Decision |
|---|---|---|---|
| Harness-exists, 1 seed, public ML + REML, ntip=16 | **20–45 s** warm; **1–3 min** first compile | Cell C/D were Mac-cheap; full A–D probe was **~66 s** (`docs/dev-log/after-task/2026-08-18-cox-reid-scoping-probe.md`) | **Ran** (see PRE-RUN). Measured **9.40 s** total (ML 7.24 s first-fit JIT, CR 0.20 s warm) |
| Replay cheap Cell D (12 seeds, probe `cell_d` only) | **~15–40 s** local if `cell_d` is called without `main()` | 12 × warm pair ~0.5–2 s | Allowed as smoke; **not run** — 1-seed already proved the public path |
| Full `include("bench/cox_reid_probe.jl")` | **~1–2 min** | `main()` runs Cell A (60 seeds × 3 G, GHQ-32) + B+C+D | Do not use as ADEMP. Reprints Cell A numbers |
| **Campaign ADEMP** (ntip ∈ {32,64} × n_sim=200 × 2 estimators) | **~1.5–4 h Totoro**; **same order local, ≫ 30 min** | AGENT-INFERRED from 1-seed warm CR 0.20 s and sparse Laplace growing with tree (`q ≈ 2·ntip−1`). ntip=64 pair ~few seconds × 400 fits | **>30 min → plan + STOP.** Do not start |
| Coverage-grade n_sim=500–1000 | **several hours–overnight Totoro** | Williams coverage MCSE table | New G0 + owner approval |

If a later lane cannot re-estimate from a 3-seed ntip=32 warm pair, **that is
the finding** (D-139): run that pair only, then re-report. A run that overruns
its estimate **stops**.

---

## PRE-RUN TEST

**Purpose:** the harness *exists* and the public estimators *dispatch*. Not
recovery. Not a chip.

### Smallest command

Do **not** `include("bench/cox_reid_probe.jl")` (that fires `main()`).

Existence (instant):

```sh
rg -n "^function cell_d" bench/cox_reid_probe.jl
```

Public-API 1-seed (what this lane ran):

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. --startup-file=no -e '
    using DRM, Random, LinearAlgebra, Distributions
    # one Cell D-sized draw; drm(...); drm(...; method=:REML)
    # plus a phylo × marginal=:AGHQ call that must throw
  '
```

(Full snippet is in the after-task for this slice; do not promote it to
`bench/` in this G0.)

### Success criterion

1. `pathof(DRM)` is this checkout.
2. `cell_d` is defined in `bench/cox_reid_probe.jl`.
3. One ML and one `:REML` fit **converge**; `estimation_method` is `:ML` / `:REML`.
4. `marginal = :AGHQ` on the **same phylo formula throws**
   (`not available … phylogenetic/structured`).
5. **No recovery sentence** is written from the one-seed \(\hat\sigma\).

### Failure modes to partition (before any Totoro grid)

1. **`include` of the probe file** — you silently re-ran Cell A GHQ-32.
2. **Tree-scale DGP** — unit-height vs `branch_length = 0.25` vs
   `ape::vcv(corr=TRUE)`. Suspect the DGP before the engine (~30% fake VC bias).
3. **JIT vs warm** — first ML 7.24 s vs warm CR 0.20 s. Time the campaign from
   a *warm* pair or the Totoro estimate is decorative.
4. **Private refit vs public `:REML`** — `cell_d` still calls
   `_glsp_reml_refit_clean`. Campaign must use `method = :REML`.
5. **AGHQ smuggled into Cell D** — it rejects phylo. Soft-scope bugs in `-e`
   scripts can print “no-throw” after a real `catch` (happened this slice;
   re-checked with `Ref`).
6. **Underpowered cheap cell** — ntip=16 / 12 seeds cannot sign Laplace bias.
7. **Twin leak** — quoting drmTMB −7.3/−5.0/−0.9 or GLLVM Λ as DRM.jl.
8. **Chip leak** — treating a green smoke as “DRM.jl has non-Gaussian REML /
   AGHQ”.

---

## PRE-RUN LOG (2026-08-19, this machine)

Estimate before start: 20–45 s warm / 1–3 min compile; stop if >5 min.
Full ADEMP: hours → not started.

```
pathof(DRM) = /Users/z3437171/Dropbox/Github Local/DRM.jl/src/DRM.jl
PRE-RUN: harness-exists smoke. 1 seed. NOT recovery. NOT ADEMP.
  N=64 ntip=16 per=4 true_σ=0.70
  ML  conv=true  method=ML    σ̂=0.53442  wall=7.24s
  CR  conv=true  method=REML  σ̂=0.59279  wall=0.20s
  AGHQ×phylo: THREW=true
    ArgumentError: marginal = :AGHQ … not available for Poisson() with a
    phylogenetic/structured random effect. … `(1 | g)` only.
  TOTAL_WALL=9.40s
```

One-seed \(\hat\sigma\) is **logged, not headlined**. Do not average it with
the 12-seed +8.18% / +17.41% probe.

---

## Recommendation

- **Do not flip the chip.** AGHQ stays `missing` (`docs/design/capability-status.md`).
  Cox–Reid stays “wired, not ADEMP-certified” — no TSV / “has non-Gaussian REML”.
- **ADEMP is a new G0**, not a silent continuation of #449 / #451. Those PRs
  earned plumbing + honesty. They did not earn a recovery headline.
- **AGHQ is out of Cell D.** If Shinichi wants AGHQ recovery, that is a
  Poisson `(1 | g)` cell (and still not a chip until ADEMP).
- **STOP for human before Totoro.** D-139: campaign estimate is >30 min.
  Owner approves the grid (ntip, n_sim, whether coverage is in) before anyone
  `ssh`s.

---

## Item 2 of this sequence is **scope + stop**

This file + the 1-seed log are the deliverable. No Totoro job, no new sim
script, no capability-status edit, no #420 / #406 / q4 / #49 / `src/` punch.
Items 3–5 wait.
