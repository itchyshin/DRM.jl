# Rose claim fence — future Arc 1 (11 unsigned ledger rows)

**Role:** Rose (pre-publish gate). **Read-only.** No `src/` edits. No commit.
**When:** 2026-08-16. **For:** a *future* Arc 1 ultra-plan, after Arc 0 `@ref` is done.
**Verdict on this note:** **clean-with-limitations** — a fence, not a ship. Limitation: it binds
prose and PR shape; it does not inventory which of the 11 rows are missing cells vs
drmTMB-side claim decisions. That inventory is Arc 1's first slice.

**Scoreboard A (binding for Arc 1):** Hopper remasure
`docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md` — drmTMB 0.7.0
`origin/main` `9e42d2c94`; DRM.jl export set as on `origin/main` (154).
**Scoreboard B (do not merge into A):** `docs/design/capability-status.md` on DRM.jl
`origin/main` — Julia code+test census (Mission Control julia-surface chips).

---

## 1. What "11 unsupported" means

The ledger phrase **"11 unsupported capability rows"** means
`claim_status != "supported"` (script: `sum(… != 'supported')`). It is **not**
11 rows with status `unsupported`.

| Split (measured 2026-08-16) | Count | IDs |
|---|---|---|
| `partial` | 6 | `base_gaussian_location_scale`, `biv_gaussian_residual`, `gaussian_phylo_mean`, `gaussian_response_mask`, `biv_q4_phylo_reml`, `plain_binomial_nonphylo` |
| `experimental` | 4 | `phylo_count_large_p`, `phylo_gamma_beta_binomial`, `general_covariance_structured`, `cross_family_latent` |
| `unsupported` | 1 | `engine_control_surface` (design fence — needs an R API first; not a port) |
| `supported` | **0** | — |

CLOSURE PASS on the ledger means every row is `supported` **or** carries a written
`claim_boundary`. It does **not** mean any cell is a public twin claim.

**COUNTDOWN 0** is an **export-name** countdown (18 raw / 18 accounted). It is not
capability readiness and not D-111 readiness condition (1).

---

## 2. Allowed public claims (Arc 1 may say these)

Phrase the campaign, README, HANDOVER, Documenter, PR titles, and Mission Control
**only** in this vocabulary:

1. **"Export-gap countdown at 0; 11 capability rows still unsigned."** Cite the
   remasure date and drmTMB ref. Do not drop the second clause.
2. **"No ledger row is `supported`."** Zero of eleven. Promoting any row is a
   **drmTMB TSV / claim decision**, not a DRM.jl export.
3. **Per-row `claim_boundary` as already written** in
   `inst/extdata/julia-capabilities.tsv` (read via `git show <ref>:…`). Quote; do
   not tighten or loosen the sentence in Julia docs.
4. **"This PR adds a native-vs-Julia same-target fixture for `<capability_id>`
   within the row's declared tolerance."** Allowed only when the artefact exists
   (matching coefficients and logLik). That is **cell evidence**, not a TSV flip.
5. **"Direct DRM.jl evidence is not R-via-Julia bridge support."** Repeat when a
   Julia unit test is green and someone wants to call the bridge admitted.
6. **"Export-name presence is not capability parity."** Repeat when a symbol
   exists on both sides.
7. **Status tags on Documenter pages** stay honest: Stable / First slice /
   Opt-in control / Planned / Blocked / Experimental. Reader pages stay
   Experimental until the inventory says otherwise.
8. **License:** DRM.jl is MIT; parity uses generated drmTMB *outputs* only.

---

## 3. Forbidden public claims (Rose blocks the PR)

Do **not** write, imply, or title:

| Forbidden | Why |
|---|---|
| "R–Julia parity complete" / "caught up" / "D-111 ready" | COUNTDOWN 0 ≠ D-111 bar (1). Registration is **OFF**. |
| "`engine = \"julia\"` admits whatever drmTMB fits" | The 11 rows are the shared surface that still is not a public twin claim. |
| Any row flipped to `supported` from this tree | drmTMB claim. STOP GATE: do not merge drmTMB `#1049` / `#1050` from a DRM.jl lane. |
| "11 missing Julia engines / ports" | Six are already Phase 1.5 admitted cells; one is unsupported *by design*. |
| An invented twin **Δ** | If drmTMB did not ship the cell, a Julia-only "Δ" is forbidden, not owed. Do not invent drmTMB support. |
| "Catch up to GLLVM" / "become GLLVM" / copy VA-GH, ordination, fourth-corner, LV modes | **D-94:** DRM.jl is sequenced behind **drmTMB**, not GLLVM.jl. Different twin, different estimand. |
| Extrapolated speed/accuracy (e.g. drmTMB at p=10,000) | Verify-before-claim. Measured only. |
| GPL vendoring of drmTMB source | MIT boundary. Generated outputs only. |
| "VA is implemented" / closing or resolving **#136** | VA is a stub. `#136` stays **OPEN**. |
| Unparking **#49** / documenting `impute` / `mi()` as a fitted route | **#49 PARKED** — owner-named only. |
| JuliaRegistrator / General / "ready to register" | **D-111 OFF.** Do not chase Registrator. |
| Flipping Scoreboard B orange → green without a new guard + test | That is a claim lie on the Julia census. |

---

## 4. Two scoreboards — do not conflate (orange chips)

**A = drmTMB bridge claim vocabulary** (`julia-capabilities.tsv` / parity ledger).
**B = DRM.jl code+test census** (`docs/design/capability-status.md`).
Mission Control julia-surface chips parse **only** B's `Capability | Status` tables
(green = implemented · orange = rejected · blue = planned · grey = missing).

Arc 1 owns **A**. Arc 1′ (if ever opened) would be B's rejected/planned/missing
rows. **They are not one campaign.**

### Orange on B — rejected, not missing ports

| Chip | Status on B | Relation to Arc 1 |
|---|---|---|
| **REML with ordinary random effects** (Gaussian mean) | **rejected** — `ArgumentError` in `src/gaussian_core.jl`: `method = :REML` only for gated FE / q4 paths | **Not an Arc 1 row.** Do not plan a REML-RE port. Do not treat the orange chip as a ledger gap. |
| **Natural-gradient EM** (`algorithm = :natgrad`) | **rejected** — #13 decision gate FAIL (2026-08-01): `fit_em_natgrad` stalls at logLik ≈ −259.80 vs sparse-TMB −256.51 | **Not a public solver.** Do not invent `:natgrad` on the bridge. Not an Arc 1 row. |

**Easy misread:** REML (Gaussian FE location-scale) and REML bivariate phylogenetic
q4 are **implemented** on B. If a UI shows those as orange, treat UI-vs-file as
UNVERIFIED; **do not plan a REML-FE port.** Ledger row `biv_q4_phylo_reml` is
`partial` because of **missing same-target bridge parity**, not because q4 REML
code is absent.

### Blue / #136 — planned stub

| Chip | Status on B | Fence |
|---|---|---|
| **Variational (VA/ELBO)** | **planned** — `src/variational.jl` exists; `_fit_va` errors and points at **#136** | **#136 stays OPEN.** Never `close` / `fix` / `resolve` near that number. Do not `@docs` `Laplace` / `Variational` as a working estimator. Tests cover method-selection plumbing only. |

VA on GLLVM.jl / gllvmTMB VA-GH is the **wrong twin**. Copying it would change the
product (D-94).

### Grey on B — not Arc 1 unless the inventory says so

| Chip | Fence |
|---|---|
| AGHQ | Real missing estimator; not a ledger row; not catch-up OWED. |
| Cross-family bivariate | Live work is **#428 A11** — do not steal. Ledger `cross_family_latent` is `experimental`. |
| Missing-response / `mi()` | **#49 PARKED.** |

---

## 5. How Arc 1 may proceed (shape, not inventory)

1. **Inventory first** (claim_boundary vs missing cell vs drmTMB-side claim).
   Guessing the 11 as "port these engines" is how a wrong plan runs for hours.
2. **One issue → one branch → one PR → merge.** Do not bundle unsigned rows.
   Do not mix a ledger fixture with a Scoreboard B chip flip.
3. **Promote a *cell* only** on a native-vs-Julia same-target comparison
   (coefficients + logLik within the row's declared tolerance). That still does
   **not** flip TSV `claim_status` to `supported` from this repo.
4. **`engine_control_surface`:** leave `unsupported`. No user-selectable Julia
   optimizer API until an R design exists.
5. **`bf()` / `drm_formula()` touch:** `DRM_PARITY_TESTS=1` on the PR. Workflow G
   fixtures still record **drmTMB 0.6.0**; campaign anchor is **0.7.0** — say the
   split; do not silently re-anchor.
6. **Never regress** the verified q=4 core (2.18×, logLik −256.51).
7. **Never** vendor drmTMB GPL source.

---

## 6. Standing locks (copy into the future ultra-plan DEFER)

- **#136 OPEN** — VA Experimental; no close/fix/resolve.
- **#49 PARKED** — missing-data / bridge `impute` payload; owner-named only.
- **D-111 OFF** — no Julia General / Registrator.
- **D-94** — behind **drmTMB**, not GLLVM.jl. No invented twin Δ. No "become GLLVM."
- License boundary (Rose, every tag): MIT here; generated outputs only.
- Do not start Arc 1 in the same `/goal` as Arc 0.

---

## 7. Rose would block (checklist for the future G0)

- [ ] Any title or README line that says parity is complete.
- [ ] One PR that "clears the 11 rows."
- [ ] A TSV `supported` flip authored on the DRM.jl side.
- [ ] A Julia-only cell sold as drmTMB parity (invented Δ).
- [ ] An orange-chip "fix" (ordinary-RE REML, `:natgrad`) or a `#136` close.
- [ ] A GLLVM-shaped G0 (VA-GH, family-count race, LV / ordination).
- [ ] Registrator / General language (D-111).
- [ ] Unparking #49 in passing.

**What Rose will accept later:** one-issue PRs that add a same-target fixture
and leave `claim_status` untouched; inventory prose that quotes existing
`claim_boundary` text; the sentence *export-gap countdown at 0; 11 rows still
unsigned*.

---

## Sources (do not re-derive)

- Hopper remasure: `docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md`
- Ada two-scoreboard plan: `docs/dev-log/after-task/2026-08-16-ultra-plan-next-arc.md`
- Pólya transferable three: `docs/dev-log/after-task/2026-08-16-polya-gllvm-lessons.md`
- Catch-up `LOOP/GOAL.md` (invariants + promote-only-on-same-target)
- [[DECISIONS#D-94]] · [[DECISIONS#D-111]]
