using DRM
using Serialization, LinearAlgebra, SparseArrays, SHA

const STATE = "/private/tmp/locscale_objective_arithmetic_states-001.jls"
states = deserialize(STATE)

linear_sum(xs) = foldl(+, xs; init=0.0)
function neumaier(xs)
    s = 0.0; c = 0.0
    for x in xs
        t = s + x
        c += abs(s) >= abs(x) ? (s - t) + x : (x - t) + s
        s = t
    end
    s + c
end
function float_terms(s, a; rev=false)
    inds = rev ? Base.reverse(eachindex(s.y)) : eachindex(s.y)
    xs = Float64[]
    for i in inds
        g=s.gidx[i]
        eta=s.eta[i]+s.Zeta[i,1]*a[2g-1]+s.Zeta[i,2]*a[2g]
        psi=s.psi[i]+s.Zpsi[i,1]*a[2g-1]+s.Zpsi[i,2]*a[2g]
        push!(xs, DRM._ls_nll(s.kind,s.y[i],eta,psi))
    end
    push!(xs, 0.5*dot(a,s.P*a))
    xs
end
function hp_sum_float_terms(xs, bits)
    setprecision(BigFloat,bits) do
        sum(BigFloat.(xs))
    end
end
function hp_recomputed(s, a, bits; rev=false)
    setprecision(BigFloat,bits) do
        total=BigFloat(0)
        inds = rev ? Base.reverse(eachindex(s.y)) : eachindex(s.y)
        for i in inds
            g=s.gidx[i]
            eta=BigFloat(s.eta[i])+BigFloat(s.Zeta[i,1])*BigFloat(a[2g-1])+BigFloat(s.Zeta[i,2])*BigFloat(a[2g])
            psi=BigFloat(s.psi[i])+BigFloat(s.Zpsi[i,1])*BigFloat(a[2g-1])+BigFloat(s.Zpsi[i,2])*BigFloat(a[2g])
            total += DRM._ls_nll(s.kind,BigFloat(s.y[i]),eta,psi)
        end
        prior=BigFloat(0)
        for j in axes(s.P,2), i in axes(s.P,1)
            prior += BigFloat(a[i])*BigFloat(s.P[i,j])*BigFloat(a[j])
        end
        total + prior/2
    end
end
function ranges(s,a)
    eta=Float64[]; psi=Float64[]
    for i in eachindex(s.y)
        g=s.gidx[i]
        push!(eta,s.eta[i]+s.Zeta[i,1]*a[2g-1]+s.Zeta[i,2]*a[2g])
        push!(psi,s.psi[i]+s.Zpsi[i,1]*a[2g-1]+s.Zpsi[i,2]*a[2g])
    end
    (eta=(minimum(eta),maximum(eta)), psi=(minimum(psi),maximum(psi)),
     nb2_rate=(-2maximum(psi),-2minimum(psi)))
end
function line(name,s)
    fa=float_terms(s,s.a); ft=float_terms(s,s.trial)
    fra=float_terms(s,s.a;rev=true); frt=float_terms(s,s.trial;rev=true)
    println("CASE ",name," CLAMP_RANGES_A ",ranges(s,s.a)," CLAMP_RANGES_T ",ranges(s,s.trial))
    println("FLOAT_LINEAR_FORWARD delta=",repr(linear_sum(ft)-linear_sum(fa)),
            " REVERSE delta=",repr(linear_sum(frt)-linear_sum(fra)),
            " NEUMAIER delta=",repr(neumaier(ft)-neumaier(fa)))
    for bits in (128,256)
        sf_a=hp_sum_float_terms(fa,bits); sf_t=hp_sum_float_terms(ft,bits)
        sr_a=hp_sum_float_terms(fra,bits); sr_t=hp_sum_float_terms(frt,bits)
        rf_a=hp_recomputed(s,s.a,bits); rf_t=hp_recomputed(s,s.trial,bits)
        rr_a=hp_recomputed(s,s.a,bits;rev=true); rr_t=hp_recomputed(s,s.trial,bits;rev=true)
        println("BITS ",bits,
                " SAME_TERMS_FORWARD delta=",sf_t-sf_a,
                " REVERSE delta=",sr_t-sr_a,
                " RECOMPUTED_FORWARD delta=",rf_t-rf_a,
                " RECOMPUTED_REVERSE delta=",rr_t-rr_a)
        # Additive-constant control: same calculation after a large literal
        # shift, exposing whether a Float64 comparison loses this tiny delta.
        c=1e12
        println("BITS ",bits," SHIFTED_FLOAT delta=",repr((linear_sum(ft)+c)-(linear_sum(fa)+c)),
                " SHIFTED_RECOMPUTED delta=",(rf_t+BigFloat(c))-(rf_a+BigFloat(c)))
    end
end
println("STATE_SHA ",bytes2hex(sha256(read(STATE))))
for name in sort!(collect(keys(states))); line(name,states[name]); end
