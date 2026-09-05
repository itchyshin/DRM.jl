using DRM
using Serialization, LinearAlgebra, SparseArrays, SHA

const STATE = "/private/tmp/locscale_objective_arithmetic_states-001.jls"
states = deserialize(STATE)

# Deterministic Gauss--Legendre nodes/weights on [0,1], increasing-node order.
const GL = Dict(
  1 => ([0.5], [1.0]),
  2 => ([0.21132486540518713, 0.7886751345948129], [0.5, 0.5]),
  4 => ([0.06943184420297371, 0.33000947820757187, 0.6699905217924281, 0.9305681557970262],
        [0.17392742256872693, 0.32607257743127307, 0.32607257743127307, 0.17392742256872693]),
  8 => ([0.019855071751231856, 0.10166676129318664, 0.2372337950418355, 0.4082826787521751,
         0.5917173212478249, 0.7627662049581645, 0.8983332387068134, 0.9801449282487682],
        [0.05061426814518815, 0.11119051722668726, 0.15685332293894365, 0.181341891689181,
         0.181341891689181, 0.15685332293894365, 0.11119051722668726, 0.05061426814518815])
)

function hp_joint(s, a, bits)
  setprecision(BigFloat,bits) do
    total=BigFloat(0)
    for i in eachindex(s.y)
      g=s.gidx[i]
      eta=BigFloat(s.eta[i])+BigFloat(s.Zeta[i,1])*BigFloat(a[2g-1])+BigFloat(s.Zeta[i,2])*BigFloat(a[2g])
      psi=BigFloat(s.psi[i])+BigFloat(s.Zpsi[i,1])*BigFloat(a[2g-1])+BigFloat(s.Zpsi[i,2])*BigFloat(a[2g])
      total += DRM._ls_nll(s.kind,BigFloat(s.y[i]),eta,psi)
    end
    prior=BigFloat(0)
    for j in axes(s.P,2), i in axes(s.P,1)
      prior += BigFloat(a[i])*BigFloat(s.P[i,j])*BigFloat(a[j])
    end
    total+prior/2
  end
end
function hp_joint_grad(s,a,bits)
  setprecision(BigFloat,bits) do
    ab=BigFloat.(a); grad=zeros(BigFloat,length(a))
    for j in axes(s.P,2), i in axes(s.P,1)
      grad[i] += BigFloat(s.P[i,j])*ab[j]
    end
    for i in eachindex(s.y)
      g=s.gidx[i]
      eta=BigFloat(s.eta[i])+BigFloat(s.Zeta[i,1])*ab[2g-1]+BigFloat(s.Zeta[i,2])*ab[2g]
      psi=BigFloat(s.psi[i])+BigFloat(s.Zpsi[i,1])*ab[2g-1]+BigFloat(s.Zpsi[i,2])*ab[2g]
      ge,gp=DRM._ls_grad(s.kind,BigFloat(s.y[i]),eta,psi)
      grad[2g-1] += ge*BigFloat(s.Zeta[i,1])+gp*BigFloat(s.Zpsi[i,1])
      grad[2g] += ge*BigFloat(s.Zeta[i,2])+gp*BigFloat(s.Zpsi[i,2])
    end
    grad
  end
end
function smooth_components(s, d, bits, nnode)
  setprecision(BigFloat,bits) do
    ab=BigFloat.(s.a); db=BigFloat.(d)
    g=hp_joint_grad(s,s.a,bits)
    first=dot(g,db)
    prior=BigFloat(0)
    for j in axes(s.P,2), i in axes(s.P,1)
      prior += db[i]*BigFloat(s.P[i,j])*db[j]
    end
    prior /= 2
    nodes,weights=GL[nnode]
    data=BigFloat(0)
    for q in eachindex(nodes)
      t=BigFloat(nodes[q]); weight=BigFloat(weights[q])*(1-t)
      for i in eachindex(s.y)
        group=s.gidx[i]; u=2group-1
        de=BigFloat(s.Zeta[i,1])*db[u]+BigFloat(s.Zeta[i,2])*db[u+1]
        dp=BigFloat(s.Zpsi[i,1])*db[u]+BigFloat(s.Zpsi[i,2])*db[u+1]
        eta=BigFloat(s.eta[i])+BigFloat(s.Zeta[i,1])*(ab[u]+t*db[u])+BigFloat(s.Zeta[i,2])*(ab[u+1]+t*db[u+1])
        psi=BigFloat(s.psi[i])+BigFloat(s.Zpsi[i,1])*(ab[u]+t*db[u])+BigFloat(s.Zpsi[i,2])*(ab[u+1]+t*db[u+1])
        hee,hep,hpp=DRM._ls_hess(s.kind,BigFloat(s.y[i]),eta,psi)
        data += weight*(hee*de*de + 2hep*de*dp + hpp*dp*dp)
      end
    end
    (first=first, prior=prior, data=data, total=first+prior+data)
  end
end

function float_smooth_components(s, d, nnode)
  grad=DRM._ls_joint_grad(s.kind,s.y,s.eta,s.psi,s.gidx,s.a,s.P,s.Zeta,s.Zpsi)
  first=dot(grad,d); prior=0.5*dot(d,s.P*d)
  nodes,weights=GL[nnode]; data_terms=Float64[]
  for q in eachindex(nodes)
    t=nodes[q]; weight=weights[q]*(1-t)
    for i in eachindex(s.y)
      group=s.gidx[i]; u=2group-1
      de=s.Zeta[i,1]*d[u]+s.Zeta[i,2]*d[u+1]
      dp=s.Zpsi[i,1]*d[u]+s.Zpsi[i,2]*d[u+1]
      eta=s.eta[i]+s.Zeta[i,1]*(s.a[u]+t*d[u])+s.Zeta[i,2]*(s.a[u+1]+t*d[u+1])
      psi=s.psi[i]+s.Zpsi[i,1]*(s.a[u]+t*d[u])+s.Zpsi[i,2]*(s.a[u+1]+t*d[u+1])
      hee,hep,hpp=DRM._ls_hess(s.kind,s.y[i],eta,psi)
      push!(data_terms,weight*(hee*de*de+2hep*de*dp+hpp*dp*dp))
    end
  end
  data=sum(data_terms)
  data_hp=setprecision(256) do; sum(BigFloat.(data_terms)); end
  (first=first,prior=prior,data=data,data_hp=data_hp,total=first+prior+data,
   total_hp=BigFloat(first)+BigFloat(prior)+data_hp)
end

function ranges(s,d)
  function endpoint(a)
    eta=Float64[]; psi=Float64[]
    for i in eachindex(s.y)
      g=s.gidx[i]
      push!(eta,s.eta[i]+s.Zeta[i,1]*a[2g-1]+s.Zeta[i,2]*a[2g])
      push!(psi,s.psi[i]+s.Zpsi[i,1]*a[2g-1]+s.Zpsi[i,2]*a[2g])
    end
    (eta,psi)
  end
  ea,pa=endpoint(s.a); et,pt=endpoint(s.a.+d)
  (eta=(min(minimum(ea),minimum(et)),max(maximum(ea),maximum(et))),
   psi=(min(minimum(pa),minimum(pt)),max(maximum(pa),maximum(pt))),
   nb2_rate=(-2max(maximum(pa),maximum(pt)),-2min(minimum(pa),minimum(pt))))
end

function report_actual(name,s)
  d=s.trial.-s.a
  println("CASE ",name," SEGMENT_CLAMP_RANGES ",ranges(s,d))
  for bits in (128,256)
    ref=hp_joint(s,s.trial,bits)-hp_joint(s,s.a,bits)
    println("BITS ",bits," FULL_REFERENCE delta=",ref)
    for n in (1,2,4,8)
      try
        c=smooth_components(s,d,bits,n)
        println("BITS ",bits," GL",n," first=",c.first," prior=",c.prior,
                " data=",c.data," total=",c.total," diff_reference=",c.total-ref)
      catch err
        println("BITS ",bits," BIGFLOAT_HESSIAN_UNSUPPORTED ",typeof(err)," ",sprint(showerror,err))
        break
      end
    end
  end
  for n in (1,2,4,8)
    c=float_smooth_components(s,d,n)
    println("FLOAT_HESS_GL",n," first=",repr(c.first)," prior=",repr(c.prior),
            " data=",repr(c.data)," data_hp=",c.data_hp,
            " total=",repr(c.total)," total_hp=",c.total_hp)
  end
  # Opposite actual displacement, useful only if it is a positive-step control.
  rev=-d
  refrev=hp_joint(s,s.a.+rev,256)-hp_joint(s,s.a,256)
  c=float_smooth_components(s,rev,8)
  println("REVERSE_ACTUAL_256 reference=",refrev," FLOAT_HESS_GL8=",c.total_hp,
          " positive_control=",refrev>0)
end

function quadratic_control()
  a=BigFloat[1.2,-0.7]; d=BigFloat[0.03,-0.02]
  P=BigFloat[2 0.25;0.25 1.4]; Hd=BigFloat[1.1 -0.2;-0.2 0.9]; b=BigFloat[0.4,-0.3]
  g=P*a+Hd*a+b; exact=dot(g,d)+BigFloat(0.5)*dot(d,(P+Hd)*d)
  identity=dot(g,d)+BigFloat(0.5)*dot(d,P*d)+BigFloat(0.5)*dot(d,Hd*d)
  println("QUADRATIC_CONTROL exact=",exact," identity=",identity," difference=",identity-exact)
end
function quartic_control()
  a=BigFloat("1.1"); d=BigFloat("0.02"); c=BigFloat("0.7")
  exact=c*((a+d)^4-a^4); first=4c*a^3*d
  for n in (1,2,4,8)
    nodes,weights=GL[n]; integ=BigFloat(0)
    for q in eachindex(nodes)
      t=BigFloat(nodes[q]); integ += BigFloat(weights[q])*(1-t)*(12c*(a+t*d)^2)*d^2
    end
    println("QUARTIC_CONTROL GL",n," total=",first+integ," exact=",exact," difference=",first+integ-exact)
  end
end
println("STATE_SHA ",bytes2hex(sha256(read(STATE))))
quadratic_control(); quartic_control()
for name in sort!(collect(keys(states))); report_actual(name,states[name]); end
