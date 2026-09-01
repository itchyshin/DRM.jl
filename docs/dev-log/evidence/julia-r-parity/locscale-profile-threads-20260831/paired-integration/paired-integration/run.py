from pathlib import Path
import os,subprocess,hashlib,json,time,signal
repo=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl');base=Path(__file__).parent
stamp=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime());out=base/('paired-'+stamp)
script=base/'diagnose.jl'; snap=out.with_suffix('.script.jl');snap.write_bytes(script.read_bytes())
paths=list((repo/'src').glob('*.jl'))+[repo/'test/test_locscale_profile_threads.jl']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before={str(p.relative_to(repo)):sha(p) for p in paths}
cmd=['julia','--startup-file=no','--project='+str(repo),str(snap),str(out.with_suffix('.jls'))]
start=time.monotonic();timeout=False
with out.with_suffix('.log').open('xb') as f:
 p=subprocess.Popen(cmd,cwd=repo,env=dict(os.environ,JULIA_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1'),stdout=f,stderr=subprocess.STDOUT,start_new_session=True)
 try:code=p.wait(timeout=60)
 except subprocess.TimeoutExpired:timeout=True;os.killpg(p.pid,signal.SIGKILL);p.wait();code=124
after={str(p.relative_to(repo)):sha(p) for p in paths}
r=dict(command=cmd,seconds=time.monotonic()-start,estimate_seconds=30,cap_seconds=60,code=code,timed_out=timeout,before=before,after=after,unchanged=before==after,script_sha256=sha(snap))
out.with_suffix('.json').write_text(json.dumps(r,indent=2)+'\n')
print(out);print({k:v for k,v in r.items() if k not in ['before','after']})
raise SystemExit(code if before==after else 1)
