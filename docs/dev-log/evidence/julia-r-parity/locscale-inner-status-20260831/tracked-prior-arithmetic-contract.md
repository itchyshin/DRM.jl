# Tracked prior arithmetic contract — 2026-08-31

Status: Rose reviewed; Ada authorizes bounded implementation and tests only.
Parent source: 2c534141d8439a4ee339bfc6d795e4a4836fea885f986f677b418016a4afc32f.
All programme gates remain open. No estimator, tolerance, iteration budget,
likelihood convention, or registered case changes.

Use round-to-nearest Float64, explicit fma, no fastmath and local accumulators.
TwoProd(a,b) gives p=a*b and e=fma(a,b,-p). Expand each triple with
TwoProd(d_i,P_ij) => (p,ep), TwoProd(p,a_j) => (q,eq), and
TwoProd(ep,a_j) => (r,er). Stream q,eq,r,er separately.

For each component x, general TwoSum (no magnitude assumption) gives:

```
(s,e) = TwoSum(hi,x)
(t,f) = TwoSum(lo,e)
(h,l0) = TwoSum(s,t)
(l,dropped) = TwoSum(l0,f)
(hi,lo) = TwoSum(h,l)
```

Within the guarded range old_hi+old_lo+x = hi+lo+dropped. Track B by
nextfloat(B+abs(dropped)) for nonzero dropped; zero does not increase B.
Keep both prior components through combination with independently computed data
direction, existing prior quadratic and each data quadrature. Finalize via
TwoSum(hi,lo); include the discarded final low component in B.

Freeze E = 8*max(abs(Q8-Q4),abs(Q4-Q2)) +
64*(eps(Float64)*(Sdata+Sprior_quadratic+Squadrature)+max(B2,B4,B8)).
Only the prior-direction arithmetic allowance changes. Data envelopes and
quadrature scales remain unchanged. This remains an engineering estimate, not
a universal bound for transcendental library functions.

All arithmetic intermediates must be finite. Permit exact/signed zero. For
nonzero TwoProd operands require normal finite values and exponent(a)+exponent(b)
>= -970 (floor log2 exponents) to guard hidden residual underflow. Reject genuinely
nonzero subnormal intermediates and overflow. Such failure disables this fallback
only; ordinary backtracking stays available. Preserve existing stationarity, PD,
locality, smooth endpoint, 4ULP fast-path, tol=1e-9 and maxiter=200 guards.
Traverse CSC stored entries directly in O(nnz); no dense scan or findnz copies.

Before acceptance: independent high-precision recurrence controls and deliberate
residual-discard corruption; severe within-prior/prior-data cancellation; row and
coordinate permutations; dense/CSC equivalence; zero/uphill NEW helper results;
normal/subnormal/overflow cases; all six saved states; unchanged varied oracles;
then original gradient/recovery and one/four-thread profile tests.

The preceding prototype's uphill checks exercised the old helper and its sparse
calculation used dense indexing. Neither is evidence for this new implementation.
Builder owns only its existing inner-source/focused-test/runtests/ignored-ledger
lease. Root owns independent varied checks and durable receipts. Freeze source
and test hashes before root runs; retain all failures. Local arithmetic estimate
under three minutes with bounded process caps; no remote campaign authorized.
