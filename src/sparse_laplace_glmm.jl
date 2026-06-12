# sparse_laplace_glmm.jl — reusable sparse-Laplace spine for non-Gaussian GLMMs.
#
# First proving slice: Poisson crossed random intercepts. The latent state is one
# scalar effect per level of each component, with a block-diagonal Gaussian prior.
# For fixed θ = [β; log σ_1, …, log σ_K], the inner Newton solve finds b̂ and the
# Laplace marginal is
#   data_nll(b̂) + 0.5 b̂'Pb̂ + Σ_k G_k log σ_k + 0.5 logdet(Z'WZ + P).

using LinearAlgebra: Symmetric, cholesky, logdet, I, diag, norm
using SparseArrays: sparse, spdiagm, rowvals, nonzeros, nzrange
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

function _laplace_outer_converged(res, nllhat, gfinal, θ, n::Int, g_tol)
    isfinite(nllhat) && nllhat < 1e17 || return false
    Optim.converged(res) && return true
    grad_limit = max(1e-4 * (1 + norm(θ, Inf)), g_tol * max(n, 1))
    return norm(gfinal, Inf) <= grad_limit
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

function _poisson_phylo_setup(tree, labels)
    phy = tree isa AugmentedPhy ? tree : augmented_phy(tree)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    q = length(keep)
    Q = phy.Q_topology[keep, keep]
    pos = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [pos[phy.leaf_indices[i]] for i in 1:phy.n_leaves]
    by_name = Dict(phy.leaf_names[i] => leaf_pos[i] for i in 1:phy.n_leaves)

    leaf_node = Vector{Int}(undef, length(labels))
    matched_names = true
    @inbounds for i in eachindex(labels)
        key = string(labels[i])
        if haskey(by_name, key)
            leaf_node[i] = by_name[key]
        else
            matched_names = false
            break
        end
    end
    matched_names && return Q, leaf_node, phy

    numeric_labels = true
    @inbounds for i in eachindex(labels)
        li = labels[i]
        if li isa Integer && 1 <= Int(li) <= phy.n_leaves
            leaf_node[i] = leaf_pos[Int(li)]
        else
            numeric_labels = false
            break
        end
    end
    numeric_labels && return Q, leaf_node, phy

    gidx, G = _group_index(labels)
    G == phy.n_leaves ||
        error("phylo labels must match tree tip names, integer tip indices, or have one level per tree tip")
    @inbounds for i in eachindex(labels)
        leaf_node[i] = leaf_pos[gidx[i]]
    end
    return Q, leaf_node, phy
end

function _sparse_trace_product(A, B)
    rows = rowvals(B)
    vals = nonzeros(B)
    s = 0.0
    @inbounds for col in 1:size(B, 2)
        for ptr in nzrange(B, col)
            s += vals[ptr] * A[rows[ptr], col]
        end
    end
    return s
end

function _poisson_phylo_mode(y, η0, leaf_node, Q, logσ; b0 = nothing,
                             maxiter::Int = 60, tol::Real = 1e-8)
    q = size(Q, 1)
    b = b0 === nothing ? zeros(q) : copy(b0)
    invσ2 = exp(-2 * logσ)

    function joint_no_const(bb)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(y)
            η = clamp(η0[i] + bb[leaf_node[i]], -30.0, 30.0)
            s += exp(η) - y[i] * η
        end
        return s + 0.5 * invσ2 * dot(bb, Q * bb)
    end

    ch = nothing
    iters = 0
    for iter in 1:maxiter
        iters = iter
        T = eltype(b)
        grad = zeros(T, q)
        diagH = zeros(Float64, q)
        @inbounds for i in eachindex(y)
            li = leaf_node[i]
            η = clamp(η0[i] + b[li], -30.0, 30.0)
            μ = exp(η)
            grad[li] += μ - y[i]
            diagH[li] += μ
        end
        grad .+= invσ2 .* (Q * b)
        Hmat = invσ2 .* Q + spdiagm(0 => diagH)
        ch = cholesky(Symmetric(Hmat); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        sn = norm(step)
        sn <= tol * (1 + norm(b)) && return b, ch, iters, true

        # The Poisson phylo joint is strictly convex in b (convex data term + PD
        # prior). Once inside the quadratic-convergence basin (small step) the
        # full Newton step is contractive, but a backtracking line search there
        # STALLS on rounding-level decreases — it cannot verify the tiny strict
        # improvement, so it would exhaust and leave the mode only loosely
        # converged (~1e-6), which then shows up as finite-difference noise in the
        # marginal gradient. So in the basin take the FULL Newton step (driving
        # the mode to ~`tol`); use the safeguarded line search only far from the
        # mode, where for a convex objective it is guaranteed to find a decrease.
        if sn <= 1e-3 * (1 + norm(b))
            b = b .- step
        else
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
    end
    return b, ch, iters, ch !== nothing
end

"""
    _poisson_phylo_laplace_fg(y, Xμ, leaf_node, Q, logdetQ, lf, θ; grad, b0, newton_tol, newton_maxiter)

Module-level f/g evaluation of the Poisson phylogenetic-Laplace marginal NLL at a
single θ, used both by `_fit_poisson_phylo_laplace` and by the standing
FD-vs-analytic gradient gate (#165). Hoisting it out of the fit closure lets the
gate drive a *controlled, tightly-converged, warm-started* inner mode (the same
recipe `marginal_and_exact_grad` / the q4 Q-gate use to reach ≤ 1e-6).

The marginal is

    L(θ) = data(b̂) + ½ σ⁻² b̂'Q b̂ + q logσ − ½ logdet Q + ½ logdet H,
    H = σ⁻² Q + diag(Σ_{i∈leaf} μ_i).

Because b̂ solves ∂(data+prior)/∂b = 0, the total θ-gradient is the explicit part
(b̂ frozen) plus the implicit logdet correction through
db̂/dθ = −H⁻¹ ∂²(data+prior)/∂b∂θ. For Poisson the data Hessian weight and its
η-derivative coincide (d²ℓ = d³ℓ = μ), so a single μ drives both the logdet trace
and the cross term — this is the family-specific third-derivative term the IFT
introduces. Returns `(val[, grad], b, ok)`; on a non-PD inner solve `ok = false`.
"""
function _poisson_phylo_laplace_fg(y, Xμ, leaf_node, Q, logdetQ, lf, θ;
                                   grad::Bool = false, b0 = nothing,
                                   newton_tol::Real = 1e-8, newton_maxiter::Int = 60)
    n = length(y)
    pμ = length(θ) - 1
    q = size(Q, 1)
    βμ = θ[1:pμ]
    logσ = clamp(θ[pμ+1], -8.0, 3.0)
    invσ2 = exp(-2 * logσ)
    η0 = Xμ * βμ
    b, ch, _, ok = _poisson_phylo_mode(y, η0, leaf_node, Q, logσ;
                                       b0 = b0, tol = newton_tol, maxiter = newton_maxiter)
    if !ok
        return grad ? (1e18, zeros(length(θ)), b, false) : (1e18, b, false)
    end

    data = zero(eltype(θ))
    gradβ_raw = zeros(eltype(θ), pμ)
    μstore = Vector{eltype(θ)}(undef, n)
    @inbounds for i in eachindex(y)
        η = clamp(η0[i] + b[leaf_node[i]], -30.0, 30.0)
        μ = exp(η)
        μstore[i] = μ
        data += μ - y[i] * η + lf[i]
        r = μ - y[i]
        for k in 1:pμ
            gradβ_raw[k] += Xμ[i, k] * r
        end
    end
    Qb = Q * b
    prior = 0.5 * invσ2 * dot(b, Qb)
    val = data + prior + q * logσ - 0.5 * logdetQ + 0.5 * logdet(ch)
    grad || return val, b, true

    S = takahashi_selinv(ch)
    hd = diag(S)
    traceSQ = _sparse_trace_product(S, Q)
    tlogdet = zeros(eltype(θ), q)
    crossβ = zeros(eltype(θ), q, pμ)
    gβ = gradβ_raw
    @inbounds for i in eachindex(y)
        li = leaf_node[i]
        μi = μstore[i]
        lever = hd[li]
        μlever = μi * lever
        tlogdet[li] += μlever
        adj = 0.5 * μlever
        for k in 1:pμ
            xik = Xμ[i, k]
            gβ[k] += xik * adj
            crossβ[li, k] += μi * xik
        end
    end
    implicit = ch \ tlogdet
    @inbounds for k in 1:pμ
        gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
    end
    Pu = invσ2 .* Qb
    gσ = q - invσ2 * (dot(b, Qb) + traceSQ) + dot(implicit, Pu)
    return val, vcat(gβ, [gσ]), b, true
end

"""
    _fit_poisson_phylo_laplace(fam, y, Xμ, labels, tree, nmμ, grp, g_tol)

Internal sparse-Laplace fitter for `Poisson()` with a phylogenetic random
intercept `phylo(1 | grp)` on the mean. The tree is represented by the
root-conditioned augmented precision, so the latent state has one effect per
non-root tree node and the mode/logdet computations stay sparse.
"""
function _fit_poisson_phylo_laplace(fam::Poisson, y, Xμ, labels, tree, nmμ, grp,
                                    g_tol; se::Bool = true,
                                    polish_iterations::Int = 15)
    Q, leaf_node, _ = _poisson_phylo_setup(tree, labels)
    return _fit_poisson_general_laplace(fam, y, Xμ, Q, leaf_node, nmμ, grp, g_tol;
                                        se = se, polish_iterations = polish_iterations)
end

"""
    _general_cov_setup(C, labels) -> (Q, leaf_node)

Resolve a user-supplied per-group covariance/relatedness matrix `C` (G×G, SPD)
to the `(precision Q, leaf_node)` pair the sparse-Laplace spine consumes. `C` is
first rescaled to a unit-diagonal correlation `R` (so the recovered `:resd` block
is the random-effect SD `σ_b`, with prior `b ~ N(0, σ_b² R)`, matching the phylo
convention), then `Q = R⁻¹`. `leaf_node` maps each observation to its group level
via [`_group_index`](@ref) — the relatedness/animal-model/spatial analogue of the
tree's leaf-to-node map. Mathematically identical to the phylo path with the tree
precision swapped for an arbitrary PD precision.
"""
function _general_cov_setup(C::AbstractMatrix, labels)
    gidx, G = _group_index(labels)
    size(C, 1) == size(C, 2) == G ||
        error("covariance matrix must be $(G)×$(G) (the number of `$(length(labels))`-row group levels = $G)")
    Cf = Matrix{Float64}(C)
    d = sqrt.(diag(Cf))
    all(>(0), d) || error("covariance matrix must have a strictly positive diagonal")
    R = Symmetric(Cf ./ (d * d'))                       # unit-diagonal correlation
    Rchol = cholesky(R; check = false)
    issuccess(Rchol) || error("covariance matrix is not positive definite")
    Q = sparse(Symmetric(inv(Rchol)))                   # dense precision, sparse-wrapped
    return Q, gidx
end

"""
    _fit_poisson_relmat_laplace(fam, y, Xμ, C, labels, nmμ, grp, g_tol; se)

Poisson sparse-Laplace fit with a general user-supplied PD covariance `C` on the
mean random intercept (`relmat`/`animal`/`spatial(1 | grp)`). Reuses the verified
phylo Laplace spine via [`_general_cov_setup`](@ref): the only difference from the
phylo route is that the prior precision comes from `C⁻¹` instead of the tree
topology. Exact O(p) gradient and Takahashi log-det derivatives carry over
unchanged.
"""
function _fit_poisson_relmat_laplace(fam::Poisson, y, Xμ, C, labels, nmμ, grp,
                                     g_tol; se::Bool = true,
                                     polish_iterations::Int = 15)
    Q, leaf_node = _general_cov_setup(C, labels)
    return _fit_poisson_general_laplace(fam, y, Xμ, Q, leaf_node, nmμ, grp, g_tol;
                                        se = se, polish_iterations = polish_iterations)
end

# Shared body: Poisson sparse-Laplace fit for an arbitrary precision `Q` and
# observation→latent map `leaf_node`. Driven by the tree route
# (`_fit_poisson_phylo_laplace`) and the general-covariance route
# (`_fit_poisson_relmat_laplace`); see those for the two front ends.
function _fit_poisson_general_laplace(fam::Poisson, y, Xμ, Q, leaf_node, nmμ, grp,
                                      g_tol; se::Bool = true,
                                      polish_iterations::Int = 15)
    n = length(y)
    pμ = size(Xμ, 2)
    q = size(Q, 1)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    qchol = cholesky(Symmetric(Q); check = false)
    issuccess(qchol) || error("phylo(1 | $grp) tree precision is not positive definite after root conditioning")
    logdetQ = logdet(qchol)
    last_b = zeros(q)

    function eval_laplace(θ; grad::Bool = false)
        if grad
            val, g, b, ok = _poisson_phylo_laplace_fg(
                y, Xμ, leaf_node, Q, logdetQ, lf, θ; grad = true, b0 = last_b
            )
            if !ok
                val, g, b, ok = _poisson_phylo_laplace_fg(
                    y, Xμ, leaf_node, Q, logdetQ, lf, θ; grad = true, b0 = zeros(q)
                )
            end
            ok || return 1e18, zeros(length(θ))
            last_b .= b
            return val, g
        else
            val, b, ok = _poisson_phylo_laplace_fg(
                y, Xμ, leaf_node, Q, logdetQ, lf, θ; grad = false, b0 = last_b
            )
            if !ok
                val, b, ok = _poisson_phylo_laplace_fg(
                    y, Xμ, leaf_node, Q, logdetQ, lf, θ; grad = false, b0 = zeros(q)
                )
            end
            ok || return 1e18
            last_b .= b
            return val
        end
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + 1)
    θ0[1:pμ] .= _poisson_fixed_start(y, Xμ)
    θ0[pμ+1] = log(0.4)
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ]))
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
end

function _phylo_mean_mode(kind, aux, η0, leaf_node, Q, logσ; b0 = nothing,
                          maxiter::Int = 60, tol::Real = 1e-8)
    q = size(Q, 1)
    b = b0 === nothing ? zeros(q) : copy(b0)
    invσ2 = exp(-2 * logσ)

    function joint(bb)
        s = zero(eltype(bb))
        @inbounds for i in eachindex(η0)
            η = η0[i] + bb[leaf_node[i]]
            s += _laplace_value(kind, aux, i, η)
        end
        return s + 0.5 * invσ2 * dot(bb, Q * bb)
    end

    ch = nothing
    iters = 0
    for iter in 1:maxiter
        iters = iter
        T = eltype(b)
        grad = zeros(T, q)
        diagH = zeros(Float64, q)
        all_w_nonneg = true
        @inbounds for i in eachindex(η0)
            li = leaf_node[i]
            η = η0[i] + b[li]
            r, w = _laplace_d12(kind, aux, i, η)
            grad[li] += r
            diagH[li] += w
            w < 0 && (all_w_nonneg = false)
        end
        grad .+= invσ2 .* (Q * b)
        Hmat = invσ2 .* Q + spdiagm(0 => diagH)
        ch = cholesky(Symmetric(Hmat); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        sn = norm(step)
        sn <= tol * (1 + norm(b)) && return b, ch, iters, true

        # Mirror the `_poisson_phylo_mode` basin fix: once inside the
        # quadratic-convergence basin (small step) the backtracking line search
        # STALLS on rounding-level decreases, leaving the mode only loosely
        # converged (~1e-6) and polluting the marginal FD gradient. Where the
        # data-term Hessian weights are all nonnegative the joint is locally
        # convex (binomial/nb2/gamma data terms have w ≥ 0 everywhere), so the
        # full Newton step in the basin is safe and drives the mode to ~`tol`.
        # For a family whose data weight can go negative (e.g. beta's d² is not
        # sign-definite) we fall back to the safeguarded line search — never an
        # unsafe full step.
        if all_w_nonneg && sn <= 1e-3 * (1 + norm(b))
            b = b .- step
        else
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
    end
    return b, ch, iters, ch !== nothing
end

function _phylo_mean_laplace_nuisance_fg(kind, aux_from, n::Int, Xμ, leaf_node,
                                         Q, logdetQ, θ; grad::Bool = false,
                                         b0 = nothing, newton_tol::Real = 1e-8,
                                         newton_maxiter::Int = 60)
    pμ = length(θ) - 2
    βμ = θ[1:pμ]
    θσ = clamp(θ[pμ+1], -8.0, 8.0)
    logσ = clamp(θ[pμ+2], -8.0, 3.0)
    aux = aux_from(θσ)
    η0 = Xμ * βμ
    b, ch, _, ok = _phylo_mean_mode(kind, aux, η0, leaf_node, Q, logσ; b0 = b0,
                                    tol = newton_tol, maxiter = newton_maxiter)
    if !ok
        return grad ? (1e18, zeros(length(θ)), b, false) : (1e18, b, false)
    end

    q = size(Q, 1)
    invσ2 = exp(-2 * logσ)
    data = zero(eltype(θ))
    prior = 0.5 * invσ2 * dot(b, Q * b)
    gradβ_raw = zeros(eltype(θ), pμ)
    dataν = zero(eltype(θ))
    wstore = Vector{eltype(θ)}(undef, n)
    tstore = Vector{eltype(θ)}(undef, n)
    rνstore = Vector{eltype(θ)}(undef, n)
    wνstore = Vector{eltype(θ)}(undef, n)
    @inbounds for i in 1:n
        η = η0[i] + b[leaf_node[i]]
        v, r, w, t, nval, nr, nw = _laplace_v123_nuisance(kind, aux, i, η)
        data += v
        wstore[i] = w
        tstore[i] = t
        dataν += nval
        rνstore[i] = nr
        wνstore[i] = nw
        for k in 1:pμ
            gradβ_raw[k] += Xμ[i, k] * r
        end
    end
    val = data + prior + q * logσ - 0.5 * logdetQ + 0.5 * logdet(ch)
    grad || return val, b, true

    S = takahashi_selinv(ch)
    hd = diag(S)
    traceSQ = _sparse_trace_product(S, Q)
    tlogdet = zeros(eltype(θ), q)
    crossβ = zeros(eltype(θ), q, pμ)
    crossν = zeros(eltype(θ), q)
    gβ = gradβ_raw
    gnuis = dataν
    @inbounds for i in 1:n
        li = leaf_node[i]
        lever = hd[li]
        tlever = tstore[i] * lever
        tlogdet[li] += tlever
        adj = 0.5 * tlever
        gnuis += 0.5 * wνstore[i] * lever
        crossν[li] += rνstore[i]
        for k in 1:pμ
            xik = Xμ[i, k]
            gβ[k] += xik * adj
            crossβ[li, k] += wstore[i] * xik
        end
    end
    implicit = ch \ tlogdet
    @inbounds for k in 1:pμ
        gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
    end
    gnuis -= 0.5 * dot(crossν, implicit)
    Qb = Q * b
    Pu = invσ2 .* Qb
    gσ = q - invσ2 * (dot(b, Qb) + traceSQ) + dot(implicit, Pu)
    return val, vcat(gβ, [gnuis, gσ]), b, true
end

# Tree front end for the nuisance Laplace spine: resolve the tree to its
# root-conditioned augmented precision and delegate to the Q-generic core. The
# general-covariance front end (`_fit_*_relmat_laplace`) calls the same core with
# `_general_cov_setup` instead — the spine is identical once Q is in hand.
function _fit_phylo_mean_laplace_nuisance(fam, kind, aux_from, n::Int, Xμ, labels,
                                          tree, nmμ, nmσ, grp, g_tol; θβ0,
                                          θσ0::Real, sigma_scale,
                                          se::Bool = false,
                                          polish_iterations::Int = 0)
    Q, leaf_node, _ = _poisson_phylo_setup(tree, labels)
    return _fit_general_mean_laplace_nuisance(
        fam, kind, aux_from, n, Xμ, Q, leaf_node, nmμ, nmσ, grp, g_tol;
        θβ0 = θβ0, θσ0 = θσ0, sigma_scale = sigma_scale, se = se,
        polish_iterations = polish_iterations,
        prec_error = "phylo(1 | $grp) tree precision is not positive definite after root conditioning"
    )
end

# Q-generic core for a nuisance-parameter family (NB2/Gamma/Beta) with a single
# structured random intercept of arbitrary PD precision `Q` and observation→latent
# map `leaf_node`. Driven by the tree route (`_fit_phylo_mean_laplace_nuisance`)
# and the general-covariance route (`_fit_nb2_relmat_laplace` /
# `_fit_gamma_relmat_laplace`); the only difference is where `(Q, leaf_node)` come
# from. Exact O(p) implicit-logdet gradient and Takahashi log-det derivatives
# carry over unchanged from the phylo path.
function _fit_general_mean_laplace_nuisance(fam, kind, aux_from, n::Int, Xμ, Q,
                                            leaf_node, nmμ, nmσ, grp, g_tol; θβ0,
                                            θσ0::Real, sigma_scale,
                                            se::Bool = false,
                                            polish_iterations::Int = 0,
                                            prec_error::AbstractString = "structured(1 | $grp) precision is not positive definite")
    q = size(Q, 1)
    pμ = size(Xμ, 2)
    qchol = cholesky(Symmetric(Q); check = false)
    issuccess(qchol) || error(prec_error)
    logdetQ = logdet(qchol)
    last_b = zeros(q)

    function eval_laplace(θ; grad::Bool = false)
        if grad
            val, g, b, ok = _phylo_mean_laplace_nuisance_fg(
                kind, aux_from, n, Xμ, leaf_node, Q, logdetQ, θ; grad = true, b0 = last_b
            )
            if !ok
                val, g, b, ok = _phylo_mean_laplace_nuisance_fg(
                    kind, aux_from, n, Xμ, leaf_node, Q, logdetQ, θ;
                    grad = true, b0 = zeros(q)
                )
            end
            ok || return 1e18, zeros(length(θ))
            last_b .= b
            return val, g
        else
            val, b, ok = _phylo_mean_laplace_nuisance_fg(
                kind, aux_from, n, Xμ, leaf_node, Q, logdetQ, θ; grad = false, b0 = last_b
            )
            if !ok
                val, b, ok = _phylo_mean_laplace_nuisance_fg(
                    kind, aux_from, n, Xμ, leaf_node, Q, logdetQ, θ;
                    grad = false, b0 = zeros(q)
                )
            end
            ok || return 1e18
            last_b .= b
            return val
        end
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + 2)
    θ0[1:pμ] .= θβ0
    θ0[pμ+1] = θσ0
    θ0[pμ+2] = log(0.4)
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = if polish_iterations > 0
        try
            θp = Optim.minimizer(res_fast)
            odp = Optim.OnceDifferentiable(nll, grad!, θp)
            Optim.optimize(odp, θp, Optim.LBFGS(),
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+1), :resd => (pμ+2):(pμ+2)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    auxhat = aux_from(clamp(θ̂[pμ+1], -8.0, 8.0))
    means = Dict(:mu => [_laplace_mean(kind, dot(@view(Xμ[i, :]), θ̂[1:pμ])) for i in 1:n])
    obs = Dict(:mu => [_laplace_obs(kind, auxhat, i) for i in 1:n])
    scales = Dict(:sigma => fill(sigma_scale(θ̂[pμ+1]), n))
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
end

"""
    _phylo_mean_laplace_hetero_fg(kind, aux_from, n, Xμ, Xσ, leaf_node, Q, logdetQ, θ; …)

Heteroscedastic generalisation of `_phylo_mean_laplace_nuisance_fg` (#164): the
single scalar dispersion nuisance θσ is replaced by a per-observation
log-dispersion linear predictor `ησ = Xσ·βσ`, so θ = `[βμ(pμ); βσ(pσ); logσ]`.
`aux_from(ησ::Vector)` returns a per-observation aux whose dispersion is
`exp.(ησ)` (a vector kind, e.g. `Val(:nb2_hetero)`).

The σ-axis kernel derivatives (`nval, nr, nw`) are taken w.r.t. each
observation's `log r_i`, so the βσ gradient is the Xσ-chained version of the
scalar nuisance gradient: where the scalar code accumulates one `gnuis`, this
accumulates a `pσ`-vector `gν` with each per-observation contribution weighted
by `Xσ[i, k]`, and the implicit cross-term `crossν` becomes a `q × pσ` matrix —
structurally identical to how the mean axis already chains `r/w` through `Xμ`.
A one-column constant `Xσ` reproduces `_phylo_mean_laplace_nuisance_fg` exactly.
"""
function _phylo_mean_laplace_hetero_fg(kind, aux_from, n::Int, Xμ, Xσ, leaf_node,
                                       Q, logdetQ, θ; grad::Bool = false,
                                       b0 = nothing, newton_tol::Real = 1e-8,
                                       newton_maxiter::Int = 60)
    pσ = size(Xσ, 2)
    pμ = length(θ) - pσ - 1
    βμ = θ[1:pμ]
    βσ = θ[pμ+1:pμ+pσ]
    logσ = clamp(θ[pμ+pσ+1], -8.0, 3.0)
    ησ = clamp.(Xσ * βσ, -8.0, 8.0)
    aux = aux_from(ησ)
    η0 = Xμ * βμ
    b, ch, _, ok = _phylo_mean_mode(kind, aux, η0, leaf_node, Q, logσ; b0 = b0,
                                    tol = newton_tol, maxiter = newton_maxiter)
    if !ok
        return grad ? (1e18, zeros(length(θ)), b, false) : (1e18, b, false)
    end

    q = size(Q, 1)
    invσ2 = exp(-2 * logσ)
    data = zero(eltype(θ))
    prior = 0.5 * invσ2 * dot(b, Q * b)
    gradβ_raw = zeros(eltype(θ), pμ)
    gν = zeros(eltype(θ), pσ)
    wstore = Vector{eltype(θ)}(undef, n)
    tstore = Vector{eltype(θ)}(undef, n)
    rνstore = Vector{eltype(θ)}(undef, n)
    wνstore = Vector{eltype(θ)}(undef, n)
    @inbounds for i in 1:n
        η = η0[i] + b[leaf_node[i]]
        v, r, w, t, nval, nr, nw = _laplace_v123_nuisance(kind, aux, i, η)
        data += v
        wstore[i] = w
        tstore[i] = t
        rνstore[i] = nr
        wνstore[i] = nw
        for k in 1:pμ
            gradβ_raw[k] += Xμ[i, k] * r
        end
        for k in 1:pσ
            gν[k] += Xσ[i, k] * nval
        end
    end
    val = data + prior + q * logσ - 0.5 * logdetQ + 0.5 * logdet(ch)
    grad || return val, b, true

    S = takahashi_selinv(ch)
    hd = diag(S)
    traceSQ = _sparse_trace_product(S, Q)
    tlogdet = zeros(eltype(θ), q)
    crossβ = zeros(eltype(θ), q, pμ)
    crossν = zeros(eltype(θ), q, pσ)
    gβ = gradβ_raw
    @inbounds for i in 1:n
        li = leaf_node[i]
        lever = hd[li]
        tlever = tstore[i] * lever
        tlogdet[li] += tlever
        adj = 0.5 * tlever
        nadj = 0.5 * wνstore[i] * lever
        for k in 1:pμ
            xik = Xμ[i, k]
            gβ[k] += xik * adj
            crossβ[li, k] += wstore[i] * xik
        end
        for k in 1:pσ
            zik = Xσ[i, k]
            gν[k] += zik * nadj
            crossν[li, k] += zik * rνstore[i]
        end
    end
    implicit = ch \ tlogdet
    @inbounds for k in 1:pμ
        gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
    end
    @inbounds for k in 1:pσ
        gν[k] -= 0.5 * dot(@view(crossν[:, k]), implicit)
    end
    Qb = Q * b
    Pu = invσ2 .* Qb
    gσ = q - invσ2 * (dot(b, Qb) + traceSQ) + dot(implicit, Pu)
    return val, vcat(gβ, gν, [gσ]), b, true
end

function _fit_phylo_mean_laplace_hetero(fam, kind, aux_from, n::Int, Xμ, Xσ,
                                        labels, tree, nmμ, nmσ, grp, g_tol; θβ0,
                                        θσ0, sigma_scale, se::Bool = false,
                                        polish_iterations::Int = 0)
    Q, leaf_node, _ = _poisson_phylo_setup(tree, labels)
    q = size(Q, 1)
    pμ = size(Xμ, 2)
    pσ = size(Xσ, 2)
    qchol = cholesky(Symmetric(Q); check = false)
    issuccess(qchol) || error("phylo(1 | $grp) tree precision is not positive definite after root conditioning")
    logdetQ = logdet(qchol)
    last_b = zeros(q)

    function eval_laplace(θ; grad::Bool = false)
        if grad
            val, g, b, ok = _phylo_mean_laplace_hetero_fg(
                kind, aux_from, n, Xμ, Xσ, leaf_node, Q, logdetQ, θ; grad = true, b0 = last_b
            )
            if !ok
                val, g, b, ok = _phylo_mean_laplace_hetero_fg(
                    kind, aux_from, n, Xμ, Xσ, leaf_node, Q, logdetQ, θ;
                    grad = true, b0 = zeros(q)
                )
            end
            ok || return 1e18, zeros(length(θ))
            last_b .= b
            return val, g
        else
            val, b, ok = _phylo_mean_laplace_hetero_fg(
                kind, aux_from, n, Xμ, Xσ, leaf_node, Q, logdetQ, θ; grad = false, b0 = last_b
            )
            if !ok
                val, b, ok = _phylo_mean_laplace_hetero_fg(
                    kind, aux_from, n, Xμ, Xσ, leaf_node, Q, logdetQ, θ;
                    grad = false, b0 = zeros(q)
                )
            end
            ok || return 1e18
            last_b .= b
            return val
        end
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + pσ + 1)
    θ0[1:pμ] .= θβ0
    θ0[pμ+1:pμ+pσ] .= θσ0
    θ0[pμ+pσ+1] = log(0.4)
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = if polish_iterations > 0
        try
            θp = Optim.minimizer(res_fast)
            odp = Optim.OnceDifferentiable(nll, grad!, θp)
            Optim.optimize(odp, θp, Optim.LBFGS(),
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    ησ̂ = clamp.(Xσ * θ̂[pμ+1:pμ+pσ], -8.0, 8.0)
    auxhat = aux_from(ησ̂)
    means = Dict(:mu => [_laplace_mean(kind, dot(@view(Xμ[i, :]), θ̂[1:pμ])) for i in 1:n])
    obs = Dict(:mu => [_laplace_obs(kind, auxhat, i) for i in 1:n])
    scales = Dict(:sigma => [sigma_scale(ησ̂[i]) for i in 1:n])
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
end

function _phylo_mean_laplace_fg(kind, aux, n::Int, Xμ, leaf_node, Q, logdetQ, θ;
                                grad::Bool = false, b0 = nothing,
                                newton_tol::Real = 1e-8, newton_maxiter::Int = 60)
    pμ = length(θ) - 1
    βμ = θ[1:pμ]
    logσ = clamp(θ[pμ+1], -8.0, 3.0)
    η0 = Xμ * βμ
    b, ch, _, ok = _phylo_mean_mode(kind, aux, η0, leaf_node, Q, logσ; b0 = b0,
                                    tol = newton_tol, maxiter = newton_maxiter)
    if !ok
        return grad ? (1e18, zeros(length(θ)), b, false) : (1e18, b, false)
    end

    q = size(Q, 1)
    invσ2 = exp(-2 * logσ)
    data = zero(eltype(θ))
    prior = 0.5 * invσ2 * dot(b, Q * b)
    gradβ_raw = zeros(eltype(θ), pμ)
    wstore = Vector{eltype(θ)}(undef, n)
    tstore = Vector{eltype(θ)}(undef, n)
    @inbounds for i in 1:n
        η = η0[i] + b[leaf_node[i]]
        v, r, w, t = _laplace_v123(kind, aux, i, η)
        data += v
        wstore[i] = w
        tstore[i] = t
        for k in 1:pμ
            gradβ_raw[k] += Xμ[i, k] * r
        end
    end
    val = data + prior + q * logσ - 0.5 * logdetQ + 0.5 * logdet(ch)
    grad || return val, b, true

    S = takahashi_selinv(ch)
    hd = diag(S)
    traceSQ = _sparse_trace_product(S, Q)
    tlogdet = zeros(eltype(θ), q)
    crossβ = zeros(eltype(θ), q, pμ)
    gβ = gradβ_raw
    @inbounds for i in 1:n
        li = leaf_node[i]
        lever = hd[li]
        tlever = tstore[i] * lever
        tlogdet[li] += tlever
        adj = 0.5 * tlever
        for k in 1:pμ
            xik = Xμ[i, k]
            gβ[k] += xik * adj
            crossβ[li, k] += wstore[i] * xik
        end
    end
    implicit = ch \ tlogdet
    @inbounds for k in 1:pμ
        gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
    end
    Qb = Q * b
    Pu = invσ2 .* Qb
    gσ = q - invσ2 * (dot(b, Qb) + traceSQ) + dot(implicit, Pu)
    return val, vcat(gβ, [gσ]), b, true
end

function _fit_phylo_mean_laplace(fam, kind, aux, n::Int, Xμ, labels, tree, nmμ,
                                 grp, g_tol; θβ0, se::Bool = false,
                                 polish_iterations::Int = 0,
                                 scales = Dict{Symbol,Vector{Float64}}())
    Q, leaf_node, _ = _poisson_phylo_setup(tree, labels)
    q = size(Q, 1)
    pμ = size(Xμ, 2)
    qchol = cholesky(Symmetric(Q); check = false)
    issuccess(qchol) || error("phylo(1 | $grp) tree precision is not positive definite after root conditioning")
    logdetQ = logdet(qchol)
    last_b = zeros(q)

    function eval_laplace(θ; grad::Bool = false)
        if grad
            val, g, b, ok = _phylo_mean_laplace_fg(
                kind, aux, n, Xμ, leaf_node, Q, logdetQ, θ; grad = true, b0 = last_b
            )
            if !ok
                val, g, b, ok = _phylo_mean_laplace_fg(
                    kind, aux, n, Xμ, leaf_node, Q, logdetQ, θ;
                    grad = true, b0 = zeros(q)
                )
            end
            ok || return 1e18, zeros(length(θ))
            last_b .= b
            return val, g
        else
            val, b, ok = _phylo_mean_laplace_fg(
                kind, aux, n, Xμ, leaf_node, Q, logdetQ, θ; grad = false, b0 = last_b
            )
            if !ok
                val, b, ok = _phylo_mean_laplace_fg(
                    kind, aux, n, Xμ, leaf_node, Q, logdetQ, θ;
                    grad = false, b0 = zeros(q)
                )
            end
            ok || return 1e18
            last_b .= b
            return val
        end
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + 1)
    θ0[1:pμ] .= θβ0
    θ0[pμ+1] = log(0.4)
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = if polish_iterations > 0
        try
            θp = Optim.minimizer(res_fast)
            odp = Optim.OnceDifferentiable(nll, grad!, θp)
            Optim.optimize(odp, θp, Optim.LBFGS(),
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => [_laplace_mean(kind, dot(@view(Xμ[i, :]), θ̂[1:pμ])) for i in 1:n])
    obs = Dict(:mu => [_laplace_obs(kind, aux, i) for i in 1:n])
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
end

# Shared NB2 setup for the sparse-Laplace nuisance routes (phylo + general-cov):
# build the dispersion-dependent `aux_from`, the fixed-effect start and the
# method-of-moments dispersion start. Used so the tree and relmat fitters are
# numerically identical given the same precision Q. (Constant-σ path only; the
# covariate-dispersion #164 path builds its own per-observation aux in-place.)
function _nb2_laplace_setup(y, Xμ)
    yint = round.(Int, y)
    function aux_from(logsize)
        r = exp(clamp(logsize, -8.0, 8.0))
        lconst = [loggamma(yint[i] + r) - loggamma(r) - _logfactorial(yint[i]) for i in eachindex(yint)]
        return (y = Float64.(yint), size = r, lconst = lconst)
    end
    m = sum(y) / length(y)
    v = sum(abs2, y .- m) / max(length(y) - 1, 1)
    θσ0 = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
    return aux_from, _poisson_fixed_start(y, Xμ), θσ0
end

function _fit_nb2_phylo_laplace(fam, y, Xμ, Xσ, labels, tree, nmμ, nmσ, grp,
                                g_tol; se::Bool = true,
                                polish_iterations::Int = 0)
    if size(Xσ, 2) == 1 && all(x -> x == 1.0, @view Xσ[:, 1])
        # constant-σ (sigma ~ 1): shared setup with the relmat route (#271)
        aux_from, θβ0, θσ0 = _nb2_laplace_setup(y, Xμ)
        return _fit_phylo_mean_laplace_nuisance(
            fam, Val(:nb2_fixed), aux_from, length(y), Xμ, labels, tree, nmμ, nmσ,
            grp, g_tol; θβ0 = θβ0, θσ0 = θσ0,
            sigma_scale = exp, se = se, polish_iterations = polish_iterations
        )
    end
    # Covariate dispersion (#164): log-size is a per-observation linear predictor
    # ησ = Xσ·βσ. The hetero aux turns ησ into the per-observation size vector.
    yint = round.(Int, y)
    yf = Float64.(yint)
    m = sum(y) / length(y)
    v = sum(abs2, y .- m) / max(length(y) - 1, 1)
    function aux_from_hetero(ησ)
        r = exp.(clamp.(ησ, -8.0, 8.0))
        lconst = [loggamma(yf[i] + r[i]) - loggamma(r[i]) - _logfactorial(yint[i]) for i in eachindex(yint)]
        return (y = yf, size = r, lconst = lconst)
    end
    θσ0 = zeros(size(Xσ, 2))
    θσ0[1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))   # intercept; slopes 0
    return _fit_phylo_mean_laplace_hetero(
        fam, Val(:nb2_hetero), aux_from_hetero, length(y), Xμ, Xσ, labels, tree,
        nmμ, nmσ, grp, g_tol; θβ0 = _poisson_fixed_start(y, Xμ), θσ0 = θσ0,
        sigma_scale = exp, se = se, polish_iterations = polish_iterations
    )
end

"""
    _fit_nb2_relmat_laplace(fam, y, Xμ, Xσ, C, labels, nmμ, nmσ, grp, g_tol; se)

NB2 sparse-Laplace fit with a general user-supplied PD covariance `C` on the mean
random intercept (`relmat`/`animal`/`spatial(1 | grp)`), with the dispersion `θ`
(the `sigma` slot) a fixed nuisance parameter. Reuses the verified phylo nuisance
spine via [`_general_cov_setup`](@ref): the only difference from the phylo route
is that the prior precision comes from `C⁻¹` instead of the tree topology. Exact
O(p) gradient and Takahashi log-det derivatives carry over unchanged (#167).
"""
function _fit_nb2_relmat_laplace(fam, y, Xμ, Xσ, C, labels, nmμ, nmσ, grp,
                                 g_tol; se::Bool = true,
                                 polish_iterations::Int = 0)
    size(Xσ, 2) == 1 || error("_fit_nb2_relmat_laplace currently supports a constant sigma formula")
    all(x -> x == 1.0, @view Xσ[:, 1]) ||
        error("_fit_nb2_relmat_laplace currently supports a constant sigma formula")
    Q, leaf_node = _general_cov_setup(C, labels)
    aux_from, θβ0, θσ0 = _nb2_laplace_setup(y, Xμ)
    return _fit_general_mean_laplace_nuisance(
        fam, Val(:nb2_fixed), aux_from, length(y), Xμ, Q, leaf_node, nmμ, nmσ,
        grp, g_tol; θβ0 = θβ0, θσ0 = θσ0,
        sigma_scale = exp, se = se, polish_iterations = polish_iterations
    )
end

function _fit_binomial_phylo_laplace(fam, s, ntr, Xμ, labels, tree, nmμ, grp,
                                     g_tol; se::Bool = true,
                                     polish_iterations::Int = 0)
    sint = round.(Int, s)
    nint = round.(Int, ntr)
    logchoose = [_logfactorial(nint[i]) - _logfactorial(sint[i]) - _logfactorial(nint[i] - sint[i]) for i in eachindex(sint)]
    aux = (s = sint, ntr = nint, logchoose = logchoose)
    p̄ = clamp(sum(s) / max(sum(ntr), 1), 1e-4, 1 - 1e-4)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(p̄ / (1 - p̄))
    return _fit_phylo_mean_laplace(
        fam, Val(:binomial), aux, length(s), Xμ, labels, tree, nmμ, grp, g_tol;
        θβ0 = θβ0, se = se, polish_iterations = polish_iterations,
        scales = Dict(:trials => Float64.(nint))
    )
end

# Shared Gamma setup for the sparse-Laplace nuisance routes (phylo + general-cov):
# the shape-dependent `aux_from`, the fixed-effect start and the method-of-moments
# log-σ start (σ = 1/√α). Keeps the tree and relmat fitters identical given Q.
function _gamma_laplace_setup(y, Xμ)
    yv = Float64.(y)
    function aux_from(logsigma)
        α = exp(clamp(-2 * logsigma, -8.0, 8.0))
        lconst = [α * log(α) - loggamma(α) + (α - 1) * log(yv[i]) for i in eachindex(yv)]
        return (y = yv, shape = α, lconst = lconst)
    end
    ȳ = sum(yv) / length(yv)
    v = sum(abs2, yv .- ȳ) / max(length(yv) - 1, 1)
    α0 = max(ȳ^2 / max(v, eps()), 3.0)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(ȳ + eps())
    return aux_from, θβ0, -0.5 * log(α0)
end

function _fit_gamma_phylo_laplace(fam, y, Xμ, Xσ, labels, tree, nmμ, nmσ, grp,
                                  g_tol; se::Bool = true,
                                  polish_iterations::Int = 5)
    size(Xσ, 2) == 1 || error("_fit_gamma_phylo_laplace currently supports a constant sigma formula")
    all(x -> x == 1.0, @view Xσ[:, 1]) ||
        error("_fit_gamma_phylo_laplace currently supports a constant sigma formula")
    aux_from, θβ0, θσ0 = _gamma_laplace_setup(y, Xμ)
    return _fit_phylo_mean_laplace_nuisance(
        fam, Val(:gamma_fixed), aux_from, length(y), Xμ, labels, tree, nmμ, nmσ,
        grp, g_tol; θβ0 = θβ0, θσ0 = θσ0, sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
    )
end

"""
    _fit_gamma_relmat_laplace(fam, y, Xμ, Xσ, C, labels, nmμ, nmσ, grp, g_tol; se)

Gamma sparse-Laplace fit with a general user-supplied PD covariance `C` on the
mean random intercept (`relmat`/`animal`/`spatial(1 | grp)`), with the shape `α`
(via the `sigma` slot, σ = 1/√α) a fixed nuisance parameter. Reuses the verified
phylo nuisance spine via [`_general_cov_setup`](@ref); only the prior precision
differs (`C⁻¹` vs the tree topology). Exact O(p) gradient carries over (#167).
"""
function _fit_gamma_relmat_laplace(fam, y, Xμ, Xσ, C, labels, nmμ, nmσ, grp,
                                   g_tol; se::Bool = true,
                                   polish_iterations::Int = 5)
    size(Xσ, 2) == 1 || error("_fit_gamma_relmat_laplace currently supports a constant sigma formula")
    all(x -> x == 1.0, @view Xσ[:, 1]) ||
        error("_fit_gamma_relmat_laplace currently supports a constant sigma formula")
    Q, leaf_node = _general_cov_setup(C, labels)
    aux_from, θβ0, θσ0 = _gamma_laplace_setup(y, Xμ)
    return _fit_general_mean_laplace_nuisance(
        fam, Val(:gamma_fixed), aux_from, length(y), Xμ, Q, leaf_node, nmμ, nmσ,
        grp, g_tol; θβ0 = θβ0, θσ0 = θσ0, sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
    )
end

# Shared Beta setup for the sparse-Laplace nuisance routes (phylo + general-cov):
# the precision-dependent `aux_from` (φ = 1/σ², logit-transformed responses cached),
# the fixed-effect start and the method-of-moments log-σ start. Keeps the tree and
# relmat fitters numerically identical given the same precision Q.
function _beta_laplace_setup(y, Xμ)
    yv = Float64.(y)
    ylogit = log.(yv) .- log1p.(-yv)
    function aux_from(logsigma)
        φ = exp(clamp(-2 * logsigma, -8.0, 8.0))
        return (y = yv, precision = φ, ylogit = ylogit,
                lgammaφ = loggamma(φ), digammaφ = digamma(φ))
    end
    ȳ = clamp(sum(yv) / length(yv), 1e-4, 1 - 1e-4)
    v = sum(abs2, yv .- ȳ) / max(length(yv) - 1, 1)
    φ0 = max(ȳ * (1 - ȳ) / max(v, eps()) - 1, 0.5)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(ȳ / (1 - ȳ))
    return aux_from, θβ0, -0.5 * log(φ0)
end

function _fit_beta_phylo_laplace(fam, y, Xμ, Xσ, labels, tree, nmμ, nmσ, grp,
                                 g_tol; se::Bool = true,
                                 polish_iterations::Int = 0)
    size(Xσ, 2) == 1 || error("_fit_beta_phylo_laplace currently supports a constant sigma formula")
    all(x -> x == 1.0, @view Xσ[:, 1]) ||
        error("_fit_beta_phylo_laplace currently supports a constant sigma formula")
    aux_from, θβ0, θσ0 = _beta_laplace_setup(y, Xμ)
    return _fit_phylo_mean_laplace_nuisance(
        fam, Val(:beta_fixed), aux_from, length(y), Xμ, labels, tree, nmμ, nmσ,
        grp, g_tol; θβ0 = θβ0, θσ0 = θσ0, sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
    )
end

"""
    _fit_beta_relmat_laplace(fam, y, Xμ, Xσ, C, labels, nmμ, nmσ, grp, g_tol; se)

Beta sparse-Laplace fit with a general user-supplied PD covariance `C` on the mean
(logit) random intercept (`relmat`/`animal`/`spatial(1 | grp)`), with the precision
`φ` (via the `sigma` slot, σ = 1/√φ) a fixed nuisance parameter. Reuses the verified
phylo nuisance spine via [`_general_cov_setup`](@ref); only the prior precision
differs (`C⁻¹` vs the tree topology). Exact O(p) gradient carries over (#167).
"""
function _fit_beta_relmat_laplace(fam, y, Xμ, Xσ, C, labels, nmμ, nmσ, grp,
                                  g_tol; se::Bool = true,
                                  polish_iterations::Int = 0)
    size(Xσ, 2) == 1 || error("_fit_beta_relmat_laplace currently supports a constant sigma formula")
    all(x -> x == 1.0, @view Xσ[:, 1]) ||
        error("_fit_beta_relmat_laplace currently supports a constant sigma formula")
    Q, leaf_node = _general_cov_setup(C, labels)
    aux_from, θβ0, θσ0 = _beta_laplace_setup(y, Xμ)
    return _fit_general_mean_laplace_nuisance(
        fam, Val(:beta_fixed), aux_from, length(y), Xμ, Q, leaf_node, nmμ, nmσ,
        grp, g_tol; θβ0 = θβ0, θσ0 = θσ0, sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
    )
end

const CROSSED_SPARSE_Q_THRESHOLD = 512

function _crossed_dense_hessian(diagH, weights, gidx, G, hidx, Hh)
    q = G + Hh
    Hmat = zeros(Float64, q, q)
    @inbounds for j in 1:q
        Hmat[j, j] = diagH[j]
    end
    @inbounds for i in eachindex(weights)
        gi = gidx[i]
        hi = G + hidx[i]
        w = weights[i]
        Hmat[gi, hi] += w
        Hmat[hi, gi] += w
    end
    return Hmat
end

function _crossed_sparse_hessian(diagH, weights, gidx, G, hidx, Hh)
    n = length(weights)
    q = G + Hh
    rows = Vector{Int}(undef, q + 2n)
    cols = Vector{Int}(undef, q + 2n)
    vals = Vector{Float64}(undef, q + 2n)
    @inbounds for j in 1:q
        rows[j] = j
        cols[j] = j
        vals[j] = diagH[j]
    end
    offset = q
    @inbounds for i in 1:n
        gi = gidx[i]
        hi = G + hidx[i]
        w = weights[i]
        rows[offset + 2i - 1] = gi
        cols[offset + 2i - 1] = hi
        vals[offset + 2i - 1] = w
        rows[offset + 2i] = hi
        cols[offset + 2i] = gi
        vals[offset + 2i] = w
    end
    return sparse(rows, cols, vals, q, q)
end

function _crossed_hessian(diagH, weights, gidx, G, hidx, Hh)
    q = G + Hh
    q > CROSSED_SPARSE_Q_THRESHOLD ?
        _crossed_sparse_hessian(diagH, weights, gidx, G, hidx, Hh) :
        _crossed_dense_hessian(diagH, weights, gidx, G, hidx, Hh)
end

function _crossed_selected_inverse_entries(ch, gidx, G, hidx, Hh)
    q = G + Hh
    if !(ch isa SparseArrays.CHOLMOD.Factor)
        Hinv = ch \ Matrix{Float64}(I, q, q)
        hd = diag(Hinv)
        cross = Vector{Float64}(undef, length(gidx))
        @inbounds for i in eachindex(gidx)
            cross[i] = Hinv[gidx[i], G + hidx[i]]
        end
        return hd, cross
    end
    S = takahashi_selinv(ch)
    hd = diag(S)
    cross = Vector{Float64}(undef, length(gidx))
    @inbounds for i in eachindex(gidx)
        cross[i] = S[gidx[i], G + hidx[i]]
    end
    return hd, cross
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
        diagH = zeros(Float64, q)
        weights = Vector{Float64}(undef, length(y))
        @inbounds for i in eachindex(y)
            gi = gidx[i]
            hi = G + hidx[i]
            η = clamp(η0[i] + b[gi] + b[hi], -30.0, 30.0)
            μ = exp(η)
            r = μ - y[i]
            grad[gi] += r
            grad[hi] += r
            diagH[gi] += μ
            diagH[hi] += μ
            weights[i] = μ
        end
        @inbounds for j in 1:G
            grad[j] += invg * b[j]
            diagH[j] += invg
        end
        @inbounds for j in (G+1):q
            grad[j] += invh * b[j]
            diagH[j] += invh
        end
        Hmat = _crossed_hessian(diagH, weights, gidx, G, hidx, Hh)
        ch = cholesky(Symmetric(Hmat); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        sn = norm(step)
        sn <= tol * (1 + norm(b)) && return b, ch, iters, true

        # The crossed-Poisson joint is strictly convex in b (convex Poisson data
        # term + diagonal Gaussian prior), so the same fix as `_poisson_phylo_mode`
        # applies: inside the quadratic-convergence basin (small step) the full
        # Newton step is contractive, but the backtracking line search there STALLS
        # on rounding-level decreases and would exhaust, leaving the mode only
        # loosely converged (~1e-6) — which then shows up as finite-difference noise
        # in the marginal gradient. So in the basin take the FULL Newton step;
        # keep the safeguarded line search only far from the mode.
        if sn <= 1e-3 * (1 + norm(b))
            b = b .- step
        else
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
    end
    return b, ch, iters, ch !== nothing
end

"""
    _poisson_crossed_laplace_fg(y, Xμ, gidx, G, hidx, Hh, lf, θ; grad, b0, newton_tol, newton_maxiter)

Module-level f/g evaluation of the Poisson crossed-random-intercepts Laplace
marginal NLL at a single θ, used both by `_fit_poisson_crossed_intercepts_laplace`
and by the standing FD-vs-analytic gradient gate (#165). Hoisting it out of the
fit closure lets the gate drive a *controlled, tightly-converged, warm-started*
inner mode (the same recipe the q4 Q-gate / the Poisson-phylo gate use to reach
≤ 1e-6). Returns `(val[, grad], b, ok)`; on a non-PD inner solve `ok = false`.
"""
function _poisson_crossed_laplace_fg(y, Xμ, gidx, G, hidx, Hh, lf, θ;
                                     grad::Bool = false, b0 = nothing,
                                     newton_tol::Real = 1e-8, newton_maxiter::Int = 60)
    n = length(y)
    pμ = length(θ) - 2
    logσ = clamp.(θ[pμ+1:pμ+2], -8.0, 3.0)
    η0 = Xμ * θ[1:pμ]
    b, ch, _, ok = _poisson_crossed_mode(y, η0, gidx, G, hidx, Hh, logσ;
                                         b0 = b0, tol = newton_tol, maxiter = newton_maxiter)
    if !ok
        return grad ? (1e18, zeros(length(θ)), b, false) : (1e18, b, false)
    end
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
    grad || return val, b, true

    hd, crossinv = _crossed_selected_inverse_entries(ch, gidx, G, hidx, Hh)
    tlogdet = zeros(eltype(θ), G + Hh)             # Z' * (μ .* leverage)
    crossβ = zeros(eltype(θ), G + Hh, pμ)          # Z' * (μ .* Xβ_col)
    gβ = gradβ_raw
    @inbounds for i in eachindex(y)
        gi = gidx[i]
        hi = G + hidx[i]
        lever = hd[gi] + hd[hi] + 2 * crossinv[i]
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
    implicit = ch \ tlogdet
    @inbounds for k in 1:pμ
        gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
    end
    gσ1 = G - invg * (sum(abs2, @view b[1:G]) + sum(@view hd[1:G]))
    gσ2 = Hh - invh * (sum(abs2, @view b[G+1:G+Hh]) + sum(@view hd[G+1:G+Hh]))
    gσ1 += dot(@view(implicit[1:G]), invg .* @view(b[1:G]))
    gσ2 += dot(@view(implicit[G+1:G+Hh]), invh .* @view(b[G+1:G+Hh]))
    return val, vcat(gβ, [gσ1, gσ2]), b, true
end

function _fit_poisson_crossed_intercepts_laplace(fam::Poisson, y, Xμ, gidx, G, hidx, Hh,
                                                 nmμ, labels, g_tol; se::Bool = true,
                                                 polish_iterations::Int = 35)
    n = length(y)
    pμ = size(Xμ, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    last_b = zeros(G + Hh)

    function eval_laplace(θ; grad::Bool = false)
        if grad
            val, g, b, ok = _poisson_crossed_laplace_fg(
                y, Xμ, gidx, G, hidx, Hh, lf, θ; grad = true, b0 = last_b
            )
            if !ok
                val, g, b, ok = _poisson_crossed_laplace_fg(
                    y, Xμ, gidx, G, hidx, Hh, lf, θ; grad = true, b0 = zeros(G + Hh)
                )
            end
            ok || return 1e18, zeros(length(θ))
            last_b .= b
            return val, g
        else
            val, b, ok = _poisson_crossed_laplace_fg(
                y, Xμ, gidx, G, hidx, Hh, lf, θ; grad = false, b0 = last_b
            )
            if !ok
                val, b, ok = _poisson_crossed_laplace_fg(
                    y, Xμ, gidx, G, hidx, Hh, lf, θ; grad = false, b0 = zeros(G + Hh)
                )
            end
            ok || return 1e18
            last_b .= b
            return val
        end
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
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

        # Exact Laplace gradient via the implicit-function theorem (#165),
        # generalising the verified two-block crossed path
        # (`_fit_crossed_mean_laplace`) to K components. For Poisson the data
        # Hessian weight and its η-derivative coincide (d²ℓ = d³ℓ = μ), so a
        # single μ drives both the logdet term and the cross term.
        #
        # The marginal is  L(θ) = f(b̂,θ) + ½ logdet H,  H = Z'diag(μ)Z + P.
        # Because b̂ solves ∂f/∂b = 0, the total derivative splits into an
        # explicit part (b̂ held fixed) plus an implicit part through db̂/dθ:
        #   dL/dθ = ∂L/∂θ + (∂[½ logdet H]/∂b)·db̂/dθ,
        #   db̂/dθ = −H⁻¹ (∂²f/∂b∂θ).
        Hinv = ch \ Matrix{Float64}(I, size(Z, 2), size(Z, 2))
        ZH = Z * Hinv
        lever = vec(sum(ZH .* Z, dims = 2))              # zᵢ' H⁻¹ zᵢ  (exact)
        hd = diag(Hinv)

        # Explicit part (b̂ frozen): data score + ½ tr(H⁻¹ ∂H/∂θ).
        gβ = Vector(Xμ' * (μ .- y .+ 0.5 .* μ .* lever))
        gσ = zeros(K)
        @inbounds for j in eachindex(compid)
            k = compid[j]
            gσ[k] += -invvar[j] * b[j]^2 - invvar[j] * hd[j]
        end
        @inbounds for k in 1:K
            gσ[k] += Gks[k]
        end

        # Implicit part: tlogdet = ∂(2·½ logdet H)/∂b carrier = Z'(μ ⊙ lever),
        # implicit = H⁻¹ tlogdet, contracted against the mixed second
        # derivatives ∂²f/∂b∂β = Z'diag(μ)X and ∂²f/∂b∂logσ_k = −2 invvar b.
        tlogdet = Vector(Z' * (μ .* lever))
        implicit = Hinv * tlogdet
        crossβ = Matrix(Z' * (μ .* Xμ))                  # q × pμ
        @inbounds for k in 1:pμ
            gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
        end
        @inbounds for j in eachindex(compid)
            gσ[compid[j]] += implicit[j] * invvar[j] * b[j]
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
    res = if polish_iterations > 0
        try
            # Short polish on the exact gradient (no longer a finite-difference
            # step — the analytic gradient above is the true Laplace gradient).
            θp = Optim.minimizer(res_fast)
            odp = Optim.OnceDifferentiable(nll, grad!, θp)
            Optim.optimize(odp, θp, Optim.LBFGS(),
                           Optim.Options(g_tol = g_tol, iterations = polish_iterations))
        catch
            res_fast
        end
    else
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
    return _withnll(fit, nll, grad!)
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

function _laplace_nuisance_value(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    dldr = -(digamma(y + r) - digamma(r)) - log(r) - 1 + log(r + μ) + (y + r) / (r + μ)
    return r * dldr
end

function _laplace_nuisance_d1(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    return r * μ * (μ - y) / (r + μ)^2
end

function _laplace_nuisance_d2(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    return r * μ * ((y + 2r) / (r + μ)^2 - 2r * (y + r) / (r + μ)^3)
end

# ---- NB2 with a per-observation log-dispersion (`sigma ~ x`; #164) ----------
# Identical likelihood to `:nb2_fixed`, but the size r is a per-observation
# vector `aux.size[i] = exp(Xσ[i,:]·βσ)` rather than one scalar. Each nuisance
# derivative is the derivative w.r.t. that observation's `log r_i` (the σ-axis
# linear predictor), so the outer fitter can chain it by Xσ to a vector βσ
# gradient. With a one-column constant Xσ this reduces exactly to `:nb2_fixed`.
function _laplace_value(::Val{:nb2_hetero}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size[i]
    return -(aux.lconst[i] + y * log(μ) + r * log(r) - (y + r) * log(r + μ))
end

function _laplace_d12(::Val{:nb2_hetero}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size[i]
    den = r + μ
    return (y + r) * μ / den - y, (y + r) * r * μ / den^2
end

function _laplace_v123(::Val{:nb2_hetero}, aux, i, η)
    ηc = clamp(η, -30.0, 30.0)
    μ = exp(ηc)
    y = aux.y[i]
    r = aux.size[i]
    den = r + μ
    v = -(aux.lconst[i] + y * ηc + r * log(r) - (y + r) * log(den))
    d1 = (y + r) * μ / den - y
    d2 = (y + r) * r * μ / den^2
    d3 = (y + r) * r * μ * (r - μ) / den^3
    return v, d1, d2, d3
end

function _laplace_v123_nuisance(::Val{:nb2_hetero}, aux, i, η)
    ηc = clamp(η, -30.0, 30.0)
    μ = exp(ηc)
    y = aux.y[i]
    r = aux.size[i]
    den = r + μ
    v = -(aux.lconst[i] + y * ηc + r * log(r) - (y + r) * log(den))
    d1 = (y + r) * μ / den - y
    d2 = (y + r) * r * μ / den^2
    d3 = (y + r) * r * μ * (r - μ) / den^3
    dldr = -(digamma(y + r) - digamma(r)) - log(r) - 1 + log(den) + (y + r) / den
    nv = r * dldr
    nd1 = r * μ * (μ - y) / den^2
    nd2 = r * μ * ((y + 2r) / den^2 - 2r * (y + r) / den^3)
    return v, d1, d2, d3, nv, nd1, nd2
end

_laplace_mean(::Val{:nb2_hetero}, η) = exp(clamp(η, -30.0, 30.0))
_laplace_obs(::Val{:nb2_hetero}, aux, i) = aux.y[i]

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

function _laplace_nuisance_value(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    α = aux.shape
    dldα = -log(α) - 1 + digamma(α) - log(y) + log(μ) + y / μ
    return -2α * dldα
end

function _laplace_nuisance_d1(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    α = aux.shape
    return -2α * (1 - aux.y[i] / μ)
end

function _laplace_nuisance_d2(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    return -2 * aux.shape * aux.y[i] / μ
end

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

function _laplace_beta_nuisance_terms(aux, i, η)
    μ = _laplace_logistic(clamp(η, -30.0, 30.0))
    φ = aux.precision
    a = μ * φ
    b = (1 - μ) * φ
    y = aux.y[i]
    v = μ * (1 - μ)
    vp = v * (1 - 2μ)
    ta = trigamma(a)
    tb = trigamma(b)
    dA = digamma(a) - digamma(b) - aux.ylogit[i] + φ * (μ * ta - (1 - μ) * tb)
    dB = 2φ * (ta + tb) + φ^2 * (μ * polygamma(2, a) + (1 - μ) * polygamma(2, b))
    dL = -digamma(φ) + μ * digamma(a) + (1 - μ) * digamma(b) -
         μ * log(y) - (1 - μ) * log1p(-y)
    return φ, v, vp, dL, dA, dB
end

function _laplace_nuisance_value(::Val{:beta_fixed}, aux, i, η)
    φ, _, _, dL, _, _ = _laplace_beta_nuisance_terms(aux, i, η)
    return -2φ * dL
end

function _laplace_nuisance_d1(::Val{:beta_fixed}, aux, i, η)
    φ, v, _, _, dA, _ = _laplace_beta_nuisance_terms(aux, i, η)
    return -2φ * dA * v
end

function _laplace_nuisance_d2(::Val{:beta_fixed}, aux, i, η)
    φ, v, vp, _, dA, dB = _laplace_beta_nuisance_terms(aux, i, η)
    return -2φ * (dB * v^2 + dA * vp)
end

function _laplace_d12(kind, aux, i, η)
    return _laplace_d1(kind, aux, i, η), _laplace_d2(kind, aux, i, η)
end

function _laplace_v123(kind, aux, i, η)
    return (_laplace_value(kind, aux, i, η),
            _laplace_d1(kind, aux, i, η),
            _laplace_d2(kind, aux, i, η),
            _laplace_d3(kind, aux, i, η))
end

function _laplace_v123_nuisance(kind, aux, i, η)
    return (_laplace_value(kind, aux, i, η),
            _laplace_d1(kind, aux, i, η),
            _laplace_d2(kind, aux, i, η),
            _laplace_d3(kind, aux, i, η),
            _laplace_nuisance_value(kind, aux, i, η),
            _laplace_nuisance_d1(kind, aux, i, η),
            _laplace_nuisance_d2(kind, aux, i, η))
end

function _laplace_d12(::Val{:binomial}, aux, i, η)
    p = _laplace_logistic(clamp(η, -30.0, 30.0))
    w = aux.ntr[i] * p * (1 - p)
    return aux.ntr[i] * p - aux.s[i], w
end

function _laplace_v123(::Val{:binomial}, aux, i, η)
    p = _laplace_logistic(clamp(η, -30.0, 30.0))
    s = aux.s[i]
    n = aux.ntr[i]
    v = -(aux.logchoose[i] + s * log(p) + (n - s) * log1p(-p))
    w = n * p * (1 - p)
    return v, n * p - s, w, w * (1 - 2p)
end

function _laplace_d12(::Val{:nb2_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    y = aux.y[i]
    r = aux.size
    den = r + μ
    return (y + r) * μ / den - y, (y + r) * r * μ / den^2
end

function _laplace_v123(::Val{:nb2_fixed}, aux, i, η)
    ηc = clamp(η, -30.0, 30.0)
    μ = exp(ηc)
    y = aux.y[i]
    r = aux.size
    den = r + μ
    v = -(aux.lconst[i] + y * ηc + r * log(r) - (y + r) * log(den))
    d1 = (y + r) * μ / den - y
    d2 = (y + r) * r * μ / den^2
    d3 = (y + r) * r * μ * (r - μ) / den^3
    return v, d1, d2, d3
end

function _laplace_v123_nuisance(::Val{:nb2_fixed}, aux, i, η)
    ηc = clamp(η, -30.0, 30.0)
    μ = exp(ηc)
    y = aux.y[i]
    r = aux.size
    den = r + μ
    v = -(aux.lconst[i] + y * ηc + r * log(r) - (y + r) * log(den))
    d1 = (y + r) * μ / den - y
    d2 = (y + r) * r * μ / den^2
    d3 = (y + r) * r * μ * (r - μ) / den^3
    dldr = -(digamma(y + r) - digamma(r)) - log(r) - 1 + log(den) + (y + r) / den
    nv = r * dldr
    nd1 = r * μ * (μ - y) / den^2
    nd2 = r * μ * ((y + 2r) / den^2 - 2r * (y + r) / den^3)
    return v, d1, d2, d3, nv, nd1, nd2
end

function _laplace_d12(::Val{:gamma_fixed}, aux, i, η)
    μ = exp(clamp(η, -30.0, 30.0))
    αy_over_μ = aux.shape * aux.y[i] / μ
    return aux.shape - αy_over_μ, αy_over_μ
end

function _laplace_v123(::Val{:gamma_fixed}, aux, i, η)
    ηc = clamp(η, -30.0, 30.0)
    μ = exp(ηc)
    αy_over_μ = aux.shape * aux.y[i] / μ
    v = -(aux.lconst[i] - aux.shape * ηc - αy_over_μ)
    return v, aux.shape - αy_over_μ, αy_over_μ, -αy_over_μ
end

function _laplace_v123_nuisance(::Val{:gamma_fixed}, aux, i, η)
    ηc = clamp(η, -30.0, 30.0)
    μ = exp(ηc)
    y = aux.y[i]
    α = aux.shape
    αy_over_μ = α * y / μ
    v = -(aux.lconst[i] - α * ηc - αy_over_μ)
    d1 = α - αy_over_μ
    d2 = αy_over_μ
    d3 = -αy_over_μ
    dldα = -log(α) - 1 + digamma(α) - log(y) + ηc + y / μ
    return v, d1, d2, d3, -2α * dldα, -2α * (1 - y / μ), -2α * y / μ
end

function _laplace_d12(::Val{:beta_fixed}, aux, i, η)
    μ = _laplace_logistic(clamp(η, -30.0, 30.0))
    φ = aux.precision
    a = μ * φ
    b = (1 - μ) * φ
    A = φ * (digamma(a) - digamma(b) - aux.ylogit[i])
    B = φ^2 * (trigamma(a) + trigamma(b))
    v = μ * (1 - μ)
    vp = v * (1 - 2μ)
    return A * v, B * v^2 + A * vp
end

function _laplace_v123(::Val{:beta_fixed}, aux, i, η)
    μ, A, B, C, v, vp, vpp = _laplace_beta_terms(aux, i, η)
    φ = aux.precision
    a = μ * φ
    b = (1 - μ) * φ
    y = aux.y[i]
    value = -(aux.lgammaφ - loggamma(a) - loggamma(b) +
              (a - 1) * log(y) + (b - 1) * log1p(-y))
    return value, A * v, B * v^2 + A * vp, C * v^3 + 3 * B * v * vp + A * vpp
end

_laplace_beta_digamma_precision(aux) =
    hasproperty(aux, :digammaφ) ? aux.digammaφ : digamma(aux.precision)

function _laplace_v123_nuisance(::Val{:beta_fixed}, aux, i, η)
    μ = _laplace_logistic(clamp(η, -30.0, 30.0))
    φ = aux.precision
    a = μ * φ
    b = (1 - μ) * φ
    y = aux.y[i]
    logy = log(y)
    log1my = log1p(-y)
    da = digamma(a)
    db = digamma(b)
    ta = trigamma(a)
    tb = trigamma(b)
    p2a = polygamma(2, a)
    p2b = polygamma(2, b)
    v = μ * (1 - μ)
    u = 1 - 2μ
    vp = v * u
    vpp = v * u^2 - 2v^2
    A = φ * (da - db - aux.ylogit[i])
    B = φ^2 * (ta + tb)
    C = φ^3 * (p2a - p2b)
    value = -(aux.lgammaφ - loggamma(a) - loggamma(b) +
              (a - 1) * logy + (b - 1) * log1my)
    dL = -_laplace_beta_digamma_precision(aux) + μ * da + (1 - μ) * db -
         μ * logy - (1 - μ) * log1my
    dA = da - db - aux.ylogit[i] + φ * (μ * ta - (1 - μ) * tb)
    dB = 2φ * (ta + tb) + φ^2 * (μ * p2a + (1 - μ) * p2b)
    return (value,
            A * v,
            B * v^2 + A * vp,
            C * v^3 + 3 * B * v * vp + A * vpp,
            -2φ * dL,
            -2φ * dA * v,
            -2φ * (dB * v^2 + dA * vp))
end

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
        diagH = zeros(Float64, q)
        weights = Vector{Float64}(undef, length(η0))
        all_w_nonneg = true
        @inbounds for i in eachindex(η0)
            gi = gidx[i]
            hi = G + hidx[i]
            η = η0[i] + b[gi] + b[hi]
            r, w = _laplace_d12(kind, aux, i, η)
            grad[gi] += r
            grad[hi] += r
            diagH[gi] += w
            diagH[hi] += w
            weights[i] = w
            w < 0 && (all_w_nonneg = false)
        end
        @inbounds for j in 1:G
            grad[j] += invg * b[j]
            diagH[j] += invg
        end
        @inbounds for j in (G+1):q
            grad[j] += invh * b[j]
            diagH[j] += invh
        end
        Hmat = _crossed_hessian(diagH, weights, gidx, G, hidx, Hh)
        ch = cholesky(Symmetric(Hmat); check = false)
        issuccess(ch) || return b, ch, iters, false
        step = ch \ grad
        sn = norm(step)
        sn <= tol * (1 + norm(b)) && return b, ch, iters, true

        # Same convexity-gated full-Newton-in-basin fix as `_phylo_mean_mode` /
        # `_poisson_crossed_mode`: avoid the line search stalling on rounding-level
        # decreases near the mode when the data term is locally convex.
        if all_w_nonneg && sn <= 1e-3 * (1 + norm(b))
            b = b .- step
        else
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
            v, r, w, t = _laplace_v123(kind, aux, i, η)
            data += v
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

        hd, crossinv = _crossed_selected_inverse_entries(ch, gidx, G, hidx, Hh)
        tlogdet = zeros(eltype(θ), G + Hh)
        crossβ = zeros(eltype(θ), G + Hh, pμ)
        gβ = gradβ_raw
        @inbounds for i in 1:n
            gi = gidx[i]
            hi = G + hidx[i]
            lever = hd[gi] + hd[hi] + 2 * crossinv[i]
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
        implicit = ch \ tlogdet
        @inbounds for k in 1:pμ
            gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
        end
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
end

function _crossed_mean_laplace_nuisance_fg(kind, aux_from, n::Int, Xμ, gidx, G,
                                           hidx, Hh, θ; grad::Bool = false,
                                           b0 = nothing)
    pμ = length(θ) - 3
    βμ = θ[1:pμ]
    θσ = clamp(θ[pμ+1], -8.0, 8.0)
    logσ = clamp.(θ[pμ+2:pμ+3], -8.0, 3.0)
    aux = aux_from(θσ)
    η0 = Xμ * βμ
    b, ch, _, ok = _crossed_mean_mode(kind, aux, η0, gidx, G, hidx, Hh, logσ; b0 = b0)
    if !ok
        return grad ? (1e18, zeros(length(θ)), b, false) : (1e18, b, false)
    end

    invg = exp(-2 * logσ[1])
    invh = exp(-2 * logσ[2])
    data = zero(eltype(θ))
    prior = 0.5 * invg * sum(abs2, @view b[1:G]) +
            0.5 * invh * sum(abs2, @view b[G+1:G+Hh])
    gradβ_raw = zeros(eltype(θ), pμ)
    dataν = zero(eltype(θ))
    wstore = Vector{eltype(θ)}(undef, n)
    tstore = Vector{eltype(θ)}(undef, n)
    rνstore = Vector{eltype(θ)}(undef, n)
    wνstore = Vector{eltype(θ)}(undef, n)
    @inbounds for i in 1:n
        η = η0[i] + b[gidx[i]] + b[G+hidx[i]]
        v, r, w, t, nval, nr, nw = _laplace_v123_nuisance(kind, aux, i, η)
        data += v
        wstore[i] = w
        tstore[i] = t
        dataν += nval
        rνstore[i] = nr
        wνstore[i] = nw
        for k in 1:pμ
            gradβ_raw[k] += Xμ[i, k] * r
        end
    end
    val = data + prior + G * logσ[1] + Hh * logσ[2] + 0.5 * logdet(ch)
    grad || return val, b, true

    hd, crossinv = _crossed_selected_inverse_entries(ch, gidx, G, hidx, Hh)
    tlogdet = zeros(eltype(θ), G + Hh)
    crossβ = zeros(eltype(θ), G + Hh, pμ)
    crossν = zeros(eltype(θ), G + Hh)
    gβ = gradβ_raw
    gnuis = dataν
    @inbounds for i in 1:n
        gi = gidx[i]
        hi = G + hidx[i]
        lever = hd[gi] + hd[hi] + 2 * crossinv[i]
        tlever = tstore[i] * lever
        tlogdet[gi] += tlever
        tlogdet[hi] += tlever
        adj = 0.5 * tlever
        gnuis += 0.5 * wνstore[i] * lever
        crossν[gi] += rνstore[i]
        crossν[hi] += rνstore[i]
        for k in 1:pμ
            xik = Xμ[i, k]
            gβ[k] += xik * adj
            crossβ[gi, k] += wstore[i] * xik
            crossβ[hi, k] += wstore[i] * xik
        end
    end
    implicit = ch \ tlogdet
    @inbounds for k in 1:pμ
        gβ[k] -= 0.5 * dot(@view(crossβ[:, k]), implicit)
    end
    gnuis -= 0.5 * dot(crossν, implicit)
    gσ1 = G - invg * (sum(abs2, @view b[1:G]) + sum(@view hd[1:G]))
    gσ2 = Hh - invh * (sum(abs2, @view b[G+1:G+Hh]) + sum(@view hd[G+1:G+Hh]))
    gσ1 += dot(@view(implicit[1:G]), invg .* @view(b[1:G]))
    gσ2 += dot(@view(implicit[G+1:G+Hh]), invh .* @view(b[G+1:G+Hh]))
    return val, vcat(gβ, [gnuis, gσ1, gσ2]), b, true
end

function _fit_crossed_mean_laplace_nuisance(fam, kind, aux_from, n::Int, Xμ, gidx, G,
                                            hidx, Hh, nmμ, nmσ, labels, g_tol;
                                            θβ0, θσ0::Real, sigma_scale,
                                            se::Bool = false,
                                            polish_iterations::Int = 0)
    pμ = size(Xμ, 2)
    last_b = zeros(G + Hh)

    function eval_laplace(θ; grad::Bool = false)
        if grad
            val, g, b, ok = _crossed_mean_laplace_nuisance_fg(
                kind, aux_from, n, Xμ, gidx, G, hidx, Hh, θ; grad = true, b0 = last_b
            )
            if !ok
                val, g, b, ok = _crossed_mean_laplace_nuisance_fg(
                    kind, aux_from, n, Xμ, gidx, G, hidx, Hh, θ;
                    grad = true, b0 = zeros(G + Hh)
                )
            end
            ok || return 1e18, zeros(length(θ))
            last_b .= b
            return val, g
        else
            val, b, ok = _crossed_mean_laplace_nuisance_fg(
                kind, aux_from, n, Xμ, gidx, G, hidx, Hh, θ; grad = false, b0 = last_b
            )
            if !ok
                val, b, ok = _crossed_mean_laplace_nuisance_fg(
                    kind, aux_from, n, Xμ, gidx, G, hidx, Hh, θ;
                    grad = false, b0 = zeros(G + Hh)
                )
            end
            ok || return 1e18
            last_b .= b
            return val
        end
    end

    nll(θ) = eval_laplace(θ; grad = false)
    function grad!(Gout, θ)
        _, g = eval_laplace(θ; grad = true)
        Gout .= g
        return Gout
    end

    θ0 = zeros(pμ + 3)
    θ0[1:pμ] .= θβ0
    θ0[pμ+1] = θσ0
    θ0[pμ+2] = log(0.4)
    θ0[pμ+3] = log(0.4)
    od = Optim.OnceDifferentiable(nll, grad!, θ0)
    method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
    res_fast = Optim.optimize(od, θ0, method, Optim.Options(g_tol = g_tol, iterations = 250))
    res = if polish_iterations > 0
        try
            θp = Optim.minimizer(res_fast)
            odp = Optim.OnceDifferentiable(nll, grad!, θp)
            Optim.optimize(odp, θp, Optim.LBFGS(),
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
    nllhat = nll(θ̂)
    converged = _laplace_outer_converged(res, nllhat, gfinal, θ̂, n, g_tol)
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
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+1), :resd => (pμ+2):(pμ+3)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => labels]
    auxhat = aux_from(clamp(θ̂[pμ+1], -8.0, 8.0))
    means = Dict(:mu => [_laplace_mean(kind, dot(@view(Xμ[i, :]), θ̂[1:pμ])) for i in 1:n])
    obs = Dict(:mu => [_laplace_obs(kind, auxhat, i) for i in 1:n])
    scales = Dict(:sigma => fill(sigma_scale(θ̂[pμ+1]), n))
    fit = DrmFit(fam, blocks, names, θ̂, Matrix(V), -nllhat, n, converged, means, obs, scales)
    return _withnll(fit, nll, grad!)
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

function _fit_nb2_crossed_laplace(fam, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol;
                                  se::Bool = false, polish_iterations::Int = 0)
    length(comps) == 2 || error("_fit_nb2_crossed_laplace requires two random-intercept components")
    size(Xσ, 2) == 1 || error("_fit_nb2_crossed_laplace currently supports a constant sigma formula")
    yint = round.(Int, y)
    function aux_from(logsize)
        r = exp(clamp(logsize, -8.0, 8.0))
        lconst = [loggamma(yint[i] + r) - loggamma(r) - _logfactorial(yint[i]) for i in eachindex(yint)]
        return (y = Float64.(yint), size = r, lconst = lconst)
    end
    m = sum(y) / length(y)
    v = sum(abs2, y .- m) / max(length(y) - 1, 1)
    θσ0 = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
    return _fit_crossed_mean_laplace_nuisance(
        fam, Val(:nb2_fixed), aux_from, length(y), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, nmσ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = _poisson_fixed_start(y, Xμ), θσ0 = θσ0, sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
    )
end

function _fit_gamma_crossed_laplace(fam, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol;
                                    se::Bool = false, polish_iterations::Int = 5)
    length(comps) == 2 || error("_fit_gamma_crossed_laplace requires two random-intercept components")
    size(Xσ, 2) == 1 || error("_fit_gamma_crossed_laplace currently supports a constant sigma formula")
    yv = Float64.(y)
    function aux_from(logsigma)
        α = exp(clamp(-2 * logsigma, -8.0, 8.0))
        lconst = [α * log(α) - loggamma(α) + (α - 1) * log(yv[i]) for i in eachindex(yv)]
        return (y = yv, shape = α, lconst = lconst)
    end
    ȳ = sum(yv) / length(yv)
    v = sum(abs2, yv .- ȳ) / max(length(yv) - 1, 1)
    α0 = max(ȳ^2 / max(v, eps()), 3.0)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(ȳ + eps())
    return _fit_crossed_mean_laplace_nuisance(
        fam, Val(:gamma_fixed), aux_from, length(yv), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, nmσ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, θσ0 = -0.5 * log(α0), sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
    )
end

function _fit_beta_crossed_laplace(fam, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol;
                                   se::Bool = false, polish_iterations::Int = 0)
    length(comps) == 2 || error("_fit_beta_crossed_laplace requires two random-intercept components")
    size(Xσ, 2) == 1 || error("_fit_beta_crossed_laplace currently supports a constant sigma formula")
    yv = Float64.(y)
    ylogit = log.(yv) .- log1p.(-yv)
    function aux_from(logsigma)
        φ = exp(clamp(-2 * logsigma, -8.0, 8.0))
        return (y = yv, precision = φ, ylogit = ylogit,
                lgammaφ = loggamma(φ), digammaφ = digamma(φ))
    end
    ȳ = clamp(sum(yv) / length(yv), 1e-4, 1 - 1e-4)
    v = sum(abs2, yv .- ȳ) / max(length(yv) - 1, 1)
    φ0 = max(ȳ * (1 - ȳ) / max(v, eps()) - 1, 0.5)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(ȳ / (1 - ȳ))
    return _fit_crossed_mean_laplace_nuisance(
        fam, Val(:beta_fixed), aux_from, length(yv), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, nmσ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, θσ0 = -0.5 * log(φ0), sigma_scale = exp,
        se = se, polish_iterations = polish_iterations
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
                                          se::Bool = false, polish_iterations::Int = 5)
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
    aux = (y = yv, precision = φ, ylogit = ylogit,
           lgammaφ = loggamma(φ), digammaφ = digamma(φ))
    ȳ = clamp(sum(yv) / length(yv), 1e-4, 1 - 1e-4)
    θβ0 = zeros(size(Xμ, 2))
    θβ0[1] = log(ȳ / (1 - ȳ))
    return _fit_crossed_mean_laplace(
        fam, Val(:beta_fixed), aux, length(yv), Xμ, comps[1][2], comps[1][3],
        comps[2][2], comps[2][3], nmμ, [comps[1][4], comps[2][4]], g_tol;
        θβ0 = θβ0, se = se, polish_iterations = polish_iterations
    )
end
