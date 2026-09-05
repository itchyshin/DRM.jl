#!/usr/bin/env python3
import copy,json,sys
from pathlib import Path
from check_two_public import check
r=json.loads(Path(sys.argv[1]).read_text());check(r)
mutations=[
 ('false convergence',lambda x:x['result']['flags'].update(converged=False)),
 ('false nobs',lambda x:x['result']['flags'].update(nobs=False)),
 ('missing flags',lambda x:x['result'].pop('flags')),
 ('NaN adapter error',lambda x:x['result']['adapter_errors'].update(newdata=float('nan'))),
 ('source',lambda x:x['source_before'].clear()),
 ('runtime',lambda x:x['runtime'].update(threads=8)),
 ('tolerance',lambda x:x.update(native_tolerance=1)),
 ('theta',lambda x:x['result']['raw_theta'].__setitem__(1,0.0)),
 ('covariance axis',lambda x:x['result']['raw_covariance'][0].__setitem__(2,7)),
 ('SD cross covariance',lambda x:x['result']['public_covariance'][7].__setitem__(10,7)),
 ('second SD',lambda x:x['result']['coef'].__setitem__('sigma_mi_x2',1)),
 ('rows',lambda x:x['result']['imputation']['x2'][0].update(original_row=4)),
 ('mask',lambda x:x['result']['imputation']['x1'][0].update(observed=False)),
 ('second mean',lambda x:x['result']['imputation']['x2'][6].update(estimate=99)),
 ('second SE',lambda x:x['result']['imputation']['x2'][6].update(std_error=99)),
 ('NaN',lambda x:x['result']['imputation']['x2'][6].update(estimate=float('nan'))),
 ('conditional offdiagonal',lambda x:x['result']['conditional_covariance'][69][0].__setitem__(1,0)),
 ('newdata',lambda x:x['result']['newdata_prediction'].__setitem__(0,99)),
 ('training',lambda x:x['result']['prediction'].__setitem__(0,99)),
 ('native error',lambda x:x['result']['native_errors'].update(theta=0)),
 ('denominator',lambda x:x['result']['imputation']['x2'].pop())]
for label,damage in mutations:
 bad=copy.deepcopy(r);damage(bad)
 try:check(bad)
 except (ValueError,TypeError,KeyError,IndexError,OverflowError):pass
 else:raise RuntimeError('damaged receipt passed: '+label)
print('TWO_PUBLIC_DAMAGE_PASS',len(mutations))
