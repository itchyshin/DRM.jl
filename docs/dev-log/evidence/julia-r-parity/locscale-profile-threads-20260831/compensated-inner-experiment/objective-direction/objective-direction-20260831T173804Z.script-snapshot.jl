#!/usr/bin/env julia
# One fixed-point objective-direction diagnostic. No outer fit and no call to
# _ls_inner_mode: this evaluates only the retained compensated zero final mode,
# one undamped Hessian step, and alpha = 1, 1/2, 1/4 trial points.
using DRM
using Serialization, SHA, LinearAlgebra, SparseArrays

const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const EXPERIMENT = joinpath(ROOT, "compensated-inner-experiment")
const PREVIOUS = joinpath(EXPERIMENT, "compensated-inner-20260831T173220Z.jls")
const PREVIOUS_SHA = "9e0f655ab8dc714aa941b3b6fa08bb88c6294f0c89d73edbe6ccdd3d5f081ffc"
const CANDIDATE = joinpath(EXPERIMENT, "compensated_inner_experiment.jl")
const CANDIDATE_SHA = "c2a94657acde733dd580d892f2d11c69bc04710f28f4335563e3838070f5c796"
const STAMP = get(ENV, "S11_STAMP", "UNSET")
const OUTDIR = @__DIR__
const SOURCE_FILES = ["src/locscale_fit.jl", "src/locscale_grad.jl", "src/locscale_inner.jl",
                      "src/locscale_marginal.jl", "src/locscale_infer.jl",
                      "test/test_locscale_profile_status.jl"]
sha256_file(path) = bytes2hex(sha256(read(path)))
hashes() = Dict(path => sha256_file(path) for path in SOURCE_FILES)

# Import definitions (not the candidate's top-level helper-load or main call).
function definition_expression(ex)
    ex isa LineNumberNode && return true
    ex isa Expr || return false
    ex.head in (:using, :import, :const, :function, :macro) && return true
    return ex.head === :(=) && ex.args[1] isa Expr && ex.args[1].head === :call
end
function defined_name(ex)
    ex isa Expr || return nothing
    if ex.head === :const
        binding = ex.args[1]
        return binding isa Symbol ? binding :
               (binding isa Expr && binding.head === :(=) ? binding.args[1] : nothing)
    elseif ex.head === :function
        signature = ex.args[1]
        return signature isa Symbol ? signature :
               (signature isa Expr && signature.head === :call ? signature.args[1] : nothing)
    end
    return nothing
end
function load_candidate_definitions()
    @assert sha256_file(CANDIDATE) == CANDIDATE_SHA
    needed_constants = Set([:HELPER, :HELPER_SHA, :S11_FALLBACK_CALLS, :S11_CANDIDATE_CALLS])
    needed_functions = Set([:helper_definition, :load_helper, :s11_generic_grad,
                            :production_parts, :independent_bigfixedP_gradient,
                            :install_compensated_override!])
    for ex in Meta.parseall(read(CANDIDATE, String)).args
        ex isa Expr && ex.head === :call && ex.args[1] === :main && break
        name = defined_name(ex)
        (ex isa Expr && ((ex.head === :const && name in needed_constants) ||
                          (ex.head === :function && name in needed_functions))) || continue
        Core.eval(@__MODULE__, ex)
    end
    # The candidate script deliberately does this before main; reproduce only
    # the definition dependency here, never its baseline/override experiment.
    Base.invokelatest(load_helper)
    return nothing
end

function bigfixed_joint(design, parts, a64)
    setprecision(BigFloat, 256) do
        y = BigFloat.(design.y); eta0 = BigFloat.(parts.eta0); psi0 = BigFloat.(parts.psi0)
        a = BigFloat.(a64); P = BigFloat.(parts.P)
        total = zero(BigFloat)
        for i in eachindex(y)
            group = design.gidx[i]
            nll, _, _, _, _, _ = gamma_data(y[i], eta0[i] + a[2group-1], psi0[i] + a[2group])
            total += nll
        end
        return total + dot(a, P * a) / 2
    end
end
function row_result(design, parts, Zeta, Zpsi, alpha, a, step, f0, bigf0)
    trial = a .- alpha .* step
    grad64 = Base.invokelatest(DRM._ls_joint_grad, Val(:gamma), design.y, parts.eta0, parts.psi0,
                               design.gidx, trial, parts.P, Zeta, Zpsi)
    biggrad = independent_bigfixedP_gradient(design, parts, trial)
    f = DRM._ls_joint(Val(:gamma), design.y, parts.eta0, parts.psi0, design.gidx,
                      trial, parts.P, Zeta, Zpsi)
    bigf = bigfixed_joint(design, parts, trial)
    localbound = sqrt(eps(Float64)) * (1 + norm(a))
    displacement = norm(trial .- a)
    return (alpha=alpha, trial=copy(trial), f64=f, f64_change=f-f0,
            bigfixed_f=bigf, bigfixed_change=bigf-bigf0,
            float_big_same_sign=signbit(f-f0) == signbit(bigf-bigf0),
            displacement=displacement, rounding_local_bound=localbound,
            within_rounding_local_bound=(0 < displacement <= localbound),
            grad64=copy(grad64), grad64_l2=norm(grad64), grad64_inf=maximum(abs, grad64),
            bigfixed_grad=biggrad, bigfixed_grad_l2=norm(biggrad),
            bigfixed_grad_inf=maximum(abs, biggrad),
            native_vs_bigfixed_grad_inf=maximum(abs, BigFloat.(grad64) .- biggrad))
end

function main()
    STAMP == "UNSET" && error("set S11_STAMP to a fresh actual UTC stamp")
    before = hashes()
    @assert sha256_file(PREVIOUS) == PREVIOUS_SHA
    load_candidate_definitions()
    prior = deserialize(PREVIOUS)
    @assert prior.inputs_unchanged && prior.candidate_method_reached && prior.generic_fallback_calls == 0
    zero = only(x for x in prior.compensated if x.label == :zero)
    design, parts, a = prior.design, production_parts(prior.design, prior.theta), copy(zero.mode)
    Zeta, Zpsi = DRM._ls_canonical_Zeta(length(design.y)), DRM._ls_canonical_Zpsi(length(design.y))
    # Force latest world dispatch and record it before evaluating the direction.
    g = Base.invokelatest(DRM._ls_joint_grad, Val(:gamma), design.y, parts.eta0, parts.psi0,
                          design.gidx, a, parts.P, Zeta, Zpsi)
    H = DRM._ls_joint_hess(Val(:gamma), design.y, parts.eta0, parts.psi0, design.gidx,
                           design.G, a, parts.P, Zeta, Zpsi)
    ch = cholesky(Symmetric(H); check=false)
    @assert isposdef(ch)
    step = ch \ g
    f0 = DRM._ls_joint(Val(:gamma), design.y, parts.eta0, parts.psi0, design.gidx,
                       a, parts.P, Zeta, Zpsi)
    bigf0 = bigfixed_joint(design, parts, a)
    baserow = (alpha=0.0, point=copy(a), f64=f0, bigfixed_f=bigf0,
               grad64=copy(g), grad64_l2=norm(g), grad64_inf=maximum(abs, g),
               bigfixed_grad=independent_bigfixedP_gradient(design, parts, a),
               predicted_dot_g_step=dot(g, step), step=copy(step), step_l2=norm(step),
               hessian_pd=isposdef(ch), candidate_calls=S11_CANDIDATE_CALLS[],
               generic_fallback_calls=S11_FALLBACK_CALLS[])
    trials = [row_result(design, parts, Zeta, Zpsi, alpha, a, step, f0, bigf0)
              for alpha in (1.0, 0.5, 0.25)]
    after = hashes()
    receipt = (kind=:compensated_zero_objective_direction_no_fit, previous_sha256=PREVIOUS_SHA,
               candidate_sha256=CANDIDATE_SHA, before_hashes=before, after_hashes=after,
               source_unchanged=(before == after), theta=prior.theta, start_mode=copy(a),
               base=baserow, trials=trials, script_source=read(@__FILE__, String), stamp=STAMP)
    output = joinpath(OUTDIR, "objective-direction-$(STAMP).jls")
    serialize(output, receipt)
    println("S11_OBJECTIVE_DIRECTION_RECEIPT ", output)
end
if get(ENV, "S11_STATIC_ONLY", "0") == "1"
    load_candidate_definitions()
    @assert hasmethod(DRM._ls_joint_grad,
                      Tuple{Any,Any,Any,Any,Any,Any,Any,Any,Any})
    println("S11_STATIC_API_OK")
else
    main()
end
