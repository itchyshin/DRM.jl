using DRM, LinearAlgebra, SparseArrays, Serialization, SHA
# Scratch mathematical prototype. Dense inverse is an independent small-model
# reference, not a proposed production algorithm. No source overrides.
const SOURCE=["src/locscale_inner.jl","src/locscale_grad.jl","src/locscale_fit.jl"]
hashes()=Dict(p=>bytes2hex(sha256(read(p))) for p in SOURCE)

function white_eval(d,t; gradient=true)
    p=size(d.Xmu,2); q=size(d.Xpsi,2); u,c,v=t[p+q+1:end]
    L=[exp(u) 0.;c exp(v)]; A=d.Zeta*L; B=d.Zpsi*L
    eta=d.Xmu*t[1:p]; psi=d.Xpsi*t[p+1:p+q]
    P=DRM.prior_precision(d.Q,Matrix{Float64}(I,2,2))
    z,ch,ok=DRM._ls_inner_mode(d.kind,d.y,eta,psi,d.gidx,d.G,P,A,B;tol=1e-12)
    gz=DRM._ls_joint_grad(d.kind,d.y,eta,psi,d.gidx,z,P,A,B)
    a=vec(L*reshape(z,2,:)); ga=vec(transpose(L)\reshape(gz,2,:))
    certified=ok && norm(ga)<=1e-9*(1+norm(a)) && ch!==nothing && issuccess(ch)
    certified || error("uncertified moderate-point solve: $(norm(ga)), white=$ok")
    @assert all(i->abs(eta[i]+dot(A[i,:],z[2d.gidx[i]-1:2d.gidx[i]]))<DRM.LS_CLAMP &&
                  abs(psi[i]+dot(B[i,:],z[2d.gidx[i]-1:2d.gidx[i]]))<DRM.LS_PSI_CLAMP,eachindex(d.y))
    value=DRM._ls_joint(d.kind,d.y,eta,psi,d.gidx,z,P,A,B)+logdet(ch)/2-logdet(cholesky(Symmetric(d.Q)))
    gradient || return value
    S=Matrix(ch\Matrix{Float64}(I,2d.G,2d.G)); obs=NamedTuple[]; adj=zeros(2d.G)
    for i in eachindex(d.y)
        ix=2d.gidx[i]-1:2d.gidx[i]; W=vcat(A[i,:]',B[i,:]')
        h=DRM._ls_hess(d.kind,d.y[i],eta[i]+dot(A[i,:],z[ix]),psi[i]+dot(B[i,:],z[ix]))
        D=[h[1] h[2];h[2] h[3]]
        score=collect(DRM._ls_grad(d.kind,d.y[i],eta[i]+dot(A[i,:],z[ix]),psi[i]+dot(B[i,:],z[ix])))
        t3=DRM._ls_third(d.kind,d.y[i],eta[i]+dot(A[i,:],z[ix]),psi[i]+dot(B[i,:],z[ix]))
        R=W*S[ix,ix]*W'
        kappa=[(t3[1]*R[1,1]+2t3[2]*R[1,2]+t3[3]*R[2,2])/2,
               (t3[2]*R[1,1]+2t3[3]*R[1,2]+t3[4]*R[2,2])/2]
        adj[ix] .+= W'*kappa
        push!(obs,(;ix,W,D,score,kappa))
    end
    w=ch\adj; grad=zeros(length(t))
    dLs=([L[1,1] 0.;0. 0.],[0. 0.;1. 0.],[0. 0.;0. L[2,2]])
    for (i,o) in enumerate(obs)
        ix=o.ix; r=o.score+o.kappa-o.D*o.W*w[ix]
        grad[1:p] .+= d.Xmu[i,:]*r[1]; grad[p+1:p+q] .+= d.Xpsi[i,:]*r[2]
        Zi=vcat(d.Zeta[i,:]',d.Zpsi[i,:]')
        for k in 1:3
            dW=Zi*dLs[k]
            grad[p+q+k]+=dot(r,dW*z[ix])-dot(o.score,dW*w[ix])+sum((o.D*o.W*S[ix,ix]).*dW)
        end
    end
    (;value,grad,z,a,original_residual=norm(ga),bound=1e-9*(1+norm(a)))
end

function one_case(kind,general)
    G=3;n=18;x=collect(range(-1,1;length=n));gidx=repeat(1:G;inner=6)
    Xmu=hcat(ones(n),x);Xpsi=hcat(ones(n),cos.(2x))
    y=kind==Val(:gamma) ? exp.(.2 .+ .4x .+ .25sin.(collect(1:n))) : Float64.(mod.(collect(1:n).*7,9))
    Q=general ? sparse([1.7 -.2 .1;-.2 1.3 -.15;.1 -.15 1.9]) : sparse(1.0I,G,G)
    Zeta=general ? hcat(1 .+ .1x,.2sin.(x)) : hcat(ones(n),zeros(n))
    Zpsi=general ? hcat(.15cos.(x),1 .- .1x) : hcat(zeros(n),ones(n))
    d=(;kind,y,Xmu,Xpsi,gidx,G,Q,Zeta,Zpsi)
    t=[.15,.25,.4,.06,log(.4),.05,log(.45)]
    candidate=white_eval(d,t)
    fd=[[(white_eval(d,t+[j==k ? h : 0. for j in eachindex(t)];gradient=false)-
           white_eval(d,t-[j==k ? h : 0. for j in eachindex(t)];gradient=false))/(2h)
          for k in eachindex(t)] for h in (1e-4,1e-5,1e-6)]
    original=DRM._ls_fit_nll(kind,y,Xmu,Xpsi,gidx,G,Q,t,Zeta,Zpsi)
    original_grad=DRM._ls_marginal_grad(kind,y,Xmu,Xpsi,gidx,G,Q,t,Zeta,Zpsi)
    errors=[maximum(abs,g-candidate.grad) for g in fd]
    (;kind,general,d,t,candidate,fd,errors,original,original_grad,
      objective_error=abs(candidate.value-original),gradient_error=maximum(abs,candidate.grad-original_grad),
      pass=maximum(errors)<2e-6 && abs(candidate.value-original)<1e-8 && maximum(abs,candidate.grad-original_grad)<2e-6,
      damaged_gradient_rejected=maximum(abs,(-candidate.grad)-fd[2])>2e-6,
      missing_normalization_rejected=general ? abs(logdet(cholesky(Symmetric(Q))))>1e-8 : true)
end

function main()
    before=hashes(); rows=[one_case(kind,general) for kind in (Val(:gamma),Val(:nb2)) for general in (false,true)]
    after=hashes(); receipt=(;rows,before,after,unchanged=before==after,scope="Moderate-model transformed derivative diagnostic; not near-boundary solver or production evidence")
    serialize(only(ARGS),receipt)
    for r in rows
        println((;r.kind,r.general,r.errors,r.objective_error,r.gradient_error,r.pass,r.damaged_gradient_rejected,r.missing_normalization_rejected))
    end
    @assert before==after
    @assert all(r->r.pass && r.damaged_gradient_rejected && r.missing_normalization_rejected,rows)
    println("WHITENED_GRADIENT_MODERATE_PASS")
end
main()
