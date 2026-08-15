# After-task — A4d: two inventories built, two ports refused

Date: 2026-08-15 · lane: DRM.jl (Claude, arc-loop) · arcs A4d-1 / A4d-2 · anchor drmTMB **0.7.0**

## What shipped

`src/introspection.jl` — `profile_targets(fit; ready_only = false)` and
`structured_effects(fit)`, the Julia twins of drmTMB's `profile_targets()`
(`R/profile.R:660`) and `structured_effects()` (`R/methods.R:233`).

## What did NOT ship, and why that is the result

Two of the four items in this arc were **refused after measurement**. Both
refusals are the point of the arc, not a shortfall in it: the A4 re-scope already
established that this campaign's ledger counts *export names*, and that closing a
name without closing a capability makes the countdown lie.

### A4d-1 `corpair` — BLOCKED, on two independent grounds

**1. The syntax is not expressible.** `bf()` is built on StatsModels'
`@formula`, which rejects both ingredients of drmTMB's marker at
macro-expansion time, before any DRM.jl code runs:

```julia
@formula(corpair(species, level = "phylogenetic") ~ x)
# ArgumentError: non-call expression encountered: $(Expr(:kw, :level, "phylogenetic"))
@formula(corpair(species, "phylogenetic") ~ x)
# MethodError: no method matching parse!(::String, ::Bool)
```

Keyword arguments and string literals are both unrepresentable. drmTMB's
`corpair(group, level =, block =, class =, from =, to =)` uses both. So the
AGENTS.md formula-parity contract — *syntactically identical, paste-and-run* —
**cannot be met for this marker**, and DRM.jl cannot even improve the error a
pasting user sees, because the failure is inside the macro.

This is the same constraint that shaped every existing marker: `phylo(x) = x`,
`relmat(x) = x` are positional identity stubs with configuration moved to
`drm(...)` keywords, exactly as the formula-grammar developer note documents.

**2. The fitted path has no counterpart.** drmTMB's real `corpair` route attaches
a group-level design to a **labelled covariance block** (`block = "p"`, the
`(1 | p | id)` grammar). DRM.jl has no labelled covariance-block grammar at all —
`_split_ranef` reads only `t.args[1]` and `t.args[2]`. Building one is a
covariance-block-grammar slice, not a marker port.

Building a *divergent* `corpair` — positional, options on `drm()` — would be
worse than absence: non-paste-compatible syntax under a name whose whole contract
is paste-compatibility, that still cannot fit anything.

Lifting this is an owner decision about the front end itself (a `@drmformula`
macro supporting keyword arguments), not a marker port.

### A4d-2 `meta_vcov_bivariate` — BLOCKED

It constructs the dense `2n × 2n` known sampling-covariance `V` for bivariate
meta-analysis. DRM.jl's `meta_V` is **diagonal-only** — `gaussian_meta.jl:16`
says so outright, `meta_V(v)` marks a single column consumed as a scalar per row
(`gaussian_meta.jl:28`), and the bivariate route does not consume `metav` at all.

Porting it would export a constructor whose output **nothing in DRM.jl can
accept**. Blocked on a dense bivariate `V_known` engine path.

## The two that were worth building

`profile_targets` is only worth having if `profile_ready` tracks what
`profile_result` will *actually* do. A readiness column that always says "ready"
is worse than no column, because it converts a clear downstream error into a
broken promise. So the implementation mirrors `profile_result`'s dispatch
branch-for-branch, and the tests pin it on three routes that genuinely differ:

| route | ready? | checked against |
|---|---|---|
| fixed-effect location-scale | yes | row count equals `length(profile_result(fit).ci)` |
| σ-phylo (no stored objective) | no | `profile_result(fit)` does throw, and the note names `profile_ci` |
| σ-phylo + `profile_ci = true` | only the SD blocks | precomputed rows exist for those blocks alone |

That third case is the one that makes the column non-trivial: the mean and scale
coefficients stay *not ready* even on a `profile_ci = true` fit, because the
route precomputes SD rows only. Reporting them as ready would have been the easy
bug.

`structured_effects` reconstructs markers from the retained formula via
`_collect_structured`, one row per `(dpar, kind, grouping)`. It declines rather
than guesses on a formula shape it does not recognise — an introspection helper
that invents structure is worse than one that returns nothing.

## Evidence

`test_introspection.jl` — 21 assertions, all passing.

## Effect on the countdown

A4d closes **2** of the 6 genuinely-owed export gaps and converts **2** into
written `claim_boundary` entries. That satisfies GOAL.md's closure rule (every
row either `supported` with a fixture, or carrying an explicit written reason)
without inflating the supported count.

Remaining genuinely owed after this arc: `drm_phylo_penalty` +
`drm_phylo_penalty_sweep` (**done**, A4c, PR #414) — so the real remainder is
`corpair` and `meta_vcov_bivariate`, both now blocked with reasons.

## What this arc does NOT cover

- No `corpair` marker of any kind, divergent or otherwise.
- No dense bivariate `V_known` path, and therefore no `meta_vcov_bivariate`.
- `profile_targets` reports DRM.jl's own blocks; it does not attempt drmTMB's
  richer `target_class` / `transformation` columns, which describe R-side
  derived and constrained targets DRM.jl does not have.
- `structured_effects` returns `(dpar, kind, grouping)` only, not drmTMB's ~20
  provenance columns (matrix digest, level alignment, missing-level policy),
  which describe metadata DRM.jl does not retain.
- `docs/src/rosetta.md:117` still mis-maps `corpair` as an accessor — real, and
  left for a docs pass rather than folded in here.
