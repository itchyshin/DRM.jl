from pathlib import Path
import subprocess,os,time,signal,json,hashlib
out=Path(__file__).resolve().parent
repo=out.parent/"DRM.jl"
build=repo/"docs/build/integration-anchor-001"
cmd=["/Users/z3437171/.julia/artifacts/34a516c9d97d925f9ae668de15ecaa6eeeb8df32/bin/node",str(build/"node_modules/vitepress/dist/node/cli.js"),"build",str(build/".documenter")]
inputs=[p for p in (build/".documenter").rglob("*") if p.is_file()]
before={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
start=time.monotonic();timeout=False
with (out/"render.log").open("x") as log:
 p=subprocess.Popen(cmd,cwd=build,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 try:rc=p.wait(timeout=60)
 except subprocess.TimeoutExpired:
  timeout=True;os.killpg(p.pid,signal.SIGTERM);p.wait(timeout=10);rc=124
after={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
receipt=dict(command=cmd,exit_code=rc,elapsed_seconds=time.monotonic()-start,timed_out=timeout,inputs_unchanged=before==after,emitted_inputs_before=before,emitted_inputs_after=after,scope="Fresh all-page local Vitepress HTML, no deployment",reused_dependencies=str(build/"node_modules"))
(out/"render.json").write_text(json.dumps(receipt,indent=2)+"\n")
print({k:v for k,v in receipt.items() if not k.startswith("emitted_inputs")})
raise SystemExit(0 if rc==0 and before==after and not timeout else 1)
