# test_lambda_p100.jl — CHARACTERISATION of a measured negative result (#472).
#
# The sparse-EM Λ M-step (`mstep_Lambda`) does NOT ascend the true Laplace
# marginal on the real q4_p100 data: the closed-form update moves DOWNHILL for
# every step size in (1.0, 0.5, 0.25, 0.1, 0.01) — measured 2026-08-25, and
# independently corroborated by the (unwired) test_analytic_grad.jl, whose
# gradient premise fails at 3–690% against central differences. This is the
# measured confirmation of why production (`src/fit_ml_q4.jl`) abandoned the
# closed-form step for line-searched ascent. `mstep_Lambda`/`fit_em_aug` are
# NOT reachable from the public `drm()` API and back only the `bench/` EM
# demos (fence recorded in src/sparse_em_fit.jl and HANDOVER.md).
#
# This file therefore asserts the DESCENT — the defect as measured — per
# #472's own instruction that no option may weaken the test to make it pass.
# If someone repairs `mstep_Lambda`, these assertions fail LOUDLY, which is
# the intended tripwire: a repair must also revisit the fence text here, in
# src/sparse_em_fit.jl, and in HANDOVER.md. Same question as
# test_lambda_direction.jl (p=8, synthetic), at the fixture scale (p=100)
# that originally motivated it.

using DRM
using Test, LinearAlgebra, Statistics
using DelimitedFiles: readdlm

const D = DRM
const FIX = joinpath(@__DIR__, "..", "bench", "fixtures")

@testset "sparse-EM Λ M-step DESCENDS the true Laplace marginal (q4_p100, #472 characterisation)" begin
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

    # The measured defect, asserted as such (see header): every tested step
    # along the closed-form update direction LOWERS the marginal.
    @test L_of_Λ(Λem) < L0
    for α in (1.0, 0.5, 0.25, 0.1, 0.01)
        Λα = Matrix(Symmetric(Λ0 .+ α .* (Λem .- Λ0)))
        @test L_of_Λ(Λα) < L0
    end
end
