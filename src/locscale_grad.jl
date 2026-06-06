# locscale_grad.jl — exact O(p) outer gradient of the q=2 location–scale Laplace
# marginal (#202). Differentiates `_ls_fit_nll` w.r.t. the packed
# θ = [βμ; βψ; λ(3)] analytically, in O(p) (Takahashi selected inverse + a single
# adjoint solve; never forms a dense Hessian inverse).
#
# Derivation and the per-block formulas are in
# docs/dev-log/2026-06-06-locscale-exact-gradient.md. In brief, with
#   M(θ) = jn(â) + ½ logdet H − ½ logdet P,  g(â)=0,  v_j=½ tr(H⁻¹ ∂H/∂a_j),
#   w = H⁻¹ v,
# the exact gradient is
#   dM/dθₖ = ∂jn/∂θₖ + ½ tr(H⁻¹ ∂H/∂θₖ) − ½ tr(P⁻¹ ∂P/∂θₖ) − wᵀ ∂g/∂θₖ.
# Third derivatives of the kernel (needed for ∂H/∂a and ∂H/∂β) come from
# ForwardDiff of the analytic `_ls_hess`, so there is no hand-coded 3rd-deriv
# algebra. `test/test_locscale_grad.jl` gates this against central finite
# differences of `_ls_fit_nll` for i.i.d. and tree fixtures.

using ForwardDiff: derivative
using SparseArrays: rowvals, nonzeros, nzrange

# Per-observation third derivatives of the kernel in (η, ψ), obtained by
# ForwardDiff of the analytic second-derivative kernel. Returns
# (tηηη, tηηψ, tηψψ, tψψψ); the two mixed paths agree by symmetry.
function _ls_third(kind, y, η, ψ)
    dη = derivative(t -> collect(_ls_hess(kind, y, t, ψ)), η)   # d/dη (hηη,hηψ,hψψ)
    dψ = derivative(t -> collect(_ls_hess(kind, y, η, t)), ψ)   # d/dψ (hηη,hηψ,hψψ)
    return dη[1], dη[2], dη[3], dψ[3]
end

# ∂Λ/∂λ_k (2×2) by ForwardDiff of the log-Cholesky map.
function _dΛ_dλ(λ, k::Int)
    return derivative(t -> _ls_lc_to_Λ([i == k ? t : λ[i] for i in 1:3]), λ[k])
end

"""
    _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ) -> Vector

Exact gradient of `_ls_fit_nll` at the packed θ = [βμ; βψ; λ(3)]. Returns a
zero vector if the inner mode fails to converge (rare; the caller treats this as
a flat step). O(p) in the number of groups.
"""
function _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ; a0 = nothing)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ = @view θ[1:pμ]
    βψ = @view θ[pμ+1:pμ+pψ]
    λ  = θ[pμ+pψ+1:pμ+pψ+3]
    Λ = _ls_lc_to_Λ(λ); Λinv = _ls_inv2x2(Λ)
    P = prior_precision(Q, Λinv)
    η0 = Xμ * βμ; ψ0 = Xψ * βψ

    a, ch, ok = _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P; a0 = a0)
    grad = zeros(length(θ))
    ok || return grad

    # 2×2 diagonal blocks of H⁻¹ from the Takahashi selected inverse.
    Hinv = takahashi_selinv(ch)
    α = zeros(G); β = zeros(G); δ = zeros(G)
    @inbounds for g in 1:G
        α[g] = Hinv[2g-1, 2g-1]; β[g] = Hinv[2g-1, 2g]; δ[g] = Hinv[2g, 2g]
    end

    # Adjoint v_j = ½ tr(H⁻¹ ∂H/∂a_j): group-wise third-derivative sums.
    Tηηη = zeros(G); Tηηψ = zeros(G); Tηψψ = zeros(G); Tψψψ = zeros(G)
    @inbounds for i in eachindex(y)
        g = gidx[i]
        t1, t2, t3, t4 = _ls_third(kind, y[i], η0[i] + a[2g-1], ψ0[i] + a[2g])
        Tηηη[g] += t1; Tηηψ[g] += t2; Tηψψ[g] += t3; Tψψψ[g] += t4
    end
    v = zeros(2G)
    @inbounds for g in 1:G
        v[2g-1] = 0.5 * (α[g] * Tηηη[g] + 2β[g] * Tηηψ[g] + δ[g] * Tηψψ[g])
        v[2g]   = 0.5 * (α[g] * Tηηψ[g] + 2β[g] * Tηψψ[g] + δ[g] * Tψψψ[g])
    end
    w = ch \ v

    # βμ / βψ components (one obs loop). Each obs contributes a column-weighted
    # scalar on the mean axis (cμ) and the scale axis (cψ).
    @inbounds for i in eachindex(y)
        g = gidx[i]
        ηi = η0[i] + a[2g-1]; ψi = ψ0[i] + a[2g]
        gη, gψ = _ls_grad(kind, y[i], ηi, ψi)
        hηη, hηψ, hψψ = _ls_hess(kind, y[i], ηi, ψi)
        t1, t2, t3, t4 = _ls_third(kind, y[i], ηi, ψi)
        cμ = gη + 0.5 * (α[g] * t1 + 2β[g] * t2 + δ[g] * t3) -
             (w[2g-1] * hηη + w[2g] * hηψ)
        cψ = gψ + 0.5 * (α[g] * t2 + 2β[g] * t3 + δ[g] * t4) -
             (w[2g-1] * hηψ + w[2g] * hψψ)
        for k in 1:pμ
            grad[k] += Xμ[i, k] * cμ
        end
        for k in 1:pψ
            grad[pμ+k] += Xψ[i, k] * cψ
        end
    end

    # λ components: only P depends on λ, so ∂H/∂λ = ∂P/∂λ = kron(Q, Mk).
    qrows = rowvals(Q); qvals = nonzeros(Q)
    @inbounds for k in 1:3
        dΛk = _dΛ_dλ(λ, k)
        Mk = -Λinv * dΛk * Λinv               # ∂Λ⁻¹/∂λ_k
        t_quad = 0.0; t_adj = 0.0; t_tr = 0.0
        for h in 1:G
            for idx in nzrange(Q, h)
                g = qrows[idx]; q = qvals[idx]
                ag1 = a[2g-1]; ag2 = a[2g]; ah1 = a[2h-1]; ah2 = a[2h]
                m_ah1 = Mk[1, 1] * ah1 + Mk[1, 2] * ah2
                m_ah2 = Mk[2, 1] * ah1 + Mk[2, 2] * ah2
                t_quad += q * (ag1 * m_ah1 + ag2 * m_ah2)
                t_adj  += q * (w[2g-1] * m_ah1 + w[2g] * m_ah2)
                hb11 = Hinv[2g-1, 2h-1]; hb12 = Hinv[2g-1, 2h]
                hb21 = Hinv[2g, 2h-1];   hb22 = Hinv[2g, 2h]
                # ⟨Hinv_block(g,h), Mk⟩ = Σ_{s,t} Hinv[s,t]·Mk[t,s]
                t_tr += q * (hb11 * Mk[1, 1] + hb12 * Mk[2, 1] +
                             hb21 * Mk[1, 2] + hb22 * Mk[2, 2])
            end
        end
        # −½ logdet P derivative = +½ G·tr(Λ⁻¹ ∂Λ/∂λ_k)
        trLP = Λinv[1, 1] * dΛk[1, 1] + Λinv[1, 2] * dΛk[2, 1] +
               Λinv[2, 1] * dΛk[1, 2] + Λinv[2, 2] * dΛk[2, 2]
        grad[pμ+pψ+k] = 0.5 * t_quad + 0.5 * t_tr - t_adj + 0.5 * G * trLP
    end

    return grad
end
