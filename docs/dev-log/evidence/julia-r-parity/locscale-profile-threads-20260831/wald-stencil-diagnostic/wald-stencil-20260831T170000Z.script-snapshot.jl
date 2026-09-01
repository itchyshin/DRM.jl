#!/usr/bin/env julia
# Single-use, no-edit / no-profile discriminator for the canonical status fixture.
# It deliberately fits with se=false, then inspects the ordinary 1e-5 Wald stencil.
using DRM
using Random, Distributions, LinearAlgebra, Serialization, SHA

const OUTDIR = "/private/tmp/drm-parity-20260830/profile-threads-s11/wald-stencil-diagnostic"
const RESULT = joinpath(OUTDIR, "wald-stencil-20260831T170000Z.jls")
const SOURCE_FILES = [
    "src/locscale_fit.jl", "src/locscale_grad.jl", "src/locscale_infer.jl",
    "src/locscale_inner.jl", "src/locscale_profile.jl",
    "test/test_locscale_profile_status.jl",
]
sha256_file(path) = bytes2hex(sha256(read(path)))
hashes() = Dict(path => sha256_file(path) for path in SOURCE_FILES)

function fixture()
    Random.seed!(20_260_831)
    G, m = 4, 8
    species = repeat(1:G, inner=m)
    x = repeat(range(-1.0, 1.0; length=m), G)
    eta = 0.70 .+ 0.55 .* x .+ (0.16 .* randn(G))[species]
    psi = 1.05 .+ (0.10 .* randn(G))[species]
    y = [begin
        shape = exp(psi[i]); mu = exp(eta[i])
        Float64(rand(Distributions.Gamma(shape, mu / shape)))
    end for i in eachindex(x)]
    return (; y, x, species, G, m)
end

function engine_theta(fit, obj)
    base = size(obj.Xμ, 2) + size(obj.Xψ, 2)
    perm = vcat(collect(1:base), [base + 1, base + 3, base + 2])
    θ = fit.theta[perm]
    @assert θ[perm] == fit.theta # involutive recov <-> engine mapping
    return θ, perm
end

function inspect_point(obj, θ)
    pμ = size(obj.Xμ, 2); pψ = size(obj.Xψ, 2)
    λ = θ[pμ+pψ+1:pμ+pψ+3]
    Λ = DRM._ls_lc_to_Λ(λ)
    P = DRM.prior_precision(obj.Q, DRM._ls_inv2x2(Λ))
    η0, ψ0 = obj.Xμ * θ[1:pμ], obj.Xψ * θ[pμ+1:pμ+pψ]
    value, a, nll_ok = DRM._ls_marginal_nll(obj.kind, obj.y, η0, ψ0, obj.gidx,
                                              obj.G, P; a0=nothing)
    inner_a, _, inner_ok = DRM._ls_inner_mode(obj.kind, obj.y, η0, ψ0, obj.gidx,
                                                obj.G, P; a0=nothing)
    grad = DRM._ls_marginal_grad(obj.kind, obj.y, obj.Xμ, obj.Xψ, obj.gidx,
                                  obj.G, obj.Q, θ; a0=nothing)
    return (theta=copy(θ), value=value, nll_ok=nll_ok, value_finite=isfinite(value),
            mode=copy(a), mode_finite=all(isfinite, a), inner_ok=inner_ok,
            inner_mode=copy(inner_a), inner_mode_finite=all(isfinite, inner_a),
            gradient=copy(grad), gradient_finite=all(isfinite, grad),
            gradient_maxabs=maximum(abs, grad), Lambda=Λ, P_finite=all(isfinite, P))
end

function main()
    before = hashes()
    dat = fixture()
    # Intentional diagnostic-only choice: skip Wald inversion so the returned
    # theta can be interrogated. This does not establish a replacement policy.
    fit = drm(
        bf(@formula(y ~ x + (1 | status_smoke | species)),
           @formula(sigma ~ 1 + (1 | status_smoke | species))),
        Gamma(); data=(; dat.y, dat.x, dat.species), se=false,
    )
    obj = fit.nll
    @assert obj isa DRM.LocScaleObjective
    θ, perm = engine_theta(fit, obj)
    base = inspect_point(obj, θ)
    h = 1e-5
    probes = NamedTuple[]
    for k in eachindex(θ), direction in (-1, 1)
        θprobe = copy(θ); θprobe[k] += direction * h
        point = inspect_point(obj, θprobe)
        push!(probes, merge((k=k, direction=direction, coordinate=θprobe[k]), point))
    end
    Hraw = Matrix{Float64}(undef, length(θ), length(θ))
    for k in eachindex(θ)
        gm = only(p.gradient for p in probes if p.k == k && p.direction == -1)
        gp = only(p.gradient for p in probes if p.k == k && p.direction == 1)
        Hraw[:, k] .= (gp .- gm) ./ (2h)
    end
    H = (Hraw + Hraw') ./ 2
    after = hashes()
    receipt = (
        kind=:canonical_locscale_wald_stencil_diagnostic,
        label=:se_false_diagnostic_only,
        source_root=realpath(dirname(pathof(DRM))),
        julia_version=string(VERSION),
        h=h,
        data=dat,
        fit_theta_recov=copy(fit.theta),
        theta_engine=θ,
        permutation_recov_to_engine=perm,
        fit_converged=fit.converged,
        base=base,
        probes=probes,
        Hraw=Hraw,
        H=H,
        H_finite=all(isfinite, H),
        before_hashes=before,
        after_hashes=after,
        inputs_unchanged=(before == after),
    )
    serialize(RESULT, receipt)
    println("S11_WALD_STENCIL_OK result=", RESULT,
            " sha256=", sha256_file(RESULT),
            " base_finite=", base.value_finite && base.gradient_finite,
            " finite_probes=", count(p -> p.value_finite && p.gradient_finite, probes),
            "/", length(probes), " H_finite=", receipt.H_finite,
            " inputs_unchanged=", receipt.inputs_unchanged)
end

main()
