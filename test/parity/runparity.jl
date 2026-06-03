# runparity.jl — gated R-parity runner (executed only under DRM_PARITY_TESTS=1,
# wired from test/runtests.jl). Globs test/parity/fixtures/*/expected.toml, fits
# each case with DRM.jl by ML, and applies compare.jl's contract against the
# committed drmTMB reference numbers.
#
# NO RCall at run time — fixtures are static, generated out-of-band (GENERATING.md).
# If no real fixtures are committed yet, that is NOT a failure: the suite passes
# trivially with an @info, because an empty real-fixture set is expected until a
# maintainer with local R + drmTMB generates them.

using DRM       # exports @formula, bf, drm, Gaussian
using Test
using TOML

# Guard against double-inclusion: test_parity_harness.jl (always-on) already
# includes these in the same Pkg.test() process; re-including would redefine the
# ParityExpected struct. Only include if not already loaded.
isdefined(@__MODULE__, :ParityExpected) || include("compare.jl")
isdefined(@__MODULE__, :load_expected) || include("loadfixture.jl")

# Build the (response formula, sigma formula) and family object for a case from
# its `expected.toml` [fit] metadata. Returns `nothing` for an unsupported
# family/shape so the caller can @test_skip rather than error.
#
# Supported now: family = "gaussian" univariate location–scale, where the design
# is reconstructed from the data columns. We do NOT parse arbitrary R formula
# text here (that lives in the bf() front end); instead the runner uses a simple
# convention — see _parity_formula below — that covers the committed gaussian
# location–scale fixtures. Anything else returns nothing.
function _parity_family(family::AbstractString)
    fam = lowercase(strip(family))
    fam == "gaussian" && return Gaussian()
    return nothing
end

# Parse the `formula` text from [fit] (e.g. "y ~ x; sigma ~ x") into the
# response/sigma RHS. We support the two-formula location–scale convention used
# by the committed gaussian fixtures. Returns (bf_bundle) or nothing if it can't
# be parsed into the supported shape.
function _parity_formula(formula_text::AbstractString, family::AbstractString)
    fam = lowercase(strip(family))
    fam == "gaussian" || return nothing
    parts = strip.(split(formula_text, ';'))
    length(parts) == 2 || return nothing
    # Each part is "<lhs> ~ <rhs>". We reconstruct via Meta.parse + @formula-like
    # building. To keep dependencies minimal and avoid eval pitfalls, only the
    # canonical "y ~ <rhs>; sigma ~ <rhs>" forms are accepted; the RHS strings are
    # parsed by Julia's parser and fed through StatsModels' formula machinery.
    mu_expr = Meta.parse(parts[1])
    sg_expr = Meta.parse(parts[2])
    (mu_expr isa Expr && mu_expr.head === :call && mu_expr.args[1] === :~) || return nothing
    (sg_expr isa Expr && sg_expr.head === :call && sg_expr.args[1] === :~) || return nothing
    mu_form = eval(Expr(:macrocall, Symbol("@formula"), LineNumberNode(0), mu_expr))
    sg_form = eval(Expr(:macrocall, Symbol("@formula"), LineNumberNode(0), sg_expr))
    return bf(mu_form, sg_form)
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
