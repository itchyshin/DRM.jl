#!/usr/bin/env python3
"""Adversarial controls for the independent two-Gaussian reference verifier."""
import copy
import json
import sys
from pathlib import Path
import check_two_gaussian_reference as oracle

r=json.loads(Path(sys.argv[1]).read_text());oracle.check(r)
def overflow_case(x):
    x['fixture']['y'][0]=1e200
    x['fixture']['x1'][0]=x['fixture']['x2'][0]=1e197
    x['imputed1'][0]['estimate']=x['imputed2'][0]['estimate']=1e197
    t=x['theta'];x['prediction'][0]=t[0]+t[1]*x['fixture']['z'][0]+t[2]*1e197+t[3]*1e197

mutations=[
 ('computed likelihood nonfinite',overflow_case),
 ('schema',lambda x:x.update(schema='wrong')),
 ('source changed',lambda x:x.update(source_unchanged=False)),
 ('frozen source provenance',lambda x:x.update(source_before={},source_after={})),
 ('frozen runner_sha256',lambda x:x.update(runner_sha256='wrong')),
 ('frozen loaded_native_DLL_sha256',lambda x:x.update(loaded_native_DLL_sha256='wrong')),
 ('default optimizer controls',lambda x:x.update(optimizer_control={'rel.tol':1e-14})),
 ('native convergence',lambda x:x.update(native_convergence=1)),
 ('parameter order' ,lambda x:x['raw_order'].reverse()),
 ('row identity',lambda x:x['fixture']['original_row'].reverse()),
 ('point denominator',lambda x:x['points'].pop()),
 ('point perturbation',lambda x:x['points'][1]['theta'].__setitem__(0,x['points'][1]['theta'][0]+.1)),
 ('nll: numerical',lambda x:x['points'][1].update(nll=x['points'][1]['nll']+1)),
 ('gradient: numerical',lambda x:x['points'][2]['gradient'].__setitem__(3,x['points'][2]['gradient'][3]+.1)),
 ('imputation denominator',lambda x:x['imputed1'].pop()),
 ('mean: numerical',lambda x:x['imputed1'][34].update(estimate=x['imputed1'][34]['estimate']+.1)),
 ('se: numerical',lambda x:x['imputed2'][34].update(std_error=x['imputed2'][34]['std_error']+.1)),
 ('uncertainty status',lambda x:x['imputed1'][4].update(uncertainty_status='bad')),
 ('V symmetry',lambda x:x['covariance'][0].__setitem__(1,x['covariance'][0][1]+.1)),
 ('prediction: dimension',lambda x:x.update(prediction=[])),
 ('prediction: numerical',lambda x:x['prediction'].__setitem__(4,x['prediction'][4]+.1)),
 ('eight masks',lambda x:x['fixture']['y_observed'].__setitem__(34,True)),
 ('mask counts',lambda x:x['mask_counts'].update({'000':2})),
 ('y: finite',lambda x:x['fixture']['y'].__setitem__(0,float('nan'))),
]
for reason,mutate in mutations:
    damaged=copy.deepcopy(r);mutate(damaged)
    try:
        oracle.check(damaged)
    except ValueError as e:
        oracle.require(reason in str(e),'wrong rejection for '+reason+': '+str(e))
    else:
        raise ValueError('damage accepted: '+reason)
# Full covariance identity and opposite-slope signs, independent of fitted points.
f=r['fixture'];both=next(i for i in range(160) if f['y_observed'][i] and not f['x1_observed'][i] and not f['x2_observed'][i])
for sign in (-1,1):
    theta=list(r['theta']);theta[2]=sign*abs(theta[2])
    C=oracle.row(theta,f,both)[2]
    oracle.check_conditional_covariance(C,theta,f,both)
    oracle.require(C[0][1]*theta[2]*theta[3]<0,'offdiagonal sign')
original=oracle.row
def damaged_row(*args):
    ll,m,C=original(*args);C[0][1]=C[1][0]=123.0
    return ll,m,C
oracle.row=damaged_row
try:
    oracle.check(r)
except ValueError as e:
    oracle.require('conditional covariance' in str(e) or 'conditional precision identity' in str(e),'wrong covariance damage rejection')
else:
    raise ValueError('damaged conditional offdiagonals accepted')
finally:
    oracle.row=original
print('TWO_GAUSSIAN_REFERENCE_NEGATIVES_PASS='+str(len(mutations)+1))
