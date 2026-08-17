# Rose S5 — claim fence (`gaussian_phylo_mean` Route A fixture G0)

**Role:** Rose (pre-publish gate). **Read-only.** No `src/` · no TSV edit · no
`runtests.jl` · no commit.
**When:** 2026-08-17. **For:** G0-approved hermetic same-target fixture for
`gaussian_phylo_mean` (Route A: ML, univariate, `sigma ~ 1`).
**Personas named:** Rose. **No spawned subagents.** Melissa N/A (fence, not a close).
**Verdict:** **clean-with-limitations** — a fence, not a ship. Limitation:
S3–S4 artefacts are not yet banked; this note binds **PR language** and
ledger status. It does not certify coef/logLik numbers.

**Lane taken:** `PLATFORM: cursor | ON BRANCH: leftover docs/arc1-inventory
(catchup; this file only) | LANE: rose-s5-gaussian-phylo-mean-fence |
OTHER LANES: claude/lane-arc1-backlog-after-434 · #429 #428 #423 #421 #420 #406
· leftover docs/a3c-design · leftover #434 worktree`
Did not claim those files. No dedicated `feat/gaussian-phylo-mean-fixture`
lane exists yet — catchup path used.

Two scoreboards stay separate. **A** = drmTMB `julia-capabilities.tsv` (bridge
claim). **B** = DRM.jl `docs/design/capability-status.md` (code+test census).
This G0 owns a **cell on A**. It does not own orange chips on B.

Campaign G0 stays **2026-08-14 admit-what-R-fits**. This is a **new implement
G0** under it. Inventory class stays **TSV-claim / Phase 1.5 admitted**.
#432's `fixture-gap` class remains empty after `#434` (`b73d9241`). Do **not**
rewrite that taxonomy.

Parent fences: morning `2026-08-17-morning-rose-fence.md` (candidate G0s);
`2026-08-16-next-after-biv-rose.md` (after `#434`). This file is the
**row-specific S5** now that Shinichi named this G0.

---

## 1. Re-measured status (do not "improve" in prose)

Quoted from `git show origin/main:inst/extdata/julia-capabilities.tsv`
(drmTMB **0.7.0** @ `2d92c3666`; row text unchanged from `d9fddfa28`).
DRM.jl tip `5ddaffa9` (merge `#425`; `#434` already in history).

| Field | Today (do not flip) |
|---|---|
| `capability_id` | `gaussian_phylo_mean` |
| `r_bridge_status` | **`experimental`** |
| `claim_status` | **`partial`** |
| `drmjl_status` | DRM.jl first Gaussian phylo-mean path (Hopper Phase 1.5 #5) |
| `syntax` | `bf(y ~ x + phylo(1 \| species, tree = tree), sigma ~ 1), family = gaussian(), engine = "julia"` |
| `claim_boundary` | Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (`sigma ~ 1`) marshalling/result-shape + optional live TMB parity; **not** loc-scale phylo or non-Gaussian phylo. |
| `next_action` | Keep first phylo-mean result-shape and Route A parity tests; **do not widen to sigma-phylo here.** |
| `issue` | drmTMB#544 |
| twin (Hopper) | **YES** — live skip-guarded Route A (`engine="tmb"` vs `"julia"`, ML, seed 111, n=18) |
| class (Arc 1) | **TSV-claim / Phase 1.5 admitted** — engine on Scoreboard B; hermetic `expected.toml` **NONE** on `origin/main`. **Not** a remaining `#432` `fixture-gap`. |
| `#136` | **OPEN** (`gh issue view 136` — `closedAt=null`) — never `close` / `fix` / `resolve` |
| `#49` | GitHub **OPEN**; campaign lock **PARKED** — do not unpark |
| `#1049` | **OPEN** (`mergedAt=null`) — TSV `supported` STOP GATE |

Keep `claim_status` **`partial`** and `r_bridge_status` **`experimental`**.
A TSV `supported` flip is a **drmTMB owner + evidence** claim (STOP GATE),
not a Julia export. **No TSV supported flip in this PR.**

Scoreboard B (do not merge into A):

| Chip | Status | Relation to this G0 |
|---|---|---|
| Gaussian phylogenetic random intercept (mean) | **implemented** | Why this is keep-test banking, not an engine port. |
| Gaussian loc-scale phylo (`sigma ~ phylo(...)`) | neighbour cell | **Not this row.** |
| REML bivariate phylogenetic location-scale (q4) | **implemented** (`#434` fixture banked) | **Not this row.** Wrong estimand. |
| Variational (VA/ELBO) | **planned** | **#136 OPEN.** |
| Missing-data / `impute` / `mi()` | **PARKED** | **#49.** |

---

## 2. Allowed claim language (this PR may say)

Phrase the PR title, body, check-log, after-task, and HANDOVER **only** in
this vocabulary:

1. *"This PR adds a same-target fixture for `gaussian_phylo_mean` within
   the row's declared tolerance."* Cell evidence, not a TSV flip, not
   "parity complete."
2. *"`claim_status` stays `partial`; `r_bridge_status` stays `experimental`."*
3. *"ML, univariate, `sigma ~ 1` — not σ-phylo, not loc-scale phylo, not
   q4 REML."*
4. Quote the existing `claim_boundary` (do not tighten or loosen).
5. *"Direct DRM.jl evidence is not R-via-Julia bridge support."*
6. Record drmTMB **0.7.0** on this new cell; say the Workflow G **0.6.0**
   split. Cell lives **outside** `test/parity/fixtures/` (runner is ML / no tree).
7. Inventory class stays **TSV-claim / Phase 1.5 admitted**. This PR banks
   the missing hermetic Route A cell. It is **not** "the last fixture-gap."
8. License: DRM.jl is MIT; generated drmTMB *outputs* only.

---

## 3. Forbidden language (Rose blocks the PR)

| Forbidden | Why |
|---|---|
| "R–Julia parity complete" / "caught up" / "D-111 ready" | COUNTDOWN 0 is export-name honesty. This row stays unsigned. |
| Flip TSV `claim_status` → `supported` (or `r_bridge_status` → ready) | STOP GATE (`#1049` OPEN). Cell ≠ ledger. **No TSV supported flip.** |
| "The last fixture-gap" / rewrite `#432` taxonomy | After `#434` that inventory class is empty. This is keep-test banking of an admitted row. |
| Close / fix / resolve **#136** | VA is a stub. `#136` stays **OPEN**. |
| Widen to `sigma ~ phylo(...)` / loc-scale phylo / non-Gaussian phylo / q4 | TSV `next_action` + `claim_boundary`. Neighbour tests are **other cells**. |
| Unpark **#49** / sell listwise as `miss_control` | Campaign **PARKED**. Owner-named only. |
| Reuse `#434` REML/q4 numbers or `atol_loglik=6.0` | Wrong estimand (mean-only REML vs mean+scale). Measure this cell's own `[tol]`. |
| Glob into `test/parity/fixtures/` or "Workflow G 1e-3 twin" | Runner is ML / no tree. |
| Include in `test/runtests.jl` this PR | `#423` + `#428` still own that file. |
| "engine = julia admits this cell" / "bridge-admitted" | Direct `drm()` ≠ R-via-Julia. |
| Registrator / General / "ready to register" | **D-111 OFF.** |
| GPL vendoring of drmTMB source | MIT boundary. Generated outputs only. |
| Touch verified q=4 ML core (logLik −256.51 / 2.18×) | Fixture only. Noether lane. |
| Steal `#428` · edit `src/` | Wrong IDs / verified engine. |

---

## 4. Five-line PR body claim block (conductor paste)

```
This PR adds a same-target fixture for `gaussian_phylo_mean` within the row's declared tolerance.
`claim_status` stays **partial**; `r_bridge_status` stays **experimental**. No TSV `supported` flip.
#136 stays OPEN. #49 stays PARKED. Does not widen to `sigma ~ phylo(...)`.
Does not claim "R–Julia parity complete," "last fixture-gap," or close #136.
Quote: first phylo-mean (sigma ~ 1) marshalling/result-shape + optional live TMB parity; not loc-scale phylo or non-Gaussian phylo.
```

---

## 5. Rose would block (checklist at PR open)

- [ ] Title or README that says parity is complete.
- [ ] A TSV `supported` flip authored on the DRM.jl side.
- [ ] "Last fixture-gap" / rewrite of `#432` taxonomy.
- [ ] A `#136` close / fix / resolve.
- [ ] Widen to `sigma ~ phylo(...)` / loc-scale / non-Gaussian phylo / q4.
- [ ] Unpark `#49`.
- [ ] Registrator / General language (D-111 OFF).
- [ ] Vendoring drmTMB GPL source or writing the shared drmTMB tree.

**What Rose will accept:** one-issue PR that adds the Route A fixture +
standalone test, leaves `claim_status` **`partial`** and `r_bridge_status`
**`experimental`**, quotes the existing `claim_boundary`, does not call
this the last fixture-gap, and uses the five-line block above.

---

## Sources (do not re-derive)

- TSV: `git show` drmTMB `origin/main:inst/extdata/julia-capabilities.tsv` @ `2d92c3666`
- `#136` OPEN / `#49` OPEN+PARKED / `#1049` OPEN: `gh` this pass
- Hopper S1: `docs/dev-log/evidence/2026-08-17-gaussian-phylo-mean-s1.md`
- Morning fence: `docs/dev-log/evidence/2026-08-17-morning-rose-fence.md`
- Approved plan: Dropbox
  `docs/dev-log/after-task/2026-08-17-ultra-plan-gaussian-phylo-mean-fixture.md`
- Sibling S5 shape: `docs/dev-log/evidence/2026-08-16-biv-q4-s5-rose-fence.md`
- License: MIT here; generated outputs only. D-94 · D-111 OFF.

**UNVERIFIED this pass:** fresh `parity_ledger.py` countdown; `Pkg.test`;
S3–S4 coef/logLik (not yet generated).
