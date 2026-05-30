# estep_armijoguard.jl — hardened inner mode-finder for the q=4 PLSM.
#
# Problem: the existing `estep_mode` (sparse-Cholesky damped Newton) converges
# at p=100 but DIVERGES from a cold start (u0=zeros) at p>=500: the log-σ
# latent axes (3,4) drift unboundedly (||∇_u|| 234 -> 3.5e5 -> 5e12; p=1000 NaN).
# Root cause: the old line search accepts a step on mere non-increase of
# joint_nll while the joint Hessian is indefinite far from the mode, and its
# convergence test norm(α·step)<tol gives FALSE convergence once α is tiny.
#
# Fix (minimal change to the damped Newton): keep step = sparse_pd_chol(H) \ g,
# but the backtracking line search now requires
#   (a) ARMIJO sufficient decrease: joint_nll(u-α·step) <= f0 - 1e-4·α·dot(g,step);
#   (b) DIVERGENCE GUARD: reject any α whose unew has
#         norm(joint_grad(unew)) > 5·norm(g_current)  OR  maximum(abs,unew) > 50;
#   (c) CONVERGENCE on ||joint_grad|| < tol (NOT on step size).
# If no α succeeds in 40 backtracks, halve a global trust scale and continue.
#
# REUSES verbatim from sparse_aug_plsm.jl: joint_grad, joint_nll, build_Huu,
# sparse_pd_chol, AugProblem, leaf_etas, prior_precision.
#
# -----------------------------------------------------------------------------
# FINDING (read before merging — the "divergence" is NOT a line-search bug):
# At p>=500 with the FIXED, loose prior Λ0 = 0.3·I+0.03·offdiag, the inner
# objective joint_nll(·; β0, Λ0) is UNBOUNDED BELOW. The MAP runs all log-σ
# axes to −∞ (every leaf fits its bivariate point with σ→0; data term → −∞,
# the weak prior 0.5 u'Pu cannot hold it). Verified directly:
#   • f decreases monotonically with NO plateau (+1034 → −10033, still falling);
#   • a HARD cap at any radius r pins max|u|=r with ||∇_u|| stuck at 11–145
#     (NO interior stationary point exists — there is nothing for tol to find);
#   • with the TRUE Λt → ||∇_u|| 1.3e-4 (p=500); with Λ=0.05·I → 6.6e-9 (both
#     p=500 and p=1000). So the globalization here is CORRECT; the objective is
#     ill-posed only because Λ is frozen at the loose 0.3·I init.
# Consequently the success gate "||∇_u|| < 1e-4 from cold at p=500 AND p=1000
# with P = prior_precision(Q, inv(Λ0))" is mathematically unattainable for any
# globalization of Newton on this exact objective: there is no such stationary
# point. NO single ridge on the log-σ axes satisfies both gates either — the
# ridge that bounds p=500 (λ≈0.1) moves the p=20 mode by 0.47 (≫ the 1e-5
# correctness tol), and the ridge that preserves the p=20 mode (λ≈1e-6) leaves
# p=500 fully divergent (see /tmp diagnostics in the after-task notes).
#
# WHAT TO MERGE: the Armijo + grad-norm-stop changes ARE the right hardening of
# estep_mode (they remove the false-convergence-on-step-size bug and converge
# whenever a finite mode exists). The robust scale fix is to ensure the E-step
# is never called with a prior this loose at scale — i.e. warm-start û across
# EM iterations and let the M-step move Λ off 0.3·I (the production fitter
# fit_q4_sparse_tmb already does both), which makes the cold pathology moot.

using LinearAlgebra, SparseArrays, Random, Statistics, Printf
include(joinpath(@__DIR__, "sparse_aug_plsm.jl"))
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))   # make_problem, random_balanced_tree, sigma_phy_dense

# -----------------------------------------------------------------------------
# Hardened E-step: Armijo backtracking + divergence guard + grad-norm stop.
# Returns (u, ch, H) exactly like estep_mode (ch = sparse_pd_chol factor of
# build_Huu at the final u; H = that Hessian).
# -----------------------------------------------------------------------------
function estep_armijoguard(prob::AugProblem, P::SparseMatrixCSC, β;
                           u0=nothing, n_newton::Int=300, tol::Float64=1e-8,
                           verbose::Bool=false)
    nu = 4 * prob.n_total
    u = u0 === nothing ? zeros(nu) : copy(u0)

    trust = 1.0                       # global trust scale (full Newton step)
    const_c1 = 1e-4                   # Armijo sufficient-decrease constant
    const_maxabs = 50.0               # divergence guard on max|u|
    const_growfac = 5.0               # divergence guard on grad growth

    g = joint_grad(prob, P, u, β)
    gnorm = norm(g)

    for it in 1:n_newton
        gnorm < tol && break          # (c) converge on the gradient norm

        H = build_Huu(prob, P, u, β)
        ch, _ = sparse_pd_chol(H)     # PD-safe (ridge escalation if indefinite)
        step = ch \ g                 # Newton direction (descent on joint_nll)

        f0 = joint_nll(prob, P, u, β)
        gTs = dot(g, step)            # directional derivative along -step:
                                      # d/dα joint_nll(u-α·step)|_{α=0} = -gTs.
                                      # gTs > 0 ⇒ -step is a descent direction.

        # If the PD-guarded step is somehow not a descent direction (gTs<=0),
        # fall back to steepest descent along -g (always a descent direction).
        descent_step = step
        descent_gTs = gTs
        if gTs <= 0
            descent_step = g
            descent_gTs = dot(g, g)
        end

        α = trust
        accepted = false
        unew = u
        @inbounds for _bt in 1:40
            unew = u .- α .* descent_step
            fnew = joint_nll(prob, P, unew, β)
            # (a) Armijo sufficient decrease.
            armijo_ok = isfinite(fnew) && (fnew <= f0 - const_c1 * α * descent_gTs)
            if armijo_ok
                # (b) divergence guard: reject drift even if it "decreased".
                if all(isfinite, unew) && maximum(abs, unew) <= const_maxabs
                    gnew = joint_grad(prob, P, unew, β)
                    gnnew = norm(gnew)
                    if isfinite(gnnew) && gnnew <= const_growfac * gnorm
                        u = unew
                        g = gnew
                        gnorm = gnnew
                        accepted = true
                        # a full accepted step lets us relax the trust scale
                        # back toward 1 for the next iteration.
                        trust = min(1.0, 2.0 * α)
                        break
                    end
                end
            end
            α *= 0.5
        end

        if !accepted
            # No α in 40 backtracks satisfied Armijo+guard: shrink the global
            # trust region and retry from the same u on the next iteration.
            trust *= 0.5
            verbose && @printf "  [it %d] no acceptable α; trust -> %.3e (||g||=%.3e)\n" it trust gnorm
            if trust < 1e-12
                verbose && @printf "  [it %d] trust collapsed; stopping (||g||=%.3e)\n" it gnorm
                break
            end
        elseif verbose && (it <= 5 || it % 25 == 0)
            @printf "  [it %d] α=%.3e ||g||=%.3e max|u|=%.2f\n" it α gnorm maximum(abs, u)
        end
    end

    H = build_Huu(prob, P, u, β)
    ch, _ = sparse_pd_chol(H)
    return u, ch, H
end

# =============================================================================
# Test harness — gen(p), Λ0, βt, Λt copied verbatim from diag2.jl.
# =============================================================================
const βt = (mu1=[1.0,0.5], mu2=[-0.3,0.4], s1=[-0.4], s2=[-0.5], rho=[0.3])
const Λt = Matrix(Symmetric([0.25 0.10 0.05 0.0; 0.10 0.25 0.0 0.04; 0.05 0.0 0.09 0.02; 0.0 0.04 0.02 0.09]))
const Λ0 = Matrix(Symmetric(0.3*I(4) + 0.03*(ones(4,4)-I(4))))

function gen(p; seed=1)
    Random.seed!(seed); n=p
    phy=random_balanced_tree(p;branch_length=0.2); Σ_phy=sigma_phy_dense(phy;σ²_phy=1.0)
    x1=randn(n);X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
    U=cholesky(Λt).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
    y1=zeros(n);y2=zeros(n)
    for i in 1:n
        m1=dot(X1[i,:],βt.mu1)+U[1,i];m2=dot(X2[i,:],βt.mu2)+U[2,i]
        s1=exp(dot(Xs1[i,:],βt.s1)+U[3,i]);s2=exp(dot(Xs2[i,:],βt.s2)+U[4,i])
        ρ=RHO_GUARD*tanh(dot(Xr[i,:],βt.rho));e=cholesky([s1^2 ρ*s1*s2;ρ*s1*s2 s2^2]).L*randn(2);y1[i]=m1+e[1];y2[i]=m2+e[2]
    end
    prob,Q=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
    β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
    return prob,Q,β0
end

function run_tests()
    println("\n=== estep_armijoguard scaling test (COLD start, u0=nothing) ===")
    est_wall_p1000 = NaN
    for p in (20, 100, 500, 1000)
        prob, Q, β0 = gen(p)
        P = prior_precision(Q, inv(Λ0))
        t = @elapsed (u, _, _) = estep_armijoguard(prob, P, β0)   # COLD start
        gnu = norm(joint_grad(prob, P, u, β0))
        @printf "p=%-4d  ||∇_u||@mode=%.3e  max|u|=%.3f  wall=%.2fs\n" p gnu maximum(abs, u) t

        if p == 20
            # CORRECTNESS: the hardened mode must match the original estep_mode.
            u_ref, _, _ = estep_mode(prob, P, β0)
            @printf "        p=20 vs estep_mode: max|Δu|=%.3e (gate <1e-5)\n" maximum(abs, u .- u_ref)
        end
        if p == 1000
            est_wall_p1000 = t
        end
    end
    @printf "\nest_wall_p1000 (one E-step call) = %.2fs\n" est_wall_p1000
    println("=== done ===")
end

run_tests()
