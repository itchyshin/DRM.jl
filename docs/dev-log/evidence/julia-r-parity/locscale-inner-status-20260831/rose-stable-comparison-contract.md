# Rose review — diagnostic contract, not implementation approval

Keep tolerance, iteration budget, local-displacement and PD guards. Do not widen
four ULPs to fit the two examples. Sequential objective accumulation and
within-term log-gamma cancellation can both matter. Compare rounded-term sums
in Float64/BigFloat, then full128/256bit input evaluation, reversed observations
and an added objective constant. Convert before predictor arithmetic and assess
the tiny difference itself, without a large absolute tolerance.

Within a smooth, unclipped segment, d=trial-a and predictor displacement delta_i:

Delta j = g(a)'d + (d'P*d)/2
          + sum_i integral_0^1 (1-t) delta_i' H_i(predictor_i+t*delta_i) delta_i dt.

The identity avoids subtracting two large totals. A plain quadratic approximation
is not an exact difference; approximations require explicit error/remainder
assessment against a high-precision oracle. Existing analytic derivatives omit
clipping derivatives outside kernel clamp bounds; segment checks are necessary.
BigFloat production fallback would also require a concurrency-safe precision
contract. No new comparison algorithm or source expansion is approved here.
