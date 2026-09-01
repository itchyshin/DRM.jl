using Serialization
using SHA

# Import only the immutable helper definitions from the exact passing script;
# do not re-execute its two-point pilot.  The passed controls remain in its
# frozen log and receipt, while this script records 104 new evaluations exactly.
seed_path, output_path = ARGS
const PASSING_SCRIPT = "/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-oracle/fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl"
source_expressions = Meta.parseall(read(PASSING_SCRIPT, String)).args
for expression in source_expressions[2:50]
    expression isa LineNumberNode || Core.eval(@__MODULE__, expression)
end
payload = deserialize(SOURCE_ARTIFACT)
state = payload.state
seed = deserialize(seed_path)
@assert bytes2hex(sha256(read(SOURCE_ARTIFACT))) == SOURCE_SHA
@assert state.kind == Val(:gamma) && state.G == 4 && Matrix(state.Q) == Matrix{Float64}(I, 4, 4)
@assert state.gidx == repeat(collect(1:4), inner=8)

function big_l21_pair(theta_float64, h, bits, label)
    setprecision(BigFloat, bits) do
        base = BigFloat.(theta_float64)
        plus, minus = copy(base), copy(base)
        plus[5] += h
        minus[5] -= h
        rp = evaluate_case(Symbol(label, :_big_plus), plus, state, bits; transformed_a=seed.a)
        rm = evaluate_case(Symbol(label, :_big_minus), minus, state, bits; transformed_a=seed.a)
        return (h=h, plus_coordinate=plus[5], minus_coordinate=minus[5],
                numerator=rp.M-rm.M, derivative=(rp.M-rm.M)/(2*h), plus=rp, minus=rm)
    end
end

function float64_l21_pair(theta_float64, h, bits, label)
    delta = Float64(h)
    plus, minus = copy(theta_float64), copy(theta_float64)
    plus[5] += delta
    minus[5] -= delta
    rp = evaluate_case(Symbol(label, :_float64_plus), plus, state, bits; transformed_a=seed.a)
    rm = evaluate_case(Symbol(label, :_float64_minus), minus, state, bits; transformed_a=seed.a)
    return (requested_h=h, float64_delta=delta, plus_coordinate=plus[5], minus_coordinate=minus[5],
            numerator=rp.M-rm.M, plus=rp, minus=rm)
end

const HSTEPS = (big"1e-4", big"5e-5", big"2.5e-5")
const BITS = (128, 256)
const NUMERATOR_GATE = big"1e-20"
const RICHARDSON_GATE = big"1e-10"

terminals = NamedTuple[]
manifest = (kind=:fixed_outer_all_terminal_L21_directional, source_artifact_sha256=SOURCE_SHA,
            passing_script_sha256=bytes2hex(sha256(read(PASSING_SCRIPT))),
            seed_sha256=bytes2hex(sha256(read(seed_path))),
            symmetric_bigfloat_steps=HSTEPS, bits=BITS,
            numerator_crossprecision_gate=NUMERATOR_GATE,
            richardson_stability_gate=RICHARDSON_GATE, terminals=terminals)
serialize(output_path, manifest)
println("S11_WHITE_EXPANSION_START=", repr((output=output_path, planned_objective_evaluations=104,
    planned_mode_solves=208, hsteps=HSTEPS, bits=BITS)))

for k in eachindex(state.candidates)
    candidate, outer = state.candidates[k], payload.optim_results[k]
    theta = copy(state.theta_engine)
    theta[1] = candidate.value
    theta[2:6] .= Optim.minimizer(outer)
    baselines = NamedTuple[]
    big_pairs = NamedTuple[]
    float64_pairs = NamedTuple[]
    for bits in BITS
        push!(baselines, (bits=bits, result=evaluate_case(Symbol(candidate.label, :_baseline), theta, state, bits; transformed_a=seed.a)))
        local_big = [big_l21_pair(theta, h, bits, candidate.label) for h in HSTEPS]
        local_float64 = [float64_l21_pair(theta, h, bits, candidate.label) for h in HSTEPS]
        push!(big_pairs, (bits=bits, pairs=local_big))
        push!(float64_pairs, (bits=bits, pairs=local_float64))
    end
    cross_numerator = NamedTuple[]
    for j in eachindex(HSTEPS)
        difference = abs(big_pairs[1].pairs[j].numerator - big_pairs[2].pairs[j].numerator)
        @assert difference <= NUMERATOR_GATE "symmetric BigFloat numerator cross-precision gate failed"
        push!(cross_numerator, (h=HSTEPS[j], abs_difference=difference, gate=NUMERATOR_GATE))
    end
    r128 = [pair.derivative for pair in big_pairs[1].pairs]
    r256 = [pair.derivative for pair in big_pairs[2].pairs]
    rich128_h = (4*r128[2] - r128[1]) / 3
    rich128_h2 = (4*r128[3] - r128[2]) / 3
    rich256_h = (4*r256[2] - r256[1]) / 3
    rich256_h2 = (4*r256[3] - r256[2]) / 3
    stability128, stability256 = abs(rich128_h-rich128_h2), abs(rich256_h-rich256_h2)
    @assert stability128 <= RICHARDSON_GATE && stability256 <= RICHARDSON_GATE "Richardson L21 derivative stability failed"
    terminal = (candidate=candidate, theta_engine=theta, baselines=baselines,
                symmetric_bigfloat=big_pairs, actual_float64=float64_pairs,
                crossprecision_numerators=cross_numerator,
                richardson=(bits128=(R_h=rich128_h, R_h2=rich128_h2, difference=stability128),
                            bits256=(R_h=rich256_h, R_h2=rich256_h2, difference=stability256),
                            gate=RICHARDSON_GATE))
    push!(terminals, terminal)
    manifest = merge(manifest, (terminals=terminals,))
    serialize(output_path, manifest)
    println("S11_WHITE_EXPANSION_TERMINAL=", repr((candidate=candidate, crossprecision_numerators=cross_numerator,
        richardson=terminal.richardson, completed_terminals=length(terminals))))
end
println("S11_WHITE_EXPANSION_COMPLETE=", repr((terminals=length(terminals),
    serialized_output=output_path, output_sha256=bytes2hex(sha256(read(output_path))))))
