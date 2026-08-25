# After-task — drmTMB catch-up, Wave 1

**Date:** 2026-08-24 · **Platform:** Claude Code (Shannon) · **Branch:** `feat/drmtmb-catchup`
**Issues:** #465 #466 #467 #468 · DRM.jl#460 → drmTMB#1080 · **Base:** `origin/main` @ `8d45b651`

## 1. Goal

The owner named a G0: **catch up with drmTMB, then complete the package.** Wave 1 was the cheap,
independent, de-risking half — orphan tests, `niterations`, bridge formula constructs, the coverage
pre-run, and the one drmTMB-side routing fix that unlocks the most user-visible capability per line.

## 2. Implemented

- **#465** — six of nine orphan test files wired into `runtests.jl` (+100 assertions), including the
  first tests that actually execute for the Cox–Reid work merged in #451.
- **#466** — `niterations` wired across ~18 family routes; honest `-1` retained where no single
  optimiser call is attributable.
- **#467** — `scale()`, `I()`, `factor()`, `(...)^k` and mechanical `- term` removal landed through
  `engine = "julia"`, each with an R-parity fixture on byte-identical CSV. `poly()` deliberately still
  rejected.
- **#468** — coverage-campaign pre-run: smoke, Totoro + DRAC reachability, D-139 estimates. **Stopped at
  the go/no-go.** No grid run, no fence touched, no coverage claimed.
- **DRM.jl#460 → drmTMB#1080** — profile and bootstrap now accept `fixef:<dpar>:<coef>` targets through
  the bridge; Wald row count reconciled with native drmTMB. PR open, **not merged**.
- **Tooling:** `tools/check_capability_citations.py`, `tools/drmtmb_provenance.R`; ledger countdown fixed.

## 3a. Decisions and Rejected Alternatives

- **`poly()` stays rejected.** R defaults to `raw = FALSE` (QR-orthogonal). A raw-power implementation
  would fit and silently disagree with R. A formula that returns different numbers is worse than an
  honest refusal, so the refusal was sharpened rather than removed.
- **`- term` through an unexpanded `*` stays rejected**, with a new guard that throws: a silent no-op
  there would leave the removed interaction in the Julia model.
- **`niterations` keeps `-1`** where no single `Optim.optimize` call exists. Attributing a seeding run's
  count would be a mismatch dressed as a measurement.
- **Group A re-scoped by reading before dispatching.** Bivariate q=4 REML is already implemented; the
  residual-only REML rejection is *correct statistics* (no random effects ⇒ nothing to restrict) and was
  left alone. Wave 2 is two slices, not four.
- **Did not run the coverage grid, and did not use DRAC to satisfy the instruction to use it.** At this
  grid size Totoro absorbs the whole campaign in ~1 h; DRAC earns its place only if the grid widens.

## 4. Files Touched

`src/` — ~15 family fitters (`niterations` only), `src/bridge.jl`.
`test/` — `runtests.jl`, 6 rewired orphan files, `test_niterations.jl`, 5 new bridge fixtures,
`test/parity/q4-reml/biv-q4-phylo-reml/expected*.toml` (prose only).
`tools/` — `check_capability_citations.py` (new), `drmtmb_provenance.R` (new), `parity_ledger.py`,
`check_test_deps.py`.
`docs/` — `design/capability-status.md`, `dev-log/coordination-board.md`,
`dev-log/evidence/2026-08-24-coverage-prerun.md`, check-log entry.
**drmTMB** — `R/julia-bridge.R` + tests, on a branch only.

## 5. Checks Run

`julia --project=test --startup-file=no test/runtests.jl` · `tools/check_test_deps.py` (OK, 185 files) ·
`tools/parity_ledger.py` (CLOSURE: PASS) · `tools/check_capability_citations.py` ·
`DRM_PARITY_TESTS=1` bridge-formula fixtures (5/5) · drmTMB targeted `testthat` (15 files, 0 failures).

## 6. Tests of the Tests

Both new guards were verified to **fail** on injected drift and pass on restoration —
`check_capability_citations.py` on a broken single citation, a broken range, and a broken list;
`drmtmb_provenance.R --check` on a wrong hash. A guard only ever seen green is an untested guard.

## 7a. Issue Ledger

Opened: #465 #466 #467 #468 #470 #471 #472 #473 #474 #475 #476 #477 #478, drmTMB#1079, drmTMB#1080.
Closed: none — nothing merged.

## 8. Consistency Audit

`supported` was corrected everywhere it had propagated: `parity_ledger.py`, the coordination board, and
Mission Control. Seven stale citations re-pointed, plus two more the guard caught minutes later when the
Wave 1 merges shifted `runtests.jl`.

## 9. What Did Not Go Smoothly

- **I committed twice to `main` without noticing.** The checkout is shared and HEAD moved under me
  between commits. Nothing was lost, but it is exactly the bleed-through D-88 warns about; the commits
  were moved to the lane branch and `main` reset to `origin/main`.
- **My first citation guard produced 13 false positives out of 37** by anchoring on nearby prose tokens.
  Discarded and rewritten to prove-or-skip. Its first "improvement" then added a tight-span check that
  produced another false positive; also removed.
- **I broke a TOML** by embedding double quotes in a double-quoted string, then reached for
  `git checkout --` to fix it. The guard blocked that correctly — it would have discarded work — and the
  file was rebuilt forward from `git show HEAD:`.
- **A subagent audit reported "0 over-claims" and under-reported stale citations** (5 of 6). The
  adversarial pass and the mechanical sweep both found things it missed.
- **`check-after-task.R` reports unapproved gates as UNMET.** It blocks this report on
  `.unlazy/parity-catchup/GATES.md` — the *previous* session's scope, for work already merged — saying
  *"the work is not finished"*. Re-verifying shows `UNMET: 22 (met: 3)`, but every one of the 22 carries
  the reason **"reverify not run"**: `gate-check` refuses to execute a `CHECK:` oracle nobody has
  approved, printing its resolved CWD/SHELL/PATH instead. That refusal is the feature.
  So the message conflates **"not verified"** with **"verified failing"** — in a project whose entire
  discipline is keeping those apart. `--status` says ALL MET (25); `--reverify` says UNMET (22); neither
  number means the merged work is broken. Two of those oracles are full 45-minute suite runs, which is
  why approving them casually is not free either.

## 10. Known Residuals

- **#472** `mstep_Lambda` descends the true marginal at p=100 — real, not shipped-path.
- **#473** `drmTMB 0.7.0` spans ≥16 builds; every banked parity number used the older one.
- **#476** two parity files share `FIXTURE`/`_load_data` in `Main` with *differing* numeric-column sets.
- **#477** `reml_loglik` omits the constant lme4/glmmTMB/TMB include — user-facing.
- **#478** two `claim_boundary` criteria unsatisfiable as written; one rewrite narrows scope → owner call.
- The #468 go/no-go is **unanswered by design**.

## 11. Team Learning

**A note in our own fixture caused an analytical dead end.** It asserted that the two engines restrict
different fixed effects; a promotion analysis read it and concluded REML parity was undefined and the row
permanently unpromotable. Source reading refuted it: both restrict all four axes, and the gap is the
`(n_β/2)·log(2π)` integration constant — 5.5136 predicted against −5.63 measured, with
`julia_converged = false` recorded three lines above the note.

The lesson is not "check fixtures". It is that **a prose note sitting beside correct numbers inherits
their credibility**, and nothing in the DoD gates prose the way it gates code. The numbers were right the
whole time; the sentence next to them was wrong, and the sentence is what everyone downstream read.

## 12. Cross-Product Coverage

**Does NOT cover:** interval coverage (no campaign run — agreement is not calibration, and both
`coverage_claimed` fences are intact); bivariate q=4 fixed-effect profile/bootstrap through the bridge;
`poly()` and `factor()`/`scale()` with non-default arguments; `newdata` prediction for materialised
bridge columns; any capability-row promotion (**none** was promoted); drmTMB `main` (untouched — PR only);
and REML is **not** done — Wave 2 (#470) is the q=2 structured gap.
