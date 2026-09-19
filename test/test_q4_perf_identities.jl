# test_q4_perf_identities.jl -- leaf-S5 identity gates for the q=4 bivariate
# phylo ML route's three performance changes (cholesky! reuse, warm u0 into
# _q4_fd_vcov, closed-form logdet P). Pins numbers measured on ORIGINAL
# (pre-S5) origin/main (90fbb0e28) so each change is checked as a provable
# identity, never a "close enough" re-measurement. Tolerances match the
# ledger (.unlazy/julia-speed-20260919/gates/leaf-S5.md) exactly and are never
# widened.
#
# G5.4 (cholesky!-reuse fallback count) and G5.6 (full Pkg.test()) live
# elsewhere (bench/profile_q4_sections.jl --gate fallback; `Pkg.test()`); this
# file does not duplicate them.
#
# Usage:
#   env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. \
#       test/test_q4_perf_identities.jl --gate {nll|logdet|newton|vcov}
#   include("test/test_q4_perf_identities.jl")   # runs all four as a @testset
#
# G5.3's "inner-Newton iteration counts and accepted ridge lambda sequence"
# are measured by a SHADOW copy of _estep_robust's cold-start loop (verbatim
# transcription from src/sparse_aug_plsm.jl on 90fbb0e28), calling through to
# the REAL (unrenamed, unwrapped) sparse_pd_chol/build_Huu/build_Huu_expected/
# joint_nll/joint_grad. The shadow's own control flow never changes across S5
# -- only what sparse_pd_chol does internally does -- so re-running the SAME
# shadow after change (b) is a direct, apples-to-apples check that the
# cholesky!-reuse path reproduces the exact same Newton trajectory.

using DRModels
using Test, LinearAlgebra, SparseArrays, Random, Statistics, Printf

# -----------------------------------------------------------------------------
# Case generator -- VERBATIM from bench/head_to_head_q4_scaling.jl's `_make_case`
# (G5.1's CHECK names this file's generator explicitly). Copied, not included,
# because that file's `main()` runs unconditionally at file scope.
# -----------------------------------------------------------------------------

const βT_ID = (mu1 = [1.0, 0.5], mu2 = [-0.3, 0.4], s1 = [-0.4], s2 = [-0.5], rho = [0.3])
const ΛT_ID = Matrix(Symmetric([0.25 0.10 0.05 0.00; 0.10 0.25 0.00 0.04; 0.05 0.00 0.09 0.02; 0.00 0.04 0.02 0.09]))
const Λ0_ID = Matrix(Symmetric([0.30 0.02 0.01 0.010; 0.02 0.30 0.01 0.010; 0.01 0.01 0.08 0.005; 0.01 0.01 0.005 0.080]))

function _id_balanced_edges(p::Integer; branch_length::Real = 0.2)
    edges = Tuple{Int,Int,Float64}[]
    current_level = collect(1:p)
    next_id = p + 1
    while length(current_level) > 1
        next_level = Int[]
        i = 1
        while i <= length(current_level)
            if i == length(current_level)
                push!(next_level, current_level[i]); break
            end
            parent = next_id; next_id += 1
            push!(edges, (parent, current_level[i], Float64(branch_length)))
            push!(edges, (parent, current_level[i + 1], Float64(branch_length)))
            push!(next_level, parent); i += 2
        end
        current_level = next_level
    end
    root = only(current_level)
    return _id_ultrametricize(edges, p, root), root
end

function _id_ultrametricize(edges::Vector{Tuple{Int,Int,Float64}}, n_leaves::Integer, root::Integer)
    parent_of = Dict{Int,Tuple{Int,Float64}}()
    for (parent, child, blen) in edges
        parent_of[child] = (parent, blen)
    end
    function depth(node::Int)
        node == root && return 0.0
        par, blen = parent_of[node]
        return depth(par) + blen
    end
    depths = [depth(t) for t in 1:n_leaves]
    target = maximum(depths)
    out = Tuple{Int,Int,Float64}[]
    for (parent, child, blen) in edges
        if child <= n_leaves
            push!(out, (parent, child, blen + (target - depths[child])))
        else
            push!(out, (parent, child, blen))
        end
    end
    return out
end

function _id_sample_augmented_state(rng::AbstractRNG, phy, Q_cond)
    P = prior_precision(Q_cond, inv(ΛT_ID))
    F = cholesky(Symmetric(P))
    return F.UP \ randn(rng, size(P, 1))
end

"Balanced-tree q4 case, VERBATIM DGP from bench/head_to_head_q4_scaling.jl's `_make_case`."
function id_make_case(p::Integer; seed::Integer, nrep::Integer = 4)
    rng = MersenneTwister(seed)
    edges, root = _id_balanced_edges(p; branch_length = 0.2)
    leaf_names = ["L$t" for t in 1:p]
    phy = DRModels.make_phy(edges, p; root_index = root, leaf_names = leaf_names)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    Q_cond = phy.Q_topology[keep, keep]
    u_aug = _id_sample_augmented_state(rng, phy, Q_cond)

    pos = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [pos[phy.leaf_indices[t]] for t in 1:p]
    U = Matrix{Float64}(undef, 4, p)
    @inbounds for k in 1:p, a in 1:4
        U[a, k] = u_aug[4 * (leaf_pos[k] - 1) + a]
    end

    species = repeat(1:p, inner = nrep)
    n = length(species)
    x1 = randn(rng, n)
    X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
    Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)
    y1 = Vector{Float64}(undef, n); y2 = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        k = species[i]
        m1 = dot(@view(X1[i, :]), βT_ID.mu1) + U[1, k]
        m2 = dot(@view(X2[i, :]), βT_ID.mu2) + U[2, k]
        s1 = exp(dot(@view(Xs1[i, :]), βT_ID.s1) + U[3, k])
        s2 = exp(dot(@view(Xs2[i, :]), βT_ID.s2) + U[4, k])
        ρ = DRModels.RHO_GUARD * tanh(dot(@view(Xr[i, :]), βT_ID.rho))
        e = cholesky(Symmetric([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2])).L * randn(rng, 2)
        y1[i] = m1 + e[1]; y2[i] = m2 + e[2]
    end

    prob, Q = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr; species = species)
    β0 = (
        mu1 = X1 \ y1, mu2 = X2 \ y2,
        s1 = [log(std(y1 .- X1 * (X1 \ y1)))], s2 = [log(std(y2 .- X2 * (X2 \ y2)))],
        rho = [0.0],
    )
    return (; prob, Q, β0, p, n)
end

_id_seed(p::Integer) = 37600 + p   # matches head_to_head_q4_scaling.jl's own seed formula

# -----------------------------------------------------------------------------
# G5.1: marginal NLL at fixed theta0, pinned from origin/main (90fbb0e28),
# n_newton = 40, theta0 = pack_theta(beta0, Lambda0_ID).
# -----------------------------------------------------------------------------

const NLL_PINNED = Dict(100 => 865.03857291814597, 1000 => 10371.799176493616)

function gate_nll(; verbose::Bool = true)
    ok = true
    for p in (100, 1000)
        case = id_make_case(p; seed = _id_seed(p))
        θ0 = pack_theta(case.β0, Λ0_ID)
        nll, = marginal_nll(case.prob, case.Q, θ0; n_newton = 40)
        pinned = NLL_PINNED[p]
        rel = abs(nll - pinned) / abs(pinned)
        this_ok = rel <= 1e-12
        verbose && @printf "  p=%d nll=%.17g pinned=%.17g rel=%.3e %s\n" p nll pinned rel (this_ok ? "OK" : "FAIL")
        ok &= this_ok
    end
    return ok
end

# -----------------------------------------------------------------------------
# G5.2: closed-form logdet P vs the factorised logdet P, on 20 random Lambda
# (log-Cholesky draws) at FIXED Q_cond, p=100 and p=1000. Pure math identity --
# does not depend on which src/ implementation is currently active, so it is
# meaningful before change (a) exists (verifying the formula itself) and after
# (verifying the landed code uses it correctly).
#
# det(kron(Q_cond, Lambda^{-1})) = det(Q_cond)^4 * det(Lambda^{-1})^N
#   => logdet(P) = 4*logdet(Q_cond) - N*logdet(Lambda)     (N = prob.n_total)
# Compared against the UNRIDGED factorised logdet (cholesky(Symmetric(P))) --
# not laplace_ll's ridged `P + 1e-10I` version, whose ridge is a deliberate,
# documented ~1e-8 numerical-safety perturbation unrelated to this identity.
# -----------------------------------------------------------------------------

function gate_logdet(; verbose::Bool = true)
    ok = true
    rng = MersenneTwister(20260919)
    for p in (100, 1000)
        case = id_make_case(p; seed = _id_seed(p))
        Q_cond = case.Q
        N = case.prob.n_total
        logdetQ = logdet(cholesky(Symmetric(Q_cond); check = false))
        worst = 0.0
        for _ in 1:20
            lc = randn(rng, 10)
            Λ = lc_to_Λ(lc)
            P = prior_precision(Q_cond, inv(Λ))
            chP = cholesky(Symmetric(P); check = false)
            issuccess(chP) || error("gate_logdet: reference factorisation failed at p=$p")
            logdetP_factorized = logdet(chP)
            logdetP_closed = 4 * logdetQ - N * logdet(Symmetric(Λ))
            rel = abs(logdetP_closed - logdetP_factorized) / abs(logdetP_factorized)
            worst = max(worst, rel)
        end
        this_ok = worst <= 1e-12
        verbose && @printf "  p=%d worst_rel_over_20_draws=%.3e %s\n" p worst (this_ok ? "OK" : "FAIL")
        ok &= this_ok
    end
    return ok
end

# -----------------------------------------------------------------------------
# G5.3: inner-Newton iteration count + accepted ridge lambda sequence, pinned
# from origin/main (90fbb0e28), p=100, cold start (u0 = nothing), n_newton=40.
# The shadow below is a fixed, unchanging reference loop (see file header).
# -----------------------------------------------------------------------------

const NEWTON_ITERS_PINNED = 12
const LAMBDA_SEQ_PINNED = [
    0.8190991490268129, 0.40954957451340646, 0.20477478725670323,
    0.10238739362835161, 0.05119369681417581, 0.025596848407087903,
    0.012798424203543952, 0.006399212101771976, 0.003199606050885988,
    0.001599803025442994, 0.000799901512721497, 0.0003999507563607485,
]

function _shadow_estep_robust_cold(prob, P, β; n_newton = 40, tol = 1e-8, trust = 5.0, gswitch = 1.0)
    lambdas = Float64[]
    iters = 0
    nu = 4 * prob.n_total
    u = zeros(nu)
    nit = max(n_newton, 200)
    f = DRModels.joint_nll(prob, P, u, β)
    g = DRModels.joint_grad(prob, P, u, β); ng = norm(g)
    H = ng < gswitch ? DRModels.build_Huu(prob, P, u, β) : DRModels.build_Huu_expected(prob, P, u, β)
    λ = 1e-2 * mean(abs.(diag(H))); λ = (isfinite(λ) && λ > 0) ? λ : 1.0
    λmax = 1e14
    for _ in 1:nit
        ng < tol && break
        iters += 1
        push!(lambdas, λ)
        ch_try, extra = DRModels.sparse_pd_chol(H + λ * I)
        if extra > 0; λ = min(λmax, max(λ, λ + extra)); ch_try, _ = DRModels.sparse_pd_chol(H + λ * I); end
        step = ch_try \ g
        sc = min(1.0, trust / max(maximum(abs, step), eps())); α = sc
        unew = u .- α .* step; fnew = DRModels.joint_nll(prob, P, unew, β); nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 60
            α *= 0.5; unew = u .- α .* step; fnew = DRModels.joint_nll(prob, P, unew, β); nbt += 1
        end
        if isfinite(fnew) && fnew < f
            u = unew; f = fnew
            g = DRModels.joint_grad(prob, P, u, β); ng = norm(g)
            H = ng < gswitch ? DRModels.build_Huu(prob, P, u, β) : DRModels.build_Huu_expected(prob, P, u, β)
            λ = max(1e-12, λ * 0.5)
        else
            λ *= 4.0; λ > λmax && break
        end
    end
    return iters, lambdas
end

function gate_newton(; verbose::Bool = true)
    case = id_make_case(100; seed = _id_seed(100))
    θ0 = pack_theta(case.β0, Λ0_ID)
    β0, lc0 = unpack_theta(case.prob, θ0)
    Λ0m = lc_to_Λ(lc0)
    P0 = prior_precision(case.Q, inv(Λ0m))
    iters, lambdas = _shadow_estep_robust_cold(case.prob, P0, β0; n_newton = 40)
    iters_ok = iters == NEWTON_ITERS_PINNED
    len_ok = length(lambdas) == length(LAMBDA_SEQ_PINNED)
    lam_ok = len_ok && all(isapprox.(lambdas, LAMBDA_SEQ_PINNED; rtol = 1e-10))
    ok = iters_ok && lam_ok
    if verbose
        @printf "  iters=%d pinned=%d %s\n" iters NEWTON_ITERS_PINNED (iters_ok ? "OK" : "FAIL")
        println("  lambda sequence length match: ", len_ok, "; elementwise rtol<=1e-10: ", lam_ok)
    end
    return ok
end

# -----------------------------------------------------------------------------
# G5.5: warm-u0 Wald vcov from _q4_fd_vcov equals origin/main's cold result
# within rtol 1e-8 (the one stated non-bitwise gate), p=100. Compares diag(V)
# (the 17 parameter variances), the Frobenius norm, and one off-diagonal
# spot-check -- not the full 17x17 matrix literal.
# -----------------------------------------------------------------------------

const VCOV_DIAG_PINNED = [
    0.02807960894013022, 0.0010211852652557726, 0.06300591449287987,
    0.0009107548734057989, 0.022635991349669184, 0.01314226241215916,
    0.003508500675446877, 0.0262945463441285, 0.009481289795594865,
    0.004079781701422195, 0.002722755163454296, 0.015591790687558943,
    0.004263260601434347, 0.002517143875367198, 0.08789020974663996,
    0.0024010419270051827, 10.871137555625735,
]
const VCOV_NORM_PINNED = 10.872096828506606
const VCOV_12_PINNED = -2.7811760381624746e-5
const VCOV_THETA_HAT_PINNED = [
    0.9726426336769248, 0.4691853983510966, -0.34371254566918313, 0.3955437939066539,
    -0.5209202354385878, -0.4821396409041553, 0.3063896222960122, -1.0175064619254408,
    0.2557258914249091, 0.16841795786881375, 0.16823964405005554, -0.7321062957900702,
    -0.06692807440175658, 0.057648038158769704, -1.4222822981533805, -0.14726715238506996,
    -4.556304995158093,
]

function gate_vcov(; verbose::Bool = true)
    case = id_make_case(100; seed = _id_seed(100))
    fit = fit_q4_sparse_tmb(case.prob, case.Q; β0 = case.β0, Λ0 = Λ0_ID, g_tol = 1e-3, iterations = 300, n_newton = 40)
    θhat = Vector{Float64}(fit.θ)
    # θ_hat itself must match the pinned optimum closely (sanity: the fit
    # trajectory, not just fd_vcov, must be unaffected by S5's changes).
    theta_ok = isapprox(θhat, VCOV_THETA_HAT_PINNED; rtol = 1e-6)
    V = DRModels._q4_fd_vcov(case.prob, case.Q, θhat; n_newton = 40)
    diag_ok = isapprox(diag(V), VCOV_DIAG_PINNED; rtol = 1e-8)
    norm_ok = isapprox(norm(V), VCOV_NORM_PINNED; rtol = 1e-8)
    v12_ok = isapprox(V[1, 2], VCOV_12_PINNED; rtol = 1e-8, atol = 1e-12)
    ok = theta_ok && diag_ok && norm_ok && v12_ok
    if verbose
        println("  theta_hat rtol<=1e-6 vs pinned: ", theta_ok)
        println("  diag(V) rtol<=1e-8 vs pinned: ", diag_ok)
        @printf "  norm(V)=%.15g pinned=%.15g %s\n" norm(V) VCOV_NORM_PINNED (norm_ok ? "OK" : "FAIL")
        @printf "  V[1,2]=%.6e pinned=%.6e %s\n" V[1, 2] VCOV_12_PINNED (v12_ok ? "OK" : "FAIL")
    end
    return ok
end

# -----------------------------------------------------------------------------
# CLI / testset
# -----------------------------------------------------------------------------

function _q4_identities_cli(argv)
    gate = nothing
    i = 1
    while i <= length(argv)
        if argv[i] == "--gate"
            gate = argv[i + 1]; i += 2
        else
            error("unknown argument: $(argv[i])")
        end
    end
    gate === nothing && error("--gate is required (one of nll|logdet|newton|vcov)")
    label = Dict("nll" => "G5.1", "logdet" => "G5.2", "newton" => "G5.3", "vcov" => "G5.5")[gate]
    ok = gate == "nll" ? gate_nll() :
         gate == "logdet" ? gate_logdet() :
         gate == "newton" ? gate_newton() :
         gate == "vcov" ? gate_vcov() :
         error("unknown --gate $gate (expected nll|logdet|newton|vcov)")
    println(ok ? "GATE $label PASS" : "GATE $label FAIL see diagnostics above")
    exit(ok ? 0 : 1)
end

if abspath(PROGRAM_FILE) == @__FILE__
    _q4_identities_cli(ARGS)
else
    @testset "q4 perf identities (leaf-S5)" begin
        @test gate_nll(; verbose = false)
        @test gate_logdet(; verbose = false)
        @test gate_newton(; verbose = false)
        @test gate_vcov(; verbose = false)
    end
end
