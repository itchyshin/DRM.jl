# ML phylo rows — remeasure after #577 (prior_precision structural zeros)

Date: 2026-09-02 · lane: Curie (simulation & recovery / receipts) · measurement
only, no promotion claim.

## Head measured

`origin/main` at `77513aa0` (merge of PR #597, "fix(sparse): prior_precision
keeps structural zeros — closes #577"). Worktree:
`wt-563-remeasure`, no local edits (`git status` clean at time of measurement).

## What #577 changed

`src/sparse_aug_plsm.jl` / `src/sparse_em_fit.jl`: the ML path's
`prior_precision` sparsity pattern now keeps structural zeros instead of
dropping them, so `nnz` on the q4 fixture went 2360 → 9440 (×4). This changes
the sparse pattern the ML exact gradient is built against at diagonal Λ. Two
capability rows whose parity evidence rests on the ML phylo path are
re-measured here: `gaussian_phylo_mean` (ML, univariate, `sigma ~ 1`,
`phylo(1|species)` on `mu`) and `phylo_count_large_p` (ML, Poisson,
`phylo(1|species)` on `mu`, p up to 3000).

## What this measures

Same-target point AND SE comparisons of DRM.jl's fit against the **committed
drmTMB reference numbers**, on this head, plus a diff against the DRM.jl
numbers recorded in the repo from **before** #577 where such a record exists.
No `src/`, TSV, or fixture file was edited. No promotion claim is made; this
report is handed to the drmTMB lane for its ledger.

---

## Row 1 — `gaussian_phylo_mean`

Fixture: `test/parity/phylo-mean/gaussian-phylo-mean/` (`expected.toml` +
`expected.meta.toml`, drmTMB 0.7.0, seed 404, generated 2026-08-24 —
unchanged by this measurement). Test: `test/test_parity_gaussian_phylo_mean.jl`
(wired directly into `test/runtests.jl`, no gate flag). Tolerances from the
fixture: `atol_loglik=1e-6`, `atol_coef=1e-5`, `rtol_coef=1e-5`,
`atol_re_sd=2.8627056822019127e-03`.

**No pre-#577 DRM.jl point/SE snapshot is committed anywhere in the repo for
this row** (only the drmTMB reference in `expected.toml`/`expected.meta.toml`,
which predates #577 by commits `f5ab5842`/`6afea0c4`/`786e7854` and is
untouched). So the "moved vs pre-#577" column is not measurable for this row;
only the same-target comparison against the drmTMB reference is reported.

Direct `drm(...)` probe
(`/private/tmp/.../scratchpad/probe_gaussian_phylo_mean.jl`,
log: `remeasure-gaussian_phylo_mean.log`) and the official fixture test
(`remeasure-gaussian_phylo_mean-testfile.log`) were both run.

| quantity | drmTMB ref | DRM.jl now (post-#577) | \|Δ\| | tolerance | pass/fail |
|---|---|---|---|---|---|
| loglik | -32.73529897226713 | -32.7352989706 | 1.696e-09 | atol 1e-6 | PASS |
| mu_(Intercept) | 0.6914990511952894 | 0.6914988118 | 2.394e-07 | atol 1e-5 / rtol 1e-5 | PASS |
| mu_x | 1.4581870345132255 | 1.4581877863 | 7.518e-07 | atol 1e-5 / rtol 1e-5 | PASS |
| sigma_(Intercept) | -1.1761387347674666 | -1.1761389005 | 1.657e-07 | atol 1e-5 / rtol 1e-5 | PASS |
| sd_phylo (corr. scale) | 0.916577446510401 | 0.9165774315 | 1.501e-08 | atol 2.863e-03 | PASS |
| tree height (h) | 2.4738053235707165 | 2.4738053235599997 | 1.07e-11 | atol/rtol 1e-6 | PASS |

Multi-height round trip (h = 0.5, 1.0, 3.0): all three refits converged and
matched drmTMB's height-invariant `sd_phylo_corr` within `atol_re_sd`.

**Converged / gradient status:** `is_converged(fit) == true` at all four
heights (primary tree + 3 round-trip trees). `fieldnames(fit)` exposes no
`g_residual`/`gradnorm` field on this fit type — no numeric gradient-norm
diagnostic is available through the public `drm()` return object for this
route, so none is reported beyond `converged`.

**Supplementary, not a formal fixture comparison:** DRM.jl's own fitted SE
vector is `[0.6087485, 0.2826973, 0.0986131, 0.3123251]` (order: `mu_Intercept,
mu_x, sigma_Intercept, log_sd_phylo`). The 4th entry matches drmTMB's own
reported `log_sd_phylo_se = 0.31232556431546754` (`expected.meta.toml
[identifiability]`) to `|Δ| = 4.2e-7` — the same quantity, informally
confirmed close, but the fixture/test does not declare this a compared SE and
no committed drmTMB SE exists for the three fixed-effect coefficients, so no
formal SE-axis pass/fail is reported for the other three coefficients.

**Parity-test summary line** (`test/test_parity_gaussian_phylo_mean.jl`, full
suite incl. multi-height round trip):

```
Test Summary:                           | Pass  Total   Time
gaussian_phylo_mean same-target fixture |   53     53  14.2s
```

**Verdict — `gaussian_phylo_mean`:** point axis: within tol (max \|Δ\| =
7.518e-07 on `mu_x`, tolerance 1e-5). SE axis: no formal drmTMB-referenced
comparison exists in this row's fixture to move or not move; the one
informally-checkable quantity (log-scale phylo SD SE) agrees with drmTMB to
4.2e-7. Not measurable: "moved vs pre-#577" — no pre-#577 DRM.jl snapshot is
committed for this row.

---

## Row 2 — `phylo_count_large_p`

Two evidence layers exist for this row:

1. **Julia-side standing gate** (`test/test_phylo_count_largep_gate.jl`,
   wired into `runtests.jl` unconditionally) — DGP recovery only, no drmTMB
   comparator (by design; see the file's own header).
2. **R-side same-target parity harness** (`tools/parity_classc_largep.R`,
   requires installed drmTMB 0.7.0 + `DRM_JL_PATH` bridge to this worktree) —
   the actual drmTMB comparator, at p = 300, 1000, 3000, Poisson,
   `phylo(1|species)` mean intercept, seed 20260824, m=4. This is the
   harness that originally produced the rows committed in
   `docs/dev-log/evidence/parity-classc.tsv` (pre-#577, via commits
   `b7e34dee`/`33c0153f`/`8dbc310c`/`e84f3ab4`/`09402d3e`).

### 2a. Julia-side standing gate

```
Test Summary:                                  | Pass  Total   Time
phylo_count_large_p — Julia-side standing gate |   31    31  12.9s
```
All DGP-recovery assertions pass (converged flags, `re_sd` height-invariance,
FD-vcov step schedule). No drmTMB numbers involved — not a parity check.

### 2b. R-bridge same-target parity vs drmTMB (this head, `DRM_JL_PATH` = this
worktree)

Run via a scratch copy of `tools/parity_classc_largep.R` with its output
redirected to a scratch TSV (`probe-parity-classc-scratch.tsv`, seeded from a
read-only copy of the committed `parity-classc.tsv`) — **the committed TSV
itself was never opened for writing.** Log:
`remeasure-phylo_count_large_p-Rbridge.log`.

One transient note: the p=300 Julia fit hit a `LogExpFunctionsInverseFunctionsExt`
precompile-cache error on first load (`UndefVarError: loglogistic not
defined`) — this is the shared-depot precompile race already documented in
`docs/dev-log/evidence/2026-08-24-phylo-large-p-probe.md` (many concurrent
Julia lanes in this environment hitting the same `~/.julia` depot). JuliaCall
recovered on the same call (the bridge functions loaded immediately after)
and the fit completed and returned real, finite, `PARITY_PASS` numbers; not a
DRM.jl defect.

| p | quantity | drmTMB ref (this run) | DRM.jl (this run, post-#577) | \|Δ\| this run | pre-#577 committed \|Δ\| | moved by | tolerance | pass/fail |
|---|---|---|---|---|---|---|---|---|
| 300 | max\|Δcoef\| | (tmb=0.3843,0.3815) | (julia=0.3843,0.3815) | 7.216e-07 | 3.836e-07 | +3.38e-07 | 1e-4 | PASS |
| 300 | \|Δloglik\| | -1800.6692 | -1800.6692 | 3.657e-09 | 3.673e-09 | -1.6e-11 | 1e-4 | PASS |
| 300 | max_rel_se_diff | — | — | 9.735e-07 | 1.947e-06 | -9.7e-07 (improved) | 1e-4 | PASS |
| 300 | rcond(vcov) | 8.115234e-03 | 8.115250e-03 | ~1.6e-08 | ~0 (both 8.115e-03 rounded) | negligible | — | — |
| 1000 | max\|Δcoef\| | (tmb=-0.1249,0.3604) | (julia=-0.1249,0.3604) | 1.003e-06 | 5.747e-07 | +4.28e-07 | 1e-4 | PASS |
| 1000 | \|Δloglik\| | -5162.6078 | -5162.6078 | 5.448e-10 | 5.557e-10 | -1.1e-11 | 1e-4 | PASS |
| 1000 | max_rel_se_diff | — | — | 1.199e-06 | 3.994e-06 | -2.8e-06 (improved) | 1e-4 | PASS |
| 1000 | rcond(vcov) | 2.522004e-03 | 2.522010e-03 | ~6e-09 | ~0 (both 2.522e-03 rounded) | negligible | — | — |
| 3000 | max\|Δcoef\| | (tmb=0.2664,0.3614) | (julia=0.2664,0.3614) | 5.568e-08 | 1.288e-06 | -1.23e-06 (improved) | 1e-4 | PASS |
| 3000 | \|Δloglik\| | -16459.4946 | -16459.4946 | 3.347e-10 | 2.474e-10 | +8.7e-11 | 1e-4 | PASS |
| 3000 | max_rel_se_diff | — | — | 3.551e-06 | 4.534e-06 | -9.8e-07 (improved) | 1e-4 | PASS |
| 3000 | rcond(vcov) | 9.473915e-04 | 9.473982e-04 | ~7e-09 | ~0 (both 9.474e-04 rounded) | negligible | — | — |

(pre-#577 reference row: `docs/dev-log/evidence/parity-classc.tsv`,
`cell_id` = `poisson_phylo_p300`/`poisson_phylo_p1000`/`poisson_phylo_p3000`,
committed by `b7e34dee`/`33c0153f`/`e84f3ab4`/`09402d3e`, all predating the
`77513aa0` merge by dozens of commits.)

**Converged / gradient status:** all six fits (3×tmb, 3×julia) returned
`real=TRUE` (finite, non-NA coefficients, finite logLik) per the harness's
own `check_real()` gate; all three cells reported `STATUS: PARITY_PASS`.

**Wall clock (this run, not the claim being measured):** p=300 tmb 0.40s /
julia 44.77s (JuliaCall cold-start dominated, consistent with the prior
probe's note); p=1000 tmb 0.92s / julia 0.62s; p=3000 tmb 3.35s / julia 5.15s.

**Verdict — `phylo_count_large_p`:** point axis: within tol at all three p
(max \|Δcoef\| = 1.003e-06 at p=1000, tolerance 1e-4 — 2 orders of magnitude
of margin). SE axis: within tol at all three p (max\|rel SE diff\| =
3.551e-06 at p=3000, tolerance 1e-4). Moved vs pre-#577: yes, by a small
amount in both directions — coef-diff increased at p=300/1000 (+3.4e-07,
+4.3e-07) and decreased at p=3000 (-1.23e-06); SE-diff decreased (improved)
at all three p. All movements are 2–5 orders of magnitude below the 1e-4
tolerance and are consistent with ordinary run-to-run floating-point/solver-
path noise, not a directional regression.

---

## Files

- Probe scripts (not committed): `probe_gaussian_phylo_mean.jl`,
  `probe_phylo_count_largep.R` (scratch copy of
  `tools/parity_classc_largep.R` with `out_path` and `.tools_dir` redirected
  to scratch; the tool itself in the worktree is unmodified).
- Logs: `remeasure-gaussian_phylo_mean.log`,
  `remeasure-gaussian_phylo_mean-testfile.log`,
  `remeasure-phylo_count_large_p-gate.log`,
  `remeasure-phylo_count_large_p-Rbridge.log`.
- Scratch output TSV (not the committed one):
  `probe-parity-classc-scratch.tsv`.

No `src/`, test, fixture, or TSV file in the worktree was modified. No
commits were made.
