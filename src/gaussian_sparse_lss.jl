# Sparse exact marginal LSS engine for phylogenetic structured scale (#551).
# Fits the Mizuno et al. QQQ model / phylogenetic location–scale–scale:
#     y ~ Xμ βμ + a + e
#     e ~ N(0, diag(σ_e,i²)),      log σ_e,i = (Xσ βσ)ᵢ
#     a ~ N(0, D_a K D_a),          log σ_a,g = (Zg α)g,  D_a = diag(σ_a)
# using the augmented tree precision Q (O(p) nnz, root-conditioned) and
# Takahashi selected inverse.
#
# Exact GMRF sum-of-squares quadratic form avoids Woodbury cancellation.
# O(p) evaluation and exact analytic gradients for ML, and sparse Cholesky
# column solves for REML Xμ' V⁻¹ Xμ.

function _fit_phylo_gaussian_lss_sparse(fam::Gaussian, y, Xμ, Xσ, Zg, gidx, G, tree,
                                        nmμ, nmσ, nmsd, grp, g_tol;
                                        block::Symbol = :sd_phylo, reml::Bool = false)
    phy = tree isa AbstractString ? augmented_phy(tree) : tree
    phy.n_leaves == G ||
        error("phylo($grp): tree has $(phy.n_leaves) tips but `$grp` has $G levels")
    Q, leaf_pos, q = augmented_tree_precision(phy)
    Qs = dropzeros!(sparse(Symmetric(Q, :U)))
    chQ = cholesky(Symmetric(Qs); check = false)
    issuccess(chQ) ||
        error("phylo($grp): root-conditioned augmented precision is not PD")
    logdetCprior = -logdet(chQ)
    Qinv = takahashi_selinv(chQ)
    leaf_var = [Qinv[leaf_pos[t], leaf_pos[t]] for t in 1:G]
    inv_sd = [1.0 / sqrt(leaf_var[t]) for t in 1:G]

    n = length(y)
    pμ = size(Xμ, 2); pσ = size(Xσ, 2); psd = size(Zg, 2)
    np = pμ + pσ + psd
    iβμ = 1:pμ
    iβσ = (pμ+1):(pμ+pσ)
    iα = (pμ+pσ+1):np

    # Template sparsity pattern for H = Q + diag(Z'WZ)
    diag_template = zeros(q)
    for i in 1:n
        diag_template[leaf_pos[gidx[i]]] += 1.0
    end
    H_template = Qs + Diagonal(diag_template)
    Hzero = 0.0 .* H_template
    chol_ref = Ref(cholesky(Symmetric(H_template); check = false))
    issuccess(chol_ref[]) ||
        error("sparse LSS phylo: template Cholesky failed (non-PD pattern)")

    function eval_core(βμ, βσ, α; want_grad::Bool, use_ref::Bool = true)
        ημ = Xμ * βμ
        ησ = Xσ * βσ
        ησa = Zg * α
        w = exp.(-2 .* ησ)
        σa = exp.(ησa)
        wts_g = σa .* inv_sd
        wts = [wts_g[gidx[i]] for i in 1:n]
        r = y .- ημ

        diag_ZtWZ = zeros(q)
        for i in 1:n
            r_node = leaf_pos[gidx[i]]
            diag_ZtWZ[r_node] += w[i] * wts[i]^2
        end

        H = Qs + Diagonal(diag_ZtWZ) + Hzero
        ch = if use_ref
            try
                cholesky!(chol_ref[], H; check = false); chol_ref[]
            catch
                cholesky(Symmetric(H); check = false)
            end
        else
            cholesky(Symmetric(H); check = false)
        end
        issuccess(ch) || return (1e18, Float64[], r, zeros(q), zeros(n), w, wts, diag_ZtWZ, ch, false)

        b = zeros(q)
        for i in 1:n
            r_node = leaf_pos[gidx[i]]
            b[r_node] += wts[i] * w[i] * r[i]
        end

        â = ch \ b
        Zâ = [wts[i] * â[leaf_pos[gidx[i]]] for i in 1:n]
        res_lat = r .- Zâ

        logdetH = logdet(ch)
        logdetD = -sum(log, w)
        logdetV = logdetD + logdetCprior + logdetH

        quad_sos = dot(res_lat, w .* res_lat) + dot(â, Qs * â)
        nll_ml = 0.5 * (logdetV + quad_sos + n * log(2π))
        isfinite(nll_ml) || return (1e18, Float64[], r, â, Zâ, w, wts, diag_ZtWZ, ch, false)

        want_grad || return (nll_ml, Float64[], r, â, Zâ, w, wts, diag_ZtWZ, ch, true)

        # Takahashi selected inverse for exact O(p) analytic gradients
        Hinv = takahashi_selinv(ch)
        u = w .* res_lat

        g_βμ = -(Xμ' * u)

        g_βσ = zeros(pσ)
        for i in 1:n
            r_node = leaf_pos[gidx[i]]
            s_ii = Hinv[r_node, r_node]
            zHz_ii = wts[i]^2 * s_ii
            vinv_ii = w[i] - w[i]^2 * zHz_ii
            dη = vinv_ii / w[i] - (u[i]^2) / w[i]
            for k in 1:pσ
                g_βσ[k] += Xσ[i, k] * dη
            end
        end

        d_g = zeros(G)
        for g in 1:G
            r_node = leaf_pos[g]
            s_node = Hinv[r_node, r_node]
            ztwz_node = diag_ZtWZ[r_node]
            trace_term = ztwz_node * s_node
            quad_term = 0.0
            for i in 1:n
                if gidx[i] == g
                    quad_term += u[i] * Zâ[i]
                end
            end
            d_g[g] = trace_term - quad_term
        end
        g_α = Zg' * d_g

        grad = vcat(g_βμ, g_βσ, g_α)
        all(isfinite, grad) || return (1e18, Float64[], r, â, Zâ, w, wts, diag_ZtWZ, ch, false)

        return (nll_ml, grad, r, â, Zâ, w, wts, diag_ZtWZ, ch, true)
    end

    function eval_reml(βμ, βσ, α; use_ref::Bool = true)
        nll_ml, _, r, â, Zâ, w, wts, diag_ZtWZ, ch, ok = eval_core(βμ, βσ, α; want_grad = false, use_ref = use_ref)
        ok || return 1e18
        XtVinvX = zeros(pμ, pμ)
        for k in 1:pμ
            Xk = @view Xμ[:, k]
            wXk = w .* Xk
            bX = zeros(q)
            for i in 1:n
                bX[leaf_pos[gidx[i]]] += wts[i] * wXk[i]
            end
            âX = ch \ bX
            ZâX = [wts[i] * âX[leaf_pos[gidx[i]]] for i in 1:n]
            VinvXk = w .* (Xk .- ZâX)
            for j in 1:pμ
                XtVinvX[j, k] = dot(@view(Xμ[:, j]), VinvXk)
            end
        end
        chX = cholesky(Symmetric(XtVinvX); check = false)
        issuccess(chX) || return nll_ml + REML_NONPD_PENALTY
        return nll_ml + 0.5 * logdet(chX) - 0.5 * pμ * log(2π)
    end

    unpack(θ) = (θ[iβμ], θ[iβσ], θ[iα])
    nll_ml_only(θ) = eval_core(unpack(θ)...; want_grad = false, use_ref = false)[1]
    # Profile calls can run concurrently for distinct coefficients.  Do not use
    # the optimiser's mutable `chol_ref`: each stored-gradient evaluation gets
    # its own factor and scratch arrays through `use_ref = false`.
    function nllgrad!(g, θ)
        _, grad, _, _, _, _, _, _, _, ok =
            eval_core(unpack(θ)...; want_grad = true, use_ref = false)
        if ok && length(grad) == length(g)
            copyto!(g, grad)
        else
            # A finite 1e18 objective sentinel plus a zero gradient can look
            # stationary to a stored-gradient profile optimizer.  Make the
            # callback failure explicit so the nuisance solve is rejected.
            fill!(g, NaN)
        end
        return g
    end
    nll_reml_only(θ) = eval_reml(unpack(θ)...; use_ref = false)

    βμ0 = Xμ \ y; res0 = y - Xμ * βμ0
    s0 = std(res0)
    θ0 = zeros(np)
    θ0[iβμ] .= βμ0
    θ0[first(iβσ)] = log(s0 / sqrt(2) + eps())
    θ0[iα] .= Zg \ fill(log(s0 / sqrt(2) + eps()), G)

    local res, θ̂, Vcov

    if !reml
        function fg!(F, Gout, θ)
            nll, grad, _, _, _, _, _, _, _, ok = eval_core(unpack(θ)...; want_grad = true, use_ref = true)
            if Gout !== nothing
                ok ? copyto!(Gout, grad) : fill!(Gout, 0.0)
            end
            return nll
        end
        od = Optim.NLSolversBase.only_fg!(fg!)
        res = Optim.optimize(od, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol))
        θ̂ = Optim.minimizer(res)

        # Finite differences on exact analytic gradient for variance-covariance matrix
        grad_at(θ) = eval_core(unpack(θ)...; want_grad = true, use_ref = false)[2]
        Hmat = zeros(np, np)
        hstep = 1e-6
        for k in 1:np
            θp = copy(θ̂); θm = copy(θ̂)
            step = hstep * max(abs(θ̂[k]), 1.0)
            θp[k] += step; θm[k] -= step
            gp = grad_at(θp); gm = grad_at(θm)
            if isempty(gp) || isempty(gm)
                step = 1e-4
                θp = copy(θ̂); θm = copy(θ̂)
                θp[k] += step; θm[k] -= step
                gp = grad_at(θp); gm = grad_at(θm)
            end
            Hmat[:, k] .= (gp .- gm) ./ (2 * step)
        end
        Hmat .= 0.5 .* (Hmat .+ Hmat')
        Vcov = _vcov_from_hessian(Hmat; context = "sparse LSS phylo")
    else
        res = Optim.optimize(nll_reml_only, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :finite)
        θ̂ = Optim.minimizer(res)

        # Finite difference Hessian for REML
        Hmat = zeros(np, np)
        hstep = 1e-5
        for k in 1:np
            for j in 1:np
                if j >= k
                    θpp = copy(θ̂); θpm = copy(θ̂); θmp = copy(θ̂); θmm = copy(θ̂)
                    sk = hstep * max(abs(θ̂[k]), 1.0)
                    sj = hstep * max(abs(θ̂[j]), 1.0)
                    θpp[k] += sk; θpp[j] += sj
                    θpm[k] += sk; θpm[j] -= sj
                    θmp[k] -= sk; θmp[j] += sj
                    θmm[k] -= sk; θmm[j] -= sj
                    Hmat[k, j] = (nll_reml_only(θpp) - nll_reml_only(θpm) - nll_reml_only(θmp) + nll_reml_only(θmm)) / (4 * sk * sj)
                    Hmat[j, k] = Hmat[k, j]
                end
            end
        end
        Vcov = _vcov_from_hessian(Hmat; context = "sparse LSS phylo REML")
    end

    # Random effects (BLUPs)
    βμ_hat, βσ_hat, α_hat = unpack(θ̂)
    _, _, _, â, _, _, _, _, _, _ = eval_core(βμ_hat, βσ_hat, α_hat; want_grad = false, use_ref = false)
    σa_hat = exp.(Zg * α_hat)
    u_phylo = [σa_hat[t] * inv_sd[t] * â[leaf_pos[t]] for t in 1:G]
    re_dict = Dict(Symbol(grp) => u_phylo)

    blocks = [:mu => iβμ, :sigma => iβσ, block => iα]
    names = [:mu => nmμ, :sigma => nmσ, block => nmsd]
    means = Dict(:mu => Xμ * θ̂[iβμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[iβσ]))

    fit = _withranef(_withnll(DrmFit(fam, blocks, names, θ̂, Vcov, -nll_ml_only(θ̂), n,
                                     Optim.converged(res), means, obs, scales), nll_ml_only,
                                reml ? nothing : nllgrad!), re_dict)
    if reml
        return _withreml(fit, -nll_reml_only(θ̂), -nll_ml_only(θ̂))
    end
    return fit
end

# Alias for compatibility
const _fit_structured_gaussian_lss_sparse = _fit_phylo_gaussian_lss_sparse

# ---------------------------------------------------------------------------
# #563 S7b.1 — sparse MULTI-component block assembly + objective.
#
# Generalises the single-phylo-component engine above
# (`_fit_phylo_gaussian_lss_sparse`) to several `sd()` components in one fit,
# the way `#555`'s dense multi-component engine (`_fit_gaussian_lss_multi`,
# `gaussian_lss.jl:564`) already does — following the block-precision
# construction (`H = blockdiag(Q_k) + ZᵀWZ`) `gaussian_structured.jl`'s
# `_fit_two_structured_gaussian_sparse_spec` already uses for TWO fixed-
# variance structured MEAN components, generalised here to `m` components
# whose per-group SDs are themselves modelled (LSS, `sd(g) ~ …`, as #551
# does for one). See
# `docs/src/developer-notes/lss-sparse-multi-component.md` (§2/§3) for the
# reviewed design.
#
# Scope for THIS sub-slice (assembly + objective ONLY, evaluated at a fixed
# θ — no fit loop yet):
# - the block augmented precision H = blockdiag(Q_1,…,Q_m) + ZᵀWZ (§2),
#   including the genuine cross-component blocks (Z_k)ᵀ W Z_l the design
#   note introduces — `hcat`-ing the per-component sparse incidence columns
#   into one `Z = [Z_1|…|Z_m]` and forming `Zᵀ diag(W) Z` in one sparse
#   product assembles those cross blocks automatically, so no separate
#   cross-block loop is needed;
# - the per-component `b_c = Z_cᵀ W r` accumulation into a shared `b`
#   (`Z' * (w .* r)` sums every component's contribution at its own block
#   offset in one product, generalising the `b` loop at :75–79);
# - the ML objective at that fixed θ (logdet via the Cholesky factor, the
#   zero-cancellation quadratic form, and the per-component prior logdets,
#   generalising :85–90).
#
# NOT in scope here (design note §7, sub-slices S7b.2–S7b.4): the exact
# analytic gradient (the diagonal-only trace-term formula the note first
# drafted is WRONG for the cross-component case — §3/§8 finding 4 — so no
# gradient is attempted here at all), the REML correction (§4), and
# `drm()`/router wiring. `_lss_sparse_multi_objective` only evaluates a
# supplied θ; it does not fit. Because there is no repeated-evaluation loop
# yet in this sub-slice, the block Cholesky is (re)factorised fresh each
# call — the symbolic-factor-reuse-via-`cholesky!` idiom `#551` and
# `gaussian_structured.jl` use inside their optimiser closures only pays for
# itself once a fit loop calls this repeatedly (S7b.4); building that
# machinery here with no caller to benefit from it would be premature.

# One component of a sparse multi-component LSS fit. `Qs` is the component's
# sparse prior precision: the root-conditioned augmented tree precision for a
# phylogenetic component (generalising `Qs` at :20 above), or `I_G` for an
# iid component, since `K_c = I` (design note §1). `leaf_pos` maps a group
# level to its row within the component's own latent block; `inv_sd` is the
# Takahashi leaf-SD row-scaling (the `D_a T` row-scaling generalised, :53) —
# ≡ 1 for iid, since an iid group has no cross-group correlation to absorb.
struct _SparseLssComp
    gidx::Vector{Int}
    G::Int
    Zg::Matrix{Float64}
    q::Int
    leaf_pos::Vector{Int}
    Qs::SparseMatrixCSC{Float64,Int}
    inv_sd::Vector{Float64}
    logdetCprior::Float64
end

"""
    _sparse_lss_phylo_comp(gidx, G, Zg, tree) -> _SparseLssComp

The phylogenetic block of a sparse multi-component LSS fit: the same
root-conditioned augmented tree precision and Takahashi leaf-SD row-scaling
`_fit_phylo_gaussian_lss_sparse` builds for a single component (:16–27).
"""
function _sparse_lss_phylo_comp(gidx::AbstractVector{<:Integer}, G::Int, Zg::AbstractMatrix, tree)
    phy = tree isa AbstractString ? augmented_phy(tree) : tree
    phy.n_leaves == G ||
        error("phylo component: tree has $(phy.n_leaves) tips but the grouping has $G levels")
    Q, leaf_pos, q = augmented_tree_precision(phy)
    Qs = dropzeros!(sparse(Symmetric(Q, :U)))
    chQ = cholesky(Symmetric(Qs); check = false)
    issuccess(chQ) || error("sparse LSS multi (phylo): augmented precision is not PD")
    logdetCprior = -logdet(chQ)
    Qinv = takahashi_selinv(chQ)
    leaf_var = [Qinv[leaf_pos[t], leaf_pos[t]] for t in 1:G]
    inv_sd = [1.0 / sqrt(leaf_var[t]) for t in 1:G]
    return _SparseLssComp(collect(Int, gidx), G, Matrix{Float64}(Zg), q, leaf_pos, Qs, inv_sd, logdetCprior)
end

"""
    _sparse_lss_iid_comp(gidx, G, Zg) -> _SparseLssComp

An iid block: `K_c = I_G` (design note §1), so the latent state IS the group
level (`leaf_pos = 1:G`), prior precision `I_G`, and `inv_sd ≡ 1`.
"""
function _sparse_lss_iid_comp(gidx::AbstractVector{<:Integer}, G::Int, Zg::AbstractMatrix)
    Qs = sparse(1.0 * I, G, G)
    return _SparseLssComp(collect(Int, gidx), G, Matrix{Float64}(Zg), G, collect(1:G), Qs, ones(G), 0.0)
end

"""
    _lss_sparse_multi_assemble(θ, y, Xμ, Xσ, comps::Vector{_SparseLssComp})

Block assembly at a fixed `θ = [βμ; βσ; α_1; …; α_m]` (`comps` order):
`H = blockdiag(Q_1,…,Q_m) + ZᵀWZ` (design note §2), plus the joint sparse
incidence `Z = [Z_1|…|Z_m]`, the residual precision `w`, and the mean
residual `r`. Returns a `NamedTuple` `(H, Q_all, Z, w, r)`; `H` is what a
caller checks the O(p) fill claim (§2.1/§2.3) or PD-ness against.
"""
function _lss_sparse_multi_assemble(θ::AbstractVector, y::AbstractVector, Xμ::AbstractMatrix,
                                    Xσ::AbstractMatrix, comps::Vector{_SparseLssComp})
    n = length(y)
    pμ = size(Xμ, 2); pσ = size(Xσ, 2)
    m = length(comps)
    psds = [size(c.Zg, 2) for c in comps]
    offα = pμ + pσ .+ cumsum([0; psds])

    βμ = θ[1:pμ]; βσ = θ[(pμ+1):(pμ+pσ)]
    ημ = Xμ * βμ; ησ = Xσ * βσ
    w = exp.(-2 .* ησ)
    r = y .- ημ

    Zcols = Vector{SparseMatrixCSC{Float64,Int}}(undef, m)
    for (ci, c) in enumerate(comps)
        α = θ[(offα[ci]+1):offα[ci+1]]
        σa = exp.(c.Zg * α)
        wtsc = (σa .* c.inv_sd)[c.gidx]
        Zcols[ci] = _sparse_incidence(c.leaf_pos[c.gidx], n, c.q, wtsc)
    end
    Z = hcat(Zcols...)

    Q_all = blockdiag((c.Qs for c in comps)...)
    ZtWZ = dropzeros!(sparse(Symmetric(Z' * Diagonal(w) * Z)))
    H = Q_all + ZtWZ
    return (H = H, Q_all = Q_all, Z = Z, w = w, r = r)
end

"""
    _lss_sparse_multi_objective(θ, y, Xμ, Xσ, comps::Vector{_SparseLssComp}) -> Float64

Negative Gaussian ML log-likelihood of a sparse multi-component LSS model at
a fixed `θ`, via the block assembly of [`_lss_sparse_multi_assemble`](@ref):
logdet through the Cholesky factor of `H`, the zero-cancellation GMRF sum of
squares (`:89` generalised: `dot(â, Qs*â)` becomes
`dot(â, Q_all*â) = Σ_c dot(â_c, Q_c*â_c)`, §3), and the per-component prior
logdets. Structural pattern (nested vs. crossed fill, §2.1) and PD-ness are
checked directly against `_lss_sparse_multi_assemble`'s `H`, not through this
scalar.

IN SCOPE (#563 S7b.1): the assembly is correct for genuinely crossed
component groupings too (it does not assume nesting) — but the design note's
O(p) fill argument (§2.1/§2.3) only covers one phylogenetic component plus
nested or small (`G_c ≪ p`) iid components; a crossed topology at comparable
scale is numerically correct here but NOT O(p) (§2.3 case (c)).

OUT OF SCOPE for this sub-slice: gradients (S7b.2/S7b.2b), the REML
correction (S7b.3), and `drm()`/router wiring (S7b.4) — see the block comment
above this section.
"""
function _lss_sparse_multi_objective(θ::AbstractVector, y::AbstractVector, Xμ::AbstractMatrix,
                                     Xσ::AbstractMatrix, comps::Vector{_SparseLssComp})
    n = length(y)
    asm = _lss_sparse_multi_assemble(θ, y, Xμ, Xσ, comps)
    H, Q_all, Z, w, r = asm.H, asm.Q_all, asm.Z, asm.w, asm.r
    ch = cholesky(Symmetric(H); check = false)
    issuccess(ch) || return 1e18

    b = Vector(Z' * (w .* r))
    â = ch \ b
    Zâ = Z * â
    res_lat = r .- Zâ

    logdetH = logdet(ch)
    logdetD = -sum(log, w)
    logdetCprior = sum(c.logdetCprior for c in comps)
    logdetV = logdetD + logdetCprior + logdetH

    quad_sos = dot(res_lat, w .* res_lat) + dot(â, Q_all * â)
    nll_ml = 0.5 * (logdetV + quad_sos + n * log(2π))
    return isfinite(nll_ml) ? nll_ml : 1e18
end
