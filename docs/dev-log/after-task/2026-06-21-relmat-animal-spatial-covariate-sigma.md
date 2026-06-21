# After Task: relmat/animal/spatial covariate dispersion sigma ~ x (#164 follow-on)

**Date:** 2026-06-21 (autonomous; Ada orchestrating, session 6)
**Worktree:** `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`,
branch `shannon/overnight-audit-verify-20260619`.
**Lane:** direct DRM.jl only. No R↔Julia bridge or native-TMB claim. MIT provenance intact.

## Goal

Close the last non-Gaussian `sigma ~ x` route named as a follow-on in the crossed
#164 after-task (2026-06-21-crossed-covariate-sigma-164.md, "Follow-ups"): a covariate
dispersion sub-model over a general user-supplied PD covariance random intercept —
`relmat(1 | id)` (`K = C`), `animal(1 | id)` (`A = C`), `spatial(1 | id)` (`K = C`) —
for NB2 / Gamma / Beta. The phylo and crossed halves of #164 had already landed; the
general-covariance route was guarded (`sigma ~ 1`-only).

## Key decision: factor a Q-generic hetero core, mirroring the nuisance pair

The crossed note flagged this as cheap because "the phylo hetero fg is Q-generic." It
is — `_phylo_mean_laplace_hetero_fg` already takes `(Q, leaf_node)` directly and is
blind to whether Q comes from a tree or a matrix. The only thing NOT yet Q-generic was
the FITTER: `_fit_phylo_mean_laplace_hetero` built Q from the tree inline and ran the
optimisation itself, with no shared core — unlike the nuisance path, where
`_fit_phylo_mean_laplace_nuisance` already delegates to a Q-generic
`_fit_general_mean_laplace_nuisance`. So this slice extracts the hetero analogue
(`_fit_general_mean_laplace_hetero`) and makes the phylo hetero fitter a thin wrapper,
exactly mirroring the nuisance pair. The relmat fitters then branch on Xσ the same way
the phylo fitters already do.

## What was done

- New `_fit_general_mean_laplace_hetero` (src/sparse_laplace_glmm.jl): the Q-generic
  hetero core, extracted verbatim from `_fit_phylo_mean_laplace_hetero`'s body, taking
  `(Q, leaf_node)` + a `prec_error` message instead of `(labels, tree)`.
  `_fit_phylo_mean_laplace_hetero` is now a thin wrapper that builds Q from the tree via
  `_poisson_phylo_setup` and delegates — phylo hetero behaviour is byte-identical.
- `_fit_{nb2,gamma,beta}_relmat_laplace` now BRANCH on Xσ (mirroring the phylo
  fitters): constant 1-col Xσ → the existing `_fit_general_mean_laplace_nuisance` path
  (unchanged); covariate Xσ → the per-family `aux_from_hetero` + `_fit_general_mean_laplace_hetero`
  with the relmat-derived Q. Removed the three `sigma ~ 1`-only relmat guards.
- Flipped the relmat `sigma ~ x` throw-tests to affirmative `converged` fits
  (test_relmat_counts_nb2.jl, test_relmat_counts_beta.jl). Kept the orthogonal guards
  (missing K/A matrix; coords-only spatial for non-Gaussian).
- New tests (test_relmat_counts_{nb2,beta}.jl): `drm()` recovery of the σ-slope for
  relmat NB2/Gamma/Beta `sigma ~ x`; an FD-vs-exact gradient gate ≤ 1e-6 and a 1-col-Xσ
  reduction invariant, both driven through a relmat-derived (general-covariance) Q.
- De-staled the prose the change falsified: the NB2/Gamma/Beta family docstrings (which
  said general PD-covariance intercepts "still require `sigma ~ 1`") and the
  test_nonconst_sigma_re.jl header.

## Verification (all local, Julia 1.10, this session)

- New relmat hetero gates: NB2/Gamma/Beta `sigma ~ x` `drm()` recovery 7/7 each (σ-slope
  recovered with `re_sd > 0`); FD-vs-exact ≤ 1e-6 + reduction (1-col Xσ ⇒ scalar fg to
  val 1e-12 / grad 1e-10) over a general-covariance Q 5/5; flipped throw-test testsets
  10/10 each.
- Constant-σ regression (byte-preservation): existing relmat NB2/Gamma/Beta recovery +
  FD gates all green (the constant branch is the unchanged nuisance core).
- Core-extraction regression: #164 phylo NB2/Gamma/Beta FD + recovery + reduction all
  green, and the #164 crossed gates all green — the phylo hetero path is byte-identical
  after the extraction.
- Broader sparse-Laplace batch (no regression, 0 fail/error): test_crossed_laplace_generic.jl
  46/46 (non-Gaussian kernels 31, nuisance gradient 9, routing smoke 6);
  test_nonconst_sigma_re.jl 21/21; NB2/Gamma/Beta phylo nuisance routes + gradient gates all green.

## Review

Verified by Rose (claim-boundary) + Fisher (inference); both GO after the fixes below
were applied (re-verified locally — verdicts not trusted blind):
- Fisher (inference): GO. Confirmed the estimator is real (12-seed σ-slope sweep:
  12/12 correct sign, ~14% bias) and the load-bearing gates are honest (FD margin
  4.9e-8 = 20× headroom, with a genuinely large σ-slope gradient ~29 at the
  off-optimum; the 1-col-Xσ reduction is EXACT — measured 0.0 / 0.0). Caught that the
  recovery σ-slope bands INCLUDED zero (a constant-σ fit would have passed them) — bands
  tightened to atol 0.15 (recovered ≈ -0.28 / -0.19 / -0.30, all excluding 0), and the
  one-sided `re_sd > 0.10` replaced by the centered `≈ σb atol = 0.20` the constant-σ
  siblings use. The general-cov FD gate is near-redundant with the phylo #164 gate (same
  Q-generic fg) — kept as a regression guard, not sold as new math.
- Rose (claim-boundary): GO. Confirmed byte-preservation (the extracted core is
  character-identical to the old phylo body bar the Q source + `prec_error` kwarg; the
  constant-σ relmat branch routes to the unchanged nuisance core), the flipped
  throw-tests keep the orthogonal guards, and no bridge registry cell is falsified (the R
  bridge still gates `sigma ~ x` → native TMB). Caught two stale user-facing docs the
  de-staling sweep missed (`get-started.md`, `model-map.md`) — both corrected;
  model-map's "constant `sigma`" claim was PRE-EXISTING stale (since the phylo/crossed
  slices), now fixed. Flagged the cross-repo + DRY follow-ups below.

## Boundaries respected

Direct-DRM.jl lane only — no bridge parity or native-TMB claim, no coverage / release /
speed claim. This is a likelihood-capability landing (FD-gated exact gradient + point
recovery + byte-identical constant-σ reduction), NOT an engine-vs-engine parity. The
phylo + crossed `sigma ~ x` paths are byte-preserved. No GPL drmTMB/gllvmTMB code
referenced; MIT provenance intact.

## Follow-ups (not in this slice)

- The `aux_from_hetero` construction is now duplicated THREE ways per family — phylo
  fitter, crossed fitter (from the prior #164 slice), and the relmat sibling added here
  (the σ-axis aux is Q-independent). A shared `_<fam>_laplace_hetero_setup` helper
  (mirroring `_<fam>_laplace_setup`) would DRY all three; deferred to keep this follow-on
  surgical and the #164-verified phylo/crossed branches untouched.
- CROSS-REPO (parent drmTMB, NOT touched here): `R/julia-bridge.R` attributes the
  `sigma ~ 1` constraint to the DRM.jl ENGINE in several `claim_boundary`/error strings
  ("sigma predictors stay gated", the general-covariance route). That is now engine-level
  FALSE — the DRM.jl engine fits `sigma ~ x`; it is the R BRIDGE that still requires
  `sigma ~ 1` for this route. The bridge BEHAVIOUR is unchanged (no cell flip), but the
  wording misattributes the gate to the wrong layer and should be corrected drmTMB-side.
  The same strings list the general-cov families as "Gaussian, Poisson, NB2, Gamma" —
  omitting Beta. Both are drmTMB-prose follow-ups.
- Team hygiene (Rose): the per-family docstrings + throw-tests get de-staled every #164
  slice, but the cross-cutting overview surfaces (model-map narrative, get-started
  bullets, bridge `claim_boundary` strings) lag a slice behind. A grep gate for "constant
  `sigma`" / "require `sigma ~ 1`" / "sigma predictors stay gated" across `docs/src` +
  `R/julia-bridge.R` would stop the overview drift.
- Single non-phylo `(1 | g)` non-Gaussian RE with `sigma ~ x` (the single-RE GHQ/Laplace
  path) — still to confirm whether covered or a separate gap (carried over from the
  crossed note).
- SE/Hessian for the relmat hetero path is wired (`se` forwards) but not separately gated
  here; a vcov sanity gate could follow.
