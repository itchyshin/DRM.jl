# Private paired whitening route for the q=2 non-Gaussian location--scale
# Laplace problem. Coupled public fits opt into this paired route; unmigrated
# raw-P value and gradient consumers continue together on their existing route.
#
# With a = (I_G ⊗ L) z, the prior is Q ⊗ I₂ and the per-observation loadings
# are Wη = ZηL and Wψ = ZψL.  All objective, derivative, and adjoint work below
# remains in z coordinates.  The original-coordinate residual is calculated
# only for the final certificate; a rounded a vector is never fed back into a
# computation or used as a warm-state certificate.

using LinearAlgebra: Symmetric, cholesky, issuccess, norm, dot, opnorm, logdet, issymmetric, SingularException
using SparseArrays: sparse, SparseMatrixCSC, nonzeros, findnz, nzrange

const _LS_WHITENED_I2 = sparse([1, 2], [1, 2], [1.0, 1.0], 2, 2)

"""Owned transformed warm start; acceptance is intentionally not stored."""
struct _LSWhitenedSeed
    z::Vector{Float64}
    L::Matrix{Float64}
    theta::Vector{Float64}
    function _LSWhitenedSeed(z::AbstractVector{<:Real}, L::AbstractMatrix{<:Real},
                             theta::AbstractVector{<:Real})
        size(L) == (2, 2) || throw(ArgumentError("whitened seed L must be 2×2"))
        length(z) % 2 == 0 || throw(ArgumentError("whitened seed z must have even length"))
        return new(Float64.(z), Matrix{Float64}(L), Float64.(theta))
    end
end

_ls_whitened_fail(theta, reason; initial_z = Float64[], first_white_ok = false,
                  second_white_ok = false, attempts = 0) =
    (value = Inf, gradient = fill(NaN, length(theta)), seed = nothing,
     status = (; ok = false, reason, initial_z, first_white_ok, second_white_ok,
               attempts, original_residual = Inf, original_bound = NaN,
               undamped_hpd = false, inside_clamp = false,
               selected_inverse_blocks = NTuple{3, Float64}[]))

function _ls_whitened_L(theta, pμ, pψ)
    length(theta) == pμ + pψ + 3 || return nothing
    u, c, v = theta[pμ + pψ + 1:pμ + pψ + 3]
    L = [exp(u) 0.0; c exp(v)]
    all(isfinite, L) && L[1, 1] > 0 && L[2, 2] > 0 || return nothing
    return L
end

function _ls_whitened_initial(seed, L, G)
    if seed === nothing
        return zeros(Float64, 2G), :cold
    elseif seed isa _LSWhitenedSeed
        length(seed.z) == 2G && size(seed.L) == (2, 2) &&
            all(isfinite, seed.z) && all(isfinite, seed.L) || return nothing
        T = L \ seed.L
        all(isfinite, T) || return nothing
        z = similar(seed.z)
        @inbounds for g in 1:G
            ix = 2g-1:2g
            z[ix] .= T * view(seed.z, ix)
        end
        return all(isfinite, z) ? (z, :typed) : nothing
    elseif seed isa AbstractVector
        length(seed) == 2G && all(isfinite, seed) || return nothing
        # Compatibility only: a legacy vector contributes an initial z guess.
        # It carries no acceptance state and is re-certified at current theta.
        z = Vector{Float64}(undef, 2G)
        @inbounds for g in 1:G
            ix = 2g-1:2g
            z[ix] .= L \ Float64.(view(seed, ix))
        end
        return all(isfinite, z) ? (z, :legacy_vector) : nothing
    end
    return nothing
end

function _ls_whitened_inside(kind, η0, ψ0, gidx, z, Wη, Wψ)
    (kind isa Val{:gamma} || kind isa Val{:nb2} || kind isa Val{:beta} ||
     kind isa Val{:betabinomial}) || return false
    @inbounds for i in eachindex(gidx)
        g = gidx[i]; ix = 2g-1:2g
        η = η0[i] + dot(view(Wη, i, :), view(z, ix))
        ψ = ψ0[i] + dot(view(Wψ, i, :), view(z, ix))
        (isfinite(η) && isfinite(ψ) && -LS_CLAMP < η < LS_CLAMP) || return false
        if kind isa Val{:gamma}
            -LS_CLAMP < ψ < LS_CLAMP || return false
        else
            -LS_CLAMP < -2 * ψ < LS_CLAMP || return false
        end
    end
    return true
end

# `P + D` drops exact stored zeros.  For an unobserved c=0 group this can
# remove its within-group off-diagonal from CHOLMOD's symbolic pattern even
# though the inverse entry is nonzero through other groups' data coupling.
function _ls_whitened_block_pattern(H::SparseMatrixCSC{Float64, Int}, G)
    rows, cols, vals = findnz(H)
    rows, cols, vals = copy(rows), copy(cols), copy(vals)
    @inbounds for g in 1:G
        i, j = 2g - 1, 2g
        push!(rows, i); push!(cols, i); push!(vals, 0.0)
        push!(rows, j); push!(cols, j); push!(vals, 0.0)
        push!(rows, i); push!(cols, j); push!(vals, 0.0)
        push!(rows, j); push!(cols, i); push!(vals, 0.0)
    end
    patterned = sparse(rows, cols, vals, size(H)...)
    norm(patterned - H) == 0.0 || error("whitened structural rebuild changed Hessian values")
    return patterned
end

function _ls_whitened_has_block_slots(S::SparseMatrixCSC{Float64, Int}, G)
    @inbounds for g in 1:G
        i, j = 2g - 1, 2g
        any(S.rowval[p] == i for p in nzrange(S, j)) || return false
        any(S.rowval[p] == j for p in nzrange(S, i)) || return false
    end
    return true
end

function _ls_whitened_original_certificate(kind, y, η0, ψ0, gidx, G, Pz,
                                            Wη, Wψ, L, z)
    all(isfinite, z) ||
        return (ok = false, residual = Inf, bound = NaN, inside = false, gradient = Float64[], ch = nothing)
    # This is deliberately fresh: inner acceptance at a white tolerance cannot
    # stand in for the current original-coordinate Hessian certificate.
    rawH = _ls_joint_hess(kind, y, η0, ψ0, gidx, G, z, Pz, Wη, Wψ)
    _ls_allfinite(rawH) ||
        return (ok = false, residual = Inf, bound = NaN, inside = false, gradient = Float64[], ch = nothing)
    H = _ls_whitened_block_pattern(rawH, G)
    ch = cholesky(Symmetric(H); check = false)
    issuccess(ch) ||
        return (ok = false, residual = Inf, bound = NaN, inside = false, gradient = Float64[], ch)
    gz = _ls_joint_grad(kind, y, η0, ψ0, gidx, z, Pz, Wη, Wψ)
    all(isfinite, gz) ||
        return (ok = false, residual = Inf, bound = NaN, inside = false, gradient = gz, ch)
    ga2 = 0.0; a2 = 0.0
    @inbounds for g in 1:G
        ix = 2g-1:2g
        # Per-group 2-vectors preserve the implicit a = Lz representation.
        ablock = L * view(z, ix)
        gablock = transpose(L) \ view(gz, ix)
        a2 += dot(ablock, ablock)
        ga2 += dot(gablock, gablock)
    end
    residual, anorm = sqrt(ga2), sqrt(a2)
    bound = 1e-9 * (1 + anorm)
    inside = _ls_whitened_inside(kind, η0, ψ0, gidx, z, Wη, Wψ)
    good = all(isfinite, (residual, anorm, bound)) && residual <= bound && inside
    return (ok = good, residual, bound, inside, gradient = gz, ch)
end

_ls_whitened_yfinite(y) = all(v -> v isa Tuple ? all(isfinite, v) : isfinite(v), y)

function _ls_whitened_state_norm(L, z, G)
    total = 0.0
    @inbounds for g in 1:G
        block = L * view(z, 2g-1:2g)
        total += dot(block, block)
    end
    return sqrt(total)
end

function _ls_whitened_block(Hinv, g)
    i, j = 2g - 1, 2g
    return Hinv[i, i], Hinv[i, j], Hinv[j, j]
end

function _ls_whitened_obs(kind, y, η0, ψ0, gidx, z, Wη, Wψ, i)
    g = gidx[i]; ix = 2g-1:2g
    W = [Wη[i, 1] Wη[i, 2]; Wψ[i, 1] Wψ[i, 2]]
    η = η0[i] + dot(view(Wη, i, :), view(z, ix))
    ψ = ψ0[i] + dot(view(Wψ, i, :), view(z, ix))
    h11, h12, h22 = _ls_hess(kind, y[i], η, ψ)
    D = [h11 h12; h12 h22]
    score = collect(_ls_grad(kind, y[i], η, ψ))
    return g, ix, W, D, score, η, ψ
end

function _ls_whitened_gradient(kind, y, Xμ, Xψ, Zη, Zψ, η0, ψ0, gidx, G, theta,
                               z, ch, Wη, Wψ, L)
    Hinv = takahashi_selinv(ch)
    _ls_whitened_has_block_slots(Hinv, G) || return nothing
    blocks = Vector{NTuple{3, Float64}}(undef, G)
    @inbounds for g in 1:G
        blocks[g] = _ls_whitened_block(Hinv, g)
    end
    all(isfinite, Iterators.flatten(blocks)) || return nothing

    adj = zeros(Float64, 2G)
    @inbounds for i in eachindex(y)
        g, ix, W, _, _, η, ψ = _ls_whitened_obs(kind, y, η0, ψ0, gidx, z, Wη, Wψ, i)
        s11, s12, s22 = blocks[g]
        R11 = W[1, 1]^2 * s11 + 2 * W[1, 1] * W[1, 2] * s12 + W[1, 2]^2 * s22
        R12 = W[1, 1] * W[2, 1] * s11 +
              (W[1, 1] * W[2, 2] + W[1, 2] * W[2, 1]) * s12 + W[1, 2] * W[2, 2] * s22
        R22 = W[2, 1]^2 * s11 + 2 * W[2, 1] * W[2, 2] * s12 + W[2, 2]^2 * s22
        t1, t2, t3, t4 = _ls_third(kind, y[i], η, ψ)
        κ1 = (t1 * R11 + 2 * t2 * R12 + t3 * R22) / 2
        κ2 = (t2 * R11 + 2 * t3 * R12 + t4 * R22) / 2
        adj[ix] .+= transpose(W) * [κ1, κ2]
    end
    all(isfinite, adj) || return nothing
    w = ch \ adj
    all(isfinite, w) || return nothing

    pμ, pψ = size(Xμ, 2), size(Xψ, 2)
    grad = zeros(Float64, length(theta))
    dLs = ([L[1, 1] 0.0; 0.0 0.0], [0.0 0.0; 1.0 0.0],
           [0.0 0.0; 0.0 L[2, 2]])
    @inbounds for i in eachindex(y)
        g, ix, W, D, score, _, _ = _ls_whitened_obs(kind, y, η0, ψ0, gidx, z, Wη, Wψ, i)
        s11, s12, s22 = blocks[g]
        R11 = W[1, 1]^2 * s11 + 2 * W[1, 1] * W[1, 2] * s12 + W[1, 2]^2 * s22
        R12 = W[1, 1] * W[2, 1] * s11 +
              (W[1, 1] * W[2, 2] + W[1, 2] * W[2, 1]) * s12 + W[1, 2] * W[2, 2] * s22
        R22 = W[2, 1]^2 * s11 + 2 * W[2, 1] * W[2, 2] * s12 + W[2, 2]^2 * s22
        t1, t2, t3, t4 = _ls_third(kind, y[i],
                                    η0[i] + dot(view(Wη, i, :), view(z, ix)),
                                    ψ0[i] + dot(view(Wψ, i, :), view(z, ix)))
        κ = [(t1 * R11 + 2 * t2 * R12 + t3 * R22) / 2,
             (t2 * R11 + 2 * t3 * R12 + t4 * R22) / 2]
        r = score + κ - D * (W * view(w, ix))
        grad[1:pμ] .+= view(Xμ, i, :) .* r[1]
        grad[pμ+1:pμ+pψ] .+= view(Xψ, i, :) .* r[2]
        Z = [Zη[i, 1] Zη[i, 2]; Zψ[i, 1] Zψ[i, 2]]
        for k in 1:3
            dW = Z * dLs[k]
            # tr((D W S_g)' dW), expressed with the retained 2×2 block only.
            WS = [W[1, 1] * s11 + W[1, 2] * s12 W[1, 1] * s12 + W[1, 2] * s22;
                  W[2, 1] * s11 + W[2, 2] * s12 W[2, 1] * s12 + W[2, 2] * s22]
            grad[pμ+pψ+k] += dot(r, dW * view(z, ix)) -
                               dot(score, dW * view(w, ix)) + sum((D * WS) .* dW)
        end
    end
    return all(isfinite, grad) ? (gradient = grad, selected_inverse_blocks = blocks) : nothing
end

"""
    _ls_whitened_eval(kind, y, Xμ, Xψ, gidx, G, Q, theta, Zη, Zψ;
                      seed=nothing, gradient=true)

Private paired value/gradient route in whitened latent coordinates.  A returned
seed is an owned initial guess only: every invocation re-solves and certifies at
its current `theta`, `Q`, data, and loadings.
"""
function _ls_whitened_eval(kind, y, Xμ, Xψ, gidx, G, Q, theta, Zη, Zψ;
                           seed = nothing, gradient::Bool = true)
    pμ, pψ = size(Xμ, 2), size(Xψ, 2)
    theta64 = Float64.(theta)
    L = _ls_whitened_L(theta64, pμ, pψ)
    L === nothing && return _ls_whitened_fail(theta64, :invalid_theta)
    (Q isa SparseMatrixCSC{Float64, Int} && size(Q) == (G, G) &&
     length(y) == length(gidx) == size(Xμ, 1) == size(Xψ, 1) == size(Zη, 1) == size(Zψ, 1) &&
     size(Zη, 2) == 2 && size(Zψ, 2) == 2 && issymmetric(Q) && all(isfinite, nonzeros(Q)) &&
     _ls_whitened_yfinite(y) && all(isfinite, Xμ) && all(isfinite, Xψ) && all(isfinite, Zη) && all(isfinite, Zψ) &&
     all(g -> 1 <= g <= G, gidx)) || return _ls_whitened_fail(theta64, :invalid_input)
    initial = _ls_whitened_initial(seed, L, G)
    initial === nothing && return _ls_whitened_fail(theta64, :invalid_seed)
    z0, seed_kind = initial
    chQ = cholesky(Symmetric(Q); check = false)
    issuccess(chQ) || return _ls_whitened_fail(theta64, :non_pd_Q; initial_z = z0)
    Pz = kron(Q, _LS_WHITENED_I2)
    η0, ψ0 = Xμ * view(theta64, 1:pμ), Xψ * view(theta64, pμ+1:pμ+pψ)
    Wη, Wψ = Matrix{Float64}(Zη * L), Matrix{Float64}(Zψ * L)
    all(isfinite, η0) && all(isfinite, ψ0) && all(isfinite, Wη) && all(isfinite, Wψ) ||
        return _ls_whitened_fail(theta64, :nonfinite_predictor_basis; initial_z = z0)

    invLnorm = opnorm(L \ Matrix{Float64}(I, 2, 2))
    tol1 = min(1e-9, 1e-9 / max(invLnorm, 1.0))
    (isfinite(tol1) && tol1 > 0) || return _ls_whitened_fail(theta64, :invalid_transform; initial_z = z0)
    z, _, first_white_ok = _ls_inner_mode(kind, y, η0, ψ0, gidx, G, Pz, Wη, Wψ;
                                            a0 = z0, tol = tol1)
    cert = _ls_whitened_original_certificate(kind, y, η0, ψ0, gidx, G, Pz, Wη, Wψ, L, z)
    second_white_ok = false
    attempts = 1
    if !cert.ok
        C = max(invLnorm, 1.0)
        tol2 = min(tol1 / 2, 1e-9 * (1 + _ls_whitened_state_norm(L, z, G)) /
                                (4 * C * (1 + norm(z))))
        (isfinite(tol2) && tol2 > 0) || return _ls_whitened_fail(theta64, :invalid_second_tolerance;
                                                                   initial_z = copy(z), first_white_ok = first_white_ok,
                                                                   attempts = attempts)
        z, _, second_white_ok = _ls_inner_mode(kind, y, η0, ψ0, gidx, G, Pz, Wη, Wψ;
                                                 a0 = z, tol = tol2)
        cert = _ls_whitened_original_certificate(kind, y, η0, ψ0, gidx, G, Pz, Wη, Wψ, L, z)
        attempts = 2
    end
    cert.ok || return _ls_whitened_fail(theta64, :uncertified_current_state; initial_z = copy(z),
                                         first_white_ok = first_white_ok, second_white_ok = second_white_ok,
                                         attempts = attempts)
    value = _ls_joint(kind, y, η0, ψ0, gidx, z, Pz, Wη, Wψ) + logdet(cert.ch) / 2 - logdet(chQ)
    isfinite(value) || return _ls_whitened_fail(theta64, :nonfinite_value; initial_z = copy(z),
                                                 first_white_ok = first_white_ok, second_white_ok = second_white_ok,
                                                 attempts = attempts)
    result = gradient ? _ls_whitened_gradient(kind, y, Xμ, Xψ, Zη, Zψ, η0, ψ0, gidx, G, theta64,
                                                z, cert.ch, Wη, Wψ, L) : nothing
    gradient && result === nothing && return _ls_whitened_fail(theta64, :gradient_failure; initial_z = copy(z),
                                                                 first_white_ok = first_white_ok,
                                                                 second_white_ok = second_white_ok, attempts = attempts)
    owned_seed = _LSWhitenedSeed(z, L, theta64)
    status = (; ok = true, reason = :certified_current_state, seed_kind, initial_z = copy(z0),
              first_white_ok, second_white_ok, attempts, original_residual = cert.residual,
              original_bound = cert.bound, undamped_hpd = true, inside_clamp = cert.inside,
              selected_inverse_blocks = gradient ? result.selected_inverse_blocks : NTuple{3, Float64}[],
              transformed_state = copy(z), L = copy(L))
    return (value, gradient = gradient ? result.gradient : nothing, seed = owned_seed, status)
end

# A finite-difference probe must never share a mutable warm state with another
# probe.  `_LSWhitenedSeed` is already owned at construction, but copy it again
# here because the two perturbed theta evaluations are independent numerical
# problems.  Legacy vectors retain their initial-guess-only compatibility.
function _ls_whitened_seed_copy(seed)
    seed === nothing && return nothing
    seed isa _LSWhitenedSeed && return _LSWhitenedSeed(seed.z, seed.L, seed.theta)
    seed isa AbstractVector && return copy(seed)
    return seed                         # evaluated as an invalid seed, never mutated
end

_ls_whitened_unusable_information(p) = Symmetric(fill(NaN, p, p))

"""
    _ls_whitened_information(kind, y, Xμ, Xψ, gidx, G, Q, theta,
                              Zη=canonical, Zψ=canonical; h=1e-5, seed=nothing)

Observed information for the private paired whitening route.  This has the
same central-difference and symmetrisation contract as `_ls_obs_information`,
but every `theta ± h e_k` call receives a separately owned initial-guess seed.
Failure of either certified paired evaluation makes the whole information
matrix unusable (all `NaN`), rather than mixing paired and legacy gradients.
"""
function _ls_whitened_information(kind, y, Xμ, Xψ, gidx, G, Q, theta,
                                  Zη = _ls_canonical_Zeta(length(y)),
                                  Zψ = _ls_canonical_Zpsi(length(y));
                                  h::Real = 1e-5, seed = nothing)
    θ = Float64.(theta)
    p = length(θ)
    H = zeros(Float64, p, p)
    @inbounds for k in 1:p
        θp = copy(θ); θp[k] += h
        θm = copy(θ); θm[k] -= h
        plus = _ls_whitened_eval(kind, y, Xμ, Xψ, gidx, G, Q, θp, Zη, Zψ;
                                 seed = _ls_whitened_seed_copy(seed))
        minus = _ls_whitened_eval(kind, y, Xμ, Xψ, gidx, G, Q, θm, Zη, Zψ;
                                  seed = _ls_whitened_seed_copy(seed))
        (!plus.status.ok || !minus.status.ok || plus.gradient === nothing ||
         minus.gradient === nothing || !all(isfinite, plus.gradient) ||
         !all(isfinite, minus.gradient)) && return _ls_whitened_unusable_information(p)
        H[:, k] .= (plus.gradient .- minus.gradient) ./ (2h)
    end
    return all(isfinite, H) ? Symmetric((H + H') ./ 2) : _ls_whitened_unusable_information(p)
end

"""
    _ls_whitened_vcov(args...; kwargs...)

Wald covariance from private paired observed information. Singular information
returns `nothing`, as in `_ls_vcov`; failed/non-finite paired information is
also refused explicitly instead of passing it to matrix inversion.
"""
function _ls_whitened_vcov(kind, y, Xμ, Xψ, gidx, G, Q, theta,
                            Zη = _ls_canonical_Zeta(length(y)),
                            Zψ = _ls_canonical_Zpsi(length(y));
                            h::Real = 1e-5, seed = nothing)
    H = _ls_whitened_information(kind, y, Xμ, Xψ, gidx, G, Q, theta, Zη, Zψ;
                                  h = h, seed = seed)
    all(isfinite, Matrix(H)) || return nothing
    return try
        inv(Matrix(H))
    catch err
        err isa SingularException ? nothing : rethrow(err)
    end
end
