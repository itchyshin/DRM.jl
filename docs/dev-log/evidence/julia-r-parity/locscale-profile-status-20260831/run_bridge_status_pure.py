from pathlib import Path
import subprocess,sys,hashlib,time
r=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl')
s=(subprocess.check_output(['git','show','643b584a:src/bridge.jl'],cwd=r).decode() if sys.argv[1]=='old' else (r/'src/bridge.jl').read_text())
start=s.index('function _bridge_profile_outcome(');end=s.index('\nfunction _bridge_inference_flatten',start)
function=s[start:end];test=(r/'test/test_bridge_profile_status.jl').read_text()
code='using Test\nmodule DRM\n'+function+'\nend\n'+test.replace('using DRM, Test','using .DRM, Test')
print('FUNCTION_SHA256',hashlib.sha256(function.encode()).hexdigest(),flush=True)
print('TEST_SHA256',hashlib.sha256(test.encode()).hexdigest(),flush=True)
t=time.monotonic();p=subprocess.run(['/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia','--startup-file=no','-e',code],timeout=60)
print('EXIT',p.returncode,'ELAPSED',time.monotonic()-t);raise SystemExit(p.returncode)
