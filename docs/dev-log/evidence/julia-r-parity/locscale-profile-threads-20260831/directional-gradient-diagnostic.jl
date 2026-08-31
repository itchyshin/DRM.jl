using SHA
using Serialization
using LinearAlgebra
using DRM
using Optim

artifact_path = only(ARGS)
payload = deserialize(artifact_path)
state = payload.state
result = payload.optim_results[1]
target = state.candidates[1]
free = 2:6
free_labels = [:mu_x, :sigma_intercept, :logL11, :L21, :logL22]
theta0 = copy(state.theta_engine)
theta0[1] = target.value
theta0[free] .= Optim.minimizer(result)
kind, y, Xmu, Xpsi, gidx, G, Q = state.kind, state.y, state.Xmu, state.Xpsi, state.gidx, state.G, state.Q
p_mu, p_psi = size(Xmu, 2), size(Xpsi, 2)

function cold_objective(theta)
    beta_mu = @view theta[1:p_mu]
    beta_psi = @view theta[p_mu+1:p_mu+p_psi]
    lambda = theta[p_mu+p_psi+1:p_mu+p_psi+3]
    precision = DRM.prior_precision(Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
    value, _, ok = DRM._ls_marginal_nll(kind, y, Xmu * beta_mu, Xpsi * beta_psi, gidx, G, precision; a0=nothing)
    return (value=value, ok=ok)
end

function cold_gradient(theta)
    full = DRM._ls_marginal_grad(kind, y, Xmu, Xpsi, gidx, G, Q, theta; a0=nothing)
    return full[free]
end

baseline = cold_objective(theta0)
gradient = cold_gradient(theta0)
directions = [
    (label=:unit_L21, direction=[0.0, 0.0, 0.0, 1.0, 0.0]),
    (label=:normalized_negative_free_gradient, direction=-gradient / norm(gradient)),
]
steps = (1e-2, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8)

println("S11_DIRECTIONAL_ARTIFACT_SHA256=", bytes2hex(sha256(read(artifact_path))))
println("S11_DIRECTIONAL_PACKING=(full_labels=[:mu_intercept,:mu_x,:sigma_intercept,:logL11,:L21,:logL22], fixed_index=1, free_labels=", repr(free_labels), ", theta=", repr(theta0), ")")
println("S11_DIRECTIONAL_BASELINE=(status=", baseline.ok, ", value=", repr(baseline.value), ", free_gradient=", repr(gradient), ")")
for entry in directions
    direction = entry.direction
    gdotd = dot(gradient, direction)
    println("S11_DIRECTIONAL_DIRECTION=", repr((label=entry.label, direction=direction, gdotd=gdotd)))
    for step in steps
        theta_plus = copy(theta0); theta_plus[free] .+= step .* direction
        theta_minus = copy(theta0); theta_minus[free] .-= step .* direction
        plus = cold_objective(theta_plus)
        minus = cold_objective(theta_minus)
        derivative = (plus.value - minus.value) / (2step)
        raw_delta = plus.value - baseline.value
        actual_displacement = theta_plus[free] .- theta0[free]
        println("S11_DIRECTIONAL_STEP=", repr((label=entry.label, requested_step=step,
            actual_displacement=actual_displacement, plus_status=plus.ok, minus_status=minus.ok,
            central_derivative=derivative, gdotd=gdotd, raw_forward_delta=raw_delta,
            expected_linear_delta=step*gdotd, plus_value=plus.value, minus_value=minus.value)))
    end
end
println("S11_DIRECTIONAL_COMPLETE")
