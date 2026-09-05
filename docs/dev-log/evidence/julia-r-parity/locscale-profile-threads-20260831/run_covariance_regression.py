import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

repo = Path('/private/tmp/drm-parity-20260830/integration/DRM.jl')
base = Path(__file__).resolve().parent
label = sys.argv[1]
assert label.replace('-', '').replace('_', '').isalnum()
stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
log = base / f'covariance-regression-{label}-{stamp}.log'
paths = [repo / name for name in (
    'src/locscale_grad.jl', 'src/locscale_inner.jl', 'src/inference.jl',
    'test/test_locscale_precision_derivatives.jl',
    'test/fixtures/locscale_precision/locscale_gamma_l21.toml',
    'test/test_locscale_profile_threads.jl',
)]
def hashes():
    return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
before = hashes()
command = ['julia', '--startup-file=no', f'--project={repo}', '-e',
           'include("test/test_locscale_precision_derivatives.jl"); println("LOCSCALE_PRECISION_REFERENCE_OK")']
started = time.monotonic()
timed_out = False
with log.open('wb') as out:
    process = subprocess.Popen(command, cwd=repo, stdout=out, stderr=subprocess.STDOUT,
                               start_new_session=True,
                               env=dict(os.environ, JULIA_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1'))
    try:
        status = process.wait(timeout=30)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        status = 124
receipt = dict(label=label, command=command, cwd=str(repo), log=str(log),
               status=status, timed_out=timed_out, cap_seconds=30,
               seconds=time.monotonic()-started, before=before, after=hashes())
log.with_suffix('.json').write_text(json.dumps(receipt, indent=2)+'\n')
print(json.dumps({k:v for k,v in receipt.items() if k not in ('before', 'after')}))
print(log.read_text())
raise SystemExit(status)
