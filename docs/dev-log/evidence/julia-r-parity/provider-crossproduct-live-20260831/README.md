# Live R structured-provider cross-product

This directory closes the three live-R numerical cells left open by the earlier
provider-forwarding slice: Gaussian `animal(A)`, Gaussian `spatial(coords)`
after drmTMB's established conversion to `relmat(K)`, and Poisson
`relmat(K)`. Each driver source-loads the paired integration worktrees and
calls the public R `engine = "julia"` fit, profile interval, and `B = 2`
bootstrap interval. The public result is compared with direct
`DRM.drm_bridge_inference` on the identical retained provider and seed.

All three cells pass at one and four Julia threads with BLAS pinned to one.
Every bootstrap records 2/2 successful refits, and public versus direct point
and interval differences are exactly zero. The Poisson one/four-thread RDS
outputs also agree exactly for the point, profile, and bootstrap results.

`provider-damage-control.R` replaces each retained covariance with identity.
The maximum profile change is 0.00484 for animal, 0.04247 for converted
spatial, and 0.00983 for Poisson. Thus the live matches are sensitive to the
provider rather than passing because it is numerically irrelevant.

The unprivileged Poisson log is retained: JuliaCall was denied its normal
`~/.julia/logs` pid file before any fit. The exact rerun with the existing Julia
depot permitted passes. This is an environment receipt, not a model failure.

Warnings about singular or non-positive-definite finite-difference Hessians are
preserved verbatim. They concern boundary Wald covariance estimates and do not
prevent finite profile/bootstrap intervals, but they rule out a warning-free or
Wald-accuracy claim.

This evidence proves live provider plumbing for these cells. It does not prove
native-R parity, interval calibration or coverage, benchmark performance, or
the global G0-G8 programme gates.

Rose's final review and Melissa's bounded reconciliation both pass. Their
receipts are retained as `rose-review.md` and `melissa-reconciliation.md`.
