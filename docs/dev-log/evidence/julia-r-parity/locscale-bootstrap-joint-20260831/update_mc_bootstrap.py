from pathlib import Path
import subprocess,json,hashlib,urllib.request,re
r=Path('/Users/z3437171/shinichi-brain');rel='Shinichi/Dashboards/mission-control/live/status/drmTMB.json';p=r/rel
out=Path('/private/tmp/drm-parity-20260830/integration/DRM.jl/docs/dev-log/evidence/julia-r-parity/locscale-bootstrap-joint-20260831')
def git(*args):return subprocess.check_output(['git',*args],cwd=r)
assert not git('status','--porcelain','--',rel).strip(), 'target has foreign changes'
old=p.read_text();x=json.loads(old)
staged_before=git('diff','--cached','--raw','-z','--','.',':(exclude)'+rel)
updates={('now', 'active_lane'): 'Julia-R parity remains active. Canonical coupled location-scale marginal bootstrap now redraws both latent axes with their full covariance. Sampler, simulation neighbours and the retained Gamma B=2 refit regression pass 145 checks with one and four Julia threads; existing finite profiles also pass. A single bounded continuation repairs an unsuccessful boundary fit without relaxing its gradient tolerance. Rose reviewed. These are local regression results, not full inference parity or coverage evidence.', ('now', 'next_safe_action'): 'Continue structured/direct/R-bridge bootstrap parity: test and fix non-Gaussian tree forwarding in drm_bridge_inference, then cover other providers and families. Preserve seeds, failed replicates, trials, row maps, estimator and requested SEs. Beta draws can round to rejected endpoints; retain those failures rather than clipping or redrawing. Gamma public scale normalization, full parity/performance, documentation, recovery and reconciliation remain open.'}
new=old
for (section,key),value in updates.items():
 matches=list(re.finditer(r'("'+re.escape(key)+r'"\s*:\s*)("(?:\\.|[^"\\])*")',new))
 assert len(matches)==1,(section,key)
 m=matches[0];assert json.loads(m[2])==x[section][key]
 new=new[:m.start(2)]+json.dumps(value)+new[m.end(2):]
p.write_text(new)
assert git('diff','--cached','--raw','-z','--','.',':(exclude)'+rel)==staged_before
subprocess.run(['git','diff','--check','--',rel],cwd=r,check=True)
subprocess.run(['git','commit','--only','-m','docs(mc): record coupled bootstrap repair and remaining parity work','--',rel],cwd=r,check=True)
commit=git('rev-parse','HEAD').decode().strip()
assert git('diff-tree','--no-commit-id','--name-only','-r',commit).decode().splitlines()==[rel]
assert git('diff','--cached','--raw','-z','--','.',':(exclude)'+rel)==staged_before
served=json.load(urllib.request.urlopen('http://127.0.0.1:8823/p/drmTMB/status.json',timeout=10))
for (section,key),value in updates.items():assert served[section][key]==value
receipt=dict(commit=commit,changed_file=rel,changed_fields=['.'.join(k) for k in updates],source_before_sha256=hashlib.sha256(old.encode()).hexdigest(),source_after_sha256=hashlib.sha256(new.encode()).hexdigest(),foreign_staged_raw_before_after_sha256=hashlib.sha256(staged_before).hexdigest(),foreign_staged_unchanged=True,served_url='http://127.0.0.1:8823/p/drmTMB/status.json',served_fields_match=True,scope='Exact status fields and resume path only; no foreign memory or intake read or edited')
(out/'mission-control-bootstrap.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2))
