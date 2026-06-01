# profile_inference_quick.jl -- quick timing for profile-likelihood and bootstrap.
#
# This isolates the inference pipeline cost from the single-fit crossed-Laplace
# benchmark. It intentionally uses small deterministic Gaussian fixtures so the
# script stays cheap enough to run during engine work.
#
# Run:
#   julia --project=bench bench/profile_inference_quick.jl

import Pkg
Pkg.activate(dirname(@__DIR__))

using DRM
using LinearAlgebra, Printf, Random, Statistics
using Distributions: Chisq, quantile
import Optim

BLAS.set_num_threads(1)

const OUT = joinpath(@__DIR__, "..", "report", "inference-profile-quick.md")

function fixed_gaussian_fixture()
    rng = MersenneTwister(8101)
    n = 600
    x = randn(rng, n)
    z = randn(rng, n)
    y = 0.4 .+ 0.75 .* x .- 0.35 .* z .+ exp(-0.45) .* randn(rng, n)
    form = bf(@formula(y ~ x + z), @formula(sigma ~ 1))
    return form, (; y, x, z)
end

function crossed_gaussian_fixture()
    rng = MersenneTwister(8102)
    n = 900
    G = 20
    H = 20
    x = randn(rng, n)
    g = [Symbol("g", rand(rng, 1:G)) for _ in 1:n]
    h = [Symbol("h", rand(rng, 1:H)) for _ in 1:n]
    bg = 0.45 .* randn(rng, G)
    bh = 0.35 .* randn(rng, H)
    y = [0.25 + 0.55 * x[i] + bg[parse(Int, String(g[i])[2:end])] +
         bh[parse(Int, String(h[i])[2:end])] + 0.45 * randn(rng) for i in 1:n]
    form = bf(@formula(y ~ x + (1 | g) + (1 | h)), @formula(sigma ~ 1))
    return form, (; y = Float64.(y), x, g, h)
end

function timecall(f)
    out = nothing
    t = @elapsed out = f()
    return t, out
end

function profiled_nll_warm(nll, θhat, k, v, ustart)
    p = length(θhat)
    idx = [i for i in 1:p if i != k]
    function obj(u)
        θ = Vector{eltype(u)}(undef, p)
        θ[k] = convert(eltype(u), v)
        @inbounds for (t, i) in enumerate(idx)
            θ[i] = u[t]
        end
        return nll(θ)
    end
    res = Optim.optimize(obj, ustart, Optim.LBFGS(); autodiff = :forward)
    return Optim.minimum(res), Optim.minimizer(res)
end

function profile_endpoint_warm(nll, θhat, k, nllhat, half, s, dir)
    idx = [i for i in 1:length(θhat) if i != k]
    ustart = copy(θhat[idx])
    target = nllhat + half
    function h(t)
        val, u = profiled_nll_warm(nll, θhat, k, θhat[k] + dir * t, ustart)
        ustart .= u
        return val - target
    end
    tlo = 0.0
    thi = s
    hval = h(thi)
    iters = 0
    while hval < 0 && iters < 40
        tlo = thi
        thi *= 1.6
        hval = h(thi)
        iters += 1
    end
    hval < 0 && return dir < 0 ? -Inf : Inf
    for _ in 1:60
        tm = (tlo + thi) / 2
        h(tm) < 0 ? (tlo = tm) : (thi = tm)
        thi - tlo < 1e-7 && break
    end
    return θhat[k] + dir * (tlo + thi) / 2
end

function profile_ci_warm(fit; level = 0.95)
    nll = fit.nll
    θhat = copy(fit.theta)
    nllhat = nll(θhat)
    half = quantile(Chisq(1), level) / 2
    se = sqrt.(diag(fit.vcov))
    out = NamedTuple[]
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, k) in enumerate(r)
            est = θhat[k]
            s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(est), 1.0)
            lo = profile_endpoint_warm(nll, θhat, k, nllhat, half, s, -1)
            hi = profile_endpoint_warm(nll, θhat, k, nllhat, half, s, +1)
            push!(out, (param = pp, coef = nms[j], estimate = est, lower = lo, upper = hi))
        end
    end
    return out
end

function profile_ci_threaded_warm(fit; level = 0.95)
    nll = fit.nll
    θhat = copy(fit.theta)
    nllhat = nll(θhat)
    half = quantile(Chisq(1), level) / 2
    se = sqrt.(diag(fit.vcov))
    jobs = NamedTuple[]
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, k) in enumerate(r)
            push!(jobs, (param = pp, coef = nms[j], k = k))
        end
    end
    out = Vector{NamedTuple}(undef, length(jobs))
    Threads.@threads for i in eachindex(jobs)
        job = jobs[i]
        k = job.k
        est = θhat[k]
        s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(est), 1.0)
        lo = profile_endpoint_warm(nll, θhat, k, nllhat, half, s, -1)
        hi = profile_endpoint_warm(nll, θhat, k, nllhat, half, s, +1)
        out[i] = (param = job.param, coef = job.coef, estimate = est, lower = lo, upper = hi)
    end
    return out
end

form_fixed, data_fixed = fixed_gaussian_fixture()
drm(form_fixed, Gaussian(); data = data_fixed)
GC.gc()
t_fit_fixed, fit_fixed = timecall(() -> drm(form_fixed, Gaussian(); data = data_fixed))
confint(fit_fixed; method = :wald)
confint(fit_fixed; method = :profile)
bootstrap_ci(form_fixed, Gaussian(); data = data_fixed, B = 2, rng = MersenneTwister(90))
GC.gc()
t_wald, wald = timecall(() -> confint(fit_fixed; method = :wald))
t_profile, prof = timecall(() -> confint(fit_fixed; method = :profile))
t_boot20, boot20 = timecall(() -> bootstrap_ci(form_fixed, Gaussian(); data = data_fixed, B = 20, rng = MersenneTwister(91)))

form_crossed, data_crossed = crossed_gaussian_fixture()
drm(form_crossed, Gaussian(); data = data_crossed)
GC.gc()
t_fit_crossed, fit_crossed = timecall(() -> drm(form_crossed, Gaussian(); data = data_crossed))
confint(fit_crossed; method = :profile)
profile_ci_warm(fit_crossed)
profile_ci_threaded_warm(fit_crossed)
GC.gc()
t_profile_crossed, prof_crossed = timecall(() -> confint(fit_crossed; method = :profile))
t_profile_crossed_warm, prof_crossed_warm = timecall(() -> profile_ci_warm(fit_crossed))
t_profile_crossed_threaded, prof_crossed_threaded = timecall(() -> profile_ci_threaded_warm(fit_crossed))
warm_delta = maximum(max(abs(prof_crossed[i].lower - prof_crossed_warm[i].lower),
                         abs(prof_crossed[i].upper - prof_crossed_warm[i].upper))
                     for i in eachindex(prof_crossed))
threaded_delta = maximum(max(abs(prof_crossed[i].lower - prof_crossed_threaded[i].lower),
                             abs(prof_crossed[i].upper - prof_crossed_threaded[i].upper))
                         for i in eachindex(prof_crossed))

mkpath(dirname(OUT))
open(OUT, "w") do io
    println(io, "# Quick inference profile")
    println(io)
    println(io, "CPU-aware run: Julia threads = $(Threads.nthreads()), BLAS threads = $(BLAS.get_num_threads()).")
    println(io)
    println(io, "| task | fixture | n | params | elapsed/s |")
    println(io, "|:-----|:--------|--:|-------:|----------:|")
    @printf(io, "| fit | fixed Gaussian | %d | %d | %.4f |\n", length(data_fixed.y), length(coef(fit_fixed)), t_fit_fixed)
    @printf(io, "| Wald CI | fixed Gaussian | %d | %d | %.4f |\n", length(data_fixed.y), length(wald), t_wald)
    @printf(io, "| profile CI | fixed Gaussian | %d | %d | %.4f |\n", length(data_fixed.y), length(prof), t_profile)
    @printf(io, "| bootstrap CI B=20 | fixed Gaussian | %d | %d | %.4f |\n", length(data_fixed.y), length(boot20), t_boot20)
    @printf(io, "| fit | crossed Gaussian | %d | %d | %.4f |\n", length(data_crossed.y), length(coef(fit_crossed)), t_fit_crossed)
    @printf(io, "| profile CI | crossed Gaussian | %d | %d | %.4f |\n", length(data_crossed.y), length(prof_crossed), t_profile_crossed)
    @printf(io, "| profile CI warm prototype | crossed Gaussian | %d | %d | %.4f |\n", length(data_crossed.y), length(prof_crossed_warm), t_profile_crossed_warm)
    @printf(io, "| profile CI threaded warm prototype | crossed Gaussian | %d | %d | %.4f |\n", length(data_crossed.y), length(prof_crossed_threaded), t_profile_crossed_threaded)
    println(io)
    println(io, "Interpretation guardrails:")
    println(io, "- This measures DRM.jl local costs only; it is not an R-vs-Julia comparison.")
    println(io, "- Profile CI refits the nuisance parameters many times per coefficient, so this is the next pipeline target after bootstrap.")
    @printf(io, "- Warm prototype max endpoint delta versus current profile CI: %.3e.\n", warm_delta)
    @printf(io, "- Threaded warm prototype max endpoint delta versus current profile CI: %.3e.\n", threaded_delta)
    println(io, "- The bootstrap row is serial in this script; threaded bootstrap should be measured separately with explicit thread counts.")
end

@printf("fixed fit %.4fs, profile %.4fs, bootstrap B=20 %.4fs\n", t_fit_fixed, t_profile, t_boot20)
@printf("crossed fit %.4fs, crossed profile %.4fs, warm %.4fs, threaded warm %.4fs, deltas %.3e/%.3e\n",
    t_fit_crossed, t_profile_crossed, t_profile_crossed_warm, t_profile_crossed_threaded, warm_delta, threaded_delta)
println("wrote ", OUT)
