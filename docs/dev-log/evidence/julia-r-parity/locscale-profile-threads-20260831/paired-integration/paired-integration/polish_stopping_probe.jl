using DRM,Serialization,LinearAlgebra
@assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
saved=deserialize(joinpath(@__DIR__,"paired-20260831T191719Z.jls"));o=saved.fit.nll;p=last(saved.points)
println("START ",p.nuisance)
r=DRM._ls_profile_nll_result(o.kind,o.y,o.Xμ,o.Xψ,o.gidx,o.G,o.Q,saved.theta,2,p.theta[2];whitened=true,x0=p.nuisance.minimizer)
println("RESTART ",r)
free=[1,3,4,5,6]; warm=Ref{Union{Nothing,DRM._LSWhitenedSeed}}(nothing)
build(x)=(t=copy(p.theta);t[free].=x;t)
f(x)=begin
 a=DRM._ls_whitened_eval(o.kind,o.y,o.Xμ,o.Xψ,o.gidx,o.G,o.Q,build(x),DRM._ls_canonical_Zeta(length(o.y)),DRM._ls_canonical_Zpsi(length(o.y));seed=warm[],gradient=false)
 a.status.ok && (warm[]=a.seed);a.status.ok ? a.value : 1e18
end
g!(g,x)=(g .= DRM._ls_whitened_eval(o.kind,o.y,o.Xμ,o.Xψ,o.gidx,o.G,o.Q,build(x),DRM._ls_canonical_Zeta(length(o.y)),DRM._ls_canonical_Zpsi(length(o.y));seed=warm[]).gradient[free];g)
res=DRM.Optim.optimize(f,g!,p.nuisance.minimizer,DRM.Optim.LBFGS(linesearch=DRM.Optim.LineSearches.BackTracking()),DRM.Optim.Options(g_tol=1e-7,iterations=10,x_abstol=NaN,x_reltol=NaN,f_abstol=NaN,f_reltol=NaN,store_trace=true,extended_trace=true))
status=DRM._ls_profile_candidate_status(f,g!,DRM.Optim.minimizer(res),DRM.Optim.converged(res))
println("STRICT ",status," iterations=",DRM.Optim.iterations(res));println(res)
serialize(ARGS[1],(;restart=r,strict=status,result=res))
