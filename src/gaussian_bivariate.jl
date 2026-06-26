# gaussian_bivariate.jl — bivariate Gaussian location–scale with a
# predictor-dependent residual correlation ρ12 (fixed effects, ML). Mirrors
# drmTMB's bivariate Gaussian:
#
#   bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = …, sigma2 = …, rho12 = …)
#
# σ1, σ2 use a log link; ρ12 uses a tanh link (so its coefficients act on
# atanh ρ12, keeping ρ12 ∈ (-1, 1)).

"""
    BivariateDrmFormula

Two-response formula bundle (μ1, μ2, σ1, σ2, ρ12), built by the keyword form of
[`bf`](@ref).
"""
struct BivariateDrmFormula
    response1::Symbol
    response2::Symbol
    forms::Vector{Pair{Symbol,Any}}
end

_rhs_or_intercept(f) = f === nothing ? ConstantTerm(1) : f.rhs

# Validate a bivariate placeholder formula's LHS. The σ1/σ2/ρ12 formulas carry a
# *placeholder* left-hand side, so — mirroring the univariate rejection
# discipline (and drmTMB) — that placeholder must be the parameter's own name.
# `nothing` (the parameter omitted ⇒ `~ 1`) is always allowed.
function _check_bivariate_lhs(f, expected::Symbol)
    f === nothing && return f
    f isa FormulaTerm || throw(ArgumentError("bf: `$expected` must be a formula " *
        "`$expected ~ …` (got `$(repr(f))`)."))
    lhs = f.lhs
    lhs isa Term || throw(ArgumentError("bf: the `$expected` formula must read " *
        "`$expected ~ …` with the parameter name on the left (got `$lhs`)."))
    name = lhs.sym
    if name === :tau && (expected === :sigma1 || expected === :sigma2)
        throw(ArgumentError("bf: the scale parameter is named `sigma1`/`sigma2`, never " *
            "`tau` — write `$expected ~ …`."))
    elseif name !== expected
        throw(ArgumentError("bf: the `$expected` formula must read `$expected ~ …` " *
            "(got `$name ~ …`); in the bivariate keyword form each placeholder LHS " *
            "must be its own parameter name."))
    end
    return f
end

# The two mean formulas each name a single response column on the left. Reject a
# two-column `cbind(…)` (univariate-only) with a clear message rather than a
# cryptic `getproperty` error on a FunctionTerm.
function _bivariate_response_sym(f::FormulaTerm, kw::Symbol)
    f.lhs isa Term || throw(ArgumentError("bf: `$kw = response ~ …` needs a single " *
        "response column on the left (got `$(f.lhs)`); the bivariate form takes one " *
        "response per mean, not `cbind(…)`."))
    return f.lhs.sym
end

"""
    bf(; mu1, mu2, sigma1=…, sigma2=…, rho12=…)

Bivariate Gaussian formula bundle, mirroring drmTMB. `mu1 = y1 ~ …` and
`mu2 = y2 ~ …` set the two responses and their mean predictors; `sigma1`,
`sigma2` (log σ) and `rho12` (atanh ρ) default to `~ 1`. For one-sided
predictors give the parameter name as a placeholder LHS, e.g.
`sigma1 = @formula(sigma1 ~ x)`.

Like the univariate form, `bf` rejects reserved / mis-typed syntax: a placeholder
LHS that is not its own parameter name (e.g. `sigma1 = @formula(tau ~ x)` or a
swapped `sigma1`/`sigma2`), and a two-column `cbind(…)` response on `mu1`/`mu2`.
"""
function bf(; mu1::FormulaTerm, mu2::FormulaTerm, sigma1 = nothing, sigma2 = nothing, rho12 = nothing)
    _check_bivariate_lhs(sigma1, :sigma1)
    _check_bivariate_lhs(sigma2, :sigma2)
    _check_bivariate_lhs(rho12, :rho12)
    forms = Pair{Symbol,Any}[
        :mu1 => mu1.rhs,
        :mu2 => mu2.rhs,
        :sigma1 => _rhs_or_intercept(sigma1),
        :sigma2 => _rhs_or_intercept(sigma2),
        :rho12 => _rhs_or_intercept(rho12),
    ]
    return BivariateDrmFormula(_bivariate_response_sym(mu1, :mu1),
                               _bivariate_response_sym(mu2, :mu2), forms)
end

"""
    drm(formula::BivariateDrmFormula, Gaussian(); data, tree = nothing,
        K = nothing, A = nothing, coords = nothing, g_tol = 1e-8,
        q4_g_tol = 1e-3, q4_iterations = 300, q4_n_newton = 40,
        q4_vcov = true, method = :ML) -> DrmFit

Fit a bivariate Gaussian distributional regression model.

With no structured-effect marker, this is the residual-correlation model:
`mu1`, `mu2`, `sigma1`, `sigma2`, and residual `rho12` each have their own fixed
effect formula.

With matching structured markers on `mu1` and `mu2` only, this routes to the
q=2 exact-Gaussian ML point-fit cell. The q=2 route currently accepts
`phylo(1 | group)` with `tree`, `relmat(1 | group)` with `K`, or
`animal(1 | group)` with `A`; it requires complete responses, identical mean
fixed-effect designs, and intercept-only `sigma1`, `sigma2`, and `rho12`.
`spatial(1 | group)` remains outside the formula route here.

With the same `phylo(1 | group)` marker on all four location/scale predictors
(`mu1`, `mu2`, `sigma1`, and `sigma2`) and a supplied `tree`, this routes to the
verified q=4 phylogenetic location-scale engine. The residual `rho12` formula
remains the residual correlation; the group-level 4×4 covariance `Σ_a` is stored
as `fit.ranef.Sigma_a`, with axes `(:mu1, :mu2, :sigma1, :sigma2)`. Population
parameter prediction skips the internal `:phylocov` coefficient block.

```julia
fit = drm(
    bf(mu1 = @formula(y1 ~ x + phylo(1 | species)),
       mu2 = @formula(y2 ~ x + phylo(1 | species)),
       sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
       sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
       rho12 = @formula(rho12 ~ 1)),
    Gaussian();
    data = dat,
    tree = phy,
)
```
"""
function drm(f::BivariateDrmFormula, fam::Gaussian; data, tree = nothing,
             K = nothing, A = nothing, coords = nothing,
             g_tol::Real = 1e-8, q4_g_tol::Real = 1e-3,
             q4_iterations::Int = 300, q4_n_newton::Int = 40,
             q4_vcov::Bool = true, method::Symbol = :ML)
    method in (:ML, :REML) ||
        throw(ArgumentError("drm: `method` must be :ML (default) or :REML (got :$method)"))
    rhs = Dict(f.forms)
    fixed, structured_marker = _bivariate_q4_marker(rhs)
    if structured_marker !== nothing && structured_marker[1] === :phylo_q4
        return _fit_bivariate_q4_phylo(
            f, fam, data, fixed, structured_marker, tree;
            q4_g_tol = q4_g_tol,
            q4_iterations = q4_iterations,
            q4_n_newton = q4_n_newton,
            q4_vcov = q4_vcov,
            method = method,
        )
    elseif structured_marker !== nothing && structured_marker[1] === :structured_q2
        method === :REML &&
            throw(ArgumentError("drm: method = :REML is not implemented for the bivariate " *
                "q=2 structured residual-correlation route; use method = :ML."))
        coords === nothing ||
            throw(ArgumentError("drm: bivariate q=2 spatial(coords) is not implemented; use a known covariance relmat route or method = :ML native TMB."))
        return _fit_bivariate_q2_structured(
            f, fam, data, fixed, structured_marker, tree, K, A;
            g_tol = Float64(g_tol),
        )
    end
    # The residual-only bivariate route has no random effects / structured terms;
    # REML (Patterson–Thompson) is implemented only for the q=4 phylogenetic path,
    # so reject it here as the univariate core does (gaussian_core.jl:383-393).
    method === :REML &&
        throw(ArgumentError("drm: method = :REML is implemented only for the bivariate q=4 " *
            "phylogenetic location–scale engine (shared `phylo(1 | g)` on mu1, mu2, sigma1, " *
            "sigma2). The residual-only bivariate Gaussian model has no random effects; use " *
            "method = :ML (the default)."))
    return _fit_bivariate_residual(f, fam, data, rhs, g_tol)
end

function _fit_bivariate_residual(f::BivariateDrmFormula, fam::Gaussian, data, rhs, g_tol::Real)
    y1, X1, nm1 = _design(f.response1, rhs[:mu1], data)
    y2, X2, nm2 = _design(f.response2, rhs[:mu2], data)
    _, Xs1, nms1 = _design(f.response1, rhs[:sigma1], data)   # reuse a real LHS;
    _, Xs2, nms2 = _design(f.response1, rhs[:sigma2], data)   # only the matrix is kept
    _, Xr, nmr = _design(f.response1, rhs[:rho12], data)

    n = length(y1)
    obs1 = _observed_response_mask(y1)
    obs2 = _observed_response_mask(y2)
    n_like = count(obs1 .| obs2)
    n_like > 0 ||
        throw(ArgumentError("drm: at least one bivariate Gaussian response cell must be observed"))
    count(obs1) >= size(X1, 2) ||
        throw(ArgumentError("drm: observed `$(f.response1)` values are fewer than the mu1 coefficients"))
    count(obs2) >= size(X2, 2) ||
        throw(ArgumentError("drm: observed `$(f.response2)` values are fewer than the mu2 coefficients"))
    count(obs1 .& obs2) > 0 ||
        throw(ArgumentError("drm: at least one row must observe both bivariate Gaussian responses to estimate rho12"))

    ps = (size(X1, 2), size(X2, 2), size(Xs1, 2), size(Xs2, 2), size(Xr, 2))
    offs = cumsum([0, ps...])
    rng(k) = (offs[k]+1):offs[k+1]

    function nll(θ)
        b1 = θ[rng(1)]; b2 = θ[rng(2)]; bs1 = θ[rng(3)]; bs2 = θ[rng(4)]; br = θ[rng(5)]
        η1 = X1 * b1; η2 = X2 * b2; ls1 = Xs1 * bs1; ls2 = Xs2 * bs2; ηr = Xr * br
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            if obs1[i] && obs2[i]
                ρ = RHO_GUARD * tanh(ηr[i])    # guard ρ off ±1 (tanh saturates to ±1.0 in
                om = 1 - ρ * ρ                 # Float64 for large η → om=0 → NaN); matches the
                                               # q4 engine's RHO_GUARD + drmTMB's guarded link
                z1 = (y1[i] - η1[i]) * exp(-ls1[i])     # standardised residuals
                z2 = (y2[i] - η2[i]) * exp(-ls2[i])
                # −log φ₂ = log(2π) + (½ log|Σ|) + (½ rᵀΣ⁻¹r)
                s += log(2π) + ls1[i] + ls2[i] + 0.5 * log(om) +
                     0.5 * (z1 * z1 - 2ρ * z1 * z2 + z2 * z2) / om
            elseif obs1[i]
                z1 = (y1[i] - η1[i]) * exp(-ls1[i])
                s += 0.5 * log(2π) + ls1[i] + 0.5 * z1 * z1
            elseif obs2[i]
                z2 = (y2[i] - η2[i]) * exp(-ls2[i])
                s += 0.5 * log(2π) + ls2[i] + 0.5 * z2 * z2
            end
        end
        return s
    end

    θ0 = zeros(offs[end])
    X1_obs = Matrix{Float64}(X1[obs1, :])
    X2_obs = Matrix{Float64}(X2[obs2, :])
    y1_obs = Vector{Float64}(y1[obs1])
    y2_obs = Vector{Float64}(y2[obs2])
    β1 = X1_obs \ y1_obs
    β2 = X2_obs \ y2_obs
    θ0[rng(1)] .= β1
    θ0[rng(2)] .= β2
    θ0[offs[3]+1] = log(sqrt(mean((y1_obs - X1_obs * β1) .^ 2)) + eps())
    θ0[offs[4]+1] = log(sqrt(mean((y2_obs - X2_obs * β2) .^ 2)) + eps())     # ρ intercept starts at 0

    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    H = Matrix(Symmetric(ForwardDiff.hessian(nll, θ̂)))
    V0 = try
        inv(H)
    catch
        pinv(H)
    end
    V = Matrix(Symmetric((V0 + V0') / 2))

    blocks = [:mu1 => rng(1), :mu2 => rng(2), :sigma1 => rng(3), :sigma2 => rng(4), :rho12 => rng(5)]
    names = [:mu1 => nm1, :mu2 => nm2, :sigma1 => nms1, :sigma2 => nms2, :rho12 => nmr]
    means = Dict(:mu1 => X1 * θ̂[rng(1)], :mu2 => X2 * θ̂[rng(2)])
    obs = Dict(:mu1 => Vector{Float64}(y1), :mu2 => Vector{Float64}(y2))
    scales = Dict(:sigma1 => exp.(Xs1 * θ̂[rng(3)]),
                  :sigma2 => exp.(Xs2 * θ̂[rng(4)]),
                  :rho12 => RHO_GUARD .* tanh.(Xr * θ̂[rng(5)]))   # report the model's guarded ρ
    return _withformula(_withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n_like, Optim.converged(res), means, obs, scales), nll), f)
end

function _bivariate_q4_marker(rhs)
    params = (:mu1, :mu2, :sigma1, :sigma2)
    fixed = Dict{Symbol,Any}()
    markers = Dict{Symbol,Any}()
    for p in params
        fixed_p, structured = _split_bivariate_q4_rhs(rhs[p], p)
        fixed[p] = fixed_p
        structured !== nothing && (markers[p] = structured)
    end
    fixed_rho, re_rho, metav_rho, structured_rho = _split_ranef(rhs[:rho12])
    isempty(re_rho) || error("`rho12` is the residual-correlation formula and cannot contain random-effect terms")
    metav_rho === nothing || error("`rho12` is the residual-correlation formula and cannot contain `meta_V`")
    structured_rho === nothing || error("`rho12` is the residual correlation; group-level coevolution lives in the shared `phylo` block on mu1/mu2/sigma1/sigma2")
    fixed[:rho12] = fixed_rho

    isempty(markers) && return fixed, nothing
    marker_keys = Set(keys(markers))
    if marker_keys == Set((:mu1, :mu2))
        marker_vals = [markers[p] for p in (:mu1, :mu2)]
        kind = marker_vals[1][1]
        kind in (:phylo, :relmat, :animal) ||
            error("the bivariate q=2 front end currently supports only `phylo(...)`, `relmat(...)`, or `animal(...)` markers")
        all(m -> m[1] === kind, marker_vals) ||
            error("the q=2 structured markers on mu1 and mu2 must use the same structured type")
        groups = [m[2] for m in marker_vals]
        all(==(groups[1]), groups) ||
            error("the q=2 structured markers on mu1 and mu2 must use the same grouping variable")
        tags = [m[3] for m in marker_vals]
        (all(isnothing, tags) || (tags[1] == tags[2])) ||
            error("the q=2 structured markers on mu1 and mu2 must share the same correlation tag")
        return fixed, (:structured_q2, kind, groups[1])
    end
    length(markers) == length(params) ||
        error("bivariate phylogenetic Julia fits require either q=2 phylo on mu1 and mu2 only, or q=4 phylo on mu1, mu2, sigma1, and sigma2")
    marker_vals = [markers[p] for p in params]   # one (kind, group, tag) per axis
    all(m -> m[1] === :phylo, marker_vals) ||
        error("the bivariate q=4 front end currently supports only `phylo(...)` markers")
    groups = [m[2] for m in marker_vals]
    all(==(groups[1]), groups) ||
        error("the q=4 phylogenetic markers on mu1, mu2, sigma1, and sigma2 must use the same grouping variable")
    tags = [m[3] for m in marker_vals]           # axis order: mu1, mu2, sigma1, sigma2
    lc_zero = _q4_block_lc_zero(tags)
    return fixed, (:phylo_q4, groups[1], lc_zero)
end

# Translate the per-axis correlation tags into the set of log-Cholesky indices to
# pin at 0 so Σ_a is block-diagonal across distinct tags.
#
# Axis order = (mu1, mu2, sigma1, sigma2) = Σ_a rows/cols 1..4. The 10-vec lc is
# the column-major lower triangle of the Cholesky factor C (lc_to_Λ): index→(i,j)
#   1→(1,1) 2→(2,1) 3→(3,1) 4→(4,1) 5→(2,2) 6→(3,2) 7→(4,2) 8→(3,3) 9→(4,3) 10→(4,4)
# Zeroing every off-diagonal C[i,j] (i>j) whose two axes carry DIFFERENT tags
# makes C block-lower-triangular within each tag-group ⇒ C C' is exactly
# block-diagonal (the cross-tag covariance is identically 0).
#
# All-`nothing` tags (every axis written `phylo(1 | group)`) ⇒ spec E, the full
# correlated 4×4 Σ_a ⇒ `lc_zero = Int[]` (no constraint). A mix of tagged and
# untagged axes is rejected (ambiguous block membership).
function _q4_block_lc_zero(tags)
    all(isnothing, tags) && return Int[]
    any(isnothing, tags) &&
        error("the q=4 block-diagonal form needs a correlation tag on EVERY axis: " *
              "write `phylo(1 | tag | group)` on mu1, mu2, sigma1, sigma2 (got a mix " *
              "of tagged and untagged markers)")
    # column-major lower-tri (i, j) for each lc index 1..10
    ij = [(1,1),(2,1),(3,1),(4,1),(2,2),(3,2),(4,2),(3,3),(4,3),(4,4)]
    lc_zero = Int[]
    for (k, (i, j)) in enumerate(ij)
        i == j && continue                 # never pin a diagonal (block variances)
        tags[i] == tags[j] || push!(lc_zero, k)
    end
    return lc_zero
end

function _split_bivariate_q4_rhs(rhs, param::Symbol)
    terms = rhs isa Tuple ? collect(rhs) : Any[rhs]
    fixed = Any[]
    structured = nothing
    for t in terms
        if t isa FunctionTerm && t.f === (|)
            error("bivariate q=4 phylogenetic fits support only `phylo(1 | group)` markers, not ordinary random effects")
        elseif t isa FunctionTerm && t.f === meta_V
            error("bivariate q=4 phylogenetic fits do not support `meta_V` markers")
        elseif t isa FunctionTerm && (t.f === relmat || t.f === animal || t.f === phylo || t.f === spatial)
            structured === nothing ||
                error("`$param` contains multiple structured markers; the q=4 front end accepts exactly one `phylo(1 | group)` marker per predictor")
            grp, tag = _q4_marker_group(t, param)
            structured = (_structured_marker_kind(t), grp, tag)
        else
            push!(fixed, t)
        end
    end
    fixed_rhs = isempty(fixed) ? ConstantTerm(1) :
                length(fixed) == 1 ? fixed[1] : Tuple(fixed)
    return fixed_rhs, structured
end

# Parse the inner term of a structured q=4 marker. Returns `(group, tag)` where
# `tag` is `nothing` for the 2-arg `phylo(1 | group)` (spec E, one shared 4×4 Σ_a)
# or the correlation-group symbol for the 3-arg `phylo(1 | tag | group)` (spec D,
# block-diagonal Σ_a — axes sharing a `tag` form one block). Julia parses
# `1 | tag | group` left-associatively as `|(|(1, tag), group)`.
function _q4_marker_group(t, param::Symbol)
    inner = t.args[1]
    inner isa FunctionTerm && inner.f === (|) ||
        error("`$param` structured marker must be written as `phylo(1 | group)` or `phylo(1 | tag | group)`")
    if inner.args[1] isa FunctionTerm && inner.args[1].f === (|)
        # 3-arg tagged form: |(|(1, tag), group)
        coef = inner.args[1].args[1]
        (coef isa ConstantTerm && coef.n == 1) ||
            error("`$param` uses `$(_structured_marker_kind(t))`, but the bivariate q=4 front end supports only intercept markers (`phylo(1 | tag | group)`)")
        inner.args[1].args[2] isa Term ||
            error("`$param` correlation tag must be a bare symbol in `phylo(1 | tag | group)`")
        inner.args[2] isa Term ||
            error("`$param` group must be a bare grouping variable in `phylo(1 | tag | group)`")
        return inner.args[2].sym, inner.args[1].args[2].sym
    end
    # 2-arg form: |(1, group)
    length(inner.args) == 2 && inner.args[2] isa Term ||
        error("`$param` structured marker must be written as `phylo(1 | group)` or `phylo(1 | tag | group)`")
    lhs = inner.args[1]
    (lhs isa ConstantTerm && lhs.n == 1) ||
        error("`$param` uses `$(_structured_marker_kind(t))`, but the bivariate q=4 front end supports only intercept markers (`phylo(1 | group)`)")
    return inner.args[2].sym, nothing
end

function _structured_marker_kind(t)
    t.f === relmat && return :relmat
    t.f === animal && return :animal
    t.f === phylo && return :phylo
    t.f === spatial && return :spatial
    error("unsupported structured marker")
end

function _fit_bivariate_q2_structured(f::BivariateDrmFormula, fam::Gaussian, data,
                                      fixed, marker, tree, K, A;
                                      g_tol::Float64)
    marker[1] === :structured_q2 || error("internal error: expected q2 structured marker")
    kind = marker[2]
    grp = marker[3]
    y1, X1, nm1 = _design(f.response1, fixed[:mu1], data)
    y2, X2, nm2 = _design(f.response2, fixed[:mu2], data)
    _, Xs1, nms1 = _design(f.response1, fixed[:sigma1], data)
    _, Xs2, nms2 = _design(f.response1, fixed[:sigma2], data)
    _, Xr, nmr = _design(f.response1, fixed[:rho12], data)
    all(isfinite, y1) && all(isfinite, y2) ||
        throw(ArgumentError("drm: bivariate q=2 structured Julia route currently requires complete responses"))
    size(Xs1, 2) == 1 && size(Xs2, 2) == 1 && size(Xr, 2) == 1 ||
        throw(ArgumentError("drm: bivariate q=2 structured Julia route currently supports intercept-only sigma1, sigma2, and rho12 formulas"))

    Y = hcat(Vector{Float64}(y1), Vector{Float64}(y2))
    size(X2, 2) == size(X1, 2) && X2 ≈ X1 ||
        throw(ArgumentError("drm: bivariate q=2 structured Julia route currently requires mu1 and mu2 to use the same fixed-effect design"))

    group_values = getproperty(data, grp)
    gidx, G = _group_index(group_values)
    phy = nothing
    species = Int[]
    prob, Q_cond = if kind === :phylo
        tree === nothing && error("phylo(1 | $grp) needs `tree = …`")
        phy_obj = _as_augmented_phy(tree)
        sp = _phylo_species_index(phy_obj, group_values)
        phy = phy_obj
        species = sp
        make_coevo_problem(phy_obj, Y, Matrix{Float64}(X1); species = sp)
    elseif kind === :relmat
        K === nothing && error("relmat(1 | $grp) needs `K = …`")
        C = Matrix{Float64}(K)
        size(C) == (G, G) || error("relmat structured matrix must be $(G)×$(G) (the number of `$grp` levels)")
        make_coevo_problem_from_covariance(C, Y, Matrix{Float64}(X1); group = gidx)
    elseif kind === :animal
        A === nothing && error("animal(1 | $grp) needs `A = …`")
        C = Matrix{Float64}(A)
        size(C) == (G, G) || error("animal relatedness matrix must be $(G)×$(G) (the number of `$grp` levels)")
        make_coevo_problem_from_covariance(C, Y, Matrix{Float64}(X1); group = gidx)
    else
        error("internal error: unsupported q2 structured marker `$kind`")
    end

    β0 = hcat(X1 \ y1, X2 \ y2)
    r1 = y1 .- X1 * β0[:, 1]
    r2 = y2 .- X2 * β0[:, 2]
    ρ0 = if std(r1) > 0 && std(r2) > 0
        clamp(cor(r1, r2), -0.5, 0.5)
    else
        0.0
    end
    fit_q2 = fit_coevolution_q2_residual(
        prob,
        Q_cond;
        β0 = β0,
        Λ0 = Matrix(Symmetric([0.25 0.02; 0.02 0.25])),
        σ0 = [std(r1) + eps(), std(r2) + eps()],
        rho0 = ρ0,
        g_tol = g_tol,
        iterations = 300,
    )

    k = size(X1, 2)
    blocks = [
        :mu1 => 1:k,
        :mu2 => (k + 1):(2k),
        :sigma1 => (2k + 1):(2k + 1),
        :sigma2 => (2k + 2):(2k + 2),
        :rho12 => (2k + 3):(2k + 3),
        :phylocov => (2k + 4):(2k + 6),
    ]
    names = [
        :mu1 => nm1,
        :mu2 => nm2,
        :sigma1 => nms1,
        :sigma2 => nms2,
        :rho12 => nmr,
        :phylocov => _q2_phylocov_names(),
    ]
    θ̂ = vcat(
        fit_q2.β[:, 1],
        fit_q2.β[:, 2],
        log(fit_q2.σ_res[1]),
        log(fit_q2.σ_res[2]),
        atanh(fit_q2.rho12 / RHO_GUARD),
        cov_to_lc(fit_q2.Λ),
    )
    V = fill(NaN, length(θ̂), length(θ̂))
    means = Dict(:mu1 => X1 * fit_q2.β[:, 1], :mu2 => X2 * fit_q2.β[:, 2])
    obs = Dict(:mu1 => Vector{Float64}(y1), :mu2 => Vector{Float64}(y2))
    scales = Dict(
        :sigma1 => fill(fit_q2.σ_res[1], length(y1)),
        :sigma2 => fill(fit_q2.σ_res[2], length(y1)),
        :rho12 => fill(fit_q2.rho12, length(y1)),
    )

    all_blups = reshape(Vector{Float64}(fit_q2.u_hat), 2, prob.N)
    blups = if kind === :phylo
        keep = setdiff(1:phy.n_total, [phy.root_index])
        node_pos = Dict(node => i for (i, node) in enumerate(keep))
        leaf_pos = [node_pos[phy.leaf_indices[k]] for k in 1:phy.n_leaves]
        all_blups[:, leaf_pos]
    else
        all_blups
    end
    re = (;
        effects = Dict(Symbol(grp) => blups),
        Sigma_a = Matrix{Float64}(fit_q2.Λ),
        axes = (:mu1, :mu2),
        structured_type = kind,
        Q_cond = Q_cond,
        phy = phy,
        group = grp,
        group_index = gidx,
        species = species,
        prob = prob,
    )
    nll = function (θ)
        β = hcat(θ[blocks[1].second], θ[blocks[2].second])
        Λ = lc_to_cov(θ[blocks[6].second], 2)
        σ1 = exp(θ[blocks[3].second][1])
        σ2 = exp(θ[blocks[4].second][1])
        ρ = RHO_GUARD * tanh(θ[blocks[5].second][1])
        D = Matrix(Symmetric([σ1^2 ρ * σ1 * σ2; ρ * σ1 * σ2 σ2^2]))
        ℓ, = coevo_marginal_cov(prob, Q_cond, β, Λ, D)
        return -ℓ
    end
    fit = DrmFit(fam, blocks, names, θ̂, V, fit_q2.loglik, length(y1),
                 fit_q2.converged, means, obs, scales)
    return _withranef(_withformula(_withnll(fit, nll), f), re)
end

function _fit_bivariate_q4_phylo(f::BivariateDrmFormula, fam::Gaussian, data, fixed, marker, tree;
                                 q4_g_tol::Real, q4_iterations::Int,
                                 q4_n_newton::Int, q4_vcov::Bool, method::Symbol = :ML)
    marker[1] === :phylo_q4 || error("internal error: expected q4 phylo marker")
    grp = marker[2]
    lc_zero = length(marker) >= 3 ? marker[3] : Int[]   # block-diagonal Σ_a pins
    tree === nothing && error("phylo(1 | $grp) needs `tree = …`")
    phy = _as_augmented_phy(tree)

    y1, X1, nm1 = _design(f.response1, fixed[:mu1], data)
    y2, X2, nm2 = _design(f.response2, fixed[:mu2], data)
    _, Xs1, nms1 = _design(f.response1, fixed[:sigma1], data)
    _, Xs2, nms2 = _design(f.response1, fixed[:sigma2], data)
    _, Xr, nmr = _design(f.response1, fixed[:rho12], data)
    # #19: missing responses are supported via a per-cell observed mask — observed
    # cells enter the likelihood, the full tree is kept. make_problem records the mask
    # (NaN ⇒ missing) and zeroes the missing values; here we only guard identifiability
    # and seed the optimiser from the OBSERVED rows.
    obs1 = _observed_response_mask(y1)
    obs2 = _observed_response_mask(y2)
    (count(obs1) >= size(X1, 2) && count(obs2) >= size(X2, 2)) ||
        throw(ArgumentError("drm: too few observed `$(f.response1)`/`$(f.response2)` rows " *
            "for the bivariate q=4 mean coefficients"))

    species = _phylo_species_index(phy, getproperty(data, grp))
    prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr; species = species)

    β1 = X1[obs1, :] \ y1[obs1]        # seed from observed rows (X1 \ y1 would be NaN)
    β2 = X2[obs2, :] \ y2[obs2]
    res1 = y1[obs1] .- X1[obs1, :] * β1
    res2 = y2[obs2] .- X2[obs2, :] * β2
    β0 = (
        mu1 = β1,
        mu2 = β2,
        s1 = _initial_scale_beta(Xs1, res1),
        s2 = _initial_scale_beta(Xs2, res2),
        rho = zeros(size(Xr, 2)),
    )
    Λ0 = Matrix(Symmetric([
        0.30 0.02 0.01 0.010
        0.02 0.30 0.01 0.010
        0.01 0.01 0.08 0.005
        0.01 0.01 0.005 0.080
    ]))
    if !isempty(lc_zero)
        # Block-diagonal start so Λ_to_lc(Λ0) already has 0 in the pinned cross
        # entries (an arbitrary cross block would make the constrained start
        # inconsistent). Zero the mu↔sigma cross block; keep the within-block
        # 2×2 covariances. For the general tag layout this is exact because the
        # only pinned entries are mu↔sigma cross terms (axes 1,2 vs 3,4).
        Λ0[1:2, 3:4] .= 0.0
        Λ0[3:4, 1:2] .= 0.0
    end
    reml_ll = NaN
    ml_ll = NaN
    if method === :REML
        # REML (Patterson–Thompson): β_μ profiled out via the bordered augmented
        # state; fit_q4_reml warm-starts from an internal ML fit. We rebuild a
        # unified `r` so the DrmFit construction below is identical to the ML path.
        rr = fit_q4_reml(
            prob, Q_cond;
            beta0 = β0,
            Lambda0 = Λ0,
            g_tol = Float64(q4_g_tol),
            iterations = q4_iterations,
            n_newton = q4_n_newton,
            lc_zero = lc_zero,
        )
        β_reml = (mu1 = rr.beta.mu1, mu2 = rr.beta.mu2,
                  s1 = rr.beta.s1, s2 = rr.beta.s2, rho = rr.beta.rho)
        θ_reml = pack_theta(β_reml, rr.Lambda)   # full 17-vec θ̂ (β + log-Cholesky Λ)
        reml_ll = rr.reml_loglik
        ml_ll = rr.ml_loglik
        r = (θ = θ_reml, β = β_reml, Λ = Matrix(rr.Lambda),
             loglik = rr.reml_loglik, converged = rr.converged)
    else
        r = fit_q4_sparse_tmb(
            prob, Q_cond;
            β0 = β0,
            Λ0 = Λ0,
            g_tol = Float64(q4_g_tol),
            iterations = q4_iterations,
            n_newton = q4_n_newton,
            lc_zero = lc_zero,
        )
    end

    k1, k2, ks1, ks2, kr = beta_widths(prob)
    offs = cumsum([0, k1, k2, ks1, ks2, kr, 10])
    rng(k) = (offs[k] + 1):offs[k + 1]
    blocks = [
        :mu1 => rng(1),
        :mu2 => rng(2),
        :sigma1 => rng(3),
        :sigma2 => rng(4),
        :rho12 => rng(5),
        :phylocov => rng(6),
    ]
    names = [
        :mu1 => nm1,
        :mu2 => nm2,
        :sigma1 => nms1,
        :sigma2 => nms2,
        :rho12 => nmr,
        :phylocov => _q4_phylocov_names(),
    ]
    θ̂ = Vector{Float64}(r.θ)
    nll(θ) = marginal_nll(prob, Q_cond, Vector{Float64}(θ); n_newton = q4_n_newton)[1]
    nllgrad! = function (g, θ)
        _, gg, _, _ = marginal_and_exact_grad(prob, Q_cond, Vector{Float64}(θ); n_newton = q4_n_newton)
        copyto!(g, gg)
        return g
    end
    # V is the ML observed-information vcov (FD of the marginal ML NLL) evaluated
    # at θ̂. Under method = :REML this is θ̂_reml, so V is the ML curvature at the
    # REML point; the restricted-penalty curvature (−0.5·∂²logdet S/∂θ²) is
    # omitted, mirroring the q=2 σ-phylo REML route (gaussian_locscale_phylo.jl).
    V = q4_vcov ? _q4_fd_vcov(prob, Q_cond, θ̂; n_newton = q4_n_newton) :
        fill(NaN, length(θ̂), length(θ̂))

    β̂ = r.β
    means = Dict(:mu1 => X1 * β̂.mu1, :mu2 => X2 * β̂.mu2)
    obs = Dict(:mu1 => Vector{Float64}(y1), :mu2 => Vector{Float64}(y2))
    scales = Dict(
        :sigma1 => exp.(Xs1 * β̂.s1),
        :sigma2 => exp.(Xs2 * β̂.s2),
        :rho12 => RHO_GUARD .* tanh.(Xr * β̂.rho),   # report the model's guarded ρ (engine uses RHO_GUARD)
    )
    _, u_hat, _, _ = marginal_nll(prob, Q_cond, θ̂; n_newton = q4_n_newton)
    all_blups = reshape(Vector{Float64}(u_hat), 4, prob.n_total)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    node_pos = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [node_pos[phy.leaf_indices[k]] for k in 1:phy.n_leaves]
    blups = all_blups[:, leaf_pos]
    re = (;
        effects = Dict(Symbol(grp) => blups),
        Sigma_a = Matrix{Float64}(r.Λ),
        axes = (:mu1, :mu2, :sigma1, :sigma2),
        Q_cond = Q_cond,
        phy = phy,
        group = grp,
        species = species,
        prob = prob,                 # AugProblem — lets profile_sigma_a re-optimise the marginal
        n_newton = q4_n_newton,      # the inner-mode iteration count this fit used
    )
    fit = DrmFit(fam, blocks, names, θ̂, V, r.loglik, length(y1), r.converged, means, obs, scales)
    fit = method === :REML ? _withreml(fit, reml_ll, ml_ll) : fit
    return _withranef(_withformula(_withnll(fit, nll, nllgrad!), f), re)
end

_as_augmented_phy(tree::AugmentedPhy) = tree
_as_augmented_phy(tree::AbstractString) = augmented_phy(tree)
_as_augmented_phy(tree) = error("tree must be an AugmentedPhy or Newick string for bivariate q=4 phylogenetic fits")

function _phylo_species_index(phy::AugmentedPhy, labels)
    length(labels) > 0 || error("phylo grouping column is empty")
    if all(l -> l isa Integer, labels)
        idx = Int.(labels)
        all(i -> 1 <= i <= phy.n_leaves, idx) ||
            error("integer phylo group labels must be in 1:$(phy.n_leaves)")
        return idx
    end
    name_to_idx = Dict(name => i for (i, name) in enumerate(phy.leaf_names))
    idx = Vector{Int}(undef, length(labels))
    for (i, label) in enumerate(labels)
        key = String(label)
        haskey(name_to_idx, key) ||
            error("phylo group label `$key` is not present in the tree tip names")
        idx[i] = name_to_idx[key]
    end
    return idx
end

function _initial_scale_beta(X, residual)
    y = fill(log(std(residual) + eps()), size(X, 1))
    return X \ y
end

function _q4_phylocov_names()
    ["Sigma_a:L11", "Sigma_a:L21", "Sigma_a:L31", "Sigma_a:L41", "Sigma_a:L22",
     "Sigma_a:L32", "Sigma_a:L42", "Sigma_a:L33", "Sigma_a:L43", "Sigma_a:L44"]
end

_q2_phylocov_names() = ["Sigma_a:L11", "Sigma_a:L21", "Sigma_a:L22"]

function _q4_fd_vcov(prob::AugProblem, Q_cond::SparseMatrixCSC, θ::Vector{Float64};
                     h::Real = 1e-4, n_newton::Int = 40)
    nθ = length(θ)
    H = zeros(nθ, nθ)
    for k in 1:nθ
        θp = copy(θ); θp[k] += h
        θm = copy(θ); θm[k] -= h
        _, gp, _, _ = marginal_and_exact_grad(prob, Q_cond, θp; n_newton = n_newton)
        _, gm, _, _ = marginal_and_exact_grad(prob, Q_cond, θm; n_newton = n_newton)
        H[:, k] .= (gp .- gm) ./ (2h)
    end
    H = Matrix(Symmetric((H + H') / 2))
    invH = try
        inv(H)
    catch
        pinv(H)
    end
    return Matrix(Symmetric((invH + invH') / 2))
end
