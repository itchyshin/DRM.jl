# A5 — the missing comparator for `phylo_gamma_beta_binomial`

Date: 2026-08-15 · lane: DRM.jl (Claude, arc-loop) · anchor: drmTMB **0.7.0**, installed
Harness: `tools/parity_phylo_nongaussian.R` → `docs/dev-log/evidence/parity-phylo-nongaussian.tsv`

## Why this arc

The capability row's own `claim_boundary` reads *"Finite-and-sane bridge smoke
evidence only; **no native TMB parity**"*, and its `next_action` is *"Add
comparator or parity evidence before promoting beyond experimental."*

Smoke evidence shows a fit **runs**. It cannot show two engines **agree**. This
produces the missing comparator — and stops there. `claim_status` lives in
drmTMB's release process; promotion is the owner's call, not this lane's.

## Result

```
phylo_gamma      PARITY_FAIL           coef|d| = 6.825e-05   ll|d| = 1.016e-04
phylo_binomial   NO_NATIVE_COMPARATOR  (drmTMB refuses the syntax)
phylo_beta       PARITY_PASS           coef|d| = 5.019e-07   ll|d| = 3.892e-10
```

Tolerance 1e-4. **Two of the row's three families now have a native comparator
where none existed; the third turns out not to have one available at all.**

## Finding 1 — the row lists a combination native drmTMB does not implement

The row's `syntax` field is *"Gamma()/beta()/stats::binomial() with
phylo(1 | group, tree = tree)"*. Native drmTMB accepts the first two and
**refuses the third**:

```
Structured-effect syntax is planned, not implemented.
```

Gamma and beta fit natively with the identical `phylo(1 | species, tree = tree)`
term, so this is binomial-specific, not a fixture error.

That is not a parity failure — it is the **absence of a comparator**, and the
harness reports it as `NO_NATIVE_COMPARATOR` rather than `NATIVE_FAILED`. The two
must not be collapsed: one says "the engines disagree", the other says "there is
nothing to disagree with". A third of this row cannot be parity-verified against
drmTMB 0.7.0 at all, and no amount of further work on this lane changes that.

## Finding 2 — agreement is usually ~1e-8, occasionally ~1e-4, and NOT root-caused

The gamma cell fails by a hair — 1.016e-04 against a 1e-4 tolerance. Two things
were checked before reporting it:

**It is not optimiser tolerance.** Identical to the last digit at
`g_tol` 1e-8, 1e-10 and 1e-12:

```
g_tol=1e-8    max|coef d|=6.825e-05   |ll d|=1.016e-04
g_tol=1e-10   max|coef d|=6.825e-05   |ll d|=1.016e-04
g_tol=1e-12   max|coef d|=6.825e-05   |ll d|=1.016e-04
```

(drmTMB's own optimum is not razor-tight either: `max|grad| = 2.815e-06`.)

**It is dataset-specific, not family-specific.** Across four seeds:

| seed | gamma coef / ll | beta coef / ll |
|---|---|---|
| 411 | 6.825e-05 / **1.016e-04** | 2.151e-07 / **1.582e-04** |
| 412 | 9.038e-08 / 3.409e-09 | 1.693e-07 / 4.066e-09 |
| 413 | 1.161e-09 / 2.711e-10 | 2.846e-07 / 9.231e-10 |
| 414 | 1.171e-08 / 1.790e-09 | 5.514e-08 / 1.837e-09 |

Three of four seeds agree to **~1e-8 or better in both families**. Seed 411 is
the outlier for **both** — so whatever it is belongs to that dataset, not to the
Gamma likelihood.

**The tolerance was NOT loosened to make this pass.** Moving the threshold to fit
the result is precisely the failure mode this campaign has a rule against. The
measured statement is: *these two engines typically agree to ~1e-8 on this route,
and on some datasets only to ~1e-4.* That is the evidence; whether it clears the
bar for promotion is a claim decision, and the honest input to it is the range,
not a pass stamp.

**Not root-caused.** The likely candidates are a difference in the Laplace inner
solve or in how the dispersion parameter is handled between TMB's AD-based
marginal and DRM.jl's `sparse_laplace_glmm`, on a dataset where the optimum is
flat. That was not chased down; it is stated as an open question rather than
guessed at.

## Carried over from the penalty fixture (and it paid off again)

- **Tree normalised to unit height.** drmTMB uses `ape::vcv(corr = TRUE)`; DRM.jl
  uses Newick branch lengths as given. Without this the SDs differ by `sqrt(h)`.
- **Species passed as tip-label strings.** The non-Gaussian phylo route
  (`sparse_laplace_glmm.jl:161`) matches **by name**, unlike the univariate
  Gaussian sparse route, which matches **positionally**. A real asymmetry inside
  one package — the penalty fixture needed Newick-ordered rows for exactly this
  reason, and assuming one route's convention held for the other would have
  produced a silent misalignment rather than an error.
- **More than one quantity compared.** Coefficients *and* log-likelihood.

## What this arc does NOT claim

- **No promotion.** `phylo_gamma_beta_binomial` stays `experimental`. This lane
  produces evidence; drmTMB decides claims.
- **No binomial evidence**, and none is obtainable against 0.7.0.
- **No root cause** for the seed-411 ~1e-4.
- **Nothing about the other ten capability rows** — most of whose `next_action`
  is explicitly *"keep tests / do not promote"*, i.e. nothing is owed on them.
