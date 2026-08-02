# #291 — Gaussian q4 REML acceleration: design boundary

**Issue:** [#291](https://github.com/itchyshin/DRM.jl/issues/291)  
**Scope:** design only; Gaussian q4 phylogenetic location--scale REML.  
**Status:** deferred implementation. This note neither changes the public API nor
reports a performance result.

## Estimand and current baseline

The supported q4 REML objective is the restricted Laplace objective implemented
by `fit_q4_reml`:

\[
\ell_R(\phi) =
  \ell_{\mathrm{Laplace}}(\hat u,\hat\beta;\phi)
  - \tfrac12\log\left|S\right|,
\qquad
S = H_{\beta\beta} - H_{\beta u}H_{uu}^{-1}H_{u\beta}.
\]

Here \(\phi=(\beta_\rho,\operatorname{lc}(\Lambda))\).  The location and
log-scale fixed effects, \(\beta_{\mu_1},\beta_{\mu_2},
\beta_{\log\sigma_1},\beta_{\log\sigma_2}\), are jointly profiled, while
\(\beta_\rho\) remains outer because it has no random-effect axis.  The
Schur-complement correction must therefore include all four lifted fixed-effect
axes and their mean--scale cross blocks.  Each outer evaluation currently
alternates a sparse augmented-state mode solve with conditional fixed-effect
Newton updates, then evaluates the Laplace term and restricted correction.

This boundary is **Gaussian q4 only**.  It does not establish an acceleration
route for other Gaussian structures, non-Gaussian Laplace models, or a general
distributional-regression REML interface.  ML remains the default because REML
objectives are not comparable across fixed-effect structures.

## What the landed `lc_metric` may and may not do

`lc_metric` is reusable local curvature infrastructure from the landed #13
decision gate: a ridge-projected, SPD 10-by-10 observed-information metric for
the *ML marginal NLL* in the log-Cholesky coordinates of \(\Lambda\).  It is
formed by central finite differences of the existing exact lc gradient (20
gradient evaluations), not by a REML score or REML Hessian.

Consequently, a later q4 REML experiment may reuse its numerical discipline:

- retain sparse factorizations and selected-inverse/Takahashi work already
  needed by a mode/gradient evaluation;
- warm-start neighbouring evaluations only after a cold re-evaluation confirms
  the restricted objective at the proposed point;
- use local SPD curvature solely as a safeguarded preconditioner or proposal
  metric, with line search/trust-region acceptance based on the restricted
  objective.

It may **not** be labelled an exact REML information matrix, an AI-REML matrix,
or evidence that a Fisher/natural-gradient solver is valid for q4 REML.
`lc_metric` cannot by itself supply the derivative of the Schur-complement
restriction, the mode-dependence terms, or the profiled fixed-effect curvature.

## Why the HSquared AI-REML quadratic does not transplant

AI-REML's familiar quadratic/linear-mixed-model construction applies when the
restricted Gaussian likelihood is expressed through a fixed marginal covariance
\(V(\psi)\), its projection \(P\), and variance-component derivatives
\(\partial V/\partial\psi_j\).  Its score and average-information curvature are
derived for that exact Gaussian LMM/MME structure.

The q4 location--scale route is not such a quadratic restricted likelihood:
log-scale random effects enter the Gaussian leaf likelihood nonlinearly; the
Laplace Hessian and log determinant depend on the fitted latent mode; and the
restriction is the mode-dependent Schur complement above.  Replacing that
objective with an HSquared-style \(P\,\partial V\,P\) update would omit precisely
the mode, log-determinant, and mean--scale coupling terms that define this
estimand.  The valid transfer is therefore implementation discipline
(factorization reuse, selected-inverse reuse, guarded local curvature), not the
HSquared AI-REML quadratic or its name.

## Later-candidate acceptance gates

No accelerated candidate is eligible for a speed comparison until the following
gates pass against the current `fit_q4_reml` baseline on fixed small and
intermediate Gaussian q4 fixtures (including `nrep >= 2` and an off-diagonal
\(\Lambda_0\) to avoid the lc3/lc7 removable singularity):

1. **Same restricted objective.** At the final, independently cold-re-evaluated
   solution, the restricted log likelihood must agree within
   \(10^{-6}\max(1,|\ell_R|)\).  Both paths must use the same parameter
   constraints and restricted correction.
2. **Same estimates.** Report \(\beta_\rho\), profiled fixed effects, and the
   transformed \(\Lambda\).  Their relative Euclidean discrepancy must be at
   most \(10^{-4}\), unless the baseline is on a declared variance boundary; a
   boundary fixture then requires matching objective plus the same explicit
   boundary status rather than a misleading coordinate comparison.
3. **Same inference status.** For every requested profile/bootstrap interval,
   preserve finite-versus-one-sided-versus-unavailable status and the
   boundary/diagnostic status.  Where both endpoints are finite, they must agree
   to the same \(10^{-4}\) relative tolerance.  A candidate may not silently
   turn an unavailable or boundary interval into an ordinary Wald interval.
4. **Only then measure time.** Record commit SHA, dirty flag, Julia and BLAS
   versions, thread count, fixture shape, convergence diagnostics, objective,
   estimates, and CI status for baseline and candidate.  Treat a failed gate as
   a rejected estimator, not as a benchmark result.

These gates preserve the current sparse augmented-state contract: never form a
dense phylogenetic covariance, retain robust mode finding, and stop on a
relative objective near singular variance boundaries.

## Explicit non-claims

- No public AI-REML solver is proposed or exposed.
- No public `algorithm = :natgrad` is proposed; #13's natural-gradient EM
  candidate stalled and remains non-public.
- No 10,000-tip REML speed headline follows from this note or from ML scaling.
- This issue is not evidence for Julia General registration; D-111 still
  defers General until the twin/readiness conditions hold.

The landed `lc_metric` is a useful prerequisite for investigating #291, not a
completion of #291.
