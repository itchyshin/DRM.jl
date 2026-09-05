# Re-verification against the real anchor: drmTMB 0.7.0 installed

Date: 2026-08-15 · lane: DRM.jl (Claude) · owner-approved environment change

## What changed

drmTMB **0.7.0** is now installed (built from a temporary `git worktree` at
`origin/main` — never `git checkout` in the shared drmTMB tree, which would move
HEAD under another lane). Every parity number recorded before today was measured
against **0.6.0**.

`biv_lognormal`, `biv_student`, `associate_pairs`, `latent_normal` and
`association` are all present in the installed build.

## Every parity cell re-run against 0.7.0 — all still pass

```
base_gaussian_location_scale   PARITY_PASS   coef 4.564e-06   logLik 4.584e-09
base_gaussian_intercept_only   PARITY_PASS   coef 2.492e-10   logLik 5.258e-13
fe_poisson                     PARITY_PASS   coef 1.029e-12   logLik 1.705e-13
fe_nbinom2                     PARITY_PASS   coef 2.787e-08   logLik 2.274e-13
fe_gamma                       PARITY_PASS   coef 3.912e-06   logLik 2.750e-09
biv_lognormal                  PARITY_PASS   coef 9.149e-07   logLik 7.390e-12
biv_student                    PARITY_PASS   coef 3.117e-06   logLik 1.026e-09
```

Identical to the 0.6.0 numbers, so the implementations were already right against
the true anchor.

## The campaign HEADLINE, now MEASURED rather than read

Earlier this campaign I concluded from *reading* `drm_julia_family_tag()` that
fixed-effect non-Gaussian families route through `engine = "julia"` on 0.7.0. That
is now **executed and measured**:

```
poisson  ADMITTED via engine=julia   coef_diff=1.029e-12   logLik_diff=1.705e-13
nbinom2  ADMITTED via engine=julia   coef_diff=6.891e-08   logLik_diff=6.821e-13
gamma    ADMITTED via engine=julia   coef_diff=5.319e-06   logLik_diff=4.599e-09
```

**This is a real upgrade in evidence class.** Those cells previously compared
native TMB against the DRM.jl *bridge payload* — direct Julia evidence, which by
the standing rule is **not** R-via-Julia bridge support. They now run
`engine = "tmb"` versus `engine = "julia"` through drmTMB itself, which is the
comparison the promotion gate actually requires. `tools/parity_fixture.R` has
been updated so this is what the harness measures from now on.

## Anchor drift, noted

drmTMB `origin/main` has already moved from `f5ec53634` (the A0 anchor) to
`859c0f6e6`. The twin is developing fast; re-run
`python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main` before
relying on any count.

## What this still does not establish

Point estimates and logLik only. No interval, coverage, or reliability claim.
No RE/phylo cell. And promoting a drmTMB capability row remains a **claim
decision inside drmTMB's own release process**, not something this evidence
performs by itself.
