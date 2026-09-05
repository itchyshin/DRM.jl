# Totoro two-frontends pilot

This directory retains the completed Linux/Totoro single-thread correctness pilot at source commit `f67eeb8046417c110c2f0ce7785bd3e70f2fcb1a`. The run used Julia 1.10.10, one Julia thread, and one BLAS thread, with elapsed time 67 seconds. It passed the targeted two-Gaussian preparation, likelihood/conditional-moment, derivative/mask/validation, stable-arithmetic, full-covariance imputation, fit/order, direct frontend, refusal, primitive preparation, and primitive fit checks. The terminal token was `TOTORO_TWO_FRONTENDS_PASS`.

This is a Linux single-thread correctness pilot. It is not evidence for warm speed, a whole-programme result, or final-source status. No SSH connection or rerun was performed while filing this receipt.

The log records the source archive SHA-256 digest `1a132a9fd4003d55f328c1328f3f73d539ab054ef933714886d8d70470957f4c` for `source.tar`; the local outer tar has the same SHA-256 digest.
