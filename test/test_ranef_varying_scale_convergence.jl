# test_ranef_varying_scale_convergence.jl -- DRM.jl #609 item 2 (varying-scale
# conditional cell, `bf(y ~ x + (1 | g), sigma ~ x)`, routed through
# `_fit_ranef_gaussian` in src/gaussian_ranef.jl).
#
# WHAT #609 LEFT OPEN. The issue's own diagnosis established that DRM.jl reaches
# its optimum on this cell (sweeping `g_tol` from 1e-8 to 1e-16 moves the
# coefficients by 1.3e-11) and handed the ~1e-5 parity gap to the drmTMB lane. It
# never looked at the flag DRM.jl reports alongside that optimum, and that flag is
# where this route does have a defect.
#
# THE DEFECT. `Optim.converged(res)` is the OR of the x, f and g criteria
# (Optim/src/api.jl:117). `Optim.Options(g_tol = g_tol)` leaves `f_reltol`,
# `f_abstol`, `x_reltol` and `x_abstol` at their 0.0 defaults, so `f_converged`
# fires whenever two successive objective values are byte-identical -- which is
# what "flat" means numerically, and which a varying-scale Gaussian surface
# reaches while running away up the unbounded sigma_i -> 0 ridge, nowhere near a
# stationary point. Measured on this route 2026-09-05 over a 6,400-cell grid
# (n in 30..400, G in 3..20, sigma slope in 0.15..8.0): 1,042 fits returned
# `converged = true` with the GRADIENT criterion false; among those the true
# gradient infinity-norm was <= 1e-6 for 840, <= 1e-3 for 107, <= 1 for 50, and
# ABOVE 1 for 45. Worst case is the `NEG` fixture below.
#
# WHY NOT A RESTART. Re-running LBFGS from the stalled point was measured on the
# same 1,042 cases: it recovered 665, left 377 still not gradient-converged, made
# the objective WORSE in 143, and produced NaN. Rejected. The change is to the
# reported condition only -- theta-hat, the ML/REML objective and logLik are
# untouched.
#
# WHY `Optim.g_converged` IS THE RIGHT CRITERION. Over the same grid,
# `Optim.g_residual(res)` equalled `maximum(abs, ForwardDiff.gradient(nll, theta))`
# EXACTLY (max absolute difference 0.0 over 5,349 gradient-converged fits), and
# the largest recomputed norm among them was 9.996e-9 -- inside `g_tol = 1e-8`.
#
#   julia --project=test -e 'using DRM, Test; include("test/test_ranef_varying_scale_convergence.jl")'

module TestRanefVaryingScaleConvergence

using DRM
using Test
using LinearAlgebra
using ForwardDiff
using StableRNGs

const GTOL = 1e-8          # the `drm(...)` default g_tol (src/gaussian_core.jl:436)

# Gaussian varying-scale random-intercept draw. StableRNGs, per test/README.md's
# preference order, so the fixture is identical on every Julia minor version.
function _draw(seed; n, G, sigma_slope, sd_b)
    rng = StableRNG(seed)
    g = [string("g", 1 + (i % G)) for i in 0:(n - 1)]
    x = 2 .* rand(rng, n) .- 1
    levels = unique(g)
    b = Dict(l => sd_b * randn(rng) for l in levels)
    y = [0.3 + 0.6 * x[i] + b[g[i]] + exp(-0.5 + sigma_slope * x[i]) * randn(rng)
         for i in 1:n]
    return (y = y, x = x, g = g)
end

_fit(dat) = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ x)), Gaussian(); data = dat)
_gradinf(fit) = maximum(abs, ForwardDiff.gradient(fit.nll, fit.theta))

@testset "#609: varying-scale ranef `converged` is the gradient criterion" begin

    # --- the RED case -----------------------------------------------------
    # LBFGS stops on `f_converged` far up the runaway ridge. Measured on
    # origin/main b4db190e7 (2026-09-05): converged = true, ||g||_inf =
    # 3.7214142683935073e137, loglik = +980.4848669647353 (a POSITIVE Gaussian
    # log-likelihood: sigma_i has collapsed toward zero at some rows).
    neg = _fit(_draw(263; n = 30, G = 3, sigma_slope = 8.0, sd_b = 0.8))
    gneg = _gradinf(neg)
    # Fixture guard: if a future Optim genuinely optimises this draw, this line
    # fails first and says so -- re-pick a stalling seed rather than relaxing the
    # contract assertion below.
    @test gneg > GTOL
    @test !neg.converged                      # <- fails on origin/main (was `true`)

    # --- the OTHER side of the boundary -----------------------------------
    # A well-behaved draw that genuinely meets the gradient criterion, and sits
    # close to the boundary: ||g||_inf = 7.409475699660106e-9, i.e. 74% of
    # `g_tol`. A change that merely reported `false` more often would fail here.
    pos = _fit(_draw(5; n = 144, G = 12, sigma_slope = 0.15, sd_b = 0.8))
    gpos = _gradinf(pos)
    @test gpos <= GTOL
    @test pos.converged

    # --- the invariant, over a panel --------------------------------------
    # `converged` must never be reported for a point above `g_tol`. Counts on
    # origin/main b4db190e7 and after the fix: 16 fits, 16 `converged = true`,
    # 0 violations -- so the panel also pins that the fix did not turn the flag
    # off wholesale.
    nfit = 0
    nconv = 0
    nviol = 0
    for seed in 1:8
        for cfg in ((n = 144, G = 12, sigma_slope = 0.15, sd_b = 0.8),
                    (n = 30, G = 3, sigma_slope = 8.0, sd_b = 0.8))
            fit = _fit(_draw(seed; cfg...))
            nfit += 1
            fit.converged || continue
            nconv += 1
            _gradinf(fit) <= GTOL || (nviol += 1)
        end
    end
    @test nfit == 16
    @test nconv == 16
    @test nviol == 0
end

end # module
