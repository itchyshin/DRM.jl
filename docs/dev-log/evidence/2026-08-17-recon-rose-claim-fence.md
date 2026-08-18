# Rose claim fence — ordinary Gaussian mean-RE REML (plan review)

**Role:** Rose (pre-publish / claim-vs-evidence). **Read-only plan review** of
the *claim fence*, not the unwritten code.
**When:** 2026-08-17. **For:** the upcoming ultra-plan G0 locked as opt-in
`method = :REML` for Gaussian mean `(1 | g)` only.
**Personas named:** Rose. **No spawned subagents.**
**Locks (unchanged):** ML stays default. No AI-REML. No parity complete. No
TSV flip. `#136` not this. `#49` PARKED. D-111 OFF.

**Verdict on this fence:** **clean-with-limitations**.

This is a fence on the *plan*, not a ship of `src/`. The recommended G0 in
`docs/dev-log/after-task/2026-08-17-recommended-next-g0.md` is already scoped
tightly enough to plan. The limitations are scoreboard confusion, a stale
line-cite, and Documenter-tag honesty after the flip.

Two scoreboards stay separate (same split as
`docs/dev-log/evidence/2026-08-16-next-after-biv-rose.md`):

- **A** = drmTMB `julia-capabilities.tsv` (bridge / campaign claim). **Do not
  touch.**
- **B** = DRM.jl `docs/design/capability-status.md` (code + test census). This
  G0 may flip **one** B row after src + test land.

---

## 1. Can the B card flip without `test/runtests.jl` include?

**Yes** — for scoreboard B `implemented`, not for Documenter **Tested**, and
not for a full `AGENTS.md` Definition of Done.

Evidence, `docs/design/capability-status.md`:

- Lines 10–12: `implemented` = real code **and** a test file exercising it
  (`src/` path + matching `test/test_*.jl`, **and for the default-suite
  claims**, included in `test/runtests.jl`).
- Lines 22–25: nothing is marked `implemented` without a source file and a
  test file both found by reading the repository.

The parenthetical makes default-suite include **extra**. It is the bar for a
*default-suite claim*, not the minimum for the B chip.

The live rejected row (line 102) is `rejected` because of an explicit guard,
not because a test is missing from `runtests.jl`. The guard is in
`src/gaussian_core.jl` at the `if method === :REML` block **lines 413–423**
(throws `ArgumentError` for any non-fixed-effect structure outside the
separately gated q4 path). The census prose at lines 124–129 cites
`src/gaussian_core.jl:407` — **that line cite is stale**. Line 407 is
`return _withformula(fit, f)` on the asymmetric σ-phylo path. Ada must
re-cite the live guard (~413–423), not copy `:407`.

**#434 / #438 are a wait-gate precedent, not a B-card-flip precedent.**
Those PRs landed standalone `test/test_parity_*.jl` files and did **not**
edit `test/runtests.jl` (Option A wait-gate: `#423` + `#428` still own that
file). They also did **not** flip a B chip. Rose 2026-08-16: “#434 owned a
cell on A. It did not flip A, and it did not own orange chips on B.”
`test/runtests.jl` still has no `test_parity_biv_q4_phylo_reml` /
`test_parity_gaussian_phylo_mean` include (grep, this pass). Ada may reuse
the *include wait-gate*. Ada may **not** write “same as #434/#438 we already
flipped B cards this way.”

**DoD tension (limitation, not a block).** `AGENTS.md` Definition of Done
item 2 still says tests are wired into `test/runtests.jl`. A card flip
without that include is a **named exception**, the same class #434/#438
already used. The after-task must say: B chip flipped; default-suite include
deferred; full DoD item 2 incomplete until Option A. Do not claim
`Pkg.test()` covers ordinary-RE REML until the include lands.

**Card-flip rule:** flip
`REML with ordinary random effects (Gaussian mean)` from `rejected` →
`implemented` **only after** (i) the `gaussian_core.jl` guard is gone for
Gaussian mean `(1 | g)` and (ii) a real `test/test_*.jl` exercises that
path. `test/runtests.jl` include is later. Do not flip on docs alone. Do
not flip on a stub that still throws.

---

## 2. Docs MUST update vs MUST NOT

### MUST update (else the census / Documenter lie after the flip)

| File | Why |
|---|---|
| `docs/design/capability-status.md` | The row (line 102), the rejection prose (lines 124–129), and the snapshot counts. Snapshot line 198 already says “1 rejected” while the table has **2** rejected (ordinary-RE REML + `:natgrad`) — `2026-08-17-what-else.md` already flagged this stale arithmetic. When this row flips, recount honestly: rejected decrements by one; do not “fix” the count by minting other chips. |
| `docs/src/capabilities.md` REML-scope warning (lines 190–195) | Today: “Ordinary random effects under REML remain rejected. **ML is the default**.” After a real path, that sentence is false. Rewrite the warning to the fence: opt-in `method = :REML` for Gaussian mean `(1 \| g)` only; FE loc-scale and q4 all-axes unchanged; σ-RE / slopes / non-Gaussian / structured ordinary-RE still rejected; **ML stays default**. |

**Documenter tag honesty.** `docs/src/capabilities.md` lines 12–16:

- **Tested** = a `test/` file that runs in the default `Pkg.test()` suite
  (`test/runtests.jl`).
- **Impl, untested** = reachable code, no default-suite test.

If the B card flips without a `runtests.jl` include, any new Inference-table
row must be **Impl, untested** (or “standalone test file, not in the default
suite”), **not Tested**. Conflating B `implemented` with Documenter
**Tested** is the oversell this G0 is most likely to make.

DoD leftovers that *are* required for the slice (check-log.d entry,
after-task, Rose close, docstrings / a scoped worked example) are not
reader-facing claim surfaces. They do not flip A or B by themselves.

### MUST NOT update (HANDOVER / README oversell risk)

Leave these alone unless a single tightly scoped sentence is unavoidable.
Do **not** rewrite them as “REML now works for random effects.”

| File | Current honest sentence | Forbidden rewrite |
|---|---|---|
| `README.md` 155–157 | Opt-in REML for the **fixed-effect** Gaussian location–scale fit; model-selection guard. | “REML for random effects” / “REML is available” / any default-REML hint. |
| `HANDOVER.md` 29–30, 41–42, 109–110, 152–155 | Opt-in REML (#11/#235) + public `src/reml_q4.jl`; **ML is the default**; `lc_metric` is infra for AI-REML, **not** a public solver. Verified engine 2.18× / logLik −256.51. | Broaden “Public REML” to ordinary RE; touch verified-engine numbers; treat `lc_metric` as AI-REML shipped; “fix” the stale “#136 open” line as a VA ship. |
| `ROADMAP.md` 61–62, 137 | Phase 1.0 public opt-in REML = `reml_q4` / #11/#235. Open research still lists “REML scale-axis + exact REML gradient (ML stays default).” | Check off scale-axis / exact gradient / “full twin.” This G0 is mean `(1 \| g)` only. |
| `AGENTS.md` / `CLAUDE.md` | Constitution + ML-default + license boundary. | No constitution edit for a one-cell REML path. |
| TSV / Workflow G fixtures / `gen_fixtures.R` / `runparity.jl` | Campaign A. | No `supported` flip; no new ledger row; no “parity complete.” |

Safer to leave `HANDOVER.md` / `README.md` untouched than to “update docs”
and accidentally promote the cell to a headline. If a one-liner is added,
it must keep FE loc-scale and q4 sentences intact and name the `(1 | g)`
Gaussian-mean fence.

`docs/src/capabilities.md` is already stale in three places this census
corrects (SkewNormal, `reml_q4`, chi-bar-square). This G0 must not leave a
**fourth** stale sentence (the REML-scope warning). That is a MUST-update,
not an invitation to restyle the whole audit page.

---

## 3. Forbidden claims

Do not write any of these in the plan, PR title, HANDOVER, README,
Documenter, Mission Control, or after-task:

1. **AI-REML** — `lc_metric` is Fisher infra for #11/#165, not a public
   solver (`capability-status.md` 116–122; `HANDOVER.md` 155). HSquared
   AI-REML is a sister-package claim; do not mint a B row for it
   (`2026-08-17-what-else.md`).
2. **Parity complete** — no Workflow G cell, no “twin done,” no
   drmTMB-numeric identity for this path.
3. **TSV `supported`** — scoreboard A stays `partial` / untouched. This G0
   does not own `julia-capabilities.tsv`.
4. **REML as default** — `AGENTS.md` / `CLAUDE.md` / HANDOVER: **ML is the
   default** (REML likelihoods are not comparable across fixed-effect
   structures). Keep the model-selection guard.
5. **q4 regression / verified-engine rewrite** — do not touch
   `src/reml_q4.jl` / the sparse PLSM path; do not change or restate as
   newly measured the 2.18× or logLik −256.51 headlines.
6. **GPL / vendoring drmTMB source** — drmTMB is GPL(≥3); DRM.jl is MIT
   (`AGENTS.md` contract 3). Patterson–Thompson on the existing Woodbury
   spine must be fresh MIT code. Any lmer/drmTMB comparison uses
   *generated outputs* only.

Also forbidden (named so Ada does not smuggle them in as “docs cleanup”):

- Treating GitHub `#136` CLOSED as a VA ship; this G0 is not #136.
- Unparking `#49` (listwise ≠ native missing-response).
- D-111 / JuliaRegistrator / “supported” / CRAN-adjacent promotion.
- σ-RE REML, random slopes, non-Gaussian REML, structured/phylo/meta
  ordinary-RE REML (except the already-gated q4 path).
- Un-rejecting `:natgrad` (#13 FAIL, −259.80 vs −256.51).
- “Default suite covers ordinary-RE REML” before the `runtests.jl` include.
- A new export invented only to satisfy a misread of “export list” — this
  row is a `method = :REML` path, same shape as the existing FE REML chip.

---

## 4. Phase 0.25 receipt — greps, not `search_notes` alone

**Yes — a receipt that only cites `search_notes` is vacuous.**

`ultra-plan` Phase 0.25 (skill text): *semantic search finds what you asked
for; grep finds what you forgot to ask for. Neither alone is a sweep.*
**A receipt line citing only `search_notes` is INCOMPLETE** — it must cite
at least one deterministic grep over the log / journal / decisions, with
the string searched.

This pass’s own `search_notes` (`REML ordinary random effects claim fence
capability-status implemented runtests`, `search_all_projects: true`)
returned sister-package / n-effect REML notes and a **stale** drmTMB-era
`capabilities` hit (“a random effect on the mean under REML is exp…”). It
did **not** surface the live B definition (lines 10–12), the live guard
(~413–423), or the Documenter **Tested** vs **Impl, untested** split.
That is the failure mode.

**Remind Ada:** the Phase 0.25 receipt must cite greps (string + path),
not only MCP. Minimum set for this G0:

| Grep / read | Why |
|---|---|
| `docs/design/capability-status.md` — `implemented` definition + row “REML with ordinary random effects” | B-card rule |
| `src/gaussian_core.jl` — `method === :REML` | Live guard (~413–423), not `:407` |
| `docs/src/capabilities.md` — `REML scope` | Reader-facing warning that must move |
| `test/runtests.jl` — `test_reml` / `test_parity_` | Include wait-gate; no ordinary-RE file today |
| `memory/DECISIONS.md` — `D-111` | Registrator OFF |
| `docs/dev-log/after-task/2026-08-17-recommended-next-g0.md` + `2026-08-17-what-else.md` | Locked G0 + chip list |
| `git grep` / `gh` for `#423` `#428` `#136` `#49` | Foreign lanes + parked issues |

Brain `search_notes` may be an extra line. It is not the receipt.

---

## 5. Scope honesty / missing-cell / license / Confidence Eye

- **Scope tag:** after the flip, Documenter must keep ordinary-RE REML as a
  narrow opt-in cell, not a general REML page. Status tag if added:
  **First slice** / **Opt-in control**, never **Stable** for “REML.”
- **Missing-cell:** this G0 fills **one** B hole (ordinary Gaussian mean
  `(1 | g)`). It does not fill σ-RE, slopes, non-Gaussian REML, AGHQ, VA,
  native missingness, or cross-family (`#428` owns). Do not retally those
  chips as a side effect.
- **License:** no drmTMB GPL source. Generated numeric comparisons only.
- **Confidence Eye:** not in scope (no figure).
- **Verified-before-claim:** recovery vs ML + the existing FE-REML guard
  on Mac is the G0 bar in the recommended memo. Do not promote that to a
  Totoro / p-ladder / drmTMB-parity number.

---

## 6. Plan-review verdict

**clean-with-limitations** — on the *plan fence*, not the unwritten code.

**Why not blocked.** The recommended G0 already names the only legal
motion: replace the ordinary-RE guard with a real Patterson–Thompson path
on the existing Woodbury spine; ML remains default; no AI-REML; no parity
complete; no TSV; `#136` / `#49` / D-111 stay off; `#423`/`#428` not
stolen; q4 / FE REML / σ-phylo REML not regressable. B’s own definition
allows the chip flip on src + test file. License boundary is respected if
the plan stays “fresh MIT on `gaussian_ranef.jl`.”

**Why not clean.**

1. `#434`/`#438` must not be cited as B-card-flip precedent (they were A
   fixtures + a `runtests.jl` wait-gate).
2. B `implemented` ≠ Documenter **Tested** ≠ full `AGENTS.md` DoD item 2.
   The plan must name that split or the first PR sentence will oversell.
3. Census line-cite `:407` is already wrong; copying it into the plan is
   a false evidence trail.
4. Snapshot arithmetic is already stale (1 vs 2 rejected). The flip must
   recount, not “fix” other chips.
5. HANDOVER/README are one careless sentence away from a headline oversell.

**Ada may proceed to write the ultra-plan** with this fence quoted, not
paraphrased into a broader REML story.

*Rose. 2026-08-17. Plan fence only. No `src/` · no TSV · no GPL · no commit.*
