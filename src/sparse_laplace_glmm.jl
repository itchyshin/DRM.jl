# sparse_laplace_glmm.jl — reusable sparse-Laplace spine for non-Gaussian GLMMs.
#
# First proving slice: Poisson crossed random intercepts. The latent state is one
# scalar effect per level of each component, with a block-diagonal Gaussian prior.
# For fixed θ = [β; log σ_1, …, log σ_K], the inner Newton solve finds b̂ and the
# Laplace marginal is
#   data_nll(b̂) + 0.5 b̂'Pb̂ + Σ_k G_k log σ_k + 0.5 logdet(Z'WZ + P).

using LinearAlgebra: Symmetric, cholesky, logdet, I, diag, norm
using SparseArrays: sparse, spdiagm
using SpecialFunctions: digamma, loggamma, polygamma, trigamma

function _laplace_re_design(comps, n::Int)
    Gks = [c[3] for c in comps]
    offs = cumsum([0; Gks])
    q = sum(Gks)
    rows = Int[]
    cols = Int[]
    vals = Float64[]
    compid = Vector{Int}(undef, q)
    for (k, (w, gidx, Gk, _)) in enumerate(comps)
        for c in 1:Gk
            compid[offs[k] + c] = k
        end
        @inbounds for i in 1:n
            wi = w[i]
            iszero(wi) && continue
            push!(rows, i)
            push!(cols, offs[k] + gidx[i])
            push!(vals, wi)
        end
    end
    return sparse(rows, cols, vals, n, q), compid, Gks
end

function _poisson_laplace_mode(y, η0, Z, compid, logσ; b0 = nothing,
                               maxiter::Int = 60, tol::Real = 1e-8)
    q = size(Z, 2)
    b = b0 === nothing ? zeros(q) : copy(b0)
    invvar = exp.(-2 .* logσ[compid])
    Pdiag = invvar

    function joint_no_const(bb)
        η = clamp.(η0 .+ Z * bb, -30.0, 30.0)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(y)
            s += exp(η[i]) - y[i] * η[i]
        end
        return s + 0.5 * sum(Pdiag .* bb .* bb)
    end

    ch = nothing
    iters = 0
    for iter in 1:maxiter
        iters = iter
        η = clamp.(η0 .+ Z * b, -30.0, 30.0)
        μ = exp.(η)
        grad = Vector(Z' * (μ .- y)) .+ Pdiag .* b
        H = Matrix(Z' * (spdiagm(0 => μ) * Z))
        @inbounds for j in 1:q
            H[j, j] += Pdiag[j]
        end
        ch = cholesky(Symmetric(H); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        norm(step) <= tol * (1 + norm(b)) && return b, ch, iters, true

        f0 = joint_no_const(b)
        α = 1.0
        accepted = false
        while α >= 1e-4
            trial = b .- α .* step
            if joint_no_const(trial) <= f0
                b = trial
                accepted = true
                break
            end
            α *= 0.5
        end
        accepted || return b, ch, iters, false
    end
    return b, ch, iters, ch !== nothing
end

function _finite_hessian(f, x; h::Real = 1e-3)
    n = length(x)
    H = zeros(n, n)
    fx = f(x)
    for i in 1:n
        ei = zeros(n); ei[i] = h
        H[i, i] = (f(x .+ ei) - 2fx + f(x .- ei)) / h^2
        for j in (i+1):n
            ej = zeros(n); ej[j] = h
            H[i, j] = (f(x .+ ei .+ ej) - f(x .+ ei .- ej) -
                       f(x .- ei .+ ej) + f(x .- ei .- ej)) / (4h^2)
            H[j, i] = H[i, j]
        end
    end
    return H
end

function _poisson_fixed_start(y, X)
    p = size(X, 2)
    β = zeros(p)
    β[1] = log(sum(y) / length(y) + eps())
    for _ in 1:25
        η = clamp.(X * β, -30.0, 30.0)
        μ = exp.(η)
        g = Vector(X' * (μ .- y))
        H = Matrix(X' * (μ .* X))
        ch = cholesky(Symmetric(H); check = false)
        issuccess(ch) || return β
        step = ch \ g
        β .-= step
        norm(step) <= 1e-8 * (1 + norm(β)) && break
    end
    return β
end

function _poisson_crossed_mode(y, η0, gidx, G, hidx, Hh, logσ; b0 = nothing,
                               maxiter::Int = 60, tol::Real = 1e-8)
    q = G + Hh
    b = b0 === nothing ? zeros(q) : copy(b0)
    invg = exp(-2 * logσ[1])
    invh = exp(-2 * logσ[2])

    function joint_no_const(bb)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(y)
            η = clamp(η0[i] + bb[gidx[i]] + bb[G+hidx[i]], -30.0, 30.0)
            s += exp(η) - y[i] * η
        end
        return s + 0.5 * invg * sum(abs2, @view bb[1:G]) +
                   0.5 * invh * sum(abs2, @view bb[G+1:G+Hh])
    end

    ch = nothing
    iters = 0
    for iter in 1:maxiter
        iters = iter
        T = eltype(b)
        grad = zeros(T, q)
        Hmat = zeros(T, q, q)
        @inbounds for i in eachindex(y)
            gi = gidx[i]
            hi = G + hidx[i]
            η = clamp(η0[i] + b[gi] + b[hi], -30.0, 30.0)
            μ = exp(η)
            r = μ - y[i]
            grad[gi] += r
            grad[hi] += r
            Hmat[gi, gi] += μ
            Hmat[hi, hi] += μ
            Hmat[gi, hi] += μ
        end
        @inbounds for j in 1:G
            grad[j] += invg * b[j]
            Hmat[j, j] += invg
        end
        @inbounds for j in (G+1):q
            grad[j] += invh * b[j]
            Hmat[j, j] += invh
        end
        Hmat .+= transpose(Hmat)
        @inbounds for j in 1:q
            Hmat[j, j] *= 0.5
        end
        ch = cholesky(Symmetric(Hmat); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        norm(step) <= tol * (1 + norm(b)) && return b, ch, iters, true

        f0 = joint_no_const(b)
        α = 1.0
        accepted = false
        while α >= 1e-4
            trial = b .- α .* step
            if joint_no_const(trial) <= f0
                b = trial
                accepted = true
                break
            end
            α *= 0.5
        end
        accepted || return b, ch, iters, false
    end
    return b, ch, iters, ch !== nothing
end

function _fit_poisson_crossed_intercepts_laplace(fam::Poisson, y, Xμ, gidx, G, hidx, Hh,
                                                 nmμ, labels, g_tol; se::Bool = true,
                                                 polish_iterations::Int = 35)
    n = length(y)
    pμ = size(Xμ, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    last_b = zeros(G + Hh)

    function eval_laplace(θ; grad::Bool = false)
        βμ = θ[1:pμ]
        logσ = clamp.(θ[pμ+1:pμ+2], -8.0, 3.0)
        η0 = Xμ * βμ
        b, ch, _, ok = _poisson_crossed_mode(y, η0, gidx, G, hidx, Hh, logσ; b0 = last_b)
        if !ok
            b, ch, _, ok = _poisson_crossed_mode(y, η0, gidx, G, hidx, Hh, logσ; b0 = zeros(G + Hh))
        end
        ok || return grad ? (1e18, zeros(length(θ))) : 1e18
        last_b .= b
        data = zero(eltype(θ))
        invg = exp(-2 * logσ[1])
        invh = exp(-2 * logσ[2])
        prior = 0.5 * invg * sum(abs2, @view b[1:G]) +
                0.5 * invh * sum(abs2, @view b[G+1:G+Hh])
        gradβ_raw = zeros(eltype(θ), pμ)
        μstore = Vector{eltype(θ)}(undef, n)
        @inbounds for i in eachindex(y)
            η = clamp(η0[i] + b[gidx[i]] + b[G+hidx[i]], -30.0, 30.0)
            μ = exp(η)
            μstore[i] = μ
            data += μ - y[i] * η + lf[i]
            r = μ - y[i]
            for k in 1:pμ
                gradβ_raw[k] += Xμ[i, k] * r
            end
        end
        val = data + prior + G * logσ[1] + Hh * logσ[2] + 0.5 * logdet(ch)
        grad || return val

        Hinv = ch \ Matrix{Float64}(I, G + Hh, G + Hh)
        tlogdet = zeros(eltype(θ), G + Hh)             # Z' * (μ .* leverage)
        crossβ = zeros(eltype(θ), G + Hh, pμ)          # Z' * (μ .* Xβ_col)
        gβ = gradβ_raw
        @inbounds for i in eachindex(y)
            gi = gidx[i]
            hi = G + hidx[i]
            lever = Hinv[gi, gi] + Hinv[hi, hi] + 2 * Hinv[gi, hi]
            μi = μstore[i]
            μlever = μi * lever
            tlogdet[gi] += μlever
            tlogdet[hi] += μlever
            adj = 0.5 * μlever
            for k in 1:pμ
                xik = Xμ[i, k]
                gβ[k] += xik * adj
                crossβ[gi, k] += μi * xik
                crossβ[hi, k] += μi * xik
            end
        end
        implicit = Hinv * tlogdet
        @inbounds for k in 1:pμ
            gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
        end
        hd = diag(Hinv)
        gσ1 = G - invg * (sum(abs2, @view b[1:G]) + sum(@view hd[1:G]))
        gσ2 = Hh - invh * (sum(abs2, @view b[G+1:G+Hh]) + sum(@view hd[G+1:G+Hh]))
        gσ1 += dot(@view(implicit[1:G]), invg .* @view(b[1:G]))
        gσ2 += dot(@view(implicit[G+1:G+Hh]), invh .* @view(b[G+1:G+Hh]))
        return val, vcat(gβ, [gσ1, gσ2])
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + 2)
    θ0[1:pμ] .= _poisson_fixed_start(y, Xμ)
    θ0[pμ+1] = log(0.4)
    θ0[pμ+2] = log(0.4)
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = if polish_iterations > 0
        try
            Optim.optimize(nll, Optim.minimizer(res_fast), Optim.LBFGS(),
                           Optim.Options(g_tol = g_tol, iterations = polish_iterations))
        catch
            res_fast
        end
    else
        res_fast
    end
    θ̂ = Optim.minimizer(res)
    gfinal = zeros(length(θ̂))
    grad!(gfinal, θ̂)
    converged = Optim.converged(res) || norm(gfinal, Inf) <= 1e-4 * (1 + norm(θ̂, Inf))
    V = if se
        Hθ = _finite_hessian(nll, θ̂)
        try
            inv(Symmetric(Hθ))
        catch
            Matrix{Float64}(I, length(θ̂), length(θ̂))
        end
    else
        fill(NaN, length(θ̂), length(θ̂))
    end
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+2)]
    names = [:mu => nmμ, :resd => labels]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ]))
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nll(θ̂), n, converged, means, obs, scales)
    return _withnll(fit, nll)
end

"""
    _fit_poisson_crossed_laplace(fam, y, Xμ, comps, nmμ, g_tol)

Internal engine-lane fitter for Poisson random-intercept GLMMs with one or more
independent scalar random-effect components. `comps` is a vector of
`(w, gidx, G, label)` tuples, matching the Gaussian multi-RE fitter.
"""
function _fit_poisson_crossed_laplace(fam::Poisson, y, Xμ, comps, nmμ, g_tol; se::Bool = true,
                                      polish_iterations::Int = 35)
    length(comps) == 1 && begin
        w, gidx, G, label = comps[1]
        all(==(1.0), w) && return _fit_poisson_ranef(fam, y, Xμ, gidx, G, nmμ, Symbol(label), g_tol)
    end
    if length(comps) == 2 && all(==(1.0), comps[1][1]) && all(==(1.0), comps[2][1])
        return _fit_poisson_crossed_intercepts_laplace(
            fam, y, Xμ, comps[1][2], comps[1][3], comps[2][2], comps[2][3],
            nmμ, [comps[1][4], comps[2][4]], g_tol; se = se,
            polish_iterations = polish_iterations
        )
    end

    n = length(y)
    pμ = size(Xμ, 2)
    Z, compid, Gks = _laplace_re_design(comps, n)
    K = length(comps)
    labels = [c[4] for c in comps]
    lf = [_logfactorial(round(Int, yi)) for yi in y]

    last_b = zeros(size(Z, 2))
    last_iters = Ref(0)
    function eval_laplace(θ; grad::Bool = false)
        βμ = θ[1:pμ]
        logσ = clamp.(θ[pμ+1:pμ+K], -8.0, 3.0)
        η0 = Xμ * βμ
        b, ch, iters, ok = _poisson_laplace_mode(y, η0, Z, compid, logσ; b0 = last_b)
        if !ok
            b, ch, iters, ok = _poisson_laplace_mode(y, η0, Z, compid, logσ; b0 = zeros(size(Z, 2)))
        end
        last_iters[] = iters
        ok || return grad ? (1e18, zeros(length(θ))) : 1e18
        last_b .= b
        η = clamp.(η0 .+ Z * b, -30.0, 30.0)
        μ = exp.(η)
        data = zero(eltype(θ))
        @inbounds for i in eachindex(y)
            data += μ[i] - y[i] * η[i] + lf[i]
        end
        invvar = exp.(-2 .* logσ[compid])
        prior = 0.5 * sum(invvar .* b .* b)
        logprior_scale = sum(Gks[k] * logσ[k] for k in 1:K)
        val = data + prior + logprior_scale + 0.5 * logdet(ch)
        grad || return val

        # Fast proving-slice gradient: differentiates the Laplace objective with
        # b̂ frozen. The exact implicit logdet correction is the next #70
        # optimisation target; this gradient is used to make the R-vs-Julia grid
        # executable and expose any remaining parity gap.
        Hinv = ch \ Matrix{Float64}(I, size(Z, 2), size(Z, 2))
        ZH = Z * Hinv
        lever = vec(sum(ZH .* Z, dims = 2))              # zᵢ' H⁻¹ zᵢ
        gβ = Vector(Xμ' * (μ .- y .+ 0.5 .* μ .* lever))
        gσ = zeros(K)
        hd = diag(Hinv)
        @inbounds for j in eachindex(compid)
            k = compid[j]
            gσ[k] += -invvar[j] * b[j]^2 - invvar[j] * hd[j]
        end
        @inbounds for k in 1:K
            gσ[k] += Gks[k]
        end
        return val, vcat(gβ, gσ)
    end
    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(G, θ)
        _, g = eval_laplace(θ; grad = true)
        G .= g
        return G
    end

    θ0 = zeros(pμ + K)
    θ0[1:pμ] .= _poisson_fixed_start(y, Xμ)
    for k in 1:K
        θ0[pμ+k] = log(0.4)
    end
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = try
        # Short exact-objective polish. The fast frozen-mode gradient gets close;
        # finite-difference LBFGS from that point keeps the reported benchmark on
        # the true Laplace objective rather than the proving-slice gradient.
        Optim.optimize(nll, Optim.minimizer(res_fast), Optim.LBFGS(),
                       Optim.Options(g_tol = g_tol, iterations = polish_iterations))
    catch
        res_fast
    end
    θ̂ = Optim.minimizer(res)
    V = if se
        H = _finite_hessian(nll, θ̂)
        try
            inv(Symmetric(H))
        catch
            Matrix{Float64}(I, length(θ̂), length(θ̂))
        end
    else
        fill(NaN, length(θ̂), length(θ̂))
    end

    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+K)]
    names = [:mu => nmμ, :resd => labels]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ]))
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nll(θ̂), n, Optim.converged(res), means, obs, scales)
    return _withnll(fit, nll)
end

_laplace_logistic(η) = 1 / (1 + exp(-η))

function _laplace_value(::Val{:binomial}, aux, i, η)
    p = _laplace_logistic(clamp(η, -30.0, 30.0))
    s = aux.s[i]
    n = aux.ntr[i]
    return -(aux.logchoose[i] + s * log(p) + (n - s) * log1p(-p))
end

function _laplace_d1(::Val{:binomial}, aux, i, η)
    p = _laplace_logistic(clamp(η, -30.0, 30.0))
    return aux.ntr[i] * p - aux.s[i]
end

function _laplace_d2(::Val{:binomial}, aux, i, η)
    p = _laplace_logistic(clamp(η, -30.0, 30.0))
    return aux.ntr[i] * p * (1 - p)
end

function _laplace_d3(::Val{:binomial}, aux, i, η)
    p = _laplace_logistic(clamp(η, -30.0, 30.0))
    return aux.ntr[i] * p * (1 - p) * (1 - 2p)
end

_laplace_mean(::Val{:binomial}, η) = _laplace_logistic(clamp(η, -30.0, 30.0))
_laplace_obs(::Val{:binomial}, aux, i) = aux.s[i] / aux.ntr[i]

function _laplace_value(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    return -(aux.lconst[i] + y * log(μ) + r * log(r) - (y + r) * log(r + μ))
end

function _laplace_d1(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    return (y + r) * μ / (r + μ) - y
end

function _laplace_d2(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    return (y + r) * r * μ / (r + μ)^2
end

function _laplace_d3(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    return (y + r) * r * μ * (r - μ) / (r + μ)^3
end

_laplace_mean(::Val{:nb2_fixed}, η) = exp(clamp(η, -30.0, 30.0))
_laplace_obs(::Val{:nb2_fixed}, aux, i) = aux.y[i]

function _laplace_value(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    α = aux.shape
    return -(aux.lconst[i] - α * log(μ) - α * y / μ)
end

function _laplace_d1(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    α = aux.shape
    return α - α * aux.y[i] / μ
end

function _laplace_d2(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    return aux.shape * aux.y[i] / μ
end

function _laplace_d3(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    return -aux.shape * aux.y[i] / μ
end

_laplace_mean(::Val{:gamma_fixed}, η) = exp(clamp(η, -30.0, 30.0))
_laplace_obs(::Val{:gamma_fixed}, aux, i) = aux.y[i]

function _laplace_beta_terms(aux, i, η)
    μ = _laplace_logistic(clamp(η, -30.0, 30.0))
    φ = aux.precision
    a = μ * φ
    b = (1 - μ) * φ
    ylogit = aux.ylogit[i]
    A = φ * (digamma(a) - digamma(b) - ylogit)
    B = φ^2 * (trigamma(a) + trigamma(b))
    C = φ^3 * (polygamma(2, a) - polygamma(2, b))
    v = μ * (1 - μ)
    u = 1 - 2μ
    vp = v * u
    vpp = v * u^2 - 2v^2
    return μ, A, B, C, v, vp, vpp
end

function _laplace_value(::Val{:beta_fixed}, aux, i, η)
    μ = _laplace_logistic(clamp(η, -30.0, 30.0))
    φ = aux.precision
    a = μ * φ
    b = (1 - μ) * φ
    y = aux.y[i]
    return -(aux.lgammaφ - loggamma(a) - loggamma(b) + (a - 1) * log(y) + (b - 1) * log1p(-y))
end

function _laplace_d1(::Val{:beta_fixed}, aux, i, η)
    _, A, _, _, v, _, _ = _laplace_beta_terms(aux, i, η)
    return A * v
end

function _laplace_d2(::Val{:beta_fixed}, aux, i, η)
    _, A, B, _, v, vp, _ = _laplace_beta_terms(aux, i, η)
    return B * v^2 + A * vp
end

function _laplace_d3(::Val{:beta_fixed}, aux, i, η)
    _, A, B, C, v, vp, vpp = _laplace_beta_terms(aux, i, η)
    return C * v^3 + 3 * B * v * vp + A * vpp
end

_laplace_mean(::Val{:beta_fixed}, η) = _laplace_logistic(clamp(η, -30.0, 30.0))
_laplace_obs(::Val{:beta_fixed}, aux, i) = aux.y[i]

function _crossed_mean_mode(kind, aux, η0, gidx, G, hidx, Hh, logσ; b0 = nothing,
                            maxiter::Int = 60, tol::Real = 1e-8)
    q = G + Hh
    b = b0 === nothing ? zeros(q) : copy(b0)
    invg = exp(-2 * logσ[1])
    invh = exp(-2 * logσ[2])

    function joint(bb)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(η0)
            η = η0[i] + bb[gidx[i]] + bb[G+hidx[i]]
            s += _laplace_value(kind, aux, i, η)
        end
        return s + 0.5 * invg * sum(abs2, @view bb[1:G]) +
                   0.5 * invh * sum(abs2, @view bb[G+1:G+Hh])
    end

    ch = nothing
    iters = 0
    for iter in 1:maxiter
        iters = iter
        T = eltype(b)
        grad = zeros(T, q)
        Hmat = zeros(T, q, q)
        @inbounds for i in eachindex(η0)
            gi = gidx[i]
            hi = G + hidx[i]
            η = η0[i] + b[gi] + b[hi]
            r = _laplace_d1(kind, aux, i, η)
            w = _laplace_d2(kind, aux, i, η)
            grad[gi] += r
            grad[hi] += r
            Hmat[gi, gi] += w
            Hmat[hi, hi] += w
            Hmat[gi, hi] += w
        end
        @inbounds for j in 1:G
            grad[j] += invg * b[j]
            Hmat[j, j] += invg
        end
        @inbounds for j in (G+1):q
            grad[j] += invh * b[j]
            Hmat[j, j] += invh
        end
        Hmat .+= transpose(Hmat)
        @inbounds for j in 1:q
            Hmat[j, j] *= 0.5
        end
        ch = cholesky(Symmetric(Hmat); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        norm(step) <= tol * (1 + norm(b)) && return b, ch, iters, true

        f0 = joint(b)
        α = 1.0
        accepted = false
        while α >= 1e-4
            trial = b .- α .* step
            if joint(trial) <= f0
                b = trial
                accepted = true
                break
            end
            α *= 0.5
        end
        accepted || return b, ch, iters, false
    end
    return b, ch, iters, ch !== nothing
end

function _fit_crossed_mean_laplace(fam, kind, aux, n::Int, Xμ, gidx, G, hidx, Hh,
                                   nmμ, labels, g_tol; θβ0 = nothing,
                                   se::Bool = false, polish_iterations::Int = 0)
    pμ = size(Xμ, 2)
    last_b = zeros(G + Hh)

    function eval_laplace(θ; grad::Bool = false)
        βμ = θ[1:pμ]
        logσ = clamp.(θ[pμ+1:pμ+2], -8.0, 3.0)
        η0 = Xμ * βμ
        b, ch, _, ok = _crossed_mean_mode(kind, aux, η0, gidx, G, hidx, Hh, logσ; b0 = last_b)
        if !ok
            b, ch, _, ok = _crossed_mean_mode(kind, aux, η0, gidx, G, hidx, Hh, logσ; b0 = zeros(G + Hh))
        end
        ok || return grad ? (1e18, zeros(length(θ))) : 1e18
        last_b .= b

        invg = exp(-2 * logσ[1])
        invh = exp(-2 * logσ[2])
        data = zero(eltype(θ))
        gradβ_raw = zeros(eltype(θ), pμ)
        wstore = Vector{eltype(θ)}(undef, n)
        tstore = Vector{eltype(θ)}(undef, n)
        @inbounds for i in 1:n
            η = η0[i] + b[gidx[i]] + b[G+hidx[i]]
            data += _laplace_value(kind, aux, i, η)
            r = _laplace_d1(kind, aux, i, η)
            w = _laplace_d2(kind, aux, i, η)
            t = _laplace_d3(kind, aux, i, η)
            wstore[i] = w
            tstore[i] = t
            for k in 1:pμ
                gradβ_raw[k] += Xμ[i, k] * r
            end
        end
        prior = 0.5 * invg * sum(abs2, @view b[1:G]) +
                0.5 * invh * sum(abs2, @view b[G+1:G+Hh])
        val = data + prior + G * logσ[1] + Hh * logσ[2] + 0.5 * logdet(ch)
        grad || return val

        Hinv = ch \ Matrix{Float64}(I, G + Hh, G + Hh)
        tlogdet = zeros(eltype(θ), G + Hh)
        crossβ = zeros(eltype(θ), G + Hh, pμ)
        gβ = gradβ_raw
        @inbounds for i in 1:n
            gi = gidx[i]
            hi = G + hidx[i]
            lever = Hinv[gi, gi] + Hinv[hi, hi] + 2 * Hinv[gi, hi]
            tlever = tstore[i] * lever
            tlogdet[gi] += tlever
            tlogdet[hi] += tlever
            adj = 0.5 * tlever
            for k in 1:pμ
                xik = Xμ[i, k]
                gβ[k] += xik * adj
                crossβ[gi, k] += wstore[i] * xik
                crossβ[hi, k] += wstore[i] * xik
            end
        end
        implicit = Hinv * tlogdet
        @inbounds for k in 1:pμ
            gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
        end
        hd = diag(Hinv)
        gσ1 = G - invg * (sum(abs2, @view b[1:G]) + sum(@view hd[1:G]))
        gσ2 = Hh - invh * (sum(abs2, @view b[G+1:G+Hh]) + sum(@view hd[G+1:G+Hh]))
        gσ1 += dot(@view(implicit[1:G]), invg .* @view(b[1:G]))
        gσ2 += dot(@view(implicit[G+1:G+Hh]), invh .* @view(b[G+1:G+Hh]))
        return val, vcat(gβ, [gσ1, gσ2])
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + 2)
    if θβ0 === nothing
        θ0[1:pμ] .= 0.0
    else
        θ0[1:pμ] .= θβ0
    end
    θ0[pμ+1] = log(0.4)
    θ0[pμ+2] = log(0.4)
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = if polish_iterations > 0
        try
            Optim.optimize(nll, Optim.minimizer(res_fast), Optim.LBFGS(),
                           Optim.Options(g_tol = g_tol, iterations = polish_iterations))
        catch
            res_fast
        end
    else
        res_fast
    end
    θ̂ = Optim.minimizer(res)
    gfinal = zeros(length(θ̂))
    grad!(gfinal, θ̂)
    converged = Optim.converged(res) || norm(gfinal, Inf) <= 1e-4 * (1 + norm(θ̂, Inf))
    V = if se
        Hθ = _finite_hessian(nll, θ̂)
        try
            inv(Symmetric(Hθ))
        catch
            Matrix{Float64}(I, length(θ̂), length(θ̂))
        end
    else
        fill(NaN, length(θ̂), length(θ̂))
    end
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+2)]
    names = [:mu => nmμ, :resd => labels]
    means = Dict(:mu => [_laplace_mean(kind, dot(@view(Xμ[i, :]), θ̂[1:pμ])) for i in 1:n])
    obs = Dict(:mu => [_laplace_obs(kind, aux, i) for i in 1:n])
    scales = Dict{Symbol,Vector{Float64}}()
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nll(θ̂), n, converged, means, obs, scales)
    return _withnll(fit, nll)
end

function _fit_binomial_crossed_laplace(fam, s, ntr, Xμ, comps, nmμ, g_tol; se::Bool = false,
                                       polish_iterations::Int = 0)
    length(comps) == 2 || error("_fit_binomial_crossed_laplace requires two random-intercept components")
    all(==(1.0), comps[1][1]) && all(==(1.0), comps[2][1]) ||
        error("_fit_binomial_crossed_laplace supports scalar random intercepts only")
    sint = round.(Int, s)
    nint = round.(Int, ntr)
    logchoose = [_logfactorial(nint[i]) - _logfactorial(sint[i]) - _logfactorial(nint[i] - sint[i]) for i in eachindex(sint)]
    aux = (s = sint, ntr = nint, logchoose = logchoose)
    p̄ = clamp(sum(s) / max(sum(ntr), 1), 1e-4, 1 - 1e-4)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(p̄ / (1 - p̄))
    return _fit_crossed_mean_laplace(
        fam, Val(:binomial), aux, length(s), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, se = se, polish_iterations = polish_iterations
    )
end

function _fit_nb2_fixed_crossed_laplace(fam, y, size::Real, Xμ, comps, nmμ, g_tol;
                                        se::Bool = false, polish_iterations::Int = 0)
    length(comps) == 2 || error("_fit_nb2_fixed_crossed_laplace requires two random-intercept components")
    yint = round.(Int, y)
    r = float(size)
    lconst = [loggamma(yint[i] + r) - loggamma(r) - _logfactorial(yint[i]) for i in eachindex(yint)]
    aux = (y = Float64.(yint), size = r, lconst = lconst)
    θβ0 = _poisson_fixed_start(y, Xμ)
    return _fit_crossed_mean_laplace(
        fam, Val(:nb2_fixed), aux, length(y), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, se = se, polish_iterations = polish_iterations
    )
end

function _fit_gamma_fixed_crossed_laplace(fam, y, shape::Real, Xμ, comps, nmμ, g_tol;
                                          se::Bool = false, polish_iterations::Int = 0)
    length(comps) == 2 || error("_fit_gamma_fixed_crossed_laplace requires two random-intercept components")
    α = float(shape)
    lconst = [α * log(α) - loggamma(α) + (α - 1) * log(y[i]) for i in eachindex(y)]
    aux = (y = Float64.(y), shape = α, lconst = lconst)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(sum(y) / length(y) + eps())
    return _fit_crossed_mean_laplace(
        fam, Val(:gamma_fixed), aux, length(y), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, se = se, polish_iterations = polish_iterations
    )
end

function _fit_beta_fixed_crossed_laplace(fam, y, precision::Real, Xμ, comps, nmμ, g_tol;
                                         se::Bool = false, polish_iterations::Int = 0)
    length(comps) == 2 || error("_fit_beta_fixed_crossed_laplace requires two random-intercept components")
    φ = float(precision)
    yv = Float64.(y)
    ylogit = log.(yv) .- log1p.(-yv)
    aux = (y = yv, precision = φ, ylogit = ylogit, lgammaφ = loggamma(φ))
    ȳ = clamp(sum(yv) / length(yv), 1e-4, 1 - 1e-4)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(ȳ / (1 - ȳ))
    return _fit_crossed_mean_laplace(
        fam, Val(:beta_fixed), aux, length(yv), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, se = se, polish_iterations = polish_iterations
    )
end
