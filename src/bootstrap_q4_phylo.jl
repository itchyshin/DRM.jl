# Parametric bootstrap of the q=4 phylogenetic location–scale among-axis SDs.
#
# The single-tree complement to Ayumi's across-tree sweep. A bivariate q=4
# σ-phylo fit reports the 4×4 among-axis covariance Σ_a; its diagonal SDs
# sqrt.(diag(Σ_a)) for axes (μ1, μ2, σ1, σ2) are the quantities of interest
# ("is there phylogenetic signal in this trait's mean / in its variance?").
# When an axis collapses the boundary makes a Wald SE or a profile singular
# (profile_result → SingularException) — so neither gives an honest interval.
#
# This bootstrap does: each replicate redraws tip random effects from the fitted
# N(0, Q_cond⁻¹ ⊗ Σ̂_a) on the SAME tree (the exact precision-Cholesky draw the
# verified `simulate_coevolution` uses), adds them to the fitted fixed effects on
# all four axes, regenerates (y1, y2) with the fitted residual ρ12, refits the
# verified q=4 engine, and records sqrt.(diag(Σ̂_a)). Percentile CIs respect the
# SD ≥ 0 boundary automatically: a collapsing axis yields an interval whose lower
# end sits at ~0 — the honest "no detectable phylogenetic signal in that axis".

"""
    bootstrap_sigma_a(fit; data, B = 300, level = 0.95, rng = default_rng(),
                      failures = :warn, check_converged = true,
                      q4_g_tol = 1e-3, q4_iterations = 300) -> NamedTuple

Parametric bootstrap of the among-axis standard deviations `sqrt.(diag(Σ_a))`
for a bivariate q=4 phylogenetic location–scale fit
(`drm(bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…), Gaussian(); tree = …)`).

Returns a `NamedTuple` with

- `summary` — a vector of rows `(param, coef, estimate, std_error, lower, upper)`
  for `param ∈ (:sd_mu1, :sd_mu2, :sd_sigma1, :sd_sigma2)`. `estimate` is the
  fitted SD; `lower`/`upper` are the `level` percentile interval over the
  successful replicates.
- `attempted`, `used`, `failed`, `failures`, `level`, `draws` (the `used × 4`
  matrix of replicate SDs), `axes`, `elapsed`.

The interval is the honest report at a boundary: when a scale axis carries no
phylogenetic signal its SD collapses and the percentile interval includes ~0,
where the Hessian-based SE / profile is undefined. `data` must be the table the
fit was estimated on (the covariate / grouping columns are reused; the two
response columns are overwritten per replicate).

With `failures = :warn` (default) failed refits are dropped and reported in
`failures`; `failures = :error` rethrows on the first failure.
"""
function bootstrap_sigma_a(fit::DrmFit; data, B::Int = 300, level::Real = 0.95,
                           rng = Random.default_rng(), failures::Symbol = :warn,
                           check_converged::Bool = true,
                           q4_g_tol::Real = 1e-3, q4_iterations::Int = 300)
    re = fit.ranef
    (re isa NamedTuple && haskey(re, :Sigma_a) && haskey(re, :Q_cond) &&
     haskey(re, :phy) && haskey(re, :species)) || throw(ArgumentError(
        "bootstrap_sigma_a requires a bivariate q=4 phylogenetic fit " *
        "(fit.ranef with Sigma_a / Q_cond / phy / species)"))
    fit.formula isa BivariateDrmFormula || throw(ArgumentError(
        "bootstrap_sigma_a requires a BivariateDrmFormula fit created by drm"))
    B >= 1 || throw(ArgumentError("bootstrap requires B >= 1"))
    (failures === :warn || failures === :error) ||
        throw(ArgumentError("failures must be :warn or :error"))
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))

    Σa = Matrix{Float64}(re.Sigma_a)
    Q_cond = re.Q_cond
    phy = re.phy
    species = collect(Int, re.species)
    form = fit.formula
    fam = fit.family

    # Fixed (RE-free) parts per observation. fit.means/scales hold Xβ only (no
    # BLUP); log σ axes are recovered as log of the reported σ.
    μ1f = Vector{Float64}(fit.means[:mu1])
    μ2f = Vector{Float64}(fit.means[:mu2])
    logσ1f = log.(Vector{Float64}(fit.scales[:sigma1]))
    logσ2f = log.(Vector{Float64}(fit.scales[:sigma2]))
    ρ = Vector{Float64}(fit.scales[:rho12])
    n = length(μ1f)

    # leaf → augmented-node position, EXACTLY as the fit extracted its BLUPs
    # (gaussian_bivariate.jl) — guarantees consistency with this re.Q_cond.
    keep = setdiff(1:phy.n_total, [phy.root_index])
    node_pos = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [node_pos[phy.leaf_indices[k]] for k in 1:phy.n_leaves]

    Fchol = _q4_re_prior_chol(Q_cond, Σa)
    cols0 = Tables.columntable(data)

    axes = (:sd_mu1, :sd_mu2, :sd_sigma1, :sd_sigma2)
    est = sqrt.(max.(diag(Σa), 0.0))
    draws = Matrix{Float64}(undef, B, 4)
    ok = falses(B)
    messages = Vector{Union{Nothing,String}}(nothing, B)
    seeds = rand(rng, UInt, B)

    function run_one!(b)
        rr = Random.MersenneTwister(seeds[b])
        try
            u = Fchol.UP \ randn(rr, size(Fchol, 1))
            U = reshape(u, 4, :)            # 4 × length(keep), axis-inner
            Uleaf = U[:, leaf_pos]          # 4 × n_leaves
            μ1 = μ1f .+ Uleaf[1, species]
            μ2 = μ2f .+ Uleaf[2, species]
            σ1 = exp.(logσ1f .+ Uleaf[3, species])
            σ2 = exp.(logσ2f .+ Uleaf[4, species])
            e1 = randn(rr, n)
            e2 = randn(rr, n)
            y1 = μ1 .+ σ1 .* e1
            y2 = μ2 .+ σ2 .* (ρ .* e1 .+ sqrt.(max.(1 .- ρ .^ 2, 0.0)) .* e2)
            datab = merge(cols0,
                          NamedTuple{(form.response1, form.response2)}((y1, y2)))
            fitb = drm(form, fam; data = datab, tree = phy,
                       q4_g_tol = q4_g_tol, q4_iterations = q4_iterations,
                       q4_vcov = false)
            (!check_converged || is_converged(fitb)) ||
                error("refit did not converge")
            draws[b, :] = sqrt.(max.(diag(Matrix{Float64}(fitb.ranef.Sigma_a)), 0.0))
            ok[b] = true
        catch err
            messages[b] = sprint(showerror, err)
        end
        return nothing
    end

    elapsed = @elapsed for b in 1:B
        run_one!(b)
    end

    failure_rows = NamedTuple{(:replicate, :seed, :message),Tuple{Int,UInt,String}}[]
    for b in 1:B
        messages[b] === nothing && continue
        push!(failure_rows, (replicate = b, seed = seeds[b], message = messages[b]::String))
    end
    if !isempty(failure_rows) && failures === :error
        f = first(failure_rows)
        throw(ErrorException("bootstrap_sigma_a failed in $(length(failure_rows)) of " *
            "$B replicates; first failure replicate $(f.replicate), seed $(f.seed): $(f.message)"))
    end
    used = count(ok)
    used > 0 || throw(ErrorException("all $B bootstrap_sigma_a replicates failed"))

    used_draws = draws[ok, :]
    α = (1 - level) / 2
    summary = NamedTuple{(:param, :coef, :estimate, :std_error, :lower, :upper),
                         Tuple{Symbol,String,Float64,Float64,Float64,Float64}}[]
    for a in 1:4
        col = @view used_draws[:, a]
        push!(summary, (param = axes[a], coef = String(axes[a]), estimate = est[a],
                        std_error = Statistics.std(col),
                        lower = Statistics.quantile(col, α),
                        upper = Statistics.quantile(col, 1 - α)))
    end

    return (summary = summary, failures = failure_rows, attempted = B, used = used,
            failed = length(failure_rows), seeds = seeds, level = level,
            draws = used_draws, axes = axes, elapsed = elapsed)
end

# Cholesky of the tip-RE prior precision kron(Q_cond, Σ_a⁻¹). Σ_a may be near
# singular at a σ-collapse; add a vanishing ridge only if the bare inverse fails,
# so the common path is byte-identical to the engine's own prior_precision draw.
function _q4_re_prior_chol(Q_cond, Σa::AbstractMatrix)
    Σ = Matrix{Float64}(Σa)
    for ridge in (0.0, 1e-10, 1e-8, 1e-6)
        Σr = ridge == 0.0 ? Σ : Σ + ridge * I
        try
            P = prior_precision(Q_cond, inv(Symmetric(Σr)))
            return cholesky(Symmetric(P))
        catch
            continue
        end
    end
    error("bootstrap_sigma_a: could not form a positive-definite tip-RE prior " *
          "precision from Σ_a (an axis is fully collapsed); try fewer axes")
end
