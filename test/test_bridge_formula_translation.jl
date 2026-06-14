# R→Julia formula translation across the drm_bridge string boundary (Ayumi LS#2).
#
# The R side sends model formulas as strings; R writes interactions with `:`,
# which Julia parses as the (lower-precedence) range operator, mis-associating
# the `+` chain and pulling a trailing phylo()/(1|g) term inside a Colon term the
# engine cannot read. The bridge rewrites `:` → `&` (string level) and rejects
# the crash/silent constructs (I/poly/scale/factor/^) with a clear message.
using DRM
using Test

@testset "bridge: R formula operator translation" begin
    p = 16; m = 5
    phy = random_balanced_tree(p; branch_length = 0.20)
    species = ["sp$(i)" for i in repeat(1:p, inner = m)]
    n = length(species)
    rng_x1 = Float64[sin(i) for i in 1:n]          # deterministic, no RNG dependence
    rng_x2 = Float64[cos(2i) for i in 1:n]
    rng_x3 = Float64[sin(3i + 1) for i in 1:n]
    noise  = Float64[0.4 * sin(7.1i + 2.3) for i in 1:n]   # deterministic pseudo-noise
    y = 0.3 .+ 0.5 .* rng_x1 .- 0.2 .* rng_x2 .+ 0.1 .* (rng_x1 .* rng_x2) .+ noise
    dat = (; y, x1 = rng_x1, x2 = rng_x2, x3 = rng_x3, species)

    fitok(f) = isfinite(drm_bridge(; formula = f, family = "gaussian",
                                   data = dat, tree = phy)["loglik"])

    @testset "valid formulas still fit" begin
        @test fitok("y ~ x1; sigma ~ 1")
        @test fitok("y ~ x1 + phylo(1 | species); sigma ~ 1")
        @test fitok("y ~ x1 + phylo(1 | species); sigma ~ phylo(1 | species)")
    end

    @testset "R `:` interaction + phylo no longer crashes" begin
        # The exact shape of Ayumi's MethodError |(::Int64, ::String).
        @test fitok("y ~ x1 + x2 + x1:x2 + phylo(1 | species); sigma ~ 1")
        @test fitok("y ~ x1 + x1:x2 + phylo(1 | species); sigma ~ x1 + x1:x2")
        @test fitok("y ~ x1 + x2 + x3 + x1:x2:x3; sigma ~ 1")   # 3-way
    end

    @testset "R `*` crossing: valid fits, nested bans rejected" begin
        # `*` (crossing = main effects + interaction) is a valid Julia formula op.
        @test fitok("y ~ x1 * x2 + phylo(1 | species); sigma ~ 1")
        # A banned construct nested under `*` or a transform must still be caught
        # (it must NOT leak a raw Julia error). `temp*lat` is common in ecology.
        for f in ("y ~ x1 * I(x1^2); sigma ~ 1",
                  "y ~ x1 * scale(x2); sigma ~ 1",
                  "y ~ log1p(I(x1^2)); sigma ~ 1")
            @test_throws ArgumentError drm_bridge(; formula = f, family = "gaussian",
                                                  data = dat, tree = phy)
        end
    end

    @testset "crash/silent constructs become clear rejections" begin
        for f in ("y ~ x1 + I(x1^2); sigma ~ 1",
                  "y ~ factor(species); sigma ~ 1",
                  "y ~ poly(x1, 2); sigma ~ 1",
                  "y ~ scale(x1); sigma ~ 1",
                  "y ~ (x1 + x2)^2; sigma ~ 1")
            @test_throws ArgumentError drm_bridge(; formula = f, family = "gaussian",
                                                  data = dat, tree = phy)
        end
    end

    @testset "R `- 1` drops the intercept" begin
        with_int = drm_bridge(; formula = "y ~ x1; sigma ~ 1", family = "gaussian", data = dat, tree = phy)
        no_int   = drm_bridge(; formula = "y ~ x1 - 1; sigma ~ 1", family = "gaussian", data = dat, tree = phy)
        # naming-agnostic: dropping the intercept removes exactly one mu coefficient.
        @test length(no_int["coef_names"]) == length(with_int["coef_names"]) - 1
    end
end
