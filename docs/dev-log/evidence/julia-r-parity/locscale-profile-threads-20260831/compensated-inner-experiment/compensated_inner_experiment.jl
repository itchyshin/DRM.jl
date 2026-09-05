#!/usr/bin/env julia
# PREPARED ONLY — no execution without review.  A bounded, no-refit comparison
# at the retained exact theta.  The override exists only in this process.
using DRM
using Serialization, SHA, LinearAlgebra, SparseArrays, Dates

const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const OUTDIR = joinpath(ROOT, "compensated-inner-experiment")
const FROZEN = joinpath(ROOT, "wald-stencil-diagnostic", "wald-stencil-20260831T171108Z.jls")
const FROZEN_SHA = "25084fd208dbbe9f863331b19b70c2ed7f3407d2135095a8cc0e07dcda3647a3"
const INPUT = joinpath(ROOT, "wald-stencil-diagnostic", "exact-theta-reference-rounding-20260831T172237Z.jls")
const INPUT_SHA = "1001c0ac0a3aa691518d20c6e0b57f316f7c4271474b228c299e7ec0771071d4"
const HELPER = joinpath(ROOT, "whitened-oracle", "fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl")
const HELPER_SHA = "405f28114a2d665cf40bc8c4ec46ec324422a00a141250849e35bead4dace73d"
const STAMP = get(ENV, "S11_STAMP", "UNSET")
const SOURCE_FILES = ["src/locscale_fit.jl", "src/locscale_grad.jl", "src/locscale_inner.jl",
                      "src/locscale_marginal.jl", "src/locscale_infer.jl",
                      "test/test_locscale_profile_status.jl"]
sha256_file(path) = bytes2hex(sha256(read(path)))
hashes() = Dict(path => sha256_file(path) for path in SOURCE_FILES)
const S11_FALLBACK_CALLS = Ref(0)
const S11_CANDIDATE_CALLS = Ref(0)

function s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
    S11_FALLBACK_CALLS[] += 1
    return invoke(DRM._ls_joint_grad, Tuple{Any,Any,Any,Any,Any,Any,Any,Any,Any},
                  kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
end

# Load only imports/constants/function definitions from the immutable independent
# oracle; stop before its first ordinary statement, so no old diagnostic runs.
function helper_definition(ex)
    ex isa LineNumberNode && return true
    ex isa Expr || return false
    ex.head in (:using, :import, :const, :function, :macro) && return true
    return ex.head === :(=) && ex.args[1] isa Expr && ex.args[1].head === :call
end
function load_helper()
    @assert sha256_file(HELPER) == HELPER_SHA
    for ex in Meta.parseall(read(HELPER, String)).args
        helper_definition(ex) || break
        ex isa LineNumberNode || Core.eval(@__MODULE__, ex)
    end
end
load_helper() # before compiling calls to gamma_data: avoids eval/world-age issues.

function exact_design(retained)
    dat = retained.data
    Xmu = hcat(ones(Float64, length(dat.y)), Float64.(dat.x))
    Xpsi = ones(Float64, length(dat.y), 1)
    gidx = repeat(collect(1:dat.G), inner=dat.m)
    Q = sparse(1.0I, dat.G, dat.G)
    @assert dat.G == 4 && length(dat.y) == 32 && dat.species == gidx
    return (; y=Float64.(dat.y), Xmu, Xpsi, gidx, G=dat.G, Q)
end
function production_parts(design, theta)
    pμ, pψ = size(design.Xmu, 2), size(design.Xpsi, 2)
    lambda = theta[pμ+pψ+1:pμ+pψ+3]
    P = DRM.prior_precision(design.Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
    eta0 = design.Xmu * theta[1:pμ]
    psi0 = design.Xpsi * theta[pμ+1:pμ+pψ]
    return (; pμ, pψ, lambda, P, eta0, psi0)
end

# Independently recompute a fixed-P64 joint gradient in BigFloat. This check is
# diagnostic only; it is never dispatched by the proposed Float64 override.
function independent_bigfixedP_gradient(design, parts, a64)
    setprecision(BigFloat, 256) do
        y = BigFloat.(design.y); eta0 = BigFloat.(parts.eta0); psi0 = BigFloat.(parts.psi0)
        a = BigFloat.(a64); P = BigFloat.(parts.P)
        g = P * a
        for i in eachindex(y)
            group = design.gidx[i]
            _, ge, gp, _, _, _ = gamma_data(y[i], eta0[i] + a[2group-1], psi0[i] + a[2group])
            g[2group-1] += ge
            g[2group] += gp
        end
        return g
    end
end

# Generic Float64 baseline, recorded before any extension is installed.
function case_result(design, parts, label, astart)
    fallback_before = S11_FALLBACK_CALLS[]
    candidate_before = S11_CANDIDATE_CALLS[]
    a, ch, inner_ok = DRM._ls_inner_mode(Val(:gamma), design.y, parts.eta0, parts.psi0,
                                          design.gidx, design.G, parts.P; a0=astart)
    raw, marginal_a, raw_ok = DRM._ls_marginal_nll(Val(:gamma), design.y, parts.eta0,
        parts.psi0, design.gidx, design.G, parts.P; a0=astart)
    grad = DRM._ls_joint_grad(Val(:gamma), design.y, parts.eta0, parts.psi0,
                               design.gidx, a, parts.P)
    bigfixed = independent_bigfixedP_gradient(design, parts, a)
    bigbound = setprecision(BigFloat, 256) do
        big"1e-9" * (1 + norm(BigFloat.(a)))
    end
    return (label, start=copy(astart), mode=copy(a), hessian_pd=isposdef(ch), inner_ok,
            raw_marginal=raw, raw_ok, marginal_mode=copy(marginal_a),
            gradient=copy(grad), gradient_l2=norm(grad), gradient_inf=maximum(abs, grad),
            certificate_bound=1e-9 * (1 + norm(a)),
            independent_bigfixed_inf=maximum(abs, bigfixed),
            independent_bigfixed_l2=norm(bigfixed),
            independent_bigfixed_certificate_bound=bigbound,
            independent_bigfixed_certified=(norm(bigfixed) <= bigbound),
            native_vs_bigfixed_inf=maximum(abs, BigFloat.(grad) .- bigfixed),
            generic_fallback_calls=S11_FALLBACK_CALLS[] - fallback_before,
            candidate_method_calls=S11_CANDIDATE_CALLS[] - candidate_before,
            iterations=:unavailable_from_original_api,
            termination=:unavailable_from_original_api)
end

# Install only after the generic baseline has been recorded. The extension is
# process-local: it leaves neither source nor a persisted method-table change.
function install_compensated_override!()
@eval DRM begin
# Process-local candidate. It is more specific than DRM's unconstrained generic
# nine-argument method and is selected only for canonical Vector/Matrix Float64
# values and SparseMatrixCSC{Float64,Int}. Every arithmetic-support refusal
# dispatches to the unmodified generic method via its nine-Any signature.
function _ls_joint_grad(kind,
                            y::Vector{Float64}, eta0::Vector{Float64}, psi0::Vector{Float64},
                            gidx::Vector{Int}, a::Vector{Float64},
                            P::SparseMatrixCSC{Float64,Int},
                            Zeta::Matrix{Float64}, Zpsi::Matrix{Float64})
    Main.S11_CANDIDATE_CALLS[] += 1
    nstate = length(a)
    hi = zeros(Float64, nstate)
    lo = zeros(Float64, nstate)
    bound = zeros(Float64, nstate)
    # Sparse prior rows: track each P[row,col] * a[col] term and its FMA residual.
    @inbounds for col in axes(P, 2)
        for ptr in nzrange(P, col)
            row = P.rowval[ptr]
            pieces = DRM._ls_twoprod_finite(P.nzval[ptr], a[col])
            pieces === nothing && return Main.s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
            for term in pieces
                acc = DRM._ls_tracked_add(hi[row], lo[row], bound[row], term)
                acc === nothing && return Main.s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
                hi[row], lo[row], bound[row] = acc
            end
        end
    end
    # Data rows: every g_eta * Zeta and g_psi * Zpsi term is separately tracked.
    @inbounds for i in eachindex(y)
        group = gidx[i]
        u, v = 2group - 1, 2group
        etai = eta0[i] + Zeta[i, 1] * a[u] + Zeta[i, 2] * a[v]
        psii = psi0[i] + Zpsi[i, 1] * a[u] + Zpsi[i, 2] * a[v]
        geta, gpsi = DRM._ls_grad(kind, y[i], etai, psii)
        for (row, g, z) in ((u, geta, Zeta[i, 1]), (u, gpsi, Zpsi[i, 1]),
                            (v, geta, Zeta[i, 2]), (v, gpsi, Zpsi[i, 2]))
            pieces = DRM._ls_twoprod_finite(g, z)
            pieces === nothing && return Main.s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
            for term in pieces
                acc = DRM._ls_tracked_add(hi[row], lo[row], bound[row], term)
                acc === nothing && return Main.s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
                hi[row], lo[row], bound[row] = acc
            end
        end
    end
    grad = Vector{Float64}(undef, nstate)
    @inbounds for row in eachindex(grad)
        final = DRM._ls_tracked_finalize(hi[row], lo[row], bound[row])
        final === nothing && return Main.s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        grad[row] = final[1]
    end
    return grad
end
end # @eval DRM
return nothing
end

function main()
    STAMP == "UNSET" && error("set S11_STAMP to a fresh actual UTC stamp")
    before = hashes()
    @assert sha256_file(FROZEN) == FROZEN_SHA
    @assert sha256_file(INPUT) == INPUT_SHA
    frozen, input = deserialize(FROZEN), deserialize(INPUT)
    @assert frozen.inputs_unchanged && frozen.theta_engine == input.theta_engine
    design = exact_design(frozen); theta = frozen.theta_engine; parts = production_parts(design, theta)
    input_parts = production_parts(input.design, input.theta_engine)
    input_P_unchanged = parts.P == input_parts.P
    neighbor = only(p for p in frozen.probes if p.k == 6 && p.direction == 1)
    @assert neighbor.inner_ok && neighbor.nll_ok
    refstart = copy(only(s for s in input.starts if s[1] == :independent_reference_rounded)[2])
    starts = [(:zero, zeros(Float64, 2design.G)),
              (:failed_base_iterate, copy(frozen.base.inner_mode)),
              (:certified_neighbor_k6_plus, copy(neighbor.inner_mode)),
              (:independent_reference_rounded, refstart)]
    baseline = [case_result(design, parts, label, start) for (label, start) in starts]
    baseline_zero = only(x for x in baseline if x.label == :zero)
    baseline_zero_reproduces_failure = !baseline_zero.inner_ok && !baseline_zero.raw_ok
    install_compensated_override!()
    compensated = [Base.invokelatest(case_result, design, parts, label, start)
                   for (label, start) in starts]
    candidate_method_reached = S11_CANDIDATE_CALLS[] > 0
    after = hashes()
    all_claims_valid = before == after && input_P_unchanged &&
                       baseline_zero_reproduces_failure && candidate_method_reached &&
                       S11_FALLBACK_CALLS[] == 0
    receipt = (kind=:compensated_inner_process_local_experiment, frozen_sha256=FROZEN_SHA,
               input_sha256=INPUT_SHA, helper_sha256=HELPER_SHA, theta=theta, design=design,
               starts=starts, baseline=baseline, compensated=compensated,
               generic_fallback_calls=S11_FALLBACK_CALLS[],
               candidate_method_calls=S11_CANDIDATE_CALLS[],
               baseline_zero_reproduces_failure=baseline_zero_reproduces_failure,
               input_P_unchanged=input_P_unchanged,
               candidate_method_reached=candidate_method_reached,
               before_hashes=before, after_hashes=after,
               inputs_unchanged=(before == after && input_P_unchanged),
               all_claims_valid=all_claims_valid,
               override_method=sprint(show, which(DRM._ls_joint_grad,
                   Tuple{Val{:gamma},Vector{Float64},Vector{Float64},Vector{Float64},Vector{Int},
                         Vector{Float64},SparseMatrixCSC{Float64,Int},Matrix{Float64},Matrix{Float64}})),
               script_source=read(@__FILE__, String), julia_version=VERSION, timestamp=STAMP)
    output = joinpath(OUTDIR, "compensated-inner-$(STAMP).jls")
    serialize(output, receipt)
    println("S11_COMPENSATED_RECEIPT ", output)
    all_claims_valid && println("S11_COMPENSATED_VALID candidate_calls=", S11_CANDIDATE_CALLS[])
end
main()
