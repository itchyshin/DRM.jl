#!/usr/bin/env python3
"""Validate frozen native output and transport numerical fixtures, never R source."""
import json,sys
from pathlib import Path
from check_finite_native_reference import check,sha,permutation,row
source,target=map(Path,sys.argv[1:])
if target.exists():raise ValueError('refusing stale fixture')
r=json.loads(source.read_text());print(check(r))
lines=['# Generated numerical reference; no native implementation source.',
       'source_json_sha256 = '+json.dumps(sha(source))]
for kind,c in r['cases'].items():
    lines.append('\n['+kind+']')
    fields=('levels','n','K','y','x','z','observed_y','observed_x','original_row','state_design','X_sigma','X_predictor')
    data={k:c[k] for k in fields}
    for key in ('mu_names','sigma_names','predictor_names'):
        data[key]=c[key] if isinstance(c[key],list) else [c[key]]
    perm=permutation(c);data['native_to_prepared']=[j+1 for j in perm]
    for k,v in data.items():lines.append(k+' = '+json.dumps(v,allow_nan=False))
    for point in c['points']:
        t=[point['theta'][j] for j in perm]
        values=[row(c,t,i) for i in range(c['n'])]
        data={'theta':t,'nll':point['nll'],'gradient':[point['gradient'][j] for j in perm],
              'rowloglik':[v[0] for v in values],'probabilities':[v[1] for v in values],
              'estimate':[v[2] for v in values],'prediction':[v[4] for v in values]}
        if kind=='ordinal':data['conditional_sd']=[v[3] for v in values]
        lines.append('\n[['+kind+'.points]]')
        for k,v in data.items():lines.append(k+' = '+json.dumps(v,allow_nan=False))
target.write_text('\n'.join(lines)+'\n')
print('FINITE_REFERENCE_TOML_PASS')
