#!/usr/bin/env julia
# Certificate-only fixed-state check.  It does not call DRM, an inner solver,
# an outer fit, or production likelihood/gradient code.
using LinearAlgebra
using SparseArrays
using Serialization
using SHA
using SpecialFunctions

const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const NEIGHBORS = joinpath(ROOT, "whitened-return-neighbors",
    "whitened-return-neighbors-20260831T182759Z.jls")
const NEIGHBORS_SHA = "c007a27a05121d47426b0e246b495caf3079563ec4f1c950c6d39ae344dbbd44"
const DESIGN = joinpath(ROOT, "post-compensation-profile",
    "post-compensation-profile-20260831T175800Z.jls")
const DESIGN_SHA = "fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"
const REPO = "/private/tmp/drm-parity-20260830/integration/DRM.jl"
const SOURCE_FILES = ["src/locscale_inner.jl", "src/locscale_grad.jl",
    "src/locscale_marginal.jl", "src/locscale_fit.jl", "src/locscale_infer.jl"]
const CLAMP = big"30"

sha256_file(path) = bytes2hex(sha256(read(path)))
source_hashes() = Dict(path => sha256_file(joinpath(REPO, path)) for path in SOURCE_FILES)
maxabs(x) = isempty(x) ? zero(eltype(x)) : maximum(abs, x)

# SpecialFunctions provides BigFloat digamma here but no BigFloat trigamma.
# This is the retained oracle's guarded, fourth-order Richardson derivative.
function trigamma_big(x)
    h = precision(x) <= 128 ? big"1e-8" : big"1e-16"
    central(step) = (digamma(x + step) - digamma(x - step)) / (2 * step)
    richardson(step) = (4 * central(step / 2) - central(step)) / 3
    coarse, refined = richardson(h), richardson(h / 2)
    gate = precision(x) <= 128 ? big"1e-27" : big"1e-55"
    @assert abs(coarse - refined) <= gate "trigamma h-versus-h/2 stability failed"
    return refined, (h_vs_h2=abs(coarse - refined), gate=gate)
end

function gamma_terms(y, eta, psi)
    s = exp(psi)
    rate = s * exp(-eta)
    ry = rate * y
    ell = loggamma(s) - s * log(rate) - (s - one(s)) * log(y) + ry
    geta = s - ry
    gpsi = s * (digamma(s) - log(rate) - one(s) - log(y)) + ry
    hee = ry
    hep = s - ry
    tri, stability = trigamma_big(s)
    hpp = gpsi - s + s^2 * tri
    return (; ell, geta, gpsi, hee, hep, hpp, stability)
end

function intended_components(d, theta64)
    theta = BigFloat.(theta64)
    L = BigFloat[exp(theta[4]) 0; theta[5] exp(theta[6])]
    B = kron(Matrix{BigFloat}(I, d.G, d.G), L)
    C = kron(BigFloat.(Matrix(d.Q)), Matrix{BigFloat}(I, 2, 2))
    Binv = B \ Matrix{BigFloat}(I, 2d.G, 2d.G)
    P = transpose(Binv) * C * Binv
    eta0 = BigFloat.(d.Xmu) * theta[1:2]
    psi0 = BigFloat.(d.Xpsi) * theta[3:3]
    return (; theta, L, B, C, P, eta0, psi0)
end

function independent_state(d, theta64, a64, bits)
    setprecision(BigFloat, bits) do
        c = intended_components(d, theta64)
        a = BigFloat.(a64)
        g = c.P * a
        J = dot(a, g) / 2
        H = copy(c.P)
        strict_clamp = true
        trigamma_records = NamedTuple[]
        for i in eachindex(d.y)
            group = d.gidx[i]
            mu, psi = c.eta0[i] + a[2group - 1], c.psi0[i] + a[2group]
            strict_clamp &= -CLAMP < mu < CLAMP && -CLAMP < psi < CLAMP
            term = gamma_terms(BigFloat(d.y[i]), mu, psi)
            J += term.ell
            g[2group - 1] += term.geta
            g[2group] += term.gpsi
            H[2group - 1, 2group - 1] += term.hee
            H[2group - 1, 2group] += term.hep
            H[2group, 2group - 1] += term.hep
            H[2group, 2group] += term.hpp
            push!(trigamma_records, term.stability)
        end
        ch = cholesky(Symmetric(H); check=false)
        bound = BigFloat(1e-9) * (1 + norm(a))
        return (; J, gradient=g, gradient_l2=norm(g), bound,
            certificate=(all(isfinite, g) && norm(g) <= bound),
            strict_gamma_clamp=strict_clamp, undamped_hpd=isposdef(ch),
            # Pivot record only; positive-definiteness is isposdef(ch).
            minimum_cholesky_pivot=minimum(abs2, diag(ch.L)),
            trigamma_records, L=c.L, B=c.B, C=c.C, P=c.P)
    end
end

function row_for_precision(d, row, bits)
    # `chosen` is the retained selected representable a64; `a` is the prior
    # returned a64, retained for the required objective-change comparison.
    selected = independent_state(d, row.theta, row.chosen, bits)
    original = independent_state(d, row.theta, row.a, bits)
    return (; bits, idx=row.idx, side=row.side, theta=copy(row.theta),
        original_a64=copy(row.a), selected_a64=copy(row.chosen),
        selection_changed=row.changed, maxabs_selection_change=row.maxabs_change,
        original_J=original.J, selected_J=selected.J,
        selected_minus_original_J=selected.J - original.J,
        original_gradient=original.gradient,
        original_gradient_l2=original.gradient_l2,
        original_bound=original.bound,
        selected_gradient=selected.gradient,
        selected_gradient_l2=selected.gradient_l2,
        selected_bound=selected.bound,
        selected_certificate=selected.certificate,
        selected_undamped_hpd=selected.undamped_hpd,
        selected_minimum_cholesky_pivot=selected.minimum_cholesky_pivot,
        selected_strict_gamma_clamp=selected.strict_gamma_clamp,
        selected_trigamma_records=selected.trigamma_records,
        intended_L=selected.L, intended_Q=BigFloat.(Matrix(d.Q)),
        intended_P=selected.P)
end

function certify_row(d, row)
    c128 = row_for_precision(d, row, 128)
    c256 = row_for_precision(d, row, 256)
    precision_consistent = abs(c128.selected_J - c256.selected_J) <= big"1e-20" &&
        abs(c128.selected_gradient_l2 - c256.selected_gradient_l2) <= big"1e-20"
    prospective_gate = c256.selected_certificate && c256.selected_undamped_hpd &&
        c256.selected_strict_gamma_clamp && precision_consistent
    return (; c128, c256, precision_consistent, prospective_gate)
end

function exact_design(input)
    d = input.design
    @assert d.kind == Val(:gamma) && d.G == 4 && length(d.y) == 32
    @assert size(d.Xmu) == (32, 2) && size(d.Xpsi) == (32, 1) && length(d.gidx) == 32
    return d
end

function main(output)
    @assert Base.Threads.nthreads() == 1 "runner did not pin JULIA_NUM_THREADS=1"
    @assert BLAS.get_num_threads() == 1 "runner did not pin OPENBLAS_NUM_THREADS=1"
    @assert sha256_file(NEIGHBORS) == NEIGHBORS_SHA
    @assert sha256_file(DESIGN) == DESIGN_SHA
    before = source_hashes()
    selection = deserialize(NEIGHBORS)
    input = deserialize(DESIGN)
    @assert selection.input_sha256 == "b841698cace0c39867995a8296ce90ac25ff2a08f68db32314e293bf49d044c2"
    @assert selection.design_sha256 == DESIGN_SHA
    @assert length(selection.rows) == 4
    d = exact_design(input)
    rows = [certify_row(d, row) for row in selection.rows]
    after = source_hashes()
    @assert before == after
    receipt = (; kind=:fixed_point_return_certificate,
        neighbors_input_sha256=NEIGHBORS_SHA, design_input_sha256=DESIGN_SHA,
        runtime_threads=(julia=Base.Threads.nthreads(), blas=BLAS.get_num_threads()),
        before_hashes=before, after_hashes=after, source_unchanged=(before == after),
        rows, prospective_gate=all(row.prospective_gate for row in rows),
        scope="Fixed saved a64 certificate only; no mode solve, outer fit, production call, or claim that the prior three returned-a failures are repaired.")
    serialize(output, receipt)
    for row in rows
        println((; row.c256.idx, row.c256.side,
            selected_l2=Float64(row.c256.selected_gradient_l2),
            bound=Float64(row.c256.selected_bound), row.c256.selected_certificate,
            row.c256.selected_undamped_hpd, row.c256.selected_strict_gamma_clamp,
            delta_J=Float64(row.c256.selected_minus_original_J), row.precision_consistent,
            row.prospective_gate))
    end
    @assert receipt.prospective_gate "fixed selected states did not satisfy the prospective certificate gate"
    println("S11_FIXED_POINT_CERTIFICATE_COMPLETE")
end

length(ARGS) == 1 || error("usage: diagnose.jl <fresh-output.jls>")
main(only(ARGS))
