import hashlib, json, os, re, signal, subprocess, time
from pathlib import Path
repo = Path('/private/tmp/drm-parity-20260830/integration/DRM.jl')
base = Path(__file__).resolve().parent
fixture = repo/'test/test_locscale_profile_threads.jl'
assert hashlib.sha256(fixture.read_bytes()).hexdigest() == 'ca1d9db86c33fb8046028c0e9833d1e0cc0af095509d5580b48375a390bd7ad4'
def expected_metadata_only(raw):
    failed = re.findall(r'Test Failed at [^\n]*test_locscale_profile_threads.jl:(\d+)', raw)
    return sorted(failed) == ['63', '64'] and re.search(r'14 passed, 2 failed, 0 errored', raw) is not None and 'Error During Test' not in raw
original = base/'profile-threads-4-expected-red-20260831T155259Z.log'
assert not expected_metadata_only(original.read_text()), 'classifier accepted original numerical failures'
# Damaged controls reject an additional failure, absent total, and an error.
control = '\n'.join(['Test Failed at test_locscale_profile_threads.jl:63', 'Test Failed at test_locscale_profile_threads.jl:64', '14 passed, 2 failed, 0 errored'])
assert expected_metadata_only(control)
assert not expected_metadata_only(control+'\nTest Failed at test_locscale_profile_threads.jl:52')
assert not expected_metadata_only(control.replace('14 passed', '12 passed'))
assert not expected_metadata_only(control+'\nError During Test')
def hashes():
    paths = sorted((repo/'src').rglob('*.jl')) + sorted((repo/'test').glob('*.jl'))
    return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
before = hashes()
stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
log = base/f'original-profile-numerics-{stamp}.log'
cmd = ['julia','--startup-file=no',f'--project={repo}','-e','include("test/test_locscale_profile_threads.jl"); println("ORIGINAL_PROFILE_ALL_PASS")']
start = time.monotonic(); timeout = False
with log.open('xb') as out:
    proc = subprocess.Popen(cmd,cwd=repo,env=dict(os.environ,JULIA_NUM_THREADS='4',OPENBLAS_NUM_THREADS='1'),stdout=out,stderr=subprocess.STDOUT,start_new_session=True)
    try: status = proc.wait(timeout=60)
    except subprocess.TimeoutExpired:
        timeout = True
        os.killpg(proc.pid,signal.SIGTERM)
        try: proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid,signal.SIGKILL); proc.wait()
        status = 124
raw = log.read_text(); after = hashes()
accepted = before == after and not timeout and ((status == 1 and expected_metadata_only(raw)) or (status == 0 and 'ORIGINAL_PROFILE_ALL_PASS' in raw))
receipt = dict(command=cmd,cwd=str(repo),log=str(log),status=status,timed_out=timeout,cap_seconds=60,seconds=time.monotonic()-start,accepted=accepted,before=before,after=after,negative_control_rejected=True)
log.with_suffix('.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(raw); print(json.dumps({k:v for k,v in receipt.items() if k not in ('before','after')}))
if accepted: print('ORIGINAL_PROFILE_NUMERICS_OK')
raise SystemExit(0 if accepted else 1)
