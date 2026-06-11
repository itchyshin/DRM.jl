# test_reml_parity.jl — DRM.jl method=:REML reproduces lme4::lmer(REML=TRUE) and
# metafor::rma(method="REML") to ~1e-3 on stored reference fits. Fixtures generated
# by test/parity/gen_reml_refs.R (lme4 1.1.37, metafor 4.8.0) — GENERATED OUTPUTS
# only, no GPL source vendored. This is the cross-package correctness oracle for the
# REML-for-all-Gaussian work: random intercepts/slopes/crossed (lme4) and the
# known-sampling-variance meta-analysis path (metafor, via meta_V).
using DRM
using Test, DelimitedFiles
import TOML

const PFIX = joinpath(@__DIR__, "parity", "fixtures")
_load(name) = let dir = joinpath(PFIX, name)
    raw = readdlm(joinpath(dir, "data.csv"), ',', header = true)[1]
    (raw, TOML.parsefile(joinpath(dir, "expected.toml")))
end
_col(raw, j) = Float64.(raw[:, j])

@testset "REML parity: lme4 / metafor (method=:REML)" begin
    @testset "lme4 random intercept (1|g)" begin
        raw, ref = _load("reml-lme4-ri")
        y = _col(raw, 1); x = _col(raw, 2); g = string.(raw[:, 3])
        f = drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                data = (; y, x, g), method = :REML)
        @test reml_loglik(f) ≈ ref["fit"]["logLik"] rtol = 1e-3
        @test sqrt(vc(f)[:g][1, 1]) ≈ ref["reml"]["sd_g"] rtol = 1e-3
        @test exp(coef(f, :sigma)[1]) ≈ ref["reml"]["sigma"] rtol = 1e-3
    end
    @testset "lme4 correlated slope (1+x|g)" begin
        raw, ref = _load("reml-lme4-corr")
        y = _col(raw, 1); x = _col(raw, 2); g = string.(raw[:, 3])
        f = drm(bf(@formula(y ~ 1 + x + (1 + x | g)), @formula(sigma ~ 1)), Gaussian();
                data = (; y, x, g), method = :REML)
        @test reml_loglik(f) ≈ ref["fit"]["logLik"] rtol = 1e-3
        V = vc(f)[:g]
        @test sqrt(V[1, 1]) ≈ ref["reml"]["sd_intercept"] rtol = 2e-3
        @test sqrt(V[2, 2]) ≈ ref["reml"]["sd_slope"] rtol = 2e-3
        @test exp(coef(f, :sigma)[1]) ≈ ref["reml"]["sigma"] rtol = 1e-3
    end
    @testset "lme4 crossed (1|g)+(1|h)" begin
        raw, ref = _load("reml-lme4-cross")
        y = _col(raw, 1); x = _col(raw, 2); g = string.(raw[:, 3]); h = string.(raw[:, 4])
        f = drm(bf(@formula(y ~ 1 + x + (1 | g) + (1 | h)), @formula(sigma ~ 1)), Gaussian();
                data = (; y, x, g, h), method = :REML)
        @test reml_loglik(f) ≈ ref["fit"]["logLik"] rtol = 1e-3
        @test sqrt(vc(f)[:g][1, 1]) ≈ ref["reml"]["sd_g"] rtol = 2e-3
        @test sqrt(vc(f)[:h][1, 1]) ≈ ref["reml"]["sd_h"] rtol = 2e-3
    end
    # metafor: the REML ESTIMATES (pooled mean, τ², regression slope) match exactly.
    # The absolute REML logLik differs by a model-dependent additive constant —
    # metafor and lme4 use different REML normalisation constants; DRM.jl follows
    # lme4's (the lme4 logLik checks above pass). The constant is parameter-free, so
    # it changes neither the estimates nor model selection within a fixed mean
    # structure. We therefore assert estimate parity, not absolute-logLik parity.
    @testset "metafor random-effects meta (meta_V)" begin
        raw, ref = _load("reml-metafor-re")
        y = _col(raw, 1); v = _col(raw, 2)
        f = drm(bf(@formula(y ~ 1 + meta_V(v)), @formula(sigma ~ 1)), Gaussian();
                data = (; y, v), method = :REML)
        @test coef(f, :mu)[1] ≈ ref["reml"]["mu"] rtol = 1e-3       # pooled mean
        @test exp(2 * coef(f, :sigma)[1]) ≈ ref["reml"]["tau2"] rtol = 2e-3  # τ²
    end
    @testset "metafor meta-regression (meta_V + mods)" begin
        raw, ref = _load("reml-metafor-reg")
        y = _col(raw, 1); v = _col(raw, 2); x = _col(raw, 3)
        f = drm(bf(@formula(y ~ 1 + x + meta_V(v)), @formula(sigma ~ 1)), Gaussian();
                data = (; y, x, v), method = :REML)
        @test coef(f, :mu)[1] ≈ ref["reml"]["intercept"] rtol = 1e-3
        @test coef(f, :mu)[2] ≈ ref["reml"]["slope_x"] rtol = 1e-3
        @test exp(2 * coef(f, :sigma)[1]) ≈ ref["reml"]["tau2"] rtol = 2e-3
    end
end
