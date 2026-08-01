# Decisive diagnostic for the profile_sigma_a undercoverage seen in the coverage MC
# ([1.0, 0.25, 0.62, 1.0] @ p=30): is it inner-solve tightness (a fixable tuning bug
# -> profiled NLL too high -> CI too NARROW -> undercoverage), or small-p asymptotics?
#
# Direct test: on a few datasets from the SAME DGP, compute the profile CI with the
# DEFAULT inner solve vs a TIGHT one (more Newton steps, smaller g_tol, more bisection).
# If TIGHT systematically WIDENS the CIs (esp. on the under-covering mu2/sigma1 axes) and
# improves containment of the true SD -> tightness is the cause and is fixable.
# If the CIs barely move -> it's not tightness (small-p / asymptotic).
using DRM, Random, LinearAlgebra, Printf

p, m = 30, 5
true_sd = [0.8, 0.6, 0.5, 0.4]
R = [1.0 0.4 0.2 0.1; 0.4 1.0 0.1 0.2; 0.2 0.1 1.0 0.3; 0.1 0.2 0.3 1.0]
phy = random_balanced_tree(p; branch_length = 0.3)
C = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
Lc = cholesky(Symmetric(Diagonal(true_sd) * R * Diagonal(true_sd))).L
form = bf(mu1 = @formula(y1 ~ x + phylo(1 | species)), mu2 = @formula(y2 ~ x + phylo(1 | species)),
          sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)), sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
          rho12 = @formula(rho12 ~ 1))
axn = ("sd_mu1","sd_mu2","sd_sigma1","sd_sigma2")

rng = Random.MersenneTwister(20260613)
ND = 4
covd = zeros(Int,4); covt = zeros(Int,4); wider = zeros(Int,4)
for d in 1:ND
    U = LC * randn(rng, p, 4) * Lc'
    species = repeat(1:p, inner=m); n = length(species); x = randn(rng, n)
    μ1 = 0.5 .+ 0.3x .+ U[species,1]; μ2 = -0.2 .+ 0.4x .+ U[species,2]
    σ1 = exp.(-1.0 .+ U[species,3]); σ2 = exp.(-1.0 .+ U[species,4])
    e1 = randn(rng,n); e2 = 0.3e1 .+ sqrt(1-0.09)*randn(rng,n)
    dat = (; y1 = μ1 .+ σ1.*e1, y2 = μ2 .+ σ2.*e2, x, species)
    fit = drm(form, Gaussian(); data = dat, tree = phy)
    is_converged(fit) || (println("dataset $d not converged, skip"); continue)
    prD = profile_sigma_a(fit; level = 0.90)                                    # DEFAULT
    prT = profile_sigma_a(fit; level = 0.90, n_newton = 200, g_tol = 1e-6, max_bisect = 24)  # TIGHT
    println("\n=== dataset $d ===")
    for a in 1:4
        rD = prD.summary[a]; rT = prT.summary[a]; t = true_sd[a]
        cD = rD.lower <= t <= rD.upper; cT = rT.lower <= t <= rT.upper
        wD = rD.upper - rD.lower; wT = rT.upper - rT.lower
        covd[a] += cD; covt[a] += cT; wider[a] += (wT > wD + 1e-6)
        @printf "  %-10s true=%.2f  DEFAULT [%.3f,%.3f] w=%.3f %s | TIGHT [%.3f,%.3f] w=%.3f %s  Δwidth=%+.3f\n" axn[a] t rD.lower rD.upper wD (cD ? "✓" : "✗") rT.lower rT.upper wT (cT ? "✓" : "✗") (wT-wD)
    end
end
println("\n===== SUMMARY over $ND datasets =====")
for a in 1:4
    @printf "  %-10s  DEFAULT covered %d/%d | TIGHT covered %d/%d | TIGHT wider in %d/%d\n" axn[a] covd[a] ND covt[a] ND wider[a] ND
end
println("\nINTERPRETATION: if TIGHT widens + covers more on mu2/sigma1 -> inner-solve tightness (FIXABLE).")
println("                if CIs barely move -> small-p asymptotics (not a tuning bug).")
