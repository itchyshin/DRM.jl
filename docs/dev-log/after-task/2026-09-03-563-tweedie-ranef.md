# After-Task Report: Tweedie random intercept + independent slope (#615, #563 S8)

- **Date:** 2026-09-03
- **Issue:** #563 (S8, remaining engine gaps); PR #615, branch
  `feat/563-tweedie-ranef` @ `56352694674b662d1ece63bad73445b3805a30be`
  (**PR open at report time — not yet merged**)
- **Perspectives:** Shannon (Coordination/Rose after-task pass, retrospective)

## 1. Goal

Close the `Tweedie()` random-effects gap for exactly the two cells drmTMB 0.7.0
implements on the mean: `(1 | g)` and the independent slope `(0 + x | g)`. The
correlated slope `(1 + x | g)` and random effects on `sigma`/`power` or structured
markers must stay refused.

## 2. Implemented

- The Tweedie per-observation log-density plugs into the same 32-node
  Gauss–Hermite quadrature route the Gamma family already uses
  (`_fit_tweedie_ranef`, `_fit_tweedie_slope_ranef`); `phi` and `power` are
  estimated as in the fixed-effects route.
- `(1 + x | g)` (correlated slope) refused on both sides: the PR body notes a
  prior NEWS-based reading that drmTMB supported it was **wrong** and is
  corrected here — drmTMB's `validate_tweedie_mu_random_terms` refuses it too.
- `src/tweedie.jl`: +166 lines (net) for the new random-effects routes.

## 3a. Decisions and Rejected Alternatives

- **Reuse the Gamma family's 32-node GHQ route** rather than writing a
  Tweedie-specific quadrature kernel — Tweedie's per-observation log-density
  slots directly into the same integration scaffold.
- **Correlated slope stays refused, matching drmTMB**, correcting an earlier
  (wrong) NEWS-based assumption that it was supported — the PR explicitly flags
  this correction rather than silently changing scope.
- **`phi`/`power` estimated as in the fixed-effects route** (not re-derived for
  the RE case) — no new estimation logic for the dispersion/power parameters.

## 4. Files Touched

Per `git diff --stat origin/main...origin/feat/563-tweedie-ranef`:

```
docs/design/capability-status.md                   |  14 +
docs/src/families.md                               |   7 +
src/tweedie.jl                                      | 166 ++++++++++-
test/parity/fixtures/tweedie-mu-ranef/data.csv      | 321 +++++++++++++++++++++
test/parity/fixtures/tweedie-mu-ranef/gen_data.R    |  53 ++++
test/parity/fixtures/tweedie-mu-slope-ranef/data.csv| 321 +++++++++++++++++++++
test/parity/fixtures/tweedie-mu-slope-ranef/gen_data.R | 43 +++
test/runtests.jl                                    |   1 +
test/test_tweedie_ranef.jl                          | 144 +++++++++
9 files changed, 1064 insertions(+), 6 deletions(-)
```

## 5. Checks Run

- **RED first:** `test/test_tweedie_ranef.jl` failed on `origin/main` with the
  fixed-effects-only error (per PR body).
- **GREEN 18/18.** Same-target vs drmTMB 0.7.0 (fixtures generated and fitted in
  R by the committed `gen_data.R`; numbers hard-coded with the command per the
  PR body):

  | cell | β(Intercept) Δ | β(x) Δ | log σ Δ | logit p Δ | RE sd Δ | loglik Δ |
  |---|---|---|---|---|---|---|
  | `(1 \| g)` | 1.4e-4 | 1.4e-5 | 1.7e-6 | 3.3e-5 | 0.2 % | 0.052 |
  | `(0 + x \| g)` | 2.1e-4 | 5.0e-5 | 6.6e-5 | 3.3e-4 | 0.39 % | 0.076 |

  Tolerances (1e-3 abs on θ, 1 % on the RE sd, 0.3 on loglik) reflect that TMB's
  Laplace and this package's 32-node GHQ are different approximations of the
  same marginal integral, with 4–15× headroom over the measured gaps. **One seed
  per cell — no multi-seed campaign.**
- **Neighbours green (per PR body):** Tweedie recovery 6/6, AGHQ kernel 9/9,
  Poisson AGHQ surface 37/37, Gamma 5/5, Poisson 4/4, Cox–Reid REML 35/35,
  `ranef()` 15/15.
- Wired mid-file in `test/runtests.jl`; `docs/src/families.md` and
  `docs/design/capability-status.md` updated.

## 6. Tests of the Tests

- The same-target comparison is against an **independently fitted R drmTMB 0.7.0
  model** (fixtures generated and fitted by a committed `gen_data.R`, not a
  Julia-side self-consistency check), so a wrong quadrature implementation would
  show up as a Δ outside the stated tolerances, not just as internal agreement.
- The 4–15× headroom between measured Δ and stated tolerance means the test
  would fail well before the tolerance is exhausted if the fit degraded
  meaningfully.
- RED-then-GREEN documented explicitly in the PR body.

## 7a. Issue Ledger

- Advances #563 S8 (remaining engine gaps) by closing the Tweedie RE cell.
- **PR #615 was still OPEN (not merged) at the time of this report** — this
  after-task documents the branch tip, not a landed merge commit. Re-verify
  merge status before treating this as closed work.

## 8. Consistency Audit

- The correlated-slope refusal was checked against drmTMB's actual
  `validate_tweedie_mu_random_terms` source (not assumed), correcting a prior
  NEWS-based misreading — the PR body is explicit that this is a correction, not
  new information taken on faith.
- Neighbour test suites spanning the shared GHQ route (Gamma, Poisson AGHQ
  surface, AGHQ kernel) all stayed green, indicating the shared quadrature
  scaffold was not regressed by the Tweedie addition.
- No independent re-run of the R fixtures was performed in this docs-only
  session; the Δ table above is taken verbatim from the PR body.

## 9. What Did Not Go Smoothly

- An earlier (pre-PR) belief that drmTMB supported the correlated Tweedie slope
  `(1 + x | g)` was wrong (based on a NEWS-file reading rather than the
  validator source) and had to be corrected during this slice.

## 10. Known Residuals

- **One seed per cell** — no multi-seed recovery/coverage campaign for either
  RE cell.
- **PR not yet merged** at report time (`state: OPEN`); this report is written
  against the branch tip and must be re-verified once merged.
- Random effects on `sigma`/`power` and structured markers (phylo/relmat/etc.)
  for Tweedie remain refused/unimplemented — out of scope for this slice.
- No independent Julia-side re-derivation of the GHQ integration for Tweedie was
  performed in this after-task pass; the correctness evidence is the R
  same-target comparison reported in the PR.

## 11. Team Learning

- **NEWS-file claims about a competitor/reference package's scope are not
  ground truth** — the correlated-slope capability was believed present based on
  NEWS, and only reading the actual validator function (`R/drmTMB.R`) caught the
  error. Future capability-parity claims about drmTMB should cite the validator
  or model code, not the NEWS file, per this correction.
- The shared 32-node GHQ route (used by Gamma, Tweedie, and — per #617/#618 —
  CumulativeLogit) is now a proven-reusable scaffold for slotting in a new
  family's per-observation log-density without new integration machinery.

## 12. Cross-Product Coverage

Random effects on the Tweedie mean is a cross-cutting capability (adds a new RE
surface to an existing family, through the shared GHQ route).

- **Covers ✓:** `(1 | g)` random intercept on the mean; `(0 + x | g)`
  independent random slope on the mean; same-target validation vs drmTMB 0.7.0
  for both cells; `ranef()` on the new RE terms (neighbour suite 15/15 stayed
  green); documentation (`families.md`, `capability-status.md`) updated.
- **Does NOT cover:** the correlated slope `(1 + x | g)` (refused, matching
  drmTMB); random effects on `sigma` or `power`; any structured marker
  (phylo/relmat/spatial) combined with Tweedie random effects; multi-seed
  recovery/coverage evidence (one seed per cell only); merge/landing status (PR
  #615 was open, not merged, at report time).
