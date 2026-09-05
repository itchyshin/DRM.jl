using DRM, LinearAlgebra, Serialization, SHA
@assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
fpath=joinpath(pwd(),"test/test_locscale_profile_threads.jl")
@assert bytes2hex(sha256(read(fpath)))=="ca1d9db86c33fb8046028c0e9833d1e0cc0af095509d5580b48375a390bd7ad4"
prefix=split(read(fpath,String),"@testset \"canonical location-scale profile coefficient threading\"";limit=2)[1]
include_string(Main,prefix,fpath)
fit=_locscale_profile_threads_fixture(); obj=fit.nll
@assert obj.whitened
@assert !DRM.LocScaleObjective(obj.kind,obj.y,obj.Xμ,obj.Xψ,obj.gidx,obj.G,obj.Q).whitened
base=size(obj.Xμ,2)+size(obj.Xψ,2);perm=vcat(collect(1:base),[base+1,base+3,base+2]);theta=fit.theta[perm]
println("FIT ", (;theta,converged=fit.converged,nll=obj(theta),grad=DRM._ls_objective_gradient(obj,theta),se=stderror(fit),V=vcov(fit)))
result=profile_result(fit;parm=:mu,threads=false)
println("PROFILE ",result)
points=[]
for (idx,ep) in enumerate(result.endpoint_diagnostics), side in (:lower,:upper)
 status=getproperty(ep,side); n=status.nuisance
 n===nothing && continue
 full=copy(theta); free=[i for i in eachindex(theta) if i!=idx]
 full[free].=n.minimizer;full[idx]=status.candidate
 white=DRM._ls_whitened_eval(obj.kind,obj.y,obj.Xμ,obj.Xψ,obj.gidx,obj.G,obj.Q,full,DRM._ls_canonical_Zeta(length(obj.y)),DRM._ls_canonical_Zpsi(length(obj.y)))
 point=(;idx,side,theta=full,nuisance=n,white)
 push!(points,point)
 println("POINT ",(;idx,side,theta=full,nuisance=n,value=white.value,gradient=white.gradient,status=white.status))
end
serialize(ARGS[1],(;fit,result,points,theta,threads=Threads.nthreads(),blas=BLAS.get_num_threads()))
