# Location–scale–scale (#544): a third submodel putting a linear predictor on the
# LOG standard deviation of the (1 | g) random effect, mirroring drmTMB's
# `bf(y ~ x + (1 | g), sigma ~ x, sd(g) ~ x_group)` grammar (vignette
# "location-scale-scale"). Per group k: σ_b,k = exp(Z_k' α), so the marginal is
# still the exact Woodbury Gaussian of `_fit_ranef_gaussian` — the capacitance is
# diagonal per group, so a per-group variance is a drop-in. The scalar model is
# the special case Zg = ones(G, 1); `test/test_lss_group.jl` pins that reduction.
#
# `sd_phylo(species) ~ x` (climate-dependent phylogenetic SD, the Mizuno et al.
# QQQ model) is #545 and routes through the sparse phylo spine, not this file.

"""
    sd(group)

Formula marker for a location–scale–scale model. Used only on the left-hand
side of a `bf` component formula,

```julia
bf(y ~ x + (1 | g), sigma ~ x, sd(g) ~ z)
```

to put a linear predictor on the **log standard deviation of the `(1 | g)`
random effect**: `log σ_b,k = Z_k' α` with one row per group level. Mirrors
drmTMB's `sd(group) ~ …`. Predictors in the `sd()` formula must be constant
within each level of `group`. Univariate Gaussian only; the fitted
coefficients appear as the `:sd` block (`coef(fit, :sd)`, `confint(fit; parm
= :sd)`).
"""
sd(x) = x

# Extract `sd(g) ~ rhs` parts stashed by `bf` as `Symbol("sd_", g) => rhs`.
_sd_parts(f::DrmFormula) = Pair{Symbol,Any}[
    Symbol(String(first(p))[(length("sd_")+1):end]) => last(p)
    for p in f.forms if startswith(String(first(p)), "sd_")]

# One-line guard for family routes that do not support sd(): every family
# consumer reads `Dict(f.forms)` by known keys, so an unguarded sd() part would
# be DROPPED SILENTLY — the exact bug class of issue #2 (silent σ-phylo drop).
function _lss_only_gaussian_guard(f::DrmFormula, fam)
    isempty(_sd_parts(f)) ||
        throw(ArgumentError("drm: `sd(group) ~ …` location-scale-scale formulas are " *
            "supported for the univariate Gaussian family only (got $(nameof(typeof(fam))))."))
    return nothing
end

# Group-level design for the sd() submodel: build the n-row design from the full
# data, require every predictor constant within each group level (drmTMB errors
# the same way), and compress to one row per group in `_group_index` order.
function _sd_group_design(response::Symbol, rhs, data, gidx::Vector{Int}, G::Int, grp::Symbol)
    _, Zfull, nm = _design(response, rhs, data)
    q = size(Zfull, 2)
    Zg = fill(NaN, G, q)
    for i in eachindex(gidx)
        k = gidx[i]
        if isnan(Zg[k, 1])
            @views Zg[k, :] .= Zfull[i, :]
        else
            for j in 1:q
                Zg[k, j] == Zfull[i, j] ||
                    throw(ArgumentError("sd($grp): predictor `$(nm[j])` varies within a level " *
                        "of `$grp` — sd() predictors must be constant within each group. " *
                        "Check the grouping variable and source data; do not average a " *
                        "genuinely within-group predictor to silence this."))
            end
        end
    end
    return Zg, nm
end

# Router leg: validate the sd() request against the rest of the Gaussian model
# and dispatch. Called from `drm(f, ::Gaussian)` with everything it has parsed.
function _drm_gaussian_lss(f::DrmFormula, fam::Gaussian, sdp, re, re_kinds, structured,
                           structured_sigma, sigma_re, metav, has_missing_response,
                           y, Xμ, Xσ, nmμ, nmσ, data, g_tol, method)
    length(sdp) == 1 ||
        throw(ArgumentError("drm: one `sd(group) ~ …` formula per model (got $(length(sdp)))."))
    sgrp, srhs = sdp[1]
    (structured === nothing && structured_sigma === nothing) ||
        throw(ArgumentError("drm: `sd($sgrp)` with structured effects (phylo/relmat/animal/" *
            "spatial) is not yet supported — the climate-dependent phylogenetic SD " *
            "(`sd_phylo`) is issue #545."))
    metav === nothing ||
        throw(ArgumentError("drm: `sd($sgrp)` cannot be combined with `meta_V(...)`."))
    isempty(sigma_re) ||
        throw(ArgumentError("drm: `sd($sgrp)` cannot be combined with a random effect on `sigma`."))
    has_missing_response &&
        throw(ArgumentError("drm: `sd($sgrp)` does not yet support missing responses — " *
            "use `drm_listwise` to preprocess."))
    length(re) == 1 ||
        throw(ArgumentError("drm: `sd($sgrp)` requires exactly one `(1 | $sgrp)` random " *
            "intercept on the mean (got $(length(re)) random-effect terms)."))
    (kind, _) = re_kinds[1]
    kind === :intercept ||
        throw(ArgumentError("drm: `sd($sgrp)` supports a random INTERCEPT `(1 | $sgrp)` only."))
    (_, grp) = re[1]
    grp === sgrp ||
        throw(ArgumentError("drm: `sd($sgrp)` must name the grouping of the random effect — " *
            "the mean formula has `(1 | $grp)`."))
    gidx, G = _group_index(getproperty(data, grp))
    Zg, nmsd = _sd_group_design(f.response, srhs, data, gidx, G, grp)
    return _fit_ranef_gaussian_lss(fam, y, Xμ, Xσ, Zg, gidx, G, nmμ, nmσ, nmsd, grp, g_tol;
                                   reml = method === :REML)
end

# Gaussian location–scale–scale with one mean random intercept (1 | g) whose
# per-group SD carries a linear predictor: θ = [β_μ; β_σ (log σ); α (log σ_b)].
# Same exact Woodbury/Patterson–Thompson marginal as `_fit_ranef_gaussian`
# (which is left byte-for-byte untouched), with σ_b² per group. Convergence
# reasoning (exact marginal, no inner-solve noise floor) carries over from that
# function's header note.
function _fit_ranef_gaussian_lss(fam::Gaussian, y, Xμ, Xσ, Zg, gidx, G, nmμ, nmσ, nmsd,
                                 grp, g_tol; reml::Bool = false)
    n = length(y)
    pμ, pσ, psd = size(Xμ, 2), size(Xσ, 2), size(Zg, 2)
    const_2pi = 0.5 * n * log(2π)
    const_pμ = 0.5 * pμ * log(2π)

    function nll_ml(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; α = θ[pμ+pσ+1:pμ+pσ+psd]
        ημ = Xμ * βμ; ησ = Xσ * βσ                 # ησ = log σ_i
        ησb = Zg * α                                # per-group log σ_b,k
        T = eltype(θ)
        S = zeros(T, G); C = zeros(T, G)
        q1 = zero(T); logdetD = zero(T)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i])
            r = y[i] - ημ[i]
            a = r * invD
            k = gidx[i]
            S[k] += invD
            C[k] += a
            q1 += r * a
            logdetD += 2 * ησ[i]
        end
        q2 = zero(T); logdetCap = zero(T)
        @inbounds for k in 1:G
            σb² = exp(2 * ησb[k])
            Mk = 1 / σb² + S[k]
            q2 += C[k]^2 / Mk
            logdetCap += log(1 + σb² * S[k])
        end
        return 0.5 * (logdetD + logdetCap + q1 - q2) + const_2pi
    end

    function nll_reml(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; α = θ[pμ+pσ+1:pμ+pσ+psd]
        ημ = Xμ * βμ; ησ = Xσ * βσ
        ησb = Zg * α
        T = eltype(θ)
        S = zeros(T, G); C = zeros(T, G)
        ZtDinvX = zeros(T, G, pμ)
        XtDinvX = zeros(T, pμ, pμ)
        q1 = zero(T); logdetD = zero(T)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i])
            r = y[i] - ημ[i]
            a = r * invD
            k = gidx[i]
            S[k] += invD
            C[k] += a
            q1 += r * a
            logdetD += 2 * ησ[i]
            @inbounds for j in 1:pμ
                xj = Xμ[i, j]
                ZtDinvX[k, j] += invD * xj
                @inbounds for l in 1:pμ
                    XtDinvX[j, l] += invD * xj * Xμ[i, l]
                end
            end
        end
        q2 = zero(T); logdetCap = zero(T)
        XtVinvX = copy(XtDinvX)
        @inbounds for k in 1:G
            σb² = exp(2 * ησb[k])
            Mk = 1 / σb² + S[k]
            invMk = 1 / Mk
            q2 += C[k]^2 * invMk
            logdetCap += log(1 + σb² * S[k])
            @inbounds for j in 1:pμ
                zj = ZtDinvX[k, j]
                @inbounds for l in 1:pμ
                    XtVinvX[j, l] -= zj * invMk * ZtDinvX[k, l]
                end
            end
        end
        nll_ml_θ = 0.5 * (logdetD + logdetCap + q1 - q2) + const_2pi
        # Same Woodbury-subtraction PSD hazard as `_fit_ranef_gaussian.nll_reml`
        # (#499): reject a non-PD Xμ′V⁻¹Xμ with a large FINITE barrier.
        cholXtVinvX = cholesky(Symmetric(XtVinvX); check=false)
        issuccess(cholXtVinvX) || return nll_ml_θ + T(REML_NONPD_PENALTY)
        return nll_ml_θ + 0.5 * logdet(cholXtVinvX) - const_pμ
    end

    nll = reml ? nll_reml : nll_ml

    βμ0 = Xμ \ y
    res0 = y - Xμ * βμ0
    θ0 = zeros(pμ + pσ + psd)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(res0) + eps())
    # Start the sd() submodel at the constant that matches the scalar route's
    # init: solve Zg α ≈ log(std(res0)/2) in least squares (robust to any
    # column coding; with Zg = ones(G,1) this is exactly the scalar init).
    θ0[pμ+pσ+1:end] .= Zg \ fill(log(std(res0) / 2 + eps()), G)

    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = _vcov_from_hessian(ForwardDiff.hessian(nll, θ̂))

    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :sd => (pμ+pσ+1):(pμ+pσ+psd)]
    names = [:mu => nmμ, :sigma => nmσ, :sd => nmsd]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    blup = let
        βμ = θ̂[1:pμ]; βσ = θ̂[pμ+1:pμ+pσ]; α = θ̂[pμ+pσ+1:end]
        ημ = Xμ * βμ; ησ = Xσ * βσ; ησb = Zg * α
        S = zeros(G); C = zeros(G)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i]); k = gidx[i]
            S[k] += invD
            C[k] += (y[i] - ημ[i]) * invD
        end
        [C[k] / (1 / exp(2 * ησb[k]) + S[k]) for k in 1:G]
    end
    re = Dict(Symbol(grp) => blup)
    fit = _withranef(_withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n,
                                     Optim.converged(res), means, obs, scales), nll_ml), re)
    if reml
        return _withreml(fit, -nll_reml(θ̂), -nll_ml(θ̂))
    end
    return fit
end
