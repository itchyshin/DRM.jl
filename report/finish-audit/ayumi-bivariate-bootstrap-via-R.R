# Bivariate q=4 phylogenetic among-axis SD confidence intervals, computed in
# DRM.jl and called from R via JuliaCall. This is the path that works TODAY for
# the bivariate cell: the drmTMB engine="julia" bridge still routes bivariate
# phylogenetic fits to native engine="tmb" (a deliberate gate, pending parity
# tests), so for the bivariate q4 boundary-honest uncertainty we call DRM.jl
# directly. The model is fit and bootstrapped entirely in Julia; only the data
# goes in and the CI table comes back.
#
# What you get: for each axis (mu1, mu2, sigma1, sigma2) the among-species SD
# sqrt(diag(Sigma_a)) with a percentile CI. A scale axis with no phylogenetic
# signal collapses and its interval sits at ~0 — the honest "no detectable
# scale-phylo signal" report, where the native Hessian gives pdHess = FALSE.

library(JuliaCall)
julia_setup()

# Point JuliaCall at the DRM.jl dev checkout (edit to the path on your machine).
julia_command('import Pkg; Pkg.activate("/Users/z3437171/Dropbox/Github Local/DRM.jl")')
julia_library("DRM")
julia_library("LinearAlgebra")
julia_library("Random")

# --- your data ----------------------------------------------------------------
# In your analysis you have, in an R data.frame:
#   y1, y2   : the two trait responses (same rows)
#   species  : tip label, OR a 1-based tip index matching the tree
#   covariates used in the formulas (here: x)
# and a tree as a Newick string, e.g.  newick <- ape::write.tree(your_phylo).
# Pass them to Julia with julia_assign(...) and build the tree with
#   julia_command('phy = augmented_phy(newick_r)')
#
# For a runnable demonstration we pass species/x from R and simulate a
# sigma2-axis collapse in Julia (replace the simulated y1/y2 with your traits):
set.seed(20260613)
p <- 24L; m <- 5L
n <- p * m
species <- rep(seq_len(p), each = m)
x <- rnorm(n)

julia_assign("species_r", as.integer(species))
julia_assign("x_r", x)
julia_assign("p_r", p)

# --- fit + bootstrap in Julia -------------------------------------------------
julia_command('begin
  phy = random_balanced_tree(Int(p_r); branch_length = 0.3)   # your data: augmented_phy(newick_r)
  Random.seed!(20260613)
  # --- demonstration responses with a collapsed sigma2 axis (replace with yours) ---
  pp = phy.n_leaves
  C  = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
  Z  = randn(pp, 4); Lmu = cholesky([0.64 0.30; 0.30 0.64]).L
  U  = hcat(LC*Z[:,1:2]*Lmu\', LC*Z[:,3]*0.5, zeros(pp))
  sp = Int.(species_r); nn = length(sp)
  mu1 = 0.5 .+ 0.3 .* x_r .+ U[sp,1]; mu2 = -0.2 .+ 0.4 .* x_r .+ U[sp,2]
  s1  = exp.(-1.0 .+ U[sp,3]);        s2  = exp.(-1.0 .+ U[sp,4])
  e1  = randn(nn); e2 = 0.3 .* e1 .+ sqrt(1-0.3^2) .* randn(nn)
  y1  = mu1 .+ s1 .* e1; y2 = mu2 .+ s2 .* e2
  dat = (; y1, y2, x = x_r, species = sp)
  # ----------------------------------------------------------------------------
  form = bf(mu1 = @formula(y1 ~ x + phylo(1 | species)),
            mu2 = @formula(y2 ~ x + phylo(1 | species)),
            sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
            sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
            rho12  = @formula(rho12 ~ 1))
  fit = drm(form, Gaussian(); data = dat, tree = phy)        # ML; method = :REML also available
  bsd = bootstrap_sigma_a(fit; data = dat, B = 200, rng = Random.MersenneTwister(1))
  axis_names = String[String(r.param) for r in bsd.summary]
  sd_est     = Float64[r.estimate for r in bsd.summary]
  sd_lo      = Float64[r.lower    for r in bsd.summary]
  sd_hi      = Float64[r.upper    for r in bsd.summary]
  cor_names  = String[String(r.param) for r in bsd.cor_summary]
  cor_est    = Float64[r.estimate for r in bsd.cor_summary]
  cor_lo     = Float64[r.lower    for r in bsd.cor_summary]
  cor_hi     = Float64[r.upper    for r in bsd.cor_summary]
  n_used     = bsd.used
end')

ci <- data.frame(
  axis  = julia_eval("axis_names"),
  sd    = julia_eval("sd_est"),
  lower = julia_eval("sd_lo"),
  upper = julia_eval("sd_hi"),
  stringsAsFactors = FALSE
)
cat(sprintf("bootstrap used %d replicates\n", julia_eval("n_used")))
cat("\nAmong-axis SDs (sqrt(diag(Sigma_a))):\n")
print(ci, digits = 3)

# the 6 among-axis coevolution correlations, with CIs
cor_ci <- data.frame(
  pair  = julia_eval("cor_names"),
  cor   = julia_eval("cor_est"),
  lower = julia_eval("cor_lo"),
  upper = julia_eval("cor_hi"),
  stringsAsFactors = FALSE
)
cat("\nAmong-axis correlations (coevolution_cor, with CIs):\n")
print(cor_ci, digits = 3)

# Reading it: sd_sigma2's interval sits near 0 (collapsed axis = no detectable
# scale-phylo signal in trait 2's variance) while sd_mu1's interval is clearly
# above 0. In the correlation table, cor_mu1_mu2 (coevolution of the two trait
# means) is identified, while every correlation involving the collapsed sigma2
# axis comes back with a near-[-1, 1] interval — the honest "this coevolution
# correlation is not estimable here" report (your D-vs-E sign-flip, quantified).
# For the across-tree sweep, wrap the fit+bootstrap in a loop over your 100 trees
# and report, per quantity, the fraction of trees whose CI excludes 0.
