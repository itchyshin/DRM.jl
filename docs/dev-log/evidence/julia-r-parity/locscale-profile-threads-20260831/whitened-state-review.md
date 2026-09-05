# Private whitening and reading checkpoint review

2026-08-31, programme #563/S11. Root+three existing explicit child routes:
builder Terra/high, mechanical scout Luna/low, Rose Sol/high. Root actual
Sol/medium; do not recast it as the proposed high route. Agent-hours not measured.

Rose reviewed helper af1ca0ac/test4226d2a: preserving stored zero block slots is
numerically sound, without jitter/dense latent inverse. Qsymmetry and finite
transport guards are correct. She required checking raw Hessian finiteness before
pattern reconstruction; builder1baf3baf makes that correction. Root inspected it.
Run190401Z verifies252/252,12.363s,Julia/BLAS1/1,unchanged reviewed source/test.
First247pass1fail is retained, not converted into an exclusion.

Rose independently checked the literature crosswalk and scale conversion.
Zhang public XML and Leckie publisher text support its main scope statements.
MIXREGLS detailed quadrature/erratum were not independently re-fetched by Rose;
scout read the public paper and retrieved the erratum. This difference in review
coverage is retained, not called full independent replication.

## Next paired wiring: read-only builder map, not an applied patch

- DRM.jl include after locscale_infer and before locscale_profile.
- Keep _ls_fit_nll, _ls_marginal_grad and _ls_obs_information raw for existing
  sigma/corr callers. Add paired siblings and explicit private route selection.
- LocScaleObjective currently has no general Z fields. Its original construction
  must stay meaningful. Coupled frontend explicitly opts into reviewed paired
  route; preserve actual loadings if extending objective storage.
- _fit_locscale nll/g!/h!, final accepted value/seed and finalV must use one route.
  No raw final nll/vcov call after a whitened optimization. Corr line113 calls
  _fit_locscale with noncanonical Z and later raw inference; preserve it.
- Information +/- evaluations use independent copied seeds. Seeds are guesses,
  not accepted-state caches. Each evaluation recertifies currenttheta.
- Profile constrained value, nuisance gradient, nmin, initialV and envelope
  derivative use the same representation; preserve status/sentinel/root rules.
  Lower then upper chain resets warmstate/lastsol. Each coefficient job later
  owns its own state. Threading only after original finite numerical gate passes.
- Review locscale_frontend184/190 alongside these consumer changes. Acquire
  exact leases first: none of these new consumer edits occurred in this slice.

Melissa checkpoint: original finite-profile12pass4fail remains open. Helper
success is only localG0/G1. Global parity/performance/docs/recovery/cleanup and
final-head evidence remain obligations. No production source/tests committed
by the evidence-only checkpoint. No protected Gaussian/tutorial edits, remote
campaign, publication or cleanup. Current whole-programme hours cannot be
inferred from child counts or token totals.
