# locscale_kernels.jl — two-axis conditional-likelihood kernels for the
# non-Gaussian phylogenetic LOCATION–SCALE model (#202).
#
# Groundwork only: these are pure per-observation kernels, not wired into `drm()`.
# The existing non-Gaussian Laplace spine (`sparse_laplace_glmm.jl`) varies only
# the mean linear predictor η while the dispersion rides as a single global
# scalar. #202 makes the dispersion a per-species latent too, so the conditional
# log-likelihood must expose derivatives in BOTH axes:
#
#   η  — mean linear predictor
#   ψ  — log-dispersion latent
#
# Per family the two axes map to the family parameters as follows (the link/
# dispersion conventions match the standalone fits in each family file, so the
# coupled-RE `coef(:sigma)` is on the SAME scale as the fixed-only fit):
#   NB2          : μ = exp η (log link),     size  r = exp ψ
#   Gamma        : μ = exp η (log link),     shape α = exp ψ
#   Beta         : μ = logistic η (logit),   precision φ = exp(-2ψ)   [σ = e^ψ]
#   BetaBinomial : μ = logistic η (logit),   precision φ = exp(-2ψ)   [σ = e^ψ]
#
# The Beta / BetaBinomial dispersion convention is φ = exp(−2ψ) (so ψ = log σ),
# matching `beta.jl` / `betabinomial.jl` and the `:beta_fixed` Laplace nuisance
# kernel (whose `_laplace_nuisance_*` carry the −2φ = dφ/dψ chain factor). A plain
# Binomial has NO free dispersion, so its scale axis is unidentifiable; the
# overdispersed-binomial leaf is therefore the BETA-BINOMIAL, whose φ axis IS the
# scale axis. The BetaBinomial leaf carries trials per observation by packing the
# response as a 2-tuple `y = (successes, trials)`.
#
# Each kernel returns the per-observation negative log-likelihood and its
# gradient (∂η, ∂ψ) and Hessian block ((∂ηη, ∂ηψ), (∂ψψ)). These feed the q=2
# augmented-state inner Newton solve and the Laplace marginal in a later slice.
#
# Correctness anchors (cross-checked against the verified fixed-nuisance kernels
# in `sparse_laplace_glmm.jl`):
#   ∂nll/∂η, ∂²nll/∂η², ∂²nll/∂η∂ψ  match `_laplace_d1/_d2` and
#   `_laplace_nuisance_d1` for `:nb2_fixed` / `:gamma_fixed` / `:beta_fixed`
#   (the cross term after the dψ = −2φ chain factor). The BetaBinomial η-axis
#   collapses to `:binomial` in the large-φ limit. Only the new ∂²nll/∂ψ² block
#   has no fixed-nuisance analog. `test/test_locscale_kernels.jl` gates the full
#   gradient + Hessian against ForwardDiff.

using SpecialFunctions: digamma, trigamma, loggamma
import Distributions
import ForwardDiff

const LS_CLAMP = 30.0
const LS_PSI_CLAMP = 15.0          # φ = exp(-2ψ) ⇒ clamp ψ to keep φ finite & > 0

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

# ---------------------------------------------------------------------------
# Beta: mean μ = logistic η (logit link), precision φ = exp(-2ψ) (so ψ = log σ,
# the drmTMB mapping). Shapes a = μφ, b = (1-μ)φ. y ∈ (0,1). The η-axis pieces
# reuse the exact chain-rule structure of `_laplace_beta_terms`; the ψ axis adds
# the dφ/dψ = -2φ chain factor (matching `_laplace_*_nuisance(:beta_fixed)`).
# ---------------------------------------------------------------------------

function _ls_nll(::Val{:beta}, y, η, ψ)
    μ = 1 / (1 + exp(-clamp(η, -LS_CLAMP, LS_CLAMP)))
    φ = exp(-2 * clamp(ψ, -LS_PSI_CLAMP, LS_PSI_CLAMP))
    a = μ * φ
    b = (1 - μ) * φ
    logp = loggamma(φ) - loggamma(a) - loggamma(b) +
           (a - 1) * log(y) + (b - 1) * log1p(-y)
    return -logp
end

function _ls_grad(::Val{:beta}, y, η, ψ)
    μ = 1 / (1 + exp(-clamp(η, -LS_CLAMP, LS_CLAMP)))
    φ = exp(-2 * clamp(ψ, -LS_PSI_CLAMP, LS_PSI_CLAMP))
    a = μ * φ; b = (1 - μ) * φ
    v = μ * (1 - μ)
    ylogit = log(y) - log1p(-y)
    A = φ * (digamma(a) - digamma(b) - ylogit)         # ∂(-logp)/∂η = A·v
    gη = A * v
    # ∂(-logp)/∂φ, then chain dφ/dψ = -2φ.
    dnll_dφ = -(digamma(φ) - μ * digamma(a) - (1 - μ) * digamma(b) +
                μ * log(y) + (1 - μ) * log1p(-y))
    gψ = -2 * φ * dnll_dφ
    return gη, gψ
end

function _ls_hess(::Val{:beta}, y, η, ψ)
    μ = 1 / (1 + exp(-clamp(η, -LS_CLAMP, LS_CLAMP)))
    φ = exp(-2 * clamp(ψ, -LS_PSI_CLAMP, LS_PSI_CLAMP))
    a = μ * φ; b = (1 - μ) * φ
    ta = trigamma(a); tb = trigamma(b)
    v = μ * (1 - μ); vp = v * (1 - 2μ)
    ylogit = log(y) - log1p(-y)
    A = φ * (digamma(a) - digamma(b) - ylogit)
    B = φ^2 * (ta + tb)
    hηη = B * v^2 + A * vp
    # cross term: ∂(A·v)/∂φ · dφ/dψ, with dA/dφ = `_laplace_beta_nuisance` dA.
    dA = digamma(a) - digamma(b) - ylogit + φ * (μ * ta - (1 - μ) * tb)
    hηψ = -2 * φ * (dA * v)
    # ψψ: gψ = -2φ·dnll_dφ ⇒ hψψ = 4φ·dnll_dφ + 4φ²·d²nll_dφ².
    dnll_dφ = -(digamma(φ) - μ * digamma(a) - (1 - μ) * digamma(b) +
                μ * log(y) + (1 - μ) * log1p(-y))
    d2nll_dφ2 = -(trigamma(φ) - μ^2 * ta - (1 - μ)^2 * tb)
    hψψ = 4 * φ * dnll_dφ + 4 * φ^2 * d2nll_dφ2
    return hηη, hηψ, hψψ
end

# ---------------------------------------------------------------------------
# Beta-binomial (overdispersed binomial): s successes of n trials per obs,
# carried as `y = (s, n)`. mean p = logistic η (logit link), precision
# φ = exp(-2ψ); likelihood BetaBinomial(n, pφ, (1-p)φ) — the φ axis is the scale
# axis (a plain Binomial has no free dispersion). The BetaBinomial logpmf has no
# clean closed-form (η,ψ) derivatives, so grad/Hess come from ForwardDiff of the
# analytic `_ls_nll` — consistent with house style (`_ls_third` already
# ForwardDiffs `_ls_hess`). Cross-checked vs ForwardDiff (kernel test block 1)
# and, in the large-φ limit, vs the `:binomial` η-axis Laplace kernels.
# ---------------------------------------------------------------------------

@inline _ls_bb_sn(y) = (Int(round(y[1])), Int(round(y[2])))

function _ls_nll(::Val{:betabinomial}, y, η, ψ)
    s, n = _ls_bb_sn(y)
    μ = 1 / (1 + exp(-clamp(η, -LS_CLAMP, LS_CLAMP)))
    φ = exp(-2 * clamp(ψ, -LS_PSI_CLAMP, LS_PSI_CLAMP))
    return -Distributions.logpdf(Distributions.BetaBinomial(n, μ * φ, (1 - μ) * φ), s)
end

function _ls_grad(::Val{:betabinomial}, y, η, ψ)
    f = θ -> _ls_nll(Val(:betabinomial), y, θ[1], θ[2])
    g = ForwardDiff.gradient(f, [η, ψ])
    return g[1], g[2]
end

function _ls_hess(::Val{:betabinomial}, y, η, ψ)
    f = θ -> _ls_nll(Val(:betabinomial), y, θ[1], θ[2])
    H = ForwardDiff.hessian(f, [η, ψ])
    return H[1, 1], H[1, 2], H[2, 2]
end

# ---------------------------------------------------------------------------
# Poisson (mean μ = exp η; MEAN-ONLY — no free dispersion). The ψ axis is null:
# the leaf ignores ψ entirely, so under the correlated-RE promotion both latent
# axes load η (Zη = [1 xᵢ], Zψ = [0 0]) and the scale design is empty (pψ = 0).
# This is the cleanest case that the two q2 axes are loadings on ONE predictor,
# not a (mean, scale) pair. The η-axis pieces match the verified Poisson Laplace
# kernels (`_laplace_d1/_d2` :poisson) up to sign (nll = −logpmf).
# ---------------------------------------------------------------------------

function _ls_nll(::Val{:poisson}, y, η, ψ)
    ηc = clamp(η, -LS_CLAMP, LS_CLAMP)
    return -(y * ηc - exp(ηc) - loggamma(y + 1))
end

function _ls_grad(::Val{:poisson}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    return (μ - y, zero(η))            # ∂nll/∂η = μ − y;  ∂nll/∂ψ = 0
end

function _ls_hess(::Val{:poisson}, y, η, ψ)
    μ = exp(clamp(η, -LS_CLAMP, LS_CLAMP))
    return (μ, zero(η), zero(η))       # ∂²nll/∂η² = μ;  cross/ψψ = 0
end

# ---------------------------------------------------------------------------
# LogNormal (log y ~ Normal(μ = η, σ = exp ψ); identity link on the log scale).
# Equivalent to the Gaussian location–scale on log y. The −log y change-of-
# variables Jacobian is carried per observation so the Laplace marginal logLik
# matches the GHQ `_fit_lognormal_*` convention (which adds Σ log y). y is the
# RAW positive response; log y is taken inside the kernel.
# ---------------------------------------------------------------------------

function _ls_nll(::Val{:lognormal}, y, η, ψ)
    ly = log(y)
    r = ly - η
    return ψ + 0.5 * r * r * exp(-2 * ψ) + 0.5 * log(2π) + ly   # +log y Jacobian
end

function _ls_grad(::Val{:lognormal}, y, η, ψ)
    r = log(y) - η
    e = exp(-2 * ψ)
    gη = -r * e                         # ∂nll/∂η
    gψ = 1 - r * r * e                  # ∂nll/∂ψ  (d/dψ of ψ + ½r²e^{-2ψ})
    return gη, gψ
end

function _ls_hess(::Val{:lognormal}, y, η, ψ)
    r = log(y) - η
    e = exp(-2 * ψ)
    hηη = e                             # ∂²nll/∂η²
    hηψ = 2 * r * e                     # ∂²nll/∂η∂ψ
    hψψ = 2 * r * r * e                 # ∂²nll/∂ψ²
    return hηη, hηψ, hψψ
end

# Gaussian mean leaf: η = mean, ψ = log(σ_res). The full location-scale leaf the
# σ-phylo route (gaussian_locscale_phylo.jl) dispatches on via Val(:gaussian_mean).
# Hoisted here from the branch's rich_bivariate.jl (a separate ⑤b subsystem not
# part of this merge) — these 3 methods are all the σ-phylo Gaussian route needs.
function _ls_nll(::Val{:gaussian_mean}, y, η, ψ)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    r = y - η
    return 0.5 * (r^2 / σ^2 + log(2π * σ^2))
end

function _ls_grad(::Val{:gaussian_mean}, y, η, ψ)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    r = y - η
    gη = -r / σ^2
    gψ = 1.0 - r^2 / σ^2                # d/d(log σ)[½ r²/σ² + ½ log(2π σ²)]
    return gη, gψ
end

function _ls_hess(::Val{:gaussian_mean}, y, η, ψ)
    σ = exp(clamp(ψ, -LS_CLAMP, LS_CLAMP))
    r = y - η
    hηη = 1.0 / σ^2
    hηψ = 2.0 * r / σ^2
    hψψ = 2.0 * r^2 / σ^2
    return hηη, hηψ, hψψ
end
