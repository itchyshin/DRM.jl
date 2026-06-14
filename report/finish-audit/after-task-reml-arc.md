# After-task — the Ayumi q4 σ-phylo boundary arc, REML close-out (2026-06-14)

Author: Shannon. Audit lens: Rose. Stats lens: Pat. Status: engine gate PASSED;
full `Pkg.test()` running; send/merge/deploy HELD for Shinichi.

## What the arc was

Ayumi-495 was fitting bivariate q4 phylogenetic location–scale models and hitting
`pdHess = FALSE` at the σ-collapse boundary — the observed information is singular
when an among-axis SD sits on zero, so Wald SE/vcov is undefined exactly where she
needed it. The arc grew into: make the *whole* R→Julia path work (not just the
DRM.jl engine), keep her in R, and make profile likelihood — not bootstrap — the
headline interval.

## What landed this session

1. **REML scale-axis fix (the headline).** `src/reml_q4.jl`. The q4 REML profiled
   out only the **mean** fixed effects (β_μ); the **scale** fixed effects (β_σ) were
   left as plain ML outer parameters, so the restricted correction applied to 2 of
   the 4 axes. Result: REML was correct on the mean among-SDs and *wrong-signed* on
   the scale among-SDs. The fix extends the bordered-state profiling to all four
   axes — β_σ enters the leaf as `(etas + u)` exactly as β_μ enters as `(eta + u)`,
   so the same lifted-design / Schur-complement machinery generalises, including the
   mean↔scale cross-Hessian blocks `Hb[1,3]`, `Hb[3,1]`, … `phi` drops β_σ; the
   conditional Newton now estimates (β_μ1, β_μ2, β_s1, β_s2) jointly.

2. **Reply to Ayumi (`ayumi-reply-draft-rev8.md`).** REML section rewritten from
   "scale axis still being finalised" to "works fully on all four axes," plus the
   explore-everything encouragement you asked for (try ML and REML, both engines,
   profile and bootstrap, the boundary cases — she's the first serious user of this
   path and every odd thing she hits has made it better). Still leads with the
   verified profile-CI table; still two-engine; still no "calibrated" claim.

3. **Bridge group-label bug (`drmTMB R/julia-bridge.R`).** `confint()` parm rows
   on a bivariate fit were labelled `phylo(1 | group)` (literal fallback) instead of
   the real grouping variable, because `bp$group` is NULL on the live path. Now the
   group is recovered from the stored parsed formula's phylo terms (same extraction
   as `drm_julia_phylo_payload`). The article's `species` labels are now accurate.

4. **Article fixes (`vignettes/julia-engine.Rmd`, Pat + Rose).** (i) decoupled
   `derived_interval_unavailable` from `pdHess = FALSE` — they're two distinct
   things; (ii) `confint()` defaults to `wald`, so profile is *recommended* here,
   not the "default"; (iii) the boundary table no longer implies all four axes
   collapse — identified axes get a positive lower bound and `profile.boundary =
   FALSE`; (iv) a short REML note (now covers all four axes).

## Verification (honest)

- **Engine gate PASSED** via the real `drm(method = :ML/:REML)` path, `Sigma_a`
  diagonal SDs, p=16 synthetic with real among-scale signal:

  | axis | ML | REML before (bug) | REML after (fix) |
  |---|---|---|---|
  | mu1 | 0.338 | 0.354 ✓ | 0.354 ✓ |
  | mu2 | 0.275 | 0.302 ✓ | 0.294 ✓ |
  | sigma1 | 0.266 | **0.111 ✗ (down)** | **0.400 ✓** |
  | sigma2 | 0.301 | 0.282 ✗ | 0.313 ✓ |

  The defining property `diag(Σ_a)_REML ≥ diag(Σ_a)_ML` now holds on all four axes;
  the biggest correction is on σ1 — the axis that previously got none.
- **Full `Pkg.test()`** — running at time of writing; not yet green. No regression
  declared until it returns. (The change is isolated to `reml_q4.jl`; the three
  `_glsp_reml_*` univariate REML tests exercise a different route.)
- R bridge file parses clean; both worktree edits present.

## Lessons (the durable ones)

1. **Capability/gate drift is the recurring bug class of this whole arc.** Again and
   again the Julia engine *had* the capability and a thinner layer lagged: bivariate
   confint routing, missing-response, the `biv_gaussian` REML gate — and now the
   REML correction itself, which was "implemented" but scoped to 2 of 4 axes. When
   something "doesn't work," check one layer down before assuming it's missing.
   (Filed for the GLLVM team as gllvmTMB#488.)

2. **An "implemented" correction can be silently partial — test the defining
   property on every component, not a scalar.** The REML logLik-based round-trip was
   the *wrong* discriminator (ML and REML logLik differ trivially and told us
   nothing). The decisive test was the per-axis property `diag(Σ_a)_REML ≥
   diag(Σ_a)_ML`. For any variance-component estimator, gate on the property across
   all components.

3. **The fix was a generalisation the code already encoded.** The header's "KEY
   SIMPLIFICATION" — `d leaf/d β_axis = d leaf/d u_axis · X_axis` — was written for
   the mean but is true for every axis. Reading existing structure carefully beat
   reaching for a rewrite.

4. **Profile is the strength, and it decouples the two reporting questions.** The
   boundary-honest profile CI does not depend on ML vs REML, so "which point
   estimate" and "what interval" are separable: Wald for fixed effects, profile for
   random-effect SDs, REML for the better-calibrated point variance if wanted. That
   is the clean principle to hand Ayumi.

5. **Two engines, framed honestly.** Native `engine = "tmb"` (improved) fits;
   Julia adds *only* the one thing native Wald cannot — the boundary-honest interval.
   Julia is never mandatory.

## Rose's audit

- **License boundary:** clean. The REML fix is pure DRM.jl (MIT); no drmTMB GPL
  source vendored; R-parity continues to use generated outputs only.
- **Status discipline:** engine gate is verified and stated as such; the full suite
  is explicitly marked *not yet green*; the reply's REML claim is flagged in the
  internal header as DEPENDING on landing two still-local commits.
- **Held for Shinichi:** send the reply; merge the DRM.jl `reml_q4.jl` fix and the
  drmTMB worktree (group-label + REML gate + article); trigger the pkgdown deploy;
  registry/tags/CRAN. None done unprompted.

## What remains

- Confirm `Pkg.test()` green (running).
- Two follow-up commits to prepare for your merge: (1) DRM.jl `reml_q4.jl`;
  (2) drmTMB `R/julia-bridge.R` + `vignettes/julia-engine.Rmd`. Branch + PR on your
  word, not before.
- Then the gated launch steps at your pace. No CRAN.
