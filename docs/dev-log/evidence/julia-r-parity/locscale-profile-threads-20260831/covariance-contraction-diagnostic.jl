using DRM, LinearAlgebra, Serialization, SHA, SparseArrays

# Diagnostic only: lift frozen Float64 intermediates to BigFloat to isolate
# contraction roundoff. This is NOT an independent marginal-gradient oracle.
path = only(ARGS)
@assert bytes2hex(sha256(read(path))) == "d8727b67ae76c66fcc76cdd9f672b1f2bed72c165bf47e526caf50f769998434"
payload = deserialize(path)
s = payload.state
@assert Matrix(s.Q) == Matrix{Float64}(I, s.G, s.G)

function contractions(a, w, Hinv, Linv, dL, G)
    M = -Linv * dL * Linv
    tq = zero(eltype(a)); ta = zero(tq); tt = zero(tq)
    for g in 1:G
        ii = 2g-1:2g
        u = M * a[ii]
        tq += dot(a[ii], u)
        ta += dot(w[ii], u)
        tt += sum(Hinv[ii, ii] .* transpose(M))
    end
    normterm = G * tr(Linv * dL) / 2
    total = tq/2 + tt/2 - ta + normterm
    return (quad=tq/2, trace=tt/2, adjoint=-ta, normalization=normterm, total=total)
end

for (target, result) in zip(s.candidates, payload.optim_results)
    theta = copy(s.theta_engine)
    free = filter(!=(target.job_k), collect(eachindex(theta)))
    theta[target.job_k] = target.value
    theta[free] .= result.minimizer
    lambda = theta[4:6]
    Linv = DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda))
    P = DRM.prior_precision(s.Q, Linv)
    eta0 = s.Xmu * theta[1:2]; psi0 = s.Xpsi * theta[3:3]
    a, ch, ok = DRM._ls_inner_mode(s.kind, s.y, eta0, psi0, s.gidx, s.G, P)
    @assert ok
    Hinv = Matrix(DRM.takahashi_selinv(ch))
    v = zeros(2s.G)
    for i in eachindex(s.y)
        g = s.gidx[i]; j = 2g-1; k = 2g
        t1, t2, t3, t4 = DRM._ls_third(s.kind, s.y[i], eta0[i]+a[j], psi0[i]+a[k])
        alpha, beta, delta = Hinv[j,j], Hinv[j,k], Hinv[k,k]
        v[j] += (t1*alpha + 2t2*beta + t3*delta)/2
        v[k] += (t2*alpha + 2t3*beta + t4*delta)/2
    end
    w = ch \ v
    prodgrad = DRM._ls_marginal_grad(s.kind, s.y, s.Xmu, s.Xpsi, s.gidx, s.G, s.Q, theta)
    println("S11_CONTRACTION_STATE=", repr((label=target.label, theta=theta, gradient=prodgrad, mode=a)))
    for k in 1:3
        dL = DRM._dΛ_dλ(lambda, k)
        f64 = contractions(a,w,Hinv,Linv,dL,s.G)
        lifted = setprecision(BigFloat,256) do
            contractions(BigFloat.(a),BigFloat.(w),BigFloat.(Hinv),BigFloat.(Linv),BigFloat.(dL),s.G)
        end
        println("S11_CONTRACTION=", repr((label=target.label, covariance_index=k,
            float64=f64, lifted_frozen_intermediates=lifted,
            float_minus_lifted=BigFloat(f64.total)-lifted.total,
            production_component=prodgrad[3+k],
            production_minus_lifted=BigFloat(prodgrad[3+k])-lifted.total)))
    end
end
println("S11_CONTRACTION_COMPLETE")
