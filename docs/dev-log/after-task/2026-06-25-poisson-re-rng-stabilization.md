# After Task: Poisson RE RNG Stabilization

## Goal

Stabilize the unrelated Poisson random-intercept recovery test that failed the
manual CI run for the stacked q2/q4 direct-export PR.

## Implemented

`test/test_poisson_re.jl` now uses an explicit `MersenneTwister` for the recovery
data-generating process instead of the global RNG. The simulated group effects
are centered before generating Poisson means, so the finite set of group effects
does not move the population intercept target differently across Julia RNG
versions.

No package source code changed.

## Evidence

The manual CI run `28201026220` on head `41177db` failed both Julia test jobs at
the same assertion in `test/test_poisson_re.jl`: the estimated intercept was
`0.5186863613437745` against the old `0.3 ± 0.15` target. The same run's
`scaling-sweep` job passed, and manual Documenter run `28201026240` passed on the
same pre-fix head.

Local focused validation after the fix:

```sh
julia --project=. test/test_poisson_re.jl
julia --project=. test/test_bridge_q2_direct_export.jl
julia --project=. test/test_bridge_q4_direct_export.jl
git diff --check
```

`test/test_poisson_re.jl` passed 5/5 assertions. The q2 direct-export test
passed 125/125 assertions, and the q4 direct-export test passed 36/36 assertions.

## Claim Boundary

This is a test-stability fix only. It does not change the Poisson random-effect
implementation, q2/q4 direct-export implementation, bridge surface, REML status,
AI-REML status, interval reliability, or coverage status.
