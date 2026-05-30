# q4_em_dense.jl — Laplace-EM for the q=4 phylogenetic location-scale model
# (Model 5, Nakagawa et al. 2025 MEE), DENSE Σ_phy⁻¹ version.
#
# This is the correctness-oracle + moderate-p benchmark implementation.
# It avoids nested AD entirely (the EM never differentiates the marginal):
#   E-step: one Newton solve for the mode û + posterior covariance H_uu⁻¹.
#   M-step: closed-form GLS for β_mu, closed-form 4×4 Λ_phy update,
#           tiny Newton for β_sigma / β_rho given the known û offsets.
#
# Latent ordering: effect-within-species, u = [u1_s1,u2_s1,u3_s1,u4_s1,
# u1_s2,...]. Then the data Hessian is block-diagonal (4×4 per species)
# and the prior precision is P = kron(Σ_phy⁻¹, Λ_phy⁻¹).
#
# axes: 1=mu1, 2=mu2, 3=log sigma1, 4=log sigma2.

using LinearAlgebra, ForwardDiff, Statistics

const RHO_GUARD = 0.99999999

# PD-safe linear solve: escalate a ridge until Cholesky succeeds. Used by
# the inner Newton (E-step) and the small scale/rho M-step Newton, both of
# which can transiently hit an indefinite Hessian far from the optimum.
function pd_solve(Hmat::AbstractMatrix, gvec::AbstractVector)
    for λ in (0.0, 1e-8, 1e-6, 1e-4, 1e-2, 1.0, 1e2)
        Hr = λ == 0.0 ? Symmetric(Matrix(Hmat)) : Symmetric(Matrix(Hmat) + λ * I)
        ch = cholesky(Hr; check = false)
        issuccess(ch) && return ch \ gvec
    end
    return gvec ./ maximum(abs.(diag(Hmat)))   # last-resort scaled gradient
end

# ---------------------------------------------------------------------------
# Per-species data negative log-likelihood, as a function of that species'
# 4 random effects u_i (4-vector). Fixed effects + design enter as scalars.
# ---------------------------------------------------------------------------
"""
    data_nll_species(u_i, y1, y2, η_mu1, η_mu2, η_s1, η_s2, η_rho)

Bivariate-Gaussian negative log-density for one species, where the linear
predictors η_* already include the fixed-effect part (Xβ). The random
effects shift them: mu1 = η_mu1 + u_i[1], log σ1 = η_s1 + u_i[3], etc.
ρ has no random effect here (rho12 ~ 1, no phylo on ρ in this model).
"""
function data_nll_species(u_i, y1, y2, η_mu1, η_mu2, η_s1, η_s2, η_rho)
    mu1 = η_mu1 + u_i[1]
    mu2 = η_mu2 + u_i[2]
    s1  = exp(η_s1 + u_i[3])
    s2  = exp(η_s2 + u_i[4])
    ρ   = RHO_GUARD * tanh(η_rho)
    e1 = y1 - mu1
    e2 = y2 - mu2
    omr2 = 1 - ρ^2
    quad = (e1^2 / s1^2 - 2ρ * e1 * e2 / (s1 * s2) + e2^2 / s2^2) / omr2
    return 0.5 * (log(s1^2 * s2^2 * omr2) + quad) + log(2π)
end

# Gradient and Hessian of the per-species data nll w.r.t. u_i (4-dim).
data_grad_species(u_i, args...) =
    ForwardDiff.gradient(u -> data_nll_species(u, args...), u_i)
data_hess_species(u_i, args...) =
    ForwardDiff.hessian(u -> data_nll_species(u, args...), u_i)

# ---------------------------------------------------------------------------
# Linear predictors from fixed effects (intercept-only sigma/rho for q4_p100,
# but written to accept design matrices for generality).
# ---------------------------------------------------------------------------
struct Q4Design
    X_mu1::Matrix{Float64}
    X_mu2::Matrix{Float64}
    X_s1::Matrix{Float64}
    X_s2::Matrix{Float64}
    X_rho::Matrix{Float64}
end

struct Q4Params
    β_mu1::Vector{Float64}
    β_mu2::Vector{Float64}
    β_s1::Vector{Float64}
    β_s2::Vector{Float64}
    β_rho::Vector{Float64}
    Λ::Matrix{Float64}   # 4×4 phylo covariance
end

eta(D::Q4Design, P::Q4Params) = (
    D.X_mu1 * P.β_mu1, D.X_mu2 * P.β_mu2,
    D.X_s1 * P.β_s1, D.X_s2 * P.β_s2, D.X_rho * P.β_rho,
)

# ---------------------------------------------------------------------------
# E-step: Newton for the mode û, then posterior covariance = H_uu⁻¹.
# Prior precision P = kron(Σ_phy_inv, Λ_inv). Data Hessian is block-diagonal.
# ---------------------------------------------------------------------------
"""
    estep(y1, y2, D, params, Σ_inv; n_newton=30, tol=1e-9)

Returns (Û::4×p, Hinv::4p×4p dense posterior covariance, nll_joint at û).
"""
function estep(y1, y2, D::Q4Design, par::Q4Params, Σ_inv::Matrix{Float64};
               n_newton::Int = 30, tol::Float64 = 1e-9)
    p = length(y1)
    η1, η2, ηs1, ηs2, ηr = eta(D, par)
    Λ_inv = inv(par.Λ)
    Pprec = kron(Σ_inv, Λ_inv)          # 4p × 4p dense prior precision
    # joint nll(u) for backtracking line search
    function joint_nll(uvec)
        tot = 0.5 * dot(uvec, Pprec * uvec)
        @inbounds for i in 1:p
            idx = (4(i-1)+1):(4i)
            args = (y1[i], y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i])
            tot += data_nll_species(uvec[idx], args...)
        end
        return tot
    end
    u = zeros(4p)
    local H
    for _ in 1:n_newton
        g = Pprec * u
        H = copy(Pprec)
        @inbounds for i in 1:p
            idx = (4(i-1)+1):(4i)
            ui = collect(@view u[idx])
            args = (y1[i], y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i])
            g[idx] .+= data_grad_species(ui, args...)
            H[idx, idx] .+= data_hess_species(ui, args...)
        end
        step = pd_solve(H, g)
        # backtracking line search on the joint nll
        f0 = joint_nll(u)
        α = 1.0
        unew = u .- α .* step
        for _bt in 1:20
            (joint_nll(unew) <= f0 || α < 1e-6) && break
            α *= 0.5
            unew = u .- α .* step
        end
        u = unew
        if norm(α .* step) < tol
            break
        end
    end
    # Final Hessian at û
    H = copy(Pprec)
    @inbounds for i in 1:p
        idx = (4(i-1)+1):(4i)
        args = (y1[i], y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i])
        H[idx, idx] .+= data_hess_species(u[idx], args...)
    end
    # PD-safe inverse for the posterior covariance. Escalate the ridge until a
    # Cholesky succeeds, and ALWAYS leave Hinv assigned: if every preset level
    # fails (e.g. a wildly indefinite H far from the optimum), fall back to a
    # diagonally dominant PD surrogate so the caller never hits an undefined
    # variable. The monotonicity safety net in the driver will reject any step
    # built on such a degenerate E-step anyway.
    local Hinv
    Hinv_set = false
    for λ in (0.0, 1e-10, 1e-8, 1e-6, 1e-4, 1e-2, 1.0, 1e2)
        ch = cholesky(λ == 0.0 ? Symmetric(H) : Symmetric(H + λ * I); check = false)
        if issuccess(ch)
            Hinv = inv(ch)
            Hinv_set = true
            break
        end
    end
    if !Hinv_set
        d = abs.(diag(H))
        ridge = max(maximum(d), 1.0) + sum(abs, H)   # guaranteed diag-dominant
        Hpd = Symmetric(H + ridge * I)
        Hinv = inv(cholesky(Hpd))
    end
    Û = reshape(u, 4, p)
    return Û, Hinv, H
end

# ---------------------------------------------------------------------------
# M-step pieces
# ---------------------------------------------------------------------------
# (a) Λ_phy closed-form EM update:
#   Λ_new = (1/p) ( Û Σ_inv Û'  +  posterior-covariance correction )
#   correction[a,b] = Σ_{i,j} Σ_inv[i,j] * Cov(u_{a,i}, u_{b,j} | y)
#   where Cov block (i,j) is Hinv[(i-1)*4+a, (j-1)*4+b].
function mstep_Lambda(Û::Matrix{Float64}, Hinv::Matrix{Float64}, Σ_inv::Matrix{Float64})
    p = size(Û, 2)
    base = Û * Σ_inv * Û'            # 4×4
    corr = zeros(4, 4)
    @inbounds for i in 1:p, j in 1:p
        w = Σ_inv[i, j]
        w == 0 && continue
        bi = 4(i-1); bj = 4(j-1)
        for a in 1:4, b in 1:4
            corr[a, b] += w * Hinv[bi+a, bj+b]
        end
    end
    Λ = (base + corr) ./ p
    return Symmetric((Λ + Λ') / 2) |> Matrix
end

# (b) JOINT conditional M-step over ALL fixed effects β.
#
#   The prior p(u | Λ, Σ) does not depend on β, so the joint negative
#   log-likelihood splits as
#       nll_joint(β, u) = data_nll(β; u) + prior_nll(u; Λ).
#   With û held FIXED, minimizing nll_joint over β is exactly minimizing the
#   summed per-species data nll over β. We do this with a few damped Newton
#   steps (ForwardDiff over the stacked 7-vector β = [β_mu1; β_mu2; β_s1; β_s2;
#   β_rho]). Crucially β enters mu = Xβ + û and log σ = Xβ + û with û frozen and
#   ρ = RHO_GUARD·tanh(Xβ_rho); the FULL bivariate data nll (including the ρ
#   cross-term) is minimized. No offset/regression double-counting.
function mstep_beta_joint(y1, y2, D::Q4Design, par::Q4Params, Û::Matrix{Float64};
                          n_newton::Int = 25, tol::Float64 = 1e-10)
    p = length(y1)
    nm1 = length(par.β_mu1); nm2 = length(par.β_mu2)
    ns1 = size(D.X_s1, 2); ns2 = size(D.X_s2, 2); nr = size(D.X_rho, 2)
    o1 = 0; o2 = o1 + nm1; o3 = o2 + nm2; o4 = o3 + ns1; o5 = o4 + ns2  # offsets

    # summed per-species data nll as a function of the full β vector, û FROZEN
    function nll_beta(β)
        bm1 = β[o1+1:o1+nm1]; bm2 = β[o2+1:o2+nm2]
        bs1 = β[o3+1:o3+ns1]; bs2 = β[o4+1:o4+ns2]; brho = β[o5+1:o5+nr]
        tot = zero(eltype(β))
        @inbounds for i in 1:p
            η_mu1 = D.X_mu1[i, :]' * bm1
            η_mu2 = D.X_mu2[i, :]' * bm2
            η_s1  = D.X_s1[i, :]'  * bs1
            η_s2  = D.X_s2[i, :]'  * bs2
            η_rho = D.X_rho[i, :]' * brho
            # u_i frozen; reuse the canonical per-species data nll
            tot += data_nll_species((Û[1, i], Û[2, i], Û[3, i], Û[4, i]),
                                    y1[i], y2[i], η_mu1, η_mu2, η_s1, η_s2, η_rho)
        end
        return tot
    end

    β = vcat(par.β_mu1, par.β_mu2, par.β_s1, par.β_s2, par.β_rho)
    for _ in 1:n_newton
        g = ForwardDiff.gradient(nll_beta, β)
        H = ForwardDiff.hessian(nll_beta, β)
        step = pd_solve(H, g)
        # damped step: halve if the conditional data nll would rise
        f0 = nll_beta(β); α = 1.0; βnew = β .- α .* step
        for _bt in 1:25
            (nll_beta(βnew) <= f0 || α < 1e-8) && break
            α *= 0.5; βnew = β .- α .* step
        end
        β = βnew
        norm(α .* step) < tol && break
    end
    return (β[o1+1:o1+nm1], β[o2+1:o2+nm2],
            β[o3+1:o3+ns1], β[o4+1:o4+ns2], β[o5+1:o5+nr])
end

# ---------------------------------------------------------------------------
# Laplace marginal log-likelihood at the current params (for monitoring +
# final reporting). L = -[ f(û) ] + 0.5 * 4p*log(2π) - 0.5*logdet(H_uu)
#   where f(û) = data_nll(û) + 0.5 û'Pû + 0.5 logdet(P-as-cov-const)...
# We compute the standard Laplace: log p(y) ≈ log p(y,û) - 0.5 log det(H/2π)
#   = -data_nll(û) + log N(û; 0, prior) - 0.5 logdet(H) + 0.5*4p*log(2π).
# ---------------------------------------------------------------------------
function laplace_loglik(y1, y2, D::Q4Design, par::Q4Params, Σ_inv, Û, H)
    p = length(y1)
    η1, η2, ηs1, ηs2, ηr = eta(D, par)
    u = vec(Û)
    # data nll at û
    dn = 0.0
    for i in 1:p
        idx = (4(i-1)+1):(4i)
        dn += data_nll_species(u[idx], y1[i], y2[i], η1[i], η2[i], ηs1[i], ηs2[i], ηr[i])
    end
    Λ_inv = inv(par.Λ)
    Pprec = kron(Σ_inv, Λ_inv)
    # prior nll at û:  0.5 u'Pu - 0.5 logdet(P) + 0.5*4p*log(2π)
    prior_nll = 0.5 * dot(u, Pprec * u) - 0.5 * logdet(Pprec) + 0.5 * 4p * log(2π)
    joint_nll = dn + prior_nll
    # Laplace: logLik = -joint_nll + 0.5*4p*log(2π) - 0.5 logdet(H)
    return -joint_nll + 0.5 * 4p * log(2π) - 0.5 * logdet(Symmetric(H))
end

# True marginal at an ARBITRARY parameter set: run a fresh E-step, then evaluate
# the Laplace marginal there. This is the function the monotonicity safety net
# guards — it must reflect the actual objective the EM is supposed to ascend.
function marginal_ll(y1, y2, D::Q4Design, par::Q4Params, Σ_inv)
    Û, _, H = estep(y1, y2, D, par, Σ_inv)
    return laplace_loglik(y1, y2, D, par, Σ_inv, Û, H)
end

# Project a symmetric matrix onto the PD cone with a small floor on eigenvalues.
# Used when interpolating Λ during backtracking (a convex combo of two PD
# matrices is PD, but re-symmetrize + floor guards against round-off).
function pd_project(M::AbstractMatrix; floor::Float64 = 1e-8)
    S = Symmetric((M + M') / 2)
    E = eigen(S)
    λ = max.(E.values, floor)
    return Matrix(Symmetric(E.vectors * Diagonal(λ) * E.vectors'))
end

# Geometric interpolation of a full parameter set toward θ_old by factor α∈(0,1].
# Vector blocks interpolate linearly; Λ interpolates then PD-projects.
function interp_params(old::Q4Params, new::Q4Params, α::Float64)
    lin(a, b) = a .+ α .* (b .- a)
    Λα = pd_project(old.Λ .+ α .* (new.Λ .- old.Λ))
    return Q4Params(lin(old.β_mu1, new.β_mu1), lin(old.β_mu2, new.β_mu2),
                    lin(old.β_s1, new.β_s1), lin(old.β_s2, new.β_s2),
                    lin(old.β_rho, new.β_rho), Λα)
end

# ---------------------------------------------------------------------------
# Full EM driver
# ---------------------------------------------------------------------------
function fit_q4_em(y1, y2, D::Q4Design, Σ_phy::Matrix{Float64};
                   max_em::Int = 200, tol::Float64 = 1e-6, verbose::Bool = true)
    p = length(y1)
    Σ_inv = Matrix(inv(Symmetric(Σ_phy)))   # computed ONCE (tree fixed)

    # --- initial values ---
    β_mu1 = D.X_mu1 \ y1
    β_mu2 = D.X_mu2 \ y2
    r1 = y1 .- D.X_mu1 * β_mu1
    r2 = y2 .- D.X_mu2 * β_mu2
    β_s1 = zeros(size(D.X_s1, 2)); β_s1[1] = log(std(r1))
    β_s2 = zeros(size(D.X_s2, 2)); β_s2[1] = log(std(r2))
    β_rho = zeros(size(D.X_rho, 2)); β_rho[1] = atanh(clamp(cor(r1, r2), -0.9, 0.9))
    Λ = Matrix(0.3 .* I(4))            # moderate phylo SDs to start
    par = Q4Params(β_mu1, β_mu2, β_s1, β_s2, β_rho, Λ)

    # Marginal at the initial parameters (true Laplace, reusing the first E-step).
    Û, Hinv, H = estep(y1, y2, D, par, Σ_inv)
    ll_old = laplace_loglik(y1, y2, D, par, Σ_inv, Û, H)
    verbose && @info "EM init" loglik=round(ll_old; digits=4)

    # --- guarded conditional-maximization step ------------------------------
    # Given the incumbent (par_cur, ll_cur) and a proposed par_prop, recompute
    # the TRUE marginal at the proposal. If it did not increase, backtrack
    # geometrically toward par_cur until it does (or α underflows). Returns the
    # accepted params and their marginal — NEVER below ll_cur. This is the
    # monotonicity safety net, applied per CM block so a good update in one
    # block is not undone by a fighting update in another.
    function guarded(par_cur::Q4Params, ll_cur::Float64, par_prop::Q4Params)
        ll_prop = marginal_ll(y1, y2, D, par_prop, Σ_inv)
        best_par = par_prop; best_ll = ll_prop
        α = 1.0
        while best_ll < ll_cur && α > 1e-4
            α *= 0.5
            par_try = interp_params(par_cur, par_prop, α)
            ll_try = marginal_ll(y1, y2, D, par_try, Σ_inv)
            if ll_try > best_ll
                best_par = par_try; best_ll = ll_try
            end
        end
        return best_ll >= ll_cur ? (best_par, best_ll) : (par_cur, ll_cur)
    end

    ll_hist = Float64[ll_old]
    converged = false
    iters_done = 0
    for it in 1:max_em
        iters_done = it
        ll_start = ll_old

        # === ECM: update β-block, then Λ-block, each individually guarded. ===
        # (1) joint conditional update of ALL fixed effects β with û FROZEN.
        β_mu1, β_mu2, β_s1, β_s2, β_rho = mstep_beta_joint(y1, y2, D, par, Û)
        par_beta = Q4Params(β_mu1, β_mu2, β_s1, β_s2, β_rho, par.Λ)
        par, ll_old = guarded(par, ll_old, par_beta)
        # refresh the mode/posterior at the accepted β (needed for the Λ update)
        Û, Hinv, H = estep(y1, y2, D, par, Σ_inv)

        # (2) closed-form Λ update from the posterior moments of û.
        Λ = mstep_Lambda(Û, Hinv, Σ_inv)
        par_lam = Q4Params(par.β_mu1, par.β_mu2, par.β_s1, par.β_s2, par.β_rho, Λ)
        par, ll_old = guarded(par, ll_old, par_lam)
        # refresh the mode/posterior at the accepted Λ for the next iteration
        Û, Hinv, H = estep(y1, y2, D, par, Σ_inv)

        Δ = ll_old - ll_start
        push!(ll_hist, ll_old)
        if verbose && (it <= 5 || it % 10 == 0)
            @info "EM iter $it" loglik=round(ll_old; digits=4) Δ=round(Δ; digits=6)
        end
        if Δ < tol && it > 3
            verbose && @info "EM converged" iter=it loglik=round(ll_old; digits=4)
            converged = true
            break
        end
    end

    # Monotonicity assertion: the recorded marginal must be non-decreasing.
    @assert all(diff(ll_hist) .>= -1e-8) "EM marginal decreased: $(round.(ll_hist; digits=4))"

    return (par = par, Û = Û, loglik = ll_old, iters = iters_done,
            converged = converged, ll_hist = ll_hist)
end
