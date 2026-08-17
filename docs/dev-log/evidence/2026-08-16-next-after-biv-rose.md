# Rose claim fence — NEXT arc after #434 (`biv_q4_phylo_reml` fixture)

**Role:** Rose (pre-publish / claim-vs-evidence). **Read-only.** No `src/` · no TSV
edit · no GPL vendoring · no commit.
**When:** 2026-08-16. **For:** the arc *after* merged PR **#434**
(`b73d9241`, 2026-08-17T00:39:07Z).
**Personas named:** Rose. **No spawned subagents.**
**Campaign G0 (unchanged):** 2026-08-14 admit-what-R-fits.
**Owner lock (this invocation):** `claim_status` stays **`partial`**; the logLik
gap is a **declared `[tol]`** (TMB mean-only REML vs Julia mean+scale); do
**not** flip TSV to `supported`. Skip `#428`. `#49` PARKED. `#136` OPEN.
D-111 OFF.

**Verdict on this note:** **clean-with-limitations** — a fence, not a ship.
**Next-arc pick:** **docs-only backlog refresh**, not a forced implement row.
Limitation: this pass did **not** re-run `parity_ledger.py` or `Pkg.test`.
Live ledger counts below are **UNVERIFIED** against a fresh script run; they
are cited from `git show` / already-landed notes.

Two scoreboards stay separate. **A** = drmTMB `julia-capabilities.tsv` (bridge
claim). **B** = DRM.jl `docs/design/capability-status.md` (code+test census).
#434 owned a **cell on A**. It did not flip A, and it did not own orange chips
on B.

---

## 0. What #434 actually landed (`origin/main` `b73d9241`)

PR title (allowed sentence, held): *Add native-vs-Julia same-target fixture
for `biv_q4_phylo_reml`*. Merge commit: `b73d924158338b5733134414ded1d42cd6469f93`.
Closes **#433**. Tip of `origin/main` at this audit: `b73d9241` (this pass;
`git log origin/main --oneline -15`).

| Artefact | Path on `origin/main` | What it is allowed to mean |
|---|---|---|
| Fixture | `test/parity/q4-reml/biv-q4-phylo-reml/{data.csv,tree.newick,expected.toml,expected.meta.toml}` | Same-data native TMB vs Julia `drm(method=:REML)` cell, **outside** the Workflow G `fixtures/` glob |
| Generator | `test/parity/gen_biv_q4_phylo_reml.R` | Generated outputs only; does not edit `gen_fixtures.R` |
| Test | `test/test_parity_biv_q4_phylo_reml.jl` | Standalone; **not** wired into `test/runtests.jl` |
| After-task | `docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md` | Measured numbers + restriction note |
| Check-log | `docs/dev-log/check-log.d/2026-08-16-biv-q4-phylo-reml-fixture.md` | 33/33; `[tol]` = measured gap |
| In-PR S5 | `docs/dev-log/evidence/2026-08-16-biv-q4-s5-rose-fence.md` | PR-language fence written **before** S1–S4 numbers existed |
| Plan-vs-actual | `docs/dev-log/plan-actual/2026-08-16-biv-q4-phylo-reml-fixture.md` | Melissa-shaped honesty: `[tol]` widened from 1e-3 to the measured gap |
| Recon / schema | `docs/dev-log/evidence/2026-08-16-biv-q4-phylo-reml-{recon,schema}.md` | Design only |

**Measured cell (cite; do not round into a twin Δ):**

- Native TMB: `logLik = −219.6139863046289`, `converged=true`, `pdHess=true`,
  `interval_status=wald_unavailable`, n=128, seed `20260822`, n_tip=16,
  n_each=8, drmTMB **0.7.0** (`expected.toml` / `expected.meta.toml`).
- Julia re-fit (after-task S4 log): `loglik=−225.24313853493464`,
  `dloglik≈−5.63`, `max |d_coef| ≈ 0.032`, `julia_converged=false`.
- Declared `[tol]`: `atol_loglik=6.0`, `atol_coef=0.05`, `rtol_coef=0.05`.
- Restriction note (fixture `[status].reml_restriction_note` and after-task):
  native TMB REML restricts **mean** fixed effects; DRM.jl `reml_q4` profiles
  **mean and scale**. logLik is **not** a 1e-3 Workflow G twin.

**What #434 did not land:** `src/` diff; `test/runtests.jl`; Workflow G harness
edits; TSV `claim_status` flip; `capability-status.md` flip; R-via-Julia
bridge rewrite of `test/test_bridge_q4_direct_export.jl`; interval coverage;
AI-REML; Totoro recovery-grade (p≳200).

**Stale inventory (why a docs refresh is owed):**
`origin/main:docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md` (from
#432) still ranks `biv_q4_phylo_reml` as **NONE** same-target and as the
recommended first later implement. That sentence is **false after `b73d9241`**.
The TSV row is still `partial` (`git show` drmTMB `origin/main`
`inst/extdata/julia-capabilities.tsv` @ `d9fddfa28`).

---

## 1. Allowed vs forbidden public sentences

Phrase README, HANDOVER, Documenter, PR titles, Mission Control, and the next
ultra-plan **only** in this vocabulary. Quote `claim_boundary`; do not tighten
or loosen it.

### Allowed (the next arc may say)

1. *"PR #434 added a native-vs-Julia same-target fixture for
   `biv_q4_phylo_reml` within the row's declared tolerance."* Cell evidence.
   Not a TSV flip. Not "parity complete."
2. *"`claim_status` stays `partial`; `r_bridge_status` stays `experimental`."*
   Owner lock. TSV @ `d9fddfa28` still reads those two fields.
3. *"Export-gap countdown at 0; 11 capability rows still unsigned."* Do not
   drop the second clause. COUNTDOWN 0 is export-name honesty (Hopper remasure
   2026-08-16). **UNVERIFIED** as a re-run after `b73d9241` — #434 did not
   change the TSV or the export set.
4. *"The logLik gap is a declared `[tol]` (TMB mean-only REML vs Julia
   mean+scale), not a 1e-3 Workflow G twin."* Cite `atol_loglik = 6.0` and
   `d_loglik ≈ −5.63`. Do not invent a smaller Δ.
5. *"Direct DRM.jl evidence is not R-via-Julia bridge support."*
   `test/test_bridge_q4_direct_export.jl` still asserts
   `"no R-via-Julia q4 bridge parity"` — leave that sentence true.
6. *"Workflow G metas remain drmTMB 0.6.0 / ML / no tree; this cell is 0.7.0
   REML + tree, outside `test/parity/fixtures/`."* Say the split; do not
   silently re-anchor.
7. Bank **fit-specific CI/status** as recorded fields (`converged`, `pdHess`,
   `interval_status=wald_unavailable`, `julia_converged=false`). Not coverage.
   Not reliability.
8. License: DRM.jl is MIT; parity uses generated drmTMB *outputs* only.

### Forbidden (Rose blocks the PR / README line)

| Forbidden sentence | Why |
|---|---|
| "R–Julia parity complete" / "caught up" / "D-111 ready" | COUNTDOWN 0 ≠ D-111 bar (1). Registration is **OFF**. Eleven rows still unsigned. |
| "`biv_q4_phylo_reml` is `supported`" / TSV flip from this tree | Owner lock + STOP GATE. Fixture ≠ ledger. |
| "q4 REML is a 1e-3 twin" / invented tighter Δ | Measured `d_loglik ≈ −5.63`; `[tol].atol_loglik = 6.0`. Promoting a Workflow G-style twin is a claim lie. |
| "interval reliability" / "coverage" / "AI-REML" / "HSquared" as this twin | `claim_boundary` already forbids them. `interval_status=wald_unavailable`. |
| "`engine = \"julia\"` admits this cell" / "bridge-admitted" | Direct `drm()` ≠ R-via-Julia. Do not rewrite the bridge-export refusal. |
| "Julia q4 REML converged" as a public win | Fixture records `julia_converged=false`. Status is recorded, not sold. |
| Any invented twin **Δ** (binomial+`phylo`, beta+`relmat`, sigma-phylo, …) | D-94: behind **drmTMB**, not an invented surface. If R did not ship the cell, Julia-only is not owed. |
| Close / fix / resolve **#136** · unpark **#49** · steal **#428** | Standing locks. `#136` re-checked **OPEN**. `#49` GitHub state is OPEN; campaign lock is **PARKED** — do not unpark. |
| Registrator / General / "ready to register" | **D-111 OFF.** |
| GPL vendoring of drmTMB source | MIT boundary. Generated outputs only. |
| Flip Scoreboard B orange → green without a new guard + test | Ordinary-RE REML and `:natgrad` stay **rejected**. Not this campaign. |

Parent fence (still binding): `docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md`
(#432). In-PR S5 (`2026-08-16-biv-q4-s5-rose-fence.md`) bound **#434 language**;
this file binds the **next** arc. Do not treat the pre-number S5 limitation
("does not certify coef/logLik") as still true — the after-task +
`expected.toml` now certify the measured gap.

---

## 2. If Ada picks one of these four — illegal claims if sloppy

None of these is a remaining **fixture-gap** implement. Inventory class and
Hopper twin-map are from #432 (`2026-08-16-arc1-ordered-backlog.md`,
`2026-08-16-arc1-batch-experimental.md`, `2026-08-16-arc1-recon-s3.md`,
`2026-08-16-arc1-hopper-twin-map.md`). TSV fields quoted from drmTMB
`origin/main` @ `d9fddfa28`.

### 2a. `phylo_gamma_beta_binomial` (`experimental` · smoke-only / TSV-claim)

| If sloppy, the PR would illegally claim… | Evidence that forbids it |
|---|---|
| "Non-Gaussian phylo parity is complete" / flip `experimental` → `supported` | TSV `claim_boundary`: *Finite-and-sane bridge smoke evidence only; no native TMB parity or non-phylo binomial bridge promotion.* Promotion is a drmTMB claim. |
| "Add the missing comparator" as new owed work | A5 comparator **already exists** (`parity-phylo-nongaussian.tsv`): gamma **PARITY_FAIL** (ll \|d\| 1.016e-04 vs tol 1e-4); beta **PARITY_PASS**; binomial **NO_NATIVE_COMPARATOR**. S3: `next_action` is **evidence-complete**. Do not re-open "add comparator." |
| A public **binomial + `phylo()`** twin / "we caught drmTMB #1048" | Hopper twin-map: Gamma/beta **YES**; public fitted `binomial()` + `phylo()` **NO**. Inventing that Δ is D-94. drmTMB **#1049** is still **OPEN** (this pass: `gh pr view 1049` → `state=OPEN`, `mergedAt=null`) — do not merge it from a DRM.jl lane to manufacture the twin. |
| Tightening gamma's hair-fail into a PASS | A5 left the 1e-4 tol unloosened. Loosening to "pass" is a claim edit, not a port. |

### 2b. `phylo_count_large_p` (`experimental` · smoke-only)

| If sloppy, the PR would illegally claim… | Evidence that forbids it |
|---|---|
| "Large-p phylo count is `supported`" / coverage twin | TSV `next_action`: *Keep phylo count smoke + Workflow G FE parity tests; do not promote beyond experimental.* Capability-and-limits: structured count `mu` is **recovery-only**, not a coverage twin. |
| "Missing family — port Poisson/NB2 phylo" | Smoke already exists (`test/test_poisson_phylo_laplace.jl`, `test/test_nb2_phylo_laplace.jl`). Workflow G FE cells (`count-poisson`, `count-nbinom2`) are **not** phylo. Large-p is the *route* (sparse O(p)), not a missing family. |
| A Workflow G-style 1e-3 same-target at large p | S3: **NONE** committed same-target phylo-count `expected.toml`. Live drmTMB skip-guarded Poisson phylo at **n_tip=24**, tol **1e-2**, is moderate tree, **not** large-p. Do not promote that smoke to "large-p parity." |
| Extrapolated drmTMB-at-p=10,000 speed/accuracy | Verify-before-claim. Measured only. |

### 2c. `general_covariance_structured` (`experimental` · smoke-only / TSV-claim)

| If sloppy, the PR would illegally claim… | Evidence that forbids it |
|---|---|
| "relmat parity complete" / flip to `supported` | TSV `claim_boundary`: *Requires covariance/relatedness matrix `K` and `sigma ~ 1`; beta, precision `Q`, and sigma predictors stay gated.* |
| "Add the missing family-vs-gate compare" as new owed work | A9 audit **already exists** (`2026-08-16-a9-general-covariance-audit.md`). TSV `next_action` is **done**. Do not re-open "compare families vs R gate." |
| A **beta + `relmat`** twin Δ | A9: DRM.jl beta+`relmat` **fits**; drmTMB 0.7.0 **refuses**. Selling the Julia-only fit as parity is an invented Δ (D-94). |
| Widening to `Q=` / `sigma ~ x` / binomial `relmat` | Neighbours stay gated. Widening is a claim, not a port. **NONE** Workflow G `relmat` `expected.toml`. |

### 2d. Docs-only (backlog / fence refresh — **Rose's pick**)

| If sloppy, the docs PR would illegally claim… | How to stay honest |
|---|---|
| "Inventory complete / 11 rows cleared / parity caught up" | Refresh **classifies**. It does not promote. Phrase remains *export-gap countdown at 0; 11 rows still unsigned.* |
| "Recommended next implement = `<row>`" without a new G0 | After #434 there is **no** remaining fixture-gap implement in the #432 ordered list. Do not mint a new "recommended implement" in a docs PR. |
| Silent rewrite of `claim_boundary` text | Quote TSV sentences. Do not tighten or loosen. |
| Treating #434 as making `biv_q4` `supported` | Update the stale **NONE** fixture line to "fixture banked; `[tol]` = measured mean-vs-mean+scale gap; `claim_status` still `partial`." That is a fact fix, not a promotion. |
| Wiring `test/test_parity_biv_q4_phylo_reml.jl` into `runtests.jl` under a "docs" title | That is a **#434 follow-up**, collision-blocked by `#423` + `#425` + `#428` (Ada advise `2026-08-16-next-arc-ada-advise.md`). Not this docs slice. |

---

## 3. Sweep-receipt standard (still binding)

A next-arc ultra-plan / PR is **blocked** if the sweep receipt is vacuous
(lane_preflight not run; TSV not `git show`'d; sibling inventory not cited;
`gh pr` / issue locks not re-checked).

**TSV `claim_status` → `supported` remains a drmTMB STOP GATE.**

| Surface | This-pass evidence | Call |
|---|---|---|
| TSV row `biv_q4_phylo_reml` | `git show` drmTMB `origin/main:inst/extdata/julia-capabilities.tsv` @ **`d9fddfa28`**: `claim_status=partial`, `r_bridge_status=experimental`, `next_action` still "Bank fit-specific CI/status parity before release language." | Cite; **do not flip.** #434 banked the fixture; it did not author a TSV edit. |
| drmTMB **#1049** | `gh pr view 1049 --repo itchyshin/drmTMB` → **OPEN**, `mergedAt=null`. Title: binomial responses accept a phylogenetic random effect (#1048). | **STOP GATE held.** Do not merge from a DRM.jl lane. Merging it would manufacture a binomial+`phylo` twin the ledger does not admit. |
| drmTMB **#1050** | `gh pr view 1050 --repo itchyshin/drmTMB` → **MERGED** 2026-08-16T12:50:15Z (*Overnight: 31 location verdicts…*). | Merge does **not** lift the TSV-flip STOP GATE and does **not** authorize `supported` from DRM.jl. Older notes that still say "#1050 OPEN" are stale; do not treat the merge as "caught up." |
| `#136` | `gh issue view 136` → **OPEN** | Never `close` / `fix` / `resolve`. |
| `#49` | GitHub **OPEN**; campaign lock **PARKED** | Do not unpark. Owner-named only. |
| `#428` | Owned skip (`cross_family_latent`) | Do not steal. |
| D-111 | OFF (parent fence + owner lock) | No Registrator / General language. |
| License | MIT here; #434 generator note: "Generated outputs only; no drmTMB source vendored." | Hold. |
| Ledger script | **Not re-run this pass** | Mark COUNTDOWN 0 / "11 unsigned" as **UNVERIFIED** post-`b73d9241`. TSV text is verified via `git show`. |

Do **not** merge drmTMB `#1049` from this tree. Do **not** author
`julia-capabilities.tsv` on the DRM.jl side. Cell evidence ≠ ledger.

---

## 4. Verdict — forced implement row vs docs-only

**Docs-only backlog refresh is wiser.** Do not force an implement row.

Reasons (claim-vs-evidence, not taste):

1. **The only fixture-gap implement is shipped.** #432 ordered-backlog ord 1
   was `biv_q4_phylo_reml` because the engine existed and the same-target
   fixture did not. `b73d9241` banked that fixture. Ada advise
   `2026-08-16-next-arc-ada-advise.md` (0b15f5be): *after #434, no remaining
   fixture-gap row.* Rose agrees.
2. **The published inventory is now a claim hazard.** `origin/main` still
   says **NONE** same-target and still recommends that cell as the first later
   implement. A colleague who starts from #432 without this fence will
   re-plan a shipped slice or, worse, "finish" it by flipping TSV.
3. **Ords 2–4 are not implement-shaped.** `phylo_gamma_beta_binomial` /
   `phylo_count_large_p` / `general_covariance_structured` are smoke-only or
   TSV-claim; their `next_action`s are keep-smoke / evidence-complete /
   gate-compare-done. A forced G0 there is how sloppy sentences in §2 ship.
4. **The honest #434 follow-up is not a ledger row.** Including
   `test/test_parity_biv_q4_phylo_reml.jl` in `test/runtests.jl` waits on
   `#423` + `#425` + `#428` (all own that file). That is a collision wait,
   not a new capability implement, and not this docs refresh.
5. **Locks still hold.** Skip `#428`. `#49` PARKED. `#136` OPEN. D-111 OFF.
   No TSV `supported`. No invented Δ.

**What a docs-only refresh may do**

- Rewrite the #432 ordered table so ord 1 reads: fixture **banked** on
  `origin/main` (`test/parity/q4-reml/biv-q4-phylo-reml/`); `[tol]` = measured
  mean-vs-mean+scale gap; `claim_status` still **`partial`**.
- Drop "recommended first later implement = `biv_q4_phylo_reml`."
- Keep the phrase *export-gap countdown at 0; 11 rows still unsigned.*
- Quote, do not rewrite, the eleven `claim_boundary` sentences.
- Point at this fence + the #434 after-task for the `[tol]` honesty.

**What it may not do**

- Name a new "recommended implement" without a fresh G0 and a same-target
  gap that is actually missing.
- Flip any `claim_status`.
- Steal `#428`, unpark `#49`, close `#136`, or touch `src/`.

**Rose would accept later (not this pick):** one-issue PRs that add a
*new* same-target fixture for a row that still lacks one, leave
`claim_status` untouched, and use the allowed sentences in §1. After #434,
none of Ada's four named picks is that row.

---

## 5. Standing locks (copy into the next ultra-plan DEFER)

- TSV `supported` flip — drmTMB STOP GATE (`#1049` still OPEN; `#1050` merged
  does not authorize a flip from DRM.jl).
- `#136` OPEN — VA Experimental; no close/fix/resolve.
- `#49` PARKED — missing-data / `impute` / `mi()`; owner-named only.
- `#428` — owned skip; do not steal `cross_family_latent`.
- D-111 OFF — no Julia General / Registrator.
- D-94 — behind **drmTMB**, not GLLVM.jl. No invented twin Δ.
- License — MIT here; generated outputs only.
- Do not glob the q4 REML cell into `test/parity/fixtures/`.
- Do not treat `atol_loglik = 6.0` as a defect to "fix" in `src/`.

---

## Sources (do not re-derive)

- #434 merge: `git log origin/main --oneline -15`; `git show b73d9241 --stat`;
  `gh pr view 434` → MERGED, mergeCommit `b73d9241…`.
- Landed after-task / check-log / S5 / plan-actual / fixture / test: paths in §0
  via `git show origin/main:…`.
- Pre-#434 plan: `docs/dev-log/after-task/2026-08-16-ultra-plan-biv-q4-phylo-reml-fixture.md`.
- Parent fence + inventory: scratch / `origin/main`
  `docs/dev-log/evidence/2026-08-16-arc1-{rose-fence,ordered-backlog,batch-experimental,recon-s3,hopper-twin-map}.md`.
- Ada after-#434 advise: scratch
  `docs/dev-log/evidence/2026-08-16-next-arc-ada-advise.md` (0b15f5be).
- Hopper remasure (COUNTDOWN 0; **not re-run**): 
  `docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md`.
- TSV: `git show` drmTMB `origin/main:inst/extdata/julia-capabilities.tsv` @
  `d9fddfa28`.
- `#1049` OPEN / `#1050` MERGED: `gh pr view` this pass.
- `#136` OPEN / `#49` OPEN-on-GitHub + PARKED-in-campaign: `gh issue view` +
  owner lock.
- [[DECISIONS#D-94]] · [[DECISIONS#D-111]].

**UNVERIFIED this pass:** fresh `parity_ledger.py` countdown; `Pkg.test`;
whether `#423`/`#425`/`#428` still own `test/runtests.jl` at the moment a
follow-up include is filed (Ada advise said yes; not re-checked file-by-file
here).
