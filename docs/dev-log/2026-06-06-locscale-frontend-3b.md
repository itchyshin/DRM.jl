# Slice 3b — public `bf()`/`drm()` routing for the location–scale model (#209)

Decision (2026-06-06, with @itchyshin): **mirror drmTMB/brms**. Use the
correlated-RE tag syntax `(1 | <tag> | group)` — the same `<tag>` across the
`mu` and `sigma` formulas couples those intercept REs into one joint covariance
(the engine's 2×2 Λ). No new family handle: `NegBinomial2()`/`Gamma()` stay; the
cross-formula shared tag is the trigger.

## Target API

    drm(bf(y ~ x + (1|p|species), sigma ~ x + (1|p|species)), NegBinomial2(); data)

→ routes to `_fit_locscale(Val(:nb2), y, Xμ, Xψ, gidx, G, Q=I; se=true)`.

## Parse facts (verified by reading the parser, not Julia)

- `_split_ranef` (src/gaussian_ranef.jl) turns `(lhs | g)` into a
  `FunctionTerm{typeof(|)}` with `args = [lhs, group_term]`; it pushes
  `(lhs, group.sym)` into `re`.
- Julia parses `1 | p | ID` left-associatively → `|(|(1,p), ID)`. So for the
  3-part form the OUTER term has `args[1] = |(1,p)` (itself a `FunctionTerm{|}`)
  and `args[2] = ID`. Detect: `t.args[1] isa FunctionTerm && t.args[1].f === (|)`
  ⇒ `coef = t.args[1].args[1]`, `tag = t.args[1].args[2].sym`, `group = t.args[2].sym`.
- Changing `_split_ranef`'s return type would ripple into every family. Instead
  add a dedicated detector `_ls_coupled_re(rhs_mu, rhs_sigma)` used only on the
  location–scale path; leave `_split_ranef` untouched.

## Plan (CI-gated, incremental)

1. **Parser + detector** `_ls_coupled_re(rhs_mu, rhs_sigma) -> (group::Symbol, tag) | nothing`:
   returns the grouping when an intercept `(1|tag|group)` appears in BOTH mu and
   sigma with matching `tag` + `group`. Grammar test (parse → extract).
2. **Routing**: a branch at the TOP of `drm(f::DrmFormula, ::NegBinomial2)` (and
   Gamma) — if `_ls_coupled_re` fires, build `Xμ/Xψ` from the FIXED parts, the
   group index from `group`, `Q = I_G`, call `_fit_locscale(...; se=true)`, wrap
   in a `DrmFit`. End-to-end test through `drm()` vs a direct `_fit_locscale` call
   (parity).
3. **summary/accessors**: report the 2×2 Λ as brms-style group-level
   `sd(mu_Intercept)`, `sd(sigma_Intercept)`, `cor(mu_Intercept, sigma_Intercept)`.

## Constraints / open

- i.i.d. first (`Q=I`). Phylo correlated RE waits on the phylo-fit-robustness fix
  (open finding: phylo fit slow / non-converging at moderate p).
- Only intercept-only `(1|p|ID)` for the first cut; error clearly on slopes in
  the coupled term.
- Need to read `DrmFit` fields + how `_fit_negbin2_corr_ranef` reports a
  correlated RE in `summary`, to construct/display the location–scale fit
  consistently.
