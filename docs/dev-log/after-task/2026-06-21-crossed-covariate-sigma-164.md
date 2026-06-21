# After Task: Crossed (1|g)+(1|h) covariate dispersion sigma ~ x (#164)

**Date:** 2026-06-21 (autonomous; Ada orchestrating, session 5)
**Worktree:** `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`,
branch `shannon/overnight-audit-verify-20260619`.
**Lane:** direct DRM.jl only. No R↔Julia bridge or native-TMB claim. MIT provenance intact.

## Goal

Close the remaining #164 sub-case — a covariate dispersion sub-model `sigma ~ x`
on the non-Gaussian CROSSED sparse-Laplace path `(1 | g) + (1 | h)` for NB2 /
Gamma / Beta. The phylo half of #164 landed earlier (2026-06-10/11); the crossed
half was the last gapped route named in the banked recipe (relmat stays out of
scope by design).

## Key decision: extend the hetero architecture, do NOT replay the stale branch

The full crossed impl exists on `shannon/issue-164-nonconst-sigma` (`f9edc0c`),
but it is 487 commits stale and, in the interim, the phylo `sigma ~ x` work landed
on HEAD via a DIFFERENT architecture: a separate `_phylo_mean_laplace_hetero_fg`
+ `Val(:*_hetero)` kernels, leaving the scalar `:*_fixed` kernels untouched.
`f9edc0c` instead mutates the `:*_fixed` kernels in place — a literal replay would
collide on core likelihood code and break HEAD's constant-σ path. So this slice
MIRRORS the existing phylo hetero architecture onto the crossed path instead. This
was confirmed by a 4-reader mapping fan-out (recipe ⋈ f9edc0c diff ⋈ current code
⋈ current tests) before any edit.

## What was done

- New `_crossed_mean_laplace_hetero_fg` (src/sparse_laplace_glmm.jl): the
  heteroscedastic generalisation of the scalar `_crossed_mean_laplace_nuisance_fg`.
  θ = `[βμ; βσ(pσ); logσ_g; logσ_h]`; `ησ = Xσ·βσ`; the σ-axis gradient
  `gν[k] += Xσ[i,k]·nval` and the implicit cross-term `crossν` (now `(G+Hh)×pσ`)
  gathered onto BOTH the g and h latent rows. Mean axis and the two RE-logSD
  gradients are identical to the scalar version. Reuses the in-tree
  `Val(:*_hetero)` kernels (no new `*_vec` helpers).
- New `_fit_crossed_mean_laplace_hetero` fitter (θ0 sizing, blocks, per-obs σ scales).
- `_fit_{nb2,gamma,beta}_crossed_laplace` now branch: constant 1-col Xσ → the
  bit-identical scalar path (unchanged); covariate Xσ → the new hetero fitter.
  Removed the three `sigma ~ 1`-only crossed guards (2735/2756/2779).
- Gamma/Beta crossed fitters now forward `se` (was dropped; NB2 already did), so
  the new σ slope is inferable. (This also fixes the pre-existing constant-σ
  Gamma/Beta crossed `se=true` case, which previously returned a NaN vcov.)
- New `test/test_164_crossed_hetero_sigma.jl`; registered in `runtests.jl`.
- De-staled prose the change falsified: family docstrings (negbinomial/gamma/beta),
  the `test_nonconst_sigma_re.jl` header, `docs/src/get-started.md`, and the
  phylo-hetero docstring dispersion note (`exp.(-2·ησ)`).

## Verification (all local, Julia 1.10, this session)

- New gates 34/34: FD-vs-exact ≤ 1e-6 (NB2/Gamma), ≤ 1e-4 (Beta βσ-slope
  coordinate); reduction invariant (1-col constant Xσ reproduces the scalar fg to
  val 1e-12 / grad 1e-10) for all 3 families; `drm()` recovery with σ-slope bands
  tightened to EXCLUDE zero (NB2 −0.312, Gamma −0.242, Beta −0.264).
- Regression: `test_crossed_laplace_generic.jl` 46/46 (constant-σ path incl. the
  `ones(n,1)` anchors); relmat guards still reject `sigma~x`; phylo #164 hetero +
  #165 grad gates + phylo recovery all green; `test_nonconst_sigma_re.jl` 21/21.

## Review

Verified by Noether (math), Fisher (inference), Rose (claim-boundary):
- Noether: GO — σ-axis chain rule, both-rows gathering, θ-slicing, and the exact
  reduction to the scalar path all correct term-by-term.
- Fisher: GO after tightening — FD gate genuinely exercises the implicit db̂/dθ
  terms (5–7 orders of margin); flagged loose recovery bands (now tightened to
  exclude zero) and the missing Gamma/Beta `se` forwarding (now fixed).
- Rose: GO after de-staling — confirmed constant-σ byte-preservation + relmat
  out-of-scope; flagged stale prose (now corrected).

## Boundaries respected

Direct-DRM.jl lane only — no bridge parity or native-TMB claim, no coverage /
release / speed claim. Scope is crossed-only; relmat/animal/spatial `sigma~x`
stays guarded by design. No GPL drmTMB/gllvmTMB code referenced. The constant-σ
crossed path is byte-preserved (regression 46/46).

## Follow-ups (not in this slice)

- relmat/animal/spatial `sigma~x`: now a CHEAP follow-on — the phylo hetero fg is
  Q-generic, so wiring a `_general_cov_setup` Q through a hetero general-cov fitter
  + flipping the relmat throw-tests would close the last non-Gaussian `sigma~x`
  route. Deliberately deferred (banked recipe scoped this slice crossed-only).
- Single non-phylo `(1|g)` non-Gaussian RE with `sigma~x` (the single-RE
  GHQ/Laplace path) — confirm whether it is already covered or a separate gap.
- #164 issue close: phylo + crossed both landed; relmat is explicitly outside the
  issue's "phylo/crossed" title scope. Proposing close pending owner approval.
