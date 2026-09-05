using LinearAlgebra, SparseArrays, Serialization, SHA, SpecialFunctions
# Fixed points only: enumerate representable adjacent coordinates. No solver,
# production kernel, objective implementation or mutable production workspace.
const ROOT="/private/tmp/drm-parity-20260830/profile-threads-s11"
const INPUT=joinpath(ROOT,"whitened-prototype/solver/whitened-solver-20260831T182505Z.jls")
const INPUT_SHA="b841698cace0c39867995a8296ce90ac25ff2a08f68db32314e293bf49d044c2"
const DESIGN=joinpath(ROOT,"post-compensation-profile/post-compensation-profile-20260831T175800Z.jls")
const DESIGN_SHA="fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"

function components(d,t)
    tb=BigFloat.(t);L=BigFloat[exp(tb[4]) 0;tb[5] exp(tb[6])]
    B=kron(Matrix{BigFloat}(I,d.G,d.G),L)
    P=inv(B)'*inv(B)
    (;B,P,y=BigFloat.(d.y),eta=BigFloat.(d.Xmu)*tb[1:2],psi=BigFloat.(d.Xpsi)*tb[3:3])
end
function independent_gradient(d,c,a)
    ab=BigFloat.(a); g=c.P*ab; J=dot(ab,g)/2
    for i in eachindex(c.y)
        j=2d.gidx[i]-1;eta=c.eta[i]+ab[j];psi=c.psi[i]+ab[j+1]
        @assert abs(eta)<30 && abs(psi)<30
        s=exp(psi); rate=s*exp(-eta);ry=rate*c.y[i]
        g[j]+=s-ry
        g[j+1]+=s*(digamma(s)-log(rate)-1-log(c.y[i]))+ry
        J+=loggamma(s)-s*log(rate)-(s-1)*log(c.y[i])+ry
    end
    (;g,J,norm=norm(g),bound=BigFloat(1e-9)*(1+norm(ab)))
end
neighbors(x)=(prevfloat(x),x,nextfloat(x))
function one_case(d,e)
    setprecision(BigFloat,256) do
        @assert Matrix(d.Q)==Matrix{Float64}(I,d.G,d.G) "groupwise enumeration requires Q=I"
        cert=(e.second===nothing ? e.first : e.second).certificate
        c=components(d,e.theta);a=copy(cert.a); original=independent_gradient(d,c,a)
        chosen=copy(a); tables=NamedTuple[]
        # Q=I gives independent pair residuals, so minima combine exactly.
        for group in 1:d.G
            ix=2group-1:2group; candidates=NamedTuple[]
            for x in neighbors(a[ix[1]]), y in neighbors(a[ix[2]])
                trial=copy(a);trial[ix].=[x,y];r=independent_gradient(d,c,trial)
                push!(candidates,(pair=[x,y],residual2=sum(abs2,r.g[ix])))
            end
            k=argmin([r.residual2 for r in candidates]);chosen[ix].=candidates[k].pair
            push!(tables,(;group,candidates,selected=k))
        end
        result=independent_gradient(d,c,chosen)
        roundtrue=Float64.(c.B*BigFloat.(cert.z)); correctly_rounded=independent_gradient(d,c,roundtrue)
        (;idx=e.idx,side=e.side,theta=e.theta,a,chosen,tables,original,result,
          changed=chosen!=a,maxabs_change=maximum(abs,chosen-a),objective_change=result.J-original.J,
          initial_pass=original.norm<=original.bound,neighbor_pass=result.norm<=result.bound,
          rounded_true_Lz=roundtrue,correctly_rounded,
          correctly_rounded_pass=correctly_rounded.norm<=correctly_rounded.bound)
    end
end
function main()
    @assert bytes2hex(sha256(read(INPUT)))==INPUT_SHA
    @assert bytes2hex(sha256(read(DESIGN)))==DESIGN_SHA
    d=deserialize(DESIGN).design;input=deserialize(INPUT)
    rows=[one_case(d,e) for e in input.cases]
    serialize(only(ARGS),(;rows,input_sha256=INPUT_SHA,design_sha256=DESIGN_SHA,
      scope="Fixed-state gradient feasibility only; no full mode certificate, solver repair or inference result"))
    for r in rows
        println((;r.idx,r.side,initial=Float64(r.original.norm),neighbor=Float64(r.result.norm),
          bound=Float64(r.result.bound),r.neighbor_pass,correctly_rounded=Float64(r.correctly_rounded.norm),
          r.correctly_rounded_pass,r.maxabs_change))
    end
    println("FIXED_NEIGHBOR_ENUMERATION_COMPLETE")
end
main()
