# Class-(c) cells: `phylo_count_large_p` and `general_covariance_structured`

Date: 2026-08-24 · lane: DRM.jl (Hopper, `parity/se-axis`) · anchor: installed drmTMB
0.7.0 / `origin/main`, DRM.jl at `parity/se-axis` (commits 201e90b0, 9a532e67) ·
seed 20260824 · tolerance 1e-4

Both rows are MEASUREMENT ONLY per `julia-capabilities.tsv`: the engine works on
both sides and only the number was missing. This closes that gap for the two
remaining reachable class-(c) rows. Script: `tools/parity_classc.R`. Raw
results: `docs/dev-log/evidence/parity-classc.tsv`.

## Method

Each cell fits the SAME target twice through `drmTMB()`: `engine = "tmb"` vs
`engine = "julia"`. No manual `JuliaCall` marshalling was needed — reading
`R/julia-bridge.R` confirmed `drmTMB(..., engine = "julia")` auto-detects a
`phylo(1 | group, tree = tree)` mean term (`drmTMB_julia_bridge` →
`drm_julia_has_phylo_term`) and a `relmat(1 | group, K = K)` mean term
(`drm_julia_has_structured_term` → `drmTMB_julia_structured_bridge`) and routes
both through the DRM.jl bridge automatically, exactly the way the smoke-tested
`plain_binomial_nonphylo` FE cells already do. Generating phylo/relmat SDs were
kept at 0.5, well away from DRM.jl's `_LAPLACE_LOG_SD_FLOOR = log(1e-6)`
(2026-08-24-sd-floor-asymmetry.md); the fitted structured SD from both engines
is recorded in the `note` column so a near-floor draw would read as
`BOUNDARY_NOT_COMPARABLE` rather than PARITY_PASS/FAIL. None hit that this run.

D-139 estimate: JuliaCall/DRM.jl startup ~1–2 min, 8 small-to-moderate fits ×2
engines — under 5 minutes total. Ran directly (smoke cell first, p=20, read
before scaling to p=300, per the instruction). Actual wall time was well under
the estimate; no pre-run-test gate applied.

## (a) `phylo_count_large_p` — Poisson / NB2, `phylo(1 | species, tree = tree)`

| cell | p | status | max\|Δcoef\| | \|Δlogℓ\| | fitted phylo SD (tmb / julia) |
|---|---|---|---|---|---|
| poisson_phylo_smoke_p20 | 20 | PARITY_PASS | 6.43e-08 | 2.90e-06 | 2.60e-05 / 3.21e-04 |
| poisson_phylo_p300 | 300 | PARITY_PASS | 3.82e-07 | 3.67e-09 | 4.781e-01 / 4.781e-01 |
| nb2_phylo_p300 | 300 | PARITY_PASS | 5.55e-07 | 1.68e-10 | 3.741e-01 / 3.741e-01 |

Generating SD was 0.5. At p=300 both engines recover it almost identically and
agree to 1e-7–1e-9 — a clean, non-boundary same-target comparison at a p an
order of magnitude larger than DRM.jl's own unit tests (p=32). The p=20 smoke
draw landed both engines at a small (non-floor) phylo SD estimate — a
near-degenerate but *interior* draw on both sides, not a boundary case — and
still passed at 1e-4 despite the SD point estimates themselves differing by an
order of magnitude (2.6e-5 vs 3.2e-4): coefficients and logLik are what the
tolerance gates, and a small variance component barely moves either.

## (b) `general_covariance_structured` — `relmat(1 | id, K = K)`, `sigma ~ 1`

Families tested: Gaussian, Poisson, NB2, Gamma — the four the
2026-08-16 A9 audit (`2026-08-16-a9-general-covariance-audit.md`) found FIT on
both engines. That audit compared DRM.jl's direct API against native TMB
directly; this measurement instead runs the same four families through the
`engine = "julia"` bridge, which is a stricter test (`drm_julia_structured_family_tag`)
because the bridge itself hard-gates relmat/animal/spatial structured terms to
exactly Gaussian/Poisson/NB2/Gamma — independent confirmation of the audit's
family list, from the bridge's own admission gate rather than DRM.jl's direct API.

| cell | status | max\|Δcoef\| | \|Δlogℓ\| | fitted relmat SD (tmb / julia) |
|---|---|---|---|---|
| gaussian_relmat | PARITY_PASS | 1.62e-08 | 1.37e-13 | 0.4146 / 0.4146 |
| poisson_relmat | PARITY_PASS | 2.06e-07 | 5.17e-12 | 0.2663 / 0.2855 |
| nb2_relmat | PARITY_PASS | 1.63e-06 | 1.59e-10 | 0.3192 / 0.3423 |
| gamma_relmat | PARITY_PASS | 2.97e-08 | 2.78e-11 | 0.4407 / 0.4726 |
| beta_relmat | NO_NATIVE_COMPARATOR | — | — | — |

All four pass at 1e-4, most by 3–9 orders of magnitude of headroom. The
relmat SD point estimates for poisson/nb2/gamma differ modestly between
engines (e.g. 0.266 vs 0.286) despite near-identical logLik — consistent with
a variance component that is well-identified in likelihood value but only
loosely identified in magnitude at n_id=12 groups; neither estimate is near
the 1e-6 floor, so this is ordinary optimizer-path variation, not the
boundary-asymmetry mechanism.

**`beta_relmat`**: `family = drmTMB::beta()` with `relmat(1 | id, K = K)` in
`mu`. drmTMB natively refuses it — reproducing the A9 audit's finding live on
the current installed 0.7.0 / `origin/main`:

> Structured-effect syntax is planned, not implemented.
> ✖ The `mu` formula contains structured marker: "relmat".
> ℹ Implemented structured paths cover the fitted Gaussian `phylo()`,
> `spatial()`, `animal()`, and `relmat()` slices, ... **zero-one-beta** q=1
> unlabelled intercept slices ... for `phylo()`, `animal()`, `relmat()`, and
> `phylo_interaction()` ...

The message's own "implemented" list names `relmat()` support for
**`zero_one_beta()`**, not plain `beta()` — so the refusal is specific to the
family, not to relmat as a provider. DRM.jl fits `beta() + relmat(1 | id, K = K)`
cleanly (per the A9 audit); this is DRM.jl admitting a model native drmTMB
does not, the same asymmetry the audit already banked. `engine = "julia"`'s
own refusal message on the Julia side (recorded verbatim in the TSV `note`
column) independently states the same family gate: "routes relmat()/animal()/
spatial() structured terms only for univariate Gaussian, Poisson, NB2, or
Gamma fits" — beta is excluded from the *bridge's* admitted set even though
DRM.jl's direct API fits it. So beta+relmat is DRM.jl-direct-only: neither the
native TMB route nor the `engine = "julia"` bridge reaches it today.

## What this does NOT establish

No coverage claim, no promotion. `phylo_count_large_p` and
`general_covariance_structured` stay `experimental` in drmTMB's own registry;
this banks the missing same-target measurement the rows' own `claim_boundary`
asked for. `beta_relmat`'s `NO_NATIVE_COMPARATOR` status is a finding about
drmTMB's and the bridge's admitted family set, not a DRM.jl defect and not a
parity failure.
