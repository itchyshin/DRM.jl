# Monte-Carlo coverage validation for bootstrap_sigma_a (PR #286, Ayumi #2).
#
# The bootstrap claims "valid intervals" for the q4 among-axis SDs. This checks it
# empirically: generate M datasets from a KNOWN Σ_a on a fixed tree, fit + bootstrap
# each, and record, per axis, the fraction of datasets whose `level` CI covers the
# TRUE SD. For identified axes the empirical coverage should sit near nominal.
# Variance-component percentile bootstraps are known to undercover near a boundary;
# this study uses identified true SDs (0.8/0.6/0.5/0.4, all well away from 0) so the
# number is a clean calibration check.
#
# Gated / slow (M·(1+B) refits) — run by hand, NOT part of runtests.jl:
#   julia --project=. report/finish-audit/bootstrap_coverage_study.jl
using DRM, Random, LinearAlgebra
import Statistics

function run_coverage_study(; M = 40, B = 80, level = 0.90, p = 20, m = 5)
    phy = random_balanced_tree(p; branch_length = 0.3)
    true_sd = [0.8, 0.6, 0.5, 0.4]
    R = [ 1.0  0.4  0.2  0.1
          0.4  1.0  0.1  0.2
          0.2  0.1  1.0  0.3
          0.1  0.2  0.3  1.0 ]
    Σ_true = Diagonal(true_sd) * R * Diagonal(true_sd)
    Lc = cholesky(Symmetric(Σ_true)).L
    C  = sigma_phy_dense(phy; σ²_phy = 1.0)
    LC = cholesky(Symmetric(C)).L

    cover = zeros(Int, 4); used_axes = zeros(Int, 4); ndone = 0
    β_mu1 = [0.5, 0.3]; β_mu2 = [-0.2, 0.4]; logσ1 = -1.0; logσ2 = -1.0; ρ = 0.3
    rng = Random.MersenneTwister(20260613)
    form = bf(mu1 = @formula(y1 ~ x + phylo(1 | species)),
              mu2 = @formula(y2 ~ x + phylo(1 | species)),
              sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
              sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
              rho12 = @formula(rho12 ~ 1))

    for d in 1:M
        Zd = randn(rng, p, 4)
        U = LC * Zd * Lc'
        species = repeat(1:p, inner = m); n = length(species)
        x = randn(rng, n)
        μ1 = β_mu1[1] .+ β_mu1[2] .* x .+ U[species, 1]
        μ2 = β_mu2[1] .+ β_mu2[2] .* x .+ U[species, 2]
        σ1 = exp.(logσ1 .+ U[species, 3]); σ2 = exp.(logσ2 .+ U[species, 4])
        e1 = randn(rng, n); e2 = ρ .* e1 .+ sqrt(1 - ρ^2) .* randn(rng, n)
        dat = (; y1 = μ1 .+ σ1 .* e1, y2 = μ2 .+ σ2 .* e2, x, species)
        local fit, br
        try
            fit = drm(form, Gaussian(); data = dat, tree = phy)
            is_converged(fit) || continue
            br = bootstrap_sigma_a(fit; data = dat, B = B, level = level,
                                   rng = Random.MersenneTwister(d), failures = :warn)
        catch
            continue
        end
        br.used >= max(10, B ÷ 2) || continue
        ndone += 1
        for a in 1:4
            r = br.summary[a]
            used_axes[a] += 1
            (r.lower <= true_sd[a] <= r.upper) && (cover[a] += 1)
        end
        println("dataset $d/$M (used $(br.used)/$B); running coverage ",
                [used_axes[a] == 0 ? NaN : round(cover[a]/used_axes[a], digits=2) for a in 1:4])
    end

    println("\n===== COVERAGE @ nominal $level over $ndone datasets =====")
    axn = ("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
    for a in 1:4
        c = used_axes[a] == 0 ? NaN : cover[a] / used_axes[a]
        println("  ", rpad(axn[a], 10), " true=", true_sd[a],
                "  empirical coverage = ", round(c, digits = 3),
                "  (", cover[a], "/", used_axes[a], ")")
    end
    println("(nominal $level; MC s.e. on coverage ~",
            round(sqrt(level*(1-level)/max(ndone,1)), digits = 3), " at $ndone datasets)")
    return cover, used_axes, ndone
end

run_coverage_study(; M = parse(Int, get(ENV, "COV_M", "40")),
                     B = parse(Int, get(ENV, "COV_B", "80")),
                     p = parse(Int, get(ENV, "COV_P", "20")))
