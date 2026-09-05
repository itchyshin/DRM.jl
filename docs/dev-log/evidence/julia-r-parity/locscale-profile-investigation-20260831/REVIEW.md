# Rose: confirmed defect and approved repair contract

Independent Sol/high review reproduced the failure with no model fits in 0.55s.
Root repeated the exact frozen-source probes in 0.77s; see root-failure.log and
reproduce_root_failure.py. Quadratic gap t²−1 with exact slope2t and init1e20
returns ~9.31e10 after the default budget although root1 is exact. Failed
refinements return2 with residual3; a valid control reaches1 within tolerance.
The location-scale adapter hardcodes failed=0. This is not an Ayumi-data repro.

APPROVE contract with required edits: preserve generic signed-Inf failure bounds,
endpoint_failed=true, unbounded=false; distinguish no-crossing within the searched
range from numerical failure. Keep existing three-value nuisance and numeric
root/two-bound CI wrappers. Detailed private results carry nuisance convergence,
fresh objective/gradient, existing1e-7 stationarity criterion, endpoint reason,
evaluated candidate/residual and counts. No optimizer-budget or likelihood change.
Keep the global stats-row shape, add location-scale endpoint diagnostics keyed
by parameter/coefficient, and route failure counts/warnings truthfully.

Required tests: default-budget exhaustion; failed evaluations; valid root;
no crossing vs failed search; wrapper compatibility; warnings; fresh-gradient
rejection despite optimizer convergence; interrupts. Threading repair is deferred
until this correctness slice is verified. Review is of the contract only;
implementation and model-regression verdicts remain outstanding.
