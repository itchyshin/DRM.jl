#!/usr/bin/env python3
"""Damaged reference receipts must fail, including with Python assertions disabled."""
import copy,json
from check_finite_native_reference import REF,check
baseline=json.loads(REF.read_text())
check(baseline)
mutations={
 'provenance':lambda r:r.update(runner_sha256='bad'),
 'case_denominator':lambda r:r['cases'].pop('categorical'),
 'control':lambda r:r['cases']['ordinal']['fit_control'].update(se=False),
 'convergence':lambda r:r['cases']['ordinal'].update(native_convergence=1),
 'raw_order':lambda r:r['cases']['ordinal']['raw_names'].reverse(),
 'gradient':lambda r:r['cases']['ordinal']['points'][0]['gradient'].__setitem__(0,10.),
 'likelihood':lambda r:r['cases']['categorical']['points'][1].update(nll=0.),
 'finite':lambda r:r['cases']['ordinal']['theta'].__setitem__(0,float('nan')),
 'missing_mask':lambda r:r['cases']['ordinal']['observed_y'].__setitem__(6,True),
 'row_restore':lambda r:r['cases']['ordinal']['original_row'].__setitem__(0,2),
 'posterior':lambda r:r['cases']['ordinal']['conditional_probabilities'][0].__setitem__(0,1.),
 'state_prediction':lambda r:r['cases']['categorical']['prediction'].__setitem__(6,0.),
 'ordinal_sd':lambda r:r['cases']['ordinal']['imputation'][6].update(std_error=0.),
 'categorical_sd':lambda r:r['cases']['categorical']['imputation'][6].update(std_error=0.),
 'categorical_status':lambda r:r['cases']['categorical']['imputation'][6].update(uncertainty_status='ok'),
 'source_label':lambda r:r['cases']['categorical']['imputation'][6].update(source='conditional_mode'),
 'level_order':lambda r:r['cases']['categorical']['levels'].reverse(),
 'state_layout':lambda r:r['cases']['ordinal'].update(state_layout='state_then_row'),
}
for name,damage in mutations.items():
    r=copy.deepcopy(baseline);damage(r)
    try:check(r)
    except (ValueError,KeyError,TypeError,IndexError):pass
    else:raise RuntimeError('accepted damaged receipt: '+name)
print('FINITE_NATIVE_NEGATIVE_CONTROLS_PASS',len(mutations))
