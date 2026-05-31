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
function _re_weights(re_lhs, data, n)
    if re_lhs isa ConstantTerm
        re_lhs.n == 1 || error("random-effect intercept term must be `1`")
        return ones(n)
    elseif re_lhs isa FunctionTerm && re_lhs.f === (+)
        consts = filter(t -> t isa ConstantTerm, re_lhs.args)
        vars = filter(t -> t isa Term, re_lhs.args)
        if any(c -> c.n == 0, consts) && length(vars) == 1
            return Float64.(getproperty(data, vars[1].sym))
        end
        error("DRM.jl (current slice) supports `(1 | g)` or `(0 + x | g)`; correlated `(1 + x | g)` is planned")
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
