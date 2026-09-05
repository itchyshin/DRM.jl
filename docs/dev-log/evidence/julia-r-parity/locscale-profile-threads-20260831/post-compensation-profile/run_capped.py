#!/usr/bin/env python3
# Foreground fresh-process runner. Usage: UTCSTAMP; hard cap 60 seconds.
import json, os, signal, subprocess, sys, time, hashlib
from pathlib import Path
stamp = sys.argv[1]
mode = "both"
if mode not in {'baseline', 'gradient', 'objective', 'both'}:
    raise SystemExit('mode must be baseline|gradient|objective|both')
outdir = Path('/private/tmp/drm-parity-20260830/profile-threads-s11/post-compensation-profile')
script = outdir / 'diagnose.jl'
log = outdir / f'post-compensation-profile-{stamp}.log'
status = outdir / f'post-compensation-profile-{stamp}.status.json'
cmd = ['julia', '--project=.', '--startup-file=no', '--history-file=no', str(script), str(log.with_suffix('.jls'))]
env = dict(os.environ); env.update(S11_MODE=mode, S11_STAMP=stamp, JULIA_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1')
assert not log.exists() and not status.exists(), 'refuse to overwrite evidence'
source = script.read_bytes()
log.with_suffix('.script-snapshot.jl').write_bytes(source)
started = time.time()
with log.open('wb') as fh:
    proc = subprocess.Popen(cmd, cwd='/private/tmp/drm-parity-20260830/integration/DRM.jl', env=env,
                            stdout=fh, stderr=subprocess.STDOUT, start_new_session=True)
    timed_out = False
    try: rc = proc.wait(timeout=60)
    except subprocess.TimeoutExpired:
        timed_out = True; os.killpg(proc.pid, signal.SIGTERM)
        try: rc = proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL); rc = proc.wait()
payload = {'kind':'post_compensation_profile_capped','mode':mode,'stamp':stamp,'command':cmd,
           'script_sha256':hashlib.sha256(source).hexdigest(),'julia_threads':1,'blas_threads':1,'pid':proc.pid,'process_group':proc.pid,'wall_seconds':time.time()-started,
           'hard_cap_seconds':60,'timed_out':timed_out,'returncode':rc,'log':str(log),'script':str(script)}
status.write_text(json.dumps(payload, indent=2, sort_keys=True)+'\n')
print(json.dumps(payload, sort_keys=True))
sys.exit(124 if timed_out else rc)
