# locscale_kernels.jl — two-axis conditional-likelihood kernels for the
# non-Gaussian phylogenetic LOCATION–SCALE model (#202).
#
# Groundwork only: these are pure per-observation kernels, not wired into `drm()`.
# The existing non-Gaussian Laplace spine (`sparse_laplace_glmm.jl`) varies only
# the mean linear predictor η while the dispersion rides as a single global
# scalar. #202 makes the dispersion a per-species latent too, so the conditional
# log-likelihood must expose derivatives in BOTH axes:
#
#   η  — mean linear predictor   (μ = exp η, log link)
#   ψ  — log-dispersion latent   (NB2: size r = exp ψ; Gamma: shape α = exp ψ)
#
# Each kernel returns the per-observation negative log-likelihood and its
# gradient (∂η, ∂ψ) and Hessian block ((∂ηη, ∂ηψ), (∂ψψ)). These feed the q=2
# augmented-state inner Newton solve and the Laplace marginal in a later slice.
#
# Correctness anchors (cross-checked against the verified fixed-nuisance kernels
# in `sparse_laplace_glmm.jl`):
#   ∂nll/∂η, ∂²nll/∂η², ∂²nll/∂η∂ψ  match `_laplace_d1/_d2` and
#   `_laplace_nuisance_d1` for `:nb2_fixed` / `:gamma_fixed`. Only ∂²nll/∂ψ² is
#   new. `test/test_locscale_kernels.jl` gates the full gradient + Hessian
#   against ForwardDiff.

using SpecialFunctions: digamma, trigamma, loggamma

const LS_CLAMP = 30.0

# ---------------------------------------------------------------------------
# Negative binomial (NB2): mean μ = exp η, size r = exp ψ, var = μ + μ²/r.
# ---------------------------------------------------------------------------

function _ls_nll(::Val{:nb2}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    r = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    den = r + μ
    logp = loggamma(y + r) - loggamma(r) - loggamma(y + 1) +
           r * log(r) + y * log(μ) - (y + r) * log(den)
    return -logp
end

# Returns (∂nll/∂η, ∂nll/∂ψ).
function _ls_grad(::Val{:nb2}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    r = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    den = r + μ
    gη = (y + r) * μ / den - y
    # s = ∂logp/∂r;  ∂nll/∂ψ = -r·s
    s = digamma(y + r) - digamma(r) + log(r) + 1 - log(den) - (y + r) / den
    gψ = -r * s
    return gη, gψ
end

# Returns (∂²nll/∂η², ∂²nll/∂η∂ψ, ∂²nll/∂ψ²).
function _ls_hess(::Val{:nb2}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    r = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    den = r + μ
    hηη = (y + r) * r * μ / den^2
    hηψ = r * μ * (μ - y) / den^2
    # ∂²nll/∂ψ² = -(r·s + r²·ds/dr)
    s = digamma(y + r) - digamma(r) + log(r) + 1 - log(den) - (y + r) / den
    dsdr = trigamma(y + r) - trigamma(r) + 1 / r - 1 / den - (μ - y) / den^2
    hψψ = -(r * s + r^2 * dsdr)
    return hηη, hηψ, hψψ
end

# ---------------------------------------------------------------------------
# Gamma: mean μ = exp η, shape α = exp ψ, rate = α/μ  (so E[y] = μ, CV = 1/√α).
# ---------------------------------------------------------------------------

function _ls_nll(::Val{:gamma}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    α = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    logp = α * log(α) - α * log(μ) - loggamma(α) + (α - 1) * log(y) - α * y / μ
    return -logp
end

function _ls_grad(::Val{:gamma}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    α = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    gη = α - α * y / μ
    # q = ∂logp/∂α;  ∂nll/∂ψ = -α·q
    q = log(α) + 1 - digamma(α) + log(y) - log(μ) - y / μ
    gψ = -α * q
    return gη, gψ
end

function _ls_hess(::Val{:gamma}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    α = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    hηη = α * y / μ
    hηψ = α * (1 - y / μ)
    # ∂²nll/∂ψ² = -(α·q + α²·dq/dα),  dq/dα = 1/α - trigamma(α)
    q = log(α) + 1 - digamma(α) + log(y) - log(μ) - y / μ
    hψψ = -(α * q + α^2 * (1 / α - trigamma(α)))
    return hηη, hηψ, hψψ
end
