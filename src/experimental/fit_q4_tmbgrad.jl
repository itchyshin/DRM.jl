# fit_q4_tmbgrad.jl — q=4 PLSM (Model 5, Nakagawa et al. 2025) direct Laplace
# marginal with a TMB-style "cheap" analytic outer gradient.
#
# The slow part of fit_q4_julia.jl was the OUTER gradient (finite differences:
# ~dim(theta)+1 marginal evals per gradient, each marginal eval doing a full
# inner Newton + 4p×4p Hessian). This file replaces that with TMB's default
# "cheap" gradient: freeze the inner mode u_hat, then take a single-level
# ForwardDiff over theta of
#     f(theta) = nll_joint(u_hat_FROZEN, theta) + 0.5*logdet(H_uu(u_hat_FROZEN, theta))
# This drops the implicit dependence of u_hat and H on theta (the 3rd-derivative
# term). The envelope theorem makes the u_hat term's gradient correct to first
# order (∂nll_joint/∂u = 0 at the mode); the line search on the TRUE marginal
# NLL guarantees descent regardless. No nested AD through the Newton solve.
#
# REUSES fit_q4_julia.jl: chol_offdiag_to_R, build_Lambda_phy, nll_joint,
# find_u_hat, build_initial_theta, unpack_theta.
#
# Run (functions only; main guarded):
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. fit_q4_tmbgrad.jl

using ForwardDiff
using LinearAlgebra
using Optim
using Statistics

# Pull in the validated joint NLL / Newton / pack-unpack helpers.
include(joinpath(@__DIR__, "..", "fit_q4_julia.jl"))

# -----------------------------------------------------------------------------
# Per-species data Hessian at FROZEN u_block, as a function of theta.
# -----------------------------------------------------------------------------

"""
    species_data_nll(u_block, eta_mu1_r, eta_mu2_r, eta_s1_r, eta_s2_r, rho_r,
                     y1_r, y2_r)

Bivariate-Gaussian data NLL for ONE observation as a function of that species'
4-vector of random effects u_block = (u_mu1, u_mu2, u_logσ1, u_logσ2). The η's
and ρ are passed in (they carry the theta-dependence). Mirrors the per-row data
term inside `nll_joint` exactly (including the +log(2π) per-obs constant, which
is constant in u_block and theta and so does not affect derivatives, but is kept
for a faithful value).
"""
function species_data_nll(u_block::AbstractVector{T},
                          eta_mu1_r, eta_mu2_r, eta_s1_r, eta_s2_r, rho_r,
                          y1_r, y2_r) where {T}
    mu1 = eta_mu1_r + u_block[1]
    mu2 = eta_mu2_r + u_block[2]
    sigma1 = exp(eta_s1_r + u_block[3])
    sigma2 = exp(eta_s2_r + u_block[4])
    e1 = y1_r - mu1
    e2 = y2_r - mu2
    omr2 = 1 - rho_r^2
    quad = (e1^2 / sigma1^2 - 2 * rho_r * e1 * e2 / (sigma1 * sigma2) +
            e2^2 / sigma2^2) / omr2
    logdet = 2 * (log(sigma1) + log(sigma2)) + log(omr2)
    return 0.5 * (logdet + quad) + log(2π)
end

# -----------------------------------------------------------------------------
# The frozen-mode objective f(theta): nll_joint(u_hat, theta) + 0.5 logdet H_uu
# -----------------------------------------------------------------------------

"""
    frozen_objective(theta, u_hat, y1, y2, X_*, Sigma_phy_inv, logdet_Sigma_phy,
                     species_idx)

Returns nll_joint(u_hat, theta) + 0.5 * logdet(H_uu(u_hat, theta)) with u_hat
held CONSTANT. ForwardDiff-able in theta. H_uu is built with plain dense ops:

  H_uu(theta) = kron(Sigma_phy_inv, Lambda_inv(theta))            # prior precision
              + blockdiag_j( d²(data_nll_j)/du_block² )           # data curvature

The prior-precision Hessian is exact (the prior quad form is exactly quadratic
in u with Hessian kron(Σ⁻¹, Λ⁻¹) under the column-major u_flat ↔ vec(U) layout
that nll_joint uses). The per-species 4×4 data Hessians are obtained by a
single-block ForwardDiff.hessian of `species_data_nll` at the frozen u_block.
This 4-dim inner Hessian, nested inside the outer 17-dim gradient, is cheap and
well-defined — it does NOT differentiate through the inner Newton.
"""
function frozen_objective(theta::AbstractVector{T},
                          u_hat::AbstractVector{Float64},
                          y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                          Sigma_phy_inv::AbstractMatrix{Float64},
                          logdet_Sigma_phy::Float64,
                          species_idx::AbstractVector{Int}) where {T}
    n = length(y1)
    p = size(Sigma_phy_inv, 1)

    # --- joint NLL at the frozen mode (theta-dependent) ---------------------
    nll_at_hat = nll_joint(theta, u_hat, y1, y2, X_mu1, X_mu2, X_sigma1,
                           X_sigma2, X_rho12, Sigma_phy_inv, logdet_Sigma_phy,
                           species_idx)

    # --- rebuild the pieces of H_uu as functions of theta -------------------
    # Unpack theta with the SAME layout as nll_joint.
    p_mu1    = size(X_mu1, 2)
    p_mu2    = size(X_mu2, 2)
    p_sigma1 = size(X_sigma1, 2)
    p_sigma2 = size(X_sigma2, 2)
    p_rho12  = size(X_rho12, 2)
    i = 0
    beta_mu1    = theta[i+1:i+p_mu1];    i += p_mu1
    beta_mu2    = theta[i+1:i+p_mu2];    i += p_mu2
    beta_sigma1 = theta[i+1:i+p_sigma1]; i += p_sigma1
    beta_sigma2 = theta[i+1:i+p_sigma2]; i += p_sigma2
    beta_rho12  = theta[i+1:i+p_rho12];  i += p_rho12
    log_sd_phy   = theta[i+1:i+4];        i += 4
    chol_offdiag = theta[i+1:i+6];        i += 6

    # Prior precision Lambda_inv (4×4), theta-dependent.
    Lambda_phy = build_Lambda_phy(log_sd_phy, chol_offdiag)
    Lambda_inv = inv(Lambda_phy)

    # Linear predictors (theta-dependent) for the data Hessians.
    eta_mu1 = X_mu1 * beta_mu1
    eta_mu2 = X_mu2 * beta_mu2
    eta_s1  = X_sigma1 * beta_sigma1
    eta_s2  = X_sigma2 * beta_sigma2
    eta_rho = X_rho12 * beta_rho12

    U = reshape(u_hat, 4, p)   # frozen mode, Float64

    # Assemble dense H_uu (4p × 4p). Prior precision = kron(Sigma_phy_inv, Lambda_inv).
    H = kron(Sigma_phy_inv, Lambda_inv)   # promotes to T via Lambda_inv

    # Add per-species data Hessian blocks on the diagonal. Each species' obs
    # contributes a 4×4 block at rows/cols (s-1)*4+1 : (s-1)*4+4.
    for r in 1:n
        s = species_idx[r]
        u_block = Vector{Float64}(U[:, s])      # Float64 frozen 4-vector
        rho_r = 0.99999999 * tanh(eta_rho[r])   # theta-dependent
        # data NLL for this obs as a function of the 4-vector u_block, with the
        # theta-carrying η's / ρ closed over. ForwardDiff.hessian over 4 dims.
        g = ub -> species_data_nll(ub, eta_mu1[r], eta_mu2[r], eta_s1[r],
                                   eta_s2[r], rho_r, y1[r], y2[r])
        Hblk = ForwardDiff.hessian(g, u_block)  # 4×4, eltype T
        base = (s - 1) * 4
        @inbounds for a in 1:4, b in 1:4
            H[base + a, base + b] += Hblk[a, b]
        end
    end

    # logdet(H) with PD-safe fallback: if non-PD, return a large finite value so
    # the line search rejects this step (TMB does the equivalent).
    Hs = Symmetric((H + H') / 2)
    chol = cholesky(Hs; check = false)
    if !issuccess(chol)
        return nll_at_hat + convert(T, 1e10)
    end
    logdet_H = 2 * sum(log.(diag(chol.U)))
    return nll_at_hat + 0.5 * logdet_H
end

# -----------------------------------------------------------------------------
# Dense joint Hessian H_uu(u, theta) as an explicit function of u.
# -----------------------------------------------------------------------------

"""
    build_H_uu(u_flat, theta, y1, y2, X_*, Sigma_phy_inv, species_idx)

Assemble the dense 4p×4p Hessian ∂²(nll_joint)/∂u² at the supplied `u_flat`,
holding `theta` fixed. Structure (identical to `frozen_objective`):

  H_uu = kron(Sigma_phy_inv, Lambda_inv(theta))        # prior precision (const in u)
       + blockdiag_s( ∂²data_nll_s/∂u_block² )          # per-species 4×4 data curvature

The per-species data block is a 4-dim ForwardDiff.hessian of `species_data_nll`,
which is well-defined and AD-friendly in BOTH arguments. Making `u_flat` a Dual
vector therefore yields ∂H/∂u (used by step 3); passing Float64 yields the plain
numeric Hessian (used by the linear solve in step 4). Element type follows
`promote_type(eltype(u_flat), eltype(theta))`.
"""
function build_H_uu(u_flat::AbstractVector{Tu},
                    theta::AbstractVector{Tt},
                    y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                    Sigma_phy_inv::AbstractMatrix{Float64},
                    species_idx::AbstractVector{Int}) where {Tu, Tt}
    T = promote_type(Tu, Tt)
    n = length(y1)
    p = size(Sigma_phy_inv, 1)

    # Unpack theta (same layout as nll_joint).
    p_mu1    = size(X_mu1, 2)
    p_mu2    = size(X_mu2, 2)
    p_sigma1 = size(X_sigma1, 2)
    p_sigma2 = size(X_sigma2, 2)
    p_rho12  = size(X_rho12, 2)
    i = 0
    beta_mu1    = theta[i+1:i+p_mu1];    i += p_mu1
    beta_mu2    = theta[i+1:i+p_mu2];    i += p_mu2
    beta_sigma1 = theta[i+1:i+p_sigma1]; i += p_sigma1
    beta_sigma2 = theta[i+1:i+p_sigma2]; i += p_sigma2
    beta_rho12  = theta[i+1:i+p_rho12];  i += p_rho12
    log_sd_phy   = theta[i+1:i+4];        i += 4
    chol_offdiag = theta[i+1:i+6];        i += 6

    Lambda_phy = build_Lambda_phy(log_sd_phy, chol_offdiag)
    Lambda_inv = inv(Lambda_phy)

    eta_mu1 = X_mu1 * beta_mu1
    eta_mu2 = X_mu2 * beta_mu2
    eta_s1  = X_sigma1 * beta_sigma1
    eta_s2  = X_sigma2 * beta_sigma2
    eta_rho = X_rho12 * beta_rho12

    U = reshape(u_flat, 4, p)

    # Prior precision = kron(Sigma_phy_inv, Lambda_inv); promote to T.
    H = Matrix{T}(kron(Sigma_phy_inv, Lambda_inv))

    for r in 1:n
        s = species_idx[r]
        u_block = U[:, s]                       # eltype Tu (Dual or Float64)
        rho_r = 0.99999999 * tanh(eta_rho[r])
        g = ub -> species_data_nll(ub, eta_mu1[r], eta_mu2[r], eta_s1[r],
                                   eta_s2[r], rho_r, y1[r], y2[r])
        Hblk = ForwardDiff.hessian(g, u_block)  # 4×4, eltype promote(Tu, Tt)
        base = (s - 1) * 4
        @inbounds for a in 1:4, b in 1:4
            H[base + a, base + b] += Hblk[a, b]
        end
    end
    return H
end

# -----------------------------------------------------------------------------
# marginal_and_grad: inner Newton (frozen) + single-level AD of frozen_objective
# -----------------------------------------------------------------------------

"""
    marginal_and_grad(theta, y1, y2, X_*, Sigma_phy_inv, logdet_Sigma_phy,
                      species_idx; n_inner)

Returns (nll, grad) where
   nll  = frozen_objective(theta, u_hat) - 0.5*(4p)*log(2π)   [= true Laplace NLL]
   grad = ForwardDiff.gradient(th -> frozen_objective(th, u_hat), theta)

u_hat is computed by the inner Newton at Float64 theta and FROZEN (passed as a
constant). The gradient is therefore single-level AD over the 17-dim theta of a
function that does NO inner solve — cheap.
"""
function marginal_and_grad(theta::Vector{Float64},
                           y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                           Sigma_phy_inv, logdet_Sigma_phy, species_idx;
                           n_inner::Int = 20)
    p = size(Sigma_phy_inv, 1)
    # Inner Newton at Float64 theta; NOT differentiated.
    u_hat = find_u_hat(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                       Sigma_phy_inv, logdet_Sigma_phy, species_idx;
                       n_iter = n_inner)
    u_hat = Vector{Float64}(u_hat)   # freeze as plain Float64

    f = th -> frozen_objective(th, u_hat, y1, y2, X_mu1, X_mu2, X_sigma1,
                               X_sigma2, X_rho12, Sigma_phy_inv,
                               logdet_Sigma_phy, species_idx)

    const_term = 0.5 * (4 * p) * log(2π)
    nll = f(theta) - const_term
    grad = ForwardDiff.gradient(f, theta)
    return nll, grad
end

# -----------------------------------------------------------------------------
# marginal_and_exact_grad: cheap gradient + implicit (dû/dθ)'·v correction.
# -----------------------------------------------------------------------------

"""
    marginal_and_exact_grad(theta, y1, y2, X_*, Sigma_phy_inv, logdet_Sigma_phy,
                            species_idx; n_inner)

Returns (nll, exact_grad) where `nll` is the TRUE Laplace marginal NLL and
`exact_grad` is its EXACT gradient, including the implicit term from dû/dθ.

The Laplace objective is L(θ) = f(û(θ),θ) + 0.5·logdet H(û(θ),θ) − 0.5·4p·log2π,
with f = nll_joint and H = ∂²f/∂u². Because ∂f/∂u|_û = 0 (û is the inner mode),
differentiating L gives

  dL/dθ = ∇_θ[ f + 0.5 logdet H ]|_{û frozen}            (the "cheap" gradient)
        + (dû/dθ)' · ( 0.5 ∇_u logdet H )|_{û}            (the implicit term)

and dû/dθ = −H⁻¹ (∂²f/∂u∂θ). Writing v = 0.5 ∇_u logdet H and w = H⁻¹ v, the
implicit term is −(∂²f/∂u∂θ)' w = −∇_θ[ (∇_u f)' w ] (û, w frozen). All AD calls
are single-level (over u with θ fixed, or over θ with û/w fixed) — no
differentiation through the Newton iterations and no third-derivative tensor.
"""
function marginal_and_exact_grad(theta::Vector{Float64},
                                 y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                                 Sigma_phy_inv, logdet_Sigma_phy, species_idx;
                                 n_inner::Int = 20)
    p = size(Sigma_phy_inv, 1)

    # Step 1: inner Newton at Float64 theta; FROZEN.
    u_hat = find_u_hat(theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                       Sigma_phy_inv, logdet_Sigma_phy, species_idx;
                       n_iter = n_inner)
    u_hat = Vector{Float64}(u_hat)

    # Step 2: cheap gradient = ∇_θ[ f(û,θ) + 0.5 logdet H(û,θ) ], û frozen.
    f_frozen = th -> frozen_objective(th, u_hat, y1, y2, X_mu1, X_mu2, X_sigma1,
                                      X_sigma2, X_rho12, Sigma_phy_inv,
                                      logdet_Sigma_phy, species_idx)
    const_term = 0.5 * (4 * p) * log(2π)
    nll = f_frozen(theta) - const_term
    cheap = ForwardDiff.gradient(f_frozen, theta)

    # H = ∂²f/∂u² at û (Float64). At the inner mode this is PD; away from it
    # (pathological line-search trials) it can be indefinite. Factor once and
    # reuse the factor for the step-4 solve. If non-PD even after a tiny ridge,
    # skip the implicit correction (return the cheap gradient with the true
    # finite NLL value; the line search on the true NLL still rejects the step).
    H = build_H_uu(u_hat, theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                   X_rho12, Sigma_phy_inv, species_idx)
    Hs = Symmetric((H + H') / 2)
    cholH = cholesky(Hs; check = false)
    if !issuccess(cholH)
        # H not cleanly PD (a line-search excursion to a bad theta). Skip the
        # implicit correction and return the cheap gradient: the step-3 logdet
        # rebuild would otherwise hit a non-PD primal and throw. `nll` here is
        # already the large value frozen_objective returns for non-PD H, so the
        # BackTracking line search rejects this step regardless of the gradient.
        return nll, cheap
    end

    # Steps 3-5 compute the implicit-term correction. When H is only *barely* PD
    # (a near-singular line-search excursion), the Dual-arithmetic rebuild at
    # step 3 can hit a roundoff-negative pivot and throw even though `cholH`
    # (check=false) succeeded above. Wrap the whole correction in try/catch:
    # on ANY failure fall back to the cheap gradient — the large/true NLL value
    # makes the BackTracking line search reject the step regardless. Near the
    # optimum H is comfortably PD, so the exact gradient is used and LBFGS
    # converges fast.
    local correction
    try
        # Step 3: v = 0.5 ∇_u[ logdet H(u,θ) ]|_{u=û}  (ForwardDiff over u, θ fixed).
        logdetH_of_u = uu -> begin
            Hm = build_H_uu(uu, theta, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                            X_rho12, Sigma_phy_inv, species_idx)
            Hms = Symmetric((Hm + Hm') / 2)
            ch = cholesky(Hms; check = false)
            issuccess(ch) || error("non-PD H in logdet rebuild")
            2 * sum(log.(diag(ch.U)))
        end
        v = 0.5 .* ForwardDiff.gradient(logdetH_of_u, u_hat)

        # Step 4: w = H⁻¹ v, reusing the Cholesky factor of H.
        w = cholH \ v

        # Step 5: correction = −∇_θ[ dot(∇_u f(u=û, θ), w) ]  (û and w frozen).
        scalar_of_theta = th -> begin
            f_u = uu -> nll_joint(th, uu, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                  X_rho12, Sigma_phy_inv, logdet_Sigma_phy, species_idx)
            gu = ForwardDiff.gradient(f_u, u_hat)   # ∇_u f at frozen û, θ-dependent
            dot(gu, w)
        end
        correction = -ForwardDiff.gradient(scalar_of_theta, theta)
    catch
        return nll, cheap
    end

    # Step 6.
    exact_grad = cheap .+ correction
    return nll, exact_grad
end

# -----------------------------------------------------------------------------
# Fit driver: LBFGS with the analytic gradient.
# -----------------------------------------------------------------------------

function fit_q4_tmb(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                    Sigma_phy, species_idx;
                    theta0 = nothing, g_tol::Float64 = 1e-3,
                    iterations::Int = 200, n_inner::Int = 20,
                    show_trace::Bool = true)
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    if theta0 === nothing
        theta0 = build_initial_theta(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                     X_rho12)
    end

    fg! = (F, G, th) -> begin
        nll, g = marginal_and_grad(th, y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                   X_rho12, Sigma_phy_inv, logdet_Sigma_phy,
                                   species_idx; n_inner = n_inner)
        if G !== nothing
            copyto!(G, g)
        end
        return nll
    end
    od = Optim.only_fg!(fg!)

    res = Optim.optimize(
        od, theta0,
        LBFGS(linesearch = Optim.LineSearches.BackTracking()),
        Optim.Options(g_tol = g_tol, iterations = iterations,
                      show_trace = show_trace, show_every = 1),
    )

    theta_hat = Optim.minimizer(res)
    return (
        theta = theta_hat,
        nll = Optim.minimum(res),
        logLik = -Optim.minimum(res),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
        g_residual = Optim.g_residual(res),
        f_calls = Optim.f_calls(res),
        g_calls = Optim.g_calls(res),
    )
end

# -----------------------------------------------------------------------------
# Fit driver using the EXACT gradient (cheap + implicit dû/dθ correction).
# -----------------------------------------------------------------------------

function fit_q4_tmb_exact(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12,
                          Sigma_phy, species_idx;
                          theta0 = nothing, g_tol::Float64 = 1e-3,
                          iterations::Int = 200, n_inner::Int = 20,
                          show_trace::Bool = true)
    Sigma_phy_inv = inv(Sigma_phy)
    logdet_Sigma_phy = logdet(Symmetric(Sigma_phy))

    if theta0 === nothing
        theta0 = build_initial_theta(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2,
                                     X_rho12)
    end

    fg! = (F, G, th) -> begin
        nll, g = marginal_and_exact_grad(th, y1, y2, X_mu1, X_mu2, X_sigma1,
                                         X_sigma2, X_rho12, Sigma_phy_inv,
                                         logdet_Sigma_phy, species_idx;
                                         n_inner = n_inner)
        if G !== nothing
            copyto!(G, g)
        end
        return nll
    end
    # only_fg! lives in NLSolversBase (Optim's dependency), reached via the
    # Optim namespace; it is not re-exported at Optim's top level.
    od = Optim.NLSolversBase.only_fg!(fg!)

    res = Optim.optimize(
        od, theta0,
        LBFGS(linesearch = Optim.LineSearches.BackTracking()),
        Optim.Options(g_tol = g_tol, iterations = iterations,
                      show_trace = show_trace, show_every = 1),
    )

    theta_hat = Optim.minimizer(res)
    return (
        theta = theta_hat,
        nll = Optim.minimum(res),
        logLik = -Optim.minimum(res),
        converged = Optim.converged(res),
        iterations = Optim.iterations(res),
        g_residual = Optim.g_residual(res),
        f_calls = Optim.f_calls(res),
        g_calls = Optim.g_calls(res),
    )
end

# A no-op main so running the file directly just confirms it loads.
if abspath(PROGRAM_FILE) == @__FILE__
    println("fit_q4_tmbgrad.jl loaded: marginal_and_grad, marginal_and_exact_grad, " *
            "fit_q4_tmb, fit_q4_tmb_exact available.")
end
