# Formula constructs through the bridge with R-contrast fidelity (A6 of the
# drmTMB <-> DRM.jl parity programme; DRM.jl #467 + the #609 factors case;
# design 258 in drmTMB).
#
# drmTMB sends `options["coef_labels"]` -- base-R `model.matrix()` column
# names per dpar -- and `_bridge_echo_coef_labels` pastes them onto the
# fitted columns POSITIONALLY. Measured through drmTMB against DRM.jl
# 430ef64cc on 2026-09-05: `factor()`, `I(x^2)`, `poly(x, 2)`, `(x + z)^2`
# and `- term` already agree with `engine = "tmb"` name-for-name to <= 3e-11,
# but a design the two engines build DIFFERENTLY with the SAME column count
# -- a character column whose R (locale-collated) level order is not Julia's
# codepoint order (max|coef diff| 0.462), an ordered factor R codes with
# contr.poly (1.180), a contr.sum factor (1.757), or a factor whose level
# order was reversed on the Julia side only -- passed the echo and reported
# DRM.jl's coefficients under R's names with NO error.
#
# `_bridge_check_coef_labels_fidelity` closes that: every regression block
# DRM.jl can render itself must render to exactly the supplied base-R names,
# in order, else the fit is refused naming the dpar and BOTH spellings.
# Blocks DRM.jl cannot render (the `raw, raw` fallback), and blocks with no
# formula counterpart, are still echoed verbatim -- the count check in
# test_bridge_coef_labels_echo.jl is unchanged.
using DRM
using Test

const _FC_N = 60
const _FC_X = collect(range(-2.0, 2.0; length = _FC_N))
const _FC_Z = [sin(0.3 * i) + 0.05 * i for i in 1:_FC_N]
# Three levels whose Julia `sort(unique(...))` order is hi < lo < mid, so
# DRM.jl's baseline is "hi" and its dummy columns are lo, mid. An R user
# with `factor(grp, levels = c("lo", "mid", "hi"))` gets baseline "lo" and
# columns mid, hi -- same count, different design.
const _FC_GRP = [["hi", "lo", "mid"][mod1(i, 3)] for i in 1:_FC_N]
const _FC_Y = 0.6 .+ 0.35 .* _FC_X .- 0.08 .* _FC_X .^ 2 .+ 0.25 .* _FC_Z .+
    [grp == "lo" ? 0.2 : grp == "mid" ? -0.15 : 0.0 for grp in _FC_GRP] .+
    [0.05 * sin(7.0 * i) for i in 1:_FC_N]
const _FC_Y2 = 0.2 .- 0.15 .* _FC_X .+ [0.04 * cos(5.0 * i) for i in 1:_FC_N]
# A logical covariate: R names its one treatment column `flagTRUE`; Julia
# keeps the Bool vector continuous (same 0/1 column) and must render R's name.
const _FC_FLAG = [_FC_X[i] > 0 for i in 1:_FC_N]
const _FC_DATA = (; y = _FC_Y, y2 = _FC_Y2, x = _FC_X, z = _FC_Z, grp = _FC_GRP, flag = _FC_FLAG)

function _fc_try(formula; family = "gaussian", options = Dict{String,Any}())
    try
        return (:ok, drm_bridge(; formula, family, data = _FC_DATA, options))
    catch e
        return (:error, sprint(showerror, e))
    end
end

_fc_block(names, dpar) =
    [n[nextind(n, firstindex(n), length(dpar) + 1):end] for n in names if startswith(n, dpar * "_")]

_fc_options(labels::Dict{String,Vector{String}}) =
    Dict{String,Any}("coef_labels" => Dict{String,Any}(k => v for (k, v) in labels))

# (label, formula, expected base-R names per dpar -- `sigma` defaults to an
# intercept-only block for a Gaussian fit that names no sigma formula.)
const _FC_CONSTRUCTS = [
    (label = "factor()", formula = "y ~ x + factor(grp)",
     expected = Dict("mu" => ["(Intercept)", "x", "factor(grp)lo", "factor(grp)mid"],
                     "sigma" => ["(Intercept)"])),
    (label = "bare string column", formula = "y ~ x + grp",
     expected = Dict("mu" => ["(Intercept)", "x", "grplo", "grpmid"],
                     "sigma" => ["(Intercept)"])),
    (label = "factor interaction", formula = "y ~ x * grp",
     expected = Dict("mu" => ["(Intercept)", "x", "grplo", "grpmid", "x:grplo", "x:grpmid"],
                     "sigma" => ["(Intercept)"])),
    (label = "I(x^2)", formula = "y ~ x + I(x^2)",
     expected = Dict("mu" => ["(Intercept)", "x", "I(x^2)"], "sigma" => ["(Intercept)"])),
    (label = "poly(x, 2)", formula = "y ~ poly(x, 2)",
     expected = Dict("mu" => ["(Intercept)", "poly(x, 2)1", "poly(x, 2)2"],
                     "sigma" => ["(Intercept)"])),
    (label = "(x + z)^2", formula = "y ~ (x + z)^2",
     expected = Dict("mu" => ["(Intercept)", "x", "z", "x:z"], "sigma" => ["(Intercept)"])),
    (label = "- term", formula = "y ~ x + z - z",
     expected = Dict("mu" => ["(Intercept)", "x"], "sigma" => ["(Intercept)"])),
    (label = "sigma-side factor", formula = "y ~ x; sigma ~ grp",
     expected = Dict("mu" => ["(Intercept)", "x"], "sigma" => ["(Intercept)", "grplo", "grpmid"])),
    (label = "logical covariate", formula = "y ~ x + flag",
     expected = Dict("mu" => ["(Intercept)", "x", "flagTRUE"], "sigma" => ["(Intercept)"])),
    (label = "logical in an interaction", formula = "y ~ x * flag",
     expected = Dict("mu" => ["(Intercept)", "x", "flagTRUE", "x:flagTRUE"], "sigma" => ["(Intercept)"])),
    (label = "logical under factor()", formula = "y ~ x + factor(flag)",
     expected = Dict("mu" => ["(Intercept)", "x", "factor(flag)TRUE"], "sigma" => ["(Intercept)"])),
]

# One disagreement per row: the SAME column count as DRM.jl's design, a
# spelling R would produce for a design DRM.jl did not build. `mentions`
# must all appear in the refusal so the user sees both spellings.
const _FC_DISAGREEMENTS = [
    (label = "level order (R levels lo, mid, hi -> baseline lo)",
     formula = "y ~ x + grp", dpar = "mu",
     labels = Dict("mu" => ["(Intercept)", "x", "grpmid", "grphi"], "sigma" => ["(Intercept)"]),
     mentions = ["coef_labels[\"mu\"]", "grpmid", "grphi", "grplo", "engine = \"tmb\""]),
    (label = "level order under factor() (R levels mid, hi, lo)",
     formula = "y ~ x + factor(grp)", dpar = "mu",
     labels = Dict("mu" => ["(Intercept)", "x", "factor(grp)hi", "factor(grp)lo"], "sigma" => ["(Intercept)"]),
     mentions = ["coef_labels[\"mu\"]", "factor(grp)hi", "factor(grp)mid"]),
    (label = "ordered factor (contr.poly spelling .L/.Q)",
     formula = "y ~ x + grp", dpar = "mu",
     labels = Dict("mu" => ["(Intercept)", "x", "grp.L", "grp.Q"], "sigma" => ["(Intercept)"]),
     mentions = ["coef_labels[\"mu\"]", "grp.L", "grplo"]),
    (label = "contr.sum spelling (grp1/grp2)",
     formula = "y ~ x + grp", dpar = "mu",
     labels = Dict("mu" => ["(Intercept)", "x", "grp1", "grp2"], "sigma" => ["(Intercept)"]),
     mentions = ["coef_labels[\"mu\"]", "grp1", "grplo"]),
    (label = "interaction component order (grplo:x for x:grplo)",
     formula = "y ~ x * grp", dpar = "mu",
     labels = Dict("mu" => ["(Intercept)", "x", "grplo", "grpmid", "grplo:x", "grpmid:x"],
                   "sigma" => ["(Intercept)"]),
     mentions = ["coef_labels[\"mu\"]", "grplo:x", "x:grplo"]),
    (label = "term order (z before x for y ~ x + z)",
     formula = "y ~ x + z", dpar = "mu",
     labels = Dict("mu" => ["(Intercept)", "z", "x"], "sigma" => ["(Intercept)"]),
     mentions = ["coef_labels[\"mu\"]"]),
    (label = "sigma-side level order",
     formula = "y ~ x; sigma ~ grp", dpar = "sigma",
     labels = Dict("mu" => ["(Intercept)", "x"], "sigma" => ["(Intercept)", "grpmid", "grphi"]),
     mentions = ["coef_labels[\"sigma\"]", "grpmid", "grphi", "grplo"]),
]

@testset "bridge formula constructs with R-contrast fidelity (A6, #467/#609)" begin

    @testset "(a) own rendering: base-R spelling per construct" begin
        for c in _FC_CONSTRUCTS
            @testset "$(c.label): $(c.formula)" begin
                status, out = _fc_try(c.formula)
                @test status === :ok
                status === :ok || return
                for (dpar, expected) in c.expected
                    @test _fc_block(out["coef_names"], dpar) == expected
                end
            end
        end
    end

    @testset "(b) R's spelling supplied: accepted, echoed verbatim, numbers unchanged" begin
        for c in _FC_CONSTRUCTS
            @testset "$(c.label): $(c.formula)" begin
                _, baseline = _fc_try(c.formula)
                status, out = _fc_try(c.formula; options = _fc_options(c.expected))
                @test status === :ok
                status === :ok || (println("REFUSED: ", out); return)
                for (dpar, expected) in c.expected
                    @test _fc_block(out["coef_names"], dpar) == expected
                end
                @test out["vcov_names"] == out["coef_names"]
                @test out["coef_label_contract"] == "bridge_formula_labels_v1"
                @test out["raw_coef_names"] == baseline["raw_coef_names"]
                @test out["coefficients"] ≈ baseline["coefficients"]
                @test out["vcov"] ≈ baseline["vcov"]
            end
        end
    end

    @testset "(c) a design DRM.jl did not build is refused BY NAME, naming both spellings" begin
        for d in _FC_DISAGREEMENTS
            @testset "$(d.label)" begin
                # Same column count: the count check alone passes this.
                _, baseline = _fc_try(d.formula)
                @test length(_fc_block(baseline["coef_names"], d.dpar)) == length(d.labels[d.dpar])
                status, msg = _fc_try(d.formula; options = _fc_options(d.labels))
                @test status === :error
                status === :error || (println("NOT REFUSED: ", msg["coef_names"]); return)
                @test occursin("does not match the design DRM.jl built", msg)
                for m in d.mentions
                    @test occursin(m, msg)
                end
                # A design disagreement, not a count complaint.
                @test !occursin("supplies", msg)
            end
        end
    end

    @testset "(d) bivariate: mu1's factor rendered, accepted when R agrees, refused when not" begin
        formula = Dict("mu1" => "y ~ x + grp", "mu2" => "y2 ~ x",
                       "sigma1" => "sigma1 ~ 1", "sigma2" => "sigma2 ~ 1", "rho12" => "rho12 ~ 1")
        agree = Dict("mu1" => ["(Intercept)", "x", "grplo", "grpmid"], "mu2" => ["(Intercept)", "x"],
                     "sigma1" => ["(Intercept)"], "sigma2" => ["(Intercept)"], "rho12" => ["(Intercept)"])
        disagree = Dict("mu1" => ["(Intercept)", "x", "grpmid", "grphi"], "mu2" => ["(Intercept)", "x"],
                        "sigma1" => ["(Intercept)"], "sigma2" => ["(Intercept)"], "rho12" => ["(Intercept)"])
        status_ok, out = _fc_try(formula; family = "biv_gaussian", options = _fc_options(agree))
        @test status_ok === :ok
        status_ok === :ok && @test _fc_block(out["coef_names"], "mu1") == agree["mu1"]
        status_bad, msg = _fc_try(formula; family = "biv_gaussian", options = _fc_options(disagree))
        @test status_bad === :error
        status_bad === :error && @test occursin("coef_labels[\"mu1\"]", msg)
        status_bad === :error && @test occursin("grphi", msg) && occursin("grplo", msg)
    end

    @testset "(e) the count check still fires first, unchanged" begin
        status, msg = _fc_try("y ~ x + grp";
            options = _fc_options(Dict("mu" => ["(Intercept)", "x", "grplo"], "sigma" => ["(Intercept)"])))
        @test status === :error
        status === :error && @test occursin("supplies 3 names", msg)
        status === :error && @test !occursin("does not match the design", msg)
    end
end

println("BRIDGE_FORMULA_CONSTRUCTS_DONE")
