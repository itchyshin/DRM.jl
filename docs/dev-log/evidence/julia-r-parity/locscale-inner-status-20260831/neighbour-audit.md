# Neighbour audit — follow-up remains open

S1 scout (requested/initial session Luna low) read-only review found a separate
status-loss path in src/sparse_aug_plsm.jl. `_estep_fast` checks stationarity
after its budget, but `_estep_robust` returns (u,ch,Hobs) after the loop without
a final gradient gate; `estep_mode` exposes no convergence boolean. A reachable
production case with an inaccurate exhausted mode has NOT been demonstrated.
This is a follow-up investigation, not an established user-facing failure.

Other inspected outer fitters expose Optim convergence or an explicit false
status. No edits or fits occurred in this audit. The protected Gaussian files
remain untouched. Reproduce the robust E-step exhaustion separately with a
small exact oracle before proposing a source/API change; coordinate ownership.
Do not broaden the current location-scale inner repair to hide this obligation.
