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
# METHODOLOGY NOTE (read before trusting a number):
#   - sparse_pd_chol, build_Huu, build_Huu_expected, joint_nll, joint_grad,
#     estep_mode, prior_precision, takahashi_selinv, marginal_nll,
#     marginal_and_exact_grad, fit_q4_sparse_tmb are called UNMODIFIED (either
#     exported by DRModels or accessed as DRModels.<name>). No src/ file is
#     edited and no method is monkey-patched.
#   - Counting how many CHOLMOD factorisations occur inside one estep_mode
#     call cannot be done from outside without either editing src/ or
#     monkey-patching sparse_pd_chol (which self-recurses: redefining a method
#     with the same signature replaces it in place, so the "original" can no
#     longer be called from inside the wrapper). Instead this file carries a
#     COUNTING-ONLY SHADOW COPY of _estep_fast/_estep_robust/estep_mode
#     (transcribed from src/sparse_aug_plsm.jl, unmodified logic) that calls
#     through to the REAL sparse_pd_chol/build_Huu/build_Huu_expected/
#     joint_nll/joint_grad for every numeric step. The shadow supplies the
#     iteration/factorisation COUNT; wall time for the "estep_newton_chol"
#     section comes from timing the REAL estep_mode call on the same inputs,
#     not from the shadow.
#   - "kron_prior" wall = one real prior_precision(Q_cond, Λi) (Float64) call
#     plus two real prior_precision calls forced to run under Dual arithmetic
#     of the true θ width (via ForwardDiff.gradient over a kron-only
#     reduction), representing the two Dual-valued rebuilds inside jn_of_θ and
#     scalar_of_θ (fit_q4_sparse_tmb.jl:319-325, :424-431).
#   - --gate tsv projects total per-section wall over a fit as
#     (per-eval section wall) x (Optim-reported f_calls), using ONE cold eval
#     (u0 = nothing) and (f_calls - 1) warm evals (u0 = the fit's own
#     converged mode) for estep_newton_chol, and the warm per-eval cost x
#     f_calls for logdetP_chol/kron_prior/takahashi (their cost does not
#     depend materially on warm vs cold). This is an approximation of the
#     real trajectory (which explores off the optimum before converging), not
#     a per-iteration instrumented trace; the G3.1 "within 10%" check is the
#     empirical test of whether that approximation holds. fd_vcov's TSV row
#     is a projection from ONE representative cold marginal_and_exact_grad
#     call x 2*n_theta (the deterministic call count from
#     gaussian_bivariate.jl:1348-1360) -- AGENT-INFERRED for p=1000/5000 to
#     stay inside the 30-minute compute ceiling; --gate fdvcov measures the
#     real cold/warm calls directly (no projection) at p=100 and p=1000.

import Pkg
Pkg.activate(dirname(@__DIR__))

using DRModels
using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, Random, Dates, DelimitedFiles

BLAS.set_num_threads(1)

# -----------------------------------------------------------------------------
# Case generator -- SAME data-generating process as bench/run_scaling.jl's
# `:balanced` shape (random_balanced_tree, βT/ΛT/Λ0, nrep=4), which produced
# the banked p=2000 = 52.9 s / k=1.33 numbers in report/plan-and-timings.md.
# Reused (not re-derived) so --gate baseline reproduces that number on the
# same DGP; also used for --gate tsv / --gate fdvcov at other p.
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
# Counting-only shadow of _estep_fast / _estep_robust / estep_mode
# (src/sparse_aug_plsm.jl:254-339, transcribed unmodified). Calls through to
# the REAL sparse_pd_chol / build_Huu / build_Huu_expected / joint_nll /
# joint_grad. Used only to COUNT factorisations and Newton iterations; wall
# time for the harness's reported sections comes from timing the real
# estep_mode call, not from this shadow.
# -----------------------------------------------------------------------------

function _shadow_estep_fast(prob, P, β, u0::Vector{Float64}; n_newton = 40, ftol = 1e-6, stall_tol = 1e-6, ucap = 1e3)
    chol_calls = 0
    u = copy(u0)
    f = joint_nll(prob, P, u, β)
    isfinite(f) || return u, false, chol_calls
    g = joint_grad(prob, P, u, β); ng = norm(g)
    for _ in 1:n_newton
        ng < ftol && return u, true, chol_calls
        H = build_Huu(prob, P, u, β)
        ch, _ = DRModels.sparse_pd_chol(H); chol_calls += 1
        step = ch \ g
        all(isfinite, step) || return u, false, chol_calls
        α = 1.0
        unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 30
            α *= 0.5; unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt += 1
        end
        if !(isfinite(fnew) && fnew < f)
            return u, ng < stall_tol, chol_calls
        end
        u = unew; f = fnew
        maximum(abs, u) > ucap && return u, false, chol_calls
        g = joint_grad(prob, P, u, β); ng = norm(g)
    end
    return u, ng < stall_tol, chol_calls
end

function _shadow_estep_robust(prob, P, β; u0 = nothing, n_newton = 40, tol = 1e-8, trust = 5.0, gswitch = 1.0)
    chol_calls = 0
    nu = 4 * prob.n_total
    u = u0 === nothing ? zeros(nu) : copy(u0)
    nit = u0 === nothing ? max(n_newton, 200) : n_newton
    f = joint_nll(prob, P, u, β)
    g = joint_grad(prob, P, u, β); ng = norm(g)
    H = ng < gswitch ? build_Huu(prob, P, u, β) : DRModels.build_Huu_expected(prob, P, u, β)
    λ = 1e-2 * mean(abs.(diag(H))); λ = (isfinite(λ) && λ > 0) ? λ : 1.0
    λmax = 1e14
    iters_used = 0
    for _ in 1:nit
        iters_used += 1
        ng < tol && break
        ch_try, extra = DRModels.sparse_pd_chol(H + λ * I); chol_calls += 1
        if extra > 0
            λ = min(λmax, max(λ, λ + extra))
            ch_try, _ = DRModels.sparse_pd_chol(H + λ * I); chol_calls += 1
        end
        step = ch_try \ g
        sc = min(1.0, trust / max(maximum(abs, step), eps())); α = sc
        unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 60
            α *= 0.5; unew = u .- α .* step; fnew = joint_nll(prob, P, unew, β); nbt += 1
        end
        if isfinite(fnew) && fnew < f
            u = unew; f = fnew
            g = joint_grad(prob, P, u, β); ng = norm(g)
            H = ng < gswitch ? build_Huu(prob, P, u, β) : DRModels.build_Huu_expected(prob, P, u, β)
            λ = max(1e-12, λ * 0.5)
        else
            λ *= 4.0; λ > λmax && break
        end
    end
    Hobs = build_Huu(prob, P, u, β)
    ch, _ = DRModels.sparse_pd_chol(Hobs); chol_calls += 1
    return u, ch, Hobs, chol_calls, iters_used
end

function _shadow_estep_mode(prob, P, β; u0 = nothing, n_newton = 40, tol = 1e-8, trust = 5.0, gswitch = 1.0)
    if u0 !== nothing
        u, ok, calls_fast = _shadow_estep_fast(prob, P, β, Vector{Float64}(u0); n_newton = n_newton)
        if ok
            calls_fast += 1   # final Hobs factorisation in estep_mode's fast branch
            return u, calls_fast, :fast
        end
    end
    u, _, _, calls_robust, iters = _shadow_estep_robust(prob, P, β; u0 = u0, n_newton = n_newton, tol = tol, trust = trust, gswitch = gswitch)
    return u, calls_robust, (u0 === nothing ? :robust_cold : :robust_fallback)
end

# -----------------------------------------------------------------------------
# Per-evaluation section profile at a fixed θ (one representative objective
# evaluation). Real timed calls for wall/bytes; the shadow above supplies the
# estep factorisation count only.
# -----------------------------------------------------------------------------

function profile_eval_sections(prob, Q_cond, θ::Vector{Float64}; u_warm = nothing, n_newton = 40)
    β, lc = unpack_theta(prob, θ)
    Λ = lc_to_Λ(lc); Λi = inv(Λ)
    P = prior_precision(Q_cond, Λi)

    t_estep = @timed estep_mode(prob, P, β; u0 = u_warm, n_newton = n_newton)
    u_hat, chH, _ = t_estep.value
    u_hat = Vector{Float64}(u_hat)
    _, chol_calls, path = _shadow_estep_mode(prob, P, β; u0 = u_warm, n_newton = n_newton)

    t_logdetP = @timed cholesky(Symmetric(P) + 1e-10I; check = false)

    t_kron_float = @timed prior_precision(Q_cond, Λi)
    kron_only = t -> begin
        _, lct = unpack_theta(prob, t)
        Λt = lc_to_Λ(lct)
        Pt = prior_precision(Q_cond, inv(Λt))
        return sum(nonzeros(Pt))
    end
    t_kron_dual1 = @timed ForwardDiff.gradient(kron_only, θ)
    t_kron_dual2 = @timed ForwardDiff.gradient(kron_only, θ)

    t_tak = @timed takahashi_selinv(chH)

    return (;
        u_hat, path,
        estep_wall = t_estep.time, estep_bytes = t_estep.bytes, estep_count = chol_calls,
        logdetP_wall = t_logdetP.time, logdetP_bytes = t_logdetP.bytes, logdetP_count = 1,
        kron_wall = t_kron_float.time + t_kron_dual1.time + t_kron_dual2.time,
        kron_bytes = t_kron_float.bytes + t_kron_dual1.bytes + t_kron_dual2.bytes, kron_count = 3,
        tak_wall = t_tak.time, tak_bytes = t_tak.bytes, tak_count = 1,
    )
end

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
    push!(lines, "# leaf-S3 q4 section profile")
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
    n_newton = 40

    for p in ps
        seed = _seed_for(p)
        case = make_case(p; seed = seed, nrep = 4)
        sample!(rss)

        # warmup (not reported)
        warm = fit_case(case.prob, case.Q, case.β0)
        sample!(rss)

        reps = 3
        budget_s = 8 * 60.0
        fit_walls = Float64[]
        last = warm
        for r in 1:reps
            t = @elapsed (last = fit_case(case.prob, case.Q, case.β0))
            push!(fit_walls, t)
            sample!(rss)
            if p == 5000 && r == 1 && t * reps > budget_s
                push!(meta_lines, "# p=5000: 1 fit ~ $(round(t, digits=1)) s; $(reps)x would exceed the $(Int(budget_s))s (8 min) budget -> dropping to 1 rep")
                break
            end
        end
        actual_reps = length(fit_walls)
        fit_wall = median(fit_walls)
        n_evals = max(last.f_calls, 1)

        θ̂ = Vector{Float64}(last.θ)
        _, u_conv, _, _ = marginal_nll(case.prob, case.Q, θ̂; n_newton = n_newton)
        u_conv = Vector{Float64}(u_conv)

        cold = profile_eval_sections(case.prob, case.Q, θ̂; u_warm = nothing, n_newton = n_newton)
        warmsec = profile_eval_sections(case.prob, case.Q, θ̂; u_warm = u_conv, n_newton = n_newton)

        estep_total = cold.estep_wall * 1 + warmsec.estep_wall * max(n_evals - 1, 0)
        logdetP_total = warmsec.logdetP_wall * n_evals
        kron_total = warmsec.kron_wall * n_evals
        tak_total = warmsec.tak_wall * n_evals
        section_sum = estep_total + logdetP_total + kron_total + tak_total
        rel_err = abs(section_sum - fit_wall) / fit_wall
        within_10pct = rel_err <= 0.10
        ok_all &= within_10pct

        # fd_vcov TSV row: projected from ONE representative cold call.
        nθ = length(θ̂)
        h = 1e-4
        θp = copy(θ̂); θp[1] += h
        t_fd = @timed marginal_and_exact_grad(case.prob, case.Q, θp; u0 = nothing, n_newton = n_newton)
        fd_calls = 2 * nθ
        fd_wall_proj = t_fd.time * fd_calls
        fd_bytes_proj = t_fd.bytes * fd_calls

        push!(meta_lines, "# p=$p reps_used=$actual_reps fit_wall_median_s=$(round(fit_wall, digits=4)) n_evals(f_calls)=$n_evals estep_path_cold=$(cold.path) estep_path_warm=$(warmsec.path) section_sum_s=$(round(section_sum, digits=4)) rel_err_pct=$(round(100rel_err, digits=2)) within_10pct=$within_10pct converged=$(last.converged) loglik=$(round(last.loglik, digits=4))")

        sections = [
            ("estep_newton_chol", estep_total, cold.estep_count + warmsec.estep_count, cold.estep_bytes + warmsec.estep_bytes),
            ("logdetP_chol", logdetP_total, warmsec.logdetP_count, warmsec.logdetP_bytes),
            ("kron_prior", kron_total, warmsec.kron_count, warmsec.kron_bytes),
            ("takahashi", tak_total, warmsec.tak_count, warmsec.tak_bytes),
            ("fd_vcov", fd_wall_proj, fd_calls, fd_bytes_proj),
        ]
        for r in 1:actual_reps
            for (name, wall, count, bytes) in sections
                push!(tsv_lines, @sprintf("%d\t%d\t%s\t%.6f\t%d\t%d", p, r, name, wall, count, bytes))
            end
        end

        @printf "p=%d fit_wall_median=%.3fs section_sum=%.3fs rel_err=%.1f%% within_10pct=%s (reps=%d)\n" p fit_wall section_sum (100rel_err) within_10pct actual_reps
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
        println("GATE G3.1 FAIL one or more p had section-sum vs fit-wall relative error > 10% (see ", out_path, ")")
    end
    return ok_all
end

# -----------------------------------------------------------------------------
# Gate G3.2: --gate baseline --p 2000
# -----------------------------------------------------------------------------

function gate_baseline(p::Int)
    banked_s = 52.9
    seed = _seed_for(p)
    case = make_case(p; seed = seed, nrep = 4)
    fit_case(case.prob, case.Q, case.β0)  # warmup
    t = @elapsed r = fit_case(case.prob, case.Q, case.β0)
    rel = abs(t - banked_s) / banked_s
    ok = rel <= 0.20
    @printf "baseline p=%d wall=%.2fs banked=%.1fs rel=%.1f%% converged=%s loglik=%.2f\n" p t banked_s (100rel) r.converged r.loglik
    if ok
        println("GATE G3.2 PASS")
    else
        println("GATE G3.2 FAIL wall=$(round(t, digits=2))s vs banked $(banked_s)s (rel $(round(100rel, digits=1))%)")
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

        _, u_conv, _, _ = marginal_nll(case.prob, case.Q, θ̂; n_newton = n_newton)
        u_conv = Vector{Float64}(u_conv)

        t_cold = @timed marginal_and_exact_grad(case.prob, case.Q, θp; u0 = nothing, n_newton = n_newton)
        t_warm = @timed marginal_and_exact_grad(case.prob, case.Q, θp; u0 = u_conv, n_newton = n_newton)

        βp, lcp = unpack_theta(case.prob, θp)
        Λp = lc_to_Λ(lcp); Pp = prior_precision(case.Q, inv(Λp))
        _, _, _, _, iters_cold = _shadow_estep_robust(case.prob, Pp, βp; u0 = nothing, n_newton = n_newton)
        _, calls_warm, path_warm = _shadow_estep_mode(case.prob, Pp, βp; u0 = u_conv, n_newton = n_newton)

        n_calls_expected = 2 * nθ
        proj_cold_total_s = t_cold.time * n_calls_expected
        proj_warm_total_s = t_warm.time * n_calls_expected
        speedup = t_cold.time / max(t_warm.time, 1e-9)

        @printf "fdvcov p=%d n_theta=%d expected_calls(2*n_theta)=%d\n" p nθ n_calls_expected
        @printf "  cold: 1 call wall=%.4fs cold_newton_iters=%d bytes=%d  -> projected total for all %d calls = %.2fs\n" t_cold.time iters_cold t_cold.bytes n_calls_expected proj_cold_total_s
        @printf "  warm(u_hat): 1 call wall=%.4fs shadow_chol_calls=%d path=%s bytes=%d -> projected total for all %d calls = %.2fs\n" t_warm.time calls_warm path_warm t_warm.bytes n_calls_expected proj_warm_total_s
        @printf "  cold/warm speedup per call = %.2fx\n" speedup

        ok = isfinite(t_cold.time) && isfinite(t_warm.time) && iters_cold > 0
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
