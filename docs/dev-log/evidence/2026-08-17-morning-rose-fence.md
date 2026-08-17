# Rose claim fence — morning 2026-08-17 (docs refresh · `gaussian_phylo_mean`)

**Role:** Rose (pre-publish / claim-vs-evidence). **Read-only.** No `src/` · no TSV
edit · no `runtests.jl` · no GPL vendoring · no commit · no G0 pick.
**When:** 2026-08-17 morning. **For:** (a) docs-only Arc 1 backlog refresh, and
(b) a *possible* `gaussian_phylo_mean` hermetic fixture. Shinichi names one
G0 or waits. **Do not auto-start.**
**Personas named:** Rose. **No spawned subagents.** Melissa N/A (fence, not a close).
**Lane:** `PLATFORM: cursor | ON BRANCH: leftover docs/a3c-design (unused) |
LANE: morning-rose-fence (this scratch file only) | OTHER LANES:
claude/lane-arc1-backlog-after-434 · #429 #428 #423 #421 #420 #406`
Did not claim the Claude backlog scratch or open-PR files.

**Verdict:** **clean-with-limitations** — a fence, not a ship. Limitation: it
binds allowed/forbidden claims for two *candidate* G0s. It does not pick,
inventory a new cell, flip Scoreboard B, or decide drmTMB `claim_status`.

Two scoreboards stay separate. **A** = drmTMB `julia-capabilities.tsv` (bridge
claim). **B** = DRM.jl `docs/design/capability-status.md` (code+test census).
Neither candidate owns orange chips on B.

---

## 0. Live locks this pass (do not re-derive)

| Surface | This-pass evidence | Call |
|---|---|---|
| DRM.jl `origin/main` | Tip **`5ddaffa9`** (merge #425). #434 still on main: **`b73d9241`**. | #434 fixture banked. Claim stays `partial`. |
| Wait-gate | `#423` OPEN · DIRTY · CONFLICTING. `#428` OPEN · DIRTY · CONFLICTING. `#425` MERGED 2026-08-17T01:47:10Z. | Include of `test_parity_biv_q4_phylo_reml.jl` still waits on **#423 + #428**. |
| TSV | drmTMB `origin/main` **`d9fddfa28`** `inst/extdata/julia-capabilities.tsv` | 0 `supported`. `gaussian_phylo_mean`: `claim_status=partial`, `r_bridge_status=experimental`. |
| `#1049` | `gh pr view` → **OPEN**, `mergedAt=null` | STOP GATE. Do not merge from DRM.jl. |
| `#136` | `gh issue view 136` → **OPEN** (VA/ELBO) | Never close / fix / resolve. |
| `#49` | GitHub **OPEN**; campaign lock **PARKED** | Do not unpark. |
| `#428` | Owned skip (`cross_family_latent`) | Do not steal. |
| D-111 | OFF | No Registrator / General. |
| License | MIT here | Generated drmTMB *outputs* only. |
| Docs plan | `docs/dev-log/after-task/2026-08-16-ultra-plan-next-after-biv-q4.md` | Written; **still unexecuted.** |
| Stale inventory | `origin/main:docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md` | Still says `biv_q4_phylo_reml` fixture **NONE** and still recommends it as first later implement. **False after `b73d9241`.** |
| Hermetic Route A | `git ls-tree origin/main` — no `test/parity/fixtures/gaussian-phylo*` | Result-shape lives in `test/test_bridge.jl`. Same-target `expected.toml` is **NONE**. |
| Ledger script | **Not re-run this pass** | Phrase *export-gap countdown at 0; 11 rows still unsigned* is **UNVERIFIED** as a fresh `parity_ledger.py` count. TSV text is verified via `git show`. |

**Ada vs Hopper (cite; do not resolve):** Ada 0b15f5be + overnight G0 lock =
docs-only / Option B OFF / after #434 **no remaining fixture-gap implement**.
Hopper a235a3c9 late pick = `gaussian_phylo_mean` Route A hermetic fixture
(coef+logLik), not a TSV flip. Overnight handover parks that pick. Morning
Shinichi chooses (a), (b), or wait #423+#428. Rose fences both.

**Class correction** (earlier next-arc Rose line “Fixtures exist” for this
ID was sloppy): Phase 1.5 admission = result-shape + optional *live* Route A.
That is **not** a committed same-target `expected.toml`. Do not write
“fixtures exist” for `gaussian_phylo_mean` as if it were
`gaussian-locscale` / `gaussian-bivariate-rho12`.

---

## 1. Forbidden on *either* G0 (Rose blocks the PR / README line)

Do **not** write, imply, title, or close:

| Forbidden | Why |
|---|---|
| **"R–Julia parity complete"** / "caught up" / "D-111 ready" / "`engine=\"julia\"` admits whatever drmTMB fits" | COUNTDOWN 0 ≠ public twin. 11 rows still unsigned. Registration **OFF**. |
| **TSV `claim_status` → `supported`** (or `r_bridge_status` → ready) **without drmTMB owner + new evidence** | STOP GATE. Cell ≠ ledger. `#1049` still OPEN. Do not author `julia-capabilities.tsv` here. |
| **Close / fix / resolve `#136`** | VA is a stub. **#136 stays OPEN.** |
| **Widen to sigma-phylo** (`sigma ~ phylo(...)`, loc-scale phylo, σ-phylo REML as this cell) | TSV `next_action` (quote): *Keep first phylo-mean result-shape and Route A parity tests; do not widen to sigma-phylo here.* `claim_boundary`: *not loc-scale phylo or non-Gaussian phylo.* Widening invents a different row. |
| **Unpark `#49`** / sell listwise as `miss_control` / start `gaussian_response_mask` | Campaign **PARKED**. Owner-named only. |
| Invented twin **Δ** (binomial+`phylo`, beta+`relmat`, AI-REML, GLLVM VA-GH) | D-94: behind **drmTMB**. `#1049` OPEN is not a twin to manufacture. |
| Steal `#428` · edit `src/` · flip Scoreboard B orange → green | Owned / verified-engine / census lie. |
| Registrator / General · GPL vendoring | D-111 OFF · MIT boundary. |

---

## 2. Candidate (a) — docs-only backlog refresh

**What it is:** unique-path docs. Re-rank the eleven unsigned rows now that
#434 shipped. One issue → one docs branch → one PR. No `src/` · no TSV ·
no `runtests.jl`.

### Allowed sentences

1. *"PR #434 added a native-vs-Julia same-target fixture for
   `biv_q4_phylo_reml` within the row's declared `[tol]`; `claim_status`
   stays `partial`."*
2. *"Export-gap countdown at 0; 11 rows still unsigned."* Keep both clauses.
3. *"The #432 ordered backlog's **NONE** / recommended-first-implement line
   for `biv_q4_phylo_reml` is stale after `b73d9241`."* Fact fix, not a
   promotion.
4. Quote, do not rewrite, the eleven `claim_boundary` sentences (including
   Route A: first phylo-mean `sigma ~ 1`; not loc-scale / non-Gaussian phylo).
5. *"Direct DRM.jl evidence is not R-via-Julia bridge support."*
6. License: MIT; generated outputs only.

### If sloppy, the docs PR would illegally claim…

| Illegal | Honest substitute |
|---|---|
| "Inventory complete / 11 rows cleared / parity caught up" | Refresh **classifies**. It does not promote. |
| "Recommended next implement = `<row>`" without a new G0 | After #434 there is **no** remaining Ada fixture-gap implement. Do **not** mint a recommended implement in a docs PR — including do not crown `gaussian_phylo_mean`. |
| Silent rewrite of `claim_boundary` / TSV `supported` | Quote. Do not tighten or loosen. |
| Treating #434 as making `biv_q4` `supported` | Update NONE → **banked**; `[tol]` = measured mean-vs-mean+scale gap; status still `partial`. |
| Wiring the #434 test into `runtests.jl` under a "docs" title | Collision-blocked by **#423 + #428**. Not this slice. |
| "Fixtures exist" for `gaussian_phylo_mean` as a Workflow G cell | Say: result-shape + live Route A admitted; hermetic `expected.toml` **NONE**. |
| Widen sigma-phylo · unpark `#49` · close `#136` | Standing locks. |

Ada's written plan already **DEFERs** `gaussian_phylo_mean` on a docs G0.
Hold that deferral unless Shinichi names (b) as a *separate* G0.

---

## 3. Candidate (b) — possible `gaussian_phylo_mean` hermetic fixture

**What it may be, if Shinichi names a fresh G0:** same *class* as #434 —
one unsigned `capability_id` → one same-target native-vs-Julia cell
(generated outputs only) for the **already-admitted** Route A grammar.
It is **keep-test banking**, not a missing-engine port, and **not** Ada's
"remaining fixture-gap" (that row shipped as #434).

**Requires a new G0.** Do not reuse the #432 / #434 / docs-refresh LOOP kits.
Do not start from the Claude `lane-arc1-backlog-after-434` scratch.

### TSV quotes (do not tighten or loosen)

- **syntax:** `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), family = gaussian(), engine = "julia"`
- **claim_boundary:** *Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (sigma ~ 1) marshalling/result-shape + optional live TMB parity; not loc-scale phylo or non-Gaussian phylo.*
- **next_action:** *Keep first phylo-mean result-shape and Route A parity tests; do not widen to sigma-phylo here.*
- **claim_status / r_bridge_status:** `partial` / `experimental` — leave both.

### Allowed sentences

1. *"This PR adds a native-vs-Julia same-target fixture for
   `gaussian_phylo_mean` within the row's declared tolerance."* Cell
   evidence only.
2. *"`claim_status` stays `partial`."* Not a TSV flip.
3. *"ML, univariate, `sigma ~ 1` — not σ-phylo, not loc-scale phylo, not
   q4 REML."*
4. *"Workflow G metas remain drmTMB 0.6.0 / ML / no tree; this cell is
   outside `test/parity/fixtures/`."* Same reason #434 used `q4-reml/`.
5. Generated outputs only. Direct `drm()` ≠ R-via-Julia bridge support.

### Shape (if named)

- New slug + generator + standalone Julia test (coef + logLik + fit-status).
- **Do not** edit `gen_fixtures.R` / `test/runtests.jl` / `tools/parity_ledger.py`
  while `#423` / `#428` own those paths.
- **Do not** reuse `loconly-gaussian-phylo-reml-v1` or #434 REML/q4 numbers
  (wrong estimator / wrong axes).
- drmTMB **0.7.0** generated outputs; say the 0.6.0 / 0.7.0 split.

### If sloppy, the fixture PR would illegally claim…

| Illegal | Evidence that forbids it |
|---|---|
| "`gaussian_phylo_mean` is `supported`" / TSV flip | Owner lock + STOP GATE. Fixture ≠ ledger. `next_action` is keep-tests, not promote. |
| Widen to `sigma ~ phylo(...)` / loc-scale phylo / non-Gaussian phylo / q4 | TSV `claim_boundary` + `next_action`. Neighbour tests (`test_reml_sigma_phylo.jl`, `test_gaussian_locscale_phylo.jl`, #434 q4) are **other cells**. |
| "The remaining fixture-gap" / "parity complete" / "clears the 11" | Ada: no remaining fixture-gap after #434. This is optional keep-test banking of an admitted row. |
| Glob into `test/parity/fixtures/` or "Workflow G 1e-3 twin" | Runner is ML / no tree. Phylo cell stays outside that glob. |
| Include in `runtests.jl` this morning | `#423` + `#428` still own the file. |
| Unpark `#49` · close `#136` · invent binomial+`phylo` | Standing locks + D-94. |
| Reuse #434 `[tol]` (`atol_loglik=6.0`) as this cell's twin | That gap is TMB mean-only REML vs Julia mean+scale. This cell is ML Route A. Measure its own `[tol]`. |

---

## 4. What Rose will accept

- **(a)** Status-honesty docs PR: stale NONE line gone; #434 banked +
  `[tol]` honest; every `claim_status` untouched; phrase *export-gap
  countdown at 0; 11 rows still unsigned*; no new "recommended implement."
- **(b)** Only after a **named** fresh G0: one-issue hermetic Route A
  fixture, `sigma ~ 1`, generated outputs only, `claim_status` untouched,
  `claim_boundary` quoted, no sigma-phylo widen, no `runtests.jl` steal.
- **Wait** `#423` + `#428` for the #434 include — still the honest
  follow-up, not a ledger-row implement.

**What Rose will block:** any title that says parity is complete; any TSV
`supported` without drmTMB owner + new evidence; closing `#136`; widening
sigma-phylo; unparking `#49`.

---

## 5. Standing locks (copy into whichever ultra-plan DEFER)

- TSV `supported` flip — drmTMB STOP GATE (`#1049` OPEN; `#1050` merge does
  not authorize a flip from DRM.jl).
- `#136` OPEN — VA Experimental; no close/fix/resolve.
- `#49` PARKED — missing-data / `impute` / `mi()`; owner-named only.
- Do **not** widen `gaussian_phylo_mean` to sigma-phylo.
- `#428` — owned skip; do not steal `cross_family_latent`.
- `#423` + `#428` own `test/runtests.jl` until they land.
- D-111 OFF · D-94 (behind drmTMB) · MIT / generated outputs only.
- Never regress the verified q=4 ML core (2.18×, logLik −256.51).
- Do not glob a phylo cell into `test/parity/fixtures/`.
- Foreign Claude `lane-arc1-backlog-after-434` — do not claim those files.

---

## Sources (do not re-derive)

- Overnight handover: `docs/dev-log/after-task/2026-08-17-overnight-handover.md`
- Ada advise: scratch `2026-08-16-next-arc-ada-advise.md` (0b15f5be)
- Hopper late pick: scratch `2026-08-16-next-arc-hopper-pick.md` (a235a3c9)
- Parent fences: scratch `2026-08-16-next-arc-rose-fence.md`;
  Dropbox `docs/dev-log/evidence/2026-08-16-next-after-biv-rose.md`
- Ordered backlog (stale on main): `origin/main:docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`
- Docs plan (unexecuted): `docs/dev-log/after-task/2026-08-16-ultra-plan-next-after-biv-q4.md`
- TSV: `git show` drmTMB `origin/main:inst/extdata/julia-capabilities.tsv` @ `d9fddfa28`
- `#136` OPEN / `#49` OPEN+PARKED / `#1049` OPEN / `#423` `#428` DIRTY / `#425` MERGED: `gh` this pass
- [[DECISIONS#D-94]] · [[DECISIONS#D-111]]

**UNVERIFIED this pass:** fresh `parity_ledger.py` countdown; `Pkg.test`.
