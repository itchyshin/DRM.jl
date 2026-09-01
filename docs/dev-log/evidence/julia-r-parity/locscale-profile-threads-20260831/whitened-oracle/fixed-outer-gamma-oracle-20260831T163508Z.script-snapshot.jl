using LinearAlgebra
using Serialization
using SHA
using SpecialFunctions
using SparseArrays
using Optim

# Independent fixed-outer Gamma Laplace oracle.  This file deliberately does
# not import DRM or call any production likelihood, gradient, or inner solver.
# The Gamma NLL is copied from the retained tracked oracle:
#   l = loggamma(s) - s*log(r) - (s-1)*log(y) + r*y,
#   s = exp(psi), r = s*exp(-eta).
# Its analytic derivatives are
#   l_eta = s-r*y, l_psi = s*(digamma(s)-log(r)-1-log(y))+r*y,
#   l_etaeta = r*y, l_etapsi = s-r*y,
#   l_psipsi = l_psi-s+s^2*trigamma(s).

const SOURCE_ARTIFACT = "/private/tmp/drm-parity-20260830/profile-threads-s11/profile-nuisance-corrected-replay-20260831T160339Z.jls"
const SOURCE_SHA = "d8727b67ae76c66fcc76cdd9f672b1f2bed72c165bf47e526caf50f769998434"
const CLAMP = big"30"

maxabs(x) = isempty(x) ? zero(eltype(x)) : maximum(abs, x)
laplace_M(J, H) = J + logdet(H) / 2

# SpecialFunctions supplies BigFloat digamma but not BigFloat trigamma on this
# Julia build.  ψ₁ is therefore evaluated independently as the fourth-order
# Richardson central derivative of ψ, with fixed steps chosen before the pilot.
function trigamma_big(x)
    h = precision(x) <= 128 ? big"1e-8" : big"1e-16"
    central(step) = (digamma(x + step) - digamma(x - step)) / (2 * step)
    richardson(step) = (4 * central(step / 2) - central(step)) / 3
    value = richardson(h)
    refined = richardson(h / 2)
    gate = precision(x) <= 128 ? big"1e-27" : big"1e-55"
    @assert abs(value - refined) <= gate "BigFloat trigamma h-vs-h/2 stability failed"
    return refined
end

function trigamma_stability_record(x)
    h = precision(x) <= 128 ? big"1e-8" : big"1e-16"
    central(step) = (digamma(x + step) - digamma(x - step)) / (2 * step)
    richardson(step) = (4 * central(step / 2) - central(step)) / 3
    value, refined = richardson(h), richardson(h / 2)
    gate = precision(x) <= 128 ? big"1e-27" : big"1e-55"
    @assert abs(value - refined) <= gate "recorded BigFloat trigamma stability failed"
    return (shape=x, h_vs_h2=abs(value-refined), gate=gate)
end

function gamma_data(y, eta, psi)
    s = exp(psi)
    r = s * exp(-eta)
    ell = loggamma(s) - s * log(r) - (s - one(s)) * log(y) + r * y
    geta = s - r * y
    gpsi = s * (digamma(s) - log(r) - one(s) - log(y)) + r * y
    hetaeta = r * y
    hetapsi = s - r * y
    hpsipsi = gpsi - s + s^2 * trigamma_big(s)
    return ell, geta, gpsi, hetaeta, hetapsi, hpsipsi
end

function gamma_nll(y, eta, psi)
    s = exp(psi)
    r = s * exp(-eta)
    return loggamma(s) - s * log(r) - (s - one(s)) * log(y) + r * y
end

function gamma_density_anchor(bits)
    setprecision(BigFloat, bits) do
        y = BigFloat(4)
        eta = log(BigFloat(3) / 2)
        psi = log(BigFloat(3))
        expected = BigFloat(8) - log(BigFloat(64)) # Gamma(shape=3, rate=2) at y=4
        from_nll = gamma_nll(y, eta, psi)
        from_data = first(gamma_data(y, eta, psi))
        gate = bits == 128 ? big"1e-30" : big"1e-60"
        @assert abs(from_nll - expected) <= gate "Erlang Gamma density anchor failed"
        @assert abs(from_data - expected) <= gate "Erlang Gamma data density anchor failed"
        return (bits=bits, shape=BigFloat(3), rate=BigFloat(2), mean=BigFloat(3)/2,
                y=y, expected_nll=expected, gamma_nll=from_nll, gamma_data_nll=from_data,
                gate=gate)
    end
end

function numeric_derivative_control(bits)
    setprecision(BigFloat, bits) do
        # Fixed independent Gamma point; it is deliberately separate from the
        # frozen fixture and checks the hand-derived data derivatives directly.
        y, eta, psi = BigFloat(1.25), BigFloat(0.31), BigFloat(-0.42)
        _, ge, gp, hee, hep, hpp = gamma_data(y, eta, psi)
        h1 = bits == 128 ? big"1e-8" : big"1e-18"
        h2 = bits == 128 ? big"1e-6" : big"1e-14"
        f(e, p) = gamma_nll(y, e, p)
        # Fourth-order central stencils independently check first and second derivatives.
        d1(f1, h) = (-f1(2 * h) + 8 * f1(h) - 8 * f1(-h) + f1(-2 * h)) / (12 * h)
        d2(f1, h) = (-f1(2 * h) + 16 * f1(h) - 30 * f1(0) + 16 * f1(-h) - f1(-2 * h)) / (12 * h^2)
        nge = d1(t -> f(eta + t, psi), h1)
        ngp = d1(t -> f(eta, psi + t), h1)
        nhee = d2(t -> f(eta + t, psi), h2)
        nhpp = d2(t -> f(eta, psi + t), h2)
        mixed(h) = (f(eta + h, psi + h) - f(eta + h, psi - h) -
                    f(eta - h, psi + h) + f(eta - h, psi - h)) / (4 * h^2)
        nhep = (4 * mixed(h2 / 2) - mixed(h2)) / 3
        analytic = BigFloat[ge, gp, hee, hep, hpp]
        numeric = BigFloat[nge, ngp, nhee, nhep, nhpp]
        component_errors = abs.(analytic .- numeric)
        err = maxabs(component_errors)
        gate = bits == 128 ? big"1e-18" : big"1e-30"
        return (analytic=analytic, numeric=numeric, component_errors=component_errors,
                maxabs_error=err, gate=gate,
                h_first=h1, h_second=h2)
    end
end

function block_B(lambda, G)
    T = eltype(lambda)
    L = T[exp(lambda[1]) zero(T); lambda[2] exp(lambda[3])]
    B = zeros(T, 2G, 2G)
    for g in 1:G
        ii = 2g-1:2g
        B[ii, ii] .= L
    end
    return B, L
end

function oracle_terms(z, y, eta0, psi0, gidx, B)
    T = eltype(z)
    G = length(z) ÷ 2
    a = B * z
    J = dot(z, z) / 2
    ga = zeros(T, 2G)
    D = zeros(T, 2G, 2G)
    inside = true
    for i in eachindex(y)
        g = gidx[i]
        mu_idx, psi_idx = 2g-1, 2g
        eta = eta0[i] + a[mu_idx]
        psi = psi0[i] + a[psi_idx]
        inside &= abs(eta) < CLAMP && abs(psi) < CLAMP
        ell, ge, gp, hee, hep, hpp = gamma_data(y[i], eta, psi)
        J += ell
        ga[mu_idx] += ge
        ga[psi_idx] += gp
        D[mu_idx, mu_idx] += hee
        D[mu_idx, psi_idx] += hep
        D[psi_idx, mu_idx] += hep
        D[psi_idx, psi_idx] += hpp
    end
    @assert inside "predictor left strict LS_CLAMP band"
    g = z + transpose(B) * ga
    H = Matrix{T}(I, 2G, 2G) + transpose(B) * D * B
    return (J=J, g=g, H=H, a=a, D=D, inside=inside)
end

function solve_mode(zstart, y, eta0, psi0, gidx, B, tol)
    z = copy(zstart)
    for iter in 0:100
        state = oracle_terms(z, y, eta0, psi0, gidx, B)
        residual = maxabs(state.g)
        residual <= tol && return (z=z, state=state, iterations=iter, residual=residual)
        ch = cholesky(Symmetric(state.H); check=false)
        @assert isposdef(ch) "undamped whitened Hessian is not PD"
        z .-= ch \ state.g
    end
    error("mode residual gate not reached in 100 Newton steps")
end

function evaluate_case(label, theta64, state, bits; transformed_a=nothing)
    setprecision(BigFloat, bits) do
        tol = bits == 128 ? big"1e-25" : big"1e-50"
        y = BigFloat.(state.y)
        Xmu = BigFloat.(state.Xmu)
        Xpsi = BigFloat.(state.Xpsi)
        theta = BigFloat.(theta64)
        beta_mu, beta_psi = theta[1:2], theta[3:3]
        lambda = theta[4:6]
        eta0, psi0 = Xmu * beta_mu, Xpsi * beta_psi
        B, L = block_B(lambda, state.G)
        @assert all(abs.(eta0) .< CLAMP) && all(abs.(psi0) .< CLAMP)
        zero_start = zeros(BigFloat, 2state.G)
        solved_zero = solve_mode(zero_start, y, eta0, psi0, state.gidx, B, tol)
        zstart = transformed_a === nothing ? zero_start : B \ BigFloat.(transformed_a)
        solved_transformed = solve_mode(zstart, y, eta0, psi0, state.gidx, B, tol)
        agreement = maxabs(solved_zero.z .- solved_transformed.z)
        @assert agreement <= big"1e-20" "zero and transformed starts disagree"
        base = solved_zero.state
        ch = cholesky(Symmetric(base.H); check=false)
        @assert isposdef(ch) "final undamped Hz is not PD"
        M = laplace_M(base.J, ch)
        correction = ch \ base.g
        corrected = oracle_terms(solved_zero.z - correction, y, eta0, psi0, state.gidx, B)
        ch_corrected = cholesky(Symmetric(corrected.H); check=false)
        @assert isposdef(ch_corrected) "post-mode Hessian is not PD"
        logdet_mode_error = abs(logdet(ch_corrected) - logdet(ch)) / 2
        shapes = BigFloat[exp(psi0[i] + base.a[2state.gidx[i]]) for i in eachindex(y)]
        trigamma_stability = [trigamma_stability_record(shape) for shape in shapes]
        return (label=label, bits=bits, lambda=lambda, L=L, M=M, J=base.J,
                logdetHz=logdet(ch), z=solved_zero.z, a=base.a,
                residual=solved_zero.residual, iterations_zero=solved_zero.iterations,
                iterations_transformed=solved_transformed.iterations,
                start_agreement=agreement, inside=base.inside,
                pd=true, correction_maxabs=maxabs(correction), logdet_mode_error=logdet_mode_error,
                trigamma_stability=trigamma_stability)
    end
end

function gaussian_nonzero_B_normalization_control(bits)
    setprecision(BigFloat, bits) do
        B = BigFloat[2 0; 1 1]
        y = BigFloat[1, 2]
        H = Matrix{BigFloat}(I, 2, 2) + transpose(B) * B
        ch = cholesky(Symmetric(H); check=false)
        @assert isposdef(ch)
        zhat = ch \ (transpose(B) * y)
        J = (dot(y - B * zhat, y - B * zhat) + dot(zhat, zhat)) / 2 + log(2big(pi))
        M = laplace_M(J, ch)
        # Independently simplified: C=[[5,2],[2,3]], det(C)=11,
        # y'C^-1y=15/11 for y=[1,2].
        Mexact = log(2big(pi)) + log(BigFloat(11)) / 2 + BigFloat(15) / 22
        omitted_logdet = J
        full_logdet = J + logdet(ch)
        gate = bits == 128 ? big"1e-25" : big"1e-50"
        @assert abs(M - Mexact) <= gate "shared Laplace normalization failed"
        @assert abs(omitted_logdet - Mexact) > gate "omitted-logdet damage escaped control"
        @assert abs(full_logdet - Mexact) > gate "full-logdet damage escaped control"
        return (bits=bits, B=B, y=y, H=H, zhat=zhat, J=J, M=M, Mexact=Mexact,
                error=abs(M-Mexact), gate=gate, omitted_logdet=omitted_logdet,
                full_logdet=full_logdet, omitted_rejected=true, full_rejected=true)
    end
end

function normalization_controls(state, theta64, bits)
    setprecision(BigFloat, bits) do
        y = BigFloat.(state.y)
        Xmu, Xpsi = BigFloat.(state.Xmu), BigFloat.(state.Xpsi)
        theta = BigFloat.(theta64)
        eta0, psi0 = Xmu * theta[1:2], Xpsi * theta[3:3]
        B0 = zeros(BigFloat, 2state.G, 2state.G)
        z0 = zeros(BigFloat, 2state.G)
        baseline = oracle_terms(z0, y, eta0, psi0, state.gidx, B0)
        expected = sum(gamma_nll(y[i], eta0[i], psi0[i]) for i in eachindex(y))
        Hdamaged = transpose(B0) * baseline.D * B0 # deliberately omits z'z/2 -> no I
        damaged_ch = cholesky(Symmetric(Hdamaged); check=false)
        @assert maxabs(baseline.g) == 0 && baseline.H == Matrix{BigFloat}(I, 2state.G, 2state.G)
        @assert baseline.J == expected
        @assert !isposdef(damaged_ch) "damaged no-prior normalization unexpectedly PD"
        return (B_zero_M=baseline.J, independent_gamma_sum=expected,
                B_zero_H_identity=(baseline.H == Matrix{BigFloat}(I, 2state.G, 2state.G)),
                damaged_no_prior_pd=isposdef(damaged_ch), damaged_rejected=!isposdef(damaged_ch))
    end
end

length(ARGS) == 1 || error("usage: fixed_outer_gamma_oracle.jl NEWLY_CAPTURED_PRODUCTION_MODE_SEED.jls")
seed = deserialize(only(ARGS))
payload = deserialize(SOURCE_ARTIFACT)
state = payload.state
@assert bytes2hex(sha256(read(SOURCE_ARTIFACT))) == SOURCE_SHA
@assert state.kind == Val(:gamma) && state.G == 4 && Matrix(state.Q) == Matrix{Float64}(I, 4, 4)
@assert all(isfinite, state.y) && all(>(0), state.y)
@assert state.gidx == repeat(collect(1:4), inner=8)
@assert size(state.Xmu, 2) == 2 && size(state.Xpsi, 2) == 1

# Exact lower-intercept terminal outer state: engine packing is
# [beta_mu_intercept, beta_mu_x, beta_psi, logL11, L21, logL22].
theta_terminal = copy(state.theta_engine)
theta_terminal[1] = state.candidates[1].value
theta_terminal[2:6] .= payload.optim_results[1].minimizer
# Labelled moderate-L interior control: same response/data/design/fixed effects.
theta_interior = copy(theta_terminal)
theta_interior[4:6] .= Float64[-0.7, 0.05, -0.7]

@assert seed.source_artifact_sha256 == SOURCE_SHA
@assert seed.theta == theta_terminal
@assert seed.inner_ok && seed.residual_maxabs < 1e-8
@assert length(seed.a) == 2state.G

function production_seed_transformed_start(theta)
    B, _ = block_B(BigFloat.(theta[4:6]), state.G)
    return B \ BigFloat.(seed.a)
end

println("S11_WHITE_SOURCE_SHA256=", SOURCE_SHA)
println("S11_WHITE_PACKING=(G=4,Q=I4,latents=:interleaved_a_mu1_a_psi1_to_a_mu4_a_psi4,engine_theta=", repr(theta_terminal), ")")
println("S11_WHITE_DERIVATIVE_FORMULA=", "g_eta=s-r*y; g_psi=s*(digamma(s)-log(r)-1-log(y))+r*y; H=(r*y,s-r*y,g_psi-s+s^2*trigamma(s))")
println("S11_WHITE_TRIGAMMA_EVALUATION=Richardson4_central_derivative_of_BigFloat_digamma(h128=1e-8,h256=1e-16)")
for bits in (128, 256)
    println("S11_WHITE_GAMMA_DENSITY_ANCHOR=", repr(gamma_density_anchor(bits)))
    derivative_control = numeric_derivative_control(bits)
    println("S11_WHITE_DERIVATIVE_CONTROL=", repr((bits=bits, control=derivative_control)))
    @assert derivative_control.maxabs_error <= derivative_control.gate "independent Gamma derivative control failed"
    println("S11_WHITE_NORMALIZATION_CONTROL=", repr((bits=bits, control=normalization_controls(state, theta_terminal, bits))))
    println("S11_WHITE_GAUSSIAN_NORMALIZATION_CONTROL=", repr(gaussian_nonzero_B_normalization_control(bits)))
end

cases = NamedTuple[]
for (label, theta) in ((:lower_intercept_terminal, theta_terminal), (:interior_moderate_L, theta_interior))
    # The newly captured production mode is a second start only.  It never
    # enters the independent J, derivatives, Hessian, or mode acceptance.
    for bits in (128, 256)
        result = evaluate_case(label, theta, state, bits; transformed_a=seed.a)
        push!(cases, result)
        println("S11_WHITE_CASE=", repr(result))
    end
    r128, r256 = cases[end-1], cases[end]
    agreement = abs(r128.M - r256.M)
    @assert agreement <= big"1e-20" "cross-precision objective gate failed"
    println("S11_WHITE_CROSS_PRECISION=", repr((label=label, abs_M_difference=agreement, gate=big"1e-20")))
end
println("S11_WHITE_PILOT_COMPLETE")
