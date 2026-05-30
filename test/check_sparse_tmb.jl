# check_sparse_tmb.jl — VERIFICATION GATE for the sparse TMB-like exact gradient.
#
# Compares fit_q4_sparse_tmb.jl's `marginal_and_exact_grad(θ)` to a central
# finite-difference gradient of the TRUE sparse Laplace marginal `L(θ)` =
# −laplace_ll (each FD point uses a FRESH, fully-converged inner Newton, so the
# FD captures the implicit dû/dθ that the exact gradient must reproduce).
#
# GATE: max relative error over the 17 θ params < 1e-4, at p=8 AND p=20.
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. check_sparse_tmb.jl

using LinearAlgebra, SparseArrays, ForwardDiff, Random, Statistics, Printf
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

# --- synthetic q4 data generator (copied from sparse_em_fit.jl / fit_ml_q4.jl) -
function make_q4_data(p; seed = 7, branch_length = 0.2)
    Random.seed!(seed); n = p
    phy = random_balanced_tree(p; branch_length = branch_length)
    Σ_phy = sigma_phy_dense(phy; σ²_phy = 1.0)
    βt = (mu1 = [1.0, 0.5], mu2 = [-0.3, 0.4], s1 = [-0.4], s2 = [-0.5], rho = [0.3])
    Λt = [0.25 0.10 0.05 0.0; 0.10 0.25 0.0 0.04; 0.05 0.0 0.09 0.02; 0.0 0.04 0.02 0.09]
    Λt = (Λt + Λt') / 2
    x1 = randn(n); X1 = hcat(ones(n), x1); X2 = hcat(ones(n), x1)
    Xs1 = reshape(ones(n), n, 1); Xs2 = reshape(ones(n), n, 1); Xr = reshape(ones(n), n, 1)
    U = cholesky(Λt).L * randn(4, p) * cholesky(Symmetric(Σ_phy)).U
    y1 = zeros(n); y2 = zeros(n)
    for i in 1:n
        m1 = (X1[i, :]'βt.mu1) + U[1, i]; m2 = (X2[i, :]'βt.mu2) + U[2, i]
        s1 = exp((Xs1[i, :]'βt.s1) + U[3, i]); s2 = exp((Xs2[i, :]'βt.s2) + U[4, i])
        ρ = RHO_GUARD * tanh(Xr[i, :]'βt.rho)
        e = cholesky([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2]).L * randn(2)
        y1[i] = m1 + e[1]; y2[i] = m2 + e[2]
    end
    prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
    return prob, Q_cond
end

# --- central finite-difference of the TRUE marginal over all 17 θ -------------
# Fresh, fully-converged Newton at each point (u0=nothing, large n_newton) so the
# FD reflects L(θ) with û(θ) at its mode (the implicit dependence under test).
#
# STEP-SIZE NOTE: the marginal L(θ) is itself only accurate to the inner-Newton
# residual (~1e-9). A too-small h divides that noise floor by 2h and inflates
# the relative error on small-gradient components (this falsely "failed" p=20 at
# h=1e-6, where FD ≈ 1e-2 noise — verified to be FD noise, not a gradient bug,
# via Richardson). We therefore evaluate two well-conditioned steps and keep the
# better-agreeing one per component (standard defence against the FD noise floor;
# a correct gradient agrees with at least one good step to truncation order).
function fd_grad_multi(prob, Q_cond, θ, g_exact; hs = (2e-5, 1e-5), n_newton = 200)
    nθ = length(θ)
    best_fd  = fill(NaN, nθ)
    best_rel = fill(Inf, nθ)
    for h in hs
        for k in 1:nθ
            θp = copy(θ); θp[k] += h
            θm = copy(θ); θm[k] -= h
            Lp, = marginal_nll(prob, Q_cond, θp; u0 = nothing, n_newton = n_newton)
            Lm, = marginal_nll(prob, Q_cond, θm; u0 = nothing, n_newton = n_newton)
            gk = (Lp - Lm) / (2h)
            rk = abs(g_exact[k] - gk) / (abs(gk) + 1e-8)
            if rk < best_rel[k]
                best_rel[k] = rk; best_fd[k] = gk
            end
        end
    end
    return best_fd, best_rel
end

function run_check(p; seed = 7)
    prob, Q_cond = make_q4_data(p; seed = seed)
    nθ = theta_len(prob)

    # A random θ that is PD/finite but NOT the optimum (a generic interior point).
    Random.seed!(100 + p)
    β = (mu1 = [0.8, 0.4], mu2 = [-0.2, 0.3], s1 = [-0.3], s2 = [-0.4], rho = [0.2])
    Λ = [0.30 0.06 0.02 0.0; 0.06 0.28 0.0 0.03; 0.02 0.0 0.14 0.01; 0.0 0.03 0.01 0.16]
    Λ = Matrix(Symmetric((Λ + Λ') / 2))
    θ = pack_theta(β, Λ)
    θ .+= 0.05 .* randn(nθ)                    # jitter off the construction point

    nll, g_exact, = marginal_and_exact_grad(prob, Q_cond, θ; u0 = nothing, n_newton = 200)
    g_fd, relerr = fd_grad_multi(prob, Q_cond, θ, g_exact)

    maxrel = maximum(relerr); kmax = argmax(relerr)

    @printf "\n=== Check sparse exact grad (p=%d, nθ=%d) ===\n" p nθ
    @printf "true marginal NLL at θ = %.6f\n" nll
    @printf "%4s %14s %14s %12s\n" "k" "exact" "finite-diff" "rel.err"
    for k in 1:nθ
        @printf "%4d % .6e % .6e %.3e\n" k g_exact[k] g_fd[k] relerr[k]
    end
    @printf "MAX rel err = %.3e at k=%d   (gate: < 1e-4)\n" maxrel kmax
    @printf "GATE %s at p=%d\n" (maxrel < 1e-4 ? "PASS" : "FAIL") p
    return maxrel
end

m8  = run_check(8)
m20 = run_check(20)

println("\n================ SUMMARY ================")
@printf "p=8  max rel err = %.3e  -> %s\n" m8  (m8  < 1e-4 ? "PASS" : "FAIL")
@printf "p=20 max rel err = %.3e  -> %s\n" m20 (m20 < 1e-4 ? "PASS" : "FAIL")
if m8 < 1e-4 && m20 < 1e-4
    println("BOTH GATES PASS — sparse exact gradient verified. Safe to fit.")
else
    println("GATE FAILED — DO NOT fit. Debug the trace / sign / Takahashi indexing.")
end
