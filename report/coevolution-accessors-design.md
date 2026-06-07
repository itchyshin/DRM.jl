# Design: coevolution accessors (Σ_a cross-trait correlations + CIs) — #188

**Status:** design / implementation map — no engine changes. Implementation +
verification happen in a local Julia session (the cloud env has no runtime).
Part of the coevolution epic **#186** (v0.1.0, decision A); depends on the front
end **#187** landing the fitted `Σ_a`. Sibling of the front-end design **#190**.

## Goal

Once #187 makes the q=4 model fittable, turn the raw fitted 4×4 `Σ_a` into the
**named, CI'd coevolution summaries** that are the scientific payload (Nakagawa
et al. 2025, Eqs. 26–29) — keeping the **group-level** `ρ_a` rigorously distinct
from the **residual** `rho12`/`corpairs` (per `CLAUDE.md`: group-level
correlations are *named covariance summaries*, never residual `rho12`).

## What already exists (entry points to plug into)

| Piece | Symbol / file | Relevance |
|---|---|---|
| Residual correlation | `corpairs(fit)` — `src/gaussian_core.jl:400` | per-obs `ρ12 = tanh(Xρβ̂)` from `fit.scales[:rho12]`. **Different quantity** — `coevolution` must not be confused with it. |
| RE covariance | `vc(fit) -> Dict{Symbol,Matrix}` — `src/gaussian_ranef.jl:239` | "RE covariance matrix per grouping factor" — the **correct semantic home** for the 4×4 `Σ_a`. Today it only reads `:recov` blocks (the `(1+x|g)` 2×2). |
| BLUPs | `ranef(fit)` — `src/gaussian_ranef.jl:228` | returns `fit.ranef` **assuming a `Dict`** — see Storage contract below. |
| Wald CIs | `confint(fit; level, method=:wald)` — `src/inference.jl:77` | uses `vcov(fit)` blocks. |
| Profile CIs | `profile_result(fit; …)` — `src/inference.jl:100` | bracket-then-bisect on `fit.nll` (the marginal closure attached via `_withnll`). |
| Bootstrap CIs | `bootstrap_result(fit::DrmFit{<:Gaussian}; data, B, level, …)` — `src/inference.jl:491` | parametric: simulate → refit → percentile. |
| Derived-scalar CI recipe | `report/GLLVM-porting-playbook.md` rows 43–44 | the constrained-refit penalty `NLL_pen = NLL + 0.5·w·(g(θ)−c)²` for a derived scalar `g(θ)`, + Fisher-z transformed Wald for bounded `ρ`. **This is the machinery #188 ports.** |

## The `Σ_a` layout — the math core (get this exactly right)

The engine's augmented state is `u = [a_l1, a_l2, a_s1, a_s2]` per node; the
4×4 `Λ̂ = Σ_a` is indexed in **that** order (confirm against the simulator
`src/fit_ml_q4.jl:77–81`: `U[1]→μ1`, `U[2]→μ2`, `U[3]→logσ1`, `U[4]→logσ2`).

```
index:   1 = l1 (μ1 RE)   2 = l2 (μ2 RE)   3 = s1 (logσ1 RE)   4 = s2 (logσ2 RE)
```

Four phylogenetic SDs and six correlations (the full symmetric 4×4):

| Quantity | Formula | Meaning (Nakagawa 2025) |
|---|---|---|
| `σ_a(l1..s2)` | `√Σ[k,k]` | phylogenetic SDs (the σ_a(s·) are SDs of the effect on **log σ** — lability) |
| `ρ_a(l1l2)` | `Σ12/√(Σ11Σ22)` | mean–mean — classic correlated trait evolution |
| `ρ_a(s1s2)` | `Σ34/√(Σ33Σ44)` | variance–variance — **co-divergence of lability** (Eq. 28) |
| `ρ_a(l1s2)` | `Σ14/√(Σ11Σ44)` | across-trait mean–variance — selection-relaxation (Eq. 29) |
| `ρ_a(l2s1)` | `Σ23/√(Σ22Σ33)` | across-trait mean–variance (Eq. 29) |
| `ρ_a(l1s1)` | `Σ13/√(Σ11Σ33)` | within-trait mean–variance (completeness) |
| `ρ_a(l2s2)` | `Σ24/√(Σ22Σ44)` | within-trait mean–variance (completeness) |

**Scale note to document loudly:** the `s`-effects live on the **log-σ** scale,
so `ρ_a(s1s2)` is the coevolution of log-dispersion, not of the raw variances —
this is exactly the "co-divergence of lability" quantity, and must be labelled as
such so it isn't read as a raw variance correlation.

## The gap

The engine returns `Λ̂` in the log-Cholesky 10-vector (`lc`, via `Λ_to_lc` /
`lc_to_Λ`, `src/fit_q4_sparse_tmb.jl`). **Nothing turns it into named SDs +
correlations**, and there is no CI for any `ρ_a`. `vc`/`corpairs` cover the 2×2
`(1+x|g)` and residual cases only.

## Storage contract (the one #187 ↔ #188 coordination point)

#190 proposed stashing `(; Sigma_a, blups, Q_cond, phy)` in the free-form
`DrmFit.ranef` field. But `ranef(fit)` (`gaussian_ranef.jl:228`) returns
`fit.ranef` **assuming it is a `Dict` of BLUPs** — a bare NamedTuple there would
break that accessor. Resolve it explicitly, one of:

- **(rec.) NamedTuple in `ranef` + teach both accessors:** `#187` stores
  `fit.ranef = (; blups::Dict, Sigma_a::Matrix{Float64}, Q_cond, phy)`; update
  `ranef(fit)` to return `.blups` when `fit.ranef` is a NamedTuple (Dict path
  unchanged), and `vc(fit)` to surface `.Sigma_a` keyed by the grouping factor.
  Keeps `DrmFit`'s shape stable, gives `vc`/`ranef`/`coevolution` clean reads.
- *(alt.)* add a dedicated `structcov` field to `DrmFit` — more explicit, wider
  struct change touching every constructor/`_with*` helper.

**This contract must be agreed before #187 lands** (it fixes what #188 reads).
Recommend pinning it in #187's PR; #188 then consumes `vc(fit)[:<group>] = Σ_a`.

## Proposed API surface

- **`vc(fit)`** — extended to return the raw **4×4 `Σ_a`** keyed by the grouping
  factor (its existing "RE covariance per grouping factor" contract; the q=4
  block is just 4×4 instead of 2×2). Raw covariance, no interpretation.
- **`coevolution(fit; level=0.95, method=:profile)`** — the **primary readout**:
  the labelled 4 `σ_a` + 6 `ρ_a` (table / NamedTuple), each with a CI, plus
  metadata naming the structure source (`:phylo` now; `:spatial`/`:relmat` after
  #189). Name chosen over `phylo_corr` because #189 generalises beyond trees.
  Docstring states the residual-vs-group-level distinction explicitly and
  cross-links `corpairs`.

## CI ladder (point → Wald → profile → bootstrap)

Each `ρ_a` / `σ_a` is a **derived scalar** `g(Λ̂)`. Implement in increasing
robustness/cost:

1. **Point** — direct from `Σ_a`. No inference; always available.
2. **Wald (Fisher-z), cheap default** — `z = atanh ρ_a`, `se_z` by delta method
   from the **`lc`-block of `vcov(fit)`**, back-transform. ⚠️ **Dependency:**
   #190's first slice computes vcov for the **β-block only**; this needs the FD
   marginal Hessian extended to the **full 17-dim θ** (β + 10 `lc`). Small,
   local — flag it as #188's prerequisite (or fold into #187).
3. **Profile (preferred), via the derived-scalar penalty** — port
   `confint_derived.jl`'s `NLL_pen = NLL + 0.5·w·(g(θ)−c)²` trick on `fit.nll`,
   with `g = ρ_a(·)` of `Λ̂`; bracket-then-bisect like `profile_result`. Robust
   near the variance boundary where Wald is poor. This is the method the #188
   issue references.
4. **Bootstrap (gold check)** — parametric: needs a `simulate_drm(fit; rng)` for
   the **structured** model (draw `U ~ MN(0, Σ_a, Σ_phy)` then `y`), refit,
   percentile. The simulator is new work (the `fit_ml_q4.jl` simulator is the
   template); larger lift — schedule after the profile path.

**Recommendation:** ship **point + Fisher-z Wald** first (cheap, needs only the
full-θ vcov), then **profile** as the documented-accurate default; bootstrap last.

## Dependencies & sequencing

- **#187** — must land the fitted `Σ_a` under the agreed storage contract, and
  attach `fit.nll` (`_withnll`) so profile CIs work. Hard dependency.
- **Full-θ vcov** — needed for Wald CIs (see ladder step 2); tiny, local.
- **Structured `simulate_drm`** — needed only for bootstrap CIs (ladder step 4).
- **#189** — reuses `coevolution(fit)` verbatim; only the `source` metadata and
  the precision origin differ. No accessor change.

## Test plan (local Julia)

1. **Recovery vs CI:** seeded sim from a known `Σ_a`; `coevolution(fit)` SDs +
   6 ρ_a cover the truth within CI.
2. **Distinctness:** assert `coevolution(fit)` (group-level) ≠ `corpairs(fit)`
   (residual) on a model with both signals; the residual path is untouched.
3. **CI agreement:** Wald ≈ profile in the interior; profile honest near the
   boundary (Wald over-covers there).
4. **Layout guard:** a fixture with only `ρ_a(s1s2)` non-zero lights up exactly
   that cell (catches an index transposition in the 4×4 map).
5. **R-parity (later):** vs drmTMB's group-level correlation summary (generated
   outputs only).

## Implementation checklist

- [ ] Agree + pin the #187↔#188 **storage contract** (NamedTuple in `ranef`).
- [ ] Extend `vc(fit)` to surface the 4×4 `Σ_a`; update `ranef(fit)` for the NamedTuple case.
- [ ] `coevolution(fit; level, method)` — labelled 4 σ_a + 6 ρ_a + source metadata; docstring distinguishing residual `rho12`.
- [ ] Full-θ FD vcov (prereq for Wald) → Fisher-z Wald CIs.
- [ ] Port `confint_derived.jl` penalty → profile CIs for each `ρ_a`.
- [ ] Structured `simulate_drm` → bootstrap CIs (after profile).
- [ ] Tests 1–4; worked readout in the coevolution article (coordinate with #187's example).
