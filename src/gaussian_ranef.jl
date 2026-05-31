# gaussian_ranef.jl — ordinary Gaussian random *intercepts* on the mean.
#
# For a mean random effect the marginal is exactly Gaussian:
#     y ~ N(Xβ, V),  V = D + σ_b² Z Zᵀ,  D = diag(σ_i²)
# where Z is the group-indicator. We never form V: the matrix-determinant lemma
# and the Woodbury identity reduce everything to O(n) accumulations plus a
# diagonal G×G capacitance (one random-intercept term), all ForwardDiff-friendly.

# Split a μ right-hand side into its fixed part and any `(lhs | g)` terms.
function _split_ranef(rhs)
    terms = rhs isa Tuple ? collect(rhs) : Any[rhs]
    fixed = Any[]
    re = Tuple{Any,Symbol}[]
    metav = nothing                                   # meta_V(v) known-variance column
    structured = nothing                              # (:relmat, grouping) — known K
    for t in terms
        if t isa FunctionTerm && t.f === (|)
            push!(re, (t.args[1], t.args[2].sym))     # (re-lhs, grouping symbol)
        elseif t isa FunctionTerm && t.f === meta_V
            metav = t.args[1].sym
        elseif t isa FunctionTerm && t.f === relmat
            structured = (:relmat, t.args[1].args[2].sym)   # inner (1 | grp)
        elseif t isa FunctionTerm && t.f === animal
            structured = (:animal, t.args[1].args[2].sym)
        elseif t isa FunctionTerm && t.f === phylo
            structured = (:phylo, t.args[1].args[2].sym)
        elseif t isa FunctionTerm && t.f === spatial
            structured = (:spatial, t.args[1].args[2].sym)
        else
            push!(fixed, t)
        end
    end
    fixed_rhs = isempty(fixed) ? ConstantTerm(1) :
                length(fixed) == 1 ? fixed[1] : Tuple(fixed)
    return fixed_rhs, re, metav, structured
end

# Per-observation random-effect design weight from the term's lhs:
# `(1 | g)` → wᵢ = 1 (random intercept); `(0 + x | g)` → wᵢ = xᵢ (independent
# random slope). Correlated `(1 + x | g)` is planned.
function _re_kind(re_lhs)
    if re_lhs isa ConstantTerm
        re_lhs.n == 1 || error("random-effect intercept term must be `1`")
        return (:intercept, nothing)
    elseif re_lhs isa FunctionTerm && re_lhs.f === (+)
        consts = filter(t -> t isa ConstantTerm, re_lhs.args)
        vars = filter(t -> t isa Term, re_lhs.args)
        length(vars) == 1 || error("DRM.jl supports `(1 | g)`, `(0 + x | g)`, `(1 + x | g)`")
        v = vars[1].sym
        any(c -> c.n == 0, consts) && return (:slope, v)      # 0 + x  → slope only
        any(c -> c.n == 1, consts) && return (:corr, v)       # 1 + x  → correlated intercept+slope
    end
    error("unsupported random-effect term: `($re_lhs | …)`")
end

# Map group labels to 1:G (stable first-seen order), O(n).
function _group_index(labels)
    lvl = Dict{eltype(labels),Int}()
    gidx = Vector{Int}(undef, length(labels))
    for (i, l) in enumerate(labels)
        gidx[i] = get!(lvl, l, length(lvl) + 1)
    end
    return gidx, length(lvl)
end

# Gaussian location–scale with one random intercept (1 | g) on the mean.
# θ = [β_μ; β_σ (log σ); log σ_b].
function _fit_ranef_gaussian(fam::Gaussian, y, Xμ, Xσ, gidx, G, w, nmμ, nmσ, grp, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)

    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; lσb = θ[pμ+pσ+1]
        ημ = Xμ * βμ; ησ = Xσ * βσ                 # ησ = log σ_i
        σb² = exp(2lσb)
        T = eltype(θ)
        S = zeros(T, G); C = zeros(T, G)           # S_k = Σ 1/D_i,  C_k = Σ r_i/D_i
        q1 = zero(T); logdetD = zero(T)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i])
            r = y[i] - ημ[i]
            a = r * invD
            k = gidx[i]
            wi = w[i]
            S[k] += wi * wi * invD                 # (ZᵀD⁻¹Z)_kk = Σ w_i²/D_i
            C[k] += wi * a                         # (ZᵀD⁻¹r)_k  = Σ w_i r_i/D_i
            q1 += r * a                            # rᵀD⁻¹r
            logdetD += 2 * ησ[i]                   # log D_i
        end
        q2 = zero(T); logdetCap = zero(T)
        @inbounds for k in 1:G
            Mk = 1 / σb² + S[k]                     # Woodbury capacitance (diagonal)
            q2 += C[k]^2 / Mk
            logdetCap += log(1 + σb² * S[k])        # det-lemma term
        end
        quad = q1 - q2
        logdetV = logdetD + logdetCap
        return 0.5 * (logdetV + quad) + 0.5 * n * log(2π)
    end

    βμ0 = Xμ \ y
    res0 = y - Xμ * βμ0
    θ0 = zeros(pμ + pσ + 1)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(res0) + eps())
    θ0[pμ+pσ+1] = log(std(res0) / 2 + eps())

    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))

    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))   # residual σ (RE excluded)
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales)
end

# Correlated random intercept+slope (1 + x | g): per group (b0,b1) ~ N(0, Σ_re),
# Σ_re a 2×2 covariance (log-Cholesky parameters a, b, c). Groups are disjoint, so
# the Woodbury capacitance is block-diagonal in 2×2 blocks → O(G), explicit 2×2
# inverse/solve/det (ForwardDiff-friendly). θ = [β_μ; β_σ; a, b, c].
function _fit_correlated_ranef_gaussian(fam::Gaussian, y, Xμ, Xσ, gidx, G, xs, nmμ, nmσ, grp, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        a = θ[pμ+pσ+1]; b = θ[pμ+pσ+2]; cc = θ[pμ+pσ+3]
        ημ = Xμ * βμ; ησ = Xσ * βσ
        T = eltype(θ)
        l11 = exp(a); l22 = exp(b)                 # L = [l11 0; cc l22], Σ_re = L Lᵀ
        Σ11 = l11^2; Σ21 = cc * l11; Σ22 = cc^2 + l22^2
        detΣ = Σ11 * Σ22 - Σ21^2
        Si11 = Σ22 / detΣ; Si22 = Σ11 / detΣ; Si21 = -Σ21 / detΣ
        logdetΣre = log(detΣ)
        b11 = zeros(T, G); b21 = zeros(T, G); b22 = zeros(T, G)
        c1 = zeros(T, G); c2 = zeros(T, G)
        q1 = zero(T); logdetD = zero(T)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i]); r = y[i] - ημ[i]; w = xs[i]; k = gidx[i]
            b11[k] += invD; b21[k] += w * invD; b22[k] += w * w * invD
            ri = r * invD; c1[k] += ri; c2[k] += w * ri
            q1 += r * ri; logdetD += 2 * ησ[i]
        end
        quad = q1; logdetM = zero(T)
        @inbounds for k in 1:G
            m11 = Si11 + b11[k]; m21 = Si21 + b21[k]; m22 = Si22 + b22[k]
            dM = m11 * m22 - m21^2
            u1 = (m22 * c1[k] - m21 * c2[k]) / dM      # M_k⁻¹ c_k
            u2 = (-m21 * c1[k] + m11 * c2[k]) / dM
            quad -= c1[k] * u1 + c2[k] * u2
            logdetM += log(dM)
        end
        logdetV = logdetD + G * logdetΣre + logdetM
        return 0.5 * (logdetV + quad) + 0.5 * n * log(2π)
    end
    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    θ0 = zeros(pμ + pσ + 3)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(res0) + eps())
    sd0 = log(std(res0) / 2 + eps())
    θ0[pμ+pσ+1] = sd0; θ0[pμ+pσ+2] = sd0; θ0[pμ+pσ+3] = 0.0
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :recov => (pμ+pσ+1):(pμ+pσ+3)]
    names = [:mu => nmμ, :sigma => nmσ, :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]]
    means = Dict(:mu => Xμ * θ̂[1:pμ]); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales)
end

"""
    vc(fit) -> Dict{Symbol,Matrix{Float64}}

Random-effect covariance matrix per grouping factor, for correlated
random-effect blocks (`(1 + x | g)`). `sqrt.(diag(vc(fit)[:g]))` are the
intercept/slope SDs; the off-diagonal gives their covariance.
"""
function vc(fit::DrmFit)
    d = Dict{Symbol,Matrix{Float64}}()
    for (p, r) in fit.blocks
        p === :recov || continue
        a, b, cc = fit.theta[r]
        l11 = exp(a); l22 = exp(b)
        Σ = [l11^2 cc*l11; cc*l11 cc^2+l22^2]
        nm = first(cn[2] for cn in fit.coefnames if cn[1] === :recov)[1]   # "g:L11"
        d[Symbol(split(nm, ":")[1])] = Σ
    end
    return d
end

# Multiple independent scalar random-effect components (e.g. (1|g) + (1|h)).
# comps :: Vector of (w, gidx, Gk, label). Marginal V = D + Σ_k σ_k² Z_k Z_kᵀ.
# Whitened Woodbury: fold σ into a scaled design Z̃ = Z·diag(σ_per_col), giving a
# small q×q (q = Σ G_k) capacitance M = I + Z̃ᵀD⁻¹Z̃ (the logdet(G) term is
# absorbed into logdet(M)). In exact arithmetic M is identity-plus-PSD hence PD,
# but at extreme σ the I is lost to rounding (M's entries ≫ 1) and the raw
# Z̃ᵀD⁻¹Z̃ is rank-deficient (crossed intercept columns), so we factor with
# check=false and return a finite penalty on failure — the optimiser's line
# search then retreats from those ill-scaled probes. Closed-form GLS; Z precomputed.
function _fit_multi_ranef_gaussian(fam::Gaussian, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    K = length(comps)
    Gks = [c[3] for c in comps]
    q = sum(Gks)
    offs = cumsum([0; Gks])
    Z = zeros(n, q)
    colcomp = Vector{Int}(undef, q)
    for (k, (w, gidx, Gk, _)) in enumerate(comps)
        for c in 1:Gk
            colcomp[offs[k]+c] = k
        end
        @inbounds for i in 1:n
            Z[i, offs[k]+gidx[i]] = w[i]
        end
    end
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = Xμ * βμ
        ησ = clamp.(Xσ * βσ, -30.0, 30.0)          # bound σ predictor: keep exp finite
        invD = exp.(-2 .* ησ); r = y .- ημ
        σk = [exp(clamp(θ[pμ+pσ+k], -30.0, 30.0)) for k in 1:K]
        σcol = [σk[colcomp[c]] for c in 1:q]
        Z̃ = Z .* σcol'                             # scale each column by its σ_k
        ZtDir = Z̃' * (invD .* r)
        M = Z̃' * (invD .* Z̃)
        C = cholesky(Symmetric(M + I); check = false)  # check=false → never throws
        issuccess(C) || return oftype(sum(θ), 1e18)    # retreat from ill-scaled probes
        quad = sum(r .^ 2 .* invD) - dot(ZtDir, C \ ZtDir)
        logdetV = sum(2 .* ησ) + logdet(C)
        return 0.5 * (logdetV + quad) + 0.5 * n * log(2π)
    end
    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    s0 = std(res0) / sqrt(K + 1)                   # balanced variance split: resid + K REs
    θ0 = zeros(pμ + pσ + K)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(s0 + eps())
    for k in 1:K
        θ0[pμ+pσ+k] = log(s0 + eps())
    end
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+K)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [c[4] for c in comps]]
    means = Dict(:mu => Xμ * θ̂[1:pμ]); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales)
end
