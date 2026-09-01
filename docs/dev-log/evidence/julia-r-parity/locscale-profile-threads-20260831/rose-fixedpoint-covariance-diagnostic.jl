using SHA
using Serialization
using LinearAlgebra
using DRM

artifact_path = only(ARGS)
payload = deserialize(artifact_path)
state = payload.state
result = payload.optim_results[1]  # lower-intercept terminal point, preserved by the corrected replay
target = state.candidates[1]
free_labels = [:mu_x, :sigma_intercept, :logL11, :L21, :logL22]
full_labels = [:mu_intercept, :mu_x, :sigma_intercept, :logL11, :L21, :logL22]
free = 2:6
theta = copy(state.theta_engine)
theta[1] = target.value
theta[free] .= Optim.minimizer(result)

println("S11_ROSE_ARTIFACT_SHA256=", bytes2hex(sha256(read(artifact_path))))
println("S11_ROSE_PACKING=(engine=:beta_mu_then_beta_psi_then_logL11_L21_logL22, full_labels=",
        repr(full_labels), ", fixed_index=1, free_labels=", repr(free_labels), ", theta=", repr(theta), ")")

kind, y, Xmu, Xpsi, gidx, G, Q = state.kind, state.y, state.Xmu, state.Xpsi, state.gidx, state.G, state.Q
p_mu, p_psi = size(Xmu, 2), size(Xpsi, 2)
lambda = theta[p_mu+p_psi+1:p_mu+p_psi+3]
beta_mu = @view theta[1:p_mu]
beta_psi = @view theta[p_mu+1:p_mu+p_psi]
precision = DRM.prior_precision(Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
eta0, psi0 = Xmu * beta_mu, Xpsi * beta_psi

function inner_residual(a)
    gradient = DRM._ls_joint_grad(kind, y, eta0, psi0, gidx, a, precision)
    return (finite=all(isfinite, gradient), maxabs=isempty(gradient) ? 0.0 : norm(gradient, Inf))
end

function fixed_eval(a0)
    a, _, inner_ok = DRM._ls_inner_mode(kind, y, eta0, psi0, gidx, G, precision; a0=a0)
    value, _, nll_ok = DRM._ls_marginal_nll(kind, y, eta0, psi0, gidx, G, precision; a0=a0)
    full_gradient = DRM._ls_marginal_grad(kind, y, Xmu, Xpsi, gidx, G, Q, theta; a0=a0)
    return (inner_ok=inner_ok, inner_residual=inner_residual(a), nll_ok=nll_ok,
            value=value, full_gradient=full_gradient, free_gradient=full_gradient[free], mode=a)
end

reference = fixed_eval(nothing)
println("S11_ROSE_REFERENCE=(inner_ok=", reference.inner_ok, ", inner_residual=", repr(reference.inner_residual),
        ", nll_ok=", reference.nll_ok, ", value=", repr(reference.value), ", free_gradient_labels=", repr(free_labels),
        ", free_gradient=", repr(reference.free_gradient), ")")
for repeat in 1:3
    cold = fixed_eval(nothing)
    warm = fixed_eval(copy(reference.mode))
    println("S11_ROSE_REPEAT=", repr((repeat=repeat,
        cold=(inner_ok=cold.inner_ok, inner_residual=cold.inner_residual, nll_ok=cold.nll_ok,
              value=cold.value, free_gradient=cold.free_gradient),
        copied_mode=(inner_ok=warm.inner_ok, inner_residual=warm.inner_residual, nll_ok=warm.nll_ok,
                     value=warm.value, free_gradient=warm.free_gradient))))
end

l1, l21, l22 = lambda
L11, L22 = exp(l1), exp(l22)
prod_lambda = DRM._ls_lc_to_Λ(lambda)
prod_inverse = DRM._ls_inv2x2(prod_lambda)
prod_derivatives = [DRM._dΛ_dλ(lambda, k) for k in 1:3]
prod_contracts = [tr(prod_inverse * derivative) for derivative in prod_derivatives]
direct_lambda = [L11^2 L11*l21; L11*l21 l21^2 + L22^2]
direct_det = exp(2l1 + 2l22)
prod_det = prod_lambda[1,1] * prod_lambda[2,2] - prod_lambda[1,2] * prod_lambda[2,1]
direct_inverse = [1/L11^2 + l21^2/(L11^2 * L22^2) -l21/(L11 * L22^2);
                  -l21/(L11 * L22^2) 1/L22^2]
direct_derivatives = [[2L11^2 L11*l21; L11*l21 0.0],
                      [0.0 L11; L11 2l21],
                      [0.0 0.0; 0.0 2L22^2]]
direct_contracts = [tr(direct_inverse * derivative) for derivative in direct_derivatives]

high_precision = setprecision(256) do
    b1, bc, b3 = BigFloat.(lambda)
    ba, bb = exp(b1), exp(b3)
    big_lambda = BigFloat[ba^2 ba*bc; ba*bc bc^2+bb^2]
    big_det = exp(2b1 + 2b3)
    big_inverse = BigFloat[1/ba^2 + bc^2/(ba^2*bb^2) -bc/(ba*bb^2);
                          -bc/(ba*bb^2) 1/bb^2]
    big_derivatives = [BigFloat[2ba^2 ba*bc; ba*bc 0],
                       BigFloat[0 ba; ba 2bc],
                       BigFloat[0 0; 0 2bb^2]]
    (lambda=big_lambda, det=big_det, inverse=big_inverse,
     contracts=[tr(big_inverse * derivative) for derivative in big_derivatives])
end

println("S11_ROSE_COVARIANCE_FLOAT64=", repr((lambda=lambda, L11=L11, L21=l21, L22=L22,
    production_lambda=prod_lambda, direct_lambda=direct_lambda, production_det=prod_det,
    direct_det=direct_det, production_inverse=prod_inverse, direct_inverse=direct_inverse,
    production_contracts=prod_contracts, direct_contracts=direct_contracts,
    expected_contracts=(2.0, 0.0, 2.0), lambda_maxabs_diff=maximum(abs.(prod_lambda .- direct_lambda)),
    inverse_maxabs_diff=maximum(abs.(prod_inverse .- direct_inverse)))))
println("S11_ROSE_COVARIANCE_BIG256=", repr(high_precision))
println("S11_ROSE_COMPLETE")
