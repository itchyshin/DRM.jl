# gaussian_structured.jl — Gaussian structured random effects on the mean with a
# KNOWN relatedness matrix. A structured intercept u ~ N(0, σ_s² K) leaves the
# marginal exactly Gaussian:
#     y ~ N(Xβ, D + σ_s² Z K Zᵀ),   D = diag(σ_i²),  Z the group indicator,
# fit in closed form (PGLS-style) via the matrix-determinant lemma + Woodbury:
#   logdet(V) = logdet(D) + G·log σ_s² + logdet(K) + logdet(M),
#   rᵀV⁻¹r    = rᵀD⁻¹r − Cᵀ M⁻¹ C,   M = (1/σ_s²)K⁻¹ + ZᵀD⁻¹Z (diagonal part).
# `relmat(1 | id)` supplies K directly; `animal()` / `phylo()` / `spatial()`
# reuse this engine with K from a pedigree / tree / coordinates.

using LinearAlgebra: cholesky, Symmetric, Diagonal, dot, logdet, inv, diag

"""
    relmat(1 | id)

Structured random-intercept marker with a user-supplied relatedness matrix:

```julia
drm(bf(y ~ x + relmat(1 | id), sigma ~ 1), Gaussian(); data, K = K)
```

`K` is the correlation/relatedness matrix over the levels of `id`, ordered as
they first appear in `data`. The marginal stays Gaussian (closed-form).
"""
relmat(x) = x   # marker; intercepted during formula parsing

"""
    animal(1 | id)

Animal-model structured random intercept. Supply the additive-relatedness matrix
over the levels of `id` via `drm(...; A = A)`. Reuses the closed-form
structured-Gaussian engine (same as [`relmat`](@ref)).
"""
animal(x) = x

"""
    phylo(1 | species)

Phylogenetic structured random intercept on the Gaussian **mean**: pass the tree
via `drm(...; tree = tree)` (an `AugmentedPhy` from `random_balanced_tree` /
`augmented_phy`, or a Newick string). The phylogenetic correlation is built from
the tree (`sigma_phy_dense`) and the marginal is fit in closed form. (The q=4
phylogenetic *location-scale* model — a structured effect on `log σ` too — uses
the verified sparse-Laplace engine instead; see `HANDOVER.md`.)
"""
phylo(x) = x

# Phylogenetic correlation from a tree (AugmentedPhy or Newick string).
function _phylo_correlation(tree)
    phy = tree isa AbstractString ? augmented_phy(tree) : tree
    C = sigma_phy_dense(phy; σ²_phy = 1.0)
    d = sqrt.(diag(C))
    return C ./ (d * d')
end

function _fit_structured_gaussian(fam::Gaussian, y, Xμ, Xσ, gidx, G, K, nmμ, nmσ, grp, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    Kfac = cholesky(Symmetric(K))
    Kinv = inv(Kfac)            # constant (K fixed)
    logdetK = logdet(Kfac)

    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; lσs = θ[pμ+pσ+1]
        ημ = Xμ * βμ; ησ = Xσ * βσ
        σs² = exp(2 * lσs)
        T = eltype(θ)
        S = zeros(T, G); C = zeros(T, G)
        q1 = zero(T); logdetD = zero(T)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i]); r = y[i] - ημ[i]; a = r * invD; k = gidx[i]
            S[k] += invD; C[k] += a; q1 += r * a; logdetD += 2 * ησ[i]
        end
        M = Kinv ./ σs² + Diagonal(S)              # (1/σ_s²)K⁻¹ + ZᵀD⁻¹Z
        Mfac = cholesky(Symmetric(M))
        quad = q1 - dot(C, Mfac \ C)
        logdetV = logdetD + G * log(σs²) + logdetK + logdet(Mfac)
        return 0.5 * (logdetV + quad) + 0.5 * n * log(2π)
    end

    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    θ0 = zeros(pμ + pσ + 1)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(res0) + eps())
    θ0[pμ+pσ+1] = log(std(res0) / 2 + eps())
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))

    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales)
end
