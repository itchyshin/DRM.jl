# After-task: q4 FD gradient gate repair

## Scope

Repaired the standing Workflow Q finite-difference gate for issue #14.

The draft PR test already built the right small q4 PLSM fixture and called the
verified analytic gradient entry point, but its finite-difference reference used
cold-started inner solves at `h = 1e-6`. A local Julia run reproduced the draft
failure:

```text
max |analytic - FD| = 0.0028194448
```

The mismatch was finite-difference noise from independently stopped inner mode
solves, not an engine-gradient regression.

## Change

- Reused the base-theta mode returned by `marginal_and_exact_grad(...)`.
- Warm-started each perturbed `marginal_nll(...)` evaluation from that mode.
- Used `h = 1e-4`, which avoids amplifying inner-solve stopping noise while
  keeping central-difference truncation below the `1e-6` gate.

The model fixture, parameter point, and analytic gradient entry point are
unchanged.

## Evidence

Exploratory local sweep on the same fixture:

```text
h=1e-6, warm=false: max diff 2.819444816e-3
h=1e-4, warm=true:  max diff 9.719703431e-9
```

Focused gate:

```sh
julia --project=. test/test_qgate_fd_gradient.jl
```

Result: passed.

## Rose Audit

- No engine code changed.
- The `1e-6` exact-gradient claim was not weakened.
- The check-log row now records measured local Julia evidence rather than
  cloud-only expected CI status.
