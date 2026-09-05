#!/usr/bin/env python3
import json,os,signal,subprocess,sys,time
from pathlib import Path
stamp=sys.argv[1];out=Path('/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-prototype/solver');script=out/'diagnose.jl';log=out/f'whitened-solver-{stamp}.log';status=out/f'whitened-solver-{stamp}.status.json';cmd=['julia','--project=.','--startup-file=no','--history-file=no',str(script)];env=dict(os.environ);env['S11_STAMP']=stamp;t=time.time()
with log.open('wb') as f:
 p=subprocess.Popen(cmd,cwd='/private/tmp/drm-parity-20260830/integration/DRM.jl',env=env,stdout=f,stderr=subprocess.STDOUT,start_new_session=True);timeout=False
 try:rc=p.wait(timeout=60)
 except subprocess.TimeoutExpired:
  timeout=True;os.killpg(p.pid,signal.SIGTERM)
  try:rc=p.wait(timeout=2)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);rc=p.wait()
r={'kind':'whitened_solver_foreground_cap','stamp':stamp,'command':cmd,'pid':p.pid,'process_group':p.pid,'wall_seconds':time.time()-t,'hard_cap_seconds':60,'timed_out':timeout,'returncode':rc,'log':str(log),'script':str(script)};status.write_text(json.dumps(r,indent=2,sort_keys=True)+'\n');print(json.dumps(r,sort_keys=True));sys.exit(124 if timeout else rc)
