# 2026-08-19 — q4 / `reml_q4.jl` / #49 parked scout

**Lane:** `q4-49-parked-scout` (Cursor / Shannon). Branch: `docs/q4-49-parked-scout`.
**This file is item 4 of the 2026-08-19 honesty sequence.** Items 1–3 done (AGHQ
chip stays `missing`; Cell D ADEMP is a **separate** G0; next lever scout =
[#452](https://github.com/itchyshin/DRM.jl/pull/452)). Item 5 waits.
**Read-only scout.** Do not implement `src/` from this file. Do not
`gh issue create`. Do not edit `src/reml_q4.jl`.

Cite: Patterson & Thompson (1971) REML; Nakagawa et al. (2025 MEE) q=4 PLSM.
Twin = **drmTMB**. No GLLVM Λ. **Flipping nothing.** Capability chips stay
**missing** (AGHQ row; missing-response / `mi()` rows). **No Cell D.**

---

## What this item is / is not

| This slice | Not this slice |
|---|---|
| Scout what q4, `reml_q4.jl`, and GitHub **#49** *are* | Implement `src/` |
| Record why AGHQ / Cox–Reid lanes fenced them | Reopen either as a G0 |
| Recommend **keep PARKED** vs reopen, with fences | `gh issue create` |
| Docs-only PR (like #452) | Flip `docs/design/capability-status.md` |
| | ADEMP / Totoro / Cell D, #420, #406, D-111, GPL vendoring |

**Verdict up front:** **keep PARKED.** Neither subject is trivially unblocked.
`reml_q4.jl` is already a verified public path. #49 is an OPEN GitHub idea whose
*process* status is PARKED; remaining work is a campaign, not a one-PR attach.

---

## What each is (one paragraph)

### q4

**q=4** is DRM.jl's reason for existing: the bivariate phylogenetic
location–scale model (PLSM; Nakagawa et al. 2025, Model 5). Responses
`(y1, y2)` share a phylogenetic random effect on four axes
`(μ1, μ2, log σ1, log σ2)` through a 4×4 among-species covariance `Λ`, plus a
residual correlation `ρ`. The public surface is
`bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)` with matching `phylo(1 | species)`
markers. The verified engine (`sparse_aug_plsm.jl` / `fit_q4_sparse_tmb.jl`) is
the complete-data Laplace ML path that HANDOVER quotes as **2.18× vs drmTMB**
on real `q4_p100` (logLik −256.51). This is **not** “unfinished q=4.” It is the
core Gaussian engine. AGHQ / Cox–Reid lanes named it only to **leave it alone**.

### `reml_q4.jl`

`src/reml_q4.jl` is Patterson–Thompson REML for that same q=4 PLSM: integrate
out location *and* scale fixed effects (`β_μ` and `β_σ`) via a bordered
augmented state, so the restricted correction reaches **all four** among-axis
SDs (not only the means). Public entry is `drm(…; method = :REML)` on the
bivariate q=4 route. Issue **#11** (wire it into the public API) is **CLOSED**.
The scale-axis gap (historical #18) landed via [#289](https://github.com/itchyshin/DRM.jl/pull/289)
(`shannon/q4-reml-allaxes`). `test/test_reml_q4_allaxes.jl` is in the default
suite. The capability row *REML bivariate phylogenetic location-scale (q4, all
axes)* is **`implemented`**. There is **no** `experimental/reml_q4.jl` on tip
(HANDOVER). Reopening this file would be touching a verified estimator, not
finishing a parked prototype.

### #49

GitHub **[#49](https://github.com/itchyshin/DRM.jl/issues/49)**
(*Missing-data handling: FIML / EM for incomplete data*) is **OPEN** with
labels `enhancement` + `idea`. Process status is **PARKED** — the 2026-08-16
and 2026-08-18 handovers, `LOOP/GOAL.md`, and
`docs/dev-log/coordination-board.md` all say so in those words. The intended
modelling path is FIML (or EM): integrate over / use partial rows rather than
dropping them. Design map [#198](https://github.com/itchyshin/DRM.jl/pull/198)
(`report/fiml-missing-data-design.md`) scoped **missing responses**; missing
predictors / MI deferred. Sister: GLLVM.jl [#27](https://github.com/itchyshin/GLLVM.jl/issues/27)
(still OPEN). The 08-16 handover also parks **`categorical`** under this same
fence. GitHub OPEN ≠ armed.

---

## Current status on `origin/main` @ `8c6d4f78` (2026-08-19)

Tip = merge of [#451](https://github.com/itchyshin/DRM.jl/pull/451)
(Poisson phylo Laplace Cox–Reid). Fetch/ff-only; this scout did not move tip.

### q4 / `reml_q4.jl` — shipped

| Fact | Evidence on tip |
|---|---|
| Module include | `src/DRM.jl` includes `reml_q4.jl` |
| Default-suite test | `test/runtests.jl` includes `test_reml_q4_allaxes.jl` |
| Capability chip | `implemented` (`docs/design/capability-status.md`) |
| Public q=4 front end | #187 **CLOSED**; structured providers #189 / #367 landed |
| REML speed track | #291 **CLOSED** (2026-08-02) |
| Same-target q4 REML fixture | #433 / #434 landed |
| Open PRs naming q4 / reml_q4 / FIML | **none** (only docs #452, which fences them) |
| Open issues that are “finish reml_q4” | **none** (#11 closed; leftover #11 body text about scale-axis / exact gradient is **stale** vs #289) |

`docs/src/capabilities.md` still has stale sentences that leave `reml_q4` in
`experimental/` and claim no missing-data path. **Trust the code +
`capability-status.md`**, not that page (the status file already names this
drift). This scout does not punch either file.

### #49 — partially on tip; remainder is a campaign

On tip today (the 2026-06 design report's “clean slate / no handling” sentence
is **stale**):

| Already on main | Still out |
|---|---|
| `src/missing_data.jl` — `drm_listwise` complete-case helper (no engine change) | Native **per-route** masked likelihood across drmTMB's fitted routes (chip stays `missing`) |
| Univariate Gaussian FE missing-response (`test/test_missing_response.jl`) | Gaussian **RE / structured / meta** missing-response — explicit `ArgumentError` in `gaussian_core.jl` (~line 490) |
| σ-phylo observed-rows fit (tree kept; Ayumi cell) | Missing **predictors** / `mi()` (chip `missing`) |
| Non-Gaussian missing-response tests | `missing_response = :fiml\|:omit` kwarg as designed in #198 — design checklist still unchecked |
| Bivariate q=4 per-cell observed mask (`test/test_missing_response_bivariate.jl`; comments say “#19”, which is **not** GitHub #19 — that issue is a closed phylo-marshalling design) | Remaining #198 checklist: summary observed-counts, MAR-beats-listwise campaign, worked Documenter example |
| Design file `report/fiml-missing-data-design.md` (#198 merged) | Closing GitHub #49; coordinating GLLVM.jl #27 |

Capability rows *Missing-response handling (native, per fitted route)* and
*Missing-predictor imputation (`mi()`)* are **`missing`**. That is honest:
listwise + a handful of admitted response-missing cells ≠ drmTMB's native
per-route FIML. **Do not flip those chips** from this sequence.

Issue comment (2026-06-13) already said remaining work is “covariate-missing +
EM/FIML for the meta/bivariate cells (still gated).” That remains the shape
on 2026-08-19 tip.

### D-111 (searched; adjacent fence, not this subject)

**D-111** is *Julia General registry OFF* until Shinichi feels ready (catch up
with drmTMB; probably R/CRAN first). It is **not** a q4 or #49 decision. AGHQ /
Cox–Reid lanes listed it next to these parks because it is a standing “do not
chase” fence. This scout does not reopen registration.

---

## Why AGHQ / Cox–Reid lanes fenced them out

Subject split (D-88), not taste.

1. **Different math, different files.** AGHQ lever 2 (#448 / #449) and Cox–Reid
   (#443 / #444 / #450 / #451) are 1-D Poisson `(1 | g)` GHQ and Poisson
   phylo / relmat Laplace. q4 is a 4-axis Gaussian PLSM. #49 remaining work
   punches *likelihoods* (`leaf_nll` / `sparse_aug_plsm.jl` / `gaussian_core.jl`
   gates). Same calendar ≠ same contract.
2. **Verified-engine hold.** 2026-08-18 handover PROTECTED table:
   “No q4 / `reml_q4.jl` — Verified engine.” Standing 08-16 fence: “Never
   regress the verified q=4 core (2.18×, logLik −256.51).” Touching
   `reml_q4.jl` to “help” a Poisson lever is how you lose that number.
3. **#49 is process-PARKED while GitHub stays OPEN.** LOOP/GOAL.md DEFER line
   and coordination board both print `#49 PARKED`. Item 3's recommended G0
   (Binomial `(1 | g)` Cox–Reid) already lists “No q4 / `src/reml_q4.jl`” and
   “#49 PARKED” as fences. Unparking inside the lever sequence would collide
   with item 3's attach *and* with item 5 (Cell D ADEMP) on honesty + compute.
4. **Capability honesty.** This sequence's rule is **chip stays missing** /
   **flipping nothing**. Reopening #49 as a “quick FIML G0” would create
   pressure to flip the missing-data rows. Those rows are `missing` **as
   named**. A partial punch that flips them would be a Rose failure.
5. **Not a dual-start.** Dual-start AGHQ **and** Cox–Reid was already
   RETRACTED. Adding q4 or #49 as a third live `src/` subject on the same
   shared Dropbox checkout would be the same class of bleed.

They were **offered** as item 4 of this honesty sequence precisely so a scout
could say this out loud. Offering ≠ arming.

---

## Recommendation: **PARKED** (default)

Keep both parks. Do not reopen in this sequence. Item 5 (Cell D ADEMP) is the
next named wait; item 3's Binomial `(1 | g)` Cox–Reid is the next *engine*
G0 if Shinichi names it.

| Candidate | Trivially unblocked? | Why not |
|---|---|---|
| `reml_q4.jl` / “q4” | **No** | Already implemented + tested + chipped `implemented`. No open “finish reml_q4” issue. Reopening = inventing work or regressing the verified engine. |
| #49 FIML / EM | **No** | Remaining work is gated routes + predictors + chip-honest closeout + a stale design file. Campaign, not a 1-D attach. Would collide with item 3 files/honesty and item 5 compute. |

**What would change the recommendation.** Shinichi names #49 (or a *new* q4
subject that is not `reml_q4.jl`) as a G0 **after** this honesty sequence, on
a fresh worktree off then-current `origin/main`, with an explicit inventory
because `report/fiml-missing-data-design.md` is stale vs tip. Silence is not
that name (D-87).

---

## If Shinichi reopens on purpose — what G0 would look like

**Do not open this issue from this PR.** Draft only.

### Do not reopen `reml_q4.jl`

There is no honest G0 titled “finish reml_q4.” If a future q4 slice exists, it
is a *new* subject (e.g. a named acceleration or inference cell) with its own
issue, and it still treats `src/reml_q4.jl` as a verified file to keep
byte-stable unless the issue says otherwise.

### Draft #49 G0 (only if named)

**Title:** `Admit missing-response FIML on one gated Gaussian cell (not a chip flip)`

**Scope (one cell, fail-loud elsewhere):**
- Pick **one** currently rejected Gaussian missing-response route (ordinary
  `(1 | g)` **or** `meta_V`, not both; not predictors; not `categorical`).
- Complete-data equivalence (masked path ≡ today's complete-case fit
  bit-for-bit on a seeded fixture).
- Keep every other gated route throwing the existing `ArgumentError`.
- Refresh `report/fiml-missing-data-design.md` *status* sentences that still
  say “no handling today” — docs honesty, not a chip flip.
- **Do not** close GitHub #49 until the drmTMB-named row is actually true.
- **Do not** flip `docs/design/capability-status.md`.

**Estimate:** 1–2 focused days *after* a same-week inventory (the 2026-06
design under-counts what tip already has). Totoro only if a MAR-beats-listwise
n-ladder is in the named scope; default this G0 is local mechanism tests.

**Gates:**
- No `src/reml_q4.jl`.
- No Cell D / ADEMP / recovery headline.
- Chip stays `missing` (missing-response + `mi()` + AGHQ).
- Flipping nothing in `capability-status.md`.
- No steal #420 / #406.
- D-111 still OFF.
- ML default unchanged.
- One issue → one branch → one PR. Human merges. No `closes #49` unless the
  owner says the issue is actually finished (it will not be, after one cell).
- Coordinate GLLVM.jl #27 as a comment, not a paired implementation.

**Better sequencing:** after Binomial CR (item 3, if named) **and** after Cell
D ADEMP (item 5), not instead of them.

---

## Explicit fences (this scout + any later reopen)

- **Flipping nothing** — do not edit `docs/design/capability-status.md`.
- **Chip missing** — AGHQ row stays `missing`; missing-response / `mi()` stay
  `missing`. q4 REML chip stays `implemented` (do not un-implement it either).
- **No Cell D** — ADEMP / Totoro / ntip-ladder is item 5. Not this file.
- **No `src/`** in this arc. **No** `src/reml_q4.jl` even if someone “just”
  wants a comment.
- **#49 stays PARKED** until Shinichi names a G0. GitHub OPEN is not a name.
- **No q4 engine work** (including `sparse_aug_plsm.jl` leaf masks) from this
  sequence.
- **Do not steal #420 / #406.** Do not touch #448 / #450 leftovers.
- **D-111** Julia General OFF.
- **Do not `gh issue create`.** Draft lives above.
- Never `git add -A`. Never vendor drmTMB.

---

## Shannon / lane notes (this scout)

- Dropbox `DRM.jl` was on `docs/cell-d-ademp-scope` (item 5 waiting) with
  untracked `2026-08-19-cell-d-ademp-pre-run.md` and
  `.codex/agents/shannon-coordinator.toml`. This lane used a **separate
  worktree** `~/local-scratch/lanes/DRM.jl-q4-49-parked-scout` off
  `origin/main` @ `8c6d4f78` (#451 merge). Item 5 files were not staged.
- Coordination board is **committed** on `origin/main` (reaches other lanes)
  but **stale** (still 2026-08-16 catch-up). This slice does not punch it
  (shared file / shared counter).
- `LOOP/GOAL.md` on `origin/main` still reads as the #450 phylo-CR mission.
  Stale; do not rewrite from a scout. Its DEFER line (`q4 · D-111 · #49`)
  is the fence this item records.
- Open foreign docs PRs: **#452** (item 3), **#420**, **#406** — do not steal.
- Census at scout time: 4 live lanes (those PRs + worktree×34). This lane
  owns **this plan file only**.

`PLATFORM: cursor | ON BRANCH: docs/q4-49-parked-scout | LANE: q4-49-parked-scout`
`OTHER LANES: cursor+PR#452 + cursor+PR#420 + cursor+PR#406 + item-5 docs/cell-d-ademp-scope (Dropbox, untracked plan)`
