using DRM
using LinearAlgebra, SparseArrays, Serialization, SHA
const ROOT = "/private/tmp/drm-parity-20260830/integration/DRM.jl"
const CONTEXT = "/private/tmp/locscale_gamma_vcov_actual_context-001.jls"

function hp_joint(kind, y, eta0, psi0, gidx, P, Zeta, Zpsi, a, bits)
    setprecision(BigFloat, bits) do
        value = BigFloat(0)
        for i in eachindex(y)
            g = gidx[i]; u = 2g - 1
            eta = BigFloat(eta0[i]) + BigFloat(Zeta[i,1]) * BigFloat(a[u]) + BigFloat(Zeta[i,2]) * BigFloat(a[u+1])
            psi = BigFloat(psi0[i]) + BigFloat(Zpsi[i,1]) * BigFloat(a[u]) + BigFloat(Zpsi[i,2]) * BigFloat(a[u+1])
            value += DRM._ls_nll(kind, BigFloat(y[i]), eta, psi)
        end
        prior = BigFloat(0)
        for j in axes(P,2), i in axes(P,1)
            prior += BigFloat(a[i]) * BigFloat(P[i,j]) * BigFloat(a[j])
        end
        return value + prior / 2
    end
end

function hp_gradient(kind, y, eta0, psi0, gidx, P, Zeta, Zpsi, a, bits)
    setprecision(BigFloat, bits) do
        out = zeros(BigFloat, length(a))
        for j in axes(P,2), i in axes(P,1)
            out[i] += BigFloat(P[i,j]) * BigFloat(a[j])
        end
        for i in eachindex(y)
            g = gidx[i]; u = 2g - 1
            eta = BigFloat(eta0[i]) + BigFloat(Zeta[i,1]) * BigFloat(a[u]) + BigFloat(Zeta[i,2]) * BigFloat(a[u+1])
            psi = BigFloat(psi0[i]) + BigFloat(Zpsi[i,1]) * BigFloat(a[u]) + BigFloat(Zpsi[i,2]) * BigFloat(a[u+1])
            ge, gp = DRM._ls_grad(kind, BigFloat(y[i]), eta, psi)
            out[u] += ge * BigFloat(Zeta[i,1]) + gp * BigFloat(Zpsi[i,1])
            out[u+1] += ge * BigFloat(Zeta[i,2]) + gp * BigFloat(Zpsi[i,2])
        end
        out
    end
end

function hp_prior_direction(P, a, d, bits)
    setprecision(BigFloat, bits) do
        s = BigFloat(0)
        for j in axes(P,2), i in axes(P,1)
            s += BigFloat(d[i]) * BigFloat(P[i,j]) * BigFloat(a[j])
        end
        s
    end
end

function float_term_sums(kind, y, eta0, psi0, gidx, P, Zeta, Zpsi, a)
    terms = Float64[]
    for i in eachindex(y)
        g = gidx[i]; u = 2g - 1
        eta = eta0[i] + Zeta[i,1] * a[u] + Zeta[i,2] * a[u+1]
        psi = psi0[i] + Zpsi[i,1] * a[u] + Zpsi[i,2] * a[u+1]
        push!(terms, DRM._ls_nll(kind, y[i], eta, psi))
    end
    for j in axes(P,2), i in axes(P,1)
        push!(terms, 0.5 * a[i] * P[i,j] * a[j])
    end
    naive = sum(terms)
    compensated = 0.0; correction = 0.0
    for term in terms
        total = compensated + term
        correction += abs(compensated) >= abs(term) ? (compensated - total) + term : (term - total) + compensated
        compensated = total
    end
    same_float_hp = setprecision(BigFloat, 256) do
        sum(BigFloat.(terms))
    end
    return (; naive, compensated = compensated + correction, same_float_hp)
end

function report_gradient(label, kind, y, eta0, psi0, gidx, P, Zeta, Zpsi, a)
    gf = DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P,Zeta,Zpsi)
    g128 = hp_gradient(kind,y,eta0,psi0,gidx,P,Zeta,Zpsi,a,128)
    g256 = hp_gradient(kind,y,eta0,psi0,gidx,P,Zeta,Zpsi,a,256)
    diff128_256 = maximum(abs.(g128 .- g256))
    diff_float_256 = maximum(abs.(BigFloat.(gf) .- g256))
    println("GRAD ",label,
            " FLOAT_NORM=",repr(norm(gf)),
            " HP256_NORM=",sqrt(sum(abs2,g256)),
            " MAX_FLOAT_HP256=",diff_float_256,
            " MAX_HP128_HP256=",diff128_256,
            " FLOAT_FINITE=",all(isfinite,gf),
            " HP256_FINITE=",all(isfinite,g256))
end

ctx = deserialize(CONTEXT)
kind = ctx.kind
θ = copy(ctx.theta); θ[1] -= ctx.h
pμ, pψ = size(ctx.Xmu,2), size(ctx.Xpsi,2)
eta0 = ctx.Xmu * (@view θ[1:pμ]); psi0 = ctx.Xpsi * (@view θ[pμ+1:pμ+pψ])
P = DRM.prior_precision(sparse(ctx.Q), DRM._ls_inv2x2(DRM._ls_lc_to_Λ(@view θ[pμ+pψ+1:pμ+pψ+3])))
a = copy(ctx.a0)
inner_a, ch, ok = DRM._ls_inner_mode(kind,ctx.y,eta0,psi0,ctx.gidx,ctx.G,P,ctx.Zeta,ctx.Zpsi;a0=a)
grad = DRM._ls_joint_grad(kind,ctx.y,eta0,psi0,ctx.gidx,inner_a,P,ctx.Zeta,ctx.Zpsi)
H = DRM._ls_joint_hess(kind,ctx.y,eta0,psi0,ctx.gidx,ctx.G,inner_a,P,ctx.Zeta,ctx.Zpsi)
F = cholesky(Symmetric(H);check=false)
step = F \ grad
trial = inner_a .- step
f0 = DRM._ls_joint(kind,ctx.y,eta0,psi0,ctx.gidx,inner_a,P,ctx.Zeta,ctx.Zpsi)
ft = DRM._ls_joint(kind,ctx.y,eta0,psi0,ctx.gidx,trial,P,ctx.Zeta,ctx.Zpsi)
d = trial .- inner_a
est = DRM._ls_inner_estimated_change(kind,ctx.y,eta0,psi0,ctx.gidx,ctx.G,P,ctx.Zeta,ctx.Zpsi,inner_a,trial)
prior = DRM._ls_inner_prior_components(P,inner_a,d)
direction = DRM._ls_inner_data_direction(kind,ctx.y,eta0,psi0,ctx.gidx,inner_a,d,ctx.Zeta,ctx.Zpsi)
q2 = DRM._ls_inner_data_quadrature(kind,ctx.y,eta0,psi0,ctx.gidx,inner_a,d,ctx.Zeta,ctx.Zpsi,DRM._LS_GL2)
q4 = DRM._ls_inner_data_quadrature(kind,ctx.y,eta0,psi0,ctx.gidx,inner_a,d,ctx.Zeta,ctx.Zpsi,DRM._LS_GL4)
q8 = DRM._ls_inner_data_quadrature(kind,ctx.y,eta0,psi0,ctx.gidx,inner_a,d,ctx.Zeta,ctx.Zpsi,DRM._LS_GL8)
raw_prior = dot(d, P * inner_a)
hpprior128 = hp_prior_direction(P,inner_a,d,128); hpprior256 = hp_prior_direction(P,inner_a,d,256)
hp0_128 = hp_joint(kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,inner_a,128)
hpt_128 = hp_joint(kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,trial,128)
hp0_256 = hp_joint(kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,inner_a,256)
hpt_256 = hp_joint(kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,trial,256)
terms0 = float_term_sums(kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,inner_a)
termst = float_term_sums(kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,trial)
println("GAMMA_K1_MINUS_ARITHMETIC")
println("SOURCE_SHA ",bytes2hex(sha256(read(joinpath(ROOT,"src/locscale_inner.jl")))))
println("CONTEXT_SHA ",bytes2hex(sha256(read(CONTEXT))))
println("INNER_OK ",ok," INNER_F_PD ",issuccess(F)," INNER_GNORM ",norm(grad)," INNER_BOUND ",1e-9*(1+norm(inner_a)))
println("TRIAL_DISPLACEMENT ",norm(d)," TRIAL_GRADNORM ",norm(DRM._ls_joint_grad(kind,ctx.y,eta0,psi0,ctx.gidx,trial,P,ctx.Zeta,ctx.Zpsi))," TRIAL_BOUND ",1e-9*(1+norm(trial)))
println("FLOAT_F0 ",repr(f0)," FLOAT_FT ",repr(ft)," FLOAT_DELTA ",repr(ft-f0)," FOUR_ULP ",repr(4max(eps(abs(f0)),eps(abs(ft)))))
println("HP_DELTA_128 ",hpt_128-hp0_128," HP_DELTA_256 ",hpt_256-hp0_256," HP_DELTA_128_256 ",(hpt_128-hp0_128)-(hpt_256-hp0_256))
println("FLOAT_TERM_SUMS base_naive=",repr(terms0.naive)," trial_naive=",repr(termst.naive),
        " delta_naive=",repr(termst.naive-terms0.naive)," delta_compensated=",repr(termst.compensated-terms0.compensated),
        " delta_same_float_terms_hp=",termst.same_float_hp-terms0.same_float_hp,
        " same_float_terms_vs_full_hp256=",(termst.same_float_hp-terms0.same_float_hp)-(hpt_256-hp0_256))
println("ESTIMATE ",repr(est))
println("S_SPLIT directional_scale=",repr(est.directional_scale)," prior_quadratic_scale=",repr(est.prior_scale)," quadrature_scale=",repr(est.quadrature_scale))
println("S_COMPONENTS prior_direction_scale=",repr(prior[3])," data_direction_scale=",repr(direction[2]),
        " prior_quadratic_scale=",repr(prior[4])," q2_scale=",repr(q2[2]),
        " q4_scale=",repr(q4[2])," q8_scale=",repr(q8[2]))
println("SIGNED_COMPONENTS engine_dot=",repr(dot(grad,d))," prior_direction=",repr(prior[1])," prior_quadratic=",repr(prior[2])," data_direction=",repr(direction[1])," q2data=",repr(q2[1])," q4data=",repr(q4[1])," q8data=",repr(q8[1]))
println("PRIOR_DIRECTION_FLOAT_MATVEC ",repr(raw_prior)," PRIOR_DIRECTION_COMPENSATED ",repr(prior[1])," PRIOR_DIRECTION_HP128 ",hpprior128," PRIOR_DIRECTION_HP256 ",hpprior256," PRIOR_MATVEC_ERR ",BigFloat(raw_prior)-hpprior256," PRIOR_COMP_ERR ",BigFloat(prior[1])-hpprior256)
report_gradient("BASE",kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,inner_a)
report_gradient("TRIAL",kind,ctx.y,eta0,psi0,ctx.gidx,P,ctx.Zeta,ctx.Zpsi,trial)
println("GAMMA_K1_MINUS_ARITHMETIC_COMPLETE")
