# Replays the pre-slice stored-gradient branch of `_profile_optimize` from this
# repository's HEAD in isolation.  This is evidence only: it does not load DRM
# or replace production code.
using Optim

function original_profile_optimize(obj, u0::Vector{Float64}; grad!)
    try
        od = Optim.OnceDifferentiable(obj, grad!, u0)
        method = Optim.LBFGS(; linesearch=Optim.LineSearches.BackTracking(; iterations=20))
        return Optim.optimize(
            od, u0, method, Optim.Options(; iterations=40, g_tol=1e-6, x_abstol=1e-8),
        )
    catch
        return Optim.optimize(
            obj, u0, Optim.LBFGS(), Optim.Options(; iterations=40, g_tol=1e-6, x_abstol=1e-8);
            autodiff=:finite,
        )
    end
end

# A deterministic chained Rosenbrock nuisance objective.  It is finite and
# differentiable throughout this probe, but the historical 40-iteration budget
# stops before the requested tolerance from this deliberately remote start.
function rosenbrock(u)
    total = zero(eltype(u))
    for i in 1:(length(u) - 1)
        total += 100 * (u[i + 1] - u[i]^2)^2 + (one(eltype(u)) - u[i])^2
    end
    return total
end

function rosenbrock_grad!(g, u)
    fill!(g, 0.0)
    for i in 1:(length(u) - 1)
        d = u[i + 1] - u[i]^2
        g[i] += -400 * u[i] * d - 2 * (1 - u[i])
        g[i + 1] += 200 * d
    end
    return g
end

u0 = [-1.2, 1.0, -1.2, 1.0, -1.2, 1.0, -1.2, 1.0]
result = original_profile_optimize(rosenbrock, u0; grad! = rosenbrock_grad!)
u = Optim.minimizer(result)
value = Optim.minimum(result)
println("converged=$(Optim.converged(result))")
println("iterations=$(Optim.iterations(result))")
println("finite_minimizer=$(all(isfinite, u))")
println("finite_minimum=$(isfinite(value))")
println("value=$value")
@assert !Optim.converged(result)
@assert all(isfinite, u)
@assert isfinite(value)
