import subprocess,os,signal,time,hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parent.parent;repo=root/"DRM.jl";out=Path(__file__).resolve().parent
cmd=["julia","--project=docs","--startup-file=no","tools/parity_docs_subset.jl","--build-dir","docs/build/integration-profile-003","--pages-file",str(out/"pages.txt"),"--navigation","production"]
def manifest():
 files=[p for sub in ["src","docs/src"] for p in (repo/sub).rglob("*") if p.is_file()]+[repo/p for p in ["Project.toml","docs/Project.toml","docs/Manifest.toml","docs/make.jl","tools/parity_docs_subset.jl","tools/parity_docs_navigation.jl"]]+[Path(__file__),out/"pages.txt"]
 return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
before=manifest();start=time.time();env=dict(os.environ,JULIA_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",JULIA_PKG_PRECOMPILE_AUTO="0")
with (out/"build.log").open("x") as f:
 p=subprocess.Popen(cmd,cwd=repo,stdout=f,stderr=subprocess.STDOUT,env=env,start_new_session=True)
 timeout=False
 try:code=p.wait(timeout=240)
 except subprocess.TimeoutExpired:
  timeout=True;os.killpg(p.pid,signal.SIGTERM)
  try:code=p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);code=p.wait()
after=manifest();result=dict(command=cmd,head=subprocess.check_output(["git","rev-parse","HEAD"],cwd=repo,text=True).strip(),elapsed=time.time()-start,exit_code=code,timeout=timeout,source_before=before,source_after=after,source_unchanged=before==after,scope="all-page production-navigation Documenter source build; Vitepress rendering/deployment separate")
(out/"receipt.json").write_text(json.dumps(result,indent=2)+"\n");print({k:v for k,v in result.items() if k not in ["source_before","source_after"]})
raise SystemExit(0 if code==0 and before==after and not timeout else 1)
