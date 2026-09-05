#!/usr/bin/env python3
import json, os, signal, subprocess, sys, time
from pathlib import Path
stamp = sys.argv[1]
outdir = Path('/private/tmp/drm-parity-20260830/profile-threads-s11/compensated-inner-experiment/objective-direction')
script = outdir / 'objective_direction.jl'
log = outdir / f'objective-direction-{stamp}.log'
status = outdir / f'objective-direction-{stamp}.status.json'
cmd = ['julia', '--project=.', '--startup-file=no', '--history-file=no', str(script)]
env = dict(os.environ); env['S11_STAMP'] = stamp
started = time.time()
with log.open('wb') as fh:
    proc = subprocess.Popen(cmd, cwd='/private/tmp/drm-parity-20260830/integration/DRM.jl', env=env,
                            stdout=fh, stderr=subprocess.STDOUT, start_new_session=True)
    timed_out = False
    try: rc = proc.wait(timeout=20)
    except subprocess.TimeoutExpired:
        timed_out = True; os.killpg(proc.pid, signal.SIGTERM)
        try: rc = proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL); rc = proc.wait()
elapsed = time.time() - started
payload = {'kind':'objective_direction_foreground_capped','stamp':stamp,'command':cmd,'pid':proc.pid,
           'process_group':proc.pid,'started_unix':started,'wall_seconds':elapsed,'hard_cap_seconds':20,
           'timed_out':timed_out,'returncode':rc,'log':str(log),'script':str(script)}
status.write_text(json.dumps(payload, indent=2, sort_keys=True)+'\n')
print(json.dumps(payload, sort_keys=True))
sys.exit(124 if timed_out else rc)
