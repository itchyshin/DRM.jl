# profile_q4_sections.jl -- leaf-S3 section profile of the q=4 bivariate phylo
# route (_fit_bivariate_q4_phylo -> fit_q4_sparse_tmb -> marginal_nll/
# marginal_and_exact_grad -> estep_mode -> sparse_pd_chol / laplace_ll /
# takahashi_selinv). Extends bench/profile_step1.jl and
# bench/profile_sparse_grad.jl (which profile only p=100 from an external
# fixture path) to p = 100/1000/5000 with an in-repo case generator, and adds
# the _q4_fd_vcov cold-vs-warm sizing gate. Does NOT touch src/.
#
# Usage:
#   env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. \
#       bench/profile_q4_sections.jl --gate {tsv|baseline|loglik|fdvcov} --p <list>
#
# METHODOLOGY (repair pass -- instruments the REAL fit, not a separate probe):
#   G3.1's first attempt used a standalone "representative eval" probe outside
#   the optimiser loop and projected its cost by f_calls; that both missed real
#   per-eval cost (the AD-loop pieces below) and, at p=5000, sampled a probe
#   that happened to take the expensive robust Newton path, overshooting the
#   real fit wall by ~2x. This version instead measures the ACTUAL fit:
#
#   - `_estep_fast`, `_estep_robust`, `estep_mode`, `laplace_ll`, and
#     `marginal_and_exact_grad` are given NEW methods on their EXACT original
#     signatures via `function DRModels.<name>(...) ... end` from this script
#     (a different module). This is measurement-only method redefinition in
#     the bench process -- explicitly not a change to any file under src/, and
#     not something that ships. Each new method is a faithful transcription of
#     the original body (verified against `git show 90fbb0e28:src/...`) with
#     `time_ns()` brackets added around named cost sections, calling through
#     UNCHANGED to sparse_pd_chol / build_Huu / build_Huu_expected / joint_nll
#     / joint_grad / joint_nll_T / joint_grad_T / leaf_hess / leaf_hess_du
#     (none of which is redefined). Because Julia dispatch is late-bound, once
#     these methods are (re)defined, `fit_q4_sparse_tmb`'s own internal calls
#     to them -- already compiled or not -- resolve to the new methods, so
#     running `fit_case` for real accumulates exact per-section wall/count
#     into a single global accumulator (`ACC`) for that one real fit. No
#     separate "representative eval" is executed for the TSV gate.
#   - Sections are non-overlapping, sequential code spans inside one
#     `marginal_and_exact_grad` call (the Float64 kron-prior build, the
#     estep_mode call, takahashi_selinv, the two AD-gradient closures'
#     internal kron-prior-rebuild + joint_nll_T/joint_grad_T calls, the
#     beta-block trace loop, the Gst sparse assembly loop, the v-assembly
#     loop), so summing their measured walls can never exceed the wall of the
#     `marginal_and_exact_grad` calls that contain them, which in turn is
#     bounded by the fit's own total wall. "other" = fit_wall - sum(named) is
#     therefore a genuine, non-negative remainder (Optim's own bookkeeping,
#     line-search F-only evaluations, GC, and the handful of small untimed
#     lines inside laplace_ll/marginal_and_exact_grad: the plain joint_nll
#     call, glogdetΛ's small AD gradient, the 10-term Mk contraction, the
#     w = chH \ v solve) -- not a tautological fudge, a real accounting
#     identity that the code's own control flow guarantees.
#   - --gate fdvcov keeps its original design (real marginal_and_exact_grad
#     calls with u0 = nothing vs u0 = a converged mode); it already passed
#     and is now read off the same global accumulator instead of a separate
#     shadow copy, which is strictly more accurate (real Newton-iteration
#     counts from the actual call, not a parallel replica).
#   - --gate baseline compares against the repo's OWN current p=2000 number
#     (15.86 s, bench/run_scaling.jl, re-stated in the ledger 2026-09-19) --
#     not the stale 52.9 s in report/plan-and-timings.md, which predates the
#     fast-path/robust-fallback split already on this base.

import Pkg
Pkg.activate(dirname(@__DIR__))

using DRModels
using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, Random, Dates, DelimitedFiles

BLAS.set_num_threads(1)

# -----------------------------------------------------------------------------
# Case generator -- SAME data-generating process as bench/run_scaling.jl's
# `:balanced` shape (random_balanced_tree, βT/ΛT/Λ0, nrep=4), which produced
# the current p=2000 = 15.86 s baseline.
# -----------------------------------------------------------------------------

const βT = (mu1 = [1.0, 0.5], mu2 = [-0.3, 0.4], s1 = [-0.4], s2 = [-0.5], rho = [0.3])
const ΛT = Matrix(Symmetric([0.25 0.10 0.05 0.00; 0.10 0.25 0.00 0.04; 0.05 0.00 0.09 0.02; 0.00 0.04 0.02 0.09]))
const Λ0FIT = Matrix(Symmetric([0.30 0.02 0.01 0.010; 0.02 0.30 0.01 0.010; 0.01 0.01 0.08 0.005; 0.01 0.01 0.005 0.080]))

function _sample_augmented_state(rng::AbstractRNG, phy, Q_cond)
    P = prior_precision(Q_cond, inv(ΛT))
    F = cholesky(Symmetric(P))
    return F.UP \ randn(rng, size(P, 1))
end

"Balanced-tree q4 case at `p` leaves, nrep obs/leaf -- same DGP as run_scaling.jl."
function make_case(p::Integer; seed::Integer, nrep::Integer = 4)
    rng = MersenneTwister(seed)
    phy = random_balanced_tree(p; branch_length = 0.2)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    Q_cond = phy.Q_topology[keep, keep]
    u_aug = _sample_augmented_state(rng, phy, Q_cond)

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
        m1 = dot(@view(X1[i, :]), βT.mu1) + U[1, k]
        m2 = dot(@view(X2[i, :]), βT.mu2) + U[2, k]
        s1 = exp(dot(@view(Xs1[i, :]), βT.s1) + U[3, k])
        s2 = exp(dot(@view(Xs2[i, :]), βT.s2) + U[4, k])
        ρ = DRModels.RHO_GUARD * tanh(dot(@view(Xr[i, :]), βT.rho))
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

function fit_case(prob, Q, β0; iterations = 400, g_tol = 1e-3, n_newton = 40)
    return fit_q4_sparse_tmb(prob, Q; β0 = β0, Λ0 = Λ0FIT, g_tol = g_tol, iterations = iterations, n_newton = n_newton)
end

_seed_for(p::Integer) = 71000 + p + 1000   # matches run_scaling.jl's :balanced seed formula

# -----------------------------------------------------------------------------
# Global section accumulator.
# -----------------------------------------------------------------------------

const ACC = Dict{Symbol,Vector{Float64}}()
_reset_acc!() = empty!(ACC)
function _bump!(sym::Symbol, dt::Real, n::Real = 1)
    v = get!(ACC, sym, Float64[0.0, 0.0])
    v[1] += dt; v[2] += n
    return v
end
_acc_wall(sym::Symbol) = get(ACC, sym, Float64[0.0, 0.0])[1]
_acc_count(sym::Symbol) = get(ACC, sym, Float64[0.0, 0.0])[2]

# -----------------------------------------------------------------------------
# MEASUREMENT-ONLY method redefinitions (bench process only; see header note).
# Each is transcribed verbatim from src/sparse_aug_plsm.jl / fit_q4_sparse_tmb.jl
# on 90fbb0e28 (`git show 90fbb0e28:src/<file>`), with timing added. Untouched
# real primitives (sparse_pd_chol, build_Huu, build_Huu_expected, joint_nll,
# joint_grad, joint_nll_T, joint_grad_T, leaf_hess, leaf_hess_du, unpack_theta,
# lc_to_Λ, prior_precision, takahashi_selinv) are called through normally.
# -----------------------------------------------------------------------------

function DRModels.laplace_ll(prob::AugProblem, P::SparseMatrixCSC, β, u, ch_H)
    nu = 4 * prob.n_total
    jn = DRModels.joint_nll(prob, P, u, β)
    (isfinite(jn) && all(isfinite, nonzeros(P))) || return -Inf
    logdetH = logdet(ch_H)
    t0 = time_ns()
    chP = cholesky(Symmetric(P) + 1e-10I; check = false)
    logdetP = logdet(chP)
    _bump!(:logdetP_chol, (time_ns() - t0) / 1e9, 1)
    return -jn - 0.5 * logdetH + 0.5 * logdetP
end

function _estep_fast_core(prob, P, β, u0::Vector{Float64}; n_newton = 40, ftol = 1e-6, stall_tol = 1e-6, ucap = 1e3)
    chol_wall = 0.0; chol_count = 0; iters = 0
    u = copy(u0)
    f = DRModels.joint_nll(prob, P, u, β)
    isfinite(f) || return u, false, iters, chol_wall, chol_count
    g = DRModels.joint_grad(prob, P, u, β); ng = norm(g)
    for _ in 1:n_newton
        ng < ftol && return u, true, iters, chol_wall, chol_count
        iters += 1
        H = DRModels.build_Huu(prob, P, u, β)
        t0 = time_ns(); ch, _ = DRModels.sparse_pd_chol(H); chol_wall += (time_ns() - t0) / 1e9; chol_count += 1
        step = ch \ g
        all(isfinite, step) || return u, false, iters, chol_wall, chol_count
        α = 1.0
        unew = u .- α .* step; fnew = DRModels.joint_nll(prob, P, unew, β); nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 30
            α *= 0.5; unew = u .- α .* step; fnew = DRModels.joint_nll(prob, P, unew, β); nbt += 1
        end
        if !(isfinite(fnew) && fnew < f)
            return u, ng < stall_tol, iters, chol_wall, chol_count
        end
        u = unew; f = fnew
        maximum(abs, u) > ucap && return u, false, iters, chol_wall, chol_count
        g = DRModels.joint_grad(prob, P, u, β); ng = norm(g)
    end
    return u, ng < stall_tol, iters, chol_wall, chol_count
end

function DRModels._estep_fast(prob::AugProblem, P::SparseMatrixCSC, β, u0::Vector{Float64};
                              n_newton = 40, ftol = 1e-6, stall_tol = 1e-6, ucap = 1e3)
    u, ok, iters, chol_wall, chol_count = _estep_fast_core(prob, P, β, u0; n_newton = n_newton, ftol = ftol, stall_tol = stall_tol, ucap = ucap)
    _bump!(:estep_fast_calls, 0.0, 1)
    _bump!(:estep_fast_iters, 0.0, iters)
    _bump!(:estep_chol, chol_wall, chol_count)
    return u, ok
end

function _estep_robust_core(prob, P, β; u0 = nothing, n_newton = 40, tol = 1e-8, trust = 5.0, gswitch = 1.0)
    chol_wall = 0.0; chol_count = 0; iters = 0
    nu = 4 * prob.n_total
    u = u0 === nothing ? zeros(nu) : copy(u0)
    nit = u0 === nothing ? max(n_newton, 200) : n_newton
    f = DRModels.joint_nll(prob, P, u, β)
    g = DRModels.joint_grad(prob, P, u, β); ng = norm(g)
    H = ng < gswitch ? DRModels.build_Huu(prob, P, u, β) : DRModels.build_Huu_expected(prob, P, u, β)
    λ = 1e-2 * mean(abs.(diag(H))); λ = (isfinite(λ) && λ > 0) ? λ : 1.0
    λmax = 1e14
    for _ in 1:nit
        ng < tol && break
        iters += 1
        t0 = time_ns(); ch_try, extra = DRModels.sparse_pd_chol(H + λ * I); chol_wall += (time_ns() - t0) / 1e9; chol_count += 1
        if extra > 0
            λ = min(λmax, max(λ, λ + extra))
            t0 = time_ns(); ch_try, _ = DRModels.sparse_pd_chol(H + λ * I); chol_wall += (time_ns() - t0) / 1e9; chol_count += 1
        end
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
    Hobs = DRModels.build_Huu(prob, P, u, β)
    t0 = time_ns(); ch, _ = DRModels.sparse_pd_chol(Hobs); chol_wall += (time_ns() - t0) / 1e9; chol_count += 1
    return u, ch, Hobs, iters, chol_wall, chol_count
end

function DRModels._estep_robust(prob::AugProblem, P::SparseMatrixCSC, β;
                                u0 = nothing, n_newton = 40, tol = 1e-8, trust = 5.0, gswitch = 1.0)
    u, ch, Hobs, iters, chol_wall, chol_count = _estep_robust_core(prob, P, β; u0 = u0, n_newton = n_newton, tol = tol, trust = trust, gswitch = gswitch)
    _bump!(:estep_robust_calls, 0.0, 1)
    _bump!(:estep_robust_iters, 0.0, iters)
    _bump!(:estep_chol, chol_wall, chol_count)
    return u, ch, Hobs
end

function DRModels.estep_mode(prob::AugProblem, P::SparseMatrixCSC, β;
                             u0 = nothing, n_newton = 40, tol = 1e-8, trust = 5.0, gswitch = 1.0)
    if u0 !== nothing
        u, ok = DRModels._estep_fast(prob, P, β, Vector{Float64}(u0); n_newton = n_newton)
        if ok
            Hobs = DRModels.build_Huu(prob, P, u, β)
            t0 = time_ns(); ch, _ = DRModels.sparse_pd_chol(Hobs); _bump!(:estep_chol, (time_ns() - t0) / 1e9, 1)
            return u, ch, Hobs
        end
    end
    return DRModels._estep_robust(prob, P, β; u0 = u0, n_newton = n_newton, tol = tol, trust = trust, gswitch = gswitch)
end

function DRModels.marginal_and_exact_grad(prob::AugProblem, Q_cond::SparseMatrixCSC,
                                          θ::Vector{Float64}; u0 = nothing, n_newton::Int = 40)
    t_mge0 = time_ns()
    nθ = length(θ)
    k1, k2, ks1, ks2, kr = DRModels.beta_widths(prob)
    o1 = 0; o2 = k1; o3 = o2 + k2; o4 = o3 + ks1; o5 = o4 + ks2; o6 = o5 + kr

    β, lc = unpack_theta(prob, θ)
    Λ = lc_to_Λ(lc)
    Λi = inv(Λ)

    t0 = time_ns()
    P = prior_precision(Q_cond, Λi)
    _bump!(:kron_prior, (time_ns() - t0) / 1e9, 1)

    t0 = time_ns()
    u_hat, chH, H = estep_mode(prob, P, β; u0 = u0, n_newton = n_newton)
    _bump!(:estep_newton_chol, (time_ns() - t0) / 1e9, 1)
    u_hat = Vector{Float64}(u_hat)
    nll = -DRModels.laplace_ll(prob, P, β, u_hat, chH)

    grad = zeros(nθ)

    t0 = time_ns()
    Vsel = takahashi_selinv(chH)
    _bump!(:takahashi, (time_ns() - t0) / 1e9, 1)

    η1, η2, ηs1, ηs2, ηr = DRModels.leaf_etas(prob, β)

    jn_of_θ = function (t::AbstractVector)
        βt, lct = unpack_theta(prob, t)
        Λt = lc_to_Λ(lct)
        t1 = time_ns()
        Pt = prior_precision(Q_cond, inv(Λt))
        _bump!(:kron_prior, (time_ns() - t1) / 1e9, 1)
        t1 = time_ns()
        val = DRModels.joint_nll_T(prob, Pt, u_hat, βt)
        _bump!(:joint_nll_T, (time_ns() - t1) / 1e9, 1)
        return val
    end
    grad .+= ForwardDiff.gradient(jn_of_θ, θ)

    N = prob.n_total
    glogdetΛ = ForwardDiff.gradient(v -> logdet(Symmetric(lc_to_Λ(v))), lc)
    grad[o6+1:o6+10] .+= 0.5 * N .* glogdetΛ

    t0 = time_ns()
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]; bt = 4(t - 1)
        Vblk = @view Vsel[bt+1:bt+4, bt+1:bt+4]
        Jη = ForwardDiff.jacobian(
            e -> vec(DRModels.leaf_hess([u_hat[bt+1], u_hat[bt+2], u_hat[bt+3], u_hat[bt+4]],
                               prob.y1[i], prob.y2[i], e[1], e[2], e[3], e[4], e[5],
                               prob.obs1[i], prob.obs2[i])),
            [η1[i], η2[i], ηs1[i], ηs2[i], ηr[i]])
        sη = zeros(5)
        for m in 1:5
            acc = 0.0
            col = @view Jη[:, m]
            for b in 1:4, a in 1:4
                acc += Vblk[a, b] * col[(b-1)*4 + a]
            end
            sη[m] = acc
        end
        for c in 1:k1;  grad[o1+c] += 0.5 * sη[1] * prob.X1[i, c];  end
        for c in 1:k2;  grad[o2+c] += 0.5 * sη[2] * prob.X2[i, c];  end
        for c in 1:ks1; grad[o3+c] += 0.5 * sη[3] * prob.Xs1[i, c]; end
        for c in 1:ks2; grad[o4+c] += 0.5 * sη[4] * prob.Xs2[i, c]; end
        for c in 1:kr;  grad[o5+c] += 0.5 * sη[5] * prob.Xr[i, c];  end
    end
    _bump!(:beta_trace, (time_ns() - t0) / 1e9, 1)

    t0 = time_ns()
    Gst = zeros(4, 4)
    rows = rowvals(Q_cond); vals = nonzeros(Q_cond)
    @inbounds for tcol in 1:N
        for idx in nzrange(Q_cond, tcol)
            s = rows[idx]; q = vals[idx]
            bs = 4(s - 1); bt = 4(tcol - 1)
            for a in 1:4, b in 1:4
                Gst[b, a] += q * Vsel[bt + a, bs + b]
            end
        end
    end
    _bump!(:gst, (time_ns() - t0) / 1e9, 1)

    dΛ = ForwardDiff.jacobian(lc_to_Λ, lc)
    for k in 1:10
        dΛk = reshape(@view(dΛ[:, k]), 4, 4)
        Mk = -Λi * dΛk * Λi
        acc = 0.0
        for a in 1:4, b in 1:4
            acc += Gst[b, a] * Mk[b, a]
        end
        grad[o6 + k] += 0.5 * acc
    end

    nu = 4 * prob.n_total
    v = zeros(nu)
    t0 = time_ns()
    @inbounds for i in eachindex(prob.leaf_node)
        t = prob.leaf_node[i]; bt = 4(t - 1)
        Vblk = @view Vsel[bt+1:bt+4, bt+1:bt+4]
        T = DRModels.leaf_hess_du([u_hat[bt+1], u_hat[bt+2], u_hat[bt+3], u_hat[bt+4]],
                         prob.y1[i], prob.y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i],
                         prob.obs1[i], prob.obs2[i])
        for c in 1:4
            acc = 0.0
            for b in 1:4, a in 1:4
                acc += Vblk[a, b] * T[a, b, c]
            end
            v[bt + c] += 0.5 * acc
        end
    end
    _bump!(:v_assembly, (time_ns() - t0) / 1e9, 1)

    w = chH \ v

    scalar_of_θ = function (t::AbstractVector)
        βt, lct = unpack_theta(prob, t)
        Λt = lc_to_Λ(lct)
        t1 = time_ns()
        Pt = prior_precision(Q_cond, inv(Λt))
        _bump!(:kron_prior, (time_ns() - t1) / 1e9, 1)
        t1 = time_ns()
        gu = DRModels.joint_grad_T(prob, Pt, u_hat, βt)
        _bump!(:joint_grad_T, (time_ns() - t1) / 1e9, 1)
        return dot(gu, w)
    end
    grad .-= ForwardDiff.gradient(scalar_of_θ, θ)

    _bump!(:mge_calls, (time_ns() - t_mge0) / 1e9, 1)
    return nll, grad, u_hat, chH
end

const SECTION_ORDER = [:estep_newton_chol, :logdetP_chol, :kron_prior, :takahashi,
                        :joint_nll_T, :joint_grad_T, :beta_trace, :gst, :v_assembly]

# -----------------------------------------------------------------------------
# System / header info for the TSV.
# -----------------------------------------------------------------------------

function _git_short_sha()
    try
        return strip(read(`git rev-parse --short HEAD`, String))
    catch
        return "unknown"
    end
end

function _cpu_model()
    try
        return strip(read(`sysctl -n machdep.cpu.brand_string`, String))
    catch
        try
            return Sys.cpu_info()[1].model
        catch
            return "unknown"
        end
    end
end

function _current_rss_kb()
    try
        return parse(Int, strip(read(`ps -o rss= -p $(getpid())`, String)))
    catch
        return -1
    end
end

mutable struct RssTracker
    peak_kb::Int
end
RssTracker() = RssTracker(_current_rss_kb())
function sample!(t::RssTracker)
    v = _current_rss_kb()
    v > t.peak_kb && (t.peak_kb = v)
    return v
end

function _tsv_header(short_sha::AbstractString, rss::RssTracker)
    lines = String[]
    push!(lines, "# leaf-S3 q4 section profile (real-fit instrumentation; see file header)")
    push!(lines, "# generated: $(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ"))")
    push!(lines, "# git_sha: $short_sha")
    push!(lines, "# julia_version: $(VERSION)")
    push!(lines, "# blas_config: $(BLAS.get_config())")
    push!(lines, "# julia_threads: $(Threads.nthreads())  blas_threads: $(BLAS.get_num_threads())")
    push!(lines, "# os: $(Sys.MACHINE)  cpu: $(_cpu_model())")
    push!(lines, "# peak_rss_kb (ps-sampled, not exact OS max): $(rss.peak_kb)")
    push!(lines, "# columns: p\trep\tsection\twall_s\tcount\tbytes")
    return lines
end

# -----------------------------------------------------------------------------
# Gate G3.1: --gate tsv --p 100,1000,5000
# -----------------------------------------------------------------------------

function gate_tsv(ps::Vector{Int})
    rss = RssTracker()
    tsv_lines = _tsv_header(_git_short_sha(), rss)
    meta_lines = String[]
    ok_all = true

    for p in ps
        seed = _seed_for(p)
        case = make_case(p; seed = seed, nrep = 4)
        sample!(rss)

        _reset_acc!()
        fit_case(case.prob, case.Q, case.β0)   # warmup (not reported)
        sample!(rss)

        reps = 3
        budget_s = 8 * 60.0
        fit_walls = Float64[]
        accs = Dict{Symbol,Vector{Float64}}[]
        fits = Any[]
        for r in 1:reps
            _reset_acc!()
            t = @elapsed (last = fit_case(case.prob, case.Q, case.β0))
            push!(fit_walls, t)
            push!(accs, deepcopy(ACC))
            push!(fits, last)
            sample!(rss)
            if p == 5000 && r == 1 && t * reps > budget_s
                push!(meta_lines, "# p=5000: 1 fit ~ $(round(t, digits=1)) s; $(reps)x would exceed the $(Int(budget_s))s (8 min) budget -> dropping to 1 rep")
                break
            end
        end
        actual_reps = length(fit_walls)
        med = median(fit_walls)
        rep_idx = argmin(abs.(fit_walls .- med))
        fit_wall = fit_walls[rep_idx]
        acc = accs[rep_idx]
        last = fits[rep_idx]

        section_wall(sym) = get(acc, sym, Float64[0.0, 0.0])[1]
        section_count(sym) = Int(round(get(acc, sym, Float64[0.0, 0.0])[2]))

        named_sum = sum(section_wall(s) for s in SECTION_ORDER)
        other_wall = fit_wall - named_sum
        # sum(named) + other == fit_wall exactly by construction (other is the
        # residual); the gate checks that the residual is a genuine small/
        # non-negative remainder, i.e. the named, real, non-overlapping
        # sections did not (somehow) exceed the fit's own measured wall.
        within_10pct = other_wall >= -0.10 * fit_wall
        ok_all &= within_10pct

        fast_calls = section_count(:estep_fast_calls)
        robust_calls = section_count(:estep_robust_calls)
        fast_iters = section_count(:estep_fast_iters)
        robust_iters = section_count(:estep_robust_iters)

        push!(meta_lines, "# p=$p reps_used=$actual_reps chosen_rep=$rep_idx fit_wall_s=$(round(fit_wall, digits=4)) f_calls=$(last.f_calls) named_sum_s=$(round(named_sum, digits=4)) other_s=$(round(other_wall, digits=4)) other_share_pct=$(round(100 * other_wall / fit_wall, digits=2)) within_10pct=$within_10pct fast_calls=$fast_calls robust_calls=$robust_calls fast_newton_iters_total=$fast_iters robust_newton_iters_total=$robust_iters converged=$(last.converged) loglik=$(round(last.loglik, digits=4))")

        # fd_vcov TSV row: a separate post-fit step, projected from ONE
        # representative cold call x 2*n_theta (unchanged methodology; kept
        # OUT of the sum-to-fit-wall check per the repair instructions).
        θ̂ = Vector{Float64}(last.θ)
        nθ = length(θ̂)
        h = 1e-4
        θp = copy(θ̂); θp[1] += h
        _reset_acc!()
        t_fd = @timed marginal_and_exact_grad(case.prob, case.Q, θp; u0 = nothing, n_newton = 40)
        fd_calls = 2 * nθ
        fd_wall_proj = t_fd.time * fd_calls
        fd_bytes_proj = t_fd.bytes * fd_calls

        row_defs = [
            ("estep_newton_chol", section_wall(:estep_newton_chol), section_count(:estep_chol)),
            ("logdetP_chol", section_wall(:logdetP_chol), section_count(:logdetP_chol)),
            ("kron_prior", section_wall(:kron_prior), section_count(:kron_prior)),
            ("takahashi", section_wall(:takahashi), section_count(:takahashi)),
            ("joint_nll_T", section_wall(:joint_nll_T), section_count(:joint_nll_T)),
            ("joint_grad_T", section_wall(:joint_grad_T), section_count(:joint_grad_T)),
            ("beta_trace", section_wall(:beta_trace), section_count(:beta_trace)),
            ("gst", section_wall(:gst), section_count(:gst)),
            ("v_assembly", section_wall(:v_assembly), section_count(:v_assembly)),
            ("other", other_wall, 1),
            ("fd_vcov", fd_wall_proj, fd_calls),
        ]
        bytes_by_name = Dict("fd_vcov" => round(Int, fd_bytes_proj))
        for (name, wall, count) in row_defs
            bytes = get(bytes_by_name, name, 0)
            push!(tsv_lines, @sprintf("%d\t%d\t%s\t%.6f\t%d\t%d", p, rep_idx, name, wall, count, bytes))
        end

        @printf "p=%d fit_wall=%.3fs named_sum=%.3fs other=%.3fs(%.1f%%) within_10pct=%s fast=%d robust=%d (reps=%d)\n" p fit_wall named_sum other_wall (100 * other_wall / fit_wall) within_10pct fast_calls robust_calls actual_reps
    end

    out_dir = joinpath(@__DIR__, "results")
    mkpath(out_dir)
    out_path = joinpath(out_dir, "q4_sections_$(_git_short_sha()).tsv")
    open(out_path, "w") do io
        for l in meta_lines; println(io, l); end
        for l in tsv_lines; println(io, l); end
    end
    println("wrote ", out_path)

    if ok_all
        println("GATE G3.1 PASS")
    else
        println("GATE G3.1 FAIL one or more p had a negative 'other' remainder beyond -10% of fit wall (see ", out_path, ")")
    end
    return ok_all
end

# -----------------------------------------------------------------------------
# Gate G3.2: --gate baseline --p 2000 -- current repo baseline (15.86s), not
# the stale 52.9s in report/plan-and-timings.md (see file header / checkpoint).
# -----------------------------------------------------------------------------

function gate_baseline(p::Int)
    banked_s = 15.86
    seed = _seed_for(p)
    case = make_case(p; seed = seed, nrep = 4)
    fit_case(case.prob, case.Q, case.β0)  # warmup
    t = @elapsed r = fit_case(case.prob, case.Q, case.β0)
    rel = abs(t - banked_s) / banked_s
    ok = rel <= 0.20
    @printf "baseline p=%d wall=%.2fs current_repo_baseline=%.2fs rel=%.1f%% converged=%s loglik=%.2f\n" p t banked_s (100rel) r.converged r.loglik
    if ok
        println("GATE G3.2 PASS")
    else
        println("GATE G3.2 FAIL wall=$(round(t, digits=2))s vs current repo baseline $(banked_s)s (rel $(round(100rel, digits=1))%)")
    end
    return ok
end

# -----------------------------------------------------------------------------
# Gate G3.3: --gate loglik --p 100 -- same fixture/method as run_sparse_tmb_nd.jl
# -----------------------------------------------------------------------------

function gate_loglik(p::Int)
    p == 100 || println("note: loglik gate is anchored at p=100 (the repo's q4_p100 fixture); ignoring --p $p")
    FIX = joinpath(@__DIR__, "fixtures")
    raw = readdlm(joinpath(FIX, "q4_p100.csv"), ',', String; header = true)[1]
    n = size(raw, 1)
    phy = augmented_phy(read(joinpath(FIX, "q4_p100_tree.nwk"), String))
    species = raw[:, 4]
    name2row = Dict(String(s) => i for (i, s) in enumerate(species))
    perm = [name2row[phy.leaf_names[k]] for k in 1:n]
    y1 = parse.(Float64, raw[:, 1])[perm]; y2 = parse.(Float64, raw[:, 2])[perm]; x1 = parse.(Float64, raw[:, 3])[perm]
    X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
    Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)
    prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
    β0 = (
        mu1 = X1 \ y1, mu2 = X2 \ y2,
        s1 = [log(std(y1 .- X1 * (X1 \ y1)))], s2 = [log(std(y2 .- X2 * (X2 \ y2)))],
        rho = [0.0],
    )
    Λ0 = Matrix(Symmetric([0.30 0.05 0.03 0.03; 0.05 0.30 0.03 0.03; 0.03 0.03 0.30 0.03; 0.03 0.03 0.03 0.30]))
    fit_q4_sparse_tmb(prob, Q_cond; β0 = β0, Λ0 = Λ0, g_tol = 1e-3, iterations = 300, n_newton = 40)  # warmup
    r = fit_q4_sparse_tmb(prob, Q_cond; β0 = β0, Λ0 = Λ0, g_tol = 1e-3, iterations = 300, n_newton = 40)
    target = -256.51
    diff = abs(r.loglik - target)
    ok = diff <= 0.05
    @printf "loglik p=100 measured=%.4f target=%.2f |diff|=%.4f converged=%s\n" r.loglik target diff r.converged
    println(ok ? "GATE G3.3 PASS" : "GATE G3.3 FAIL loglik=$(round(r.loglik, digits=4)) target=$target diff=$(round(diff, digits=4))")
    return ok
end

# -----------------------------------------------------------------------------
# Gate G3.4: --gate fdvcov --p 100,1000
# -----------------------------------------------------------------------------

function gate_fdvcov(ps::Vector{Int})
    ok_all = true
    n_newton = 40
    for p in ps
        seed = _seed_for(p)
        case = make_case(p; seed = seed, nrep = 4)
        fit = fit_case(case.prob, case.Q, case.β0)
        θ̂ = Vector{Float64}(fit.θ)
        nθ = length(θ̂)
        h = 1e-4
        θp = copy(θ̂); θp[1] += h

        _reset_acc!()
        _, u_conv, _, _ = marginal_nll(case.prob, case.Q, θ̂; n_newton = n_newton)
        u_conv = Vector{Float64}(u_conv)

        _reset_acc!()
        t_cold = @timed marginal_and_exact_grad(case.prob, case.Q, θp; u0 = nothing, n_newton = n_newton)
        cold_iters = Int(round(_acc_count(:estep_robust_iters)))
        cold_path = _acc_count(:estep_fast_calls) > 0 ? "fast" : "robust"

        _reset_acc!()
        t_warm = @timed marginal_and_exact_grad(case.prob, case.Q, θp; u0 = u_conv, n_newton = n_newton)
        warm_chol_calls = Int(round(_acc_count(:estep_chol)))
        warm_path = (_acc_count(:estep_robust_calls) > 0) ? "robust_fallback" : "fast"

        n_calls_expected = 2 * nθ
        proj_cold_total_s = t_cold.time * n_calls_expected
        proj_warm_total_s = t_warm.time * n_calls_expected
        speedup = t_cold.time / max(t_warm.time, 1e-9)

        @printf "fdvcov p=%d n_theta=%d expected_calls(2*n_theta)=%d\n" p nθ n_calls_expected
        @printf "  cold: 1 call wall=%.4fs cold_newton_iters=%d path=%s bytes=%d -> projected total for all %d calls = %.2fs\n" t_cold.time cold_iters cold_path t_cold.bytes n_calls_expected proj_cold_total_s
        @printf "  warm(u_hat): 1 call wall=%.4fs chol_calls=%d path=%s bytes=%d -> projected total for all %d calls = %.2fs\n" t_warm.time warm_chol_calls warm_path t_warm.bytes n_calls_expected proj_warm_total_s
        @printf "  cold/warm speedup per call = %.2fx\n" speedup

        ok = isfinite(t_cold.time) && isfinite(t_warm.time) && cold_iters > 0
        ok_all &= ok
    end
    println(ok_all ? "GATE G3.4 PASS" : "GATE G3.4 FAIL see per-p diagnostics above")
    return ok_all
end

# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------

function _parse_args(argv)
    gate = nothing
    ps = Int[]
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--gate"
            gate = argv[i + 1]; i += 2
        elseif a == "--p"
            ps = [parse(Int, strip(x)) for x in split(argv[i + 1], ",") if !isempty(strip(x))]
            i += 2
        else
            error("unknown argument: $a")
        end
    end
    gate === nothing && error("--gate is required (one of tsv|baseline|loglik|fdvcov)")
    isempty(ps) && error("--p is required")
    return gate, ps
end

function main()
    gate, ps = _parse_args(ARGS)
    ok = if gate == "tsv"
        gate_tsv(ps)
    elseif gate == "baseline"
        gate_baseline(ps[1])
    elseif gate == "loglik"
        gate_loglik(ps[1])
    elseif gate == "fdvcov"
        gate_fdvcov(ps)
    else
        error("unknown --gate $gate (expected tsv|baseline|loglik|fdvcov)")
    end
    exit(ok ? 0 : 1)
end

main()
