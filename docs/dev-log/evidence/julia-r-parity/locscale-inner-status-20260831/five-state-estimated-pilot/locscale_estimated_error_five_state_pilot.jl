using DRM
using Distributions, LinearAlgebra, Random, Serialization, SHA, SparseArrays

const ROOT = "/private/tmp/drm-parity-20260830/integration/DRM.jl"
const STATE_PATH = "/private/tmp/locscale_objective_arithmetic_states-001.jls"

function fixture_state(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    pmu, ppsi = size(Xmu, 2), size(Xpsi, 2)
    λ = theta[pmu + ppsi + 1:pmu + ppsi + 3]
    P = DRM.prior_precision(Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(λ)))
    return Xmu * theta[1:pmu], Xpsi * theta[pmu + 1:pmu + ppsi], P
end

# Replays only the pre-pilot strict Float64 updates used by the historical
# full-Newton diagnostic. It does not call the current inner solver.
function old_state_before(kind, y, η0, ψ0, gidx, G, P; target=200)
    Zη = DRM._ls_canonical_Zeta(length(y))
    Zψ = DRM._ls_canonical_Zpsi(length(y))
    a = zeros(2G)
    for iter in 1:(target - 1)
        grad = DRM._ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        H = DRM._ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
        f0 = DRM._ls_joint(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
        λ = 0.0
        stepped = false
        while λ <= 1e12
            F = cholesky(Symmetric(H + λ * I); check=false)
            if issuccess(F)
                step = F \ grad
                α = 1.0
                while α >= 1e-10
                    trial = a .- α .* step
                    ft = DRM._ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)
                    if isfinite(ft) && ft <= f0
                        a = trial
                        stepped = true
                        break
                    end
                    α *= 0.5
                end
                stepped && break
            end
            λ = λ == 0.0 ? 1e-8 : 10λ
        end
        stepped || error("historical replay stalled before target=$target at iter=$iter")
    end
    return a, Zη, Zψ
end

function hp_joint(s, a, bits)
    setprecision(BigFloat, bits) do
        total = BigFloat(0)
        for i in eachindex(s.y)
            g = s.gidx[i]
            η = BigFloat(s.eta[i]) + BigFloat(s.Zeta[i,1]) * BigFloat(a[2g-1]) +
                BigFloat(s.Zeta[i,2]) * BigFloat(a[2g])
            ψ = BigFloat(s.psi[i]) + BigFloat(s.Zpsi[i,1]) * BigFloat(a[2g-1]) +
                BigFloat(s.Zpsi[i,2]) * BigFloat(a[2g])
            total += DRM._ls_nll(s.kind, BigFloat(s.y[i]), η, ψ)
        end
        prior = BigFloat(0)
        for j in axes(s.P, 2), i in axes(s.P, 1)
            prior += BigFloat(a[i]) * BigFloat(s.P[i,j]) * BigFloat(a[j])
        end
        total + prior / 2
    end
end

function hp_delta(s, trial, bits)
    hp_joint(s, trial, bits) - hp_joint(s, s.a, bits)
end

opposite_accepted(result) = result !== nothing &&
    all(isfinite, (result.estimate, result.error, result.margin)) && result.margin >= 0

function metrics(name, s)
    result = DRM._ls_inner_estimated_change(s.kind, s.y, s.eta, s.psi, s.gidx, s.G,
                                             s.P, s.Zeta, s.Zpsi, s.a, s.trial)
    reverse_trial = 2 .* s.a .- s.trial
    opposite = DRM._ls_inner_estimated_change(s.kind, s.y, s.eta, s.psi, s.gidx, s.G,
                                               s.P, s.Zeta, s.Zpsi, s.a, reverse_trial)
    if "--corrupt-opposite" in ARGS && name == "historical_gamma_plus1"
        opposite = (estimate = 1.0, error = 0.0, margin = -1.0)
    end
    d128 = hp_delta(s, s.trial, 128); d256 = hp_delta(s, s.trial, 256)
    o128 = hp_delta(s, reverse_trial, 128); o256 = hp_delta(s, reverse_trial, 256)
    reference_agreement = abs(d128 - d256) / abs(d256)
    opposite_reference_agreement = abs(o128 - o256) / abs(o256)
    println("CASE ", name,
            " RAW=", repr(s.ft - s.f0),
            " ESTIMATE=", result === nothing ? "nothing" : repr(result.estimate),
            " ERROR=", result === nothing ? "nothing" : repr(result.error),
            " MARGIN=", result === nothing ? "nothing" : repr(result.margin),
            " HP128=", d128, " HP256=", d256,
            " HP128_256_REL=", reference_agreement,
            " RELERR=", result === nothing ? "NA" : repr(abs(BigFloat(result.estimate) - d256) / abs(d256)),
            " WITHIN_MARGIN=", result === nothing ? "false" : repr(abs(BigFloat(result.estimate) - d256) <= BigFloat(result.error)),
            " OPP_ESTIMATE=", opposite === nothing ? "nothing" : repr(opposite.estimate),
            " OPP_MARGIN=", opposite === nothing ? "nothing" : repr(opposite.margin),
            " OPP_HP128=", o128, " OPP_HP256=", o256,
            " OPP_HP128_256_REL=", opposite_reference_agreement)
    result !== nothing || return false
    isfinite(result.estimate) && isfinite(result.error) && isfinite(result.margin) ||
        error("nonfinite estimated result for $name")
    reference_agreement <= BigFloat(1e-15) ||
        error("128/256 reference disagreement for $name")
    abs(BigFloat(result.estimate) - d256) / abs(d256) <= BigFloat(1e-4) ||
        error("relative-error threshold failure for $name")
    abs(BigFloat(result.estimate) - d256) <= BigFloat(result.error) ||
        error("margin-understates observed error for $name")
    result.margin < 0 || error("expected negative resolved margin for $name")
    opposite_accepted(opposite) || error("opposite helper result rejected for $name")
    opposite_reference_agreement <= BigFloat(1e-15) ||
        error("opposite 128/256 mismatch for $name")
    o256 > 0 || error("opposite step did not increase for $name")
    return true
end

function full_trial(name, kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    η0, ψ0, P = fixture_state(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    a, Zη, Zψ = old_state_before(kind, y, η0, ψ0, gidx, G, P)
    grad = DRM._ls_joint_grad(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    H = DRM._ls_joint_hess(kind, y, η0, ψ0, gidx, G, a, P, Zη, Zψ)
    F = cholesky(Symmetric(H); check=false)
    issuccess(F) || error("no historical undamped PD trial for $name")
    trial = a .- F \ grad
    f0 = DRM._ls_joint(kind, y, η0, ψ0, gidx, a, P, Zη, Zψ)
    ft = DRM._ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)
    return (; kind, y, eta=η0, psi=ψ0, gidx, G, P, Zeta=Zη, Zpsi=Zψ,
            a, trial, f0, ft)
end

states = Dict{String,Any}()
Random.seed!(202)
Gg=5; mg=6; ng=Gg*mg; gidxg=repeat(1:Gg, inner=mg)
xg=randn(ng); zg=randn(ng); Xmug=hcat(ones(ng),xg); Xpsig=hcat(ones(ng),zg)
Lg=cholesky(Symmetric(DRM._ls_lc_to_Λ([log(.35),.05,log(.4)]))).L
Ag=[Lg*randn(2) for _ in 1:Gg]
yg=[begin
    α=exp(.5+Ag[gidxg[i]][2]); μ=exp(.2+.3xg[i]+Ag[gidxg[i]][1])
    rand(Distributions.Gamma(α, μ/α))
end for i in 1:ng]
states["historical_gamma_plus1"] = full_trial("historical_gamma_plus1", Val(:gamma), yg,
    Xmug, Xpsig, gidxg, Gg, sparse(1.0I,Gg,Gg), [.150001,.25,.4,.06,log(.4),.05,log(.45)])

Random.seed!(303)
p=6; m=6; n=p*m; phy=random_balanced_tree(p;branch_length=.25)
C=sigma_phy_dense(phy;σ²_phy=1.0); LC=cholesky(Symmetric(C)).L
LΛ=cholesky(Symmetric(DRM._ls_lc_to_Λ([log(.4),0.,log(.3)]))).L
A=LC*randn(p,2)*LΛ'; species=repeat(1:p,inner=m)
x=randn(n); z=randn(n); Xmu=hcat(ones(n),x); Xpsi=hcat(ones(n),z)
ynb=[begin
    r=exp(.2+A[species[i],2]); μ=exp(.15+.4x[i]+A[species[i],1])
    Float64(rand(Distributions.NegativeBinomial(r,r/(r+μ))))
end for i in 1:n]
Q,gidx,G=DRM._locscale_phylo_setup(phy,species)
states["historical_nb2_plus2"] = full_trial("historical_nb2_plus2", Val(:nb2), ynb,
    Xmu, Xpsi, gidx, G, Q, [.2,.300001,.1,.04,log(.42),.05,log(.32)])
states["historical_nb2_minus3"] = full_trial("historical_nb2_minus3", Val(:nb2), ynb,
    Xmu, Xpsi, gidx, G, Q, [.2,.3,.099999,.04,log(.42),.05,log(.32)])

saved = deserialize(STATE_PATH)
states["saved_gamma"] = saved["gamma"]
states["saved_nb2"] = saved["nb2"]

println("FIVE_STATE_ESTIMATED_PILOT")
println("SOURCE_SHA ", bytes2hex(sha256(read(joinpath(ROOT,"src/locscale_inner.jl")))))
println("SAVED_STATE_SHA ", bytes2hex(sha256(read(STATE_PATH))))
println("COUNT ", length(states))
for name in sort!(collect(keys(states)))
    metrics(name, states[name]) || error("no estimate for $name")
end
println("FIVE_STATE_ESTIMATED_PILOT_OK")
