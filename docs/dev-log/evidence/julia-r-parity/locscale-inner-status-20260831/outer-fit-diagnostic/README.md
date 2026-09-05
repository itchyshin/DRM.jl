# Exact outer-fit diagnostic, no production edits

Candidate572f46bb is unchanged. The successful read-only instrumented run002
completed in10.42s at1Julia/1BLAS thread. Run001 is an incomplete NB-only
attempt that exited1 because of a diagnostic Gamma namespace ambiguity; it is
retained and is not a successful two-fixture run.

Both original NB2recovery(seed424242,G50,m35) and Gamma-profile(seed20260831,
G4,m8) h1e-5 observed-information routes encounter finite, PD, local fullNewton
trials reaching the unchanged stationarity threshold. The positive represented
objective differences are28ULP(NB2) and11ULP(Gamma), exceeding the current4ULP
polish allowance. The resulting gradients/Hessians are rejected; the fitted
outer solution remains nonconverged. Gamma se=false is diagnostic only; it does
not demonstrate the requested inference workflow works.

Do not simply enlarge the4ULP allowance. Next separate accumulation error from
per-observation term evaluation using identical rounded terms, reordered sums,
compensated sums and128/256bit full-endpoint calculations. No refits are needed.
