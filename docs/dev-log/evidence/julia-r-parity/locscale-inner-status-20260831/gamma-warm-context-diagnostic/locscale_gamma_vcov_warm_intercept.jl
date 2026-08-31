using DRM
using Random, SparseArrays, LinearAlgebra, SHA, Serialization
import Distributions

const ROOT = "/private/tmp/drm-parity-20260830/integration/DRM.jl"
@eval DRM begin
    function _ls_vcov(kind, y, Xμ, Xψ, gidx, G, Q, θ,
                      Zη = _ls_canonical_Zeta(length(y)),
                      Zψ = _ls_canonical_Zpsi(length(y)); h = 1e-5, a0 = nothing)
        println("VCOV_INTERCEPT a0=", repr(a0),
                " a0_finite=", a0 === nothing ? "nothing" : all(isfinite, a0))
        Main.Serialization.serialize("/private/tmp/locscale_gamma_vcov_actual_context-001.jls",
                                     (; kind, y = copy(y), Xmu = Matrix(Xμ), Xpsi = Matrix(Xψ),
                                        gidx = copy(gidx), G, Q = Matrix(Q), theta = copy(θ),
                                        Zeta = Matrix(Zη), Zpsi = Matrix(Zψ), a0 = copy(a0), h))
        H = _ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, θ, Zη, Zψ; h=h, a0=a0)
        println("VCOV_INTERCEPT H=", repr(Matrix(H)),
                " finite=", all(isfinite, Matrix(H)))
        for k in axes(H, 2)
            println("VCOV_INTERCEPT_COLUMN k=", k,
                    " finite=", all(isfinite, H[:,k]),
                    " values=", repr(H[:,k]))
            for sign in (-1.0, 1.0)
                θside = copy(θ); θside[k] += sign * h
                pμ, pψ = size(Xμ, 2), size(Xψ, 2)
                λ = @view θside[pμ+pψ+1:pμ+pψ+3]
                Pside = prior_precision(Q, _ls_inv2x2(_ls_lc_to_Λ(λ)))
                ηside = Xμ * (@view θside[1:pμ])
                ψside = Xψ * (@view θside[pμ+1:pμ+pψ])
                value, aside, inner_ok = _ls_marginal_nll(kind, y, ηside, ψside,
                                                            gidx, G, Pside, Zη, Zψ; a0=a0)
                gside = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θside,
                                           Zη, Zψ; a0=a0)
                jgrad = _ls_joint_grad(kind, y, ηside, ψside, gidx, aside, Pside, Zη, Zψ)
                println("VCOV_INTERCEPT_SIDE k=", k, " sign=", sign,
                        " nll=", repr(value), " inner_ok=", inner_ok,
                        " a_finite=", all(isfinite, aside),
                        " joint_gradnorm=", norm(jgrad),
                        " outer_grad_finite=", all(isfinite, gside),
                        " outer_grad=", repr(gside))
            end
        end
        return nothing
    end
end

Random.seed!(20_260_831)
G,m=4,8; n=G*m
species=repeat(1:G,inner=m)
x=repeat(range(-1.0,1.0;length=m),G)
eta=.70 .+ .55 .* x .+ (.16 .* randn(G))[species]
psi=1.05 .+ (.10 .* randn(G))[species]
y=[begin shape=exp(psi[i]); mu=exp(eta[i]); Float64(rand(Distributions.Gamma(shape,mu/shape))) end for i in 1:n]
println("GAMMA_VCOV_WARM_INTERCEPT")
println("SOURCE_SHA ",bytes2hex(sha256(read(joinpath(ROOT,"src/locscale_inner.jl")))))
fit=drm(bf(@formula(y ~ x + (1 | status_smoke | species)),
           @formula(sigma ~ 1 + (1 | status_smoke | species))),
        Gamma();data=(;y,x,species))
println("GAMMA_VCOV_WARM_INTERCEPT_RESULT theta=",repr(fit.theta)," converged=",fit.converged,
        " vcov=",repr(fit.vcov))
println("GAMMA_VCOV_WARM_INTERCEPT_COMPLETE")
