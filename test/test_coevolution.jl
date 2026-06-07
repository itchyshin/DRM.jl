using DRM
using Test, LinearAlgebra, Random, Statistics

function _mock_coevolution_fit(Σ; V=0.0025I(10))
    θ = Λ_to_lc(Matrix(Symmetric(Σ)))
    blocks = [:phylocov => 1:10]
    names = [
        :phylocov => [
            "Sigma_a:L11",
            "Sigma_a:L21",
            "Sigma_a:L22",
            "Sigma_a:L31",
            "Sigma_a:L32",
            "Sigma_a:L33",
            "Sigma_a:L41",
            "Sigma_a:L42",
            "Sigma_a:L43",
            "Sigma_a:L44",
        ],
    ]
    fit = DrmFit(
        Gaussian(),
        blocks,
        names,
        θ,
        Matrix{Float64}(V),
        0.0,
        1,
        true,
        Dict{Symbol,Vector{Float64}}(),
        Dict{Symbol,Vector{Float64}}(),
        Dict{Symbol,Vector{Float64}}(),
    )
    re = (;
        effects=Dict(:species => zeros(4, 2)),
        Sigma_a=Matrix(Symmetric(Σ)),
        axes=(:mu1, :mu2, :sigma1, :sigma2),
        group=:species,
    )
    return DRM._withranef(fit, re)
end

@testset "coevolution(fit) group-level Sigma_a readout" begin
    Σ = Matrix(
        Symmetric(
            [
                0.25 0.10 0.05 0.00
                0.10 0.16 0.06 0.04
                0.05 0.06 0.09 0.02
                0.00 0.04 0.02 0.04
            ]
        ),
    )
    fit = _mock_coevolution_fit(Σ)

    out = coevolution(fit; method=:none)
    @test out.group === :species
    @test out.source === :phylo
    @test out.axes == (:mu1, :mu2, :sigma1, :sigma2)
    @test out.labels == (:l1, :l2, :s1, :s2)
    @test out.covariance ≈ Σ
    @test out.sd.l1 ≈ sqrt(Σ[1, 1])
    @test out.sd.s2 ≈ sqrt(Σ[4, 4])
    @test out.correlation.l1l2 ≈ Σ[1, 2] / sqrt(Σ[1, 1] * Σ[2, 2])
    @test out.correlation.s1s2 ≈ Σ[3, 4] / sqrt(Σ[3, 3] * Σ[4, 4])
    @test out.correlation.l1s2 ≈ Σ[1, 4] / sqrt(Σ[1, 1] * Σ[4, 4])
    @test out.correlation.l2s1 ≈ Σ[2, 3] / sqrt(Σ[2, 2] * Σ[3, 3])
    @test out.correlation_matrix[3, 4] ≈ out.correlation.s1s2
    @test all(ismissing, out.ci.l1)
    @test length(out.rows) == 10
    @test [r.name for r in out.rows[1:4]] == [:l1, :l2, :s1, :s2]
    @test [r.name for r in out.rows[5:10]] == [:l1l2, :s1s2, :l1s2, :l2s1, :l1s1, :l2s2]
end

@testset "coevolution(fit) Wald intervals from phylocov vcov" begin
    Σ = Matrix(
        Symmetric(
            [
                0.30 0.06 0.03 0.02
                0.06 0.25 0.04 0.01
                0.03 0.04 0.12 0.03
                0.02 0.01 0.03 0.10
            ]
        ),
    )
    fit = _mock_coevolution_fit(Σ; V=0.001I(10))
    out = coevolution(fit; level=0.90, method=:wald)
    @test out.level == 0.90
    @test out.method === :wald
    for r in out.rows
        @test isfinite(r.lower)
        @test isfinite(r.upper)
        @test r.lower <= r.estimate <= r.upper
    end

    no_vcov = _mock_coevolution_fit(Σ; V=fill(NaN, 10, 10))
    @test_throws ArgumentError coevolution(no_vcov)
    @test all(ismissing, coevolution(no_vcov; method=:none).ci.l1)
end

@testset "coevolution(fit) is distinct from residual rho12" begin
    Random.seed!(188)
    n = 300
    x = randn(n)
    ρ = 0.35
    y1 = 1 .+ 0.4 .* x .+ randn(n)
    y2 = -0.2 .+ 0.3 .* x .+ ρ .* (y1 .- mean(y1)) .+ sqrt(1 - ρ^2) .* randn(n)
    dat = (; y1, y2, x)
    fit = drm(
        bf(;
            mu1=@formula(y1 ~ x),
            mu2=@formula(y2 ~ x),
            sigma1=@formula(sigma1 ~ 1),
            sigma2=@formula(sigma2 ~ 1),
            rho12=@formula(rho12 ~ 1)
        ),
        Gaussian();
        data=dat,
    )

    @test !isempty(rho12(fit))
    @test_throws ArgumentError coevolution(fit)
end
