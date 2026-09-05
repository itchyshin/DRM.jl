# Arithmetic separation — source unchanged

Existing Float64 prepared inputs and rejected endpoints were retained in the
Julia1.10 serialized states file. The full scripted capture and no-refit
follow-up are included. Earlier probe failures are retained separately.

Rounded Float64 per-observation terms, even summed at128/256bits, yield positive
changes: NB2 about6.01e-14, Gamma about7.83e-14. Full high-precision evaluation,
converting inputs before predictor arithmetic, instead yields stable negative
changes: NB2 -4.6745030396e-19 and Gamma -4.5657663369e-20. Reversing observations
preserves the high-precision sign; adding1e12 erases the Float64 difference but
not the high-precision sign. Both segments are inside the kernel clamp bounds.
Summation compensation alone therefore cannot recover the true step sign.

These are read-only numerical diagnostics, not a new production algorithm or
proof of global optimality. Source572f46bb/test8799bb89 remain unaccepted for
integration. Next prototype the smooth-region stable difference identity and
quantify error before implementing an alternate comparison. Keep the existing
stationarity/locality/PD/budget guards; do not merely enlarge four ULPs.
