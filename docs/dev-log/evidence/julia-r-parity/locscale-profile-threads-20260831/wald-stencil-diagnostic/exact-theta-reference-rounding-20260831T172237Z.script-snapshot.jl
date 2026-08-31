#!/usr/bin/env julia
# One no-refit diagnostic at the immutable, nonconverged returned theta.
# It contrasts start sensitivity and Float64 covariance arithmetic; it does not
# declare the mathematical marginal infeasible when a solver returns a sentinel.
using DRM
using Serialization, SHA, LinearAlgebra, SparseArrays

const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const OUTDIR = joinpath(ROOT, "wald-stencil-diagnostic")
const DIAGNOSTIC = joinpath(OUTDIR, "wald-stencil-20260831T171108Z.jls")
const DIAGNOSTIC_SHA = "25084fd208dbbe9f863331b19b70c2ed7f3407d2135095a8cc0e07dcda3647a3"
const HELPER = joinpath(ROOT, "whitened-oracle", "fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl")
const HELPER_SHA = "405f28114a2d665cf40bc8c4ec46ec324422a00a141250849e35bead4dace73d"
const STAMP = get(ENV, "S11_STAMP", "unstamped")
const RESULT = joinpath(OUTDIR, "exact-theta-reference-rounding-$(STAMP).jls")
const SOURCE_FILES = ["src/locscale_fit.jl", "src/locscale_grad.jl", "src/locscale_inner.jl",
                      "src/locscale_marginal.jl", "src/locscale_infer.jl",
                      "test/test_locscale_profile_status.jl"]
sha256_file(path) = bytes2hex(sha256(read(path)))
hashes() = Dict(path => sha256_file(path) for path in SOURCE_FILES)

# Load only definitions/imports/constants from immutable helper 405f2811, stopping
# before its first ordinary top-level statement so no earlier pilot is re-executed.
function helper_definition(ex)
    ex isa LineNumberNode && return true
    ex isa Expr || return false
    ex.head in (:using, :import, :const, :function, :macro) && return true
    return ex.head === :(=) && ex.args[1] isa Expr && ex.args[1].head === :call
end
function load_helper()
    @assert sha256_file(HELPER) == HELPER_SHA
    expressions = Meta.parseall(read(HELPER, String)).args
    for ex in expressions
        helper_definition(ex) || break
        ex isa LineNumberNode || Core.eval(@__MODULE__, ex)
    end
end

# Evaluate immutable oracle definitions before compiling the diagnostic routines
# that call them, avoiding dynamic-eval world-age dispatch.
load_helper()

function exact_design(r)
    dat = r.data
    Xmu = hcat(ones(Float64, length(dat.y)), Float64.(dat.x))
    Xpsi = ones(Float64, length(dat.y), 1)
    gidx = repeat(collect(1:dat.G), inner=dat.m)
    Q = sparse(1.0I, dat.G, dat.G)
    @assert dat.G == 4 && length(dat.y) == 32 && dat.species == gidx
    return (y=Float64.(dat.y), Xmu=Xmu, Xpsi=Xpsi, gidx=gidx, G=dat.G, Q=Q)
end

function direct_precision(lambda)
    u, c, v = lambda
    e1, e2, e12 = exp(-2u), exp(-2v), exp(-2(u+v))
    cross = exp(-u - 2v)
    return [e1 + c*c*e12  -c*cross; -c*cross  e2]
end
function true_precision_256(lambda64, G)
    setprecision(BigFloat, 256) do
        lambda = BigFloat.(lambda64) # exact binary lifts of frozen Float64 theta
        return kron(Matrix{BigFloat}(I, G, G), direct_precision(lambda))
    end
end

function production_components(design, theta)
    pμ = size(design.Xmu, 2); pψ = size(design.Xpsi, 2)
    lambda = theta[pμ+pψ+1:pμ+pψ+3]
    Lambda = DRM._ls_lc_to_Λ(lambda)
    P = DRM.prior_precision(design.Q, DRM._ls_inv2x2(Lambda))
    Pdirect = kron(Matrix(design.Q), direct_precision(lambda))
    eta0, psi0 = design.Xmu * theta[1:pμ], design.Xpsi * theta[pμ+1:pμ+pψ]
    return (; pμ, pψ, lambda, Lambda, P, Pdirect, eta0, psi0)
end

function float_data_gradient(design, eta0, psi0, a64)
    data = zeros(Float64, length(a64))
    for i in eachindex(design.y)
        group = design.gidx[i]
        ge, gp = DRM._ls_grad(Val(:gamma), design.y[i], eta0[i] + a64[2group-1], psi0[i] + a64[2group])
        data[2group-1] += ge; data[2group] += gp
    end
    return data
end
function individually_lifted_float_data_gradient(design, eta0, psi0, a64)
    setprecision(BigFloat, 256) do
        data = zeros(BigFloat, length(a64))
        for i in eachindex(design.y)
            group = design.gidx[i]
            # Each production Float64 contribution is lifted before the BigFloat
            # accumulation; this is distinct from lifting the aggregated vector.
            ge, gp = DRM._ls_grad(Val(:gamma), design.y[i], eta0[i] + a64[2group-1], psi0[i] + a64[2group])
            data[2group-1] += BigFloat(ge); data[2group] += BigFloat(gp)
        end
        return data
    end
end

function independent_big_gradient(design, eta0, psi0, a64, Pbig)
    setprecision(BigFloat, 256) do
        y, a, P = BigFloat.(design.y), BigFloat.(a64), BigFloat.(Pbig)
        eta, psi = BigFloat.(eta0), BigFloat.(psi0)
        g = P * a # deliberately lifts the exact Float64 P and a before P*a
        for i in eachindex(y)
            group = design.gidx[i]
            _, ge, gp, _, _, _ = gamma_data(y[i], eta[i] + a[2group-1], psi[i] + a[2group])
            g[2group-1] += ge; g[2group] += gp
        end
        return g
    end
end

function independent_start_results(design, theta, starts, bits)
    setprecision(BigFloat, bits) do
        y, Xmu, Xpsi = BigFloat.(design.y), BigFloat.(design.Xmu), BigFloat.(design.Xpsi)
        theta_big = BigFloat.(theta)
        eta0, psi0 = Xmu * theta_big[1:2], Xpsi * theta_big[3:3]
        B, L = block_B(theta_big[4:6], design.G)
        tol = bits == 128 ? big"1e-25" : big"1e-50"
        out = NamedTuple[]
        for (label, astart) in starts
            zstart = B \ BigFloat.(astart)
            solved = solve_mode(zstart, y, eta0, psi0, design.gidx, B, tol)
            ch = cholesky(Symmetric(solved.state.H); check=false)
            push!(out, (label=label, z=solved.z, a=solved.state.a, M=laplace_M(solved.state.J, ch),
                        J=solved.state.J, residual=solved.residual, pd=isposdef(ch),
                        iterations=solved.iterations, start_z=zstart, L=L))
        end
        return out
    end
end

function production_start_result(design, parts, theta, label, astart)
    a, ch, inner_ok = DRM._ls_inner_mode(Val(:gamma), design.y, parts.eta0, parts.psi0,
                                          design.gidx, design.G, parts.P; a0=astart)
    raw, marginal_a, marginal_ok = DRM._ls_marginal_nll(Val(:gamma), design.y,
        parts.eta0, parts.psi0, design.gidx, design.G, parts.P; a0=astart)
    g64 = DRM._ls_joint_grad(Val(:gamma), design.y, parts.eta0, parts.psi0,
                              design.gidx, a, parts.P)
    data64 = float_data_gradient(design, parts.eta0, parts.psi0, a)
    P64a64 = parts.P * a
    lifted_same_float = BigFloat.(parts.P) * BigFloat.(a) +
                         individually_lifted_float_data_gradient(design, parts.eta0, parts.psi0, a)
    independent_fixedP64 = independent_big_gradient(design, parts.eta0, parts.psi0, a, parts.P)
    independent_trueP = independent_big_gradient(design, parts.eta0, parts.psi0, a,
                                                  true_precision_256(parts.lambda, design.G))
    return (label=label, start=copy(astart), a=copy(a), inner_ok=inner_ok,
            inner_pd=isposdef(ch), residual64_inf=maximum(abs, g64), residual64_l2=norm(g64),
            certificate_bound=1e-9 * (1 + norm(a)),
            raw_marginal=raw, raw_marginal_ok=marginal_ok,
            marginal_a=copy(marginal_a), g64=copy(g64),
            data64=copy(data64), P64a64=copy(P64a64),
            residual256_lifted_same_float=maximum(abs, lifted_same_float),
            native_vs_lifted_same_float=maximum(abs, BigFloat.(g64) .- lifted_same_float),
            residual256_independent_fixedP64=maximum(abs, independent_fixedP64),
            native_vs_independent_fixedP64=maximum(abs, BigFloat.(g64) .- independent_fixedP64),
            residual256_independent_trueP=maximum(abs, independent_trueP),
            fixedP64_vs_trueP=maximum(abs, independent_fixedP64 .- independent_trueP))
end

function main()
    before = hashes()
    @assert sha256_file(DIAGNOSTIC) == DIAGNOSTIC_SHA
    retained = deserialize(DIAGNOSTIC)
    design, theta = exact_design(retained), retained.theta_engine
    parts = production_components(design, theta)
    @assert retained.inputs_unchanged && all(isfinite, retained.base.inner_mode)
    neighbor = only(p for p in retained.probes if p.k == 6 && p.direction == 1)
    @assert neighbor.inner_ok && neighbor.nll_ok
    starts = [(:zero, zeros(Float64, 2design.G)),
              (:failed_base_iterate, copy(retained.base.inner_mode)),
              (:certified_neighbor_k6_plus, copy(neighbor.inner_mode))]
    independent128 = independent_start_results(design, theta, starts, 128)
    independent256 = independent_start_results(design, theta, starts, 256)
    for solutions in (independent128, independent256)
        all(x -> x.pd, solutions) || error("independent final Hz was not PD")
        reference = first(solutions).a
        for solution in solutions
            @assert maximum(abs, solution.a .- reference) <= big"1e-20" "independent-start mode agreement failed"
        end
    end
    rounded_reference = Float64.(only(x for x in independent256 if x.label == :zero).a)
    push!(starts, (:independent_reference_rounded, rounded_reference))
    production = [production_start_result(design, parts, theta, label, a) for (label, a) in starts]
    cold_raw, cold_a, cold_ok = DRM._ls_marginal_nll(Val(:gamma), design.y,
        parts.eta0, parts.psi0, design.gidx, design.G, parts.P; a0=nothing)
    cold_packed = DRM._ls_fit_nll(Val(:gamma), design.y, design.Xmu, design.Xpsi,
                                  design.gidx, design.G, design.Q, theta)
    @assert cold_ok ? cold_packed == cold_raw : cold_packed == 1e18
    crossprecision = [(label=x.label, abs_M128_256=abs(x.M - only(y.M for y in independent256 if y.label == x.label)),
                       mode_maxabs128_256=maximum(abs, x.a .- only(y.a for y in independent256 if y.label == x.label)))
                      for x in independent128]
    for x in crossprecision
        @assert x.abs_M128_256 <= big"1e-20" && x.mode_maxabs128_256 <= big"1e-20" "cross-precision gate failed"
    end
    after = hashes()
    receipt = (kind=:exact_theta_reference_rounding_no_refit, theta_engine=theta, design=design,
               helper_sha256=HELPER_SHA, retained_diagnostic_sha256=sha256_file(DIAGNOSTIC),
               starts=starts, independent128=independent128, independent256=independent256,
               crossprecision=crossprecision, production=production,
               cold_packing_check=(raw_marginal=cold_raw, raw_ok=cold_ok, raw_mode=cold_a,
                                   packed_fit_nll=cold_packed,
                                   maps_failure_to_1e18=(!cold_ok && cold_packed == 1e18)),
               P_condition=cond(Matrix(parts.P)), Pdirect_condition=cond(Matrix(parts.Pdirect)),
               P_direct_absdiff=maximum(abs, parts.P - parts.Pdirect),
               P_direct_reldiff=maximum(abs, parts.P - parts.Pdirect) / maximum(abs, parts.Pdirect),
               before_hashes=before, after_hashes=after, inputs_unchanged=(before == after))
    serialize(RESULT, receipt)
    println("S11_EXACT_THETA_REFERENCE_OK result=", RESULT, " sha256=", sha256_file(RESULT),
            " inputs_unchanged=", receipt.inputs_unchanged,
            " prod_ok=", [(x.label, x.inner_ok, x.raw_marginal_ok) for x in production],
            " Pcond=", receipt.P_condition, " Pdirect_absdiff=", receipt.P_direct_absdiff)
end
main()
