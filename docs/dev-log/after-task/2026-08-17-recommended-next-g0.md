# 2026-08-17 — recommended next G0 (after #434 + #438 + #436)

**Author:** Shannon (Ada). Named perspectives: Ada (this memo), Rose (fences),
Noether (would own `src/` if approved). **No nested Task subagents.**
**Platform:** Cursor Grok. **Read-only** except this note.
**Lane:** `docs-recommended-next-g0`. Did not claim `#423`/`#428`/`#406` files,
`claude/lane-*` leftovers, or leftover `docs/a3c-design` for builds.
**Preflight:** `FOREIGN LANE ACTIVE (claude direct-to-main)` · 10 live lanes.
**Plan-mode:** Cursor cannot EnterPlanMode — said once; this is a recommendation
memo, not a full ultra-plan.

---

## 🎯 GOAL

Name **one** next ultra-plan G0 that would move a julia-surface card
(`implemented` = real `src/` + test). Fixtures #434+#438 and backlog #436 are
done. Cheap same-target cells are empty. Do not steal #423+#428. No TSV flip.
No “parity complete.” D-111 OFF. #49 PARKED.

---

## Recommendation — ordinary Gaussian mean-RE REML

**HEADLINE:** Opt-in `method = :REML` for Gaussian mean `(1 | g)` — keep ML
the default; replace the `gaussian_core.jl` guard with a real path.

**Why now.** After #434 / #438 / #436 there is no honest fixture-gap implement.
The only legal motions that move a julia-surface card are engine. This is the
**smallest honest flip**: `rejected` → `implemented`. The REML ladder already
has FE loc-scale, σ-phylo, and q4 all-axes; ordinary mean `(1 | g)` is the
hole in the middle. drmTMB and lmer users hit today’s `ArgumentError` first.
Woodbury ML already lives in `src/gaussian_ranef.jl` — this is Patterson–
Thompson on that spine, not a new estimator class.

**Why not the others (card-movers).**

| Candidate | Verdict |
|---|---|
| **VA / #136** | Do not pick. GitHub **CLOSED** 2026-08-17 13:45Z (same second as #438). Public Experimental `(1\|g)` already on 5 families; 136e found LA ≈ VA on Gamma shape. Remaining work is ZI / phylo / crossed — large, and treating the close as a ship is forbidden. Flipping `planned` without new engine is docs-only (does **not** move cards). |
| **AGHQ** | 2nd choice. Truly `missing`. Weeks. New estimator. |
| **`:natgrad`** | STOP. #13 FAIL (−259.80 vs −256.51). Cannot honestly un-reject. |
| **HSquared accessors** | Already **`implemented`** (`src/heritability.jl`, `test/test_heritability.jl`). AI-REML is a sister-package claim — do not mint. |
| **Cross-family** | `#428` owns. Steal unless he names steal. |
| More fixtures / runtests include / docs | Do **not** move cards. Include still wait-gated on #423+#428. |

**DEFER.** AGHQ; remaining VA (ZI×RE / phylo / crossed); `:natgrad`; HSquared
AI-REML; #49 FIML/`mi()`; #428 steal; TSV `supported`; “parity complete”;
D-111 / Registrator; `runtests.jl` include until #423+#428 merge (or an
explicit steal G0); sigma-RE REML; random slopes; non-Gaussian REML; q=4
engine edits.

**Mac vs Totoro.** **Mac.** Small-n `(1 | g)` recovery vs ML + the existing
FE-REML guard. Totoro not required for the G0 bar.

**Risk.** Medium. Touches `src/gaussian_core.jl` (routing) and
`src/gaussian_ranef.jl` (objective). Must not regress FE REML, σ-phylo REML,
or q4 REML (`logLik −256.51` / 2.18× untouched). Keep the model-selection
guard (REML likelihoods are not comparable across FE structures). Do not
sell REML as the default.

**Noether + `src/`?** **Yes.** Maintainer sign-off required (`AGENTS.md` lane:
public API / likelihood / `src/` engine). Open a **new** issue (no existing
ordinary-RE REML ticket; #11 was FE REML). Do not write `closes #136`.

**Start-gate (do not steal).** Cut from `origin/main`. Land `src/` +
standalone `test/test_reml_ordinary_ranef.jl`. **Do not edit
`test/runtests.jl`** until #423+#428 merge. Card can flip on guard-gone +
test file; default-suite include is a later Option A slice, same pattern as
#434/#438.

---

## 2nd choice — AGHQ adaptive-quadrature marginal

If he rejects REML-RE: **AGHQ** (`missing` → `implemented`). The only legal
grey estimator that is not #49 and not a #428 steal. New marginal class
(`:LA` / `:VA` / `:AGHQ`). Weeks. **Noether + `src/` + maintainer.** Totoro
for any n-ladder; Mac only for a 1-group GHQ smoke. TSV/A still NO. Do not
bundle with VA.

---

## 3 questions for G0 approval

1. **Approve this G0?** Ordinary Gaussian mean-RE REML (`(1 | g)` only), or
   wait for #423+#428 first so one PR can also include `runtests.jl`?
2. **Fence the slice?** Mean `(1 | g)` only this G0 — no σ-RE, no slopes, no
   non-Gaussian REML, no q4 touch?
3. **New issue + Noether/maintainer OK** to edit `src/gaussian_core.jl` and
   `src/gaussian_ranef.jl`?

---

## Sources (do not re-derive)

- Dropbox `docs/design/capability-status.md` (4 missing + 1 planned + 2 rejected)
- `docs/dev-log/evidence/2026-08-17-what-else.md`
- `HANDOVER.md` / `ROADMAP.md` / `AGENTS.md` (VA Experimental; D-111 OFF)
- `src/variational.jl` header; `src/gaussian_core.jl` REML guard ~L413
- `docs/src/capabilities.md` REML-scope warning + VA Experimental rows
- `docs/dev-log/after-task/2026-08-09-136e-va-bias.md` (LA ≈ VA)
- `gh issue view 136` — CLOSED 2026-08-17T13:45:12Z
- `memory/DECISIONS.md` D-111
- Overnight handover: skip steal #423+#428; no TSV flip; no parity complete

*Written 2026-08-17 America/Denver. Recommendation only. No `/goal`. No PR.*
