#!/usr/bin/env python3
import json, os, signal, subprocess, sys, time
from pathlib import Path
stamp=sys.argv[1]; outdir=Path('/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-fixed-point')
script=outdir/'diagnose.jl'; log=outdir/f'whitened-fixed-point-{stamp}.log'; status=outdir/f'whitened-fixed-point-{stamp}.status.json'
cmd=['julia','--project=.','--startup-file=no','--history-file=no',str(script)]; env=dict(os.environ);env['S11_STAMP']=stamp
started=time.time()
with log.open('wb') as fh:
 p=subprocess.Popen(cmd,cwd='/private/tmp/drm-parity-20260830/integration/DRM.jl',env=env,stdout=fh,stderr=subprocess.STDOUT,start_new_session=True)
 timed=False
 try: rc=p.wait(timeout=30)
 except subprocess.TimeoutExpired:
  timed=True;os.killpg(p.pid,signal.SIGTERM)
  try:rc=p.wait(timeout=2)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);rc=p.wait()
result={'kind':'whitened_fixed_point_foreground_cap','stamp':stamp,'command':cmd,'pid':p.pid,'process_group':p.pid,'wall_seconds':time.time()-started,'hard_cap_seconds':30,'timed_out':timed,'returncode':rc,'log':str(log),'script':str(script)}
status.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n');print(json.dumps(result,sort_keys=True));sys.exit(124 if timed else rc)
