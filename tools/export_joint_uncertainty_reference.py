#!/usr/bin/env python3
"""Retain generated native uncertainty values as a Julia-readable fixture."""
import hashlib,json,math,sys
from pathlib import Path
if len(sys.argv)!=3: raise SystemExit('usage: export_joint_uncertainty_reference.py NATIVE_JSON NEW_TOML')
src,out=map(Path,sys.argv[1:])
if out.exists():raise SystemExit('refusing stale fixture')
r=json.loads(src.read_text())
if r.get('status')!='PASS' or r.get('source_unchanged') is not True:raise SystemExit('native source probe did not pass')
lines=['native_receipt_sha256 = '+json.dumps(hashlib.sha256(src.read_bytes()).hexdigest())]
for kind in ('gaussian','bernoulli'):
 c=r['cases'][kind]; rows=c['imputed_all']
 if len(rows)!=160 or [q['original_row'] for q in rows]!=list(range(1,161)):raise SystemExit('wrong row denominator')
 values={'theta':c['se_theta'],'covariance':c['cov_fixed_common'],'mean':[q['estimate'] for q in rows],
 'std_error':[0.0 if q['std_error']=='NA' else q['std_error'] for q in rows],
 'se_available':[q['std_error']!='NA' for q in rows],'observed':[q['observed'] for q in rows],
 'original_row':[q['original_row'] for q in rows],'model_row':[q['model_row'] for q in rows],
 'source':[q['source'] for q in rows],'uncertainty_status':[q['uncertainty_status'] for q in rows],
 'conditional_variance':c['conditional_variance']}
 lines.append('\n['+kind+']')
 for key,value in values.items():lines.append(key+' = '+json.dumps(value,allow_nan=False))
out.parent.mkdir(parents=True,exist_ok=True);out.write_text('\n'.join(lines)+'\n')
print('JOINT_UNCERTAINTY_REFERENCE_EXPORTED cases=2 rows=320')
