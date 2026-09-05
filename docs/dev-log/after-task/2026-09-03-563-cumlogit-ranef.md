# After-Task Report: CumulativeLogit random intercept + independent slope (#617, #563 S8)

- **Date:** 2026-09-03
- **Issue:** #563 (S8, remaining engine gaps); PR #617, branch
  `feat/563-cumlogit-ranef` @ `e84e469930a581d97b9303fc4465de8ce47b3a6e`
  (**PR open at report time — not yet merged**)
- **Perspectives:** Shannon (Coordination/Rose after-task pass, retrospective)

## 1. Goal

Close the `CumulativeLogit()` random-effects gap for the two iid cells drmTMB
0.7.0 implements on the mean (`validate_cumulative_logit_mu_random_terms`,
`R/drmTMB.R:10922`): `(1 | g)` and the independent slope `(0 + x | g)`. The
correlated `(1 + x | g)` and a random-effect scale formula must stay refused.
The phylogenetic intercept is explicitly **out of scope** for this slice
(follow-on #618).

## 2. Implemented

- The ordinal per-observation log-likelihood (cumulative-logit differences of
  thresholds minus η) plugs into the same 32-node Gauss–Hermite route the
  Gamma/Tweedie families use; thresholds keep their fixed-effects
  parameterisation.
- `src/cumulative.jl`: +247/−(net) lines for the new random-effects routes.
- Correlated `(1 + x | g)` and a random-effect scale formula stay refused on
  both sides.

## 3a. Decisions and Rejected Alternatives

- **Reuse the shared 32-node GHQ route** (already proven for Gamma and Tweedie,
  #615) rather than a bespoke ordinal quadrature kernel.
- **Thresholds keep their fixed-effects parameterisation** — no random effect on
  cutpoints in this slice.
- **Phylogenetic intercept deliberately deferred to #618** (a separate PR on the
  sparse-Laplace GLMM pattern, not the GHQ route) — the PR body states this
  explicitly rather than silently bundling or dropping it.

## 4. Files Touched

Per `git diff --stat origin/main...origin/feat/563-cumlogit-ranef`:

```
docs/src/families.md                                |  10 +
docs/src/model-guides/model-map.md                  |   5 +
src/cumulative.jl                                    | 247 ++++-
test/parity/fixtures/cumlogit-mu-ranef/data.csv      | 811 +++++++++++++++++++++
test/parity/fixtures/cumlogit-mu-ranef/gen_data.R    |  43 ++
test/parity/fixtures/cumlogit-mu-slope-ranef/data.csv| 601 +++++++++++++++
test/parity/fixtures/cumlogit-mu-slope-ranef/gen_data.R | 47 ++
test/runtests.jl                                     |   1 +
test/test_cumlogit_ranef.jl                          | 144 ++++
9 files changed, 1870 insertions(+), 39 deletions(-)
```

## 5. Checks Run

- **RED first:** `test/test_cumlogit_ranef.jl` errored on `origin/main` with the
  fixed-effects-only guard (`src/cumulative.jl:36`, per PR body).
- **GREEN 14/14.** Same-target vs drmTMB 0.7.0 on drmTMB's own arc-2a/2b DGPs
  (fixtures generated and fitted in R by the committed `gen_data.R`; both R fits
  `convergence = 0`, `pdHess = TRUE`):

  | cell | slope β (R) | cutpoints (R) | RE sd (R) | logLik (R) | tolerance |
  |---|---|---|---|---|---|
  | `(1 \| id)`, 45×18, K=4 | 0.7988 | −1.022, 0.028, 1.012 | 0.6876 | −1026.09 | θ atol 1e-2, sd rtol 5 %, logLik atol 1 |
  | `(0 + x \| id)`, 40×15, K=4 | 0.7991 | −1.029, 0.106, 1.104 | 0.3336 | −775.38 | same |

  Tolerances are looser than the Tweedie slice because per-group Laplace (R) and
  non-adaptive GHQ-32 (Julia) are different approximations of the same marginal;
  **one seed per cell**.
- **Neighbours green (per PR body):** ordinal recovery 4/4, Poisson RE 5/5 +
  4/4, Gamma 5/5, Tweedie 6/6, Binomial 11/11, AGHQ kernel 9/9, Poisson AGHQ
  surface 37/37, plus ten more files.
- Wired mid-file in `test/runtests.jl`; `docs/src/families.md` and
  `model-map.md` updated.
- **Flake observed, not caused by this PR:** a full local `Pkg.test()` hit one
  unrelated, order-dependent flake in `test_bootstrap_marginal.jl:95` (passes
  standalone twice) — noted in the PR body, not touched.

## 6. Tests of the Tests

- Same-target comparison against **drmTMB's own arc-2a/2b DGPs**, fitted
  independently in R with the committed `gen_data.R` and confirmed
  `convergence = 0, pdHess = TRUE` on the R side — a broken Julia
  implementation would show up as a Δ outside tolerance against a genuinely
  independent fit, not a self-consistency artefact.
- RED-then-GREEN documented explicitly (test errored on the pre-PR guard).

## 7a. Issue Ledger

- Advances #563 S8 by closing the CumulativeLogit iid-RE cell (intercept and
  independent slope on the mean).
- Explicitly defers the phylogenetic intercept to #618 (see there).
- **Flags, does not fix:** `test_bootstrap_marginal.jl:95` order-dependent
  flake — pre-existing, unrelated to this PR, observed during the full local
  `Pkg.test()` run.
- **PR #617 was still OPEN (not merged) at the time of this report.**

## 8. Consistency Audit

- The shared GHQ route (already exercised by Gamma and Tweedie) was reused
  without modification to its scaffold — neighbour suites for Gamma, Tweedie,
  Poisson AGHQ surface, and the AGHQ kernel itself all stayed green, indicating
  no regression to the shared machinery.
- Fixture DGPs were taken from drmTMB's **own** test suite (arc-2a/2b), not
  freshly invented, reducing the chance of a DGP that happens to favour the
  Julia implementation.
- No independent re-run of the R fixtures was performed in this docs-only
  session; the R-side numbers above are taken verbatim from the PR body.

## 9. What Did Not Go Smoothly

- A full local `Pkg.test()` run surfaced the pre-existing, order-dependent
  `test_bootstrap_marginal.jl:95` flake (passes standalone twice) — not caused
  by this PR, but it complicates trusting a single full-suite run as a clean
  signal; per-file verification was used instead (per PR body).

## 10. Known Residuals

- **Phylogenetic intercept for CumulativeLogit is NOT in this PR** — deferred to
  #618, which stacks on this branch.
- **One seed per cell** — no multi-seed recovery/coverage campaign.
- **PR not yet merged** at report time (`state: OPEN`).
- The `test_bootstrap_marginal.jl` order-dependent flake remains unfixed
  (out of scope, flagged only).
- Random-effect scale formulas and the correlated slope remain refused/
  unimplemented for CumulativeLogit — matching drmTMB's own scope, not a Julia
  limitation, but still a residual capability gap relative to a hypothetical
  fuller ordinal RE surface.

## 11. Team Learning

- The shared 32-node GHQ route is now proven across three families (Gamma,
  Tweedie #615, CumulativeLogit #617) — confirms it is a genuinely
  family-agnostic scaffold for iid random intercept/independent-slope cells, as
  long as the family supplies its own per-observation log-density.
- Deliberately splitting the iid-RE slice (#617) from the phylo-RE slice (#618)
  for the same family — because the phylo case needs the sparse-Laplace GLMM
  pattern, not GHQ — is a reusable decomposition for future families that need
  both RE surfaces.

## 12. Cross-Product Coverage

Random effects on the CumulativeLogit mean is a cross-cutting capability (adds a
new RE surface to an ordinal family, through the shared GHQ route).

- **Covers ✓:** `(1 | g)` random intercept on the mean; `(0 + x | g)`
  independent random slope on the mean; same-target validation vs drmTMB 0.7.0
  on drmTMB's own arc-2a/2b DGPs for both cells; documentation
  (`families.md`, `model-map.md`) updated.
- **Does NOT cover:** the correlated slope `(1 + x | g)` (refused, matching
  drmTMB); a random-effect scale formula (refused); the phylogenetic intercept
  on the mean (explicitly deferred to #618, on a different code path — the
  sparse-Laplace GLMM pattern, not GHQ); multi-seed recovery/coverage evidence
  (one seed per cell only); the pre-existing `test_bootstrap_marginal.jl`
  order-dependent flake (observed, not fixed); merge/landing status (PR #617
  was open, not merged, at report time).
