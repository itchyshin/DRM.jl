# Controlled fixed-P arithmetic comparison

Four fresh single-thread processes; no outer fit. Baseline175112Z4.792s,
gradient175135Z4.784s, objective175140Z4.526s, both175145Z4.532s.
All source/P checks unchanged and candidate fallbacks zero. Script0ffab46e.

Baseline cold/failed-start do not certify. Neighbor-start native acceptance is
false-positive against independent fixedP: L2=1.38853e-9 exceeds1.32258e-9.
Reference-start does certify. Gradient-only improves arithmetic but cold-start
still fails at7.19e-6. Objective-only and combined each certify all four starts
independently. Combined cold L2=8.69634e-10, objective accumulation errors below
2.4e-15. All full/half/quarter retained directions recover negative changes
under objective-only and combined. Fullstep rawΔ=-5.68434e-13 versus fullBig
-5.73358e-13 and frozenFloat64kernel-reference -5.69691e-13.

This supports both arithmetic repairs, not a change in model, precision,
estimator, tolerance or line-search guards. It is not a broad inference pass.
Production transfer94f54c74 (separate pending change) focused13/13 checks pass;
full neighbours/SE/profile gates are still being checked. No speed claim.
