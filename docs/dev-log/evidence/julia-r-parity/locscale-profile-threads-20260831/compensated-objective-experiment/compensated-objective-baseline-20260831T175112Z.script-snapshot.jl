#!/usr/bin/env julia
# PREPARED ONLY — root runs one fresh process for each S11_MODE after review.
# Modes: baseline | gradient | objective | both. No outer optimiser is called.
using DRM
using Serialization, SHA, LinearAlgebra, SparseArrays

const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const OUTDIR = joinpath(ROOT, "compensated-objective-experiment")
const FROZEN = joinpath(ROOT, "wald-stencil-diagnostic", "wald-stencil-20260831T171108Z.jls")
const FROZEN_SHA = "25084fd208dbbe9f863331b19b70c2ed7f3407d2135095a8cc0e07dcda3647a3"
const INPUT = joinpath(ROOT, "wald-stencil-diagnostic", "exact-theta-reference-rounding-20260831T172237Z.jls")
const INPUT_SHA = "1001c0ac0a3aa691518d20c6e0b57f316f7c4271474b228c299e7ec0771071d4"
const HELPER = joinpath(ROOT, "whitened-oracle", "fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl")
const HELPER_SHA = "405f28114a2d665cf40bc8c4ec46ec324422a00a141250849e35bead4dace73d"
const DIRECTION = joinpath(ROOT, "compensated-inner-experiment", "objective-direction", "objective-direction-20260831T174337Z.jls")
const DIRECTION_SHA = "3c6ac877d6c32e72f7650fe2a19ba7d131bab6ec35c17d504485388e31544e05"
const MODE = Symbol(get(ENV, "S11_MODE", "UNSET"))
const STAMP = get(ENV, "S11_STAMP", "UNSET")
const SOURCE_FILES = ["src/locscale_fit.jl", "src/locscale_grad.jl", "src/locscale_inner.jl",
                      "src/locscale_marginal.jl", "src/locscale_infer.jl",
                      "test/test_locscale_profile_status.jl"]
sha256_file(path) = bytes2hex(sha256(read(path)))
hashes() = Dict(path => sha256_file(path) for path in SOURCE_FILES)
const S11_GRAD_CANDIDATE_CALLS = Ref(0)
const S11_GRAD_FALLBACK_CALLS = Ref(0)
const S11_OBJECTIVE_CANDIDATE_CALLS = Ref(0)
const S11_OBJECTIVE_FALLBACK_CALLS = Ref(0)
const S11_OBJECTIVE_LAST = Ref{Any}(nothing)

# Helper definition import happens at top level, before `main` is defined. This
# imports no prior main/fit execution and avoids a compiled-caller world-age gap.
function helper_definition(ex)
    ex isa LineNumberNode && return true
    ex isa Expr || return false
    ex.head in (:using, :import, :const, :function, :macro) && return true
    return ex.head === :(=) && ex.args[1] isa Expr && ex.args[1].head === :call
end
@assert sha256_file(HELPER) == HELPER_SHA
for ex in Meta.parseall(read(HELPER, String)).args
    helper_definition(ex) || break
    ex isa LineNumberNode || Core.eval(@__MODULE__, ex)
end

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

# Independently evaluated fixed-P64 Gamma objective/gradient. Float64 inputs
# are lifted exactly; this never dispatches to a proposed Float64 override.
function independent_bigfixed(design, parts, a64)
    nll64 = Float64[]
    @inbounds for i in eachindex(design.y)
        group = design.gidx[i]
        push!(nll64, DRM._ls_nll(Val(:gamma), design.y[i],
                                 parts.eta0[i] + a64[2group-1], parts.psi0[i] + a64[2group]))
    end
    setprecision(BigFloat, 256) do
        y = BigFloat.(design.y); eta0 = BigFloat.(parts.eta0); psi0 = BigFloat.(parts.psi0)
        a = BigFloat.(a64); P = BigFloat.(parts.P)
        g = P * a; prior = dot(a, P * a) / 2; J = prior
        for i in eachindex(y)
            group = design.gidx[i]
            nll, ge, gp, _, _, _ = gamma_data(y[i], eta0[i] + a[2group-1], psi0[i] + a[2group])
            J += nll; g[2group-1] += ge; g[2group] += gp
        end
        frozen_nll_J = sum(BigFloat.(nll64)) + prior
        return (J_full=J, J_frozen_nll=frozen_nll_J, grad=g)
    end
end

function s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
    S11_GRAD_FALLBACK_CALLS[] += 1
    return invoke(DRM._ls_joint_grad, Tuple{Any,Any,Any,Any,Any,Any,Any,Any,Any},
                  kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
end
function s11_generic_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
    S11_OBJECTIVE_FALLBACK_CALLS[] += 1
    S11_OBJECTIVE_LAST[] = nothing
    return invoke(DRM._ls_joint, Tuple{Any,Any,Any,Any,Any,Any,Any,Any,Any},
                  kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
end

# The gradient candidate is installed only in gradient/both fresh processes.
# Every product and FMA residual is tracked in the output row accumulator.
if MODE in (:gradient, :both)
function DRM._ls_joint_grad(kind,
                            y::Vector{Float64}, eta0::Vector{Float64}, psi0::Vector{Float64},
                            gidx::Vector{Int}, a::Vector{Float64},
                            P::SparseMatrixCSC{Float64,Int},
                            Zeta::Matrix{Float64}, Zpsi::Matrix{Float64})
    S11_GRAD_CANDIDATE_CALLS[] += 1
    hi = zeros(Float64, length(a)); lo = zeros(Float64, length(a)); bound = zeros(Float64, length(a))
    @inbounds for col in axes(P, 2), ptr in nzrange(P, col)
        row = P.rowval[ptr]
        pieces = DRM._ls_twoprod_finite(P.nzval[ptr], a[col])
        pieces === nothing && return s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        for term in pieces
            acc = DRM._ls_tracked_add(hi[row], lo[row], bound[row], term)
            acc === nothing && return s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
            hi[row], lo[row], bound[row] = acc
        end
    end
    @inbounds for i in eachindex(y)
        group = gidx[i]; u, v = 2group-1, 2group
        etai = eta0[i] + Zeta[i,1]*a[u] + Zeta[i,2]*a[v]
        psii = psi0[i] + Zpsi[i,1]*a[u] + Zpsi[i,2]*a[v]
        ge, gp = DRM._ls_grad(kind, y[i], etai, psii)
        for (row, q, z) in ((u,ge,Zeta[i,1]), (u,gp,Zpsi[i,1]),
                            (v,ge,Zeta[i,2]), (v,gp,Zpsi[i,2]))
            pieces = DRM._ls_twoprod_finite(q, z)
            pieces === nothing && return s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
            for term in pieces
                acc = DRM._ls_tracked_add(hi[row], lo[row], bound[row], term)
                acc === nothing && return s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
                hi[row], lo[row], bound[row] = acc
            end
        end
    end
    grad = Vector{Float64}(undef, length(a))
    @inbounds for row in eachindex(grad)
        final = DRM._ls_tracked_finalize(hi[row], lo[row], bound[row])
        final === nothing && return s11_generic_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        grad[row] = final[1]
    end
    return grad
end
end

# Objective candidate: data nll terms and each 0.5*a[i]*P[i,j]*a[j]
# contribution are compensated separately. The factor one half is applied to
# every triple-product FMA piece and checked for normal/zero support first.
if MODE in (:objective, :both)
function DRM._ls_joint(kind,
                       y::Vector{Float64}, eta0::Vector{Float64}, psi0::Vector{Float64},
                       gidx::Vector{Int}, a::Vector{Float64},
                       P::SparseMatrixCSC{Float64,Int},
                       Zeta::Matrix{Float64}, Zpsi::Matrix{Float64})
    S11_OBJECTIVE_CANDIDATE_CALLS[] += 1
    # A single accumulator deliberately retains every low part through the
    # data/prior combination and only then performs the final rounding.
    hi = lo = bound = 0.0
    @inbounds for i in eachindex(y)
        group = gidx[i]; u, v = 2group-1, 2group
        etai = eta0[i] + Zeta[i,1]*a[u] + Zeta[i,2]*a[v]
        psii = psi0[i] + Zpsi[i,1]*a[u] + Zpsi[i,2]*a[v]
        term = DRM._ls_nll(kind, y[i], etai, psii)
        acc = DRM._ls_tracked_add(hi, lo, bound, term)
        acc === nothing && return s11_generic_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        hi, lo, bound = acc
    end
    @inbounds for col in axes(P,2), ptr in nzrange(P,col)
        row = P.rowval[ptr]
        pieces = DRM._ls_tripleprod_pieces(a[row], P.nzval[ptr], a[col])
        pieces === nothing && return s11_generic_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        for rawterm in pieces
            term = 0.5 * rawterm
            (isfinite(term) && (term == 0.0 || abs(term) >= floatmin(Float64))) ||
                return s11_generic_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
            acc = DRM._ls_tracked_add(hi, lo, bound, term)
            acc === nothing && return s11_generic_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
            hi, lo, bound = acc
        end
    end
    final = DRM._ls_tracked_finalize(hi, lo, bound)
    final === nothing && return s11_generic_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
    S11_OBJECTIVE_LAST[] = (value=final[1], arithmetic_bound=final[2], stored_entries=nnz(P))
    return final[1]
end
end

function case_result(design, parts, label, astart)
    gbefore, obefore = S11_GRAD_CANDIDATE_CALLS[], S11_OBJECTIVE_CANDIDATE_CALLS[]
    gfbefore, ofbefore = S11_GRAD_FALLBACK_CALLS[], S11_OBJECTIVE_FALLBACK_CALLS[]
    a, ch, inner_ok = DRM._ls_inner_mode(Val(:gamma), design.y, parts.eta0, parts.psi0,
                                          design.gidx, design.G, parts.P; a0=astart)
    raw, marginal_a, raw_ok = DRM._ls_marginal_nll(Val(:gamma), design.y, parts.eta0, parts.psi0,
        design.gidx, design.G, parts.P; a0=astart)
    Zeta, Zpsi = DRM._ls_canonical_Zeta(length(design.y)), DRM._ls_canonical_Zpsi(length(design.y))
    grad = DRM._ls_joint_grad(Val(:gamma), design.y, parts.eta0, parts.psi0,
                               design.gidx, a, parts.P, Zeta, Zpsi)
    f = DRM._ls_joint(Val(:gamma), design.y, parts.eta0, parts.psi0,
                      design.gidx, a, parts.P, Zeta, Zpsi)
    big = independent_bigfixed(design, parts, a)
    bigbound = setprecision(BigFloat, 256) do
        big"1e-9" * (1 + norm(BigFloat.(a)))
    end
    return (label, start=copy(astart), mode=copy(a), hessian_pd=isposdef(ch), inner_ok,
            raw_marginal=raw, raw_ok, marginal_mode=copy(marginal_a), joint_f64=f,
            objective_arithmetic=(MODE in (:objective,:both) ? S11_OBJECTIVE_LAST[] : nothing),
            gradient=copy(grad), gradient_l2=norm(grad), gradient_inf=maximum(abs,grad),
            certificate_bound=1e-9*(1+norm(a)), independent_bigfixed_full_objective=big.J_full,
            independent_bigfixed_frozen_nll_objective=big.J_frozen_nll,
            f64_minus_frozen_nll_objective=BigFloat(f)-big.J_frozen_nll,
            frozen_nll_minus_full_objective=big.J_frozen_nll-big.J_full,
            independent_bigfixed_gradient=big.grad, independent_bigfixed_l2=norm(big.grad),
            independent_bigfixed_certificate_bound=bigbound,
            independent_bigfixed_certified=(norm(big.grad)<=bigbound),
            native_vs_bigfixed_inf=maximum(abs,BigFloat.(grad).-big.grad),
            gradient_candidate_calls=S11_GRAD_CANDIDATE_CALLS[]-gbefore,
            objective_candidate_calls=S11_OBJECTIVE_CANDIDATE_CALLS[]-obefore,
            gradient_fallback_calls=S11_GRAD_FALLBACK_CALLS[]-gfbefore,
            objective_fallback_calls=S11_OBJECTIVE_FALLBACK_CALLS[]-ofbefore,
            iterations=:unavailable_from_original_api, termination=:unavailable_from_original_api)
end

# Re-evaluate the immutable 17:43:37 zero-mode direction with its saved step;
# expected reference signs are Float64 positive and independent full-Big negative.
function saved_direction_results(design, parts)
    @assert sha256_file(DIRECTION) == DIRECTION_SHA
    saved = deserialize(DIRECTION)
    a, step = copy(saved.base.point), copy(saved.base.step)
    f0 = DRM._ls_joint(Val(:gamma), design.y, parts.eta0, parts.psi0, design.gidx,
                       a, parts.P, DRM._ls_canonical_Zeta(length(design.y)), DRM._ls_canonical_Zpsi(length(design.y)))
    arithmetic0 = MODE in (:objective,:both) ? deepcopy(S11_OBJECTIVE_LAST[]) : nothing
    big0 = independent_bigfixed(design, parts, a)
    rows = NamedTuple[]
    for alpha in (1.0, 0.5, 0.25)
        trial = a .- alpha .* step
        objective_before, fallback_before = S11_OBJECTIVE_CANDIDATE_CALLS[], S11_OBJECTIVE_FALLBACK_CALLS[]
        f = DRM._ls_joint(Val(:gamma), design.y, parts.eta0, parts.psi0, design.gidx,
                          trial, parts.P, DRM._ls_canonical_Zeta(length(design.y)), DRM._ls_canonical_Zpsi(length(design.y)))
        arithmetic = MODE in (:objective,:both) ? deepcopy(S11_OBJECTIVE_LAST[]) : nothing
        big = independent_bigfixed(design, parts, trial)
        float_change, full_change = f-f0, big.J_full-big0.J_full
        push!(rows, (alpha=alpha, f64_change=float_change, full_bigfixed_change=full_change,
                     frozen_nll_change=big.J_frozen_nll-big0.J_frozen_nll,
                     baseline_sign_inversion=(float_change > 0 && full_change < 0),
                     descent_recovered=(float_change < 0 && full_change < 0 &&
                                        big.J_frozen_nll-big0.J_frozen_nll < 0),
                     objective_arithmetic=arithmetic,
                     objective_candidate_calls=S11_OBJECTIVE_CANDIDATE_CALLS[]-objective_before,
                     objective_fallback_calls=S11_OBJECTIVE_FALLBACK_CALLS[]-fallback_before))
    end
    return (saved_base=a, saved_step=step, base_objective_arithmetic=arithmetic0,
            expected=(float_positive=true,full_bigfixed_negative=true), rows=rows)
end

function main()
    MODE in (:baseline,:gradient,:objective,:both) || error("S11_MODE must be baseline, gradient, objective, or both")
    STAMP == "UNSET" && error("S11_STAMP must be a fresh actual UTC stamp")
    before = hashes()
    @assert sha256_file(FROZEN) == FROZEN_SHA && sha256_file(INPUT) == INPUT_SHA
    frozen, input = deserialize(FROZEN), deserialize(INPUT)
    design, theta = exact_design(frozen), frozen.theta_engine
    @assert frozen.inputs_unchanged && theta == input.theta_engine
    parts, input_parts = production_parts(design,theta), production_parts(input.design,input.theta_engine)
    input_P_unchanged = parts.P == input_parts.P
    neighbor = only(p for p in frozen.probes if p.k == 6 && p.direction == 1)
    refstart = copy(only(s for s in input.starts if s[1] == :independent_reference_rounded)[2])
    starts = [(:zero,zeros(Float64,2design.G)), (:failed_base_iterate,copy(frozen.base.inner_mode)),
              (:certified_neighbor_k6_plus,copy(neighbor.inner_mode)), (:independent_reference_rounded,refstart)]
    cases = [case_result(design,parts,label,start) for (label,start) in starts]
    direction = saved_direction_results(design,parts)
    after = hashes()
    receipt = (kind=:compensated_objective_controlled_no_outer_fit, mode=MODE, stamp=STAMP,
               frozen_sha256=FROZEN_SHA,input_sha256=INPUT_SHA,helper_sha256=HELPER_SHA,
               direction_sha256=DIRECTION_SHA,
               before_hashes=before,after_hashes=after,source_unchanged=(before==after),
               input_P_unchanged=input_P_unchanged,theta=theta,design=design,starts=starts,cases=cases,direction=direction,
               counters=(gradient_candidate=S11_GRAD_CANDIDATE_CALLS[],gradient_fallback=S11_GRAD_FALLBACK_CALLS[],
                         objective_candidate=S11_OBJECTIVE_CANDIDATE_CALLS[],objective_fallback=S11_OBJECTIVE_FALLBACK_CALLS[]),
               selected_gradient_method=(MODE in (:gradient,:both) ? sprint(show,which(DRM._ls_joint_grad,
                    Tuple{Val{:gamma},Vector{Float64},Vector{Float64},Vector{Float64},Vector{Int},Vector{Float64},SparseMatrixCSC{Float64,Int},Matrix{Float64},Matrix{Float64}})) : "generic_only"),
               selected_objective_method=(MODE in (:objective,:both) ? sprint(show,which(DRM._ls_joint,
                    Tuple{Val{:gamma},Vector{Float64},Vector{Float64},Vector{Float64},Vector{Int},Vector{Float64},SparseMatrixCSC{Float64,Int},Matrix{Float64},Matrix{Float64}})) : "generic_only"),
               script_source=read(@__FILE__,String))
    output=joinpath(OUTDIR,"compensated-objective-$(MODE)-$(STAMP).jls")
    serialize(output,receipt)
    expected_gradient_override = MODE in (:gradient,:both) ? S11_GRAD_CANDIDATE_CALLS[] > 0 : S11_GRAD_CANDIDATE_CALLS[] == 0
    expected_objective_override = MODE in (:objective,:both) ? S11_OBJECTIVE_CANDIDATE_CALLS[] > 0 : S11_OBJECTIVE_CANDIDATE_CALLS[] == 0
    integrity = receipt.source_unchanged && receipt.input_P_unchanged &&
                expected_gradient_override && expected_objective_override &&
                S11_GRAD_FALLBACK_CALLS[] == 0 && S11_OBJECTIVE_FALLBACK_CALLS[] == 0
    println("S11_COMPENSATED_OBJECTIVE_RECEIPT ",output)
    integrity || error("retained receipt failed source/P/dispatch/fallback integrity gate")
end
main()
