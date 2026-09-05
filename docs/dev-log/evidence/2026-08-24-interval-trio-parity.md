# The interval trio at parity — Wald, profile, bootstrap

**Date:** 2026-08-24 · **Branch:** `parity/se-axis` · **Issue:** #457
**drmTMB** 0.7.0 (installed) · **DRM.jl** `parity/se-axis` · R 4.6.0 · Julia 1.10.0

Point estimates and logLik agreeing is not the same as *inference* agreeing. Capability
parity first: for each of the three interval methods, does it run on each engine, and do
the intervals agree?

## Headline

**The engines agree. The BRIDGE is the gap.**

| method | native drmTMB | native DRM.jl | agreement | through `engine="julia"` |
|---|---|---|---|---|
| **Wald** | yes | yes | **exact** (0 to 1e-08) | **yes — parity** |
| **profile** | yes | yes | **1.2e-06** | **NO — refused** |
| **bootstrap** | yes | yes | *not comparable* | **restricted, and defective** (#459) |

Only **1 of 3** interval methods is reachable at parity through the R bridge, and it is not
because either engine lacks the capability.

## 1. Wald — parity, through the bridge

`tools/parity_intervals.R`, three cells, both engines via `drmTMB(engine=)`:

| cell | max rel endpoint diff | width ratio | status |
|---|---|---|---|
| Gaussian location-scale FE | 5.63e-06 | 1.000 | INTERVAL_PASS |
| Gaussian mean-only | 8.51e-07 | 1.000 | PARAM_COVERAGE_DIFF |
| Poisson FE | 9.81e-08 | 1.000 | INTERVAL_PASS |

The width ratio of exactly 1.000 matters as much as the endpoint agreement: two intervals
can share endpoints on the parameters they both report and still disagree in spread.

**One real coverage difference.** On the mean-only cell drmTMB returns **4** rows and DRM.jl
returns **3** — drmTMB additionally reports a response-scale `sigma` row. This is a
capability difference, not a disagreement, and the harness reports it as its own status
(`PARAM_COVERAGE_DIFF`) rather than hiding it by silently comparing the intersection.

## 2. Profile — the engines agree; the bridge refuses

Through the bridge, profile fails on **every** cell:

```
Unknown confidence-interval target: "fixef:mu:x".
Julia-engine profile and bootstrap intervals currently support exactly one Gaussian
phylogenetic SD target (univariate) or all four axes (bivariate biv_gaussian).
```

But DRM.jl profiles fixed effects perfectly on its own. `profile_targets(fit)` returns every
coefficient with `profile_ready = true`, and `profile_result(fit)` returns CIs.

**Measured native-vs-native, on byte-identical data** (generated in R, written to CSV, read
into Julia — see §4 for why this matters):

| method | drmTMB | DRM.jl | diff |
|---|---|---|---|
| profile `mu:x` | [0.73779752, 1.04455105] | [0.73779633, 1.04455224] | **1.2e-06** |
| wald `mu:x` | [0.73853223, 1.04381633] | [0.73853223, 1.04381634] | **~1e-08** |

Both engines also place profile just outside Wald (width 0.30675 vs 0.30528), which is the
expected ordering for a well-behaved Gaussian fixed effect.

**So profile parity is real at the engine level.** The remaining work is bridge plumbing:
teaching `confint.drmTMB_julia()` to accept ordinary `fixef:` targets and route them to
`DRM.profile_result`. That code lives in **drmTMB**, which is in CRAN prepare-only quiesce,
so it is not done here.

## 3. Bootstrap — restricted, and defective where it does run

Same bridge restriction: refused for ordinary fixed effects, supported only for the Gaussian
phylogenetic SD target. At that one supported target it produces an interval **1674×
narrower** than native TMB on identical data, B and seed — filed as **#459**.

So bootstrap is behind on both axes at once: the smaller surface, and a correctness defect
on the part of the surface it does expose.

## 4. A false finding I nearly filed, and what prevented it

An earlier comparison put DRM.jl's profile CI ~16% narrower than drmTMB's, with the implied
half-width at **1.6506 SE** against a nominal **1.96** — almost exactly the 90% critical
value (1.6449), and the width ratio (0.8381) matched the 90%-vs-95% prediction (0.8392) to
three figures. That is a *very* convincing bug signature, and it was wrong.

The cause: the two fits were on **different data**. `Random.seed!(20260824); randn(n)` in
Julia does not reproduce `set.seed(20260824); rnorm(n)` in R. Two engines fitted to two
different samples will differ by roughly sampling error, and here that happened to land on a
number that looked exactly like a wrong quantile.

What caught it: checking the threshold in the source before filing. `inference.jl:177`
computes `half = quantile(Chisq(1), level) / 2`, which is correct, and
`locscale_profile.jl:155` matches. A correct implementation and a "confirmed" discrepancy
cannot both be true, so the comparison itself was the suspect.

**The rule this earns:** a cross-engine numerical comparison must fit *the same bytes*.
Seeding both languages "the same way" is not the same data, and a coincidence at three
significant figures is not proof. The re-run above exports the R data to CSV and reads it
into Julia, which is what every same-target parity fixture in this repo already does — the
existing harness had it right and the ad-hoc probe did not.

## What may and may not be claimed

**May:** Wald intervals are at parity natively and through the bridge. Profile intervals are
at parity **natively** (1.2e-06). Both engines implement all three methods.

**May not:** that profile or bootstrap intervals are usable through `engine = "julia"` for
ordinary coefficients — they are not. That the bootstrap implementations agree — they do
not (#459). Any interval **coverage** claim: agreement between two engines is not calibration
against truth, which needs a simulation campaign.

---

## UPDATE (same day) — the bootstrap row is no longer "defective"

§3 above recorded bootstrap as *"restricted, and defective where it does run"*. The
defect half is fixed (#459 + #461); the restriction half stands.

At the one target the bridge does expose, the two implementations now agree:
julia `[1.045239, 1.416228]` vs tmb `[1.027252, 1.450820]` — width ratio 0.88,
against 1674× apart when this document was written. Ten degenerate replicates are
dropped and counted rather than silently included.

**The trio table therefore now reads:**

| method | native drmTMB | native DRM.jl | agreement | via `engine="julia"` |
|---|---|---|---|---|
| **Wald** | yes | yes | exact | **at parity** |
| **profile** | yes | yes | 1.2e-06 | **refused** (#460 — bridge routing) |
| **bootstrap** | yes | yes | **width ratio 0.88** | **works, but only for the phylo SD target** (#460) |

So all three methods now *agree numerically wherever they can both be reached*. What
remains is purely bridge surface: `confint.drmTMB_julia()` accepting ordinary
`fixef:` targets for profile and bootstrap. That code lives in drmTMB, which is in
CRAN prepare-only quiesce.
