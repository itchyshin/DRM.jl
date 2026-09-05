# Live R provider cross-product acceptance ledger

- [x] **G0 — frozen source.** Julia source base `b656e6a8dc8b81178ae3e09f919be8950ff8dcee` and R source base `6487ad7281120ade8e86c66cfe7fd017ee8eaaff` resolve as ancestor commits; exact current source hashes are in `final-source.json`.
- [x] **G1 — current focused baselines.** Julia provider suite passes 19/19 at four Julia threads and BLAS one; R pure routing suite passes 48/48.
- [x] **G2 — actual R Gaussian providers.** Animal A and converted-spatial K pass public profile and B=2 bootstrap at one/four Julia threads, match direct Julia exactly, and record 2/2 refits.
- [x] **G3 — actual R non-Gaussian provider.** Poisson K passes the same public/direct checks at one/four Julia threads; serial/threaded results agree exactly.
- [x] **G4 — test of the test.** Replacing A/K with identity changes every profile by more than 1e-6; artifact integrity is checked by `verify.py` and its deliberate-damage test.
- [x] **G5 — bounded independent review.** Rose and Melissa independently pass the final artifacts, warnings and claim boundaries; see `rose-review.md` and `melissa-reconciliation.md`.

This ledger is for the bounded provider cross-product only. All global
programme G0-G8 remain open.
