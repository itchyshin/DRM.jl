# runparity.jl — gated R-parity runner (executed only under DRM_PARITY_TESTS=1,
# wired from test/runtests.jl). Globs test/parity/fixtures/*/expected.toml, fits
# each case with DRM.jl by ML, and applies compare.jl's contract against the
# committed drmTMB reference numbers.
#
# NO RCall at run time — fixtures are static, generated out-of-band (GENERATING.md).
# If no real fixtures are committed yet, that is NOT a failure: the suite passes
# trivially with an @info, because an empty real-fixture set is expected until a
# maintainer with local R + drmTMB generates them.

using DRM       # exports @formula, bf, drm, families, markers
using Test
using TOML

# Guard against double-inclusion: test_parity_harness.jl (always-on) already
# includes these in the same Pkg.test() process; re-including would redefine the
# ParityExpected struct. Only include if not already loaded.
isdefined(@__MODULE__, :ParityExpected) || include("compare.jl")
isdefined(@__MODULE__, :load_expected) || include("loadfixture.jl")

# Build the family object for a case from its `expected.toml` [fit] metadata.
# Returns `nothing` for an unsupported family/shape so the caller can @test_skip
# rather than error.
function _parity_family(family::AbstractString)
    fam = lowercase(strip(family))
    fam == "gaussian" && return Gaussian()
    fam == "biv_gaussian" && return Gaussian()
    fam == "gaussian_bivariate" && return Gaussian()
    fam == "student" && return Student()
    fam == "nbinom2" && return NegBinomial2()
    fam == "beta" && return Beta()
    return nothing
end

function _formula_from_expr(expr)
    (expr isa Expr && expr.head === :call && expr.args[1] === :~) || return nothing
    return eval(Expr(:macrocall, Symbol("@formula"), LineNumberNode(0), expr))
end

function _parse_formula_part(part::AbstractString)
    expr = Meta.parse(part)
    if expr isa Expr && expr.head === :(=)
        length(expr.args) == 2 || return nothing
        key = expr.args[1]
        key isa Symbol || return nothing
        form = _formula_from_expr(expr.args[2])
        form === nothing && return nothing
        return key => form
    end
    form = _formula_from_expr(expr)
    form === nothing && return nothing
    return nothing => form
end

const _BIVARIATE_PARITY_KEYS = Set((:mu1, :mu2, :sigma1, :sigma2, :rho12))

function _parity_formula(formula_text::AbstractString, family::AbstractString)
    parts = filter(!isempty, strip.(split(formula_text, ';')))
    isempty(parts) && return nothing

    parsed = map(_parse_formula_part, parts)
    any(isnothing, parsed) && return nothing

    keyed = Dict{Symbol,Any}()
    positional = Any[]
    for item in parsed
        key, form = item
        if key === nothing
            push!(positional, form)
        else
            keyed[key] = form
        end
    end

    if any(k -> k in _BIVARIATE_PARITY_KEYS, keys(keyed))
        (isempty(positional) && haskey(keyed, :mu1) && haskey(keyed, :mu2)) ||
            return nothing
        return bf(; mu1 = keyed[:mu1],
                    mu2 = keyed[:mu2],
                    sigma1 = get(keyed, :sigma1, nothing),
                    sigma2 = get(keyed, :sigma2, nothing),
                    rho12 = get(keyed, :rho12, nothing))
    end

    isempty(keyed) || return nothing
    return bf(positional...)
end

let fixtures_root = joinpath(@__DIR__, "fixtures")
    # Collect candidate case dirs: subdirs of fixtures/ that contain expected.toml,
    # skipping any whose name starts with `_` (machinery self-tests, not real
    # fixtures).
    cases = String[]
    if isdir(fixtures_root)
        for name in sort(readdir(fixtures_root))
            startswith(name, "_") && continue
            dir = joinpath(fixtures_root, name)
            isdir(dir) || continue
            isfile(joinpath(dir, "expected.toml")) || continue
            push!(cases, dir)
        end
    end

    if isempty(cases)
        @info "No drmTMB parity fixtures committed yet (test/parity/fixtures/) — " *
            "see README to generate them with local R + drmTMB."
        @test true   # empty real-fixture set is not a failure
    else
        for dir in cases
            casename = basename(dir)
            @testset "$casename" begin
                expected = load_expected(dir)
                fam = _parity_family(expected.family)
                if fam === nothing
                    @info "Skipping `$casename`: family `$(expected.family)` not yet " *
                        "supported by the parity runner"
                    @test_skip family_supported
                    continue
                end
                # `formula` text is read from the raw TOML for reconstruction;
                # ParityExpected does not retain it.
                fit_meta = TOML.parsefile(joinpath(dir, "expected.toml"))["fit"]
                formula_text = get(fit_meta, "formula", "")
                bundle = _parity_formula(formula_text, expected.family)
                if bundle === nothing
                    @info "Skipping `$casename`: formula `$(formula_text)` for " *
                        "`$(expected.family)` not yet supported by the parity runner"
                    @test_skip formula_supported
                    continue
                end
                data = load_data(dir)
                fit = drm(bundle, fam; data = data)
                result = compare_fit(fit, expected)
                if !result.passed
                    @error "Parity FAILED for case `$casename`" failures = result.failures
                end
                @test result.passed
            end
        end
    end
end
