from pathlib import Path
import os,subprocess,hashlib,json,time,signal,sys
repo=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl');base=Path(__file__).parent
bundles={
 'finite-profile':['test_locscale_profile_threads.jl'],
 'whitened':['test_locscale_whitened.jl'],
 'kernels':['test_locscale_kernels.jl','test_locscale_inner.jl','test_locscale_inner_status.jl','test_locscale_marginal.jl','test_locscale_grad.jl','test_locscale_compensated_gradient.jl','test_locscale_precision_derivatives.jl','test_locscale_whitened.jl'],
 'serial-profile':['test_locscale_profile_threads.jl','test_locscale_profile_status.jl','test_profile_nuisance_status.jl','test_inference_blas_pinning.jl'],
 'thread-status':['test_locscale_profile_status.jl','test_profile_nuisance_status.jl','test_inference_blas_pinning.jl']}
name=sys.argv[1];threads=int(sys.argv[2]);names=bundles[name]
stamp=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime());out=base/(name+'-'+stamp)
paths=list((repo/'src').glob('*.jl'))+[repo/'test'/n for n in names]+[repo/'test/runtests.jl']+list((repo/'test/fixtures/locscale_precision').glob('*'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before={str(p.relative_to(repo)):sha(p) for p in paths}
script='using DRM, Test, LinearAlgebra\n@assert Threads.nthreads()=='+str(threads)+' && BLAS.get_num_threads()==1\n'+''.join('include('+json.dumps(str(repo/'test'/n))+')\n' for n in names)+'\nprintln("REGRESSION_BUNDLE_PASS")\n'
snap=out.with_suffix('.jl');snap.write_text(script)
cmd=['julia','--startup-file=no','--project='+str(repo),str(snap)]
start=time.monotonic();timeout=False
with out.with_suffix('.log').open('xb') as f:
 p=subprocess.Popen(cmd,cwd=repo,env=dict(os.environ,JULIA_NUM_THREADS=str(threads),OPENBLAS_NUM_THREADS='1'),stdout=f,stderr=subprocess.STDOUT,start_new_session=True)
 try:code=p.wait(timeout=30)
 except subprocess.TimeoutExpired:timeout=True;os.killpg(p.pid,signal.SIGKILL);p.wait();code=124
after={str(p.relative_to(repo)):sha(p) for p in paths}
r=dict(command=cmd,seconds=time.monotonic()-start,estimate_seconds=30,cap_seconds=30,code=code,timed_out=timeout,before=before,after=after,unchanged=before==after,script_sha256=sha(snap),julia_threads=threads,blas_threads=1)
out.with_suffix('.json').write_text(json.dumps(r,indent=2)+'\n')
print(out);print({k:v for k,v in r.items() if k not in ['before','after']})
raise SystemExit(code if before==after else 1)
