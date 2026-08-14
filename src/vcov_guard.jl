# vcov_guard.jl — one guarded Hessian→covariance step for every fitter.
#
# Every family fitter used to end with a bare `V = inv(ForwardDiff.hessian(nll, θ̂))`. That is
# unsafe whenever the MLE sits on a variance/dispersion boundary, where the
# corresponding coordinate is unidentified and the Hessian is singular *by
# construction* — e.g. fitting NB2 to Poisson-generated data drives the size
# parameter to r → ∞, leaving that row/column numerically zero.
#
# Relying on `inv` to throw is not enough, and this is the bug it caused: on
# 2026-08-14 the `anchor (c)` VA test (test/test_variational.jl:105) threw
# SingularException(3) on CI Julia 1.10.11 and passed on 1.10.0 locally and on
# 1.11 in CI — same seeded data, same code. At the optimum θ̂[3] = −19.06
# (r = 3.6e16), diag(H)[3] = 9.9e-16 and cond(H) = 9.1e16: exactly the knife
# edge where LAPACK either reports a zero pivot or returns a finite but
# meaningless inverse. A try/inv/catch/pinv guard makes the *crash* go away but
# keeps the outcome platform-dependent and, worse, silently reports SE ≈ 0 for a
# parameter that is not estimable.
#
# So decide on the conditioning explicitly, identically on every platform, and
# say so out loud when the fit is at a boundary.

"""
Relative tolerance below which a Hessian eigenvalue counts as numerically zero.
"""
const _VCOV_RTOL = 1e-12

"""
    _vcov_from_hessian(H; context = "")

Covariance matrix from an observed-information (Hessian) matrix, guarded against
boundary degeneracy.

Symmetrises `H`, then inverts it — unless it is numerically singular, in which
case it falls back to the Moore–Penrose pseudo-inverse **and warns**, naming the
parameter coordinates that are flat. The decision is made from the eigenvalues
rather than from whether `inv` happens to throw, so the result does not depend
on the LAPACK build or CPU.

The pseudo-inverse keeps a fit usable, but standard errors for the flagged
coordinates are not trustworthy: at a variance boundary the sampling
distribution is not the usual normal approximation. Use `method = :profile` or
the bootstrap entry points for those targets (see `src/inference.jl`), or the
χ̄² boundary machinery in `src/chibar.jl`.
"""
function _vcov_from_hessian(H::AbstractMatrix; context::AbstractString = "")
    Hs = Matrix(H)
    Hs = Matrix(Symmetric((Hs + Hs') / 2))
    isempty(Hs) && return Hs

    ev = eigvals(Symmetric(Hs))
    scale = maximum(abs, ev)

    if scale == 0 || minimum(abs, ev) <= _VCOV_RTOL * scale
        d = abs.(diag(Hs))
        dmax = maximum(d)
        flat = dmax == 0 ? collect(eachindex(d)) : findall(<=(_VCOV_RTOL * dmax), d)
        @warn """
              Hessian is numerically singular at the optimum — using a pseudo-inverse.
              The fit is at a variance/dispersion boundary, so standard errors for the
              flagged coordinates are NOT trustworthy. Prefer `confint(fit, method = :profile)`
              or the bootstrap entry points for those targets.
              """ context flat_coordinates = flat rcond = scale == 0 ? 0.0 : minimum(abs, ev) / scale
        V0 = pinv(Hs)
    else
        V0 = inv(Hs)
    end

    return Matrix(Symmetric((V0 + V0') / 2))
end
