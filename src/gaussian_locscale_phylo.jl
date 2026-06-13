# gaussian_locscale_phylo.jl — univariate Gaussian location-scale model with
# phylogenetic random effects on BOTH axes (B1 of the σ-phylo plan).
#
# The `:gaussian_mean` leaf from rich_bivariate.jl is a full location-scale leaf:
#   nll = 0.5 * (r²/σ² + log(2π σ²)),   σ = exp(ψ)
#   gη = -r/σ²,   gψ = 1 - r²/σ²
#   hηη = 1/σ²,   hηψ = 2r/σ²,   hψψ = 2r²/σ²
# This means the ENTIRE existing q=2 location-scale Laplace machinery (inner
# mode, marginal, gradient, fit) works for a Gaussian response by passing
# `Val(:gaussian_mean)` as the `kind` argument — no new kernel code needed.
#
# SEPARATE block (MUST-HAVE — the capability drmTMB lacks):
#   Λ = diag(L11², L22²),  L21 ≡ 0  →  mean-phylo RE ⊥ σ-phylo RE.
# COUPLED block (secondary option):
#   Free L21 in the 2×2 Cholesky → mean↔σ correlation in the group-level Λ.
#
# The two blocks use the SAME `_fit_locscale` engine: SEPARATE is recovered by
# fixing L21 = 0 in the initial guess and letting the optimiser relax only
# logL11 and logL22 (via a constrained wrapper that pins L21 = 0); COUPLED lets
# all three λ parameters move freely.
#
# ASYMMETRIC (σ-phylo only, mean fixed) case:
#   Zη = zeros(n, 2), Zψ = [1 0] per row — same as `_sigma_re_loadings` but
#   with a phylogenetic Q instead of Q = I.  The mean-axis Λ diagonal is pinned
#   to a tiny ε = _SIGMA_RE_EPS; only logL22 (= log τ_σ) is optimised.
#   This is the "asymmetric univariate" route (no mean phylo RE).

using SparseArrays: sparse
using LinearAlgebra: I, Symmetric, cholesky, issuccess, diag
import Optim

# ---------------------------------------------------------------------------
# Λ parameterisations for SEPARATE and COUPLED blocks.
# ---------------------------------------------------------------------------

# SEPARATE (diagonal): Λ = diag(L11², L22²), λ = [logL11, logL22] (2-vector).
function _glsp_sep_Λ(λ)
    L11 = exp(λ[1]); L22 = exp(λ[2])
    return [L11^2 0.0; 0.0 L22^2]
end

# COUPLED (free L21): Λ = L Lᵀ, λ = [logL11, L21, logL22] (3-vector).
# Delegates to the existing `_ls_lc_to_Λ` parameterisation in locscale_inner.jl.
_glsp_coupled_Λ(λ) = _ls_lc_to_Λ(λ)   # [logL11, L21, logL22] → Λ

# ---------------------------------------------------------------------------
# Separate-block fitter (the MUST-HAVE, 2 free variance params: logL11, logL22).
# ---------------------------------------------------------------------------

# Marginal NLL at θ = [βμ; βψ; logL11; logL22] with L21 ≡ 0.
function _glsp_sep_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ;
                       warm::Union{Nothing,Ref{Union{Nothing,Vector{Float64}}}} = nothing)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ = @view θ[1:pμ]; βψ = @view θ[pμ+1:pμ+pψ]
    λ   = θ[pμ+pψ+1:pμ+pψ+2]   # [logL11, logL22]
    Λ   = _glsp_sep_Λ(λ)
    Λinv = _ls_inv2x2(Λ)
    P = prior_precision(Q, Λinv)
    a0 = warm === nothing ? nothing : warm[]
    val, a, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P, Zη, Zψ; a0 = a0)
    warm !== nothing && ok && (warm[] = copy(a))
    return ok ? val : 1e18
end

# Exact gradient at θ = [βμ; βψ; logL11; logL22].  Recovered from the general
# 5-component gradient (over [βμ; βψ; logL11, L21, logL22]) by embedding and
# collapsing: L21 ≡ 0 is pinned, so dM/d(L21) is never emitted; the logL11 and
# logL22 components are extracted at positions pμ+pψ+1 and pμ+pψ+3.
function _glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ;
                        warm::Union{Nothing,Ref{Union{Nothing,Vector{Float64}}}} = nothing)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    λ  = θ[pμ+pψ+1:pμ+pψ+2]   # [logL11, logL22]
    θ_full = vcat(θ[1:pμ+pψ], λ[1], 0.0, λ[2])   # embed L21 = 0
    a0 = warm === nothing ? nothing : warm[]
    g_full = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ_full, Zη, Zψ; a0 = a0)
    # g_full: [βμ(pμ); βψ(pψ); logL11; L21; logL22]
    # Extract [βμ; βψ; logL11; logL22], drop L21 (index pμ+pψ+2).
    grad = zeros(pμ + pψ + 2)
    grad[1:pμ+pψ]     .= g_full[1:pμ+pψ]
    grad[pμ+pψ+1]      = g_full[pμ+pψ+1]   # logL11
    grad[pμ+pψ+2]      = g_full[pμ+pψ+3]   # logL22 (skip L21)
    return grad
end

# REML (Patterson–Thompson) penalty for integrating out the mean fixed effects β_μ.
# By the marginal-Hessian identity, S = ∂²nll_marginal/∂β_μ² equals the Schur
# complement H_ββ − H_βuᵀ H_uu⁻¹ H_βu — the marginal information of β_μ. We form S
# by finite-differencing the route's analytic β_μ-gradient block (positions 1:pμ),
# and return the restricted correction 0.5·logdet(S). ML stays the default; REML is
# opt-in (method = :REML), reducing the n→n−pμ downward bias in the variance comps.
function _glsp_reml_penalty(grad_fn, θ, pμ::Int; h::Real = 1e-3)
    S = zeros(pμ, pμ)
    for j in 1:pμ
        θp = copy(θ); θp[j] += h
        θm = copy(θ); θm[j] -= h
        gp = grad_fn(θp); gm = grad_fn(θm)
        @views S[:, j] .= (gp[1:pμ] .- gm[1:pμ]) ./ (2h)
    end
    S .= 0.5 .* (S .+ S')                        # symmetrise FD asymmetry
    ch = cholesky(Symmetric(S); check = false)
    # β_μ information not PD (a degenerate / near-boundary point) ⇒ a LARGE FINITE penalty, not
    # Inf: Inf makes the composite gradient non-finite and trips Optim's line-search assertion
    # (a real crash near σ→0). A large finite value lets the line search backtrack away instead.
    issuccess(ch) || return 1e18
    return sum(log, diag(ch.U))                 # = 0.5·logdet(S)
end

# REML re-fit: starting from the ML estimate θ̂_ml, minimise nll_REML = nll_ML + the
# Patterson–Thompson penalty over θ. Returns (θ̂, converged, ml_nll, reml_nll).
#
# The penalty is a logdet of a FINITE-DIFFERENCE-formed β_μ-information, so its own
# gradient is a second finite difference — too noisy for LBFGS's gradient-convergence
# flag to fire near the (flat) variance-component optimum (a false negative: the search
# parks at the right θ̂ but Optim reports `converged = false`). The re-fit is a small
# polish of the ALREADY-converged ML estimate, so judge convergence on substance, not on
# that noisy flag: the ML fit converged, the restricted objective is finite (β_μ-info PD
# ⇒ non-degenerate), and θ̂ stayed in a neighbourhood of θ̂_ml (no runaway to a boundary).
# A clean flag is restored by `_glsp_reml_refit_clean` (single clean penalty FD); this older
# variant is kept only as the FD-REML correctness anchor for the tests.
function _glsp_reml_refit(obj, grad_fn, θ̂_ml, pμ::Int; ml_converged::Bool = true)
    reml_obj(θ) = obj(θ) + _glsp_reml_penalty(grad_fn, θ, pμ)
    # LBFGS with a finite-difference gradient, warm-started from the ML estimate (the REML
    # optimum is nearby) — a handful of steps, far cheaper than the hundreds NelderMead
    # burns near a flat variance-component optimum.
    res = Optim.optimize(reml_obj, θ̂_ml, Optim.LBFGS(),
                         Optim.Options(g_tol = 1e-3, iterations = 100))
    θ̂ = Optim.minimizer(res)
    reml_nll = reml_obj(θ̂)
    converged = ml_converged && isfinite(reml_nll) && norm(θ̂ .- θ̂_ml) < 5.0
    return θ̂, converged, obj(θ̂), reml_nll
end

# Clean-gradient REML refit — the PRODUCTION REML for the σ-phylo location-scale routes.
# Jointly optimises the restricted objective `nll_ML + 0.5·logdet S` over ALL of θ (so it is
# jointly stationary, unlike the block-coordinate Newton) with a CLEAN gradient (exact ML
# gradient + a single FD of the accurate penalty), and is boundary-robust (finite penalty +
# guarded line search). The observed-information Newton (`_glsp_reml_newton`) is faster on
# benign data but the adversarial verification (2026-06-12) found a β-coupling bias at larger
# pμ/pψ and boundary issues, so it is EXPERIMENTAL — this is the wired path.
# (Earlier mis-called "AI-REML stage 1"; the literal average-information data-quadratic was
# proven invalid for this augmented-Laplace model — see `_glsp_reml_newton`.)
#
# `_glsp_reml_refit` lets LBFGS finite-difference the whole composite `nll_ML + 0.5·logdet
# S`. Because S is itself an FD of the β_μ-gradient block, that is a SECOND-order finite
# difference — too noisy for the gradient-convergence flag, so the FD refit judged
# convergence on substance. Here the optimiser gets a CLEAN gradient: the EXACT analytic ML
# gradient (`grad_fn`) plus a SINGLE central FD of the penalty VALUE (logdet S is smooth and
# accurate to ~1e-8, so its single FD is clean). Same restricted objective ⇒ same optimum as
# the FD refit, but the flag fires honestly and the search is a handful of steps.
#
# Returns (θ̂, converged, ml_nll, reml_nll, n_steps).
function _glsp_reml_refit_clean(obj, grad_fn, θ̂_ml, pμ::Int; ml_converged::Bool = true)
    penalty(θ)  = _glsp_reml_penalty(grad_fn, θ, pμ)
    reml_obj(θ) = obj(θ) + penalty(θ)
    function reml_grad!(g, θ)
        h = 1e-4
        g .= grad_fn(θ)                                  # exact analytic ML gradient
        @inbounds for j in eachindex(θ)
            θp = copy(θ); θp[j] += h
            θm = copy(θ); θm[j] -= h
            g[j] += (penalty(θp) - penalty(θm)) / (2h)   # clean single-FD of the penalty
        end
        return g
    end
    # Guard the line search: near the variance boundary a probe can still hit a non-finite
    # value; on failure fall back to the ML estimate (the n→n−pμ REML correction is negligible
    # at the σ→0 boundary). Without this guard, drm(method=:REML) crashed on ~5–8% of
    # near-boundary datasets with an opaque LineSearches AssertionError (verification 2026-06-12).
    res = try
        Optim.optimize(reml_obj, reml_grad!, copy(θ̂_ml), Optim.LBFGS(),
                       Optim.Options(g_tol = 1e-3, iterations = 100))
    catch err
        err isa InterruptException && rethrow(err)
        nothing
    end
    res === nothing && return copy(θ̂_ml), false, obj(θ̂_ml), reml_obj(θ̂_ml), 0
    θ̂ = Optim.minimizer(res)
    reml_nll = reml_obj(θ̂)
    n_steps = Optim.iterations(res)
    # SUBSTANCE-based flag: the FD-penalty gradient's noise floor and the n-scaling ML gradient
    # make Optim's absolute g_tol unreliable (it reported converged=false on correct fits at
    # larger n — verification finding). Judge on substance: ML converged, restricted objective
    # finite, θ̂ near θ̂_ml (no runaway). A boundary solution (θ̂ at the σ→0 edge) is a valid
    # optimum; its SE is handled by the Wald-V guard / profile CI downstream.
    converged = ml_converged && isfinite(reml_nll) && norm(θ̂ .- θ̂_ml) < 5.0
    return θ̂, converged, obj(θ̂), reml_nll, n_steps
end

# EXPERIMENTAL (asymmetric σ-phylo route) — NOT the production REML (that is the jointly-correct
# `_glsp_reml_refit_clean`). This is the older NON-backtracking observed-information Newton;
# prefer the general `_glsp_reml_newton` (safeguarded step). Same β-coupling / boundary caveats
# as the general one (verification 2026-06-12). Kept only for the asymmetric characterisation test.
#
# HONEST FINDING (adversarial derivation panel, 2026-06-12): the textbook average-information
# DATA QUADRATIC — AI = ½ (∂P_k â)ᵀ H⁻¹ (∂P_l â) — is INVALID as the Newton metric for this
# augmented-Laplace model. The GTC identity E[(∂P â)ᵀH⁻¹(∂P â)] = tr(H⁻¹∂P H⁻¹∂P) holds only
# in EXPECTATION over â ~ N(0, H⁻¹); the realised inner mode â is the SHRUNK BLUP (covariance
# ≠ H⁻¹), so the realised quadratic lands at ~0.2× of the trace (measured: 10.0 vs the
# observed Hessian 22.2 vs the expected-info trace 51.8). With that ~5×-too-small curvature
# the AI-Newton diverges (20 steps, 18% off). The correct, FASTEST O(p) metric is the
# OBSERVED information: a central FD of the EXACT O(p) marginal + penalty REML score (each
# score eval is O(p) — analytic gradient + Takahashi + one clean penalty FD). For K variance
# components this is O(Kp) and converges in ~3 Newton steps. (The expected-info trace
# ½ tr(H⁻¹∂P_k H⁻¹∂P_l) is also valid but needs off-pattern H⁻¹ via factored solves and is
# slower — 14 steps; the observed-info FD is simpler and faster.)
#
# Block-coordinate, ASReml-like: conditional fixed-effect re-fit, then an observed-info Newton
# step on logL22. Returns (θ̂, converged, ml_nll, reml_nll, n_newton).
function _glsp_reml_newton_asym(kind, y, Xμ, Xψ, gidx, G, Q, Zη, Zψ, θ̂_ml, pμ::Int;
                                ml_converged::Bool = true, tol::Real = 1e-4, maxit::Int = 12)
    pψ = size(Xψ, 2)
    iσ = length(θ̂_ml)          # logL22 is the last entry
    iβ = 1:(pμ + pψ)
    θ = copy(θ̂_ml)
    obj(t)  = _glsp_asym_nll(kind, y, Xμ, Xψ, gidx, G, Q, t, Zη, Zψ)
    grd(t)  = _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, t, Zη, Zψ)
    pen(t)  = _glsp_reml_penalty(grd, t, pμ)
    # clean REML score for logL22: exact ML grad + single central FD of the accurate penalty.
    function score_σ(t; h = 1e-4)
        tp = copy(t); tp[iσ] += h
        tm = copy(t); tm[iσ] -= h
        return grd(t)[iσ] + (pen(tp) - pen(tm)) / (2h)
    end
    # OBSERVED information = central FD of the clean score w.r.t. logL22 (β at its conditional
    # optimum). The PD curvature for a Newton step; O(p) per score eval (the panel's 3-step winner).
    function curv_σ(t; h = 1e-3)
        tp = copy(t); tp[iσ] += h
        tm = copy(t); tm[iσ] -= h
        return (score_σ(tp) - score_σ(tm)) / (2h)
    end
    # conditional re-fit of the fixed effects (βμ, βψ) holding logL22 fixed.
    function refit_β!(t)
        ls = t[iσ]
        ob(b) = obj(vcat(b, ls))
        gb!(g, b) = (g .= grd(vcat(b, ls))[iβ]; g)
        r = Optim.optimize(ob, gb!, t[iβ], Optim.LBFGS(), Optim.Options(g_tol = 1e-7, iterations = 100))
        t[iβ] .= Optim.minimizer(r)
        return t
    end
    n_newton = 0; converged = false
    for it in 1:maxit
        n_newton = it
        refit_β!(θ)                               # (a) GLS-like fixed-effect update
        s = score_σ(θ)
        if abs(s) < tol                           # (b) observed-info Newton on logL22
            converged = true
            break
        end
        H = curv_σ(θ)
        isfinite(H) || break
        Hpd = abs(H) < 1e-6 ? 1e-6 : abs(H)       # project to PD (descent) + guard a flat curvature
        θ[iσ] -= clamp(s / Hpd, -3.0, 3.0)        # clamp IS the trust bound when curvature is poor
    end
    refit_β!(θ)                                   # final conditional fixed-effect polish
    ml_nll = obj(θ); reml_nll = ml_nll + pen(θ)
    converged = converged && ml_converged && isfinite(reml_nll)
    return θ, converged, ml_nll, reml_nll, n_newton
end

# EXPERIMENTAL — NOT the production REML path (the wired path is `_glsp_reml_refit_clean`).
# The adversarial verification (2026-06-12) confirmed two defects in this block-coordinate
# Newton: (1) `refit_β!` minimises ONLY the ML objective over β, omitting the penalty's
# β-dependence, so the fixed point is NOT jointly stationary — a σ-SD bias that is negligible
# for intercept-ish models (pμ≈pψ≈1, Δsd≈5e-6) but grows with pμ/pψ (≈3% at pμ=6, pψ=2); and
# (2) the variance-block convergence test can mis-fire at the τ→0 boundary. Kept for research /
# the speed exploration. On the verified benign fixtures it matches FD-REML in a handful of
# Newton steps (≤5 asym / ≤6 K=2, measured on seeds 808/909 — not a guaranteed bound). Per-step
# cost is O(K²·pμ) exact O(p) score/penalty evals for the curvature PLUS one conditional
# fixed-effect LBFGS refit: O(p) in the number of groups, constant growing in K and pμ.
#
# General observed-information Newton REML over K variance components (`vidx` = their indices
# in θ). Route-AGNOSTIC: it needs only the route's marginal NLL `obj` and exact gradient `grad`
# (closures over the full θ), so the same code serves the asymmetric (K=1), separate (K=2), and
# coupled (K=3) blocks. The metric is the OBSERVED information — a central FD of the clean
# REML score (exact ML grad + a single FD of the accurate penalty) — projected to PD; the
# average-information data-quadratic is invalid here (â is the shrunk BLUP). Block-coordinate:
# conditional fixed-effect re-fit, then a K×K Newton step on θ[vidx]. Returns
# (θ̂, converged, ml_nll, reml_nll, n_newton).
function _glsp_reml_newton(obj, grad, θ̂_ml, pμ::Int, vidx::AbstractVector{Int};
                           ml_converged::Bool = true, tol::Real = 1e-4, maxit::Int = 20)
    K  = length(vidx)
    nθ = length(θ̂_ml)
    βidx = setdiff(1:nθ, vidx)
    θ  = copy(θ̂_ml)
    pen(t) = _glsp_reml_penalty(grad, t, pμ)
    # clean REML score on the variance components: exact ML grad + single FD of the penalty.
    function score_v(t; h = 1e-4)
        gv = grad(t)[vidx]
        @inbounds for (c, j) in enumerate(vidx)
            tp = copy(t); tp[j] += h
            tm = copy(t); tm[j] -= h
            gv[c] += (pen(tp) - pen(tm)) / (2h)
        end
        return gv
    end
    # observed information (K×K) = central FD of the variance-component score.
    function info_v(t; h = 1e-3)
        A = zeros(K, K)
        @inbounds for (c, j) in enumerate(vidx)
            tp = copy(t); tp[j] += h
            tm = copy(t); tm[j] -= h
            A[:, c] .= (score_v(tp) .- score_v(tm)) ./ (2h)
        end
        return 0.5 .* (A .+ A')                # symmetrise FD asymmetry
    end
    # PD-projected solve: floor eigenvalues so the Newton step is a descent step.
    function pd_solve(A, b)
        E = eigen(Symmetric(A))
        d = max.(E.values, 1e-6)
        return E.vectors * ((E.vectors' * b) ./ d)
    end
    # conditional re-fit of the fixed effects holding the variance components fixed.
    function refit_β!(t)
        ob(b)     = (tw = copy(t); tw[βidx] .= b; obj(tw))
        gb!(g, b) = (tw = copy(t); tw[βidx] .= b; g .= grad(tw)[βidx]; g)
        r = Optim.optimize(ob, gb!, t[βidx], Optim.LBFGS(), Optim.Options(g_tol = 1e-7, iterations = 100))
        t[βidx] .= Optim.minimizer(r)
        return t
    end
    n_newton = 0; converged = false
    for it in 1:maxit
        n_newton = it
        refit_β!(θ)                                   # (a) conditional fixed-effect update
        s = score_v(θ)
        A = info_v(θ)
        all(isfinite, A) || break
        dir = clamp.(pd_solve(A, s), -4.0, 4.0)        # Newton direction (per-component cap)
        f0  = obj(θ) + pen(θ)
        # (b) SAFEGUARDED observed-info Newton step: backtrack until the restricted objective
        # DECREASES (monotone descent ⇒ the iterate cannot diverge even when the FD curvature is
        # unreliable at large p — the unguarded step overshot to σ-SD ≈ 7; benchmark 2026-06-12).
        # Convergence is judged on the STEP SIZE in the log-SD chart (scale-free), NOT on the raw
        # score (which scales with n and made the absolute tol unreachable at large p).
        α = 1.0; accepted = false; δθ = 0.0
        for _ in 1:24
            θt = copy(θ)
            @inbounds for c in 1:K
                θt[vidx[c]] -= α * dir[c]
            end
            refit_β!(θt)                              # β at its conditional optimum for the trial
            if obj(θt) + pen(θt) < f0
                δθ = α * norm(dir); copyto!(θ, θt); accepted = true; break
            end
            α *= 0.5
        end
        if !accepted || δθ < tol                      # no further descent / negligible step ⇒ converged
            converged = true
            break
        end
    end
    refit_β!(θ)
    ml_nll = obj(θ); reml_nll = ml_nll + pen(θ)
    converged = converged && ml_converged && isfinite(reml_nll)
    return θ, converged, ml_nll, reml_nll, n_newton
end

# B2 — boundary-aware PROFILE-LIKELIHOOD CI for one variance (log-SD) parameter.
# `nll(θ)::Real` and `grad(θ)::Vector` are the route's own marginal NLL and analytic
# gradient; `idx` is the profiled log-SD position. Profiles θ[idx]: re-optimises the
# free params (cold inner solves — never a shared warm ref) and brackets the χ²₁
# threshold. Boundary-aware: when the profile never crosses the threshold going DOWN
# (logL → −∞, SD → 0), the lower SD endpoint is 0 — an honest `[0, x]` CI instead of a
# singular-Wald failure. Returns (sd_lo, sd_hi) on the SD scale. Generic over the
# block (separate / asymmetric) via the passed closures.
function _glsp_profile_ci(nll, grad, θ̂, idx; level = 0.95)
    nll_min = nll(θ̂)
    thr  = 0.5 * Distributions.quantile(Distributions.Chisq(1), level)   # χ²₁/2
    free = setdiff(1:length(θ̂), idx)
    function prof_dev(v)
        θfix = copy(θ̂); θfix[idx] = v
        obj(z) = (θw = copy(θfix); θw[free] .= z; nll(θw))
        grad!(g, z) = (θw = copy(θfix); θw[free] .= z; g .= grad(θw)[free]; g)
        val = try
            res = Optim.optimize(obj, grad!, copy(θ̂[free]), Optim.LBFGS(),
                                 Optim.Options(g_tol = 1e-6, iterations = 150))
            Optim.minimum(res)
        catch
            Inf            # sub-fit failed (ill-conditioned at an extreme log-SD)
        end
        return (val - nll_min) - thr
    end
    crossed(d) = isfinite(d) && d > 0
    v̂ = θ̂[idx]
    # Bounded bracket: cap the log-SD excursion at ±8 (an SD ratio e^8 ≈ 3000×).
    # Beyond that the component is effectively unidentified, so report the boundary
    # (SD 0 below / Inf above) rather than chasing the threshold into the region
    # where the inner solve is ill-conditioned. prof_dev(v̂) = -thr < 0 and, when the
    # profile crosses, prof_dev(cap) > 0 — a clean sign change for the bisection.
    function endpoint(dir)
        cap = v̂ + dir * 8.0
        crossed(prof_dev(cap)) || return nothing      # never crossed in range → boundary
        a, b = v̂, cap
        for _ in 1:24                                  # 16/2²⁴ ≈ 1e-6 precision in log-SD
            m = 0.5 * (a + b)
            crossed(prof_dev(m)) ? (b = m) : (a = m)
        end
        return 0.5 * (a + b)
    end
    lo = endpoint(-1.0); hi = endpoint(+1.0)
    return (sd_lo = lo === nothing ? 0.0 : exp(lo),
            sd_hi = hi === nothing ? Inf : exp(hi))
end

# ---------------------------------------------------------------------------
# Asymmetric fitter (σ-phylo only, mean fixed, 1 free variance param: logL22).
# ---------------------------------------------------------------------------
# Reuses _sigma_re_loadings and _sigma_re_Lambda / _sigma_re_grad convention but
# with an explicit phylogenetic Q instead of Q = I.

# Build Λ = diag(ε², L22²) for the asymmetric case (L22 is the σ-phylo SD).
function _glsp_asym_Λ(logL22::Real)
    L22 = exp(logL22)
    return [_SIGMA_RE_EPS^2 0.0; 0.0 L22^2]
end

# Latent loadings for the asymmetric case: mean axis untouched (Zη = 0),
# σ axis loaded by axis-2 (Zψ = [0 1]).
function _glsp_asym_loadings(n::Int)
    Zη = zeros(n, 2)
    Zψ = zeros(n, 2)
    @views Zψ[:, 2] .= 1.0
    return Zη, Zψ
end

# Marginal NLL at θ = [βμ; βψ; logL22] for the asymmetric σ-phylo case.
function _glsp_asym_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ;
                        warm::Union{Nothing,Ref{Union{Nothing,Vector{Float64}}}} = nothing)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    βμ = @view θ[1:pμ]; βψ = @view θ[pμ+1:pμ+pψ]
    logL22 = θ[pμ+pψ+1]
    Λ = _glsp_asym_Λ(logL22)
    Λinv = _ls_inv2x2(Λ)
    P = prior_precision(Q, Λinv)
    a0 = warm === nothing ? nothing : warm[]
    val, a, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P, Zη, Zψ; a0 = a0)
    warm !== nothing && ok && (warm[] = copy(a))
    return ok ? val : 1e18
end

# Exact gradient at θ = [βμ; βψ; logL22].  Embed as [βμ; βψ; log(ε), 0, logL22]
# in the 5-component layout of `_ls_marginal_grad`, then extract only [βμ; βψ; logL22].
function _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ;
                         warm::Union{Nothing,Ref{Union{Nothing,Vector{Float64}}}} = nothing)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    logL22 = θ[pμ+pψ+1]
    θ_full = vcat(θ[1:pμ+pψ], log(_SIGMA_RE_EPS), 0.0, logL22)
    a0 = warm === nothing ? nothing : warm[]
    g_full = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ_full, Zη, Zψ; a0 = a0)
    grad = zeros(pμ + pψ + 1)
    grad[1:pμ+pψ] .= g_full[1:pμ+pψ]
    grad[pμ+pψ+1]  = g_full[pμ+pψ+3]   # logL22 component
    return grad
end

# ---------------------------------------------------------------------------
# LBFGS + Newton inner-trust-region outer optimiser (mirrors _fit_locscale).
# `obj` and `grad!` must accept/fill vectors of the appropriate length.
# ---------------------------------------------------------------------------
function _glsp_optimise(obj, grad!, θ0; g_tol = 1e-6, iterations = 1000)
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    nm() = Optim.optimize(θ -> obj(θ), θ0, Optim.NelderMead(),
                          Optim.Options(iterations = max(iterations, 2000)))
    res = try
        Optim.optimize(obj, grad!, θ0, Optim.LBFGS(), opts)
    catch err
        err isa InterruptException && rethrow(err)
        try
            nm()
        catch err2
            err2 isa InterruptException && rethrow(err2)
            nm()
        end
    end
    θ̂ = Optim.minimizer(res)
    if any(!isfinite, θ̂) || !(obj(θ̂) < 1e17)
        res = nm()
        θ̂ = Optim.minimizer(res)
    end
    return θ̂, Optim.converged(res)
end

# ---------------------------------------------------------------------------
# Public entry: _fit_gaussian_locscale_phylo
# ---------------------------------------------------------------------------
"""
    _fit_gaussian_locscale_phylo(fam, y, Xμ, Xψ, gidx, G, Q, nmμ, nmσ, grp;
                                  coupled, asymmetric, se, g_tol) -> DrmFit

Fit a UNIVARIATE Gaussian location-scale model with a phylogenetic random effect
on BOTH axes (by default SEPARATE / uncorrelated) or on the σ axis only
(asymmetric).

Modes controlled by kwargs:
  - `coupled = false` (default): SEPARATE block Λ = diag(L11², L22²), L21 ≡ 0.
    Returns DrmFit with `:mu`, `:sigma`, `:resd_mu` (logL11), `:resd_sigma` (logL22).
  - `coupled = true`: FREE L21, full 2×2 Λ with mean↔σ correlation.
    Returns DrmFit with `:mu`, `:sigma`, `:recov` (logL11, logL22, L21).
  - `asymmetric = true`: σ-phylo only (mean fixed effects, no mean phylo RE).
    Returns DrmFit with `:mu`, `:sigma`, `:resd_sigma` (logL22).

The kernel is `Val(:gaussian_mean)`: η = mean, ψ = log σ, integrating the
Gaussian location-scale likelihood through the q=2 augmented-state Laplace spine.
"""
function _fit_gaussian_locscale_phylo(fam::Gaussian, y, Xμ, Xψ, gidx, G, Q,
                                       nmμ, nmσ, grp::String;
                                       coupled::Bool = false,
                                       asymmetric::Bool = false,
                                       se::Bool = true,
                                       profile_ci::Bool = false,
                                       reml::Bool = false,
                                       g_tol::Real = 1e-6)
    kind = Val(:gaussian_mean)
    n = length(y)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2)

    # ---- ASYMMETRIC: σ-phylo only ----------------------------------------
    if asymmetric
        Zη, Zψ = _glsp_asym_loadings(n)
        # No shared warm (see the separate-block note) — cold inner solves.
        function asym_obj(θ)
            _glsp_asym_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
        end
        function asym_grad!(g, θ)
            g .= _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            g
        end
        βμ0 = Xμ \ y
        βψ0 = zeros(pψ)
        logL22_0 = log(0.3)
        θ0 = vcat(βμ0, βψ0, logL22_0)
        θ̂, conv = _glsp_optimise(asym_obj, asym_grad!, θ0; g_tol = g_tol)
        ml_nll = asym_obj(θ̂); reml_nll = NaN
        if reml
            asym_grad_fn(θ) = _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            # Jointly-correct, boundary-robust clean-gradient LBFGS REML. (The observed-info
            # Newton `_glsp_reml_newton` is faster on benign data, but the adversarial
            # verification found a β-coupling bias at larger pμ/pψ and boundary issues, so it is
            # EXPERIMENTAL, not the production path — see its docstring.)
            θ̂, conv, ml_nll, reml_nll, _ = _glsp_reml_refit_clean(asym_obj, asym_grad_fn, θ̂, pμ; ml_converged = conv)
        end
        nll_val = reml ? reml_nll : ml_nll
        βμ̂ = θ̂[1:pμ]; βψ̂ = θ̂[pμ+1:pμ+pψ]; logL22 = θ̂[pμ+pψ+1]
        # Wald covariance via FD of the gradient
        V = if se
            try
                h = 1e-4; np = length(θ̂)
                H = zeros(np, np)
                for j in 1:np
                    tp = copy(θ̂); tp[j] += h
                    tm = copy(θ̂); tm[j] -= h
                    gp = _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, tp, Zη, Zψ)
                    gm = _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, tm, Zη, Zψ)
                    H[:, j] .= (gp .- gm) ./ (2h)
                end
                # PD-guard: at the variance boundary H is singular and `inv` returns GARBAGE
                # (huge finite values), not an error — so report NaN SEs (use profile_ci there).
                chH = cholesky(Symmetric(H); check = false)
                issuccess(chH) ? Matrix(inv(chH)) : fill(NaN, size(H))
            catch
                fill(NaN, length(θ̂), length(θ̂))
            end
        else
            fill(NaN, length(θ̂), length(θ̂))
        end
        blocks = Pair{Symbol,UnitRange{Int}}[
            :mu => 1:pμ,
            :sigma => (pμ+1):(pμ+pψ),
            :resd_sigma => (pμ+pψ+1):(pμ+pψ+1)
        ]
        names = Pair{Symbol,Vector{String}}[
            :mu => nmμ,
            :sigma => nmσ,
            :resd_sigma => ["$(grp):sd_sigma"]
        ]
        means  = Dict(:mu => Xμ * βμ̂)
        obs    = Dict(:mu => Float64.(y))
        scales = Dict(:sigma => exp.(Xψ * βψ̂))
        # B2 — boundary-aware profile CI for the σ-phylo SD (the most boundary-prone
        # cell: Ayumi's collapsing σ-SDs). Reports `[0, x]` honestly when the scale
        # signal is absent. Opt-in (profile_ci) — the root-find re-fits the route NLL.
        if profile_ci
            asym_nll_θ(θ)  = _glsp_asym_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            asym_grad_θ(θ) = _glsp_asym_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            ci_s = _glsp_profile_ci(asym_nll_θ, asym_grad_θ, θ̂, pμ + pψ + 1)
            scales[:profile_ci_sd_sigma] = [ci_s.sd_lo, ci_s.sd_hi]
        end
        fit = DrmFit(fam, blocks, names, θ̂, V, -nll_val, n, conv, means, obs, scales)
        return reml ? _withreml(fit, -reml_nll, -ml_nll) : fit
    end

    # ---- BOTH-PHYLO: separate (MUST-HAVE) or coupled ----------------------
    Zη = _ls_canonical_Zeta(n)    # [1 0] per row: axis-1 → mean
    Zψ = _ls_canonical_Zpsi(n)    # [0 1] per row: axis-2 → σ

    if !coupled
        # SEPARATE block: 2 free variance params [logL11, logL22]
        # NOTE: NO shared warm-start between obj and grad. The LBFGS line search
        # leaves the grad's warm inner-mode from a DIFFERENT θ (stale), which froze
        # Λ at its init (both SDs stuck at 0.3). Cold inner solves are correct;
        # perf is fine at these sizes.
        function sep_obj(θ)
            _glsp_sep_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
        end
        function sep_grad!(g, θ)
            g .= _glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            g
        end
        βμ0 = Xμ \ y
        βψ0 = zeros(pψ)
        θ0 = vcat(βμ0, βψ0, log(0.3), log(0.3))   # [βμ; βψ; logL11; logL22]
        θ̂, conv = _glsp_optimise(sep_obj, sep_grad!, θ0; g_tol = g_tol)
        ml_nll = sep_obj(θ̂); reml_nll = NaN
        if reml
            sep_grad_fn(θ) = _glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            # Jointly-correct, boundary-robust clean-gradient LBFGS REML. (The observed-info
            # Newton `_glsp_reml_newton` is faster on benign data, but the adversarial
            # verification found a β-coupling bias at larger pμ/pψ and boundary issues, so it is
            # EXPERIMENTAL, not the production path — see its docstring.)
            θ̂, conv, ml_nll, reml_nll, _ = _glsp_reml_refit_clean(sep_obj, sep_grad_fn, θ̂, pμ; ml_converged = conv)
        end
        nll_val = reml ? reml_nll : ml_nll
        βμ̂ = θ̂[1:pμ]; βψ̂ = θ̂[pμ+1:pμ+pψ]
        logL11 = θ̂[pμ+pψ+1]; logL22 = θ̂[pμ+pψ+2]
        # Λ for reporting
        Λ̂ = _glsp_sep_Λ([logL11, logL22])
        # Wald covariance via FD of the gradient
        V = if se
            try
                h = 1e-4; np = length(θ̂)
                H = zeros(np, np)
                for j in 1:np
                    tp = copy(θ̂); tp[j] += h
                    tm = copy(θ̂); tm[j] -= h
                    gp = _glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, tp, Zη, Zψ)
                    gm = _glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, tm, Zη, Zψ)
                    H[:, j] .= (gp .- gm) ./ (2h)
                end
                # PD-guard: at the variance boundary H is singular and `inv` returns GARBAGE
                # (huge finite values), not an error — so report NaN SEs (use profile_ci there).
                chH = cholesky(Symmetric(H); check = false)
                issuccess(chH) ? Matrix(inv(chH)) : fill(NaN, size(H))
            catch
                fill(NaN, length(θ̂), length(θ̂))
            end
        else
            fill(NaN, length(θ̂), length(θ̂))
        end
        blocks = Pair{Symbol,UnitRange{Int}}[
            :mu => 1:pμ,
            :sigma => (pμ+1):(pμ+pψ),
            :resd_mu    => (pμ+pψ+1):(pμ+pψ+1),   # logL11
            :resd_sigma => (pμ+pψ+2):(pμ+pψ+2)    # logL22
        ]
        names = Pair{Symbol,Vector{String}}[
            :mu => nmμ,
            :sigma => nmσ,
            :resd_mu    => ["$(grp):sd_mu"],
            :resd_sigma => ["$(grp):sd_sigma"]
        ]
        means  = Dict(:mu => Xμ * βμ̂)
        obs    = Dict(:mu => Float64.(y))
        scales = Dict(:sigma => exp.(Xψ * βψ̂))
        # Attach Lambda and components as extra metadata in the scales dict for
        # downstream accessors (they read :lambda_sd_mu, :lambda_sd_sigma).
        scales[:lambda_sd_mu]    = [sqrt(Λ̂[1, 1])]
        scales[:lambda_sd_sigma] = [sqrt(Λ̂[2, 2])]
        # B2 — boundary-aware profile-likelihood CIs for the phylo SDs (honest
        # `[0, x]` at the boundary, where the Wald V is singular). Opt-in
        # (profile_ci) — the root-find re-optimises the route's own NLL per endpoint.
        if profile_ci
            sep_nll_θ(θ)  = _glsp_sep_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            sep_grad_θ(θ) = _glsp_sep_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            ci_s = _glsp_profile_ci(sep_nll_θ, sep_grad_θ, θ̂, pμ + pψ + 2)
            ci_m = _glsp_profile_ci(sep_nll_θ, sep_grad_θ, θ̂, pμ + pψ + 1)
            scales[:profile_ci_sd_sigma] = [ci_s.sd_lo, ci_s.sd_hi]
            scales[:profile_ci_sd_mu]    = [ci_m.sd_lo, ci_m.sd_hi]
        end
        fit = DrmFit(fam, blocks, names, θ̂, V, -nll_val, n, conv, means, obs, scales)
        return reml ? _withreml(fit, -reml_nll, -ml_nll) : fit

    else
        # COUPLED block: 3 free variance params [logL11, L21, logL22]
        # REML is not wired for the coupled mean↔σ block — make the drop LOUD rather than
        # silently returning an ML fit tagged :ML. (The public drm() frontend never dispatches
        # coupled=true, so this guards internal/direct callers.)
        reml && error("REML is not implemented for the coupled mean↔σ location-scale block; " *
                      "use the separate block (the default) or method = :ML.")
        # No shared warm (see the separate-block note) — cold inner solves.
        function coup_obj(θ)
            pμ_ = size(Xμ, 2); pψ_ = size(Xψ, 2)
            βμ = @view θ[1:pμ_]; βψ = @view θ[pμ_+1:pμ_+pψ_]
            λv = θ[pμ_+pψ_+1:pμ_+pψ_+3]
            Λ  = _glsp_coupled_Λ(λv)
            Λinv = _ls_inv2x2(Λ)
            P = prior_precision(Q, Λinv)
            val, a, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P, Zη, Zψ)
            ok ? val : 1e18
        end
        function coup_grad!(g, θ)
            g .= _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ)
            g
        end
        βμ0 = Xμ \ y
        βψ0 = zeros(pψ)
        θ0 = vcat(βμ0, βψ0, log(0.3), 0.0, log(0.3))
        θ̂, conv = _glsp_optimise(coup_obj, coup_grad!, θ0; g_tol = g_tol)
        nll_val = coup_obj(θ̂)
        βμ̂ = θ̂[1:pμ]; βψ̂ = θ̂[pμ+1:pμ+pψ]
        λ̂ = θ̂[pμ+pψ+1:pμ+pψ+3]
        Λ̂ = _glsp_coupled_Λ(λ̂)
        comp = _ls_components(Λ̂)
        # Wald via FD of the general gradient
        V = if se
            try
                h = 1e-4; np = length(θ̂)
                H = zeros(np, np)
                for j in 1:np
                    tp = copy(θ̂); tp[j] += h
                    tm = copy(θ̂); tm[j] -= h
                    gp = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, tp, Zη, Zψ)
                    gm = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, tm, Zη, Zψ)
                    H[:, j] .= (gp .- gm) ./ (2h)
                end
                # PD-guard: at the variance boundary H is singular and `inv` returns GARBAGE
                # (huge finite values), not an error — so report NaN SEs (use profile_ci there).
                chH = cholesky(Symmetric(H); check = false)
                issuccess(chH) ? Matrix(inv(chH)) : fill(NaN, size(H))
            catch
                fill(NaN, length(θ̂), length(θ̂))
            end
        else
            fill(NaN, length(θ̂), length(θ̂))
        end
        # `:recov` block: [logL11, logL22, L21] — matches the locscale_frontend convention.
        theta_out = vcat(βμ̂, βψ̂, λ̂[1], λ̂[3], λ̂[2])
        perm = vcat(collect(1:(pμ+pψ)), [pμ+pψ+1, pμ+pψ+3, pμ+pψ+2])
        V_out = V === nothing ? fill(NaN, length(theta_out), length(theta_out)) :
                (all(isnan, V) ? fill(NaN, length(theta_out), length(theta_out)) : V[perm, perm])
        blocks = Pair{Symbol,UnitRange{Int}}[
            :mu    => 1:pμ,
            :sigma => (pμ+1):(pμ+pψ),
            :recov => (pμ+pψ+1):(pμ+pψ+3)
        ]
        names = Pair{Symbol,Vector{String}}[
            :mu    => nmμ,
            :sigma => nmσ,
            :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]
        ]
        means  = Dict(:mu => Xμ * βμ̂)
        obs    = Dict(:mu => Float64.(y))
        scales = Dict(:sigma => exp.(Xψ * βψ̂))
        scales[:lambda_sd_mu]    = [comp.sd_mu]
        scales[:lambda_sd_sigma] = [comp.sd_psi]
        scales[:lambda_cor]      = [comp.cor_mu_psi]
        return DrmFit(fam, blocks, names, theta_out, V_out, -nll_val, n, conv, means, obs, scales)
    end
end

# ---------------------------------------------------------------------------
# Convenience accessor: extract the two phylo SDs from a separate-block fit.
# Returns NamedTuple (sd_mu, sd_sigma).
# ---------------------------------------------------------------------------
"""
    gaussian_locscale_phylo_sds(fit::DrmFit) -> NamedTuple

Extract sd(μ-phylo) and sd(σ-phylo) from a SEPARATE-block Gaussian phylo
location-scale fit. Reads the `:resd_mu` / `:resd_sigma` blocks (exp of their
stored log values). For a COUPLED fit use `fit.scales[:lambda_sd_mu]` etc.
"""
function gaussian_locscale_phylo_sds(fit::DrmFit)
    has_sep_mu  = any(p -> p === :resd_mu,    first.(fit.blocks))
    has_sep_sig = any(p -> p === :resd_sigma, first.(fit.blocks))
    if has_sep_mu && has_sep_sig
        return (sd_mu = exp(coef(fit, :resd_mu)[1]),
                sd_sigma = exp(coef(fit, :resd_sigma)[1]))
    elseif has_sep_sig && !has_sep_mu
        return (sd_mu = 0.0,
                sd_sigma = exp(coef(fit, :resd_sigma)[1]))
    elseif haskey(fit.scales, :lambda_sd_mu) && haskey(fit.scales, :lambda_sd_sigma)
        return (sd_mu = fit.scales[:lambda_sd_mu][1],
                sd_sigma = fit.scales[:lambda_sd_sigma][1])
    else
        error("fit does not appear to be a gaussian_locscale_phylo fit")
    end
end
