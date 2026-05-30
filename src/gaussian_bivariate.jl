# gaussian_bivariate.jl — bivariate Gaussian location–scale with a
# predictor-dependent residual correlation ρ12 (fixed effects, ML). Mirrors
# drmTMB's bivariate Gaussian:
#
#   bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = …, sigma2 = …, rho12 = …)
#
# σ1, σ2 use a log link; ρ12 uses a tanh link (so its coefficients act on
# atanh ρ12, keeping ρ12 ∈ (-1, 1)).

"""
    BivariateDrmFormula

Two-response formula bundle (μ1, μ2, σ1, σ2, ρ12), built by the keyword form of
[`bf`](@ref).
"""
struct BivariateDrmFormula
    response1::Symbol
    response2::Symbol
    forms::Vector{Pair{Symbol,Any}}
end

_rhs_or_intercept(f) = f === nothing ? ConstantTerm(1) : f.rhs

"""
    bf(; mu1, mu2, sigma1=…, sigma2=…, rho12=…)

Bivariate Gaussian formula bundle, mirroring drmTMB. `mu1 = y1 ~ …` and
`mu2 = y2 ~ …` set the two responses and their mean predictors; `sigma1`,
`sigma2` (log σ) and `rho12` (atanh ρ) default to `~ 1`. For one-sided
predictors give the parameter name as a placeholder LHS, e.g.
`sigma1 = @formula(sigma1 ~ x)`.
"""
function bf(; mu1::FormulaTerm, mu2::FormulaTerm, sigma1 = nothing, sigma2 = nothing, rho12 = nothing)
    forms = Pair{Symbol,Any}[
        :mu1 => mu1.rhs,
        :mu2 => mu2.rhs,
        :sigma1 => _rhs_or_intercept(sigma1),
        :sigma2 => _rhs_or_intercept(sigma2),
        :rho12 => _rhs_or_intercept(rho12),
    ]
    return BivariateDrmFormula(mu1.lhs.sym, mu2.lhs.sym, forms)
end

function drm(f::BivariateDrmFormula, fam::Gaussian; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    y1, X1, nm1 = _design(f.response1, rhs[:mu1], data)
    y2, X2, nm2 = _design(f.response2, rhs[:mu2], data)
    _, Xs1, nms1 = _design(f.response1, rhs[:sigma1], data)   # reuse a real LHS;
    _, Xs2, nms2 = _design(f.response1, rhs[:sigma2], data)   # only the matrix is kept
    _, Xr, nmr = _design(f.response1, rhs[:rho12], data)

    n = length(y1)
    ps = (size(X1, 2), size(X2, 2), size(Xs1, 2), size(Xs2, 2), size(Xr, 2))
    offs = cumsum([0, ps...])
    rng(k) = (offs[k]+1):offs[k+1]

    function nll(θ)
        b1 = θ[rng(1)]; b2 = θ[rng(2)]; bs1 = θ[rng(3)]; bs2 = θ[rng(4)]; br = θ[rng(5)]
        η1 = X1 * b1; η2 = X2 * b2; ls1 = Xs1 * bs1; ls2 = Xs2 * bs2; ηr = Xr * br
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            ρ = tanh(ηr[i])
            om = 1 - ρ * ρ
            z1 = (y1[i] - η1[i]) * exp(-ls1[i])     # standardised residuals
            z2 = (y2[i] - η2[i]) * exp(-ls2[i])
            # −log φ₂ = log(2π) + (½ log|Σ|) + (½ rᵀΣ⁻¹r)
            s += ls1[i] + ls2[i] + 0.5 * log(om) + 0.5 * (z1 * z1 - 2ρ * z1 * z2 + z2 * z2) / om
        end
        return s + n * log(2π)
    end

    θ0 = zeros(offs[end])
    β1 = X1 \ y1; β2 = X2 \ y2
    θ0[rng(1)] .= β1
    θ0[rng(2)] .= β2
    θ0[offs[3]+1] = log(std(y1 - X1 * β1) + eps())
    θ0[offs[4]+1] = log(std(y2 - X2 * β2) + eps())     # ρ intercept starts at 0

    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))

    blocks = [:mu1 => rng(1), :mu2 => rng(2), :sigma1 => rng(3), :sigma2 => rng(4), :rho12 => rng(5)]
    names = [:mu1 => nm1, :mu2 => nm2, :sigma1 => nms1, :sigma2 => nms2, :rho12 => nmr]
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res))
end
