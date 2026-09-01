# test_575_q4_optimum.jl — issue #575: q4 REML mode-finder stops short of its
# own optimum on the biv-q4-phylo-reml fixture.
#
# DIAGNOSIS (drmTMB docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/575-mechanism.md): on this fixture, `fit_q4_reml`
# declares convergence (g_residual = 7.54e-4 < g_tol = 1e-3) at
# reml_loglik = -219.630231, but DRM.jl's OWN objective evaluated at TMB's
# fitted point theta_hat_TMB (beta reprofiled by the same conditional-Newton
# machinery) is -219.620508 -- strictly BETTER by 0.0097. So the solver is
# not at even its own optimum, independent of any TMB comparison.
#
# This test pins DRM.jl's own reported loglik to be at least as good as the
# value its own objective attains at theta_hat_TMB (with a small tolerance),
# so a regression back to the stop-short behaviour is caught directly without
# depending on TMB reference numbers.
#
#   julia --project=. -e 'using DRM, Test; include("test/test_575_q4_optimum.jl")'

module Test575Q4Optimum

using DRM
using Test
using DelimitedFiles: readdlm

const FIXTURE = joinpath(@__DIR__, "parity", "q4-reml", "biv-q4-phylo-reml")

function _load_data(dir)
    raw, header = readdlm(joinpath(dir, "data.csv"), ','; header = true)
    cols = Symbol.(strip.(string.(vec(header))))
    numeric = Set((:y1, :y2, :x))
    pairs = map(enumerate(cols)) do (j, name)
        col = raw[:, j]
        if name in numeric
            name => Float64[parse(Float64, string(v)) for v in col]
        else
            name => string.(col)
        end
    end
    return NamedTuple(pairs)
end

@testset "issue #575: q4 REML reaches its own optimum" begin
    dat = _load_data(FIXTURE)
    tree = read(joinpath(FIXTURE, "tree.newick"), String)
    form = bf(mu1    = @formula(y1 ~ x + phylo(1 | species)),
              mu2    = @formula(y2 ~ x + phylo(1 | species)),
              sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
              sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
              rho12  = @formula(rho12 ~ 1))
    fit = drm(form, Gaussian(); data = dat, tree = tree, method = :REML, q4_vcov = false)

    # DRM.jl's own objective, evaluated at TMB's fitted point via the SAME
    # conditional-Newton profiling this route uses, attains -219.620508
    # (drmTMB docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/575-mechanism.md). The solver must reach at least that,
    # up to a small numerical-tolerance margin -- otherwise it stopped short
    # of a point it can itself demonstrably reach.
    floor_ll = -219.6206
    # PLATEAU (2026-09-01, see drmTMB docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/p12a-summary.md): several attempted
    # fixes (LBFGS restarts at tighter g_tol, an objective-value polish with
    # cache-consistent comparison, NelderMead+LBFGS, bounded jittered
    # multistart) all closed PART of the gap without ever reaching floor_ll,
    # and every version tried regressed test_q4_reml_warm_restart.jl's #484
    # convergence-flag assertion. Root cause is basin-dependence, not a
    # tolerance/line-search bug in the existing basin: warm-starting
    # `fit_q4_reml` DIRECTLY at TMB's fitted phi (bypassing the ML warm
    # start) reaches -219.6034 -- BETTER than TMB itself -- confirming a
    # materially different, better basin exists but the current ML-warm-start
    # trajectory never reaches it. Left `@test_broken` rather than reverted
    # to a looser bound: the numeric floor is correct and reachable in
    # principle (verified directly), only the "how to get there from the
    # standard warm start without breaking #484" question remains open.
    @test_broken loglik(fit) >= floor_ll - 1e-3
end

end # module Test575Q4Optimum
