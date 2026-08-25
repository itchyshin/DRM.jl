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

### Closest to promotable — but only one is actually ready

| Row | now | → | Evidence | What is still missing |
|---|---|---|---|---|
| `plain_binomial_nonphylo` | partial | **covered** | Live Workflow G binomial-trials cell vs DRM.jl `expected.toml`; logLik agreement **2.48e-13** (`docs/dev-log/evidence/parity-fixtures.tsv:7`) | Its boundary says "still experimental, not a CRAN default" — that clause is about drmTMB's *release posture*, not about evidence. Reword rather than block. |
| `biv_gaussian_residual` | partial | **not yet — materially closer** | **Measured 2026-08-24**, name-matched, live `engine="tmb"` vs `engine="julia"`, **7/7 coefficients**: coef max abs diff **9.861e-07**; SE **9.176e-08** abs / **1.835e-06** rel, independently cross-confirmed by `tools/parity_se.R` on the same draw; logLik **1.307e-11**. First fixture stamped with a real comparator build (`drmtmb_built` + `drmtmb_code_hash`, #473). | A **single** fixed-effects draw (n=400, one seed); **no** interval/diagnostic evidence; **no** public documentation pointing at the cell. Those are two of design/168's four limbs. |

> **Correction to this document, made by the measurement it commissioned.** This row originally claimed
> the blocker was that coefficients were not name-matched, needing the `:`→`_` normalisation ported from
> `tools/parity_se.R`. Measured: `fixef()`-derived coefficient names **already agreed** between engines
> (both use `.`); the `:`→`_` mismatch is real but lives in **`vcov()`'s dimnames** — the SE axis, not the
> coefficient axis. The normalisation was ported and applied to both defensively. The diagnosis here was
> wrong and the measurement corrected it, which is the point of measuring.

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
| `general_covariance_structured` | experimental | **CORRECTION + measurement, 2026-08-24.** This document said *"one family has been measured"*. Wrong — Poisson/NB2/Gamma coef+logLik evidence already existed (`ee8658df`). What was genuinely missing was the **SE axis**, now measured: Poisson **4.65e-03** rel, NB2 **6.79e-03**, Gamma **4.08e-02** (Gaussian 3.38e-07 for scale). The pre-existing coef/logLik numbers also **reproduced byte-for-byte**, which is a reproducibility check passing against the same installed build (#473). **Still NOT promotable** — one seed/fixture per family, and the row's boundary additionally gates `beta`, precision `Q`, and `sigma` predictors, none of which was touched. Beta has `NO_NATIVE_COMPARATOR` (drmTMB refuses `relmat` on plain `beta()`), though beta is not among the four families the row claims. |
| `gaussian_phylo_mean` | partial | Its defining parameter — the phylogenetic SD — is **in no comparison at all**. Regenerate the fixture carrying it before anything else. |

---

## Honest summary

- **1 row could move on evidence that exists** (`plain_binomial_nonphylo`). A second
  (`biv_gaussian_residual`) gained strong name-matched parity tonight but is still short of `covered`
  on two of the bar's four limbs — the harness work closed the gap it was said to have, and revealed
  the gap it actually had.
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

---

## Addendum, 2026-08-25 — four verdicts above were overturned by later measurement

This document is a **dated snapshot of what I believed on 2026-08-24**, and it is left intact
above rather than rewritten, because the record of what was believed when is the part that has
evidential value. Four of its per-row verdicts did not survive the night. Three failed the same
way — I read a *disclaimer* as a *requirement*, or a *symptom* as a *cause*.

| row | the verdict above | what actually happened | class of error |
|---|---|---|---|
| `biv_q4_phylo_reml` | "needs a converged fixture… → **#478**" | Promoted to **covered**. The fixture was re-derived on a converged fit; #478 turned out to state a *limitation* ("does not establish"), not a gate. | **read a limitation as a gate** |
| `cross_family_latent` | "promotion criterion is **unsatisfiable by construction**… parity evidence can never exist" | **Retracted.** Re-reading the boundary: it never demands native parity. It says "development route" and constrains what public docs may claim. Narrow, not unsatisfiable. | **read a disclaimer as a requirement** |
| `gaussian_response_mask` | "**no working path at all** for that cell. **Do not promote**" | Half wrong within hours: **#482 fixed the default `drop` path**, and my stated cause was wrong too — it was positional species-to-leaf mapping, not a missing tree re-prune. Still held at `partial`, but for a *different and better* reason: `include` remains refused, which is a hole in the named capability. | **plausible cause instead of the measured one** |
| `phylo_count_large_p` | "native TMB's dense phylo factorisation is **O(p³)**" | **Retracted (#486).** Measured **O(p^1.27)** to p=3000. The premise the whole slice was built on was false, and only running it revealed that. | **asserted a complexity I had not measured** |

The one verdict that held up unchanged is `gaussian_phylo_mean` — "its defining parameter is in no
comparison at all" was correct, the fixture was regenerated to carry the phylogenetic SD, and the
row is now `covered`.

**What generalises.** Every error in this table was a *reading* error, not a computation error, and
each one made the work look **more** blocked than it was: three rows were declared unmovable and two
of them moved. A pessimistic misreading is not the safe direction — it silently cancels work that
was ready. The counter-practice that caught all four was the same one that produced the original
findings: **running the thing** — the converged refit, the p=3000 fit, the 42/42 mask test — rather
than reasoning about what it would do.
