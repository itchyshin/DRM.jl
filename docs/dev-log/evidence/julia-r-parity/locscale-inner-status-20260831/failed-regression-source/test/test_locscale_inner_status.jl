# Inner-mode acceptance is a numerical certificate: positive curvature alone
# cannot turn a nonstationary latent state into `ok=true`.
using DRM
using Test, LinearAlgebra, SparseArrays

const _INNER_STATUS_KIND = Val(:inner_status_quartic)
const _INNER_STATUS_FINAL_KIND = Val(:inner_status_final_quadratic)
const _INNER_STATUS_NONFINITE_KIND = Val(:inner_status_nonfinite)
const _INNER_STATUS_NONFINITE_GRADIENT_KIND = Val(:inner_status_nonfinite_gradient)
const _INNER_STATUS_OVERFLOW_NORM_KIND = Val(:inner_status_overflow_norm)

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

_inner_status_args(kind) = (
    kind, Float64[], Float64[], Float64[], Int[], 1,
    Matrix{Float64}(I, 2, 2), zeros(0, 2), zeros(0, 2),
)
_inner_status_args4(kind) = (
    kind, Float64[], Float64[], Float64[], Int[], 2,
    Matrix{Float64}(I, 4, 4), zeros(0, 2), zeros(0, 2),
)

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
