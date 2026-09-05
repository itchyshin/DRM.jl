"""Pure root-solver controls; no model fits. Estimate <1 minute; hard timeout60s."""
import subprocess,time,hashlib
from pathlib import Path
repo=Path(__file__).resolve().parents[5]
source=subprocess.check_output(['git','show','479f1e06:src/locscale_profile.jl'],cwd=repo)
assert hashlib.sha256(source).hexdigest()=='c6ca8e2d9d76c372be17f61f2edc00fcef299ed897b05742ef035b3f6d29c2b5'
s=source.decode();start=s.index('function _ls_profile_root(');end=s.index('\nend\n',start)+5
code=s[start:end]+'''
println("JULIA_VERSION ", VERSION)
f(t)=(t*t-1,2t,true)
r=_ls_profile_root(f,0.0;dir=1.0,init=1e20)
println("QUADRATIC_DEFAULT_BUDGET endpoint=",r," true_root=1 residual=",f(r)[1])
n=Ref(0)
function fail_after_bracket(t)
 n[]+=1
 return n[]==1 ? (t*t-1,2t,true) : (NaN,NaN,false)
end
r2=_ls_profile_root(fail_after_bracket,0.0;dir=1.0,init=2.0)
println("FAILED_REFINEMENTS endpoint=",r2," calls=",n[]," true_gap=",f(r2)[1])
r3=_ls_profile_root(t->(NaN,NaN,false),0.0;dir=1.0,init=2.0)
println("FAILED_FIRST_EVALUATION endpoint=",r3)
r4=_ls_profile_root(f,0.0;dir=1.0,init=2.0)
println("VALID_CONTROL endpoint=",r4," residual=",f(r4)[1])
'''
print('SOURCE_SHA256',hashlib.sha256(source).hexdigest(),flush=True);t=time.monotonic()
x=subprocess.run([str(Path.home()/'.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia'),'--startup-file=no','-e',code],capture_output=True,text=True,timeout=60)
print(x.stdout);print(x.stderr);print('EXIT',x.returncode,'ELAPSED',time.monotonic()-t)
raise SystemExit(x.returncode)
