# variational.jl — opt-in Gaussian-variational (VA/ELBO) marginal as an
# alternative to the Laplace (LA) marginal for latent-integral models. See #136.
# Numerical ELBO kernels are intentionally NOT implemented here yet; this file
# establishes the method-selection surface the fitters will dispatch on.

"""
    MarginalMethod

How a model's random-effect integral is approximated. Subtypes: [`Laplace`](@ref)
(mode + curvature; the default, what drmTMB/TMB use) and [`Variational`](@ref)
(maximize an ELBO over a Gaussian q; opt-in, steadier on dispersion/shape — #136).
"""
abstract type MarginalMethod end

"""    Laplace <: MarginalMethod

Laplace marginal: Gaussian approximation at the posterior mode. The default."""
struct Laplace <: MarginalMethod end

"""    Variational <: MarginalMethod

Gaussian-variational (VA/ELBO) marginal — opt-in alternative to [`Laplace`](@ref)
for bias-sensitive random-effect models (#136). Not yet implemented."""
struct Variational <: MarginalMethod end

# Resolve a user-facing `method` symbol (:LA/:VA, case-insensitive) to a type.
_marginal_method(m::MarginalMethod) = m
function _marginal_method(s::Symbol)
    t = Symbol(uppercase(String(s)))
    t === :LA && return Laplace()
    t === :VA && return Variational()
    throw(ArgumentError("unknown marginal method `:$s`; use :LA (Laplace, default) or :VA (variational, #136)"))
end

# Generic stub entry point. The VA marginal is implemented only for the one
# tractable proof case below (Poisson random intercept, #136 Phase 2); every other
# family still errors clearly rather than silently falling back, so opt-in callers
# know the state.
function _fit_va(args...; kwargs...)
    error("The variational (VA/ELBO) marginal is implemented only for the Poisson " *
          "random-intercept case so far (`_fit_poisson_ranef_va`); other families are " *
          "not yet wired — see https://github.com/itchyshin/DRM.jl/issues/136. " *
          "Use method = :LA (Laplace, the default).")
end

# ──────────────────────────────────────────────────────────────────────────────
# Phase-2 proof kernel: closed-form mean-field Gaussian VA for the Poisson
# random-intercept model (#136 §4.1–4.4 of the design note). Self-contained and
# fully ForwardDiff-differentiable; opt-in, never the default. The verified
# Laplace/GHQ baseline (`_fit_poisson_ranef`) is untouched.
#
# Model: log λ_i = η0_i + b_{g(i)},  b_g ~ N(0, σ²),  σ² = exp(2·logσ).
# Mean-field q(b_g) = N(m_g, s_g). With the Poisson MGF E_q[e^{b}] = e^{m+s/2}:
#
#   E_q[log p(y_i|η_i)] = y_i·(η0_i + m_g) − exp(η0_i + m_g + s_g/2) − log y_i!
#   KL(N(m_g,s_g)‖N(0,σ²)) = ½[ s_g/σ² + m_g²/σ² − 1 − log(s_g/σ²) ]
#   ELBO = Σ_g [ Σ_{i∈g} E_q[log p] − KL_g ]      (a lower bound on log p(y|θ))
#
# We minimise nll = −ELBO. Per outer θ, the inner (m_g, s_g) are profiled to the
# ELBO maximiser. Because q is mean-field and groups are disjoint, the inner
# problem factorises per group into a 2-D strictly-concave solve (concave in
# (m, log s)); a fixed, short Newton unroll converges to machine precision and
# keeps the objective a smooth function of θ for the outer AD.
# ──────────────────────────────────────────────────────────────────────────────

# Inner per-group solve. Given the group totals A = Σ y_i and S = Σ e^{η0_i}, and
# the prior precision τ = 1/σ², return the ELBO-stationary (m, s). Differentiable
# in (A, S, τ): the iterates are carried in the working eltype, so ForwardDiff
# propagates through the unrolled Newton steps. Stationarity equations (§4.4):
#   m: A − e^{m+s/2}·S − τ·m = 0
#   s: 1/s − τ − e^{m+s/2}·S = 0          (parameterised in r = log s)
function _poisson_va_inner(A::T, S::T, τ::T; iters::Int = 25) where {T}
    # Warm start: prior-shrunk MAP-ish mean, modest variance.
    m = log((A + one(T)) / (S + one(T)))            # ≈ log of the per-member rate
    r = log(one(T) / (τ + S + one(T)))              # r = log s; s ≈ 1/(τ + curvature)
    for _ in 1:iters
        s = exp(r)
        E = exp(m + s / 2) * S                      # = e^{m+s/2}·S ≥ 0
        # Gradient of the per-group ELBO in (m, r=log s):
        gm = A - E - τ * m
        gr = (one(T) / s - τ - E) * (s / 2)         # ∂ELBO/∂r = ∂ELBO/∂s · s
        # Hessian in (m, r). With ∂E/∂m = E, ∂E/∂s = E/2 ⇒ ∂E/∂r = (E/2)·s:
        Hmm = -E - τ
        Hmr = -(E / 2) * s
        # ∂gr/∂r = s·[ (-1/s² - E/2)·s ] + gr   (product rule through r); assemble directly:
        Hrr = (-(one(T) / s) - (E / 2) * s) * (s / 2) + gr  # d/dr of gr
        # Newton step (2×2 solve); damp if the Hessian is near-singular.
        det = Hmm * Hrr - Hmr * Hmr
        det = abs(det) < eps(T) ? (det ≥ 0 ? eps(T) : -eps(T)) : det
        Δm = -(Hrr * gm - Hmr * gr) / det
        Δr = -(-Hmr * gm + Hmm * gr) / det
        # Step-limit r to keep s in a sane range (anti-overflow on e^{m+s/2}).
        Δr = clamp(Δr, -2.0, 2.0)
        m += Δm
        r += Δr
    end
    return m, exp(r)
end

# Closed-form Poisson random-intercept VA fit. Same call shape as
# `_fit_poisson_ranef`; returns a `DrmFit` whose `loglik` field carries the
# **ELBO** (a lower bound), not the exact marginal log-likelihood.
function _fit_poisson_ranef_va(fam::Poisson, y, Xμ, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    A = [sum(y[idx]; init = 0.0) for idx in members]    # Σ y_i per group (θ-free)
    lfsum = sum(lf)                                       # Σ log y_i!  (θ-free constant)

    # nll(θ) = −ELBO(θ, m*(θ), s*(θ)), with the inner (m,s) profiled per group.
    function nll(θ)
        βμ = θ[1:pμ]; logσ = θ[pμ+1]
        σ2 = exp(2 * logσ); τ = one(eltype(θ)) / σ2
        η0 = Xμ * βμ
        eη0 = exp.(η0)
        elbo = zero(eltype(θ))
        for (g, idx) in enumerate(members)
            isempty(idx) && continue
            S = sum(@view eη0[idx])                       # Σ e^{η0_i} in group g
            Ag = convert(eltype(θ), A[g])
            m, s = _poisson_va_inner(Ag, S, τ)
            # E_q[Σ log p] = Σ y_i·η0_i + A_g·m − e^{m+s/2}·S − (Σ log y_i! handled globally)
            yη0 = sum(y[i] * η0[i] for i in idx)
            Eqlp = yη0 + Ag * m - exp(m + s / 2) * S
            # KL(N(m,s)‖N(0,σ²)) = ½[ s·τ + m²·τ − 1 − log(s·τ) ]
            kl = 0.5 * (s * τ + m^2 * τ - one(eltype(θ)) - log(s * τ))
            elbo += Eqlp - kl
        end
        return -(elbo - lfsum)
    end

    θ0 = zeros(pμ + 1)
    θ0[1] = log(sum(y) / n + eps())
    θ0[pμ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    # loglik field carries the ELBO (a lower bound); label downstream as :VA.
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
