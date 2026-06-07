# gaussian_structured.jl — Gaussian structured random effects on the mean with a
# KNOWN relatedness matrix. A structured intercept u ~ N(0, σ_s² K) leaves the
# marginal exactly Gaussian:
#     y ~ N(Xβ, D + σ_s² Z K Zᵀ),   D = diag(σ_i²),  Z the group indicator,
# fit in closed form (PGLS-style) via the matrix-determinant lemma + Woodbury:
#   logdet(V) = logdet(D) + G·log σ_s² + logdet(K) + logdet(M),
#   rᵀV⁻¹r    = rᵀD⁻¹r − Cᵀ M⁻¹ C,   M = (1/σ_s²)K⁻¹ + ZᵀD⁻¹Z (diagonal part).
# `relmat(1 | id)` supplies K directly; `animal()` / `phylo()` / `spatial()`
# reuse this engine with K from a pedigree / tree / coordinates.

using LinearAlgebra: cholesky, Symmetric, Diagonal, dot, logdet, inv, diag, I, issuccess,
    eigen, SymTridiagonal
using SparseArrays: SparseArrays, SparseMatrixCSC, sparse, nonzeros, rowvals,
    nzrange, blockdiag, dropzeros!

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

"""
    spatial(1 | site)

Coordinate-spatial structured random intercept on the Gaussian mean. Pass site
coordinates via `drm(...; coords = coords)` (a `G×2` matrix, one row per `site`
level in first-seen order). The spatial correlation `K(ρ) = exp(-d / ρ)` is built
from pairwise distances and the range `ρ` is estimated jointly. Closed-form
Gaussian marginal (K is rebuilt each evaluation since it depends on `ρ`).
"""
spatial(x) = x

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
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Resolve one structured marker to its fixed G×G correlation/relatedness matrix
# from the keyword args. Used by the two-component path (relmat/animal/phylo;
# spatial estimates a range jointly and is not yet supported alongside a second
# component — tracked as a follow-up).
function _resolve_structured_matrix(kind::Symbol, grp::Symbol, G::Int; K, A, tree, coords)
    Cmat = if kind === :relmat
        K === nothing && error("relmat(1 | $grp) needs `K = …`")
        Matrix{Float64}(K)
    elseif kind === :animal
        A === nothing && error("animal(1 | $grp) needs the relatedness matrix `A = …`")
        Matrix{Float64}(A)
    elseif kind === :phylo
        tree === nothing && error("phylo(1 | $grp) needs `tree = …`")
        _phylo_correlation(tree)
    else  # :spatial
        error("spatial(1 | $grp) is not yet supported as one of two structured components " *
              "(it estimates a range jointly); use it as the only structured marker")
    end
    size(Cmat) == (G, G) ||
        error("structured matrix for `$grp` must be $(G)×$(G) (the number of `$grp` levels)")
    return Cmat
end

# Build the n×G group-indicator (one-hot) for a structured intercept.
function _structured_Z(gidx, G)
    n = length(gidx)
    Z = zeros(n, G)
    @inbounds for i in 1:n
        Z[i, gidx[i]] = 1.0
    end
    return Z
end

# Two structured intercepts on the Gaussian mean in ONE fit (e.g.
# `phylo(1|species) + relmat(1|id)`). The latent field is the SUM of two
# structured effects:
#     y = Xβ + Z₁a₁ + Z₂a₂ + ε,  a₁~N(0,σ₁²C₁),  a₂~N(0,σ₂²C₂),  ε~N(0,σ²I)
# so the marginal stays exactly Gaussian:
#     y ~ N(Xβ, V),  V = σ²I + σ₁² Z₁C₁Z₁ᵀ + σ₂² Z₂C₂Z₂ᵀ.
# FIRST CUT: DENSE assembly of V (correctness first); the residual scale is a
# single `sigma ~ 1` (homoscedastic), so D = σ²I. θ = [βμ; logσ (resid); logσ₁; logσ₂].
# Both σ₁ and σ₂ are reported as named variance components via `re_sd`/`vc`.
# Follow-up: sparse/Woodbury assembly for speed (tracked separately); a `sigma`
# predictor on the residual is a straightforward extension (D → diag).
function _fit_two_structured_gaussian(fam::Gaussian, y, Xμ, gidx1, G1, C1, gidx2, G2, C2,
                                      nmμ, grp1, grp2, g_tol)
    n = length(y)
    pμ = size(Xμ, 2)
    Z1 = _structured_Z(gidx1, G1)
    Z2 = _structured_Z(gidx2, G2)
    ZC1Zt = Z1 * C1 * Z1'        # constant building blocks (C₁, C₂ fixed)
    ZC2Zt = Z2 * C2 * Z2'
    Iₙ = Matrix{Float64}(I, n, n)

    function nll(θ)
        βμ = θ[1:pμ]; lσ = θ[pμ+1]; lσ1 = θ[pμ+2]; lσ2 = θ[pμ+3]
        σ² = exp(2 * lσ); σ1² = exp(2 * lσ1); σ2² = exp(2 * lσ2)
        V = σ² .* Iₙ .+ σ1² .* ZC1Zt .+ σ2² .* ZC2Zt
        # `check = false` so a line-search step that drives the residual scale to a
        # numerically non-PD V is rejected with a large finite penalty (the optimiser
        # then backtracks) instead of throwing a `PosDefException`.
        Vfac = cholesky(Symmetric(V); check = false)
        issuccess(Vfac) || return convert(eltype(θ), Inf)
        r = y .- Xμ * βμ
        quad = dot(r, Vfac \ r)
        return 0.5 * (logdet(Vfac) + quad) + 0.5 * n * log(2π)
    end

    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    s0 = std(res0)
    θ0 = zeros(pμ + 3)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(s0 / sqrt(3) + eps())     # balanced split: resid + 2 structured
    θ0[pμ+2] = log(s0 / sqrt(3) + eps())
    θ0[pμ+3] = log(s0 / sqrt(3) + eps())
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))

    # :resd carries BOTH structured SD parameters (logσ₁, logσ₂) so `re_sd` and
    # `vc` report them per grouping factor; :resid carries the residual logσ.
    blocks = [:mu => 1:pμ, :resid => (pμ+1):(pμ+1), :resd => (pμ+2):(pμ+3)]
    names = [:mu => nmμ, :resid => ["residual"], :resd => [String(grp1), String(grp2)]]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => fill(exp(θ̂[pμ+1]), n))
    # Conditional RE estimates (BLUPs): â_j = σ_j² C_j Z_jᵀ V⁻¹ r at θ̂.
    blup = let
        βμ = θ̂[1:pμ]; σ1² = exp(2 * θ̂[pμ+2]); σ2² = exp(2 * θ̂[pμ+3])
        Vh = exp(2 * θ̂[pμ+1]) .* Iₙ .+ σ1² .* ZC1Zt .+ σ2² .* ZC2Zt
        Vinvr = cholesky(Symmetric(Vh)) \ (y .- Xμ * βμ)
        a1 = σ1² .* (C1 * (Z1' * Vinvr))
        a2 = σ2² .* (C2 * (Z2' * Vinvr))
        Dict(Symbol(grp1) => a1, Symbol(grp2) => a2)
    end
    return _withranef(_withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n,
        Optim.converged(res), means, obs, scales), nll), blup)
end

# Coordinate-spatial structured intercept: K(ρ) = exp(-d/ρ) from site distances,
# with the range ρ estimated jointly (θ gains log σ_s and log ρ). K depends on θ
# so it is rebuilt each evaluation; otherwise the closed-form marginal is as in
# `_fit_structured_gaussian`.
function _fit_spatial_gaussian(fam::Gaussian, y, Xμ, Xσ, gidx, G, coords, nmμ, nmσ, grp, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    Ddist = [sqrt(sum(abs2, coords[k, :] .- coords[l, :])) for k in 1:G, l in 1:G]
    meandist = sum(Ddist) / (G^2 - G)

    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; lσs = θ[pμ+pσ+1]; lρ = θ[pμ+pσ+2]
        ημ = Xμ * βμ; ησ = Xσ * βσ
        σs² = exp(2 * lσs); ρ = exp(lρ)
        K = exp.(-Ddist ./ ρ) + 1e-8 * I           # exponential spatial correlation (+ jitter)
        Kfac = cholesky(Symmetric(K))
        T = eltype(θ)
        S = zeros(T, G); C = zeros(T, G)
        q1 = zero(T); logdetD = zero(T)
        @inbounds for i in 1:n
            invD = exp(-2 * ησ[i]); r = y[i] - ημ[i]; a = r * invD; k = gidx[i]
            S[k] += invD; C[k] += a; q1 += r * a; logdetD += 2 * ησ[i]
        end
        M = inv(Kfac) ./ σs² + Diagonal(S)
        Mfac = cholesky(Symmetric(M))
        quad = q1 - dot(C, Mfac \ C)
        logdetV = logdetD + G * log(σs²) + logdet(Kfac) + logdet(Mfac)
        return 0.5 * (logdetV + quad) + 0.5 * n * log(2π)
    end

    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    θ0 = zeros(pμ + pσ + 2)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(res0) + eps())
    θ0[pμ+pσ+1] = log(std(res0) / 2 + eps())
    θ0[pμ+pσ+2] = log(meandist)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))

    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ),
        :resd => (pμ+pσ+1):(pμ+pσ+1), :range => (pμ+pσ+2):(pμ+pσ+2)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)], :range => ["range"]]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# ===========================================================================
# SPARSE O(p) path for the SAME two-structured Gaussian model (#225 follow-up)
# ===========================================================================
# Same model as `_fit_two_structured_gaussian`:
#     y = Xβ + Z₁a₁ + Z₂a₂ + ε,  aₖ ~ N(0, σₖ²Cₖ),  ε ~ N(0, σ²I),
#     y ~ N(Xβ, V),   V = σ²I + σ₁² Z₁C₁Z₁ᵀ + σ₂² Z₂C₂Z₂ᵀ.
#
# The dense path assembles and factors the n×n V each evaluation — O(n³). This
# path NEVER forms V. It works with the AUGMENTED LATENT a = [a₁; a₂] (length
# m = m₁ + m₂) whose prior precision is BLOCK-SPARSE,
#     P(θ) = blockdiag(σ₁⁻² Q₁, σ₂⁻² Q₂),   Qₖ = Cₖ⁻¹ (sparse for tree / Ainv),
# and integrates a out EXACTLY via one sparse Cholesky of the m×m
#     H(θ) = P(θ) + ZᵀZ / σ²,   Z = [Z₁ Z₂].
#
# Marginal NLL (matrix-determinant lemma + Woodbury, exact — the Gaussian
# Laplace is exact, so the "inner mode" is a single linear solve â = H⁻¹ b):
#     logdet V = n logσ² − logdet P + logdet H,
#     rᵀV⁻¹r   = rᵀr/σ² − bᵀâ,   b = Zᵀr/σ²,  â = H⁻¹ b,
#     NLL = ½(logdet V + rᵀV⁻¹r) + ½ n log 2π.
#
# Analytic gradient (mirrors the q4 engine's logdet/Takahashi recipe). With
# u = V⁻¹r = (r − Zâ)/σ² and â = [â₁; â₂] = H⁻¹b = Σ Zᵀu (BLUPs):
#   ∂NLL/∂β   = −Xᵀu
#   ∂NLL/∂lσ  = ½(2n − 2 tr(H⁻¹ ZᵀZ)/σ²) − σ²‖u‖²
#   ∂NLL/∂lσₖ = ½(2mₖ − 2 tr(σₖ⁻²Qₖ H⁻¹)) − wₖᵀâₖ,  wₖ = Zₖᵀu
# where the traces are read off the Takahashi SELECTED INVERSE of H at the
# (sparse) pattern of ZᵀZ / Qₖ — never a dense m×m inverse.

# Build the n×m sparse incidence Z mapping each observation to its latent row.
function _sparse_incidence(rows::AbstractVector{<:Integer}, n::Int, m::Int)
    return sparse(collect(1:n), collect(rows), ones(Float64, n), n, m)
end

# tr(Sblock · Hinv) for Sblock = Qk placed at offset `off`, Hinv the selected
# inverse. Only entries of Hinv at Qk's pattern (⊆ L+Lᵀ) are read.
function _trace_block_selinv(Hinv::SparseMatrixCSC, Qk::SparseMatrixCSC, off::Int)
    s = 0.0
    rv = rowvals(Qk); nzv = nonzeros(Qk)
    Hcol = Hinv.colptr; Hrow = rowvals(Hinv); Hval = nonzeros(Hinv)
    @inbounds for jk in 1:size(Qk, 2)
        jH = jk + off
        for p in nzrange(Qk, jk)
            iH = rv[p] + off
            idx = _csc_rowidx(Hcol, Hrow, jH, iH)
            idx == -1 && continue
            s += nzv[p] * Hval[idx]
        end
    end
    return s
end

# tr(H⁻¹ ZᵀZ): ZᵀZ sparse and ⊆ H's pattern. Read selected-inverse entries.
function _trace_selinv_full(Hinv::SparseMatrixCSC, ZtZ::SparseMatrixCSC)
    s = 0.0
    rv = rowvals(ZtZ); nzv = nonzeros(ZtZ)
    Hcol = Hinv.colptr; Hrow = rowvals(Hinv); Hval = nonzeros(Hinv)
    @inbounds for j in 1:size(ZtZ, 2)
        for p in nzrange(ZtZ, j)
            idx = _csc_rowidx(Hcol, Hrow, j, rv[p])
            idx == -1 && continue
            s += nzv[p] * Hval[idx]
        end
    end
    return s
end

function _fit_two_structured_gaussian_sparse(fam::Gaussian, y, Xμ, gidx1, G1, C1,
                                             gidx2, G2, C2, nmμ, grp1, grp2, g_tol)
    n = length(y)
    pμ = size(Xμ, 2)
    m1 = G1; m2 = G2; m = m1 + m2; off2 = m1
    # Sparse precisions Qₖ = Cₖ⁻¹ (constant in θ).
    Q1 = dropzeros!(sparse(Symmetric(inv(Symmetric(Matrix(C1))))))
    Q2 = dropzeros!(sparse(Symmetric(inv(Symmetric(Matrix(C2))))))
    logdetC1 = logdet(Symmetric(Matrix(C1)))
    logdetC2 = logdet(Symmetric(Matrix(C2)))
    Z1 = _sparse_incidence(gidx1, n, m1)
    Z2 = _sparse_incidence(gidx2, n, m2)
    Z = hcat(Z1, Z2)
    ZtZ = dropzeros!(sparse(Symmetric(Z' * Z)))
    Xt = Matrix(Xμ')

    buildH(σ², σ1², σ2²) = blockdiag(Q1 ./ σ1², Q2 ./ σ2²) + ZtZ ./ σ²

    function eval_all(βμ, lσ, lσ1, lσ2; want_grad::Bool)
        σ² = exp(2lσ); σ1² = exp(2lσ1); σ2² = exp(2lσ2)
        r = y .- Xμ * βμ
        H = buildH(σ², σ1², σ2²)
        ch = cholesky(Symmetric(H); check = false)
        issuccess(ch) || return (Inf, Float64[], r, zeros(m), false)
        b = (Z' * r) ./ σ²
        â = ch \ b
        logdetH = logdet(ch)
        logdetP = -2 * (m1 * lσ1 + m2 * lσ2) - logdetC1 - logdetC2
        logdetV = n * log(σ²) - logdetP + logdetH
        quad = dot(r, r) / σ² - dot(b, â)
        nll = 0.5 * (logdetV + quad) + 0.5 * n * log(2π)
        isfinite(nll) || return (Inf, Float64[], r, â, false)
        want_grad || return (nll, Float64[], r, â, true)
        u = (r .- Z * â) ./ σ²
        w = Z' * u
        gβ = -(Xt * u)
        Hinv = takahashi_selinv(ch)
        trH_ZtZ = _trace_selinv_full(Hinv, ZtZ)
        trQ1 = _trace_block_selinv(Hinv, Q1, 0) / σ1²
        trQ2 = _trace_block_selinv(Hinv, Q2, off2) / σ2²
        glσ = 0.5 * (2n - 2 * trH_ZtZ / σ²) - σ² * dot(u, u)
        â1 = @view â[1:m1]; â2 = @view â[off2+1:off2+m2]
        w1 = @view w[1:m1]; w2 = @view w[off2+1:off2+m2]
        glσ1 = 0.5 * (2 * m1 - 2 * trQ1) - dot(w1, â1)
        glσ2 = 0.5 * (2 * m2 - 2 * trQ2) - dot(w2, â2)
        return (nll, vcat(gβ, glσ, glσ1, glσ2), r, â, true)
    end

    nll_only(θ) = eval_all(θ[1:pμ], θ[pμ+1], θ[pμ+2], θ[pμ+3]; want_grad = false)[1]
    function fg!(F, Gout, θ)
        nll, grad, _, _, ok = eval_all(θ[1:pμ], θ[pμ+1], θ[pμ+2], θ[pμ+3]; want_grad = true)
        if Gout !== nothing
            ok ? copyto!(Gout, grad) : fill!(Gout, 0.0)
        end
        return nll
    end

    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    s0 = std(res0)
    θ0 = zeros(pμ + 3)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(s0 / sqrt(3) + eps())
    θ0[pμ+2] = log(s0 / sqrt(3) + eps())
    θ0[pμ+3] = log(s0 / sqrt(3) + eps())
    od = Optim.NLSolversBase.only_fg!(fg!)
    res = Optim.optimize(od, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol))
    θ̂ = Optim.minimizer(res)

    grad_at(θ) = eval_all(θ[1:pμ], θ[pμ+1], θ[pμ+2], θ[pμ+3]; want_grad = true)[2]
    np = pμ + 3
    Hmat = zeros(np, np)
    hstep = 1e-6
    for k in 1:np
        θp = copy(θ̂); θm = copy(θ̂)
        step = hstep * max(abs(θ̂[k]), 1.0)
        θp[k] += step; θm[k] -= step
        Hmat[:, k] .= (grad_at(θp) .- grad_at(θm)) ./ (2 * step)
    end
    Hmat .= 0.5 .* (Hmat .+ Hmat')
    V = try
        inv(Symmetric(Hmat))
    catch
        fill(NaN, np, np)
    end

    blocks = [:mu => 1:pμ, :resid => (pμ+1):(pμ+1), :resd => (pμ+2):(pμ+3)]
    names = [:mu => nmμ, :resid => ["residual"], :resd => [String(grp1), String(grp2)]]
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => fill(exp(θ̂[pμ+1]), n))
    blup = let v = eval_all(θ̂[1:pμ], θ̂[pμ+1], θ̂[pμ+2], θ̂[pμ+3]; want_grad = false)
        â = v[4]
        Dict(Symbol(grp1) => Vector{Float64}(â[1:m1]),
             Symbol(grp2) => Vector{Float64}(â[off2+1:off2+m2]))
    end
    return _withranef(_withnll(DrmFit(fam, blocks, names, θ̂, V, -nll_only(θ̂), n,
        Optim.converged(res), means, obs, scales), nll_only), blup)
end
