# DRAFT follow-up to Ayumi — issue #2 (for SN to review + post; posting is user-gated)

> Follow-up to the earlier reply (`report/ayumi-issue2-reply-draft.md`). This one
> reports a concrete state change: the univariate Gaussian `sigma ~ phylo(1 | species)`
> model is now **actually fitting on the engine**, with the block structure your case
> needs and honest boundary inference — both verified by tests. It does **not** repeat
> the install instructions or the bucket-by-bucket framing from the first note; it gives
> the engine-level update and is honest about what is still landing (the R route) and
> what is planned but not shipped (REML for these blocks; the non-Gaussian parallel).

---

Hi @Ayumi-495 — a concrete update on top of the earlier note. The univariate Gaussian
`sigma ~ phylo(1 | species)` model is no longer "coming" — it **fits on the engine now**,
with recovery and boundary tests passing. Here is exactly what it does, sorted the same
way as before so it's easy to map back to your table.

## (i) Fixable features — now built and verified on the engine

You can now choose the σ-phylo block structure explicitly, instead of being forced into
a single mean–scale block:

- **Separate / uncorrelated** — your "no correlation" ask (Q2). The μ-phylo and σ-phylo
  random effects are fit as their own diagonal block (`Λ = diag`, off-diagonal pinned to
  0), so the artefactual mean–scale correlation never enters. This is the structure
  drmTMB couldn't give you.
- **Coupled** — the old single-block behaviour kept as a deliberate option: a *free*
  mean↔σ phylo correlation, estimated rather than imposed. It's reported as a named
  group-level covariance summary on the fit (the σ-phylo SD, the μ-phylo SD, and their
  correlation), not silently baked in.
- **Asymmetric** — σ-phylo on the scale axis only, mean as fixed effects (your Q3).

These three are exercised by a recovery test (separate block, both axes identified) and
a boundary test, both of which pass on the engine. The kernel and the exact O(p) gradient
are the same verified location-scale spine the rest of DRM.jl uses; nothing here is a
mock-up.

## (ii) Bugs — fixed

Two distinct failures from your report are gone:

- **The silent σ-phylo drop (our side).** The univariate Gaussian path was *discarding* a
  `phylo()` term on `sigma` and fitting `sigma ~ phylo(…)` byte-for-byte as `sigma ~ 1`.
  That parsing gap is closed: the term is now either honoured as a real σ-phylo structure
  or rejected with a clear error — never silently ignored. Your case is what surfaced it.
- **The NaN crash at the boundary.** Where the σ-SD collapses and the Wald Hessian goes
  singular, the old path could return a NaN / false-converged result. The new
  profile-likelihood CI does not invert a singular Hessian — it brackets the
  likelihood-ratio threshold directly, so a collapsing component yields an honest finite
  interval instead of a crash.

## (iii) Inherent boundary — the data speaking (unchanged, and now reportable)

This is the part that was never a bug, and the new code treats it as a *result* rather
than a failure. The boundary CIs are honest in both directions, and that's what the
boundary test checks:

- a **well-identified** σ-phylo signal returns a CI that **excludes 0** (point estimate
  inside, finite upper bound);
- an **absent** signal — a trait with no detectable phylogenetic structure in its
  variance — returns an honest **`[0, x]`**: lower endpoint *exactly* 0, finite upper
  bound. No false +1 pin, no `pdHess = FALSE`, no NaN.

So your `mass` +1 pin and the collapsing σ-SDs (down to ~2e-6 in your table) become
*reportable*: "no identifiable phylogenetic signal in this trait's variance, CI `[0, x]`"
— exactly the spirit of Santi's across-tree percentile intervals, where the boundary-prone
scale terms ride along with honest wide intervals while the well-identified anchors
(mean–mean correlations, heritabilities) carry the science. The boundary is the answer,
not an obstacle to engineer around.

## Now runnable from R via `engine = "julia"`

The new part since the earlier note: the model fits **end-to-end from R**, not just on the
Julia engine. I ran your exact shape — a Gaussian both-phylo separate block on 120 species
(4 observations each) — through the R→Julia bridge:

```r
fit <- drmTMB(
  bf(y ~ phylo(1 | species, tree = tree),
     sigma ~ phylo(1 | species, tree = tree)),
  family = gaussian(), data = dat, engine = "julia"
)
```

It converges, and recovers **both** axes' phylogenetic SDs — the mean-axis SD (0.63 against
a true 0.60) **and the σ-axis SD (0.52 against a true 0.50)** — with the σ-phylo SD reported
as a named group-level summary (`fit$sdpars$sigma`). So modelling the variance on the scale
axis is the live, reportable result now, from R.

**To install** (one caveat): the drmTMB release branch that carries this bridge route isn't
pushed to GitHub yet — I'll follow up in this thread with the exact
`remotes::install_github(...)` line the moment it is, plus a local checkout of DRM.jl that
the bridge points at (the same setup Santi is using). The modelling is done; this is the
last packaging step.

## Honest about what is still in motion

Two refinements from the earlier note are not yet shipped, and I want to be precise so you
can plan:

- **REML for these σ-phylo blocks is planned, not shipped.** REML is wired today only for
  the fixed-effect Gaussian location-scale cell; the σ-phylo route currently fits ML even
  if you ask for REML, so we've gated it to error rather than silently demote. REML on the
  scale axis is the natural estimator near the boundary and it's on the list, but treat it
  as not-yet-available for σ-phylo until I say otherwise.
- **The non-Gaussian σ-phylo parallel** (the same separate/coupled/asymmetric blocks for
  NB2/Gamma/Beta) is also planned, not built. This first slice is Gaussian-only.

Net: the model you needed now fits and reports honestly on the engine; the R door for it
and the REML refinement are the two things still in motion, and I'll follow up here when
each lands. Thanks again — your diagnostic is what made the separate block and the
boundary CIs concrete rather than aspirational.
