# After-task: sparse-LSS profile data race — never return an infinite bound from a failed endpoint (#633, closes #631)

Date: 2026-09-04 · PR [#633](https://github.com/itchyshin/DRM.jl/pull/633) OPEN, not yet merged · branch pushed to `origin`, head commit `c2b81421d` ("fix(profile): never return an infinite bound from a failed endpoint, and fix the sparse-LSS data race that caused it", closes #631) · base `main`

Perspectives: Rose (after-task QA, this report only). No subagents.

## 1. Goal

Document, for the record, the fix for #631 (Julia profile CI silently returning
infinite bounds above ~500 species): a `Core.Box` shared between a destructured
`â` and its own `eval_core` closure in `_fit_phylo_gaussian_lss_sparse` made the
fit's stored objective/gradient thread-unsafe, and this closes the Definition-of-
Done documentation debt for #633.

## 2. Implemented

Nothing new in this report beyond what #633 already contains (PR still open,
not merged, as of this pass):

- `src/gaussian_sparse_lss.jl`: renamed the destructured latent-mean variable
  from `â` to `â_hat`, unboxing it from the `Core.Box` it previously shared
  with the `eval_core` closure's own assignment to `â` in the same scope —
  the root cause. This is the **second instance of this defect class**
  (#549 was the first, a variable named `V`); a same-class sweep is noted as
  in progress.
- `src/inference.jl`: `confint(...; method = :profile)` now **raises** an
  `ArgumentError` naming the coefficient, the failed arm, and the nuisance
  failure reason, instead of warning and returning a signed infinity.
  `profile_result` is unchanged and remains the auditable surface, still
  carrying ±Inf beside the endpoint-failed flags.
- `src/bridge.jl`: `drm_bridge_inference(...; method = "profile")` — the path
  R takes for `engine = "julia"` — now raises rather than returning a payload
  with infinite bounds under `conf.status = "profile_failed"`; a backstop in
  `_bridge_inference_flatten` refuses such a row however it arises.
- `test/test_profile_infinite_bound.jl`, `test/test_profile_nuisance_status.jl`,
  `test/test_locscale_profile_status.jl` (new): `#631 profile CI never returns
  an infinite bound from a failed endpoint` 218/218 and `#631 the R bridge
  cannot present an infinite bound as a profile` 3/3, plus 35 neighbour files
  covering profiles, the bridge, the sparse routes, bootstrap, and the API
  freeze gate.
- `test/runtests.jl`: wired the new files in.

## 3a. Decisions and Rejected Alternatives

- **Diagnosed as a data race, not a solver failure, before attempting a fix.**
  Measured at 600 tips: 122 of 300 concurrent objective pairs disagreed with
  the serial value, by up to 2.0e-2 in the objective and 7.4e-1 in the
  gradient. CHOLMOD was exonerated (0/300 disagreements on the same
  matrices), and so was BLAS threading (the race persisted with BLAS pinned
  to one thread). A runtime box scan named `â` directly and confirmed it gone
  after the rename. Rejected: patching the endpoint search's failure handling
  without fixing the underlying corruption — that would have hidden the
  symptom (±Inf) while leaving the concurrent-corruption mechanism intact,
  meaning a converged-but-wrong finite bound could still occur.
- **The trigger is the sparse route with threading, not the tip count** —
  established by four targeted probes: forcing `sparse = true` at 400 tips
  reproduces it; 500 tips on the dense route does not; 600 tips with
  `threads = false` does not. The ~500-species boundary is incidental (that
  is where `drm()` auto-dispatches to the sparse LSS engine), not causal.
  Rejected: describing this as a "large tree" bug — the PR body is explicit
  that tip count alone is not the trigger.
- **Raise rather than warn-and-return-Inf, on both `confint` and the R-facing
  bridge.** A profile endpoint that could not be certified is now refused,
  not silently handed back as a number a caller could mistake for a real
  bound. `profile_result` was deliberately left returning ±Inf, since it is
  the auditable/diagnostic surface, not the CI-reporting one — the fix
  changes what a caller is handed by default, not what is recorded.
  A genuinely unbounded profile is a different, honest case and still
  returns with status `"profile"` rather than being conflated with a failed
  arm.
- **Named as the second instance of this defect class**, citing #549 (a
  variable named `V`) as the first, and explicitly notes a same-class sweep
  is in progress rather than treating this fix as having closed the whole
  class.
- **Rejected: re-running the reporter's exact R-side call** to close the loop
  end-to-end — the installed drmTMB 0.7.0 refuses her
  `sd(species, level = "phylogenetic")` formula on the Julia engine, and her
  run used a newer dev build; reported as not covered rather than worked
  around with a different formula that wouldn't actually match her case.

## 4. Files Touched

By #633 (head commit `c2b81421d`, not yet merged):
- `src/bridge.jl`
- `src/gaussian_sparse_lss.jl`
- `src/inference.jl`
- `test/runtests.jl`
- `test/test_locscale_profile_status.jl` (new)
- `test/test_profile_infinite_bound.jl` (new)
- `test/test_profile_nuisance_status.jl` (new)

By this after-task pass (docs only, this worktree):
- `docs/dev-log/after-task/2026-09-04-profile-data-race-633.md` (this file)
- `docs/dev-log/check-log.d/2026-09-04-profile-data-race-633.md`

## 5. Checks Run

- `gh pr view 633 -R itchyshin/DRM.jl --json title,body,mergeCommit,state` —
  confirmed **OPEN**, `mergeCommit: null` as of this pass (2026-09-04). This
  report describes work complete on the branch but not yet landed on `main`.
- `gh pr diff 633 -R itchyshin/DRM.jl --name-only` — confirmed the 7-file
  change list matches the PR body's description.
- `git fetch origin pull/633/head:pr633` + `git log --oneline pr633 -3` —
  confirmed head commit `c2b81421d` on top of `301121287` (#630's merge).
- Every number in §2/§3a (122/300, 2.0e-2, 7.4e-1, the 400/500/600-tip
  probe grid, 218/218, 3/3, the 2.8e-6/2.0e-6 oracle agreement) is copied
  verbatim from the PR body (`gh pr view 633 ... --json body`), not
  recomputed in this pass.
- `Rscript ~/shinichi-brain/tools/check-after-task.R
  docs/dev-log/after-task/2026-09-04-profile-data-race-633.md` (run directly
  on this file, from a neutral directory with no `.unlazy/` ledgers in
  scope — result below).

Not run in this pass (docs-only lane; forbidden from touching `src/`/`test/`):
`Pkg.test()`, the 218-test and 3-test files, the concurrency probe, or the R
`tmbprofile` oracle comparison.

## 6. Tests of the Tests

Not applicable to this pass — no code changed here. As reported in the PR
(not reproduced by this pass): explicit RED-first evidence — the new test
file gave 180 passed / 38 failed on `origin/main` before the fix, including
`Evaluated: -Inf == -0.47713193422709044`, i.e. a test that fails exactly the
way the bug manifests. GREEN after: `#631 profile CI never returns an
infinite bound from a failed endpoint` 218/218 and `#631 the R bridge cannot
present an infinite bound as a profile` 3/3, plus 35 neighbour files.

## 7a. Issue Ledger

- **#631** — closed by this PR's commit message ("closes #631"), pending the
  PR actually merging (currently OPEN, `mergeCommit: null`).
- **#549** — referenced as the first instance of this defect class (a shared
  `Core.Box` from a variable named `V`); not reopened by this PR, cited as
  precedent. A same-class sweep across the codebase is noted as in progress
  in the brief — not confirmed complete by this report.
- Ayumi-495/LS_ecogeographical-rules#28 — the collaborator's reported
  symptom (a whole-tree profile CI returning ±Inf) traces to this defect;
  see the lane-state note for the collaborator-facing correction posted
  there (the guide's own profile example passed `threads = TRUE`, exposing
  readers who followed it literally to the race).

## 8. Consistency Audit

- Checked that "the trigger is the sparse route with threading, not the tip
  count" is stated plainly rather than left implicit in a tip-count framing —
  confirmed in both the PR title/body and §3a above.
- Checked that `profile_result` vs `confint`/bridge-inference is described
  consistently as two different surfaces with two different (deliberate)
  behaviours, not as one bug with one fix.
- Checked the "second instance of this defect class" claim against #549 —
  the PR body itself draws the direct parallel (variable name `â` here,
  `V` in #549), both a shared `Core.Box` from destructuring inside a scope
  that also has a closure assigning the same name.
- Checked PR state again at write time rather than assuming merged from the
  brief's framing — confirmed OPEN, recorded as such in §5 and the header.

## 9. What Did Not Go Smoothly

- `test_profile_sigma_a.jl` and `test_bridge_bivariate_inference.jl` were
  each aborted after ~25 minutes locally; the PR body states neither calls
  `confint`, `profile_result`, or the bridge inference flattener, so the
  diff cannot reach them — but their runtime was **not confirmed against
  `origin/main`**, so a slowdown unrelated to this fix cannot be ruled out
  by this report.
- No R end-to-end re-run of the reporter's exact call was possible: the
  installed drmTMB 0.7.0 refuses her `sd(species, level = "phylogenetic")`
  formula on the Julia engine, and her run used a newer dev build.
- `test/test_lss_sparse.jl:253-255` still carries a tolerant assertion
  written around this bug before it was understood; the PR body flags
  tightening it as a reasonable follow-up rather than doing so in this PR.

## 10. Known Residuals

- **PR #633 is not yet merged** (OPEN as of this pass). #631 is not actually
  closed until this lands.
- `test_profile_sigma_a.jl` and `test_bridge_bivariate_inference.jl` runtime
  (~25 min aborts) unconfirmed against `origin/main` — could be pre-existing
  or a regression; not distinguished by this report.
- No R end-to-end re-run of the reporter's exact call — blocked by an
  installed drmTMB version mismatch, not by anything in this PR's control.
- `test/test_lss_sparse.jl:253-255`'s tolerant assertion (written around this
  bug) not tightened — left as a follow-up.
- The "same-class sweep" for other shared-`Core.Box` closures (the #549/#631
  pattern) is described as in progress, not complete; this report does not
  claim the class is closed.

## 11. Team Learning

Memory receipt: read the repo's `HANDOVER.md`/`AGENTS.md` conventions
(license boundary, ML-default, `sigma` not `tau`) as LOAD-FIRST; no
cross-repo scouting needed for a docs-only after-task pass. Durable lesson
for the next agent: **a destructured variable and a closure defined in the
same scope that both write the same name become one shared `Core.Box` in
Julia** — this is now a confirmed recurring defect class (#549, #631), so
any new closure-capturing fit routine should be checked for this pattern
specifically, not just reviewed generically for thread-safety. Golden Set:
this is exactly the kind of known-mistake class the after-task protocol asks
to check against — the PR body itself names the precedent (#549) and a sweep
is in progress; this report does not re-run that sweep (docs-only scope) but
flags it as an open item in §10 rather than letting it go unrecorded.

## 12. Cross-Product Coverage

The cross-cutting surface here is the sparse LSS fit's stored
objective/gradient closures — every threaded consumer of a
`_fit_phylo_gaussian_lss_sparse` fit was exposed to the same race, not only
`confint`.

**Covers:** `confint(...; method = :profile)` (raises on a failed arm rather
than returning ±Inf); `drm_bridge_inference(...; method = "profile")` (raises,
with a backstop in `_bridge_inference_flatten` refusing an infinite-bound row
however it arises); `profile_result` (unchanged, remains the auditable ±Inf
surface); correctness re-verified against a `tmbprofile` oracle on the same
tree (2.8e-6 / 2.0e-6 agreement, 67.2 s oracle run); post-fix concurrency
(0/300 disagreements at 600 and 1,000 tips, threaded profile bit-identical to
serial at both sizes); 35 neighbour test files across profiles, the bridge,
the sparse routes, bootstrap, and the API freeze gate, all green.

This slice does NOT cover: `test_profile_sigma_a.jl` and
`test_bridge_bivariate_inference.jl` — aborted after ~25 min each, runtime
unconfirmed against `origin/main`; an R end-to-end re-run of the reporter's
exact call — blocked by an installed drmTMB version mismatch; the tolerant
assertion at `test/test_lss_sparse.jl:253-255`, left untightened; the
same-class sweep for other shared-`Core.Box` closures elsewhere in the
codebase, described as in progress, not complete; and merge/landing status —
#633 is OPEN, not merged, as of this report, so #631 is not yet actually
closed.

## Rose audit (claim-vs-evidence)

| Check | Verdict |
|---|---|
| PR state is OPEN, not merged | **PASS** — `gh pr view --json state,mergeCommit` returned `OPEN` / `null` |
| Root cause is a shared `Core.Box` from `â` destructuring + `eval_core` closure | **PASS** — PR body's "Cause" section |
| 122/300 concurrent objective pairs disagreed at 600 tips, up to 2.0e-2 / 7.4e-1 | **PASS** — verbatim from PR body |
| Trigger is sparse+threading, not tip count (400/500/600-tip probes) | **PASS** — verbatim from PR body |
| `confint`/bridge raise; `profile_result` still returns ±Inf | **PASS** — PR body's "What a user sees now" section |
| Oracle agreement 2.8e-6 / 2.0e-6 vs `tmbprofile` | **PASS** — verbatim from PR body |
| Post-fix concurrency 0/300 at 600 and 1000 tips, bit-identical threaded vs serial | **PASS** — verbatim from PR body |
| Second instance of this defect class (#549 precedent) | **PASS** — PR body draws the explicit parallel |
| `test_profile_sigma_a.jl` / `test_bridge_bivariate_inference.jl` aborted, unconfirmed runtime | **PASS** — PR body's "Not covered" section |
| No R end-to-end re-run (drmTMB 0.7.0 formula refusal) | **PASS** — PR body's "Not covered" section |

**Rose verdict: PASS** — scope honest; PR's own text already states every
residual listed above without prompting; this report adds only the
merge-status caveat the brief required be checked live.

*Rose.*
