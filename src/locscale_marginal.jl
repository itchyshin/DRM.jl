# locscale_marginal.jl — Laplace marginal for the non-Gaussian location–scale
# model (#202). Groundwork only: not wired into `drm()`.
#
# Given fixed-effect parts η0 = Xβ and ψ0 = Zγ, a grouping, and the prior
# precision P = kron(Q, Λ⁻¹), the marginal integrates out the q=2 latent a:
#
#   p(y) = ∫ [∏ᵢ p(yᵢ | a)] N(a; 0, P⁻¹) da.
#
# The Laplace approximation expands the joint jn(a) = −Σ log p(yᵢ|a) + ½ aᵀPa at
# its mode â (the inner solve). With H = ∇²jn(â) the marginal NLL is
#
#   −log p(y) ≈ jn(â) + ½ logdet H − ½ logdet P,
#
# (the 2π factors of the prior and the Laplace integral cancel). This mirrors the
# verified q=4 PLSM marginal, reduced to q=2 with a non-Gaussian data term.
# `test/test_locscale_marginal.jl` checks it against a 2-D Gauss–Hermite integral
# (Laplace → exact as obs-per-group grows).

using LinearAlgebra: logdet, cholesky, Symmetric

"""
    _ls_marginal_nll(kind, y, η0, ψ0, gidx, G, P; a0=nothing)

Laplace-approximate marginal negative log-likelihood for the q=2 location–scale
model. Returns `(nll, â, ok)`: the marginal NLL, the inner mode, and a success
flag (the inner Newton solve can fail at extreme parameters).
"""
function _ls_marginal_nll(kind, y, η0, ψ0, gidx, G, P; a0 = nothing)
    a, ch, ok = _ls_inner_mode(kind, y, η0, ψ0, gidx, G, P; a0 = a0)
    ok || return Inf, a, false
    jn = _ls_joint(kind, y, η0, ψ0, gidx, a, P)
    logdetH = logdet(ch)
    logdetP = logdet(cholesky(Symmetric(P)))
    return jn + 0.5 * logdetH - 0.5 * logdetP, a, true
end
