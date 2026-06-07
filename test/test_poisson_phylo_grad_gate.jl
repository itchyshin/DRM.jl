# test_poisson_phylo_grad_gate.jl — STANDING FD-vs-analytic gradient gate (#165)
# for the non-Gaussian (Poisson) phylogenetic sparse-Laplace route.
#
# Mirrors test_qgate_fd_gradient.jl (the verified q=4 Q-gate) for the
# Poisson `phylo(1 | grp)` Laplace marginal: the analytic outer gradient
# (`_poisson_phylo_laplace_fg`, the exact implicit-function / implicit-logdet
# gradient that reuses `takahashi_selinv`) MUST match a central finite-difference
# gradient of the TRUE marginal NLL to ≤ 1e-6.
#
# The recipe that makes 1e-6 attainable (same as the q4 gate): drive the inner
# Newton mode to a TIGHT tolerance and warm-start every perturbed solve from the
# base-θ mode, so the finite-difference reference is not dominated by inner-mode
# stopping noise. The gradient is evaluated at a θ OFF the optimum so the
# implicit (db̂/dθ) correction terms are nonzero — a frozen-mode gradient would
# fail this gate.

using DRM
using Test, Random, LinearAlgebra
import Distributions

@testset "Poisson phylo Laplace gradient gate (#165): FD-vs-exact ≤ 1e-6" begin
    Random.seed!(165)
    p = 12
    m = 4                                  # nrep ≥ 2 (scale-RE identifiability)
    phy = random_balanced_tree(p; branch_length = 0.20)
    species = repeat(1:p, inner = m)
    n = length(species)
    x = randn(n)
    βt = [0.20, 0.35]
    σphy = 0.45
    C = sigma_phy_dense(phy; σ²_phy = σphy^2)
    u = cholesky(Symmetric(C)).L * randn(p)
    λ = exp.(βt[1] .+ βt[2] .* x .+ u[species])
    y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])

    Xμ = hcat(ones(n), x)
    Q, leaf_node, _ = DRM._poisson_phylo_setup(phy, species)
    q = size(Q, 1)
    qchol = cholesky(Symmetric(Q); check = false)
    logdetQ = logdet(qchol)
    lf = [DRM._logfactorial(round(Int, yi)) for yi in y]

    # θ = [βμ(2); logσ], deliberately OFF the optimum.
    θ = [0.10, 0.45, log(0.55)]

    # Tightly-converged base mode, reused as the warm start for every solve so
    # the FD reference sees the same inner mode the analytic gradient froze.
    ntol = 1e-13
    nmax = 400
    val0, g_an, b_base, ok = DRM._poisson_phylo_laplace_fg(
        y, Xμ, leaf_node, Q, logdetQ, lf, θ;
        grad = true, b0 = zeros(q), newton_tol = ntol, newton_maxiter = nmax,
    )
    @test ok
    @test isfinite(val0)

    mnll(t) = DRM._poisson_phylo_laplace_fg(
        y, Xμ, leaf_node, Q, logdetQ, lf, Vector{Float64}(t);
        grad = false, b0 = copy(b_base), newton_tol = ntol, newton_maxiter = nmax,
    )[1]

    h = 1e-5
    g_fd = similar(g_an)
    for k in eachindex(θ)
        tp = copy(θ); tp[k] += h
        tm = copy(θ); tm[k] -= h
        g_fd[k] = (mnll(tp) - mnll(tm)) / (2h)
    end

    max_abs_diff = maximum(abs, g_an .- g_fd)
    @info "Poisson phylo gradient gate" max_abs_diff g_an g_fd
    @test max_abs_diff ≤ 1e-6
end
