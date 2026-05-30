# test_step1_sparse.jl — Step 1 foundation: confirm the ported sparse Q
# reproduces the R-side ape::vcv Σ_phy, and that sparse Cholesky +
# Takahashi selected-inversion match dense linear algebra.
#
# Run:
#   cd /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4
#   /Users/z3437171/.juliaup/bin/julia --project=.. test_step1_sparse.jl

using LinearAlgebra, SparseArrays, Test, Printf
using CSV, DataFrames

include("sparse_phy.jl")
include("takahashi_selinv.jl")

const FIX = normpath(joinpath(@__DIR__, "..", "..", "fixtures"))

# ---------------------------------------------------------------------------
# Helper: align Julia's Newick-order leaves to the R Σ_phy / data order.
# R wrote Σ_phy = vcv(tree)[tip.label, tip.label] and species = tip.label,
# so data-row i ↔ Σ_phy row i ↔ species name df.species[i].
# ---------------------------------------------------------------------------
function leaf_perm(phy, species_order::Vector{String})
    # position of phy leaf k within the R species ordering
    name_to_rpos = Dict(s => i for (i, s) in enumerate(species_order))
    # perm[k] = R-row for Julia-leaf k
    return [name_to_rpos[phy.leaf_names[k]] for k in 1:phy.n_leaves]
end

@testset "Step 1: sparse phylogenetic infrastructure" begin

    # --- Load the q4_p100 tree + R-side artifacts ----------------------------
    newick = read(joinpath(FIX, "q4_p100_tree.nwk"), String)
    phy = augmented_phy(newick)
    @test phy.n_leaves == 100
    @test phy.n_total == 2 * 100 - 1
    @test nnz(phy.Q_topology) < 20 * phy.n_leaves   # ~8p sparse

    df = CSV.read(joinpath(FIX, "q4_p100.csv"), DataFrame)
    species_order = String.(df.species)             # = tree$tip.label order
    @test length(species_order) == 100
    @test Set(species_order) == Set(phy.leaf_names)  # same leaves, maybe reordered

    Σ_R = Matrix{Float64}(CSV.read(joinpath(FIX, "q4_p100_sigma_phy.csv"), DataFrame))
    @test size(Σ_R) == (100, 100)

    # --- (a) sparse Q reproduces the dense ape::vcv Σ_phy --------------------
    Σ_jl_newick = sigma_phy_dense(phy; σ²_phy = 1.0)   # leaves in Newick order
    perm = leaf_perm(phy, species_order)
    # reorder Julia's matrix into R's ordering: Σ_R[perm[k], perm[l]] == Σ_jl[k,l]
    Σ_jl_Rorder = similar(Σ_jl_newick)
    for k in 1:100, l in 1:100
        Σ_jl_Rorder[perm[k], perm[l]] = Σ_jl_newick[k, l]
    end
    relerr = maximum(abs.(Σ_jl_Rorder .- Σ_R)) / maximum(abs.(Σ_R))
    @printf "  max rel error Σ_phy (sparse-recon vs R vcv): %.2e\n" relerr
    @test relerr < 1e-8

    # --- (b) sparse Cholesky logdet matches dense ---------------------------
    # Build a PD sparse matrix from the augmented Q: M = Q_cond + I (root removed)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    Qc = phy.Q_topology[keep, keep]
    M = Qc + 1.0I
    Ms = sparse(Symmetric(M))
    ch = cholesky(Ms)
    ld_sparse = logdet(ch)
    ld_dense = logdet(Symmetric(Matrix(M)))
    @printf "  logdet sparse=%.6f dense=%.6f  |Δ|=%.2e\n" ld_sparse ld_dense abs(ld_sparse - ld_dense)
    @test isapprox(ld_sparse, ld_dense; rtol = 1e-10)

    # --- (c) Takahashi selected inverse matches dense inv at the pattern ----
    Minv_dense = inv(Symmetric(Matrix(M)))
    Sel = takahashi_selinv(ch)            # sparse, entries at L+L' pattern
    # check the entries Takahashi computed against dense inv
    rows = rowvals(Sel); vals = nonzeros(Sel)
    maxerr = 0.0; ncheck = 0
    for j in 1:size(Sel, 2)
        for idx in nzrange(Sel, j)
            i = rows[idx]
            maxerr = max(maxerr, abs(vals[idx] - Minv_dense[i, j]))
            ncheck += 1
        end
    end
    @printf "  Takahashi selinv: checked %d entries, max |Δ vs dense inv| = %.2e\n" ncheck maxerr
    @test maxerr < 1e-8

    # --- (d) diagonal of inverse via takahashi_diag -------------------------
    d_sel = takahashi_diag(ch)
    d_dense = diag(Minv_dense)
    @printf "  diag(inv): max |Δ| = %.2e\n" maximum(abs.(d_sel .- d_dense))
    @test maximum(abs.(d_sel .- d_dense)) < 1e-8
end

println("\n=== Step 1 complete: sparse infra validated against dense + R ===")
