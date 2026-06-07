# Design: FIML for missing responses — #49

**Status:** design / implementation map. drmTMB-parity capability (the last
modeling-parity gap in the #9 matrix). Scoped to **missing *responses*** via
full-information ML (FIML); missing *predictors* (imputation / MI) are explicitly
out of scope. Implementation + verification are local Julia.

## Why this matters (and where it's clean)

drmTMB's intent (issue #49) is to **integrate over / use the partial information
in incomplete rows rather than dropping them.** For the **bivariate / q=4
coevolution** models this is not a nicety — real comparative datasets routinely
have **one trait measured but not the other**. Listwise deletion throws away every
such species; FIML keeps each observed value contributing to the shared
parameters (and, in the q=4 model, to `Σ_a` through the phylogeny).

There is **no missing-data handling today** (a `missing`/`NaN` response simply
breaks the fit). Clean slate.

## The FIML principle (multivariate normal)

For a row with responses `(y1, y2)` and bivariate residual `Σ_i(σ1,σ2,ρ)`, the
contribution is the density over the **observed sub-vector**:
- **both observed** → bivariate `−log φ₂` (today's term);
- **only y1** → univariate `−log φ₁(y1; η1, σ1)` (drop y2 and ρ);
- **only y2** → univariate `−log φ₁(y2; η2, σ2)`;
- **neither** → 0.

Unbiased under MAR (missing-at-random) — the standard FIML guarantee. Missing
*predictors* break MAR-in-y and need a model for `x` (multiple imputation) — a
separate, larger effort; **deferred**.

## Slice 1 — bivariate **residual** Gaussian FIML (clean, bounded)

The `nll` loop in `gaussian_bivariate.jl:98` already computes the per-row
bivariate term. FIML = branch per row on an observed-mask:

```text
for i in 1:n
    o1, o2 = observed(y1[i]), observed(y2[i])
    if o1 && o2   # current bivariate term
    elseif o1     # ls1[i] + 0.5*z1^2        (univariate y1)
    elseif o2     # ls2[i] + 0.5*z2^2        (univariate y2)
    end           # neither → skip
end
# constant: 0.5*log(2π) * (total #observed responses), not n*log(2π)
```

Implementation notes:
- Precompute `o1::BitVector`, `o2::BitVector` from `ismissing`/`isnan`; replace
  the `n*log(2π)` constant with `0.5*log(2π)*(count(o1)+count(o2))`.
- The `_design` path (`gaussian_core.jl:158`) must tolerate `missing`/`NaN` in
  the **response** columns (predictors still required complete in this slice);
  carry the responses as `Vector{Union{Missing,Float64}}` or sentinel-`NaN` and
  build the masks before the optimiser.
- `means`/`obs`/`scales` packaging unchanged; report **#observed per response**
  in the fit summary.

This slice is fully testable without any engine change.

## Slice 2 — q=4 coevolution FIML (the high-value one)

In the augmented-state engine, each leaf contributes a per-observation data
likelihood `jn` over `(y1, y2)` given the latent `(a_l1,a_l2,a_s1,a_s2)`. FIML =
**mask the per-leaf data term to its observed dimensions** (same three cases as
Slice 1) while the **prior / `Σ_a` / phylogeny are untouched** — so a species with
only y1 still informs `Σ_a` via its observed trait + the tree. Concretely:
`sparse_aug_plsm.jl`'s per-leaf contribution (and its η-derivatives feeding the
Newton mode + the exact gradient) gets an observed-mask; missing dims drop out of
the leaf's gradient/Hessian. The mode-finder, Takahashi inverse, and outer
gradient machinery are otherwise unchanged.

Gated by #187 (the public q=4 path) and best done **after** Slice 1 establishes
the masking convention. This is where FIML pays off scientifically.

## API contract

- Detect partial responses automatically; `drm(...; missing_response = :fiml)`
  default where FIML is implemented (Gaussian bivariate / q=4), with
  `:omit` (listwise) as the explicit opt-out and the current behavior for
  everything else.
- **Univariate** Gaussian/GLM: a missing response *is* listwise deletion (FIML
  adds nothing with no second channel) — so `:omit` there, no special path.
- Error clearly if a **predictor** is missing (point users to `:omit` or future MI).
- Surface the per-response observed counts in `summary`/the fit.

## Acceptance / test plan (local Julia)

1. **No-missing equivalence:** with complete data, FIML ≡ the current bivariate
   fit (bit-for-bit) — the `:fiml` path must not move complete-case results.
2. **Recovery under MAR:** simulate a known bivariate `Σ`, delete y2 at random
   (e.g. 30%), assert FIML recovers β/σ/ρ within tolerance and **beats listwise**
   (tighter SEs / less bias) on a seeded fixture.
3. **Gradient ≤ 1e-6:** analytic vs FD on the masked objective (both slices).
4. **q=4 (Slice 2):** a species with one trait still shifts `Σ_a` toward truth vs
   dropping it; gradient ≤ 1e-6 with the masked leaf term.
5. **Guards:** missing predictor errors with a clear message; univariate routes to `:omit`.

## Dependencies & sequencing

1. **Slice 1** (bivariate residual FIML) — independent, bounded; lands the mask
   convention + the `missing_response` kwarg.
2. **Slice 2** (q=4 FIML) — after #187 and Slice 1; the scientifically important one.
- Missing-predictor multiple imputation — separate future issue (out of scope).

## Implementation checklist

- [ ] `_design` tolerates `missing`/`NaN` in response columns; build `o1`/`o2` masks.
- [ ] Slice 1: masked per-row `nll` in `gaussian_bivariate.jl` + corrected `log(2π)` constant; `missing_response = :fiml|:omit` kwarg.
- [ ] Report per-response observed counts in the fit summary.
- [ ] Slice 2: observed-mask the per-leaf data term + its derivatives in `sparse_aug_plsm.jl` (prior/`Σ_a` untouched); gated by #187.
- [ ] Tests 1–5 (no-missing equivalence, MAR recovery vs listwise, gradient, q=4, guards).
- [ ] Docstrings + a worked missing-trait example in the coevolution/bivariate article.
