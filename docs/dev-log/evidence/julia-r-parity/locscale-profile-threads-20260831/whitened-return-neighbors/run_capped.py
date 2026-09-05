import os,sys,time,subprocess,signal,json,hashlib
from pathlib import Path
root=Path(__file__).resolve().parent
stamp=sys.argv[1]
stem=root/f'whitened-return-neighbors-{stamp}'
script=root/'diagnose.jl'
assert not stem.with_suffix('.log').exists()
body=script.read_bytes(); stem.with_suffix('.script-snapshot.jl').write_bytes(body)
cmd=['julia','--project=.','--startup-file=no','--history-file=no',str(script),str(stem.with_suffix('.jls'))]
env=dict(os.environ,JULIA_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
t=time.monotonic();timeout=False
with stem.with_suffix('.log').open('wb') as f:
 p=subprocess.Popen(cmd,cwd='/private/tmp/drm-parity-20260830/integration/DRM.jl',env=env,stdout=f,stderr=subprocess.STDOUT,start_new_session=True)
 try:rc=p.wait(timeout=30)
 except subprocess.TimeoutExpired:
  timeout=True;os.killpg(p.pid,signal.SIGTERM)
  try:rc=p.wait(timeout=2)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);rc=p.wait()
r=dict(command=cmd,script_sha256=hashlib.sha256(body).hexdigest(),wall_seconds=time.monotonic()-t,hard_cap_seconds=30,timed_out=timeout,returncode=rc,pid=p.pid)
stem.with_suffix('.status.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps(r));print(stem.with_suffix('.log').read_text())
sys.exit(124 if timeout else rc)
