# sparse_laplace_glmm.jl — reusable sparse-Laplace spine for non-Gaussian GLMMs.
#
# First proving slice: Poisson crossed random intercepts. The latent state is one
# scalar effect per level of each component, with a block-diagonal Gaussian prior.
# For fixed θ = [β; log σ_1, …, log σ_K], the inner Newton solve finds b̂ and the
# Laplace marginal is
#   data_nll(b̂) + 0.5 b̂'Pb̂ + Σ_k G_k log σ_k + 0.5 logdet(Z'WZ + P).

using LinearAlgebra: Symmetric, cholesky, logdet, I, diag
using SparseArrays: sparse, spdiagm

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
                               maxiter::Int = 120, tol::Real = 1e-8)
    q = size(Z, 2)
    b = b0 === nothing ? zeros(q) : copy(b0)
    invvar = exp.(-2 .* logσ[compid])
    Pdiag = invvar
    lf = [_logfactorial(round(Int, yi)) for yi in y]

    function joint_no_const(bb)
        η = clamp.(η0 .+ Z * bb, -30.0, 30.0)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(y)
            s += exp(η[i]) - y[i] * η[i] + lf[i]
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
    return b, ch, iters, false
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
                               maxiter::Int = 120, tol::Real = 1e-8)
    q = G + Hh
    b = b0 === nothing ? zeros(q) : copy(b0)
    invg = exp(-2 * logσ[1])
    invh = exp(-2 * logσ[2])
    lf = [_logfactorial(round(Int, yi)) for yi in y]

    function joint_no_const(bb)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(y)
            η = clamp(η0[i] + bb[gidx[i]] + bb[G+hidx[i]], -30.0, 30.0)
            s += exp(η) - y[i] * η + lf[i]
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
    return b, ch, iters, false
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
        gβ = gradβ_raw
        @inbounds for i in eachindex(y)
            gi = gidx[i]
            hi = G + hidx[i]
            lever = Hinv[gi, gi] + Hinv[hi, hi] + 2 * Hinv[gi, hi]
            adj = 0.5 * μstore[i] * lever
            for k in 1:pμ
                gβ[k] += Xμ[i, k] * adj
            end
        end
        hd = diag(Hinv)
        gσ1 = G - invg * (sum(abs2, @view b[1:G]) + sum(@view hd[1:G]))
        gσ2 = Hh - invh * (sum(abs2, @view b[G+1:G+Hh]) + sum(@view hd[G+1:G+Hh]))
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
    res = try
        Optim.optimize(nll, Optim.minimizer(res_fast), Optim.LBFGS(),
                       Optim.Options(g_tol = g_tol, iterations = polish_iterations))
    catch
        res_fast
    end
    θ̂ = Optim.minimizer(res)
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
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nll(θ̂), n, Optim.converged(res), means, obs, scales)
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
