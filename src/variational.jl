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

# Generic stub entry point. The VA marginal is implemented for the tractable proof
# cases below (Poisson and Binomial/Bernoulli random intercept, #136 Phase 2);
# every other family still errors clearly rather than silently falling back, so
# opt-in callers know the state.
function _fit_va(args...; kwargs...)
    error("The variational (VA/ELBO) marginal is implemented only for the Poisson " *
          "(`_fit_poisson_ranef_va`) and Binomial/Bernoulli (`_fit_binomial_ranef_va`) " *
          "random-intercept cases so far; other families are not yet wired — see " *
          "https://github.com/itchyshin/DRM.jl/issues/136. Use method = :LA (Laplace, the default).")
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

# ──────────────────────────────────────────────────────────────────────────────
# Phase-2 proof kernel: mean-field Gaussian VA for the Binomial/Bernoulli
# random-intercept (logistic GLMM) model (#136). Unlike Poisson, the logit link
# gives a logistic-normal latent integral with **no** closed-form E_q[log p]; we
# evaluate the per-group E_q[log-lik] by a small Gauss–Hermite quadrature over the
# Gaussian q. The objective is otherwise identical in shape to the Poisson VA:
# a mean-field Gaussian q per group, profiled inner (m_g, s_g), and the Gaussian–
# Gaussian KL. Fully ForwardDiff-differentiable; opt-in, never the default. The
# verified Laplace/GHQ baseline (`_fit_binomial_ranef`) is untouched.
#
# Model: logit μ_i = η0_i + b_{g(i)},  b_g ~ N(0, σ²),  σ² = exp(2·logσ),
#        s_i ~ Binomial(n_i, μ_i).
# Mean-field q(b_g) = N(m_g, s_g). Writing the b-dependent log-likelihood kernel
#   ℓ_i(b) = s_i·(η0_i + b) − n_i·log(1 + e^{η0_i + b})           (logit Binomial)
# (the log C(n_i,s_i) coefficient is b- and θ-free → a global constant), then with
# the substitution b = m + √(2s)·z_k (z_k, w_k the K-node Gauss–Hermite rule):
#   E_q[Σ_{i∈g} ℓ_i] ≈ Σ_k (w_k/√π) · Σ_{i∈g} ℓ_i(m + √(2s)·z_k)
#   KL(N(m,s)‖N(0,σ²)) = ½[ s/σ² + m²/σ² − 1 − log(s/σ²) ]
#   group ELBO  F_g(m,r) = E_q[Σℓ] − KL,     r = log s
#   ELBO = Σ_g F_g + Σ_i log C(n_i, s_i)     (a lower bound on log p(y|θ))
#
# We minimise nll = −ELBO. Per outer θ, the inner (m_g, r_g) are profiled to the
# ELBO maximiser by a short Newton unroll; because q is mean-field and groups are
# disjoint the inner problem factorises per group into a smooth 2-D concave solve.
# The inner gradient/Hessian of F_g in (m, r) are taken by ForwardDiff (nodes are
# constants, so the GHQ sum is smooth); carrying the iterates in the working
# eltype lets the outer ForwardDiff propagate through the unrolled steps.
# ──────────────────────────────────────────────────────────────────────────────

# b-dependent logit-Binomial log-likelihood kernel summed over a group, as a
# function of the latent value b (the binomial coefficient is dropped — it is a
# b-free, θ-free constant handled globally). η0idx/sidx/nidx are the group's
# linear predictors, successes and trials. Differentiable in b and η0.
function _binom_group_kernel(b, η0idx, sidx, nidx)
    v = zero(promote_type(typeof(b), eltype(η0idx)))
    @inbounds for j in eachindex(η0idx)
        η = η0idx[j] + b
        # log(1 + e^η) via a numerically-stable softplus (avoids overflow for η≫0).
        sp = η > zero(η) ? η + log1p(exp(-η)) : log1p(exp(η))
        v += sidx[j] * η - nidx[j] * sp
    end
    return v
end

# Per-group GHQ ELBO F(m, r) = E_q[Σ ℓ] − KL, with q = N(m, s), s = e^r and the
# prior precision τ = 1/σ². `z` are the Gauss–Hermite nodes, `lwπ = log(w) −
# ½·log π` the log weights. Smooth in (m, r); used both for the inner solve and
# (at the optimum) the reported value.
function _binom_va_group_elbo(m, r, η0idx, sidx, nidx, τ, z, lwπ)
    s = exp(r)
    sd = sqrt(2 * s)                                   # √(2s): b = m + √(2s)·z_k
    Eqℓ = zero(promote_type(typeof(m), typeof(r)))
    @inbounds for k in eachindex(z)
        Eqℓ += exp(lwπ[k]) * _binom_group_kernel(m + sd * z[k], η0idx, sidx, nidx)
    end
    kl = 0.5 * (s * τ + m * m * τ - one(m) - log(s * τ))
    return Eqℓ - kl
end

# Inner per-group solve: maximise F(m, r) over (m, r) by a short Newton unroll.
# Gradient and Hessian in the 2-vector (m, r) come from ForwardDiff of the group
# ELBO closure (nodes are constants ⇒ smooth). Iterates carry the working eltype,
# so the outer ForwardDiff differentiates through the converged (m*, s*). Returns
# (m, s). `z`, `lwπ` are the Gauss–Hermite nodes and log w − ½ log π arrays.
function _binom_va_inner(η0idx, sidx, nidx, τ::T, z, lwπ; iters::Int = 30) where {T}
    p̄ = clamp(sum(sidx) / max(sum(nidx), one(T)), T(1e-3), one(T) - T(1e-3))
    # Warm start: a prior-shrunk logit of the group success rate, modest variance.
    m = log(p̄ / (one(T) - p̄))
    r = log(one(T) / (τ + one(T)))                    # s ≈ 1/(τ + 1): small spread
    obj = u -> _binom_va_group_elbo(u[1], u[2], η0idx, sidx, nidx, τ, z, lwπ)
    for _ in 1:iters
        u = [m, r]
        g = ForwardDiff.gradient(obj, u)
        H = ForwardDiff.hessian(obj, u)               # ∇²F (concave ⇒ H ≺ 0)
        det = H[1, 1] * H[2, 2] - H[1, 2] * H[2, 1]
        det = abs(det) < eps(T) ? (det ≥ 0 ? eps(T) : -eps(T)) : det
        Δm = -(H[2, 2] * g[1] - H[1, 2] * g[2]) / det
        Δr = -(-H[2, 1] * g[1] + H[1, 1] * g[2]) / det
        Δr = clamp(Δr, T(-2.0), T(2.0))               # keep s in a sane range
        m += Δm
        r += Δr
    end
    return m, exp(r)
end

# Mean-field Gaussian VA fit for the Binomial/Bernoulli random-intercept model.
# Same call shape as `_fit_binomial_ranef`; `loglik` carries the **ELBO** (a lower
# bound), not the exact marginal log-likelihood. θ = [β_μ; log σ_b].
function _fit_binomial_ranef_va(fam::Binomial, s, ntr, Xμ, gidx, G, nmμ, grp, g_tol)
    n = length(s); pμ = size(Xμ, 2)
    sint = round.(Int, s); nint = round.(Int, ntr)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    # GHQ node arrays (12 nodes: q is Gaussian so the quadrature is exact for the
    # latent integral up to high order; cheap and ample for a 1-D effect).
    z, w = _gauss_hermite(12)
    lwπ = log.(w) .- 0.5 * log(π)                      # log w − ½ log π
    # log C(n_i, s_i): b- and θ-free constant, summed once.
    lcoef = sum(_logfactorial(nint[i]) - _logfactorial(sint[i]) - _logfactorial(nint[i] - sint[i]) for i in 1:n)

    function nll(θ)
        βμ = θ[1:pμ]; logσ = θ[pμ+1]
        σ2 = exp(2 * logσ); τ = one(eltype(θ)) / σ2
        η0 = Xμ * βμ
        elbo = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            η0idx = @view η0[idx]
            sidx = @view sint[idx]
            nidx = @view nint[idx]
            m, sg = _binom_va_inner(η0idx, sidx, nidx, τ, z, lwπ)
            elbo += _binom_va_group_elbo(m, log(sg), η0idx, sidx, nidx, τ, z, lwπ)
        end
        return -(elbo + lcoef)
    end

    p̄ = clamp(sum(s) / max(sum(ntr), 1), 1e-3, 1 - 1e-3)
    θ0 = zeros(pμ + 1)
    θ0[1] = log(p̄ / (1 - p̄)); θ0[pμ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => _logistic.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => s ./ ntr)   # population μ (b=0)
    scales = Dict(:trials => Float64.(nint))
    # loglik field carries the ELBO (a lower bound); label downstream as :VA.
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
