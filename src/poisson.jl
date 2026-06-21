# poisson.jl — Poisson family for count responses. Log link on the mean
# (λ = exp(Xμβ)); no dispersion parameter (see the negative-binomial family for
# overdispersed counts). Fixed effects, maximum likelihood. Mirrors drmTMB's
# `poisson`. The log-pmf is written out explicitly (y·log λ − λ − log y!) so the
# fit needs no `Distributions.Poisson` — that name is left to Distributions.

"""
    Poisson()

Poisson response family for counts: log link on the mean `μ` (so `μ` coefficients
act on `log λ`). No scale parameter. Mirrors `drmTMB`'s `poisson` family.

!!! note
    `DRM.Poisson` shadows `Distributions.Poisson`; if you need the distribution
    too (e.g. to simulate), qualify it as `Distributions.Poisson`.

```julia
fit = drm(bf(y ~ x), Poisson(); data = dat)
fitted(fit)        # fitted counts λ = exp(Xβ̂), on the response scale

fit_phy = drm(bf(@formula(y ~ x + phylo(1 | species))), Poisson();
              data = dat, tree = tr, se = false)
```
"""
struct Poisson end

_logfactorial(k::Integer) = sum(log, 2:k; init = 0.0)   # log k!  (0 for k = 0, 1)

function drm(f::DrmFormula, fam::Poisson; data, tree = nothing, K = nothing,
             A = nothing, coords = nothing, g_tol::Real = 1e-8, se::Bool = true,
             method::Symbol = :LA)
    missing_fit = _fit_observed_response_rows(f, data) do data_observed
        drm(f, fam; data = data_observed, tree = tree, K = K, A = A,
            coords = coords, g_tol = g_tol, se = se, method = method)
    end
    missing_fit !== nothing && return missing_fit

    marg = _marginal_method(method)                       # :LA (default) or :VA (#136)
    isva = marg isa Variational
    rhs = Dict(f.forms)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    mv === nothing ||
        error("Poisson() does not support meta_V markers")
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    all(yi -> yi ≥ 0 && isinteger(yi), y) ||
        error("Poisson() requires non-negative integer counts as the response")
    if st !== nothing
        isva && _va_reject(fam, "a phylogenetic/structured random effect")
        isempty(re) ||
            error("Poisson() structured effects cannot be combined with ordinary random effects yet")
        (haskey(rhs, :zi) || haskey(rhs, :hu)) &&
            error("Poisson() structured effects cannot be combined with `zi`/`hu` yet")
        kind, grp = st
        labels = getproperty(data, grp)
        if kind === :phylo
            tree === nothing && error("phylo(1 | $grp) needs `tree = …`")
            return _withformula(_fit_poisson_phylo_laplace(fam, y, Xμ, labels, tree, nmμ, grp, g_tol; se = se), f)
        elseif kind === :spatial && K === nothing && coords !== nothing
            # Coordinate-based exponential-kernel spatial covariance with the range
            # ρ ESTIMATED JOINTLY (#270): C(ρ) = exp(-d/ρ) from the site distances,
            # ρ enters the outer parameter vector, and its gradient flows through
            # C(ρ) → Q(ρ) → the Laplace marginal. The coordinate-spatial twin of the
            # Gaussian `_fit_spatial_gaussian` path, on the Poisson Laplace spine.
            return _withformula(_fit_poisson_spatial_coord(fam, y, Xμ, labels, coords, nmμ, grp, g_tol; se = se), f)
        elseif kind === :relmat || kind === :animal || kind === :spatial
            # General user-supplied PD covariance C on the mean intercept
            # (relatedness / animal model / PRECOMPUTED spatial). Reuses the phylo
            # sparse-Laplace spine with the tree precision swapped for C⁻¹ (#167).
            C = _poisson_structured_cov(kind, grp, K, A, coords)
            return _withformula(_fit_poisson_relmat_laplace(fam, y, Xμ, C, labels, nmμ, grp, g_tol; se = se), f)
        else
            error("Poisson() supports phylo/relmat/animal/spatial(1 | group) among structured markers")
        end
    end
    if !isempty(re)                                       # random intercept (1|g) → GHQ marginal
        (haskey(rhs, :zi) || haskey(rhs, :hu)) &&
            error("Poisson() random effects cannot be combined with `zi`/`hu` yet")
        if length(re) > 1                                 # (1|g)+(1|h)+… crossed/multiple intercepts → sparse Laplace
            isva && _va_reject(fam, "crossed/multiple random intercepts")
            all(_re_kind(r[1])[1] === :intercept for r in re) ||
                error("Poisson() supports multiple random effects only as crossed/nested intercepts, e.g. `(1 | g) + (1 | h)`")
            comps = map(re) do r
                grp = r[2]; gidx, G = _group_index(getproperty(data, grp))
                (ones(length(y)), gidx, G, String(grp))
            end
            return _withformula(_fit_poisson_crossed_laplace(fam, y, Xμ, comps, nmμ, g_tol; se = se), f)
        end
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]; gidx, G = _group_index(getproperty(data, grp))
        if rk === :intercept                              # (1 | g) → 1-D GHQ (Laplace) or VA (#136)
            isva && return _withformula(_fit_poisson_ranef_va(fam, y, Xμ, gidx, G, nmμ, grp, g_tol), f)
            return _withformula(_fit_poisson_ranef(fam, y, Xμ, gidx, G, nmμ, grp, g_tol), f)
        elseif rk === :corr                               # (1 + x | g) → 2-D GHQ
            isva && _va_reject(fam, "a correlated random slope `(1 + x | g)`")
            xs = Float64.(getproperty(data, var))
            return _withformula(_fit_poisson_corr_ranef(fam, y, Xμ, xs, gidx, G, nmμ, grp, g_tol), f)
        else
            error("Poisson() supports `(1 | g)` or `(1 + x | g)` random effects on the mean")
        end
    end
    isva && _va_reject(fam, "no random intercept (fixed-effects-only / zi / hu)")
    haskey(rhs, :zi) && haskey(rhs, :hu) &&
        error("`zi` and `hu` cannot both be specified (zero-inflation vs hurdle)")
    if haskey(rhs, :zi)                                   # zero-inflated Poisson
        _, Xzi, nmzi = _design(f.response, rhs[:zi], data)
        return _withformula(_fit_poisson_zi(fam, y, Xμ, Xzi, nmμ, nmzi, g_tol), f)
    end
    if haskey(rhs, :hu)                                   # hurdle Poisson
        _, Xhu, nmhu = _design(f.response, rhs[:hu], data)
        return _withformula(_fit_poisson_hu(fam, y, Xμ, Xhu, nmμ, nmhu, g_tol), f)
    end
    return _withformula(_fit_poisson(fam, y, Xμ, nmμ, g_tol), f)
end

# Resolve a structured marker (relmat/animal/spatial) for a count family to its
# user-supplied G×G PD covariance from the keyword args. `relmat`/`animal` take
# the matrix directly (`K`/`A`); `spatial` accepts a precomputed covariance via
# `K`, or — handled upstream in `drm(...)` before this is reached — site `coords`
# for coordinate-based joint range estimation (#270). Reaching the `:spatial`
# branch here means neither was supplied. Mirrors `_resolve_structured_matrix`
# (gaussian_structured.jl) but for the count Laplace route.
function _poisson_structured_cov(kind::Symbol, grp::Symbol, K, A, coords)
    if kind === :relmat
        K === nothing && error("relmat(1 | $grp) needs `K = …` (the relatedness/covariance matrix)")
        return Matrix{Float64}(K)
    elseif kind === :animal
        A === nothing && error("animal(1 | $grp) needs the relatedness matrix `A = …`")
        return Matrix{Float64}(A)
    else  # :spatial
        K !== nothing && return Matrix{Float64}(K)
        error("spatial(1 | $grp) for counts needs either a precomputed spatial covariance " *
              "via `K = …`, or site `coords = …` (a G×2 coordinate matrix) for coordinate-based " *
              "exponential-kernel covariance with the range estimated jointly")
    end
end

# Poisson count GLMM with a random intercept (1|g) on log λ. b_g ~ N(0,σ_b²) is
# integrated out per group by K-node Gauss–Hermite quadrature (b = √2 σ_b z), the
# same scheme as the Gaussian σ-RE. O(n·K) per evaluation, fully differentiable.
function _fit_poisson_ranef(fam::Poisson, y, Xμ, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    z, w = _gauss_hermite(32); logw = log.(w); K = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; σb = exp(θ[pμ+1])
        η0 = Xμ * βμ
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K)
            for k in 1:K
                δ = rt2 * σb * z[k]
                gll = logw[k]
                for i in idx
                    η = η0[i] + δ
                    gll += y[i] * η - exp(η) - lf[i]      # log Poisson(y_i; e^η)
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    θ0 = zeros(pμ + 1)
    θ0[1] = log(sum(y) / n + eps())
    θ0[pμ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))   # population λ (b=0)
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Poisson count GLMM with a correlated random intercept+slope (1 + x | g) on log λ.
# Per group (b0,b1) ~ N(0, Σ); because groups are disjoint the 2-D integral
# factorises, so it is done by a 2-D Gauss–Hermite tensor grid (K² nodes). Σ is the
# log-Cholesky parameterisation L = [exp(a) 0; cc exp(b)] (the `vc` convention), so
# vc(fit) reconstructs Σ = L Lᵀ. O(G·K²·group) per eval, fully differentiable.
function _fit_poisson_corr_ranef(fam::Poisson, y, Xμ, xs, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    z1, w1 = _gauss_hermite(12); lw = log.(w1); K = length(z1); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; a = θ[pμ+1]; b = θ[pμ+2]; cc = θ[pμ+3]
        l11 = exp(a); l22 = exp(b); η0 = Xμ * βμ
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K * K)
            t = 0
            for j in 1:K, k in 1:K
                t += 1
                b0 = rt2 * l11 * z1[j]; b1 = rt2 * (cc * z1[j] + l22 * z1[k])   # √2 L z
                gll = lw[j] + lw[k]
                for i in idx
                    η = clamp(η0[i] + b0 + b1 * xs[i], -30.0, 30.0)
                    gll += y[i] * η - exp(η) - lf[i]
                end
                terms[t] = gll
            end
            mx = maximum(terms)
            s -= (-lπ + mx + log(sum(exp.(terms .- mx))))      # 2-D: -0.5·2·logπ = -logπ
        end
        return s
    end
    θ0 = zeros(pμ + 3)
    θ0[1] = log(sum(y) / n + eps())
    θ0[pμ+1] = log(0.4); θ0[pμ+2] = log(0.4); θ0[pμ+3] = 0.0
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :recov => (pμ+1):(pμ+3)]
    names = [:mu => nmμ, :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# log-logistic helpers (stable): log π and log(1-π) for π = logistic(η).
_log_logistic(η) = -log1p(exp(-η))
_log1m_logistic(η) = -log1p(exp(η))
# log(exp(a) + exp(b)), numerically stable.
_logaddexp(a, b) = (m = max(a, b); m + log1p(exp(-abs(a - b))))
# log(1 - exp(x)) for x ≤ 0, numerically stable (hurdle zero-truncation term).
_log1mexp(x) = x < -log(2) ? log1p(-exp(x)) : log(-expm1(x))

# Zero-inflated Poisson: P(0) = π + (1-π)e^{-λ}, P(k>0) = (1-π)·Poisson(k; λ),
# with π = logistic(Xziᵀβ) (logit link) and λ = exp(Xμᵀβ).
function _fit_poisson_zi(fam::Poisson, y, Xμ, Xzi, nmμ, nmzi, g_tol)
    n = length(y); pμ, pz = size(Xμ, 2), size(Xzi, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    iszero_y = y .== 0
    function nll(θ)
        βμ = θ[1:pμ]; βz = θ[pμ+1:pμ+pz]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0); ηz = clamp.(Xzi * βz, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            λ = exp(ημ[i]); lπ = _log_logistic(ηz[i]); l1mπ = _log1m_logistic(ηz[i])
            if iszero_y[i]
                s -= _logaddexp(lπ, l1mπ - λ)              # log(π + (1-π)e^{-λ})
            else
                s -= l1mπ + (y[i] * ημ[i] - λ - lf[i])
            end
        end
        return s
    end
    pos = y[y.>0]
    θ0 = zeros(pμ + pz)
    θ0[1] = log((isempty(pos) ? sum(y) / n : sum(pos) / length(pos)) + eps())   # λ from non-zeros
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :zi => (pμ+1):(pμ+pz)]
    names = [:mu => nmμ, :zi => nmzi]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:zi => _logistic.(Xzi * θ̂[(pμ+1):(pμ+pz)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Hurdle Poisson: P(0) = π, P(k>0) = (1-π)·Poisson(k; λ)/(1-e^{-λ}) [zero-truncated],
# with π = logistic(Xhuᵀβ) the hurdle (zero) probability and λ = exp(Xμᵀβ). All
# zeros are structural; the positive part is the zero-truncated Poisson.
function _fit_poisson_hu(fam::Poisson, y, Xμ, Xhu, nmμ, nmhu, g_tol)
    n = length(y); pμ, ph = size(Xμ, 2), size(Xhu, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    iszero_y = y .== 0
    function nll(θ)
        βμ = θ[1:pμ]; βh = θ[pμ+1:pμ+ph]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0); ηh = clamp.(Xhu * βh, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            lπ = _log_logistic(ηh[i]); l1mπ = _log1m_logistic(ηh[i])
            if iszero_y[i]
                s -= lπ                                        # log π
            else
                λ = exp(ημ[i])
                lpos = y[i] * ημ[i] - λ - lf[i]                # log Poisson(k; λ)
                s -= l1mπ + lpos - _log1mexp(-λ)               # − log(1 − e^{-λ})
            end
        end
        return s
    end
    pos = y[y.>0]
    θ0 = zeros(pμ + ph)
    θ0[1] = log((isempty(pos) ? sum(y) / n : sum(pos) / length(pos)) + eps())   # λ from non-zeros
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :hu => (pμ+1):(pμ+ph)]
    names = [:mu => nmμ, :hu => nmhu]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:hu => _logistic.(Xhu * θ̂[(pμ+1):(pμ+ph)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

function _fit_poisson(fam::Poisson, y, Xμ, nmμ, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]    # constant log y! offset
    function nll(θ)
        ημ = Xμ * θ                                     # log λ
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            s -= y[i] * ημ[i] - exp(ημ[i]) - lf[i]
        end
        return s
    end
    θ0 = zeros(pμ); θ0[1] = log(sum(y) / n + eps())
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ]; names = [:mu => nmμ]
    means = Dict(:mu => exp.(Xμ * θ̂)); obs = Dict(:mu => Vector{Float64}(y))   # response-scale λ
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# ===========================================================================
# Coordinate-based exponential-kernel spatial covariance for Poisson (#270)
# ===========================================================================
# spatial(1 | site) with site coordinates and the range ρ ESTIMATED JOINTLY.
# The spatial correlation among the G sites is C(ρ) = exp(-d/ρ) (+ jitter) built
# from pairwise site distances; the random intercept is b ~ N(0, σ_b² C(ρ)) on
# log λ. The outer parameter vector is θ = [β_μ; log σ_b; log ρ], so ρ is a true
# hyperparameter: its gradient flows through C(ρ) → the Laplace marginal.
#
# Unlike the verified large-p sparse-Laplace spine (`_fit_poisson_relmat_laplace`,
# which freezes a precomputed precision Q and supplies a hand-derived O(p) gradient
# for θ = [β; log σ_b] only), this path must differentiate the marginal w.r.t. ρ
# as well. It does so the same way every other DRM.jl non-Gaussian family fit does
# (Poisson/NB2/Gamma GHQ paths and the Gaussian coordinate-spatial path
# `_fit_spatial_gaussian`): the marginal NLL is written in AD-traceable operations
# and ForwardDiff supplies the EXACT gradient (and the Hessian for the covariance).
# Because the number of SITES G is the latent dimension here (one effect per site,
# typically modest), a dense per-site inner mode and a dense G×G log-det are
# acceptable and keep the whole marginal differentiable.
#
# The Laplace marginal matches the verified sparse path's convention exactly
# (`_fit_poisson_general_laplace`): with the inner mode b̂ solving
# ∂(data+prior)/∂b = 0 and H = σ_b⁻² C⁻¹ + diag(μ̂),
#     NLL(θ) = Σ_i[μ̂_i − y_i η̂_i + log y_i!]            (data, at the mode)
#            + ½ σ_b⁻² b̂ᵀ C⁻¹ b̂                         (prior quadratic)
#            + G·log σ_b + ½ logdet C(ρ)                  (−½ logdet(σ_b² C))
#            + ½ logdet H.                                 (Laplace curvature)
# AD differentiates through the data/prior/log-det terms AND through b̂(θ) — for
# that the implicit-function relation must hold on the AD (dual) numbers, so the
# inner Newton solve is run to a tight step-norm tolerance on whatever element
# type θ carries. The joint is strictly convex (convex Poisson data term + PD
# prior), so Newton from a warm start lands at the dual-exact mode in a few steps.

# AD-clean inner mode: minimise over b the joint negative log-density
#   f(b) = Σ_i[exp(η0_i + b_{s_i}) − y_i(η0_i + b_{s_i})] + ½ σ_b⁻² bᵀ C⁻¹ b,
# returning the mode b̂ and the Cholesky of H = σ_b⁻² C⁻¹ + diag(μ̂(b̂)). `Cinv` and
# `η0` carry the active element type so the whole solve is differentiable. `gidx`
# maps each observation to its site. Warm-started from `b0`.
function _poisson_spatial_mode(y, η0, gidx, Cinv, invσ2, b0;
                               maxiter::Int = 100, tol::Real = 1e-12)
    T = promote_type(eltype(η0), eltype(Cinv), typeof(invσ2))
    G = size(Cinv, 1)
    b = T.(b0)
    Hch = nothing
    for _ in 1:maxiter
        grad = invσ2 .* (Cinv * b)
        diagH = zeros(T, G)
        @inbounds for i in eachindex(y)
            k = gidx[i]
            μi = exp(clamp(η0[i] + b[k], -30.0, 30.0))
            grad[k] += μi - y[i]
            diagH[k] += μi
        end
        H = invσ2 .* Cinv + Diagonal(diagH)
        Hch = cholesky(Symmetric(H); check = false)
        issuccess(Hch) || return b, Hch, false
        step = Hch \ grad
        b = b .- step
        norm(step) <= tol * (1 + norm(b)) && break
    end
    Hch === nothing && return b, Hch, false
    # Refresh μ̂ / H at the final b so the returned Cholesky is exactly H(b̂).
    diagH = zeros(T, G)
    @inbounds for i in eachindex(y)
        k = gidx[i]
        diagH[k] += exp(clamp(η0[i] + b[k], -30.0, 30.0))
    end
    H = invσ2 .* Cinv + Diagonal(diagH)
    Hch = cholesky(Symmetric(H); check = false)
    return b, Hch, issuccess(Hch)
end

# Coordinate-spatial Poisson Laplace marginal NLL at θ = [β_μ; log σ_b; log ρ],
# with the inner mode warm-started from `bref` (a length-G buffer that the fit
# updates across outer iterations). Returns the marginal NLL only; the gradient
# and Hessian are taken by ForwardDiff over this function. `Ddist` is the G×G site
# distance matrix; `jitter` keeps C(ρ) strictly PD.
function _poisson_spatial_marginal(θ, y, Xμ, gidx, Ddist, lf, bref;
                                   jitter::Float64 = 1e-8)
    pμ = size(Xμ, 2)
    G = size(Ddist, 1)
    βμ = θ[1:pμ]
    logσ = clamp(θ[pμ+1], -8.0, 3.0)
    logρ = clamp(θ[pμ+2], -8.0, 8.0)
    invσ2 = exp(-2 * logσ)
    ρ = exp(logρ)
    T = eltype(θ)
    C = exp.(.-Ddist ./ ρ) .+ jitter .* Matrix(I, G, G)     # unit-diagonal spatial correlation
    Cchol = cholesky(Symmetric(C); check = false)
    issuccess(Cchol) || return convert(T, 1e18)
    Cinv = inv(Cchol)
    η0 = Xμ * βμ
    b, Hch, ok = _poisson_spatial_mode(y, η0, gidx, Cinv, invσ2, bref)
    ok || return convert(T, 1e18)
    bref .= ForwardDiff.value.(b)                           # warm start for the next outer eval
    data = zero(T)
    @inbounds for i in eachindex(y)
        ηi = clamp(η0[i] + b[gidx[i]], -30.0, 30.0)
        data += exp(ηi) - y[i] * ηi + lf[i]
    end
    prior = 0.5 * invσ2 * dot(b, Cinv * b)
    # −½ logdet(σ_b² C) = −½(2G logσ_b + logdet C) = −G logσ_b − ½ logdet C; the
    # marginal carries +½ logdet C⁻¹ = −½ logdet C and +G logσ_b enters from the
    # prior normaliser, matching `_fit_poisson_general_laplace` (val = … + q·logσ
    # − ½ logdetQ + ½ logdet H, with logdetQ = logdet C⁻¹ = −logdet C).
    return data + prior + G * logσ + 0.5 * logdet(Cchol) + 0.5 * logdet(Hch)
end

"""
    _fit_poisson_spatial_coord(fam, y, Xμ, labels, coords, nmμ, grp, g_tol; se)

Poisson `spatial(1 | grp)` fit with a coordinate-based exponential-kernel spatial
covariance `C(ρ) = exp(-d/ρ)` and the range `ρ` **estimated jointly** (#270). The
site coordinates (`coords`, a `G×2` matrix, one row per group level in first-seen
order) give the pairwise distances `d`; the random intercept is `b ~ N(0, σ_b² C(ρ))`
on `log λ`. The outer parameter vector is `θ = [β_μ; log σ_b; log ρ]`, so `ρ` is a
genuine hyperparameter whose gradient flows through `C(ρ)` into the Laplace
marginal — not a fixed-range or profile-over-grid approximation.

The marginal is the Poisson Laplace approximation (same convention as the verified
sparse general-covariance path), written in AD-traceable operations so ForwardDiff
supplies the exact outer gradient and the covariance Hessian. Recovered blocks:
`:mu` (fixed effects), `:resd` (`log σ_b`), `:range` (`log ρ`).

!!! note
    The range `ρ` is only weakly identified from a single spatial realization;
    `:resd` (the spatial SD) and the fixed effects are the robustly recoverable
    pieces. For a precomputed spatial covariance, use `spatial(1 | grp)` with
    `K = …` instead (the verified O(p) sparse path).
"""
function _fit_poisson_spatial_coord(fam::Poisson, y, Xμ, labels, coords, nmμ, grp,
                                    g_tol; se::Bool = true)
    n = length(y)
    pμ = size(Xμ, 2)
    gidx, G = _group_index(labels)
    size(coords, 1) == G ||
        error("spatial(1 | $grp) coords must have one row per group level (G = $G), got $(size(coords, 1))")
    size(coords, 2) >= 1 ||
        error("spatial(1 | $grp) coords must have ≥ 1 coordinate column")
    Ddist = [sqrt(sum(abs2, @view(coords[k, :]) .- @view(coords[l, :]))) for k in 1:G, l in 1:G]
    offdiag = [Ddist[k, l] for k in 1:G for l in 1:G if k != l]
    meandist = isempty(offdiag) ? 1.0 : sum(offdiag) / length(offdiag)
    lf = [_logfactorial(round(Int, yi)) for yi in y]

    bref = zeros(G)                                          # inner-mode warm start (Float64 buffer)
    nll(θ) = _poisson_spatial_marginal(θ, y, Xμ, gidx, Ddist, lf, bref)

    θ0 = zeros(pμ + 2)
    θ0[1:pμ] .= _poisson_fixed_start(y, Xμ)
    θ0[pμ+1] = log(0.5)                                      # log σ_b
    θ0[pμ+2] = log(meandist)                                 # log ρ ≈ mean pairwise distance
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol, iterations = 400);
                         autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = if se
        try
            inv(Symmetric(ForwardDiff.hessian(nll, θ̂)))
        catch
            fill(NaN, length(θ̂), length(θ̂))
        end
    else
        fill(NaN, length(θ̂), length(θ̂))
    end

    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1), :range => (pμ+2):(pμ+2)]
    names = [:mu => nmμ, :resd => [String(grp)], :range => ["range"]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ]))                 # population λ (b = 0)
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nll(θ̂), n, Optim.converged(res), means, obs, scales)
    return _withnll(fit, nll)
end
