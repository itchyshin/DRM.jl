from pathlib import Path
import subprocess,os,signal,time,hashlib,json,sys,datetime
repo=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl')
out=repo/'docs/dev-log/evidence/julia-r-parity/locscale-inner-status-20260831'
out.mkdir(exist_ok=True)
threads=int(sys.argv[1]); label='module-'+str(threads)+'threads-'+(sys.argv[2] if len(sys.argv)>2 else '001')
files=['test/test_locscale_inner_status.jl','test/test_locscale_inner.jl','test/test_locscale_marginal.jl','test/test_locscale_grad.jl','test/test_locscale_fit.jl']
def hashes():
    paths=sorted(set(repo.glob('src/**/*.jl'))|set(repo.glob('test/**/*.jl')))
    paths += [repo/'Project.toml',repo/'Manifest.toml']
    return {str(p.relative_to(repo)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths if p.exists()}
before=hashes()
code='using DRM, Test, LinearAlgebra\n@test realpath(dirname(pathof(DRM))) == '+json.dumps(str((repo/'src').resolve()))+'\nprintln("DRM_SOURCE "*pathof(DRM))\nBLAS.set_num_threads(2)\n'+''.join('include('+json.dumps(f)+'); println("FILE_COMPLETE '+f+'")\n' for f in files)+'@test BLAS.get_num_threads()==2\nprintln("MODULE_INNER_STATUS_OK")\n'
command=['/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia','--project=.','--startup-file=no','-e',code]
env=dict(os.environ,JULIA_NUM_THREADS=str(threads),OPENBLAS_NUM_THREADS='1')
started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat();start=time.monotonic();timedout=False
with (out/(label+'.log')).open('w') as log:
    process=subprocess.Popen(command,cwd=repo,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    try: rc=process.wait(timeout=180)
    except subprocess.TimeoutExpired:
        timedout=True;os.killpg(process.pid,signal.SIGTERM)
        try:process.wait(timeout=5)
        except subprocess.TimeoutExpired:os.killpg(process.pid,signal.SIGKILL);process.wait()
        rc=124
receipt=dict(started_utc=started_utc,ended_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),command=command,elapsed_seconds=time.monotonic()-start,exit_code=rc,timed_out=timedout,deadline_seconds=180,julia_threads=threads,initial_blas_threads=2,before=before,after=hashes(),head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip())
receipt['inputs_unchanged']=receipt['before']==receipt['after']
(out/(label+'.json')).write_text(json.dumps(receipt,indent=2)+'\n')
print((out/(label+'.log')).read_text());print(json.dumps({k:v for k,v in receipt.items() if k not in ['before','after','command']}))
sys.exit(rc if rc else (0 if receipt['inputs_unchanged'] else 2))
