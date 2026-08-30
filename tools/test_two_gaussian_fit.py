#!/usr/bin/env python3
import copy
import sys
import tomllib
from pathlib import Path
import check_two_gaussian_fit as oracle
r=tomllib.loads(Path(sys.argv[1]).read_text());oracle.check(r)
mutations=[
 ('reference hash',lambda x:x.update(reference_sha256='wrong')),
 ('runner hash',lambda x:x.update(runner_sha256='wrong')),
 ('source provenance',lambda x:x.update(source_before={},source_after={})),
 ('runtime',lambda x:x['runtime'].update(threads=8)),
 ('rows and masks',lambda x:x['original_row'].reverse()),
 ('snapshot isolation',lambda x:x.update(snapshot_isolated=False)),
 ('point denominator',lambda x:x['points'].pop()),
 ('row likelihood: mismatch',lambda x:x['points'][1]['row_loglik'].__setitem__(5,x['points'][1]['row_loglik'][5]+1)),
 ('conditional covariance: mismatch',lambda x:x['points'][0]['conditional_covariance'][69].__setitem__(0,[x['points'][0]['conditional_covariance'][69][0][0]+1,x['points'][0]['conditional_covariance'][69][0][1]])),
 ('conditional status',lambda x:x['points'][0]['status'][0].__setitem__(0,'wrong')),
 ('fit stationarity',lambda x:x['fitted']['gradient'].__setitem__(0,5e-6)),
 ('fit statuses',lambda x:x['fitted'].update(converged=False)),
 ('Hessian covariance identity',lambda x:x['fitted']['covariance'][0].__setitem__(0,x['fitted']['covariance'][0][0]+.1)),
 ('imputation mean: mismatch',lambda x:x['fitted']['imputed1']['estimate'].__setitem__(4,x['fitted']['imputed1']['estimate'][4]+.1)),
 ('imputation SE mask',lambda x:x['fitted']['imputed2_no_se']['se_available'].__setitem__(6,True)),
 ('native verdict',lambda x:x.update(native_status='PASS' if x['native_status']=='FAIL' else 'FAIL')),
 ('gradient: finite',lambda x:x['points'][0]['gradient'].__setitem__(0,float('nan'))),
]
for reason,mutate in mutations:
    damaged=copy.deepcopy(r);mutate(damaged)
    try:
        oracle.check(damaged)
    except ValueError as e:
        oracle.require(reason in str(e),'wrong rejection '+reason+': '+str(e))
    else:
        raise ValueError('accepted damage '+reason)
print('TWO_GAUSSIAN_FIT_NEGATIVES_PASS='+str(len(mutations)))
