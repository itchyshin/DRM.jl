# Inner-mode acceptance is a numerical certificate: positive curvature alone
# cannot turn a nonstationary latent state into `ok=true`.
using DRM
using Test, LinearAlgebra, SparseArrays

const _INNER_STATUS_KIND = Val(:inner_status_quartic)
const _INNER_STATUS_FINAL_KIND = Val(:inner_status_final_quadratic)
const _INNER_STATUS_NONFINITE_KIND = Val(:inner_status_nonfinite)
const _INNER_STATUS_NONFINITE_GRADIENT_KIND = Val(:inner_status_nonfinite_gradient)
const _INNER_STATUS_OVERFLOW_NORM_KIND = Val(:inner_status_overflow_norm)
const _INNER_STATUS_DAMPING_DIRECTION_KIND = Val(:inner_status_damping_direction)

"""Synthetic rounded-objective controls for the guarded Newton polish path."""
struct _InnerRoundingKind
    scenario::Symbol
end

const _INNER_ROUNDING_ULP = eps(1.0)
const _INNER_ROUNDING_CALLS = Ref(0)

function DRM._ls_joint(kind::_InnerRoundingKind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    _INNER_ROUNDING_CALLS[] += 1
    s = kind.scenario
    if s === :normal
        return sum(abs2, a) / 2
    elseif s === :backtracked
        return a[1] == 1e-10 ? 1.0 :
               (abs(a[1]) < 1e-20 ? 1.0 + 5 * _INNER_ROUNDING_ULP :
                                1.0 + 3 * _INNER_ROUNDING_ULP)
    else
        return a[1] == (s === :large ? 1.0 : 1e-10) ? 1.0 :
               1.0 + (s === :over ? 5 : 3) * _INNER_ROUNDING_ULP
    end
end

function DRM._ls_joint_grad(kind::_InnerRoundingKind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    s = kind.scenario
    if s === :nonstationary
        return a[1] == 1e-10 ? [4e-9, 0.0] : [2e-9, 0.0]
    elseif s === :backtracked
        return a[1] == 1e-10 ? [2e-9, 0.0] : zeros(2)
    elseif s === :damped
        return a[1] == 1e-10 ? [9e-9, 0.0] : zeros(2)
    elseif s === :unchanged
        return [2e-9, 0.0]
    elseif s === :accepted || s === :over || s === :indefinite || s === :nonfinite ||
           s === :backtracked
        return a[1] == 1e-10 ? [2e-9, 0.0] : zeros(2)
    elseif s === :large
        return a[1] == 1.0 ? [3e-9, 0.0] : zeros(2)
    else
        return copy(a)
    end
end

function DRM._ls_joint_hess(kind::_InnerRoundingKind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
    s = kind.scenario
    if s === :nonstationary
        return a[1] == 1e-10 ? 50.0I(2) : 1.0I(2)
    elseif s === :indefinite
        return a[1] == 1e-10 ? 20.0I(2) : -1.0I(2)
    elseif s === :nonfinite
        return a[1] == 1e-10 ? 20.0I(2) : fill(NaN, 2, 2)
    elseif s === :damped
        return a[1] == 1e-10 ? -1.0I(2) : 1.0I(2)
    elseif s === :unchanged
        return 1e20I(2)
    elseif s === :large
        return 3e-9I(2)
    else
        return 20.0I(2)
    end
end

function DRM._ls_joint(::Val{:inner_status_quartic}, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    return a[1]^4 / 4 + sum(abs2, a) / 2
end
function DRM._ls_joint_grad(::Val{:inner_status_quartic}, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    return [a[1]^3 + a[1], a[2]]
end
function DRM._ls_joint_hess(::Val{:inner_status_quartic}, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
    return [3a[1]^2 + 1 0.0; 0.0 1.0]
end

DRM._ls_joint(::Val{:inner_status_final_quadratic}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = sum(abs2, a) / 2
DRM._ls_joint_grad(::Val{:inner_status_final_quadratic}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = copy(a)
DRM._ls_joint_hess(::Val{:inner_status_final_quadratic}, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) = Matrix{Float64}(I, 2, 2)

# The zero gradient is deliberate: the test isolates the required finite-mode
# guard before the early-convergence return, without involving a response fit.
DRM._ls_joint(::Val{:inner_status_nonfinite}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = 0.0
DRM._ls_joint_grad(::Val{:inner_status_nonfinite}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = zeros(2)
DRM._ls_joint_hess(::Val{:inner_status_nonfinite}, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) = Matrix{Float64}(I, 2, 2)

DRM._ls_joint(::Val{:inner_status_nonfinite_gradient}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = 0.0
DRM._ls_joint_grad(::Val{:inner_status_nonfinite_gradient}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = [NaN, 0.0]
DRM._ls_joint_hess(::Val{:inner_status_nonfinite_gradient}, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) = Matrix{Float64}(I, 2, 2)

DRM._ls_joint(::Val{:inner_status_overflow_norm}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = sum(abs2, a) / 2
DRM._ls_joint_grad(::Val{:inner_status_overflow_norm}, y, η0, ψ0, gidx, a, P, Zη, Zψ) = copy(a)
DRM._ls_joint_hess(::Val{:inner_status_overflow_norm}, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) = Matrix{Float64}(I, length(a), length(a))

const _INNER_DAMPING_K = 2.0^40
const _INNER_DAMPING_A0 = [_INNER_DAMPING_K, 1.0]
const _INNER_DAMPING_G = [2.0^20, 2.0^19]
const _INNER_DAMPING_H = [2 * _INNER_DAMPING_K _INNER_DAMPING_K;
                           _INNER_DAMPING_K 2 * _INNER_DAMPING_K]
function DRM._ls_joint(::Val{:inner_status_damping_direction}, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    d = a .- _INNER_DAMPING_A0
    return dot(_INNER_DAMPING_G, d) + 0.5 * dot(d, _INNER_DAMPING_H * d)
end
DRM._ls_joint_grad(::Val{:inner_status_damping_direction}, y, η0, ψ0, gidx, a, P, Zη, Zψ) =
    _INNER_DAMPING_G + _INNER_DAMPING_H * (a .- _INNER_DAMPING_A0)
DRM._ls_joint_hess(::Val{:inner_status_damping_direction}, y, η0, ψ0, gidx, G, a, P, Zη, Zψ) =
    copy(_INNER_DAMPING_H)

_inner_status_args(kind) = (
    kind, Float64[], Float64[], Float64[], Int[], 1,
    Matrix{Float64}(I, 2, 2), zeros(0, 2), zeros(0, 2),
)
_inner_status_args4(kind) = (
    kind, Float64[], Float64[], Float64[], Int[], 2,
    Matrix{Float64}(I, 4, 4), zeros(0, 2), zeros(0, 2),
)
_inner_rounding_args(kind) = _inner_status_args(kind)

@testset "location-scale inner-mode stationarity acceptance" begin
    @testset "synthetic strictly convex controls" begin
        args = _inner_status_args(_INNER_STATUS_KIND)
        a0 = [2.0, 0.0]
        a_zero, ch_zero, ok_zero = DRM._ls_inner_mode(args...; a0=a0, maxiter=0)
        @test !ok_zero
        @test issuccess(ch_zero)
        @test norm([a_zero[1]^3 + a_zero[1], a_zero[2]]) > 1e-9 * (1 + norm(a_zero))

        a_stationary, ch_stationary, ok_stationary = DRM._ls_inner_mode(
            args...; a0=zeros(2), maxiter=0,
        )
        @test ok_stationary
        @test issuccess(ch_stationary)
        @test all(isfinite, a_stationary)
        @test norm([a_stationary[1]^3 + a_stationary[1], a_stationary[2]]) == 0.0

        a_default, ch_default, ok_default = DRM._ls_inner_mode(
            args...; a0=[1e50, 0.0],
        )
        @test !ok_default
        @test issuccess(ch_default)
        @test all(isfinite, a_default)
        @test norm([a_default[1]^3 + a_default[1], a_default[2]]) >
              1e-9 * (1 + norm(a_default))

        final_args = _inner_status_args(_INNER_STATUS_FINAL_KIND)
        a_final, ch_final, ok_final = DRM._ls_inner_mode(final_args...; a0=a0, maxiter=1)
        @test ok_final
        @test issuccess(ch_final)
        @test all(isfinite, a_final)
        @test norm(a_final) <=
              1e-9 * (1 + norm(a_final))

        nonfinite_args = _inner_status_args(_INNER_STATUS_NONFINITE_KIND)
        a_nonfinite, ch_nonfinite, ok_nonfinite = DRM._ls_inner_mode(
            nonfinite_args...; a0=[Inf, 0.0], maxiter=1,
        )
        @test !ok_nonfinite
        @test issuccess(ch_nonfinite)
        @test !all(isfinite, a_nonfinite)

        nonfinite_gradient_args = _inner_status_args(_INNER_STATUS_NONFINITE_GRADIENT_KIND)
        a_bad_gradient, ch_bad_gradient, ok_bad_gradient = DRM._ls_inner_mode(
            nonfinite_gradient_args...; a0=zeros(2), maxiter=1,
        )
        @test !ok_bad_gradient
        @test issuccess(ch_bad_gradient)

        overflow_args = _inner_status_args4(_INNER_STATUS_OVERFLOW_NORM_KIND)
        overflow0, ch_overflow0, ok_overflow0 = DRM._ls_inner_mode(
            overflow_args...; a0=fill(1e308, 4), maxiter=0,
        )
        @test !ok_overflow0
        @test issuccess(ch_overflow0)
        @test all(isfinite, overflow0)
        @test !isfinite(norm(overflow0))

        overflow1, ch_overflow1, ok_overflow1 = DRM._ls_inner_mode(
            overflow_args...; a0=fill(1e308, 4), maxiter=1,
        )
        @test issuccess(ch_overflow1)
        @test !ok_overflow1 || isfinite(norm(overflow1))
    end

    @testset "guarded ULP-scale Newton polish" begin
        # A full, undamped step moves the represented state, rises by three ULPs,
        # and is stationary under the unchanged certificate. This is the only
        # permitted positive-objective route.
        accepted_args = _inner_rounding_args(_InnerRoundingKind(:accepted))
        accepted, accepted_ch, accepted_ok = DRM._ls_inner_mode(
            accepted_args...; a0=[1e-10, 0.0], maxiter=1,
        )
        @test accepted_ok
        @test norm(accepted) <= 1e-9 * (1 + norm(accepted))
        @test issuccess(accepted_ch)

        # Each negative control has a finite apparent candidate, but fails one
        # specific clause of the narrow exception.
        for (scenario, start) in ((:over, 1e-10), (:large, 1.0),
                                  (:nonstationary, 1e-10), (:indefinite, 1e-10),
                                  (:damped, 1e-10), (:backtracked, 1e-10))
            @testset "reject $scenario" begin
                args = _inner_rounding_args(_InnerRoundingKind(scenario))
                _, _, ok = DRM._ls_inner_mode(args...; a0=[start, 0.0], maxiter=1)
                @test !ok
            end
        end

        # A non-finite trial Hessian must be rejected as an uncertified mode,
        # not leak a factorisation error through the inner-mode API.
        bad_hessian_args = _inner_rounding_args(_InnerRoundingKind(:nonfinite))
        _, _, bad_hessian_ok = DRM._ls_inner_mode(
            bad_hessian_args...; a0=[1e-10, 0.0], maxiter=1,
        )
        @test !bad_hessian_ok

        # Coordinate-identical trial steps are not progress. The guard avoids
        # 200 no-op line-search acceptances while retaining the failure result.
        unchanged_args = _inner_rounding_args(_InnerRoundingKind(:unchanged))
        _INNER_ROUNDING_CALLS[] = 0
        unchanged_one, _, unchanged_one_ok = DRM._ls_inner_mode(
            unchanged_args...; a0=[1e-10, 0.0], maxiter=1,
        )
        calls_one = _INNER_ROUNDING_CALLS[]
        _INNER_ROUNDING_CALLS[] = 0
        unchanged_many, _, unchanged_many_ok = DRM._ls_inner_mode(
            unchanged_args...; a0=[1e-10, 0.0], maxiter=200,
        )
        calls_many = _INNER_ROUNDING_CALLS[]
        @test !unchanged_one_ok && !unchanged_many_ok
        @test unchanged_one == unchanged_many == [1e-10, 0.0]
        @test calls_one > 0
        @test calls_many == calls_one
    end

    @testset "unchanged undamped step still tries damping directions" begin
        args = _inner_status_args(_INNER_STATUS_DAMPING_DIRECTION_KIND)
        kind, y, η0, ψ0, gidx, G, P, Zη, Zψ = args
        f0 = DRM._ls_joint(kind, y, η0, ψ0, gidx, _INNER_DAMPING_A0, P, Zη, Zψ)
        a, ch, ok = DRM._ls_inner_mode(args...; a0=_INNER_DAMPING_A0, maxiter=1)
        f1 = DRM._ls_joint(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        @test !ok
        @test issuccess(ch)
        @test a[2] != _INNER_DAMPING_A0[2]
        @test f1 < f0
    end

    @testset "actual Gamma kernel reports only a certified mode" begin
        G, m = 2, 3
        gidx = repeat(1:G, inner=m)
        y = [0.9, 1.1, 1.2, 0.8, 1.0, 1.3]
        η0 = zeros(length(y)); ψ0 = zeros(length(y))
        Λ = DRM._ls_lc_to_Λ([0.0, 0.1, 0.0])
        P = DRM.prior_precision(sparse(1.0I, G, G), inv(Λ))
        a, ch, ok = DRM._ls_inner_mode(Val(:gamma), y, η0, ψ0, gidx, G, P)
        gradient = DRM._ls_joint_grad(Val(:gamma), y, η0, ψ0, gidx, a, P)
        @test ok
        @test all(isfinite, a) && all(isfinite, gradient)
        @test norm(gradient) <= 1e-9 * (1 + norm(a))
        @test issuccess(ch)

        a0 = [1.0, -1.0, 1.0, -1.0]
        a_limited, ch_limited, ok_limited = DRM._ls_inner_mode(
            Val(:gamma), y, η0, ψ0, gidx, G, P; a0=a0, maxiter=0,
        )
        g_limited = DRM._ls_joint_grad(Val(:gamma), y, η0, ψ0, gidx, a_limited, P)
        @test !ok_limited
        @test issuccess(ch_limited)
        @test norm(g_limited) > 1e-9 * (1 + norm(a_limited))
    end
end
