# Boundary-honest among-axis SD confidence intervals for the bivariate q=4
# phylogenetic location-scale model, computed in DRM.jl and called from R via
# JuliaCall. Shows BOTH uncertainty routes that need no Hessian (so both work
# exactly where the native fit reports pdHess = FALSE):
#
#   profile_sigma_a   — profile-likelihood CI. Calibrated, respects the SD >= 0
#                       boundary; a collapsed axis gets lower bound EXACTLY 0.
#                       This is the recommended interval for the scale axes.
#   bootstrap_sigma_a — parametric percentile CI + the 6 among-axis coevolution
#                       correlations (each with a CI). A detection / correlation
#                       tool; its scale-axis WIDTH is not calibrated (see reply).
#
# The model is fit (and profiled / bootstrapped) entirely in Julia; only the data
# goes in and the CI tables come back. Replace the simulated y1/y2 with your traits.

library(JuliaCall)

# Point JuliaCall at the same Julia that built DRM.jl's precompile cache, and at
# the DRM.jl checkout (edit both paths for your machine).
cat(">>> julia_setup\n"); flush.console <- function() {}
julia_setup(JULIA_HOME = "/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin")
cat(">>> activate + using DRM (may precompile)\n")
julia_command('import Pkg; Pkg.activate("/Users/z3437171/Dropbox/Github Local/DRM.jl")')
julia_library("DRM")
julia_library("LinearAlgebra")
julia_library("Random")
cat(">>> DRM loaded\n")

# --- your data ---------------------------------------------------------------
# In your analysis: y1, y2 (the two traits, same rows), species (tip index or
# label), covariates (here x), and a tree (Newick -> augmented_phy(newick)).
set.seed(20260613)
p <- 24L; m <- 5L
n <- p * m
species <- rep(seq_len(p), each = m)
x <- rnorm(n)
julia_assign("species_r", as.integer(species))
julia_assign("x_r", x)
julia_assign("p_r", p)

# --- fit, then BOTH interval routes, in Julia --------------------------------
julia_command('begin
  phy = random_balanced_tree(Int(p_r); branch_length = 0.3)   # your data: augmented_phy(newick)
  Random.seed!(20260613)
  pp = phy.n_leaves
  C  = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
  Z  = randn(pp, 4); Lmu = cholesky([0.64 0.30; 0.30 0.64]).L
  U  = hcat(LC*Z[:,1:2]*Lmu\', LC*Z[:,3]*0.5, zeros(pp))       # sigma2 axis collapses
  sp = Int.(species_r); nn = length(sp)
  mu1 = 0.5 .+ 0.3 .* x_r .+ U[sp,1]; mu2 = -0.2 .+ 0.4 .* x_r .+ U[sp,2]
  s1  = exp.(-1.0 .+ U[sp,3]);        s2  = exp.(-1.0 .+ U[sp,4])
  e1  = randn(nn); e2 = 0.3 .* e1 .+ sqrt(1-0.3^2) .* randn(nn)
  y1  = mu1 .+ s1 .* e1; y2 = mu2 .+ s2 .* e2
  dat = (; y1, y2, x = x_r, species = sp)

  form = bf(mu1 = @formula(y1 ~ x + phylo(1 | species)),
            mu2 = @formula(y2 ~ x + phylo(1 | species)),
            sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
            sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
            rho12  = @formula(rho12 ~ 1))
  fit = drm(form, Gaussian(); data = dat, tree = phy)          # ML; method = :REML also available

  # (1) PROFILE-likelihood CIs (calibrated, boundary-honest, no Hessian)
  pr = profile_sigma_a(fit; level = 0.90)
  global p_axis = String[String(r.param) for r in pr.summary]
  global p_est  = Float64[r.estimate for r in pr.summary]
  global p_lo   = Float64[r.lower for r in pr.summary]
  global p_hi   = Float64[r.upper for r in pr.summary]

  # (2) parametric BOOTSTRAP CIs + the 6 among-axis correlations
  bsd = bootstrap_sigma_a(fit; data = dat, B = 200, rng = Random.MersenneTwister(1))
  global b_axis = String[String(r.param) for r in bsd.summary]
  global b_est  = Float64[r.estimate for r in bsd.summary]
  global b_lo   = Float64[r.lower for r in bsd.summary]
  global b_hi   = Float64[r.upper for r in bsd.summary]
  global c_pair = String[String(r.param) for r in bsd.cor_summary]
  global c_est  = Float64[r.estimate for r in bsd.cor_summary]
  global c_lo   = Float64[r.lower for r in bsd.cor_summary]
  global c_hi   = Float64[r.upper for r in bsd.cor_summary]
  global b_used = bsd.used
end')

profile_ci <- data.frame(axis = julia_eval("p_axis"), sd = julia_eval("p_est"),
                         lower = julia_eval("p_lo"), upper = julia_eval("p_hi"),
                         stringsAsFactors = FALSE)
boot_ci <- data.frame(axis = julia_eval("b_axis"), sd = julia_eval("b_est"),
                      lower = julia_eval("b_lo"), upper = julia_eval("b_hi"),
                      stringsAsFactors = FALSE)
cor_ci <- data.frame(pair = julia_eval("c_pair"), cor = julia_eval("c_est"),
                     lower = julia_eval("c_lo"), upper = julia_eval("c_hi"),
                     stringsAsFactors = FALSE)

cat("\n=== PROFILE-likelihood 90% CIs for among-axis SDs (calibrated, boundary-honest) ===\n")
print(profile_ci, digits = 3)
cat("\n=== Parametric BOOTSTRAP 90% CIs (detection tool; B =", julia_eval("b_used"), "reps) ===\n")
print(boot_ci, digits = 3)
cat("\n=== Among-axis coevolution correlations (bootstrap CIs) ===\n")
print(cor_ci, digits = 3)

# Reading it: on the PROFILE table the collapsed sigma2 axis gets lower = 0 EXACTLY
# (the calibrated "no detectable scale-phylo signal" interval), while the identified
# mean axes get strictly-positive lower bounds. The bootstrap agrees on the call but
# its sigma-axis width is only a rough indicator (see the coverage caveat in the reply).
# Every correlation involving the collapsed sigma2 axis comes back ~[-1, 1] — the honest
# "this coevolution correlation is not estimable here" report (your D-vs-E sign-flip).
