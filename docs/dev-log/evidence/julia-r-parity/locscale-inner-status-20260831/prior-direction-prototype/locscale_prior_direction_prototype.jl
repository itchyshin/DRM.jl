using DRM
using LinearAlgebra, SparseArrays, Serialization, SHA
const ROOT = "/private/tmp/drm-parity-20260830/integration/DRM.jl"
const CONTEXT = "/private/tmp/locscale_gamma_vcov_actual_context-001.jls"

# Reuse the retained five-state reconstruction and its full-input lifted NLL.
include("/private/tmp/locscale_estimated_error_five_state_pilot.jl")

@inline function two_sum(a::Float64, b::Float64)
    s = a + b
    z = s - a
    return s, (a - (s - z)) + (b - z)
end

@inline function triple_product_dd(a::Float64, b::Float64, c::Float64)
    p = a * b
    ep = fma(a, b, -p)
    q = p * c
    eq = fma(p, c, -q)
    # abc = q + eq + ep*c, up to the final residual addition.
    return q, eq + ep * c
end

function prior_direction_dd(P, a, d)
    hi = 0.0; lo = 0.0
    for j in axes(P,2), i in axes(P,1)
        xhi, xlo = triple_product_dd(d[i], P[i,j], a[j])
        s, e = two_sum(hi, xhi)
        t = lo + xlo + e
        hi, lo = two_sum(s, t)
    end
    return hi + lo
end

function hp_prior_direction(P, a, d, bits)
    setprecision(BigFloat, bits) do
        total = BigFloat(0)
        for j in axes(P,2), i in axes(P,1)
            total += BigFloat(d[i]) * BigFloat(P[i,j]) * BigFloat(a[j])
        end
        total
    end
end

function prior_direction_dd_info(P, a, d)
    hi = 0.0; lo = 0.0; tail_abs = 0.0; magnitude = 0.0; terms = 0
    for j in axes(P,2), i in axes(P,1)
        xhi, xlo = triple_product_dd(d[i], P[i,j], a[j])
        s, e = two_sum(hi, xhi)
        t = lo + xlo + e
        hi, lo2 = two_sum(s, t)
        lo = lo2
        tail_abs += abs(xlo) + abs(e) + abs(lo2)
        magnitude += abs(xhi)
        terms += 1
    end
    # Diagnostic-only conservative floating-point scale: expansion tails plus
    # one rounded accumulation per stored product. This is not a formal bound.
    scale = tail_abs + eps(Float64) * max(1, terms) * magnitude
    return (; value = hi + lo, tail_abs, magnitude, terms, scale)
end

function dd_dot(x, y)
    hi = 0.0; lo = 0.0
    for i in eachindex(x,y)
        xhi, xlo = triple_product_dd(x[i], y[i], 1.0)
        s,e = two_sum(hi,xhi)
        t=lo+xlo+e
        hi,lo=two_sum(s,t)
    end
    hi + lo
end

function proto_parts(s; reverse_rows=false)
    order = reverse_rows ? reverse(eachindex(s.y)) : eachindex(s.y)
    if reverse_rows
        y = s.y[order]; eta=s.eta[order]; psi=s.psi[order]; gidx=s.gidx[order]
        Zeta=s.Zeta[order,:]; Zpsi=s.Zpsi[order,:]
    else
        y=s.y; eta=s.eta; psi=s.psi; gidx=s.gidx; Zeta=s.Zeta; Zpsi=s.Zpsi
    end
    d=s.trial .- s.a
    prior=DRM._ls_inner_prior_components(s.P,s.a,d)
    data=DRM._ls_inner_data_direction(s.kind,y,eta,psi,gidx,s.a,d,Zeta,Zpsi)
    q8=DRM._ls_inner_data_quadrature(s.kind,y,eta,psi,gidx,s.a,d,Zeta,Zpsi,DRM._LS_GL8)
    g=DRM._ls_joint_grad(s.kind,y,eta,psi,gidx,s.a,s.P,Zeta,Zpsi)
    current=dot(g,d)+prior[2]+q8[1]
    prior_dd_info=prior_direction_dd_info(s.P,s.a,d)
    prior_dd=prior_dd_info.value
    proto_prior=prior_dd+data[1]+prior[2]+q8[1]
    proto_combined=dd_dot(g,d)+prior[2]+q8[1]
    return (; current, proto_prior, proto_combined, prior_current=prior[1], prior_dd,
            data_direction=data[1], prior_quadratic=prior[2], q8=q8[1],
            prior_dd_info)
end

function reverse_group_state(s; dense=false)
    idx = reduce(vcat, ([2g - 1, 2g] for g in reverse(1:s.G)))
    P = s.P[idx, idx]
    dense && (P = Matrix(P))
    return (; s..., P, a=s.a[idx], trial=s.trial[idx], gidx=s.G .+ 1 .- s.gidx)
end

# Capture the exact engine-order Gamma observed-information failure state.
ctx=deserialize(CONTEXT); theta=copy(ctx.theta); theta[1]-=ctx.h
pmu,ppsi=size(ctx.Xmu,2),size(ctx.Xpsi,2)
eta=ctx.Xmu*(@view theta[1:pmu]); psi=ctx.Xpsi*(@view theta[pmu+1:pmu+ppsi])
P=DRM.prior_precision(sparse(ctx.Q),DRM._ls_inv2x2(DRM._ls_lc_to_Λ(@view theta[pmu+ppsi+1:pmu+ppsi+3])))
a,ch,ok=DRM._ls_inner_mode(ctx.kind,ctx.y,eta,psi,ctx.gidx,ctx.G,P,ctx.Zeta,ctx.Zpsi;a0=ctx.a0)
g=DRM._ls_joint_grad(ctx.kind,ctx.y,eta,psi,ctx.gidx,a,P,ctx.Zeta,ctx.Zpsi)
H=DRM._ls_joint_hess(ctx.kind,ctx.y,eta,psi,ctx.gidx,ctx.G,a,P,ctx.Zeta,ctx.Zpsi)
F=cholesky(Symmetric(H);check=false); trial=a-F\g
states["gamma_vcov_k1minus"]=(;kind=ctx.kind,y=ctx.y,eta,psi,gidx=ctx.gidx,G=ctx.G,P,Zeta=ctx.Zeta,Zpsi=ctx.Zpsi,a,trial,
                                 f0=DRM._ls_joint(ctx.kind,ctx.y,eta,psi,ctx.gidx,a,P,ctx.Zeta,ctx.Zpsi),
                                 ft=DRM._ls_joint(ctx.kind,ctx.y,eta,psi,ctx.gidx,trial,P,ctx.Zeta,ctx.Zpsi))

println("PRIOR_DIRECTION_PROTOTYPE")
println("SOURCE_SHA ",bytes2hex(sha256(read(joinpath(ROOT,"src/locscale_inner.jl")))))
println("CONTEXT_SHA ",bytes2hex(sha256(read(CONTEXT))))
for name in sort!(collect(keys(states)))
    s=states[name]
    current=DRM._ls_inner_estimated_change(s.kind,s.y,s.eta,s.psi,s.gidx,s.G,s.P,s.Zeta,s.Zpsi,s.a,s.trial)
        parts=proto_parts(s)
    hp=hp_delta(s,s.trial,256)
    reversed=proto_parts(s;reverse_rows=true)
    dense_parts=proto_parts((; s..., P=Matrix(s.P)))
    group_parts=proto_parts(reverse_group_state(s))
    group_dense_parts=proto_parts(reverse_group_state(s; dense=true))
    zero_helper=DRM._ls_inner_estimated_change(s.kind,s.y,s.eta,s.psi,s.gidx,s.G,s.P,s.Zeta,s.Zpsi,s.a,s.a)
    uphill=2 .* s.a .- s.trial
    uphill_helper=DRM._ls_inner_estimated_change(s.kind,s.y,s.eta,s.psi,s.gidx,s.G,s.P,s.Zeta,s.Zpsi,s.a,uphill)
    println("CASE ",name,
            " HP256=",hp,
            " CURRENT_Q8=",current===nothing ? "nothing" : repr(current.q8),
            " CURRENT_E=",current===nothing ? "nothing" : repr(current.error),
            " CURRENT_MARGIN=",current===nothing ? "nothing" : repr(current.margin),
            " Q_ENGINE=",repr(parts.current),
            " Q_PRIOR_DD=",repr(parts.proto_prior),
            " Q_GRAD_DD=",repr(parts.proto_combined),
            " PRIOR_CURRENT=",repr(parts.prior_current),
            " PRIOR_DD=",repr(parts.prior_dd),
            " PRIOR_HP256=",hp_prior_direction(s.P,s.a,s.trial.-s.a,256),
            " PRIOR_DD_ERR=",BigFloat(parts.prior_dd)-hp_prior_direction(s.P,s.a,s.trial.-s.a,256),
            " PRIOR_DD_TAIL_SCALE=",repr(parts.prior_dd_info.scale),
            " PRIOR_DD_TERMS=",parts.prior_dd_info.terms,
            " Q_PRIOR_DD_ERR=",BigFloat(parts.proto_prior)-hp,
            " ROWREV_Q_ENGINE_DELTA=",repr(reversed.current-parts.current),
            " ROWREV_Q_PRIOR_DD_DELTA=",repr(reversed.proto_prior-parts.proto_prior),
            " DENSE_Q_PRIOR_DD_DELTA=",repr(dense_parts.proto_prior-parts.proto_prior),
            " GROUPPERM_Q_PRIOR_DD_DELTA=",repr(group_parts.proto_prior-parts.proto_prior),
            " GROUPPERM_DENSE_Q_PRIOR_DD_DELTA=",repr(group_dense_parts.proto_prior-parts.proto_prior),
            " ZERO_HELPER_NOTHING=",zero_helper===nothing,
            " UPHILL_MARGIN=",uphill_helper===nothing ? "nothing" : repr(uphill_helper.margin))
end
# A direct cancellation control contains no likelihood terms; compare the product path itself.
Pc=[1e10 0.0;0.0 1e10]; ac=[1.0,-1.0+2eps(1.0)]; dc=[1e-10,1e-10]
refc=hp_prior_direction(Pc,ac,dc,256)
compc=DRM._ls_inner_prior_components(Pc,ac,dc)[1]; ddc=prior_direction_dd(Pc,ac,dc)
println("CANCELLATION_CONTROL CURRENT=",repr(compc)," DD=",repr(ddc)," HP256=",refc,
        " CURRENT_ERR=",BigFloat(compc)-refc," DD_ERR=",BigFloat(ddc)-refc)
println("PRIOR_DIRECTION_PROTOTYPE_COMPLETE")
