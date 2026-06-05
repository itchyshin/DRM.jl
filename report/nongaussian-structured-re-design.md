# Design: completing non-Gaussian structured random effects — #164–#167

**Status:** design / implementation map (umbrella for #164, #165, #166, #167).
No new engine *core* — these are generalizations of the existing non-Gaussian
sparse-Laplace spine. Implementation + verification are local Julia. This is the
largest remaining **modeling-capability** gap vs drmTMB (see the #9 matrix).

## The key insight

The non-Gaussian RE engine (`src/sparse_laplace_glmm.jl`, 2042 lines) is already
**two reusable abstractions** with the family/structure specifics layered on top:

1. **A precision-agnostic Laplace spine.** `_phylo_mean_mode` /
   `_phylo_mean_laplace_fg` / `_fit_phylo_mean_laplace` (const σ) and
   `_fit_phylo_mean_laplace_nuisance` (one dispersion nuisance) take a **sparse
   precision `Q` + a group-node map** and do the inner Newton mode, the Hessian,
   the `takahashi_selinv` selected inverse, and the outer optimise. They do **not**
   care that `Q` came from a tree.
2. **Per-family `Val{}` kernels.** `_laplace_value/d1/d2/d3(::Val{:fam}, aux, i, η)`
   supply the conditional log-density and its first three η-derivatives. Present
   today: `:binomial`, `:nb2_fixed`, `:gamma_fixed`, `:beta_fixed` (Poisson has a
   dedicated fast path). Everything else is generic over the kernel.

All four open issues are **generalizations of these two abstractions** — so they
share one design, not four. What's hard-coded today:

- the precision is built **only from a tree** (`_poisson_phylo_setup(tree, labels)`),
  and every family wrapper hard-rejects non-phylo markers
  (`kind === :phylo || error("currently supports only phylo(1 | group) …")`,
  e.g. `src/poisson.jl:43`, `gamma.jl:55`, `beta.jl:57`, `binomial.jl:69`);
- the dispersion is a **single scalar nuisance** (`size(Xσ,2)==1 || error(…)`,
  `nb2/gamma/beta_phylo_laplace`, e.g. `src/sparse_laplace_glmm.jl:733`);
- the **crossed** route's outer gradient is **frozen-mode + FD-polish**
  (`sparse_laplace_glmm.jl:1128`, `:1162` — "b̂ frozen … finite-difference LBFGS");
- there is **no beta-binomial kernel**.

The Gaussian path already solves the precision-source half:
`gaussian_structured.jl` builds phylo / relmat / animal (fixed `K`) and spatial
(`K(ρ)=exp(-d/ρ)`, `ρ` estimated) precisions. We reuse those builders.

## Slice A — #167: relmat / animal / spatial precision sources

**The biggest unlock, and mostly plumbing.** Generalize the precision setup and
relax the marker guard:

- **Abstract the setup:** replace `_poisson_phylo_setup(tree, labels)` with a
  `structured_precision(kind; tree, K, Ainv, coords, labels, ρ) -> (Q, group_node, logdetQ_or_rebuild)`:
  - `:phylo` — tree → `Q` (today's path);
  - `:relmat` / `:animal` — **fixed** `Q = inv(K)` / `Ainv` (supplied), group-node = `gidx`. Same fixed-precision flow as phylo (precompute Cholesky + `logdetQ`).
  - `:spatial` — `Q(ρ) = inv(K(ρ))` from `coords`; **`ρ` is a nuisance**, so `Q` (and `logdetQ`) **rebuild every outer eval** (cf. the Gaussian spatial note in `gaussian_structured.jl:110`). Adds one nuisance param to the outer vector.
- **Relax the guard** in each family file: accept `kind ∈ {:phylo,:relmat,:animal,:spatial}`, thread the matching kwarg (`tree=` / `K=`/`Ainv=` / `coords=`), error only on genuinely-unsupported combos.
- The spine (`_phylo_mean_*`) is unchanged — it already takes `(Q, group_node, logdetQ)`. Rename it `_structured_mean_*` for honesty (optional, low-risk).

**Stretch (defer):** correlated structured slope `marker(1 + x | g)` — `_split_ranef`
currently rejects it; out of this slice.

## Slice B — #164: nonconstant σ (`sigma ~ x`) for non-Gaussian RE

Today `_fit_*_phylo_laplace` require `sigma ~ 1` and pass **one** dispersion
nuisance into `_fit_phylo_mean_laplace_nuisance` (`θσ0::Real`, `sigma_scale`).
Generalize:

- Let the dispersion enter **per observation**: `aux_i = sigma_scale(Xσ_i · βσ)`
  (NB2 φ, Gamma α, Beta φ), with **`βσ` a vector** joining the outer parameter
  block (replacing the scalar nuisance).
- The `Val{}` kernels already take `aux` **per-`i`** (`_laplace_*(::Val, aux, i, η)`),
  so the kernels need **no change** — only the wrapper that builds `aux` and the
  outer parameter packing/gradient block for `βσ`.
- Remove the `size(Xσ,2)==1` guards once the per-obs path is verified; keep the
  constant-σ path as the `kᵪ=1` special case (no regression).

## Slice C — #166: beta-binomial kernel

Purely a **missing kernel** — the spine and routing are generic. Add
`_laplace_value/d1/d2/d3(::Val{:betabinomial}, aux, i, η)`: the BB conditional
log-density (with `aux` carrying trials `n_i` and overdispersion φ) and its first
three η-derivatives (mean on the logit link). Then route `BetaBinomial()` through
the same phylo/crossed wrappers as Binomial. Constant-φ first (nonconstant φ
inherits Slice B once both land).

## Slice D — #165: exact outer gradient (the verified-engine bar)

Replace the **frozen-mode + FD-polish** outer gradient (crossed route, and any
other route still on it) with the **exact implicit-function gradient** — the same
recipe the verified q=4 engine uses (`fit_q4_tmbgrad.jl` / `marginal_and_exact_grad`):
`dL/dθ = ∇_θ[jn + ½logdetH]|_{û frozen} − (dû/dθ)'·v`, with `v = ½∇_u logdetH`,
`dû/dθ = −H⁻¹ ∂²jn/∂u∂θ`, and the `logdetH` θ-derivative as a **Takahashi
selected-inverse trace** — and `takahashi_selinv` is **already computed** in these
routes for the mode/Hessian (`sparse_laplace_glmm.jl:286,454,612,880`). So the
selected-inverse machinery is in place; #165 wires it into the marginal gradient
and drops the FD polish + FD-Hessian vcov.

**Per-route audit first:** the phylo `_phylo_mean_laplace_fg` already returns an
analytic `g` via Takahashi — confirm whether it's exact or frozen before
touching it; the explicit "frozen + FD" is the **crossed** fitter. Target only
the routes that are still FD.

## Cross-cutting

- **kwarg threading:** `drm(...; tree, K, Ainv, coords)` must reach the family
  dispatchers (mirror how `tree=` is threaded today).
- **R-bridge tie-in (#5/#19):** `K`/`Ainv` marshalling + name alignment is the
  same convention the bridge design (#193) needs — build once.

## Dependencies & sequencing (recommended)

1. **#167 relmat/animal** — cheapest (fixed `K`, identical flow to phylo); biggest capability/effort ratio. *First.*
2. **#166 beta-binomial kernel** — independent; parallelizable. 
3. **#167 spatial** — adds the `ρ`-nuisance rebuild; slightly more involved.
4. **#164 σ ~ x** — per-obs dispersion refactor of the nuisance path.
5. **#165 exact gradient** — the correctness/quality bar; benefits all routes. Land before promoting these to "verified-engine" status / before a tag that advertises them.

(#167 and #166 add **capability** and are the parity-facing wins; #165 hardens
quality. Capability-first matches the "parity with drmTMB" goal.)

## Acceptance / test plan (local Julia, per slice)

- **Recovery:** seeded sim per (family × structure) recovers β, dispersion, and
  the structured variance within tolerance.
- **Gradient ≤ 1e-6:** analytic vs finite-difference — the explicit bar in #165,
  and the acceptance gate for #166/#164 kernels/paths.
- **Collapse cross-checks:** relmat with `K=phylo-correlation` ≈ the phylo fit;
  `σ~1` special case of Slice B ≡ the current constant-σ fit (no regression);
  spatial at large range → near-iid.
- **R-parity:** add fixtures (Workflow G / `test/parity/`, #17) for the new
  (family × structure) cells against drmTMB generated outputs.
- **No regression:** existing phylo/crossed Poisson/NB2/Gamma/Beta/Binomial fits
  unchanged.

## Per-issue checklist

- [ ] **#167** `structured_precision(kind; …)` abstraction; relmat/animal (fixed K) routed for Poisson/NB2/Gamma/Beta/Binomial; guard relaxed; kwargs threaded.
- [ ] **#167** spatial (`coords`, `ρ`-nuisance rebuild) routed.
- [ ] **#166** `Val{:betabinomial}` value/d1/d2/d3 kernel; `BetaBinomial()` routed through phylo/crossed; gradient ≤ 1e-6.
- [ ] **#164** per-obs dispersion (`βσ` vector) in the nuisance path; remove `size(Xσ,2)==1` guards; constant-σ no-regression.
- [ ] **#165** exact implicit-function outer gradient (reuse `takahashi_selinv`) on the FD routes; drop FD polish + FD-Hessian vcov; per-route audit.
- [ ] Recovery + gradient + collapse tests per slice; parity fixtures; docs/articles (animal-models, spatial-models, relmat-known-matrices) gain non-Gaussian variants.
