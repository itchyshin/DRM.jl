using DRM, Serialization, SHA, LinearAlgebra, SparseArrays
const ROOT = "/private/tmp/drm-parity-20260830/integration/DRM.jl"
const FIXTURE = joinpath(ROOT,"test/test_locscale_profile_threads.jl")
@assert bytes2hex(sha256(read(FIXTURE))) == "ca1d9db86c33fb8046028c0e9833d1e0cc0af095509d5580b48375a390bd7ad4"
const TEXT = read(FIXTURE,String)
const MARKER = findfirst("@testset \"canonical location-scale profile coefficient threading\"", TEXT)
Base.include_string(Main,TEXT[1:first(MARKER)-1],FIXTURE) # definitions before calls
hashes() = Dict(f=>bytes2hex(sha256(read(joinpath(ROOT,f)))) for f in
 ["src/locscale_inner.jl","src/locscale_grad.jl","src/locscale_profile.jl","src/inference.jl", "test/test_locscale_profile_threads.jl"])
function main()
 before=hashes()
 fit=_locscale_profile_threads_fixture() # unchanged public default-SE fit
 obj=fit.nll; base=size(obj.Xμ,2)+size(obj.Xψ,2)
 perm=vcat(collect(1:base),[base+1,base+3,base+2])
 theta=fit.theta[perm]
 result=profile_result(fit; parm=:mu,threads=false)
 endpoints=NamedTuple[]
 for (idx,row) in enumerate(result.endpoint_diagnostics), side in (:lower,:upper)
  endpoint=getproperty(row,side); nuisance=endpoint.nuisance
  nuisance===nothing && continue
  free=[k for k in eachindex(theta) if k!=idx]
  full=copy(theta); full[free].=nuisance.minimizer; full[idx]=endpoint.candidate
  P=DRM.prior_precision(obj.Q,DRM._ls_inv2x2(DRM._ls_lc_to_Λ(full[base+1:base+3])))
  eta=obj.Xμ*full[1:size(obj.Xμ,2)]; psi=obj.Xψ*full[size(obj.Xμ,2)+1:base]
  raw,mode,ok=DRM._ls_marginal_nll(obj.kind,obj.y,eta,psi,obj.gidx,obj.G,P)
  grad=DRM._ls_marginal_grad(obj.kind,obj.y,obj.Xμ,obj.Xψ,obj.gidx,obj.G,obj.Q,full;a0=mode)
  eigenvalues=eigvals(Symmetric(Matrix(P)))
  push!(endpoints,(idx=idx,side=side,endpoint=endpoint,theta=full,cold_raw=raw,
                   cold_inner_ok=ok,cold_mode=copy(mode),gradient_from_returned_mode=grad,
                   precision_eigenvalues=eigenvalues))
 end
 after=hashes()
 receipt=(kind=:post_compensation_public_profile,fixture_sha256=bytes2hex(sha256(read(FIXTURE))),
  before=before,after=after,unchanged=before==after,fit_converged=fit.converged,
  theta_engine=theta,public_se=stderror(fit),cold_nll=obj(theta),profile=result,endpoints=endpoints,
  design=(kind=obj.kind,y=obj.y,Xmu=obj.Xμ,Xpsi=obj.Xψ,gidx=obj.gidx,G=obj.G,Q=obj.Q),
  source=read(@__FILE__,String))
 serialize(only(ARGS),receipt)
 @assert before==after
 println("POST_COMPENSATION_PROFILE_RETAINED ",only(ARGS))
end
main()
