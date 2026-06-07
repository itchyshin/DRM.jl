# Design: the remaining engine-quality Q-gates — #15 (zero-alloc) & #16 (multi-shape scaling)

**Status:** design / implementation map. CI/test-infra to **complete the
engine-quality battery (Workflow Q)** — the FD-gradient gate (#14) is already
wired (`test/check_sparse_tmb.jl`, `grad_check_p100.jl`); these are the last two.
Cost-disciplined, opt-in CI (Linux-only, `workflow_dispatch`, per the repo's
local-checks discipline). Implementation + verification are local Julia.

## Context

The verified engine's two headline properties — **O(p) scaling** and a **tight
inner mode-finder** — are currently *demonstrated in benchmarks* but not *guarded
as gates*. `bench/run_scaling.jl` already measures the O(p) exponent (balanced
tree, k=1.08 verified, comparison-grid §3) but only for one tree shape and isn't
an assertion. There is **no allocation gate** on the inner loop. These two gates
turn "verified once" into "stays verified."

## #16 — multi-shape scaling sweep (balanced + caterpillar, p ∈ {100, 1k, 10k})

`bench/run_scaling.jl` is the template: build a tree, simulate q4 PLSM data via
the **O(p) precision sampler**, fit with `fit_q4_sparse_tmb`, fit wall ~ pᵏ,
report `k`. Generalize:

- **Two tree shapes.** Balanced exists (`random_balanced_tree`, `sparse_phy.jl`).
  Add a **caterpillar** generator (a maximally-unbalanced ladder tree) — either a
  `random_caterpillar_tree(p)` or a generated caterpillar Newick fed to
  `augmented_phy`. Shape matters: the tree topology sets the **precision sparsity
  pattern / Cholesky fill-in**, so O(p) on a balanced tree does *not* by itself
  prove O(p) on a deep unbalanced one — this gate closes that gap.
- **Grid:** shape × p ∈ {100, 1000, 10000}; fit each, record wall + iters +
  per-obs logLik.
- **Gate assertion:** empirical `k = slope(log wall vs log p) ≤ k_max` **per
  shape** (e.g. `k_max ≈ 1.25`, with headroom over the measured 1.08), and flat
  iteration count (no p-dependent blow-up). Fail loudly with the realized `k`.
- **Wiring:** a `workflow_dispatch` (or scheduled) CI job, **not** the per-PR run
  (the p=10k cell is minutes-scale); the fast default test run stays untouched.
  Keep p=10k optional via an env knob for local quick runs (`{100,1000}` default).

## #15 — zero-alloc inner mode-finder loop (Allocs.jl)

The inner Newton mode-finder (`estep_mode` / the per-family `*_mode` loops in
`sparse_aug_plsm.jl` / `sparse_laplace_glmm.jl`) runs many times per fit; steady-
state allocations there are pure overhead and a regression smell.

- **What to measure:** allocations of **one inner Newton iteration's arithmetic**
  after warm-up — the residual/gradient/Hessian-assembly and the back-substitution
  *around* the sparse factor. Use `@allocated` (or `Allocs.@profile` /
  `BenchmarkTools.@ballocated`) on a tight wrapper that excludes first-call
  compilation.
- **Honest scope (important):** the **CHOLMOD sparse factorization/solve allocates
  inside SuiteSparse** — that is *not* Julia-controllable, so the gate must
  **exclude the factor object** and target the **pure-Julia arithmetic** of the
  loop (assert `== 0` there) **or** assert a **bounded constant** for the whole
  iteration (a fixed small budget independent of p, so a p-scaling allocation
  regression trips it). Pick one and document which; the constant-budget form is
  more robust to SuiteSparse internals.
- **Gate assertion:** pure-Julia inner step `@allocated == 0` after warm-up, **or**
  full inner step `@allocated ≤ budget` with `budget` p-independent (verified flat
  across p ∈ {100, 1000}).
- **Wiring:** a fast unit-style gate (small p), safe to run on every PR — it's
  cheap, unlike #16.

## Acceptance / test plan (local Julia)

- **#16:** the sweep runs both shapes to p=10k without error; `k ≤ k_max` per
  shape; iteration count flat; per-obs logLik stable. A seeded fixture so the
  reported `k` is reproducible. Regression: artificially densifying the precision
  trips the gate (sanity that it bites).
- **#15:** the inner-loop allocation measure is `0` (pure-Julia) / `≤ budget`
  after warm-up and **flat across p**; a deliberately allocation-introducing edit
  (e.g. a temporary in the loop) trips it.

## Dependencies & sequencing

- Both are independent of the feature work (#186 etc.); pure infra. Can run anytime.
- **#15 first** (cheap, per-PR; immediate regression protection), then **#16**
  (the `workflow_dispatch` sweep). Together they complete Workflow Q alongside the
  existing FD-gradient gate (#14).
- The caterpillar generator added for #16 is also reusable in tree-shape
  robustness tests elsewhere.

## Implementation checklist

- [ ] `random_caterpillar_tree(p)` (or caterpillar-Newick helper) in `sparse_phy.jl`.
- [ ] Generalize `bench/run_scaling.jl` → shape × p grid; emit `k` per shape.
- [ ] `test/` (or a gated bench) assertion: `k ≤ k_max` per shape + flat iters; `workflow_dispatch` CI job (p=10k behind an env knob).
- [ ] `@allocated`/Allocs wrapper around one warmed inner Newton iteration; assert `0` (pure-Julia) or `≤ budget` (flat across p).
- [ ] Per-PR alloc gate in `test/`; document the SuiteSparse-exclusion scope.
- [ ] Record both gates in the engine-quality battery doc; update `report/comparison-grid.md` if the multi-shape `k` differs from the balanced 1.08.
