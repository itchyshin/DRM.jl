# test_lambda_p100.jl — does the sparse-EM Λ M-step (`mstep_Lambda`) ASCEND
# the true Laplace marginal on the REAL q4_p100 data? Same question as
# test_lambda_direction.jl (p=8, synthetic), but at the fixture scale (p=100)
# that originally motivated it. `mstep_Lambda`/`fit_em_aug` are not on the
# public `drm()` path (see test_lambda_direction.jl), but back the
# `sparse_em_fit.jl` demos and have no other test coverage at this scale.

using DRM
using Test, LinearAlgebra, Statistics
using DelimitedFiles: readdlm

const D = DRM
const FIX = joinpath(@__DIR__, "..", "bench", "fixtures")

@testset "sparse-EM Λ M-step ascends the true Laplace marginal (q4_p100)" begin
    raw, header = readdlm(joinpath(FIX, "q4_p100.csv"), ','; header = true)
    cols = Symbol.(strip.(string.(vec(header))))
    col(name) = raw[:, findfirst(==(name), cols)]
    y1 = Float64.(col(:y1)); y2 = Float64.(col(:y2)); x1 = Float64.(col(:x1))
    species = String.(strip.(string.(col(:species))))

    phy = augmented_phy(read(joinpath(FIX, "q4_p100_tree.nwk"), String))
    p = length(y1); n = p
    name2row = Dict(String(s) => i for (i, s) in enumerate(species))
    perm = [name2row[phy.leaf_names[k]] for k in 1:p]
    y1 = y1[perm]; y2 = y2[perm]; x1 = x1[perm]

    X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
    Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)
    prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
    β = (mu1 = X1 \ y1, mu2 = X2 \ y2, s1 = [log(std(y1 .- X1 * (X1 \ y1)))],
         s2 = [log(std(y2 .- X2 * (X2 \ y2)))], rho = [0.0])

    # FULLY-converged E-step (no warm start, many Newton iters) for accurate marginals
    function L_of_Λ(Λ; nit = 60)
        P = prior_precision(Q_cond, inv(Λ))
        u, ch, _ = estep_mode(prob, P, β; u0 = nothing, n_newton = nit)
        return D.laplace_ll(prob, P, β, u, ch)
    end
    Λ0 = Matrix(0.3 * I(4)); L0 = L_of_Λ(Λ0)
    P0 = prior_precision(Q_cond, inv(Λ0)); u0, ch0, _ = estep_mode(prob, P0, β; n_newton = 60)
    Λem = D.mstep_Lambda(prob, Q_cond, u0, ch0)

    @test L_of_Λ(Λem) > L0
    for α in (1.0, 0.5, 0.25, 0.1, 0.01)
        Λα = Matrix(Symmetric(Λ0 .+ α .* (Λem .- Λ0)))
        @test L_of_Λ(Λα) > L0
    end
end
