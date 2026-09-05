# Rose draft implementation review — NOT READY

Independent Sol/high review of locscale_profile.jl SHA-256
bddb82dbd5982d95ba252561d46008e99d0b87aac36a2af4ef5bb00d11034b39.
Received 2026-08-31. No-fit Julia 1.10.0 probes: 1.24 seconds, exit 0;
reviewer did not retain a raw log. Root's candidate module run passed 100
assertions but did not cover the following defects.

1. Absolute-NLL threshold rounding: shift=1e16, half=1.920729410347062,
   callback (shift+t*t-(shift+half),2t,true), init=1.6 yields accepted=1.6,
   residual=0. True root=sqrt(half)=1.3859038243496775 and true residual
   0.6392705896529385. Use existing reference-difference cancellation guard,
   subtract half after difference, require resolved sign/certificate.
2. Ordinary callback exceptions escape. Preserve interrupts; classify ordinary
   callback failure. Slope-only exceptions may use bisection fallback.
3. init=Inf and zero gap yields accepted infinity. Guard input/candidate finiteness.
4. Original _ls_profile_ci docstring attaches to the new result helper, leaving
   the compatibility wrapper undocumented although engine-internals @docs names it.

Tests must not require a real optimizer to fail on every platform. Use a
controlled failed result for routing/warning assertions; model smoke checks
consistency and retains actual outcomes. Correct shifted quadratic to
(x-3)^2-1 with origin3 and lower root2 so the origin satisfies the contract.

Core flag propagation, compatible wrappers, selected bridge message and mocked
R forwarding otherwise follow the approved design. Builder received repair
instructions. This review is not an approval of the repaired source.
