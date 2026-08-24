# After-task — R↔Julia parity catch-up: the interval axis

**Date:** 2026-08-24 · **Platform:** Claude Code · **Branch:** `parity/se-axis`
**Issue:** [#457](https://github.com/itchyshin/DRM.jl/issues/457) · **Base:** `main` @ `6ee03fd`

## 1. Goal

Open the campaign the parity-ledger countdown deferred — *"0 export gaps ≠ parity
complete; the 11 unsupported capability rows remain the next frontier"* — by measuring
every capability whose only blocker is measurement, in one day.

## 2. Implemented

- **An SE / interval axis the harness never had.** `compare_se` + an optional `[se]`
  fixture block, wired into `compare_fit` and `compare_bridge`, parsed by
  `loadfixture.jl`, plus `tools/parity_se.R` for live Route-2 measurement.
- **All 11 canonical fixtures re-measured** against installed drmTMB 0.7.0 (frozen at
  0.6.0), seeds preserved, now carrying `[se]` blocks.
- **Four capability rows gained live same-target evidence:** `plain_binomial_nonphylo`,
  `phylo_count_large_p` (Poisson + NB2 at p=300), `general_covariance_structured`
  (Gaussian/Poisson/NB2/Gamma), `biv_gaussian_residual` (SE).
- **`tools/parity_crosscheck.py`** — the two evidence stores had never been reconciled.
- **AGHQ chip** `missing → implemented` on the ledger's own criterion. Tally 40/1/1/4 → 41/1/1/3.
- **Three latent bugs fixed** (§9).

## 3a. Decisions and rejected alternatives

- **Evidence, not promotion.** No drmTMB edit; that repo is in CRAN prepare-only quiesce.
  No capability row moved to `supported` anywhere. Each promotion becomes a one-line edit
  backed by a measured number, later.
- **Rejected: a numeric Route1↔Route2 cross-check.** The two routes fit *different data*
  (seed 20260604/n=180 vs 20260814/n=120). Comparing their numbers would pass or fail for
  meaningless reasons. The reconciler checks coverage, version skew and status instead.
- **Rejected: publishing benchmark timings.** See §10.
- **Rejected: tightening `phylo_gamma`'s tolerance.** Its margin is a boundary artefact
  (§9); tightening off a well-behaved seed would just move the failure to another draw.

## 4. Files touched

Created: `tools/parity_se.R`, `tools/parity_crosscheck.py`, `tools/parity_classc.R`,
`tools/bench_fit_h2h.R`, `tools/bench_bootstrap.R`,
`docs/dev-log/evidence/{parity-se,parity-classc,bootstrap-h2h,fit-speed-h2h}.tsv`,
`docs/dev-log/evidence/2026-08-24-{se-axis,route2-refresh,chip-audit,phylo-gamma-margin,sd-floor-asymmetry,070-regen,classc-cells,bootstrap-h2h,fit-speed-h2h}.md`,
`docs/dev-log/check-log.d/2026-08-24-parity-wave1.md`, this file.

Modified: `test/parity/compare.jl`, `test/parity/loadfixture.jl`,
`test/parity/gen_fixtures.R`, `tools/parity_fixture.R`, `tools/parity_biv_meta.R`,
`docs/design/capability-status.md`, `.gitignore`, and the 11
`test/parity/fixtures/<slug>/{expected,expected.meta}.toml` pairs.

Not staged, deliberately: `.codex/agents/shannon-coordinator.toml` (PROTECTED per the
2026-08-24 handover).

## 5. Checks run

| check | result |
|---|---|
| `tools/parity_ledger.py --ref origin/main` | `0 export gaps (17 raw, 17 accounted) · 11 rows · 14 gates`, **CLOSURE: PASS** |
| D-139 live-bridge pre-run test | **green** — tmb/julia logLik both −79.19668, coef diff 2.15e-08 |
| Route-2 refresh, all 5 scripts @ 0.7.0 | **zero drift**, no status change on 20 rows |
| `DRM_PARITY_TESTS=1 … runparity.jl` | **exit 0**, 11 pass, 0 failures |
| `tools/parity_crosscheck.py` | **PASS** (after fixing the 3 defects it found) |
| acceptance ledger | **15 met, 1 abandoned with reason** |
| GF1 coverage fences | intact — both `interval_status != "coverage_claimed"` assertions |
| GF2 drmTMB untouched | dirty-set hash `0c763689…` identical to baseline |
| GF3 claim scan | only *disclaimers*; no speed/accuracy claim outside a dated evidence doc |

## 6. Tests of the tests

Every new checker was made to fail before being trusted:

- **SE comparator** — perturbing one SE by 10% produces
  `se[mu_(Intercept)]: drmTMB=0.0658538 DRM.jl=0.0724392 |Δ|=6.585e-03 > (rtol=0.001)`.
- **Route-1 SE path** — passing fixtures do not prove the `[se]` block was *exercised*;
  feeding `gaussian-locscale` its own SEs passes, perturbing one fails.
- **Cross-check** — `--inject-contradiction` makes it report `CROSSCHECK: FAIL`.
- **`[tol]` preservation** — verified by an actual regeneration, not by reading the diff.
- **Backward compat** — 11/11 legacy fixtures load with an empty `se`.

## 7a. Issue ledger

#457 opened as the work ledger. #456 (handover) merged. #420/#406 untouched (DIRTY, leave
OPEN per scout #455). #49, #136, D-111 untouched.

## 8. Consistency audit

No capability row promoted to `supported`. drmTMB unmodified. The 2.18× and O(p) claims
untouched. `docs/design/capability-status.md` changed exactly one status word, with the
scope *narrowed* in prose (Poisson `(1|g)` only, `:REML` not wired to `:AGHQ`).

## 9. What did not go smoothly

Three bugs, each found by running something rather than reading it:

1. **My own `loadfixture.jl` edit was inert.** It parsed `[se]` and never passed it to the
   constructor. The diff read correctly; `SE_PARSED=0` caught it.
2. **`compare_fit` silently discarded declined SE names** — it passed `String[]` as a
   throwaway, contradicting `ParityExpected`'s own docstring ("declined, never silently
   passed"). A fixture declaring every SE name `not_comparable` would have reported
   `passed=true` having compared nothing. Found by reading the implementation; this class
   of defect has no failing test by construction.
3. **`gen_fixtures.R` destroyed hand-written tolerances.** `write_case()` unlinks the whole
   fixture directory before rewriting, so three fixtures' `atol_coef`/`atol_vcov` overrides
   *and the comments explaining why each bar was widened* vanished on any regeneration —
   no error, no warning. My first fix read the file inside `write_expected()` and did
   nothing at all, because the directory was already gone. The regeneration test caught it.

Also: `tools/parity_biv_meta.R` was silently broken on any path containing a space
(`system2` does not quote; this repo lives under "Github Local").

## 10. Known residuals

- **Benchmark timings — CARRIED-OVER, not measured.** The machine never went quiet: DRM.jl's
  own `Pkg.test()` (49+ min) plus a *different lane's* `devtools::test()` held load at ~18
  on 20 cores. A ratio does not rescue it — the provisional data showed the direction
  **flip** between bootstrap (TMB ahead) and single fits (Julia ahead 6.3–10.5×), so
  contention affects the engines differently rather than cancelling. Both harnesses exist
  and run; resume command in `.unlazy/parity-catchup/GATES.md` under `ABANDON: G4A`.
  The **load-independent** halves are final: bootstrap intervals agree
  (tmb [1.300263, 1.300271] vs julia [1.300260, 1.300277]); no logLik disagreement > 1e-4.
- **The optimizer question is unanswerable today.** `fit$bridge$iterations` is `NA`
  everywhere — iteration counts do not cross the bridge. Both sides are quasi-Newton
  (nlminb vs LBFGS), so "better optimizer" is not yet supported by evidence.
- **`_LAPLACE_LOG_SD_FLOOR = log(1e-6)` exists in DRM.jl and not in drmTMB.** Whether it
  *should* is an engine design question with a usability argument on both sides, out of
  scope for a measurement arc — but now a measured difference rather than an unexamined one.
- **`phylo_beta` may cross 1e-4** under a near-boundary draw (observed at 1.58e-4). Same
  mechanism, different family. Not chased.
- **drmTMB carries 102 uncommitted files** on `claude/handover-freshness-0718` from a prior
  lane. Not mine; flagged.
- Remaining blocked rows unchanged: `gaussian_response_mask` (#49 PARKED),
  `phylo_gamma_beta_binomial` binomial axis (drmTMB refuses), `cross_family_latent` and
  `engine_control_surface` (R-API design gates).

## 11. Team learning

**A passing suite does not prove a new check ran.** Adding `[se]` blocks made the replay
still print 11 passes — identical output to before the axis existed. Only a deliberate
perturbation proved the SE path was exercised. Every new comparator here was made to fail
before being trusted.

**Boundary differences masquerade as tolerance problems.** `phylo_gamma`'s loose margin
looked like a tolerance question for weeks. It was a *feasible-set* difference: the engines
agree to 7.8e-12 at a shared parameter vector and disagree only because one may stop where
the other may not. The signature — coefficients agreeing to 6e-08 while logLik opens to
2.9e-05 — is diagnostic, and no tolerance choice would have fixed it.

**Generators that unlink before writing destroy knowledge silently.** Worth checking
wherever a fixture is regenerated rather than patched.

## 12. Cross-product coverage

Capability rows with live same-target evidence after this arc: `base_gaussian_location_scale`,
`biv_gaussian_residual`, `plain_binomial_nonphylo`, `phylo_count_large_p`,
`general_covariance_structured`, plus `gaussian_phylo_mean` and `biv_q4_phylo_reml` from
existing same-target fixtures. Un-evidenced and blocked for stated reasons:
`gaussian_response_mask`, `phylo_gamma_beta_binomial` (binomial axis), `cross_family_latent`,
`engine_control_surface`.

---

# Addendum — two engine defects the measurement uncovered (#459, #461)

The arc was scoped as *measurement, not repair*. These two are the exception: the
measurement surfaced defects that made the measured quantity meaningless, so fixing
them was the only way to finish measuring. The owner directed both.

## What was wrong

**#459 — the parametric bootstrap conditioned on the fitted BLUPs.**
`_bootstrap_result` called `simulate(fit0)`, a *conditional* simulator: for a
Gaussian fit it returns `fit.means[:mu] .+ sigma .* randn(n)`, and `fit.means[:mu]`
already contains the BLUPs. Every replicate re-used the same realised random
effects, so a variance-component CI collapsed onto its point estimate. Fixed with
`_marginal_simulator`, following the pattern `bootstrap_q4_phylo.jl` already used.

**#461 — a degenerate optimum reported convergence.** With one row per group the
Gaussian likelihood is unbounded as the residual scale → 0. `Optim.converged`
returns `true` at `sigma = 7.5e-15`, `loglik = 6.78e13`, `sd_phylo = 22980`, and 25%
of replicates landed there. Fixed in `is_converged`.

## Result

| stage | julia interval | width | used / failed |
|---|---|---|---|
| as reported in #459 | [1.300189, 1.300442] | 0.000253 | 200 / 0 |
| after the #459 fix | [1.046098, 179.2615] | — | 200 / 0 |
| **now** | **[1.045239, 1.416228]** | **0.3710** | **190 / 10** |
| native TMB | [1.027252, 1.450820] | 0.4236 | 200 / 0 |

From **1674× apart to a width ratio of 0.88**; per-refit speed ratio 1.017.

Also landed: `fit$bridge$iterations` now crosses the bridge (was `NA` everywhere),
with **no drmTMB change** — the R side passes the payload through, which mattered
because drmTMB is CRAN-quiesced. First result: DRM.jl takes ~8 iterations where TMB
takes 5–15, so the 2.2–12.5× fit advantage is **per-iteration cost, not fewer
iterations**. The "better optimizers" hypothesis is not supported by that.

## What did not go smoothly (the useful part)

**I tried the wrong fix shape for #461 first.** I wired the degeneracy guard into
individual `DrmFit` construction sites — four files patched, and the guard still
never fired, because the path in question constructs its fit somewhere else again
(~30 sites across 20 family files). Reverted all of it and put one check in
`is_converged`, the single public accessor every consumer already goes through.
*When a guard has to be repeated at thirty call sites, the call sites are the wrong
layer.*

**A scale trap nearly shipped inside the #459 fix.** `re_sd` for a phylo term is
defined against the RAW covariance (diagonal = tree height), not the normalised
correlation. My first simulator used the correlation matrix and under-dispersed by
√height; the resulting CI failed to contain its own point estimate. Caught by
round-trip across three tree heights (0.85 / 1.7 / 5.667): correlation gives
0.699 / 0.374 / 1.116, raw gives 0.917 / 0.917 / 1.032. Stable ⇒ the residual 0.92
is ML shrinkage, not scale. *A fix verified on one tree height would have been
plausible and wrong.*

**A false failure count.** A first read of the full-suite log reported "2 failures".
Both were testset **names** containing the word "error", each passing. A grep loose
enough to match a testset title is not a failure detector.

## Verification

Full `julia --project=test test/runtests.jl`: **302 testsets, zero carrying a
Fail/Error/Broken column.** All four #459/#461 testsets ran inside it (16 passes),
each with its positive control demonstrated — on the pre-fix path the discriminating
assertions fail, so they catch the bug rather than merely passing.

`Pkg.test()` cannot be used on this machine: it fails with `ERROR: can not merge
projects` before running anything. Pre-existing, unrelated to these changes.

## Behaviour change worth knowing

`is_converged` is now **stricter** than `fit.converged`. A fit that previously
reported `true` at a degenerate optimum now reports `false`. That is the intent —
such a fit was never usable — but it is a visible change. `fit.converged` still
exposes the raw optimiser flag.

## Still open

**#460** — profile and bootstrap CIs remain unreachable through `engine = "julia"`
for ordinary fixed effects. Both engines implement them and they agree natively
(profile to 1.2e-06), so this is bridge routing in `confint.drmTMB_julia()`, which
lives in drmTMB and is blocked by CRAN prepare-only quiesce.
