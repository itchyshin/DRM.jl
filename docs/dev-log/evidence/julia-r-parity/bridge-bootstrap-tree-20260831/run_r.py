from pathlib import Path
import os, subprocess, hashlib, json, time, signal, sys
base=Path(__file__).parent
r=Path('/private/tmp/drm-parity-20260830/integration/drmTMB')
j=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=list((r/'R').glob('*.R'))+list((j/'src').glob('*.jl'))+list((r/'src').glob('*.so'))+[base/'actual-r.R',base/'run_r.py']+list((base/'fixture').glob('*'))
for nt in ([int(sys.argv[1])] if len(sys.argv)>1 else [1,4]):
 assert nt in (1,4)
 out=base/('actual-r-threads'+str(nt)+'-'+time.strftime('%Y%m%dT%H%M%SZ',time.gmtime()))
 before={str(p):sha(p) for p in paths};start=time.monotonic();timed_out=False
 cmd=['Rscript','--vanilla',str(base/'actual-r.R')]
 with out.with_suffix('.log').open('xb') as log:
  proc=subprocess.Popen(cmd,cwd=r,env=dict(os.environ,JULIA_NUM_THREADS=str(nt),OPENBLAS_NUM_THREADS='1',OMP_NUM_THREADS='1',DRM_JL_PATH=str(j)),stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
  try:code=proc.wait(timeout=60)
  except subprocess.TimeoutExpired:timed_out=True;os.killpg(proc.pid,signal.SIGKILL);proc.wait();code=124
 after={str(p):sha(p) for p in paths}
 record=dict(command=cmd,code=code,seconds=time.monotonic()-start,cap_seconds=60,estimate_seconds=60,timed_out=timed_out,before=before,after=after,unchanged=before==after,julia_threads=nt,blas_threads=1)
 out.with_suffix('.json').write_text(json.dumps(record,indent=2)+'\n')
 print(out, {k:v for k,v in record.items() if k not in ('before','after')},flush=True)
 if code!=0 or before!=after:sys.exit(code or 1)
print('R_TREE_BOOTSTRAP_CHECK_PASS')
