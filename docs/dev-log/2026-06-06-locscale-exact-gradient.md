# Exact O(p) outer gradient for the q=2 location–scale Laplace marginal (#202)

Design note + derivation. Written so the work can be rehydrated from the repo
(not chat memory). Branch `claude/202-grad`. Verification is CI-only this
session (no local Julia: package/install servers are network-blocked).

## What we are differentiating

The packed objective is `_ls_fit_nll(θ)` with `θ = [βμ (pμ); βψ (pψ); λ (3)]`:

    η0 = Xμ βμ,  ψ0 = Xψ βψ,  Λ = L Lᵀ (log-Cholesky λ),  P = kron(Q, Λ⁻¹)
    jn(a) = Σᵢ nllᵢ(η0ᵢ + a[2g-1], ψ0ᵢ + a[2g]) + ½ aᵀ P a        (group-major a ∈ R^{2G})
    â = argmin_a jn,   H = ∇²_a jn = P + D(â)   (D block-diag, one 2×2/group)
    M(θ) = jn(â) + ½ logdet H − ½ logdet P

`g(a,θ) = ∇_a jn`, and `g(â,θ) = 0`.

## Exact gradient (adjoint form, O(p))

Envelope theorem kills the explicit `∂jn/∂a` term. Writing `Dₖ` for the partial
holding `a = â` fixed and adding the implicit-`â` correction:

    dM/dθₖ = ∂jn/∂θₖ + ½ tr(H⁻¹ ∂H/∂θₖ) − ½ tr(P⁻¹ ∂P/∂θₖ)  −  wᵀ (∂g/∂θₖ)

where the implicit term uses the shared adjoint
    v_j = ½ tr(H⁻¹ ∂H/∂a_j),      w = H⁻¹ v   (one extra sparse solve),
because  ∂M/∂a = ½ tr(H⁻¹ ∂H/∂a) = v  and  dâ/dθₖ = −H⁻¹ ∂g/∂θₖ, so the implicit
term is `vᵀ dâ/dθₖ = −wᵀ ∂g/∂θₖ`.

### Pieces, by block

`∂H/∂a_j` and `∂H/∂{βμ,βψ}` need the per-obs THIRD derivatives of the kernel in
(η,ψ). We get them by `ForwardDiff` of the existing analytic `_ls_hess` (no hand
3rd-deriv algebra). For group g with selected-inverse block
`Hinv_g = [α β; β δ]` (from Takahashi):

* third-deriv sums per obs i in η: `tηηη,tηηψ,tηψψ = d/dη (hηη,hηψ,hψψ)`;
  in ψ: `tηηψ,tηψψ,tψψψ = d/dψ (hηη,hηψ,hψψ)` (middle two agree — symmetry check).
* `v_{2g-1} = ½ (α·Στηηη + 2β·Στηηψ + δ·Στηψψ)` (sum over obs in g)
* `v_{2g}   = ½ (α·Στηηψ + 2β·Στηψψ + δ·Στψψψ)`

βμ component k (X = Xμ, axis η):
* `∂jn/∂βμₖ = Σᵢ Xμ[i,k]·gηᵢ(â)`
* `½ tr(H⁻¹ ∂H/∂βμₖ) = ½ Σᵢ Xμ[i,k] (α_g tηηηᵢ + 2β_g tηηψᵢ + δ_g tηψψᵢ)`
* `−wᵀ ∂g/∂βμₖ = −Σᵢ Xμ[i,k] (w[2g-1] hηηᵢ + w[2g] hηψᵢ)`

βψ component k (X = Xψ, axis ψ): same with η→ψ:
* `∂jn/∂βψₖ = Σᵢ Xψ[i,k]·gψᵢ(â)`
* `½ tr(...) = ½ Σᵢ Xψ[i,k] (α_g tηηψᵢ + 2β_g tηψψᵢ + δ_g tψψψᵢ)`
* `−wᵀ ∂g/∂βψₖ = −Σᵢ Xψ[i,k] (w[2g-1] hηψᵢ + w[2g] hψψᵢ)`

λ component k (only P depends on λ; `∂H/∂λ = ∂P/∂λ`, no a-dependence):
let `Mk = ∂Λ⁻¹/∂λₖ = −Λ⁻¹ (∂Λ/∂λₖ) Λ⁻¹` (∂Λ/∂λₖ via ForwardDiff of `_ls_lc_to_Λ`),
`Pλk = kron(Q, Mk)`. With group blocks `a_g=[a[2g-1];a[2g]]`, `w_g` similarly:
* `∂jn/∂λₖ = ½ âᵀ Pλk â = ½ Σ_{g,h} Q[g,h] a_gᵀ Mk a_h`
* `½ tr(H⁻¹ Pλk) = ½ Σ_{g,h} Q[g,h] ⟨Hinv_block(g,h), Mk⟩`
* `−wᵀ ∂g/∂λₖ = −wᵀ Pλk â = −Σ_{g,h} Q[g,h] w_gᵀ Mk a_h`
* `−½ tr(P⁻¹ ∂P/∂λₖ) = +½ G · tr(Λ⁻¹ ∂Λ/∂λₖ)`  (since P⁻¹=kron(Q⁻¹,Λ))

All Hinv entries needed (within-group blocks and the (g,h) blocks where Q[g,h]≠0)
lie in the `L+Lᵀ` pattern because pattern(P) ⊆ pattern(H) ⊆ pattern(L+Lᵀ); the
Takahashi selected inverse returns them exactly.

## Layered plan (each gated by CI)

1. `src/locscale_grad.jl`: `_ls_marginal_grad(kind,y,Xμ,Xψ,gidx,G,Q,θ)`.
   Test `test/test_locscale_grad.jl`: analytic grad vs central FD of
   `_ls_fit_nll`, i.i.d. AND tree fixtures, atol ~1e-5. **(this PR)**
2. Wire into `_fit_locscale` (LBFGS w/ analytic grad → fast + accurate);
   add a recovery test (now feasible).  **(next PR)**
3. `drm()` front-end routing for `phylo(1|species)` in the σ formula + named
   group-level accessors.  **(later)**

## Status log
- 2026-06-06: derivation + Layer 1 implementation written (blind; CI to verify).
