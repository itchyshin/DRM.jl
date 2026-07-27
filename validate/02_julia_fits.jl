# DRM.jl validation — Julia side: fit DRM.jl on the IDENTICAL R-generated data
# (S1, S2, S4) and run the self-contained boundary simulation (S3).
# Outputs machine-readable CSVs next to the R outputs in /tmp/drm-validation.

using DRM, Random, LinearAlgebra, Printf, Statistics

const DIR  = "/tmp/drm-validation"
const DDIR = joinpath(DIR, "data")

# --- tiny CSV reader: strips quotes, "NA" -> NaN, returns Dict(colname=>Vector{String}) ---
function read_csv(path)
    lines = readlines(path)
    strip_q(s) = replace(strip(s), "\"" => "")
    hdr = strip_q.(split(lines[1], ","))
    cols = Dict(h => String[] for h in hdr)
    for ln in lines[2:end]
        isempty(strip(ln)) && continue
        fs = split(ln, ",")
        for (j, h) in enumerate(hdr); push!(cols[h], strip_q(fs[j])); end
    end
    return hdr, cols
end
tonum(v) = [s == "NA" ? NaN : parse(Float64, s) for s in v]

writecsv(path, header, rows) = open(path, "w") do io
    println(io, join(header, ","))
    for r in rows; println(io, join(r, ",")); end
end

# ============================================================================
# S1 — homoscedastic Gaussian REML residual SD on the SAME data lm/gls used.
# DRM.jl REML of y~x, sigma~1 must equal sqrt(RSS/(n-p)).
# ============================================================================
println("== S1: fixed-effect Gaussian REML =="); flush(stdout)
s1rows = []
for seed in 1:10
    _, c = read_csv(joinpath(DDIR, @sprintf("s1_%02d.csv", seed)))
    y = tonum(c["y"]); x = tonum(c["x"])
    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian();
              data = (; y, x), method = :REML)
    push!(s1rows, (seed, fit.scales[:sigma][1], coef(fit, :mu)[1]))
end
writecsv(joinpath(DIR, "jl_S1.csv"), ["seed", "sd_reml_jl", "b0_jl"],
         [[r[1], r[2], r[3]] for r in s1rows])
@printf("  DRM.jl REML residual SD over 10 sets: mean=%.5f\n", mean(r[2] for r in s1rows))

# ============================================================================
# S2 — mean-phylo variance parity, ML, one obs/species (Pagel-lambda model).
# Compare H = vp/(vp+ve), total, mu, logLik vs phylolm/gls/Rphylopars.
# ============================================================================
println("== S2: mean-phylo variance parity (ML) =="); flush(stdout)
s2rows = []
for seed in 1:20
    nwk = read(joinpath(DDIR, @sprintf("s2_%02d.nwk", seed)), String)
    phy = augmented_phy(nwk)
    _, c = read_csv(joinpath(DDIR, @sprintf("s2_%02d.csv", seed)))
    species = c["species"]; y = tonum(c["y"])
    fit = drm(bf(@formula(y ~ phylo(1 | species)), @formula(sigma ~ 1)), Gaussian();
              data = (; y, species), tree = phy, method = :ML)
    vp = exp(coef(fit, :resd)[1])^2
    ve = fit.scales[:sigma][1]^2
    H  = vp / (vp + ve)
    push!(s2rows, (seed, coef(fit, :mu)[1], H, vp + ve, DRM.loglik(fit)))
end
writecsv(joinpath(DIR, "jl_S2.csv"), ["seed", "mu_jl", "H_jl", "total_jl", "ll_jl"],
         [[r...] for r in s2rows])
@printf("  DRM.jl mean H=%.3f (true 0.6), mean total=%.3f (true 1.0)\n",
        mean(r[3] for r in s2rows), mean(r[4] for r in s2rows))

# ============================================================================
# S3 — boundary performance: sigma-phylo (asymmetric) REML vs ML across true
# signal x sample size. Point-estimate sweep (many seeds) + profile-CI subset.
# DGP: y ~ x fixed mean; log-sigma carries phylo signal of SD = sigtrue.
# ============================================================================
println("== S3: sigma-phylo REML-vs-ML boundary =="); flush(stdout)
function s3_dataset(p, m, sigtrue, seed)
    Random.seed!(seed); n = p * m
    phy = random_balanced_tree(p; branch_length = 0.3)
    C = sigma_phy_dense(phy; σ²_phy = 1.0); LC = cholesky(Symmetric(C)).L
    u = sigtrue .* (LC * randn(p)); species = repeat(1:p, inner = m); x = randn(n)
    y = [1.0 + 0.3 * x[i] + exp(log(0.5) + u[species[i]]) * randn() for i in 1:n]
    return (; y, x, species), phy
end
s3rows = []
form3 = bf(@formula(y ~ x), @formula(sigma ~ phylo(1 | species)))
# Point-estimate bias sweep (fast, NO profile CI). Each fit guarded: a single
# divergent seed (the seed-4-style boundary blow-up) can't hang or kill the batch.
for (p, m) in ((20, 4), (40, 4)), sigtrue in (0.50, 0.20, 0.05)
    mls = Float64[]; rmls = Float64[]; ndiv = 0
    for seed in 1:15
        ok = false
        try
            data, phy = s3_dataset(p, m, sigtrue, seed)
            fm = drm(form3, Gaussian(); data = data, tree = phy, method = :ML)
            fr = drm(form3, Gaussian(); data = data, tree = phy, method = :REML)
            mlsd = exp(coef(fm, :resd_sigma)[1]); rmsd = exp(coef(fr, :resd_sigma)[1])
            if isfinite(mlsd) && isfinite(rmsd) && mlsd < 50 && rmsd < 50
                push!(mls, mlsd); push!(rmls, rmsd); ok = true
            end
        catch
        end
        ok || (ndiv += 1)
    end
    isempty(mls) && continue
    mlmean = mean(mls); rmlmean = mean(rmls)
    push!(s3rows, (p, m, sigtrue, length(mls), mlmean, rmlmean, rmlmean / mlmean,
                   mlmean - sigtrue, rmlmean - sigtrue, ndiv))
    @printf("  p=%d m=%d sig=%.2f | n=%d ML=%.4f REML=%.4f R/M=%.3f bias(ML,REML)=(%+.3f,%+.3f) ndiv=%d\n",
            p, m, sigtrue, length(mls), mlmean, rmlmean, rmlmean / mlmean,
            mlmean - sigtrue, rmlmean - sigtrue, ndiv)
end
writecsv(joinpath(DIR, "jl_S3.csv"),
         ["p", "m", "sigtrue", "n_ok", "ml_sd", "reml_sd", "reml_over_ml",
          "ml_bias", "reml_bias", "n_diverged"],
         [[r...] for r in s3rows])

# Profile-CI characterisation — p=20 ONLY (p=40 profile CIs hit the profile-Hessian
# stall). Captures [0,Inf]-at-weak-signal vs bounded-at-strong-signal honestly.
println("== S3-CI: profile-CI characterisation (p=20) =="); flush(stdout)
s3ci = []
for sigtrue in (0.50, 0.20, 0.05)
    cov = 0; finite_hi = 0; nci = 0
    for seed in 1:6
        try
            data, phy = s3_dataset(20, 4, sigtrue, seed)
            frc = drm(form3, Gaussian(); data = data, tree = phy,
                      method = :REML, profile_ci = true)
            ci = get(frc.scales, :profile_ci_sd_sigma, [NaN, NaN])
            isfinite(ci[1]) || continue
            nci += 1
            (ci[1] <= sigtrue <= ci[2]) && (cov += 1)
            isfinite(ci[2]) && (finite_hi += 1)
            push!(s3ci, (20, 4, sigtrue, seed, ci[1], ci[2]))
        catch
        end
    end
    @printf("  p=20 sig=%.2f | n=%d coverage=%.0f%% finite-upper=%.0f%%\n",
            sigtrue, nci, nci > 0 ? 100cov / nci : 0.0, nci > 0 ? 100finite_hi / nci : 0.0)
end
writecsv(joinpath(DIR, "jl_S3_ci.csv"), ["p", "m", "sigtrue", "seed", "ci_lo", "ci_hi"],
         [[r...] for r in s3ci])

# ============================================================================
# S4 — missing-response handling, sigma-phylo locscale REML (the Ayumi cell),
# on the SAME shared trait + masks Rphylopars saw. Stability + boundary CIs +
# fully-missing-species handling.
# ============================================================================
println("== S4: sigma-phylo locscale REML under missingness =="); flush(stdout)
phy4 = augmented_phy(read(joinpath(DDIR, "s4_tree.nwk"), String))
form4 = bf(@formula(y ~ phylo(1 | species)), @formula(sigma ~ phylo(1 | species)))
scenarios = ["mcar00", "mcar30", "mcar60", "mcar90", "dropspecies"]
s4rows = []
for sc in scenarios
    _, c = read_csv(joinpath(DDIR, @sprintf("s4_%s.csv", sc)))
    species = c["species"]; y = tonum(c["y"])
    n_obs = count(!isnan, y)
    # Point estimates only (profile CIs at p=40 hit the profile-Hessian stall; the
    # missing-data headline is estimate STABILITY across missingness).
    res = try
        fit = drm(form4, Gaussian(); data = (; y, species), tree = phy4, method = :REML)
        (exp(coef(fit, :resd_mu)[1]), exp(coef(fit, :resd_sigma)[1]), fit.converged)
    catch e
        @warn "S4 $sc failed" err = sprint(showerror, e)
        (NaN, NaN, false)
    end
    push!(s4rows, (sc, n_obs, res...))
    @printf("  %-12s n_obs=%-4d sd_mu=%.3f sd_sigma=%.3f conv=%s\n",
            sc, n_obs, res[1], res[2], res[3])
end
writecsv(joinpath(DIR, "jl_S4.csv"),
         ["scenario", "n_obs", "sd_mu", "sd_sigma", "converged"],
         [[r...] for r in s4rows])
println("\nALL JULIA STUDIES COMPLETE")
