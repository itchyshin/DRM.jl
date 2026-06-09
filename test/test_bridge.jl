using DRM
using Test, Random, LinearAlgebra

@testset "drm_bridge primitive R boundary" begin
    Random.seed!(20260608)
    n = 80
    x = range(-1, 1; length = n)
    y = 0.3 .+ 0.8 .* x .+ exp.(-0.4 .+ 0.2 .* x) .* randn(n)
    data = (; y = collect(y), x = collect(x))

    native = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = data)
    bridged = drm_bridge(;
        formula = "y ~ x; sigma ~ x",
        family = "gaussian",
        data = data,
    )

    @test bridged["family"] == "gaussian"
    @test bridged["coef_names"] ==
        ["mu_(Intercept)", "mu_x", "sigma_(Intercept)", "sigma_x"]
    @test bridged["coefficients"] ≈ coef(native)
    @test bridged["vcov"] ≈ vcov(native)
    @test bridged["loglik"] ≈ loglik(native)
    @test bridged["aic"] ≈ aic(native)
    @test bridged["bic"] ≈ bic(native)
    @test bridged["df"] == dof(native)
    @test bridged["nobs"] == nobs(native)
    @test bridged["converged"] == is_converged(native)
    @test bridged["fitted"] ≈ fitted(native)
    @test bridged["residuals"] ≈ residuals(native)
    @test bridged["sigma"] ≈ sigma(native)
    @test isempty(bridged["corpairs"])

    keyed = drm_bridge(;
        formula = Dict(:mu => "y ~ x", :sigma => "sigma ~ x"),
        family = "gaussian",
        data = Dict("y" => collect(y), "x" => collect(x)),
    )
    @test keyed["coefficients"] ≈ bridged["coefficients"]
    @test keyed["loglik"] ≈ bridged["loglik"]

    @test_throws ArgumentError drm_bridge(;
        formula = Dict(:sigma => "sigma ~ x"),
        family = "gaussian",
        data = data,
    )

    y2 = -0.2 .+ 0.4 .* x .+ 0.5 .* randn(n)
    bdata = (; y1 = collect(y), y2 = collect(y2), x = collect(x))
    bnative = drm(
        bf(;
            mu1 = @formula(y1 ~ x),
            mu2 = @formula(y2 ~ x),
            sigma1 = @formula(sigma1 ~ 1),
            sigma2 = @formula(sigma2 ~ 1),
            rho12 = @formula(rho12 ~ 1),
        ),
        Gaussian();
        data = bdata,
    )
    bbridged = drm_bridge(;
        formula = Dict(
            :mu1 => "y1 ~ x",
            :mu2 => "y2 ~ x",
            :sigma1 => "sigma1 ~ 1",
            :sigma2 => "sigma2 ~ 1",
            :rho12 => "rho12 ~ 1",
        ),
        family = "biv_gaussian",
        data = bdata,
    )
    @test bbridged["coef_names"] == [
        "mu1_(Intercept)", "mu1_x", "mu2_(Intercept)", "mu2_x",
        "sigma1_(Intercept)", "sigma2_(Intercept)", "rho12_(Intercept)",
    ]
    @test bbridged["coefficients"] ≈ coef(bnative)
    @test bbridged["vcov"] ≈ vcov(bnative)
    @test bbridged["fitted"]["mu1"] ≈ fitted(bnative)[:mu1]
    @test bbridged["fitted"]["mu2"] ≈ fitted(bnative)[:mu2]
    @test bbridged["sigma"]["sigma1"] ≈ sigma(bnative)[:sigma1]
    @test bbridged["sigma"]["sigma2"] ≈ sigma(bnative)[:sigma2]
    @test bbridged["corpairs"] ≈ corpairs(bnative)

    newick = "((sp_1:0.3,sp_2:0.3):0.3,(sp_3:0.3,sp_4:0.3):0.3);"
    empty!(DRM._BRIDGE_TREE_CACHE)
    cached_phy1 = DRM._bridge_tree(newick)
    cached_phy2 = DRM._bridge_tree(newick)
    @test cached_phy1 === cached_phy2
    @test length(DRM._BRIDGE_TREE_CACHE) == 1

    G = 16
    m = 4
    phy = random_balanced_tree(G; branch_length = 0.3)
    C = sigma_phy_dense(phy; σ²_phy = 1.0)
    d = sqrt.(diag(C))
    K = C ./ (d * d')
    species = repeat(1:G, inner = m)
    xphy = randn(G * m)
    uphy = 0.6 .* (cholesky(Symmetric(K)).L * randn(G))
    yphy = 0.1 .+ 0.5 .* xphy .+ uphy[species] .+ 0.4 .* randn(G * m)
    pdata = (; y = yphy, x = xphy, species = species)
    pnative = drm(
        bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
        Gaussian();
        data = pdata,
        tree = phy,
    )
    pbridged = drm_bridge(;
        formula = Dict(:mu => "y ~ x + phylo(1 | species)", :sigma => "sigma ~ 1"),
        family = "gaussian",
        data = pdata,
        tree = phy,
    )
    @test pbridged["coefficients"] ≈ coef(pnative)
    @test pbridged["loglik"] ≈ loglik(pnative)
    @test pbridged["converged"] == is_converged(pnative)
    @test pbridged["fitted"] ≈ fitted(pnative)
    @test pbridged["sigma"] ≈ sigma(pnative)

    pprofile = drm_bridge_inference(;
        formula = Dict(:mu => "y ~ x + phylo(1 | species)", :sigma => "sigma ~ 1"),
        family = "gaussian",
        data = pdata,
        tree = phy,
        method = "profile",
        level = 0.80,
    )
    @test pprofile["method"] == "profile"
    @test pprofile["param"] == "resd"
    @test pprofile["status"] == "profile"
    @test pprofile["used"] == 1
    @test pprofile["failed"] == 0
    @test isfinite(pprofile["lower"])
    @test isfinite(pprofile["upper"])

    pbootstrap = drm_bridge_inference(;
        formula = Dict(:mu => "y ~ x + phylo(1 | species)", :sigma => "sigma ~ 1"),
        family = "gaussian",
        data = pdata,
        tree = phy,
        method = "bootstrap",
        level = 0.80,
        B = 3,
        seed = 20260609,
    )
    @test pbootstrap["method"] == "bootstrap"
    @test pbootstrap["param"] == "resd"
    @test pbootstrap["attempted"] == 3
    @test pbootstrap["used"] >= 2
    @test pbootstrap["failed"] <= 1
    @test isfinite(pbootstrap["lower"])
    @test isfinite(pbootstrap["upper"])
end
