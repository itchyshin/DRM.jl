# Independent boundary derivative reference

Pilot uses endpoint3, the saved lower-slope cold failure. All four saved endpoints
remain required; this is not a subset replacing the original profile workflow.

CHECK: python3 run_capped.py <fresh UTC stamp> 3
EXPECT: WHITENED_BOUNDARY_REFERENCE_PASS, status0, <=60s.

Before each reference: SHA-fixed design and helpers, same theta engine packing,
original-coordinate norm<=1e-9*(1+norm(a)), undamped PD, strict Gamma clamps,
128/256bit mode tolerances1e-25/1e-50, zero/saved-start agreement<=1e-20.
All6 derivatives at h1e-4,half,quarter: crossprecision objective and directional
numerator agreement<=1e-20; Richardson-halving stability<=1e-10; finalFloat
analytic gradient maxerror<=1e-7, objectiveerror<=1e-8. Reject negatedgradient.
Incremental snapshots preserve completedreferencepoints if laterpointsfail.
Returned-a64 certification and production inference remain separate obligations.
