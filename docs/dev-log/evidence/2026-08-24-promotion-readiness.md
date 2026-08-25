# Capability-row promotion readiness — 2026-08-24

**Purpose.** The G0 is *"catch up with drmTMB"*, whose measurable form is moving capability rows on
measured evidence. This maps each of the 11 rows to the evidence that exists **tonight**, so promotion
becomes a reviewable decision rather than an aspiration.

**Nothing here promotes anything.** Every status change is a `drmTMB inst/extdata/julia-capabilities.tsv`
edit — a shipped file in the other repo — and therefore the maintainer's call. This document is the
input to that call.

---

## Three facts that bound every row below

**1. `supported` is not a status.** The governing vocabulary (drmTMB `docs/design/168`) is
`covered > partial > experimental > planned > unsupported`. Promotion means
**`experimental → partial`** or **`partial → covered`**. Nothing can become `supported`, and the
countdown that said "11 unsupported rows" was `len(caps)` by construction until `d265d876`.

**2. `covered` has a four-part bar**, quoted: *"implementation, focused tests, public documentation, and
relevant diagnostic or interval evidence exist for the named row."* Note what it does **not** require:
interval *coverage*. It requires *relevant* interval evidence. That distinction decides several rows.

**3. Every banked number has an ambiguous comparator (#473).** All parity numbers labelled
`drmTMB 0.7.0` were measured against a build 16 shipped-file commits behind `origin/main`. This does not
make them wrong; it means **a promotion citing them should also cite
`tools/drmtmb_provenance.R --toml`**, or the evidence is not reproducible.

---

## Row-by-row

### Recommend promoting — evidence exists now

| Row | now | → | Evidence | Residual risk |
|---|---|---|---|---|
| `biv_gaussian_residual` | partial | **covered** | Live same-target evidence (#458); SE agreement ~1e-06; a canonical fixture cell at 0.7.0 | Needs the `:`→`_` label normalisation ported from `tools/parity_se.R` into `tools/parity_fixture.R` so coefficients are name-matched, not just logLik. **Hours, DRM.jl-side, no reinstall.** |
| `plain_binomial_nonphylo` | partial | **covered** | Live Workflow G binomial-trials cell vs DRM.jl `expected.toml`; agreement 2.48e-13 | Boundary says "still experimental, not a CRAN default" — that clause is about drmTMB's release posture, not about evidence. Reword rather than block. |

### Blocked on one specific, cheap thing

| Row | now | Blocker | Cost |
|---|---|---|---|
| `biv_q4_phylo_reml` | partial | **A non-converged fit, not an incoherent criterion.** The belief that the engines maximise different restricted likelihoods is **refuted** — both marginalise all four axes; the gap is `(n_β/2)·log(2π)` (predicted 5.5136 vs measured −5.63, residual 0.116 explained by `julia_converged = false`). Needs a converged same-target fixture, then `[tol]` re-derived. Boundary also demands bridge parity from a halted path + out-of-repo AI-REML → **#478**. | days |
| `phylo_gamma_beta_binomial` | experimental | Comparator arrived upstream (`d30841491`, 2026-08-17) and has never been run against. Requires **reinstalling drmTMB from `origin/main`** — which moves the comparator under *every* banked number at once (#473). Do it deliberately: record provenance, reinstall, re-run the full harness set. | hours + TMB compile |

### Blocked on a decision, not on work

| Row | now | The decision |
|---|---|---|
| `cross_family_latent` | experimental | Its promotion criterion is **unsatisfiable by construction**: drmTMB has no native cross-family route (accepts only `c(gaussian(), gaussian())`; the path is Julia-engine-only). Parity evidence can never exist. Must be judged on simulation recovery instead → **#478**. |
| `engine_control_surface` | unsupported | **Leave it.** Deliberately rejected pending a real R API design. A ledger that only ever promotes is a publication-bias engine; the honest "leave it" entries carry as much weight as the promotions. |

### Boundary is wrong — fix the text before considering status

| Row | now | Finding |
|---|---|---|
| `gaussian_response_mask` | partial | **Measured tonight (#482): the boundary over-claims.** It reads "Gaussian-only response masks", which a reader takes as "Gaussian response masks work". They work for **non-phylo Gaussian only** — mean-phylo fails on the opt-in `include` *and* on the **default** `drop` (37 species vs 40 leaves). There is no working path at all for that cell. **Do not promote; correct the text.** |

### Needs measurement that has not been run

| Row | now | What is missing |
|---|---|---|
| `base_gaussian_location_scale` | partial | Evidence is otherwise complete, but its live Route-C parity is **skip-guarded** — it can pass by never running. De-optionalise it. Also #460's `fixef:` targets (now fixed, drmTMB#1080 open). |
| `phylo_count_large_p` | experimental | `tools/parity_classc.R` already takes `p`. Add p=1000, then 3000. **D-139 applies** — native TMB's dense phylo factorisation is O(p³); pre-run p=1000 and estimate before committing p=3000. If TMB cannot finish, *that is the result*, and the row's reach must be worded DRM.jl-only, not parity. |
| `general_covariance_structured` | experimental | Claims four families (Gaussian, Poisson, NB2, Gamma); **one** has been measured. Also its only same-target parity lives in a skip-guarded drmTMB test, so it is not a standing gate. |
| `gaussian_phylo_mean` | partial | Its defining parameter — the phylogenetic SD — is **in no comparison at all**. Regenerate the fixture carrying it before anything else. |

---

## Honest summary

- **2 rows could move on evidence that exists**, one of them after a few hours of harness work.
- **1 row is much closer than believed** (`biv_q4_phylo_reml`) because a fixture note's structural
  explanation was wrong.
- **1 row must not move and its text must be corrected** (`gaussian_response_mask`, #482).
- **2 rows need a maintainer decision, not work** (#478).
- **1 row should stay where it is, permanently** (`engine_control_surface`).
- **The remaining 4 need measurements nobody has run**, none of which is blocked by compute.

**Nothing here is blocked by lack of compute.** The interval-coverage campaign (#468, awaiting go/no-go)
is *not* a prerequisite for any promotion listed above — `covered` asks for *relevant interval evidence*,
not calibrated coverage. Coverage is what would let the two
`interval_status != "coverage_claimed"` fences come down, which is a different and larger claim.
