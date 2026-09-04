# After-task: bridge option passthrough — sparse forwarded, unknown keys refused (#632)

Date: 2026-09-04 · PR [#632](https://github.com/itchyshin/DRM.jl/pull/632) OPEN, not yet merged · branch pushed to `origin`, head commit `80d42caa8` ("feat(bridge): forward optimizer/control options and expose the stored gradient", refs #527) · base `main`

Perspectives: Rose (after-task QA, this report only). No subagents.

## 1. Goal

Document, for the record, the two remaining joint items from a collaborator's
friction list (Ayumi-495/LS_ecogeographical-rules#28): (a) reach the `robust`
optimizer preset from R, and (b) expose Julia's internal gradient through the
bridge. This report closes the Definition-of-Done documentation debt for #632,
which addressed both — reporting one as ill-posed and fixing a worse defect
found underneath it.

## 2. Implemented

Nothing new in this report beyond what #632 already contains (PR still open,
not merged, as of this pass):

- `src/bridge.jl`: `options[:sparse]` is now forwarded to the native fit
  (Bool-validated, not coerced) instead of being silently dropped by
  `_bridge_fit`. A known-key set (`_BRIDGE_KNOWN_OPTION_KEYS`, including
  `coef_labels` — consumed by `drm_bridge` itself, not forwarded as a `drm(...)`
  kwarg, but still a real key on the same options dict) backs a fail-closed
  `ArgumentError` naming any unrecognised key. `"gradient"`
  (`Vector{Float64}`, one entry per coefficient) and `"gradient_names"`
  (`Vector{String}`, same order as `coef_names`) are returned only when the fit
  carries a gradient closure — omitted, not zero/NaN-filled, matching how
  `reml_loglik` behaves after #625.
- `test/test_bridge_option_passthrough.jl` (new): 16/16 tests — unknown key
  errors and names itself; loose vs tight tolerance changes reported
  iterations; `sparse = true/false` both match the native fit's coefficients
  and log-likelihood; a non-Bool `sparse` errors on type; the gradient is
  present, finite, correctly named, and matches the native gradient to 1e-10;
  the gradient is absent on a route that has none.
- `test/runtests.jl`: wired the new file in.

## 3a. Decisions and Rejected Alternatives

- **One of the two requested items was ill-posed, and this is reported
  honestly rather than invented around.** There is no `robust` optimizer
  preset anywhere in the native `drm(...)` API — the word appears only in
  internal comments describing an automatic E-step fast-path/
  Levenberg-Marquardt fallback, never as a user-selectable knob on either
  side. Rejected: inventing a `robust` preset to satisfy the letter of the
  request. Instead the PR states plainly that this item cannot be fixed as
  scoped, because there is nothing on the native side to forward.
- **The real, more consequential gap found during scope-establishment:**
  `sparse::Bool` — the documented alias for forcing the O(p) sparse engine on
  large phylogenetic fits, exactly the control an R user at ~11,000 species
  would reach for — was accepted natively but silently dropped by
  `_bridge_fit`. This was chosen as the item actually worth fixing over the
  `robust` request, since the friction report's intent (control-symmetry
  between engines) is better served by fixing a real silent-drop than by
  fabricating a preset that doesn't exist upstream.
- **Fail-closed unknown-key validation was added even though it wasn't
  explicitly requested**, because `_bridge_fit`'s options ladder had no such
  check at all — an unrecognised key (typo or not-yet-wired) was silently
  ignored rather than erroring, the same silent-wrong-thing class as the
  estimator gap fixed in #625. Rejected: leaving this out as scope creep —
  the PR body frames it as "worse, and not what the brief assumed" rather
  than an unrelated addition.
- **Gradient omitted rather than zero/NaN-filled when absent**, matching the
  `reml_loglik` convention established in #625, rather than introducing a new
  convention for missing bridge fields.
- **One regression found and fixed during neighbour verification**: the new
  known-key check initially rejected `coef_labels` (a key the bridge consumes
  itself, not one it forwards to `drm(...)`), which broke the base-R naming
  tests. Fixed by adding `coef_labels` to the known-key set rather than
  special-casing it outside the check.

## 4. Files Touched

By #632 (head commit `80d42caa8`, not yet merged):
- `src/bridge.jl`
- `test/runtests.jl`
- `test/test_bridge_option_passthrough.jl` (new)

By this after-task pass (docs only, this worktree):
- `docs/dev-log/after-task/2026-09-04-bridge-option-passthrough.md` (this file)
- `docs/dev-log/check-log.d/2026-09-04-bridge-option-passthrough.md`

## 5. Checks Run

- `gh pr view 632 -R itchyshin/DRM.jl --json title,body,mergeCommit,state` —
  confirmed **OPEN**, `mergeCommit: null` as of this pass (2026-09-04). This
  report describes work that is complete on the branch but not yet landed on
  `main`; the check-log/after-task entries are written now per the brief but
  the PR's merge status must be re-checked before treating #632 as closed.
- `gh pr diff 632 -R itchyshin/DRM.jl --name-only` — confirmed the 3-file
  change list matches the PR body's description.
- `git fetch origin pull/632/head:pr632` + `git log --oneline pr632 -3` —
  confirmed head commit `80d42caa8` on top of `301121287` (#630's merge),
  consistent with #632 having been branched after #630 landed.
- Every number in §2/§3a is copied verbatim from the PR body (`gh pr view 632
  ... --json body`), not recomputed in this pass.
- `Rscript ~/shinichi-brain/tools/check-after-task.R
  docs/dev-log/after-task/2026-09-04-bridge-option-passthrough.md` (run
  directly on this file, from a neutral directory with no `.unlazy/`
  ledgers in scope — result below).

Not run in this pass (docs-only lane; forbidden from touching `src/`/`test/`):
`Pkg.test()`, the 16-test file itself, or the neighbour-family suites the PR
body reports as green (bridge primitive boundary, formula labels, coef_labels
echo, direct-export suites, `objective_at`, profile, S6 route matrix, #624
REML contract).

## 6. Tests of the Tests

Not applicable to this pass — no code changed here. As reported in the PR
(not reproduced by this pass): RED-first discipline was followed — the PR
body states the new test file was written and run RED before the fix, then
reached 16/16 GREEN after. That is evidence the tests can fail (they did,
against the unfixed code) before they were made to pass, and one genuine
regression (the `coef_labels` rejection) was caught by the neighbour suite
during the same pass, not invented after the fact.

## 7a. Issue Ledger

- **#527** (referenced in the head commit message, "refs #527") — not closed
  by this PR; the PR body explicitly states "This closes no part of #527 —
  those three arms are R-side or an unrelated test assertion, thematically
  adjacent only."
- **#625** — referenced as the precedent for the gradient-omission convention
  and the silent-wrong-thing defect class; not reopened or touched by #632.
- Ayumi-495/LS_ecogeographical-rules#28 — the collaborator friction report
  this PR responds to two items from; see the lane-state note for the
  collaborator-facing corrections posted there.

## 8. Consistency Audit

- Checked that the `robust`-preset non-finding is stated as a finding, not
  smoothed over — confirmed in both the PR title/body and §3a above.
- Checked whether other Gaussian-route control kwargs needed the same
  passthrough fix — the PR body states every other control kwarg (`g_tol`,
  `algorithm`, `method`, `se`, `profile_ci`, `phylo_coupled`, and the q4
  route's `q4_g_tol`/`q4_iterations`/`q4_n_newton`/`q4_vcov`) was already
  forwarded; `sparse` was the one gap.
- Checked the gradient-omission convention against #625's `reml_loglik`
  precedent for consistency — same pattern (omit, don't fill).
- Checked PR state again at write time (`gh pr view`) rather than assuming
  merged from the brief's framing — confirmed OPEN, recorded as such in §5
  and the header rather than silently treated as landed.

## 9. What Did Not Go Smoothly

- The `robust`-preset request could not be satisfied as literally stated;
  establishing that required a repo-wide grep for "robust" across `origin/main`
  before the PR could even scope correctly, which the PR body reports doing.
- A real regression (rejecting `coef_labels`) surfaced only during neighbour
  verification, after the primary feature work looked complete — a reminder
  that a new fail-closed check needs its own negative-space check against
  keys the codebase already uses internally.
- This after-task pass cannot itself confirm the PR is merged — `gh pr view`
  returned OPEN / `mergeCommit: null` at write time, so the "state per gh"
  instruction in the brief is recorded honestly as still-open rather than
  assumed merged.

## 10. Known Residuals

- **PR #632 is not yet merged** (OPEN as of this pass). Nothing in this
  report should be read as confirming it landed on `main`.
- #527 remains open; three arms untouched by this PR (R-side or an
  unrelated test assertion).
- No full `Pkg.test()` was run for #632 itself (per its own PR body — "nothing
  in the diff touches non-bridge paths, and CI covers it"); this after-task
  pass does not add one, per its own docs-only scope.
- `sparse` remains meaningful only on phylogenetic/LSS Gaussian routes with a
  tree; it is a silent no-op elsewhere, matching native behaviour but a
  documented surprise risk for a caller who doesn't know that.

## 11. Team Learning

Memory receipt: read the repo's `HANDOVER.md`/`AGENTS.md` conventions
(license boundary, ML-default, `sigma` not `tau`) as LOAD-FIRST; no
cross-repo scouting needed for a docs-only after-task pass. Durable lesson:
**when a friction report names two items, verify each is actually reachable
in the native API before scoping the fix** — the `robust` item here was a
comment-only artifact, and reporting that honestly (rather than inventing a
preset) was the correct call; the real defect found by that same scoping
pass (`sparse` silently dropped, no fail-closed key check at all) was more
consequential than either originally-requested item. Golden Set: not
applicable — documentation-only pass, no code changed.

## 12. Cross-Product Coverage

The cross-cutting surface here is the bridge's `options` dict passthrough —
every keyword a caller passes to `drm_bridge_fit`/`drmTMB(..., engine =
"julia")` now goes through one fail-closed known-key gate, and the returned
payload can now carry a gradient.

**Covers:** `sparse::Bool` forwarding (validated, not coerced) on Gaussian
phylogenetic/LSS routes; fail-closed rejection of any unrecognised options
key across the bridge (not just `sparse`); `gradient` +
`gradient_names` returned when the underlying fit carries a gradient closure,
matching the `reml_loglik` presence/absence convention from #625; the
existing forwarded kwargs (`g_tol`, `algorithm`, `method`, `se`, `profile_ci`,
`phylo_coupled`, `q4_g_tol`, `q4_iterations`, `q4_n_newton`, `q4_vcov`)
re-verified against the new known-key gate without regression, apart from the
one `coef_labels` fix already noted.

This slice does NOT cover: a `robust` optimizer preset (does not exist
natively — not a gap this PR could close); #527 (three arms, R-side or
unrelated, explicitly untouched); routes with no gradient closure (gradient
fields are absent there by design, not an oversight); non-bridge callers of
the same options (native `drm(...)` callers were already correct; only the
bridge had the drop/no-check defects); and merge/landing status — #632 is
OPEN, not merged, as of this report.

## Rose audit (claim-vs-evidence)

| Check | Verdict |
|---|---|
| PR state is OPEN, not merged | **PASS** — `gh pr view --json state,mergeCommit` returned `OPEN` / `null` |
| `robust` preset does not exist natively | **PASS** — PR body's own scope-establishment section |
| `sparse::Bool` was silently dropped pre-fix | **PASS** — PR body |
| No fail-closed check on unknown option keys pre-fix | **PASS** — PR body |
| 16/16 new tests, RED before GREEN | **PASS** — PR body |
| Gradient omitted (not zero/NaN-filled) when absent, matching #625 | **PASS** — PR body |
| `coef_labels` regression found and fixed during neighbour verification | **PASS** — PR body |
| #527 not closed by this PR | **PASS** — PR body's own "Not covered" section |

**Rose verdict: PASS** — scope honest; PR's own text already states the
`robust` non-finding and the #527 non-closure without prompting; this report
adds only the merge-status caveat that the brief required be checked live.

*Rose.*
