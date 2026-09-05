from pathlib import Path
import datetime
import hashlib
import json
import os
import signal
import subprocess
import sys
import time

repo = Path('/private/tmp/drm-parity-20260830/integration/DRM.jl')
out = repo / 'docs/dev-log/evidence/julia-r-parity/locscale-inner-status-20260831'
probe = out / 'verify_estimated_change_varied.jl'
source = repo / 'src/locscale_inner.jl'
label, expected_source = sys.argv[1:3]
damage = len(sys.argv) > 3 and sys.argv[3] == 'negative-control'
if any((out / (label + suffix)).exists() for suffix in ('.log', '.json')):
    raise SystemExit('Refusing to overwrite retained evidence: ' + label)

def hashes():
    paths = sorted(repo.glob('src/**/*.jl')) + [probe, repo/'Project.toml', repo/'Manifest.toml']
    return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in paths if p.exists()}

before = hashes()
if before['src/locscale_inner.jl'] != expected_source:
    raise SystemExit('Source differs from the frozen candidate; no run started')
command = ['/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia',
           '--project=.', '--startup-file=no', str(probe)]
env = dict(os.environ, JULIA_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1',
           DRM_ESTIMATED_CHANGE_NEGATIVE_CONTROL='1' if damage else '0')
started = datetime.datetime.now(datetime.timezone.utc).isoformat()
clock = time.monotonic()
timeout = False
with (out/(label+'.log')).open('x') as log:
    process = subprocess.Popen(command, cwd=repo, env=env, stdout=log,
                               stderr=subprocess.STDOUT, start_new_session=True)
    try:
        rc = process.wait(timeout=120)
    except subprocess.TimeoutExpired:
        timeout = True
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        rc = 124
after = hashes()
receipt = dict(started_utc=started, elapsed_seconds=time.monotonic()-clock,
               exit_code=rc, timed_out=timeout, cap_seconds=120,
               negative_control=damage, command=command, before=before, after=after,
               inputs_unchanged=before == after,
               head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip())
with (out/(label+'.json')).open('x') as fh:
    json.dump(receipt, fh, indent=2)
    fh.write('\n')
print((out/(label+'.log')).read_text())
print(json.dumps({k:v for k,v in receipt.items() if k not in ('before','after','command')}))
sys.exit(rc if rc else (0 if before == after else 2))
