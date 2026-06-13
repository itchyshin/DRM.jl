# reml_q4.jl -- REML for the q=4 PLSM.
#
# REML = integrate out the LINEAR mean fixed effects beta_mu (mu1 and mu2
# intercepts+slopes) jointly with the latent random effects, via a BORDERED
# augmented state with ZERO / flat prior on beta_mu.
# The non-linear coefficients (beta_s1, beta_s2, beta_rho) stay as outer params.
#
# STANDARD REML FORMULA (Patterson & Thompson 1971 / lme4 / ASReml):
#
#   L_REML(phi) = L_ML(phi, beta_mu_hat)
#                 - 0.5 * logdet(Xtilde_mu' H_uu^{-1} Xtilde_mu)
#
# where
#   phi           = (beta_s1, beta_s2, beta_rho, Lambda) -- outer params, no beta_mu
#   beta_mu_hat   = ML estimate of beta_mu at phi (conditional Newton)
#   H_uu          = joint NLL Hessian wrt latents at mode (CHOLMOD from estep_mode)
#   Xtilde_mu     = (n_u x n_beta_mu) lifted design matrix:
#                   row (4(t-1)+1) = X1[i,:] for mu1,  row (4(t-1)+2) = X2[i,:] for mu2
#                   zero everywhere else
#
# The correction -0.5 logdet(S) is negative, so L_REML < L_ML at the same phi.
# Larger Lambda -> larger H_uu^{-1} -> larger logdet(S) -> bigger penalty:
# REML pushes Lambda LARGER than ML -- the defining less-biased REML property.
#
# KEY SIMPLIFICATION: d leaf_nll / d beta_mu[k] = d leaf_nll / d u[axis] * X[i,k].
# So Xtilde_mu is just the design placed at the mean-axis positions in u -- no new
# leaf derivatives, just reusing the existing leaf_etas layout.
#
# ADDITIVE BUILD: does NOT modify any of the working engine files:
#   sparse_aug_plsm.jl, fit_q4_sparse_tmb.jl, sparse_em_fit.jl, fit_ml_q4.jl
#
# GATE (task requirement):
#   (a) synthetic p=30, nrep=3: diag(Lambda_REML) >= diag(Lambda_ML) (component-wise)
#   (b) gradient ~ 0 at REML optimum (finite-diff check, max|g| < 0.5)
#   (c) runs at p=100 real q4_p100 without error, finite negative logLik
#   (baseline) fit_q4_sparse_tmb still gives logLik ~ -256.51
#
# Run:
#   ~/.juliaup/bin/julia --project="/Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia" \
#       "/Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4/reml_q4.jl"

using LinearAlgebra, SparseArrays, ForwardDiff, Statistics, Printf, Optim, Random
# Additive include into the DRM module: the q=4 engine symbols (AugProblem,
# lc_to_Λ, Λ_to_lc, prior_precision, estep_mode, laplace_ll, leaf_etas,
# leaf_hess, leaf_nll, RHO_GUARD, fit_q4_sparse_tmb, pack_theta) are already in
# module scope via fit_q4_sparse_tmb.jl's include chain — no self-include here.

# ---------------------------------------------------------------------------
# phi layout: (beta_s1[ks1], beta_s2[ks2], beta_rho[kr], lc[10])
# total phi-length = ks1 + ks2 + kr + 10.   beta_mu is ABSENT (profiled out).
# ---------------------------------------------------------------------------

function phi_widths(prob::AugProblem)
    return size(prob.Xs1, 2), size(prob.Xs2, 2), size(prob.Xr, 2)
end

function phi_len(prob::AugProblem)
    ks1, ks2, kr = phi_widths(prob)
    return ks1 + ks2 + kr + 10
end

function unpack_phi(prob::AugProblem, phi::AbstractVector{T}) where {T}
    ks1, ks2, kr = phi_widths(prob)
    o1 = 0; o2 = o1+ks1; o3 = o2+ks2; o4 = o3+kr
    beta_s = (s1 = phi[o1+1:o1+ks1], s2 = phi[o2+1:o2+ks2], rho = phi[o3+1:o3+kr])
    lc     = phi[o4+1:o4+10]
    return beta_s, lc
end

function pack_phi(prob::AugProblem, beta_s, Lam)
    vcat(beta_s.s1, beta_s.s2, beta_s.rho, Λ_to_lc(Lam))
end

# ---------------------------------------------------------------------------
# Build Xtilde_mu -- the lifted (n_u x n_beta_mu) mean design matrix.
# Nonzero only at leaf mean-axis rows: axis1 gets X1 rows, axis2 gets X2 rows.
# When a leaf has multiple observations, all are accumulated (matching H_uu).
# ---------------------------------------------------------------------------
function build_Xmu_lifted(prob::AugProblem)
    k1 = size(prob.X1, 2); k2 = size(prob.X2, 2)
    nbmu = k1 + k2
    nu   = 4 * prob.n_total
    rows_I = Int[]; cols_J = Int[]; vals_V = Float64[]
    @inbounds for i in eachindex(prob.leaf_node)
        t    = prob.leaf_node[i]
        base = 4*(t - 1)
        for c in 1:k1
            push!(rows_I, base + 1); push!(cols_J, c);    push!(vals_V, prob.X1[i, c])
        end
        for c in 1:k2
            push!(rows_I, base + 2); push!(cols_J, k1+c); push!(vals_V, prob.X2[i, c])
        end
    end
    return sparse(rows_I, cols_J, vals_V, nu, nbmu)
end

# ---------------------------------------------------------------------------
# Conditional Newton on beta_mu at fixed u_hat, over ALL data rows.
# Unlike mstep_beta (which uses 1:prob.p and misses replicate observations),
# this iterates eachindex(prob.leaf_node) so it is correct for nrep >= 1.
# ---------------------------------------------------------------------------
function cond_newton_beta_mu(prob::AugProblem, u_hat::Vector{Float64},
                              beta_full; n_newton::Int=20, tol::Float64=1e-10)
    k1 = size(prob.X1, 2); k2 = size(prob.X2, 2)
    nbmu = k1 + k2
    # Pre-extract leaf u-blocks (node-indexed, not data-row-indexed)
    nu_len = 4 * prob.n_total
    # Cached eta for non-mean axes at current beta_full
    etas_s1 = prob.Xs1 * beta_full.s1
    etas_s2 = prob.Xs2 * beta_full.s2
    etas_r  = prob.Xr  * beta_full.rho

    # Objective: NLL over all data rows as a function of [beta_mu1; beta_mu2]
    function f_bmu(bv)
        bm1 = bv[1:k1]; bm2 = bv[k1+1:k1+k2]
        eta1 = prob.X1 * bm1; eta2 = prob.X2 * bm2
        tot  = zero(eltype(bv))
        @inbounds for i in eachindex(prob.leaf_node)
            t    = prob.leaf_node[i]; base = 4*(t - 1)
            ublk = (u_hat[base+1], u_hat[base+2], u_hat[base+3], u_hat[base+4])
            tot += leaf_nll(ublk, prob.y1[i], prob.y2[i],
                            eta1[i], eta2[i], etas_s1[i], etas_s2[i], etas_r[i])
        end
        return tot
    end

    bv = vcat(beta_full.mu1, beta_full.mu2)
    for _ in 1:n_newton
        g = ForwardDiff.gradient(f_bmu, bv)
        H = ForwardDiff.hessian(f_bmu, bv)
        local step = g
        for lam in (0.0, 1e-8, 1e-6, 1e-4, 1e-2, 1.0, 1e2)
            ch = cholesky(Symmetric(H + lam*I); check=false)
            if issuccess(ch); step = ch \ g; break; end
        end
        f0 = f_bmu(bv); alpha = 1.0; bvn = bv .- alpha .* step
        for _ in 1:25
            (f_bmu(bvn) <= f0 || alpha < 1e-8) && break
            alpha *= 0.5; bvn = bv .- alpha .* step
        end
        bv = bvn
        norm(alpha .* step) < tol && break
    end
    return (mu1 = bv[1:k1], mu2 = bv[k1+1:k1+k2])
end

# ---------------------------------------------------------------------------
# REML log-likelihood at outer parameters phi.
#   1. Unpack phi, build P.
#   2. Warm E-step to get u_hat.
#   3. Conditional Newton on beta_mu at fixed u_hat (ALL data rows).
#   4. Re-run E-step with updated beta_mu for consistency.
#   5. L_ML = laplace_ll(u_hat, beta_hat, P).
#   6. REML correction: S = Xtilde_mu' H_uu^{-1} Xtilde_mu;  -0.5 logdet(S).
# Returns: (reml_ll_val, u_hat, ch_H, beta_full, P)
# ---------------------------------------------------------------------------
function reml_ll_and_mode(prob::AugProblem, Q_cond::SparseMatrixCSC,
                          phi::Vector{Float64};
                          u0=nothing, bmu0=nothing, n_newton::Int=40)
    k1 = size(prob.X1, 2); k2 = size(prob.X2, 2)
    beta_s, lc = unpack_phi(prob, phi)
    Lam  = lc_to_Λ(lc)
    P    = prior_precision(Q_cond, inv(Lam))

    # Initial beta_mu guess
    bm1 = bmu0 === nothing ? prob.X1 \ prob.y1 : bmu0.mu1
    bm2 = bmu0 === nothing ? prob.X2 \ prob.y2 : bmu0.mu2
    beta_full = (mu1 = bm1, mu2 = bm2, s1 = beta_s.s1, s2 = beta_s.s2, rho = beta_s.rho)

    # Alternate E-step and beta_mu Newton until jointly converged.
    # The Schur complement S is only PD at the joint mode of jn(u, beta_mu).
    # We need enough alternations so both u and beta_mu are at their joint mode.
    u_hat = u0 === nothing ? zeros(4*prob.n_total) : Vector{Float64}(u0)
    ch_H  = nothing
    for alt_it in 1:15    # up to 15 alternations for cold starts
        u_hat, ch_H, _ = estep_mode(prob, P, beta_full; u0=u_hat, n_newton=n_newton)
        u_hat = Vector{Float64}(u_hat)
        bmu_new = cond_newton_beta_mu(prob, u_hat, beta_full; n_newton=20)
        delta_bmu = norm(bmu_new.mu1 .- beta_full.mu1) + norm(bmu_new.mu2 .- beta_full.mu2)
        beta_full = (mu1 = bmu_new.mu1, mu2 = bmu_new.mu2,
                     s1  = beta_s.s1, s2  = beta_s.s2, rho = beta_s.rho)
        delta_bmu < 1e-6 && break   # joint convergence
    end
    # Final E-step with converged beta_mu
    u_hat, ch_H, _ = estep_mode(prob, P, beta_full; u0=u_hat, n_newton=n_newton)
    u_hat = Vector{Float64}(u_hat)

    ml_ll = laplace_ll(prob, P, beta_full, u_hat, ch_H)

    # REML correction: -0.5 * logdet(S) where S is the Schur complement of
    # beta_mu in the joint Hessian of jn(u, beta_mu).
    #
    # S = H_bmu_bmu - H_bmu_u * H_uu^{-1} * H_u_bmu
    #
    # The EXACT H_u_bmu (nu x nbmu) is:
    #   H_u_bmu[4(t-1)+d, k] = sum over k-entries in beta_mu of
    #       d^2 leaf_nll / d u[d] d eta[d'] * d eta[d'] / d beta_mu[k]
    #
    # For the bivariate Gaussian, eta1 = X1*beta_mu1 and eta2 = X2*beta_mu2.
    # The Hessian of leaf_nll(u, y, eta1, eta2, ...) wrt u and eta[d'] is
    # the (1:2, 1:2) block of the 4x4 leaf Hessian viewed as:
    #   d^2 leaf / d u[d] d eta[d'] = d^2 leaf / d (eta[d]+u[d]) d (eta[d']+u[d'])
    #     for d, d' in {1,2} = H_uu_mean_block[d, d'].
    # Therefore:
    #   H_u_bmu[base+1, k_in_mu1] = H_b[1,1] * X1[i, k] (d=1, d'=1)
    #   H_u_bmu[base+1, k_in_mu2] = H_b[1,2] * X2[i, k] (d=1, d'=2, cross term!)
    #   H_u_bmu[base+2, k_in_mu1] = H_b[2,1] * X1[i, k] (d=2, d'=1, cross term!)
    #   H_u_bmu[base+2, k_in_mu2] = H_b[2,2] * X2[i, k] (d=2, d'=2)
    # (d=3,4 axes -- log-sigma -- have no beta_mu coupling.)
    #
    # Similarly H_bmu_bmu = X_mu' * H_mean2x2 * X_mu (fully dense nbmu x nbmu).
    #
    nbmu = k1 + k2
    nu   = 4 * prob.n_total
    eta1_v, eta2_v, etas1_v, etas2_v, etar_v = leaf_etas(prob, beta_full)

    # Build H_u_bmu (nu x nbmu, dense) and H_bmu_bmu (nbmu x nbmu) analytically.
    H_u_bmu   = zeros(nu, nbmu)
    H_bmu_bmu = zeros(nbmu, nbmu)
    @inbounds for i in eachindex(prob.leaf_node)
        t    = prob.leaf_node[i]; base = 4*(t - 1)
        ublk = [u_hat[base+1], u_hat[base+2], u_hat[base+3], u_hat[base+4]]
        Hb   = leaf_hess(ublk, prob.y1[i], prob.y2[i],
                          eta1_v[i], eta2_v[i], etas1_v[i], etas2_v[i], etar_v[i])
        # H_mean2x2 = Hb[1:2, 1:2]
        # H_u_bmu rows: base+1 (axis1) and base+2 (axis2)
        # H_u_bmu cols: 1..k1 (mu1) and k1+1..k1+k2 (mu2)
        for c in 1:k1
            H_u_bmu[base+1, c]    += Hb[1,1] * prob.X1[i, c]   # axis1, mu1
            H_u_bmu[base+2, c]    += Hb[2,1] * prob.X1[i, c]   # axis2, mu1 (cross)
        end
        for c in 1:k2
            H_u_bmu[base+1, k1+c] += Hb[1,2] * prob.X2[i, c]   # axis1, mu2 (cross)
            H_u_bmu[base+2, k1+c] += Hb[2,2] * prob.X2[i, c]   # axis2, mu2
        end
        # H_bmu_bmu contribution from leaf i: X_mu[i,:]' * H_mean2x2 * X_mu[i,:]
        # where X_mu[i,:] = [X1[i,:]; X2[i,:]] viewed as block-diagonal
        xi1 = prob.X1[i, :]; xi2 = prob.X2[i, :]
        for r in 1:k1, c in 1:k1
            H_bmu_bmu[r, c] += Hb[1,1] * xi1[r] * xi1[c]
        end
        for r in 1:k1, c in 1:k2
            H_bmu_bmu[r, k1+c] += Hb[1,2] * xi1[r] * xi2[c]
            H_bmu_bmu[k1+c, r] += Hb[2,1] * xi2[c] * xi1[r]
        end
        for r in 1:k2, c in 1:k2
            H_bmu_bmu[k1+r, k1+c] += Hb[2,2] * xi2[r] * xi2[c]
        end
    end

    # Schur complement: S = H_bmu_bmu - H_bmu_u * H_uu^{-1} * H_u_bmu
    # = H_bmu_bmu - H_u_bmu' * (H_uu^{-1} * H_u_bmu)
    C   = Matrix{Float64}(undef, nu, nbmu)
    for j in 1:nbmu
        C[:, j] = ch_H \ H_u_bmu[:, j]
    end
    S     = H_bmu_bmu - H_u_bmu' * C
    S_sym = Symmetric((S + S') / 2)
    ch_S  = cholesky(S_sym; check=false)
    if !issuccess(ch_S)
        # S non-PD: mode/beta_mu not jointly converged, or phi outside valid region.
        # Return -Inf so the optimizer avoids this point (barrier).
        return -Inf, u_hat, ch_H, beta_full, P
    end
    ld_S  = logdet(ch_S)

    return ml_ll - 0.5*ld_S, u_hat, ch_H, beta_full, P
end

# ---------------------------------------------------------------------------
# REML optimizer: LBFGS over phi = (beta_s1, beta_s2, beta_rho, lc).
# Gradient: central finite differences (phi is low-dimensional: 1+1+1+10=13).
# ---------------------------------------------------------------------------

"""
    fit_q4_reml(prob, Q_cond; beta0, Lambda0, [phi0], g_tol, ...) -> NamedTuple

Fit REML objective over phi = (beta_s, lc). beta_mu profiled out internally.

Returns NamedTuple: (phi, beta, Lambda, reml_loglik, ml_loglik, converged,
                     iterations, g_residual, f_calls, u_hat)
"""
function fit_q4_reml(prob::AugProblem, Q_cond::SparseMatrixCSC;
                     phi0=nothing, beta0=nothing, Lambda0=nothing,
                     g_tol::Float64=1e-3, iterations::Int=200,
                     n_newton::Int=40, h_fd::Float64=1e-5,
                     # `lc_zero`: same block-diagonal Σ_a constraint as the ML path —
                     # log-Cholesky indices (1..10) pinned to 0. Here they map into
                     # the phi vector (β_μ profiled out), at offset (ks1+ks2+kr).
                     lc_zero::AbstractVector{<:Integer} = Int[],
                     verbose::Bool=false)
    ks1, ks2, kr = phi_widths(prob)
    o_lc = ks1 + ks2 + kr                # lc block starts here in phi
    lc_zero_idx = sort(unique(Int.(lc_zero)))
    all(1 .<= lc_zero_idx .<= 10) ||
        error("lc_zero indices must be in 1:10 (got $lc_zero_idx)")
    phi_zero = o_lc .+ lc_zero_idx       # absolute phi positions pinned to 0
    if phi0 === nothing
        beta0   === nothing && error("supply phi0 or (beta0, Lambda0)")
        Lambda0 === nothing && (Lambda0 = Matrix(0.3I(4)))
        # Warm-start from the ML optimum: at phi_ML the Schur complement S is
        # PD (the joint mode is well-defined), which stabilises the FD gradient.
        # The ML warm start honours the SAME lc_zero so the warm Λ is already
        # block-diagonal — phi0 lands on the constrained subspace.
        r_ml_ws = fit_q4_sparse_tmb(prob, Q_cond;
                                     β0=beta0, Λ0=Matrix(Lambda0),
                                     g_tol=max(g_tol*5, 1e-2),
                                     iterations=min(iterations, 100),
                                     n_newton=n_newton, lc_zero=lc_zero_idx)
        phi0 = pack_phi(prob,
                        (s1=r_ml_ws.β.s1, s2=r_ml_ws.β.s2, rho=r_ml_ws.β.rho),
                        r_ml_ws.Λ)
    end
    phi0 = copy(Vector{Float64}(phi0)); phi0[phi_zero] .= 0.0

    u_cache  = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    bmu_cache = Ref{Union{Nothing,NamedTuple}}(nothing)
    eval_cnt = Ref(0)
    nobs     = length(prob.leaf_node)
    nph      = length(phi0)

    # Cache-updating main evaluation (for the line-search objective).
    function neg_reml(phiv)
        eval_cnt[] += 1
        local rv, uv, _, bv, _
        try
            rv, uv, _, bv, _ = reml_ll_and_mode(prob, Q_cond, Vector{Float64}(phiv);
                                                  u0=u_cache[], bmu0=bmu_cache[],
                                                  n_newton=n_newton)
        catch e
            (e isa DomainError || e isa LinearAlgebra.PosDefException ||
             e isa LinearAlgebra.SingularException) || rethrow(e)
            return Inf
        end
        isfinite(rv) || return Inf
        u_cache[]   = uv
        bmu_cache[] = (mu1=bv.mu1, mu2=bv.mu2)
        return -rv / nobs
    end

    # Finite-difference gradient with robust barrier handling.
    # h_fd_inner is slightly larger than the default to avoid hitting the
    # non-PD S barrier at tiny perturbations.
    h_inner = max(h_fd, 5e-4)

    fg! = function (F, G, phiv)
        pv = Vector{Float64}(phiv)
        f  = neg_reml(pv)    # updates cache
        if G !== nothing
            # Use the WARM start from the current cached state for FD evaluations.
            # h_inner is large enough to avoid the S non-PD barrier near the mode.
            u_snap   = u_cache[]
            bmu_snap = bmu_cache[]
            for k in 1:nph
                pp = copy(pv); pp[k] += h_inner
                pm = copy(pv); pm[k] -= h_inner
                local fp, fm
                try
                    rv_p, _, _, _, _ = reml_ll_and_mode(prob, Q_cond,
                        pp; u0=u_snap, bmu0=bmu_snap, n_newton=n_newton)
                    fp = isfinite(rv_p) ? -rv_p/nobs : Inf
                catch; fp = Inf; end
                try
                    rv_m, _, _, _, _ = reml_ll_and_mode(prob, Q_cond,
                        pm; u0=u_snap, bmu0=bmu_snap, n_newton=n_newton)
                    fm = isfinite(rv_m) ? -rv_m/nobs : Inf
                catch; fm = Inf; end

                if isfinite(fp) && isfinite(fm)
                    G[k] = (fp - fm) / (2h_inner)
                elseif isfinite(fp) && !isfinite(fm)
                    G[k] = (fp - f) / h_inner
                elseif !isfinite(fp) && isfinite(fm)
                    G[k] = (f - fm) / h_inner
                else
                    G[k] = 0.0
                end
            end
            # Pin the constrained lc directions (block-diagonal Σ_a): zero their
            # gradient so LBFGS never steps off the constrained subspace.
            isempty(phi_zero) || (G[phi_zero] .= 0.0)
        end
        return f
    end

    # REML optimization via LBFGS starting from phi0.
    # The REML landscape is well-behaved NEAR the ML optimum (S is PD there).
    # We use BackTracking with a line search that rejects Inf evaluations.
    od  = Optim.NLSolversBase.only_fg!(fg!)
    res = Optim.optimize(
        od, Vector{Float64}(phi0),
        LBFGS(m=5,
              alphaguess=Optim.LineSearches.InitialStatic(scaled=true),
              linesearch=Optim.LineSearches.BackTracking(order=3)),
        Optim.Options(g_tol=g_tol, f_reltol=1e-5, successive_f_tol=10,
                      iterations=iterations, show_trace=verbose, show_every=1),
    )

    phi_hat    = Optim.minimizer(res)
    bs_hat, lc_hat = unpack_phi(prob, phi_hat)
    Lam_hat    = lc_to_Λ(lc_hat)

    rhat, uhat, ch_H, bhat, P_hat = reml_ll_and_mode(
        prob, Q_cond, phi_hat; u0=u_cache[], bmu0=bmu_cache[], n_newton=n_newton)
    # The warm-cached u0/bmu0 are the last line-search state, which need not sit at
    # the JOINT (u, β_μ) mode for phi_hat. If that lands on the non-PD Schur barrier
    # (S not PD ⇒ rhat = -Inf), re-evaluate COLD so the alternating E-step / β_μ
    # Newton re-converges the joint mode at phi_hat (mirrors the Gate-B cold check).
    if !isfinite(rhat)
        rhat, uhat, ch_H, bhat, P_hat = reml_ll_and_mode(
            prob, Q_cond, phi_hat; n_newton=n_newton)
    end
    mlhat = laplace_ll(prob, P_hat, bhat, uhat, ch_H)

    g_resid_val = try; Optim.g_residual(res); catch; NaN; end

    return (phi        = phi_hat,
            beta       = bhat,
            Lambda     = Lam_hat,
            reml_loglik = rhat,
            ml_loglik   = mlhat,
            converged  = Optim.converged(res),
            iterations = Optim.iterations(res),
            g_residual = g_resid_val,
            f_calls    = eval_cnt[],
            u_hat      = uhat)
end
