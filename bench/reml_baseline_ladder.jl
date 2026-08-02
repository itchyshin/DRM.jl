using DRM
using LinearAlgebra
using Random

const REML_BASELINE_LADDER_REPORT_FIELDS = (
    :sha,
    :dirty,
    :julia_version,
    :threads,
    :blas,
    :fixture,
    :fits,
)

const REML_BASELINE_LADDER_FIT_FIELDS = (
    :method,
    :seconds,
    :converged,
    :objective,
    :estimates,
    :interval_status,
)

function _reml_baseline_ladder_git(args...; default = "unavailable")
    try
        return strip(read(Cmd(["git", args...]), String))
    catch
        return default
    end
end

function reml_baseline_ladder_metadata()
    return (
        sha = _reml_baseline_ladder_git("rev-parse", "HEAD"),
        # Ignore untracked files so local worktree roots do not make a committed
        # checkout appear source-dirty; tracked modifications remain visible.
        dirty = !isempty(_reml_baseline_ladder_git(
            "status", "--porcelain", "--untracked-files=no"; default = "",
        )),
        julia_version = string(VERSION),
        threads = Threads.nthreads(),
        blas = sprint(show, BLAS.get_config()),
    )
end

function _reml_baseline_ladder_fixture(; p::Int, nrep::Int, seed::Int)
    rng = MersenneTwister(seed)
    phy = random_balanced_tree(p; branch_length = 0.2)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    Λ = [
        0.25 0.10 0.05 0.00
        0.10 0.25 0.00 0.04
        0.05 0.00 0.09 0.02
        0.00 0.04 0.02 0.09
    ]
    P = prior_precision(phy.Q_topology[keep, keep], inv(Λ))
    u_aug = cholesky(Symmetric(P)).UP \ randn(rng, size(P, 1))
    pos = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [pos[node] for node in phy.leaf_indices]
    species_index = repeat(1:p, inner = nrep)
    species = [phy.leaf_names[i] for i in species_index]
    n = length(species_index)
    x = randn(rng, n)
    y1 = Vector{Float64}(undef, n)
    y2 = Vector{Float64}(undef, n)
    rho = DRM.RHO_GUARD * tanh(0.3)

    for i in eachindex(y1)
        u = @view u_aug[(4 * (leaf_pos[species_index[i]] - 1) + 1):(4 * leaf_pos[species_index[i]])]
        sigma1 = exp(-0.4 + u[3])
        sigma2 = exp(-0.5 + u[4])
        e = cholesky(Symmetric([sigma1^2 rho * sigma1 * sigma2;
                                rho * sigma1 * sigma2 sigma2^2])).L * randn(rng, 2)
        y1[i] = 1.0 + 0.5 * x[i] + u[1] + e[1]
        y2[i] = -0.3 + 0.4 * x[i] + u[2] + e[2]
    end

    formula = bf(
        mu1 = @formula(y1 ~ x + phylo(1 | species)),
        mu2 = @formula(y2 ~ x + phylo(1 | species)),
        sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
        sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
        rho12 = @formula(rho12 ~ 1),
    )
    return (; formula, data = (; y1, y2, x, species), phy)
end

function _reml_baseline_ladder_fit_record(method, fit, seconds)
    return (
        method = method,
        seconds = seconds,
        converged = fit.converged,
        objective = (
            reported_loglik = fit.loglik,
            ml_loglik = fit.ml_loglik,
            reml_loglik = fit.reml_loglik,
        ),
        estimates = (
            theta = copy(fit.theta),
            sigma_a_diagonal = diag(fit.ranef.Sigma_a),
        ),
        # q=4 profile/bootstrap inference is intentionally not part of this
        # timing harness; recording that fact prevents a silent CI comparison.
        interval_status = :not_evaluated,
    )
end

function reml_baseline_ladder_markdown(report)
    lines = String[
        "# Issue #291 — small-fixture ML vs baseline REML",
        "",
        "This is a baseline record, not an acceleration claim.",
        "",
        "## Environment",
        "- SHA: `$(report.sha)`",
        "- Dirty tracked tree: `$(report.dirty)`",
        "- Julia: `$(report.julia_version)`",
        "- Threads: `$(report.threads)`",
        "- BLAS: `$(report.blas)`",
        "- Fixture: p=$(report.fixture.p), nrep=$(report.fixture.nrep), seed=$(report.fixture.seed)",
        "",
        "## Fits",
    ]
    for record in report.fits
        push!(lines, "- `$(record.method)`: seconds=$(record.seconds), converged=$(record.converged), " *
                     "reported_loglik=$(record.objective.reported_loglik), " *
                     "ml_loglik=$(record.objective.ml_loglik), " *
                     "reml_loglik=$(record.objective.reml_loglik), " *
                     "interval_status=$(record.interval_status)")
        push!(lines, "  - theta=$(repr(record.estimates.theta))")
        push!(lines, "  - sigma_a_diagonal=$(repr(record.estimates.sigma_a_diagonal))")
    end
    return join(lines, "\n") * "\n"
end

"""
    reml_baseline_ladder_report(; p=8, nrep=3, seed=291,
                                q4_iterations=100, q4_n_newton=30)

Fit the same small, deterministic Gaussian q=4 phylogenetic location-scale
fixture by ML and by the existing baseline `method=:REML` optimizer. The result
is an auditable baseline record for issue #291, not an acceleration benchmark:
it reports environment metadata, elapsed time, convergence, objectives,
estimates, and the confidence-interval evaluation status.

Run with:

    julia --project=. bench/reml_baseline_ladder.jl

Set `DRM_REML_LADDER_OUTPUT=/path/to/report.md` to also write the Markdown
record to a durable artifact.
"""
function reml_baseline_ladder_report(; p::Int = 8, nrep::Int = 3, seed::Int = 291,
                                     q4_iterations::Int = 100, q4_n_newton::Int = 30)
    p >= 4 || throw(ArgumentError("p must be at least 4 for a balanced q4 tree"))
    nrep >= 2 || throw(ArgumentError("nrep must be at least 2 for scale-RE identifiability"))
    fixture = _reml_baseline_ladder_fixture(; p, nrep, seed)
    fits = NamedTuple[]
    for method in (:ML, :REML)
        elapsed = @elapsed fit = drm(
            fixture.formula, Gaussian();
            data = fixture.data,
            tree = fixture.phy,
            method,
            q4_iterations,
            q4_n_newton,
            q4_vcov = false,
        )
        push!(fits, _reml_baseline_ladder_fit_record(method, fit, elapsed))
    end
    return (; reml_baseline_ladder_metadata()..., fixture = (; p, nrep, seed), fits)
end

function reml_baseline_ladder_main()
    report = reml_baseline_ladder_report()
    markdown = reml_baseline_ladder_markdown(report)
    print(markdown)
    output = get(ENV, "DRM_REML_LADDER_OUTPUT", "")
    isempty(output) || write(output, markdown)
    return report
end

if abspath(PROGRAM_FILE) == @__FILE__
    reml_baseline_ladder_main()
end
