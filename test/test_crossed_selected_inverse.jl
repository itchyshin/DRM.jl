using DRM
using LinearAlgebra, Random, SparseArrays, Test

@testset "Crossed sparse-Laplace selected inverse entries" begin
    rng = MersenneTwister(7001)
    G = 17
    H = 13
    n = 420
    gidx = rand(rng, 1:G, n)
    hidx = rand(rng, 1:H, n)
    weights = 0.1 .+ rand(rng, n)
    diagH = fill(20.0, G + H) .+ rand(rng, G + H)
    Hsp = DRM._crossed_sparse_hessian(diagH, weights, gidx, G, hidx, H)
    ch = cholesky(Symmetric(Hsp); check = false)
    @test issuccess(ch)

    @test !issparse(DRM._crossed_hessian(diagH, weights, gidx, G, hidx, H))

    Gbig = 260
    Hbig = 260
    nbig = 40
    gbig = rand(rng, 1:Gbig, nbig)
    hbig = rand(rng, 1:Hbig, nbig)
    diagbig = fill(2.0, Gbig + Hbig)
    weightsbig = 0.1 .+ rand(rng, nbig)
    @test issparse(DRM._crossed_hessian(diagbig, weightsbig, gbig, Gbig, hbig, Hbig))

    hd, cross = DRM._crossed_selected_inverse_entries(ch, gidx, G, hidx, H)
    Hinv = inv(Symmetric(Matrix(Hsp)))

    @test maximum(abs.(hd .- diag(Hinv))) < 1e-10
    @test maximum(abs.([cross[i] - Hinv[gidx[i], G + hidx[i]] for i in 1:n])) < 1e-10
end
