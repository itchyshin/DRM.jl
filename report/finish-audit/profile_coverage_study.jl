# Monte-Carlo coverage validation for profile_sigma_a (the calibrated complement to
# the percentile bootstrap, which undercovered the scale axes ~0.52 @ 0.90).
#
# Generate M datasets from a KNOWN Σ_a (identified true SDs, all interior), fit,
# profile, and record per-axis coverage of the true SD. For IDENTIFIED (interior)
# parameters the standard profile-LR CI uses the naive χ²₁(level) cutoff and should
# cover ~nominal — so we measure with chibar=false (the shipped default). The
# headline test: does the SCALE-axis coverage reach ~0.90 (vs the bootstrap's 0.52)?
#
# Gated / slow (~40 s per profiled fit) — run by hand, NOT in runtests.jl:
#   COV_M=30 julia --project=. report/finish-audit/profile_coverage_study.jl
using DRM, Random, LinearAlgebra

function run_profile_coverage(; M = 30, level = 0.90, p = 30, m = 5, chibar = false,
                              true_sd = [0.8, 0.6, 0.5, 0.4])
    # true_sd may contain a 0 (a truly-collapsed axis): draw RE only for the active axes
    # so Σ_true stays PD; the σ axes near/at 0 are where naive (over-covers ~0.95) and
    # chi-bar (~nominal) coverage diverge — the boundary cell the panel asked for.
    phy = random_balanced_tree(p; branch_length = 0.3)
    R = [1.0 0.4 0.2 0.1; 0.4 1.0 0.1 0.2; 0.2 0.1 1.0 0.3; 0.1 0.2 0.3 1.0]
    active = findall(>(0.0), true_sd)
    Σact = (Diagonal(true_sd) * R * Diagonal(true_sd))[active, active]
    Lc_act = cholesky(Symmetric(Matrix(Σact))).L
    C = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L

    cover = zeros(Int, 4); nu = zeros(Int, 4); ndone = 0
    rng = Random.MersenneTwister(20260613)
    form = bf(mu1 = @formula(y1 ~ x + phylo(1 | species)), mu2 = @formula(y2 ~ x + phylo(1 | species)),
              sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)), sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
              rho12 = @formula(rho12 ~ 1))
    for d in 1:M
        U = zeros(p, 4)
        U[:, active] = LC * randn(rng, p, length(active)) * Lc_act'
        species = repeat(1:p, inner = m); n = length(species); x = randn(rng, n)
        μ1 = 0.5 .+ 0.3x .+ U[species,1]; μ2 = -0.2 .+ 0.4x .+ U[species,2]
        σ1 = exp.(-1.0 .+ U[species,3]); σ2 = exp.(-1.0 .+ U[species,4])
        e1 = randn(rng, n); e2 = 0.3e1 .+ sqrt(1-0.09)*randn(rng, n)
        dat = (; y1 = μ1 .+ σ1.*e1, y2 = μ2 .+ σ2.*e2, x, species)
        local fit, pr
        try
            fit = drm(form, Gaussian(); data = dat, tree = phy); is_converged(fit) || continue
            pr = profile_sigma_a(fit; level = level, chibar = chibar)
        catch err
            println("  dataset $d skipped: ", first(sprint(showerror, err), 80)); continue
        end
        ndone += 1
        for a in 1:4
            r = pr.summary[a]; nu[a] += 1
            (r.lower <= true_sd[a] <= r.upper) && (cover[a] += 1)
        end
        println("dataset $d/$M done; running coverage ",
                [nu[a]==0 ? NaN : round(cover[a]/nu[a], digits=2) for a in 1:4])
    end
    axn = ("sd_mu1","sd_mu2","sd_sigma1","sd_sigma2")
    println("\n===== PROFILE coverage @ nominal $level (chibar=$chibar), $ndone datasets, p=$p =====")
    for a in 1:4
        c = nu[a]==0 ? NaN : cover[a]/nu[a]
        println("  ", rpad(axn[a],10), " true=", true_sd[a], "  coverage = ", round(c, digits=3),
                "  (", cover[a], "/", nu[a], ")")
    end
    println("(nominal $level; MC s.e. ~", round(sqrt(level*(1-level)/max(ndone,1)), digits=3),
            "; bootstrap was 0.88/0.87/0.53/0.52 — profile should lift the σ axes)")
    return cover, nu, ndone
end

run_profile_coverage(; M = parse(Int, get(ENV, "COV_M", "30")),
                       level = parse(Float64, get(ENV, "COV_LEVEL", "0.90")),
                       p = parse(Int, get(ENV, "COV_P", "30")),
                       chibar = get(ENV, "COV_CHIBAR", "false") == "true",
                       true_sd = get(ENV, "COV_ZERO", "false") == "true" ?
                                 [0.8, 0.6, 0.5, 0.0] : [0.8, 0.6, 0.5, 0.4])
