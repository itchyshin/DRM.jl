using DRM, Serialization, SHA, LinearAlgebra, SparseArrays
const INPUT = "/private/tmp/drm-parity-20260830/profile-threads-s11/post-compensation-profile/post-compensation-profile-20260831T175800Z.jls"
const BEFORE_FILES = ["src/locscale_inner.jl","src/locscale_grad.jl","src/locscale_marginal.jl"]
hashes()=Dict(f=>bytes2hex(sha256(read(f))) for f in BEFORE_FILES)
function direct_precision(lambda)
 u,c,v=lambda
 k11=exp(-u); k21=-c*exp(-(u+v)); k22=exp(-v)
 return [k11*k11+k21*k21 k21*k22; k21*k22 k22*k22]
end
function contractions(a,w,Hinv,M,Q,k)
 tq=ta=tt=zero(eltype(M))
 qr=rowvals(Q);qv=nonzeros(Q)
 for h in axes(Q,2), ptr in nzrange(Q,h)
  g=qr[ptr];q=qv[ptr]
  ag1,ag2=a[2g-1],a[2g];ah1,ah2=a[2h-1],a[2h]
  mh1=M[1,1]*ah1+M[1,2]*ah2;mh2=M[2,1]*ah1+M[2,2]*ah2
  tq+=q*(ag1*mh1+ag2*mh2)
  ta+=q*(w[2g-1]*mh1+w[2g]*mh2)
  tt+=q*(Hinv[2g-1,2h-1]*M[1,1]+Hinv[2g-1,2h]*M[2,1]+Hinv[2g,2h-1]*M[1,2]+Hinv[2g,2h]*M[2,2])
 end
 return (quad=tq,adjoint=ta,trace=tt,total=tq/2+tt/2-ta+(k==2 ? 0 : size(Q,1)))
end
function one_endpoint(e,d)
 theta=e.theta;lambda=theta[4:6];a=e.cold_mode
 eta=d.Xmu*theta[1:2];psi=d.Xpsi*theta[3:3]
 P0=DRM.prior_precision(d.Q,DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
 P1=DRM.prior_precision(d.Q,direct_precision(lambda))
 D=DRM._ls_joint_hess(d.kind,d.y,eta,psi,d.gidx,d.G,a,spzeros(2d.G,2d.G))
 H=P0+D;ch=cholesky(Symmetric(H));S=DRM.takahashi_selinv(ch)
 adj=zeros(2d.G)
 for i in eachindex(d.y)
  g=d.gidx[i];u=2g-1;v=2g
  t1,t2,t3,t4=DRM._ls_third(d.kind,d.y[i],eta[i]+a[u],psi[i]+a[v])
  adj[u]+=(t1*S[u,u]+2t2*S[u,v]+t3*S[v,v])/2
  adj[v]+=(t2*S[u,u]+2t3*S[u,v]+t4*S[v,v])/2
 end
 w=ch\adj; M=DRM._ls_precision_derivatives(lambda)
 float_contracts=[contractions(a,w,S,M[k],d.Q,k) for k in 1:3]
 reference=setprecision(BigFloat,256) do
  u,c,v=BigFloat.(lambda);K=BigFloat[exp(-u) 0;-c*exp(-(u+v)) exp(-v)]
  Ptrue=kron(BigFloat.(Matrix(d.Q)),transpose(K)*K)
  ab=BigFloat.(a);Db=BigFloat.(Matrix(D));qbig=sparse(BigFloat.(d.Q))
  expected_logdet=2logdet(Symmetric(BigFloat.(Matrix(d.Q))))-2d.G*(u+v)
  precisions=NamedTuple[]
  for (name,P) in ((:old,P0),(:direct,P1))
   Pb=BigFloat.(Matrix(P));Hb=BigFloat.(Matrix(P+D))
   expectedH=Pb+Db
   push!(precisions,(name=name,entry_relative_error=norm(Pb-Ptrue)/norm(Ptrue),
    action_error=norm((Pb-Ptrue)*ab),quadratic_error=dot(ab,(Pb-Ptrue)*ab)/2,
    roundedP_logdet_error=logdet(Symmetric(Pb))-expected_logdet,
    floatP_logdet_error=BigFloat(logdet(cholesky(Symmetric(P))))-logdet(Symmetric(Pb)),
    hessian_addition_error=norm(Hb-expectedH),
    floatH_logdet_error=BigFloat(logdet(cholesky(Symmetric(P+D))))-logdet(Symmetric(expectedH))))
  end
  lifted=[contractions(BigFloat.(a),BigFloat.(w),BigFloat.(S),BigFloat.(M[k]),qbig,k) for k in 1:3]
  # Independent product-rule derivative of K'K, not production closed entries.
  dKs=(BigFloat[-K[1,1] 0;-K[2,1] 0],BigFloat[0 0;-exp(-(u+v)) 0],BigFloat[0 0;-K[2,1] -K[2,2]])
  exact=[contractions(BigFloat.(a),BigFloat.(w),BigFloat.(S),transpose(dKs[k])*K+transpose(K)*dKs[k],qbig,k) for k in 1:3]
  return (precision=precisions,lifted=lifted,exact_derivative=exact,
   contraction_rounding_error=[BigFloat(float_contracts[k].total)-lifted[k].total for k in 1:3],
   derivative_entry_error=[lifted[k].total-exact[k].total for k in 1:3])
 end
 return (idx=e.idx,side=e.side,theta=theta,cold_mode_accepted=e.cold_inner_ok,
         fixed_mode=a,float_contracts=float_contracts,reference=reference)
end
before=hashes();input=deserialize(INPUT);@assert input.unchanged
cases=[one_endpoint(e,input.design) for e in input.endpoints]
after=hashes();receipt=(kind=:fixed_state_precision_and_contractions,input_sha256=bytes2hex(sha256(read(INPUT))),
 before=before,after=after,unchanged=before==after,cases=cases,source=read(@__FILE__,String))
serialize(only(ARGS),receipt);@assert before==after
for c in cases
 println("CASE ",c.idx," ",c.side," cold_accepted=",c.cold_mode_accepted)
 for p in c.reference.precision
  println((name=p.name,entryrelative=Float64(p.entry_relative_error),action=Float64(p.action_error),quadratic=Float64(p.quadratic_error),P_logdet=Float64(p.roundedP_logdet_error),P_factor=Float64(p.floatP_logdet_error),H_add=Float64(p.hessian_addition_error),H_factor=Float64(p.floatH_logdet_error)))
 end
 println("covariance_contraction_rounding=",Float64.(c.reference.contraction_rounding_error))
 println("covariance_derivative_rounding=",Float64.(c.reference.derivative_entry_error))
end
println("FIXED_COMPONENTS_RETAINED ",only(ARGS))
