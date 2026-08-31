#!/usr/bin/env julia
# No-fit exporter: derive the regression fixture only from retained serialized
# artifacts.  It intentionally does not load or call DRM fitting code.
using Serialization
using SparseArrays
using Optim
using SHA
using TOML

const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const SOURCE = joinpath(ROOT, "profile-nuisance-corrected-replay-20260831T160339Z.jls")
const EXPANSION = joinpath(ROOT, "whitened-oracle", "directional-l21-expansion-20260831T164725Z.jls")
const EXPANSION_SCRIPT = joinpath(ROOT, "whitened-oracle", "directional-l21-expansion-20260831T164725Z.script-snapshot.jl")
const OUTPUT = joinpath(ROOT, "whitened-oracle", "locscale_gamma_l21.toml")
const RECEIPT = joinpath(ROOT, "whitened-oracle", "locscale_gamma_l21.export-receipt.jls")

sha256_file(path) = bytes2hex(sha256(read(path)))
toml_float(x::Float64) = repr(x)
toml_vec(xs) = "[" * join(toml_float.(Float64.(xs)), ", ") * "]"

function main()
    source_sha = sha256_file(SOURCE)
    expansion_sha = sha256_file(EXPANSION)
    expansion_script_sha = sha256_file(EXPANSION_SCRIPT)
    source = deserialize(SOURCE)
    expansion = deserialize(EXPANSION)
    state = source.state

    # Provenance and fixture-coordinate checks: the result must describe these
    # exact saved candidates/data, not merely a similarly shaped fixture.
    @assert expansion.source_artifact_sha256 == source_sha
    @assert length(state.y) == 32
    @assert length(state.gidx) == 32
    @assert size(state.Xmu) == (32, 2)
    @assert size(state.Xpsi) == (32, 1)
    @assert state.G == 4
    @assert all(==(state.Xpsi[1, 1]), state.Xpsi)
    @assert state.Xpsi[1, 1] == 1.0
    @assert all(>(0.0), state.y)
    @assert length(expansion.terminals) == 4
    @assert length(unique(t.candidate.label for t in expansion.terminals)) == 4
    @assert Set(t.candidate.label for t in expansion.terminals) ==
            Set(c.label for c in state.candidates)

    source_candidates = Dict(c.label => c for c in state.candidates)
    object_crossprecision = NamedTuple[]
    for terminal in expansion.terminals
        candidate = terminal.candidate
        @assert candidate == source_candidates[candidate.label]
        @assert terminal.fixed_index == candidate.job_k
        @assert terminal.free_indices == filter(!=(candidate.job_k), eachindex(terminal.theta_engine))
        @assert length(terminal.theta_engine) == 6
        @assert terminal.theta_engine[candidate.job_k] == candidate.value

        # The original runner gated the symmetric numerator.  Re-check each
        # paired M value here so the retained fixture also records the stronger
        # per-objective cross-precision condition requested by Rose.
        symmetric = Dict(pair.bits => pair for pair in terminal.symmetric_bigfloat)
        @assert Set(keys(symmetric)) == Set((128, 256))
        for pair128 in symmetric[128].pairs
            pair256 = only(filter(p -> p.h == pair128.h, symmetric[256].pairs))
            plus_error = abs(pair128.plus.M - pair256.plus.M)
            minus_error = abs(pair128.minus.M - pair256.minus.M)
            @assert plus_error <= big"1e-20"
            @assert minus_error <= big"1e-20"
            push!(object_crossprecision,
                  (label=String(candidate.label), h=string(pair128.h),
                   plus_M_abs128_256=string(plus_error),
                   minus_M_abs128_256=string(minus_error)))
        end
    end

    open(OUTPUT, "w") do io
        println(io, "# Exact no-fit export from immutable saved artifacts.")
        println(io, "y = ", toml_vec(state.y))
        println(io, "x = ", toml_vec(state.Xmu[:, 2]))
        println(io, "gidx = [", join(state.gidx, ", "), "]")
        println(io, "G = ", state.G)
        println(io, "fixed_xpsi_intercept = ", toml_float(state.Xpsi[1, 1]))
        for terminal in expansion.terminals
            r256 = terminal.richardson.bits256.R_h
            println(io, "\n[[cases]]")
            println(io, "label = ", repr(String(terminal.candidate.label)))
            println(io, "theta = ", toml_vec(terminal.theta_engine))
            println(io, "expected_l21 = ", toml_float(Float64(r256)))
            println(io, "expected_l21_big = ", repr(string(r256)))
        end
        println(io, "\n[provenance]")
        println(io, "source_artifact_sha256 = ", repr(source_sha))
        println(io, "pilot_script_sha256 = ", repr(expansion.passing_script_sha256))
        println(io, "expansion_script_sha256 = ", repr(expansion_script_sha))
        println(io, "expansion_output_sha256 = ", repr(expansion_sha))
        println(io, "exporter_script_sha256 = ", repr(sha256_file(@__FILE__)))
    end

    parsed = TOML.parsefile(OUTPUT)
    @assert parsed["y"] == state.y
    @assert parsed["x"] == state.Xmu[:, 2]
    @assert parsed["gidx"] == state.gidx
    @assert parsed["G"] == state.G
    @assert parsed["fixed_xpsi_intercept"] == state.Xpsi[1, 1]
    @assert length(parsed["cases"]) == 4
    @assert parsed["provenance"]["expansion_output_sha256"] == expansion_sha

    receipt = (kind=:locscale_gamma_l21_no_fit_export,
               source_artifact_sha256=source_sha,
               expansion_output_sha256=expansion_sha,
               expansion_script_sha256=expansion_script_sha,
               output=OUTPUT,
               output_sha256=sha256_file(OUTPUT),
               object_crossprecision_gate="1e-20",
               object_crossprecision=object_crossprecision)
    serialize(RECEIPT, receipt)
    println("S11_L21_EXPORT_OK output=", OUTPUT,
            " output_sha256=", receipt.output_sha256,
            " receipt=", RECEIPT,
            " receipt_sha256=", sha256_file(RECEIPT),
            " objects_checked=", length(object_crossprecision))
end

main()
