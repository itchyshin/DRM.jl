# gaussian_meta.jl — Gaussian meta-analysis with known sampling (co)variances.
#
#   y_i ~ N(x_iᵀβ, v_i + σ_i²),   v_i supplied (known),  σ_i the residual
# heterogeneity (the σ formula; σ ~ 1 gives a single between-study τ). Marker:
# `meta_V(v)` inside the μ formula flags the data column `v` of known sampling
# variances. Mirrors drmTMB's `gaussian() + meta_V(V = V)`.

"""
    meta_V(v)

Formula marker for Gaussian meta-analysis: `v` is the data column of **known**
sampling variances. Use inside a `μ` formula, e.g.
`bf(y ~ x + meta_V(v), sigma ~ 1)`. The residual heterogeneity (τ) is the `σ`
parameter. (Diagonal known variances; dense/bivariate sampling covariance is
planned.)
"""
meta_V(v) = v     # identity stub; the marker is intercepted during formula parsing

function _fit_meta_gaussian(fam::Gaussian, y, Xμ, Xσ, vv, nmμ, nmσ, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = Xμ * βμ; ησ = Xσ * βσ                 # ησ = log τ_i
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            var = vv[i] + exp(2 * ησ[i])           # known sampling var + heterogeneity
            r = y[i] - ημ[i]
            s += log(var) + r * r / var
        end
        return 0.5 * s + 0.5 * n * log(2π)
    end
    βμ0 = Xμ \ y
    θ0 = zeros(pμ + pσ)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(y - Xμ * βμ0) / 2 + eps())   # τ below the total residual sd
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs)
end
