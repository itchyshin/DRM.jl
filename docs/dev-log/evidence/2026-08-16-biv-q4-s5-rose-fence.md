# Rose S5 — claim fence refresh (`biv_q4_phylo_reml` fixture G0)

**Role:** Rose (pre-publish gate). **Read-only.** No `src/` · no TSV edit · no
`runtests.jl` · no commit.
**When:** 2026-08-16. **For:** executing lane `feat-biv-q4-phylo-reml-fixture`
on `claude/lane-biv-q4-phylo-reml` @ `2209ecd8` (PR **#432 MERGED**).
**Personas named:** Rose. **No spawned subagents.**
**Verdict:** **clean-with-limitations** — a fence refresh, not a ship. Limitation:
S1–S4 artefacts are not yet on this branch; this note binds **PR language**
and ledger status. It does not certify coef/logLik numbers.

**Lane:** `PLATFORM: cursor | ON BRANCH: claude/lane-biv-q4-phylo-reml | LANE: feat-biv-q4-phylo-reml-fixture | OTHER LANES: leftover catchup · #429 A12 · #428 A11 · #425 A10 · #423 A8 · #421 · #420 · #406 · main-direct`

Two scoreboards stay separate. **A** = drmTMB `julia-capabilities.tsv` (bridge
claim). **B** = DRM.jl `docs/design/capability-status.md` (code+test census).
This G0 owns a **cell on A**. It does not own orange chips on B.

Parent fence (11 unsigned rows): `docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md`
(now on `origin/main` via #432). This file is the **row-specific S5 refresh**
for the fixture PR.

---

## 1. Re-measured status (do not "improve" in prose)

Quoted from `git show origin/main:inst/extdata/julia-capabilities.tsv`
(drmTMB **0.7.0** @ `d9fddfa28`; DRM.jl tip `2209ecd8`). `#136` re-checked
`OPEN` (`gh issue view 136` — no `closedAt`).

| Field | Today (do not flip) |
|---|---|
| `capability_id` | `biv_q4_phylo_reml` |
| `r_bridge_status` | **`experimental`** |
| `claim_status` | **`partial`** |
| `drmjl_status` | q4 PLSM REML path when installed DRM.jl supports it |
| `claim_boundary` | Requires the full four-axis phylogenetic location-scale grammar; native TMB has separate q4 recovery evidence, but this Julia row does not establish same-target bridge parity, interval reliability, or HSquared AI-REML support. |
| `next_action` | Bank fit-specific CI/status parity before release language. |
| `issue` | drmTMB#544 |
| twin (Hopper) | **YES** — `drmTMB(..., REML = TRUE)` + four-axis `phylo()` + `biv_gaussian()` |
| class (Arc 1) | **fixture-gap** — engine on Scoreboard B; same-target fixture **NONE** on `origin/main` |
| `#136` | **OPEN** — never `close` / `fix` / `resolve` near that number |

Keep `claim_status` **`partial`** and `r_bridge_status` **`experimental`**.
A TSV `supported` flip is a **drmTMB owner + evidence** claim (STOP GATE),
not a Julia export. **No TSV supported flip in this PR.**

Scoreboard B (do not merge into A):

| Chip | Status | Relation to this G0 |
|---|---|---|
| REML bivariate phylogenetic location-scale (q4, all axes) | **implemented** | Why this is a fixture-gap, not a Laplace port. |
| REML with ordinary random effects (Gaussian mean) | **rejected** | **Not this row.** |
| Natural-gradient EM (`algorithm = :natgrad`) | **rejected** (#13 FAIL) | **Not this row.** |
| Variational (VA/ELBO) | **planned** | **#136 OPEN.** |

---

## 2. Allowed claim language (this PR may say)

Phrase the PR title, body, check-log, after-task, and HANDOVER **only** in
this vocabulary:

1. *"This PR adds a native-vs-Julia same-target fixture for
   `biv_q4_phylo_reml` within the row's declared tolerance."* Cell evidence,
   not a TSV flip, not "parity complete."
2. *"`claim_status` stays `partial`; `r_bridge_status` stays `experimental`."*
3. *"Export-gap countdown at 0; 11 capability rows still unsigned."* Do not
   drop the second clause.
4. Quote the existing `claim_boundary` (do not tighten or loosen).
5. *"Direct DRM.jl evidence is not R-via-Julia bridge support."*
   `test/test_bridge_q4_direct_export.jl` still asserts
   `"no R-via-Julia q4 bridge parity"` — leave that sentence true.
6. Record drmTMB **0.7.0** on this new cell; say the Workflow G **0.6.0** split.
7. Bank **fit-specific CI/status** (`converged`, `pdHess` / Julia equivalent,
   `interval_status`) as recorded fields — not coverage or reliability.
8. License: DRM.jl is MIT; generated drmTMB *outputs* only.

---

## 3. Forbidden language (Rose blocks the PR)

| Forbidden | Why |
|---|---|
| "R–Julia parity complete" / "caught up" / "D-111 ready" | COUNTDOWN 0 is export-name honesty. This row stays unsigned. |
| Flip TSV `claim_status` → `supported` (or `r_bridge_status` → ready) | STOP GATE. Cell ≠ ledger. **No TSV supported flip.** |
| "interval reliability" / "coverage" / "AI-REML" / "HSquared" as this twin | `claim_boundary` already forbids them. Native TMB q4 recovery ≠ this Julia row. |
| Close / fix / resolve **#136** | VA is a stub. `#136` stays **OPEN**. |
| Promote ordinary-RE REML or `:natgrad` | Scoreboard B **rejected**. |
| Call `test_reml_q4_allaxes.jl` "bridge parity" | Julia-only REML≥ML property. Not native-vs-Julia coef+logLik. |
| Rewrite `test_bridge_q4_direct_export.jl` to drop the refusal | This slice is native `drm()`, not the bridge. |
| "engine = julia admits this cell" / "bridge-admitted" | Direct DRM.jl ≠ R-via-Julia. |
| Registrator / General / "ready to register" | **D-111 OFF.** |
| GPL vendoring of drmTMB source | MIT boundary. Generated outputs only. |
| Touch verified q=4 ML core (logLik −256.51 / 2.18×) | Fixture only. Noether lane. |
| Steal `#428` · unpark `#49` · design `engine_control` | Wrong IDs. |

---

## 4. Five-line PR body claim block (conductor paste)

```
This PR adds a native-vs-Julia same-target fixture for `biv_q4_phylo_reml` within the row's declared tolerance.
`claim_status` stays **partial**; `r_bridge_status` stays **experimental**. No TSV `supported` flip.
#136 stays OPEN. Direct DRM.jl evidence is not R-via-Julia bridge support.
Does not claim interval reliability, coverage, AI-REML, or "R–Julia parity complete."
Quote: this Julia row does not establish same-target bridge parity, interval reliability, or HSquared AI-REML support.
```

---

## 5. Rose would block (checklist at PR open)

- [ ] Title or README that says parity is complete.
- [ ] A TSV `supported` flip authored on the DRM.jl side.
- [ ] Coverage / reliability / AI-REML / HSquared sold as this twin.
- [ ] An orange-chip "fix" (ordinary-RE REML, `:natgrad`) or a `#136` close.
- [ ] Rewriting the q4 bridge-export refusal string.
- [ ] Registrator / General language (D-111 OFF).
- [ ] Vendoring drmTMB GPL source or writing the shared drmTMB tree.

**What Rose will accept:** one-issue PR that adds the fixture + standalone
test, leaves `claim_status` **`partial`** and `r_bridge_status`
**`experimental`**, quotes the existing `claim_boundary`, and uses the
five-line block above.

---

## Sources (do not re-derive)

- TSV: `git show origin/main:inst/extdata/julia-capabilities.tsv` @ `d9fddfa28`
- `#136` OPEN: https://github.com/itchyshin/DRM.jl/issues/136
- Parent fence: `docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md` (#432)
- Ordered backlog: `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`
- Hopper twin-map: `docs/dev-log/evidence/2026-08-16-arc1-hopper-twin-map.md`
- Approved plan: `LOOP/ultra-plan.md` / Dropbox
  `docs/dev-log/after-task/2026-08-16-ultra-plan-biv-q4-phylo-reml-fixture.md`
- License: MIT here; generated outputs only. D-94 · D-111 OFF.
