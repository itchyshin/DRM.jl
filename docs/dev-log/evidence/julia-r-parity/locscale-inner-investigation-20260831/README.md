# Inner-mode flag investigation

Rose ran this bounded synthetic control after the coordinator explicitly
authorized writes to this evidence directory only. No production source was
edited, no full model was fitted, and no additional agent was spawned.

`probe.py` extracts the exact `_ls_inner_mode` function from the retained MIT
source snapshot. Its callbacks provide the strictly convex joint objective
`j(a) = a[1]^4/4 + sum(abs2, a)/2`, with exact gradient and Hessian. All other
location-scale/model functions are excluded. The snapshot SHA-256 is
`7915b9cc780e723cd9928b2a71c3f22884d21df5f0b57c1ea1f0e2db334f8bcb`.

Run from this directory:

```sh
python3 probe.py
```

Use `--julia /absolute/path/to/julia` on another host. The default is the actual
local Julia 1.10.0 executable recorded in the log. The script rejects a source
snapshot with a different hash; this is a historical reproducer, not a test of
a future repair. It has a 30-second child-process cap and writes only stdout.

The replay took 0.914 seconds. With `maxiter=0`, it returned `ok=true` at
`a=[2,0]`, with gradient norm 10 versus the existing threshold of about 3e-9.
With the unchanged default 200 iterations and initial state `[1e50,0]`, it
returned `ok=true` with gradient norm 2.2143e44 versus a threshold of 604990.
Both Hessians factored successfully. A stationary `[0,0]` positive control also
returned `ok=true`, with gradient zero. Exit 0 means the two defects and the
positive control were reproduced; it does not mean the engine passed.

`probe-001.log` retains the full output. `receipt-001.json` binds the script,
source snapshot, and log hashes. The current production source matched the
snapshot before and after this replay.

This establishes that positive-definite curvature alone is accepted after
iteration exhaustion. It does not establish that any retained Gamma fit reached
that path or that this defect caused its outer optimization failure. The inner
mode contract remains a separate required repair before numerical profile
certification; it does not expand the concurrent profile-status builder's scope.
