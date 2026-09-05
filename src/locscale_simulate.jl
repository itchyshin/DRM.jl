# Marginal response simulation for the canonical coupled non-Gaussian
# location--scale route.  This is private bootstrap plumbing: it never changes
# public coefficient packing, fit acceptance, or the conditional `simulate` API.

using LinearAlgebra: Symmetric, UpperTriangular, cholesky, issuccess
using SparseArrays: sparse, SparseMatrixCSC

struct _LSMarginalBootstrapState{Kind}
    kind::Kind
    Xmu::Matrix{Float64}
    Xpsi::Matrix{Float64}
    gidx::Vector{Int}
    U::SparseMatrixCSC{Float64,Int}
    perm::Vector{Int}
    L::Matrix{Float64}
    beta_mu::Vector{Float64}
    beta_psi::Vector{Float64}
end

function _ls_bootstrap_family_matches(kind, family)
    return (kind isa Val{:gamma} && family isa Gamma) ||
           (kind isa Val{:nb2} && family isa NegBinomial2) ||
           (kind isa Val{:beta} && family isa Beta) ||
           (kind isa Val{:betabinomial} && family isa BetaBinomial)
end

function _ls_bootstrap_same_response(a, b)
    length(a) == length(b) || return false
    @inbounds for i in eachindex(a, b)
        isequal(a[i], b[i]) || return false
    end
    return true
end

function _ls_bootstrap_same_matrix(a, b)
    size(a) == size(b) || return false
    @inbounds for j in axes(a, 2), i in axes(a, 1)
        isequal(a[i, j], b[i, j]) || return false
    end
    return true
end

function _ls_bootstrap_same_sparse(a, b)
    size(a) == size(b) || return false
    return a == b
end

function _ls_bootstrap_prepared_state(fit::DrmFit, data;
                                      K=nothing, A=nothing, tree=nothing, coords=nothing)
    fit.nll isa LocScaleObjective ||
        throw(ArgumentError("coupled location-scale bootstrap requires a LocScaleObjective"))
    fit.formula isa DrmFormula ||
        throw(ArgumentError("coupled location-scale bootstrap requires the original formula"))
    obj = fit.nll::LocScaleObjective
    _ls_bootstrap_family_matches(obj.kind, fit.family) ||
        throw(ArgumentError("coupled location-scale bootstrap family does not match its stored objective"))

    rhs = Dict(fit.formula.forms)
    haskey(rhs, :mu) && haskey(rhs, :sigma) ||
        throw(ArgumentError("coupled location-scale bootstrap requires mu and sigma formulas"))
    lc = _ls_coupled_re(rhs[:mu], rhs[:sigma])
    lc === nothing && throw(ArgumentError("coupled location-scale bootstrap requires a shared coupled random effect"))

    # Rebuild every public input from the supplied rows before touching the
    # stored objective.  A bootstrap response must never be joined to an old
    # gidx after the caller reorders, truncates, or changes rows.
    y, Xmu, Xpsi, _, _, _, trials = _ls_frontend_design(obj.kind, fit.formula, lc, data)
    _ls_bootstrap_same_response(y, obj.y) ||
        throw(ArgumentError("coupled location-scale bootstrap data response differs from the fitted objective"))
    _ls_bootstrap_same_matrix(Xmu, obj.Xμ) ||
        throw(ArgumentError("coupled location-scale bootstrap mean design differs from the fitted objective"))
    _ls_bootstrap_same_matrix(Xpsi, obj.Xψ) ||
        throw(ArgumentError("coupled location-scale bootstrap sigma design differs from the fitted objective"))
    if obj.kind isa Val{:betabinomial}
        stored_trials = get(fit.scales, :trials, nothing)
        stored_trials !== nothing && trials !== nothing && stored_trials == trials ||
            throw(ArgumentError("coupled location-scale bootstrap trials differ from the fitted objective"))
    end
    Q, gidx, G = _ls_frontend_grouping(lc, data, tree, K, A, coords)
    G == obj.G && gidx == obj.gidx ||
        throw(ArgumentError("coupled location-scale bootstrap group map differs from the fitted objective"))
    _ls_bootstrap_same_sparse(Q, obj.Q) ||
        throw(ArgumentError("coupled location-scale bootstrap precision differs from the fitted objective"))

    beta_mu = Vector{Float64}(coef(fit, :mu))
    beta_psi = Vector{Float64}(coef(fit, :sigma))
    length(beta_mu) == size(obj.Xμ, 2) && length(beta_psi) == size(obj.Xψ, 2) ||
        throw(ArgumentError("coupled location-scale bootstrap fixed-effect packing differs from the fitted objective"))
    recov = Vector{Float64}(coef(fit, :recov))
    length(recov) == 3 ||
        throw(ArgumentError("coupled location-scale bootstrap requires three recov coefficients"))
    L = [exp(recov[1]) 0.0; recov[3] exp(recov[2])]
    all(isfinite, L) && L[1, 1] > 0 && L[2, 2] > 0 ||
        throw(ArgumentError("coupled location-scale bootstrap recov loading is not finite positive-Cholesky"))

    # Freeze only immutable sparse numeric data and its permutation.  CHOLMOD's
    # factor is deliberately not retained: every replicate allocates its own
    # solve workspace and effects matrix.
    qfactor = cholesky(Symmetric(obj.Q); check=false)
    issuccess(qfactor) || throw(ArgumentError("coupled location-scale bootstrap precision is not positive definite"))
    U = sparse(transpose(sparse(qfactor.L)))
    perm = Vector{Int}(qfactor.p)
    length(perm) == obj.G || throw(ArgumentError("coupled location-scale bootstrap precision permutation has wrong length"))
    return _LSMarginalBootstrapState(obj.kind, copy(Matrix{Float64}(obj.Xμ)), copy(Matrix{Float64}(obj.Xψ)),
        copy(obj.gidx), copy(U), copy(perm), copy(L), copy(beta_mu), copy(beta_psi))
end

"""Draw group-by-axis effects using a frozen sparse triangular precision factor."""
function _ls_bootstrap_effect(state::_LSMarginalBootstrapState, rng)
    G = length(state.perm)
    E = randn(rng, G, 2)
    Bperm = UpperTriangular(state.U) \ E
    B = zeros(Float64, G, 2)
    B[state.perm, :] = Bperm
    return B * transpose(state.L)
end

function _ls_marginal_simulator(fit::DrmFit, data;
                                K=nothing, A=nothing, tree=nothing, coords=nothing)
    state = _ls_bootstrap_prepared_state(fit, data; K, A, tree, coords)
    gamma_kind = state.kind isa Val{:gamma}
    psilim = gamma_kind ? LS_CLAMP : LS_PSI_CLAMP
    return function (rng)
        effects = _ls_bootstrap_effect(state, rng)
        eta = state.Xmu * state.beta_mu .+ effects[state.gidx, 1]
        psi = state.Xpsi * state.beta_psi .+ effects[state.gidx, 2]
        mu = _mean_response(fit.family, eta)
        sigma = exp.(clamp.(psi, -psilim, psilim))
        all(isfinite, mu) && all(isfinite, sigma) ||
            throw(ArgumentError("coupled location-scale bootstrap produced nonfinite predictors"))
        return _simulate_once(fit, rng; mu, sigma)
    end
end
