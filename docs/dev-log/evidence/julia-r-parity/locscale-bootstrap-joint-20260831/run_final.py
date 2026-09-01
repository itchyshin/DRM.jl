from pathlib import Path
import os,subprocess,hashlib,json,time,signal,sys
r=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl');b=Path(__file__).parent
nt=int(sys.argv[2]); assert nt in (1,4)
name=sys.argv[1];names={'neighbours':['test_simulate.jl','test_simulate_scale_conventions.jl'],'scales':['test_simulate_scale_conventions.jl'],'sampler':['test_locscale_bootstrap_simulator.jl'],'refit':['test_locscale_bootstrap_refit.jl'],'profile':['test_locscale_profile_threads.jl'],'final':['test_simulate.jl','test_simulate_scale_conventions.jl','test_locscale_bootstrap_simulator.jl','test_locscale_bootstrap_refit.jl']}[name]
stamp=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime());out=b/(name+'-threads'+str(nt)+'-'+stamp)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=list((r/'src').glob('*.jl'))+[r/'test'/n for n in names]
before={str(p.relative_to(r)):sha(p) for p in paths}
script='using DRM,Test,LinearAlgebra; @assert Threads.nthreads()=='+str(nt)+' && BLAS.get_num_threads()==1\n@testset "bounded bootstrap regression" begin\n'+''.join('include('+json.dumps(str(r/'test'/n))+')\n' for n in names)+'end\nprintln("BOOTSTRAP_SLICE_PASS")\n'
out.with_suffix('.jl').write_text(script)
for n in names:(b/(out.name+'-'+n)).write_bytes((r/'test'/n).read_bytes())
start=time.monotonic();timeout=False;cmd=['julia','--startup-file=no','--project='+str(r),str(out.with_suffix('.jl'))]
with out.with_suffix('.log').open('xb') as f:
 p=subprocess.Popen(cmd,cwd=r,env=dict(os.environ,JULIA_NUM_THREADS=str(nt),OPENBLAS_NUM_THREADS='1'),stdout=f,stderr=subprocess.STDOUT,start_new_session=True)
 try:code=p.wait(timeout=60)
 except subprocess.TimeoutExpired:timeout=True;os.killpg(p.pid,signal.SIGKILL);p.wait();code=124
after={str(p.relative_to(r)):sha(p) for p in paths}
rj=dict(command=cmd,code=code,seconds=time.monotonic()-start,estimate_seconds=60,cap_seconds=60,timed_out=timeout,before=before,after=after,unchanged=before==after,julia_threads=nt,blas_threads=1)
out.with_suffix('.json').write_text(json.dumps(rj,indent=2)+'\n');print(out);print({k:v for k,v in rj.items() if k not in ['before','after']})
raise SystemExit(code if before==after else 1)
