# After-Task Report: same-target matrix for the location-scale-scale routes through drm_bridge (#563 S6; closes #546)

- **Date:** 2026-09-02
- **Issue:** #563 slice S6; closes #546 on the DRM.jl side
- **PR:** #596
- **Commit:** `e3327e53`
- **Branch:** `feat/563-s6-bridge-lss`
- **Perspectives:** Shannon (Coordination), Hopper (Payload Shape), Boole (Grammar), Rose (Gate)

## 1. Goal

Determine whether `sd(group)`/`sd_phylo(group)` location-scale-scale routes
actually reach the bridge (`engine = "julia"`) as #546 questioned, and if
so, prove bridge-vs-direct-`drm()` fidelity across ML/REML, the forced
sparse route, and missing responses with a same-target matrix — rather than
writing new routing code before establishing whether any was needed.

## 2. Implemented

- **Recon first** (`scratchpad/s6-recon.md`): established that the bridge
  already routes `sd()`/`sd_phylo()` on `main` — `_bridge_keyed_part()` at
  `src/bridge.jl:683` matches both via
  `occursin(r"^sd(_phylo)?\([^()]+\)$", k)`, the guard's own error message
  at `src/bridge.jl:631` documents both as supported, and
  `_bridge_pick_sd_row()` (`src/bridge.jl:490–510`) selects the
  variance-component row from the result. #527 item 3 (leak-guard error
  MESSAGE assertion) was already present
  (`test/test_gaussian_phylo_mean_missing_response.jl:230`). All five
  drmTMB handoff-memo items relevant to DRM.jl were already closed
  (#594, #593, #590/#589) or noted (capabilities.md). Conclusion: S6
  collapsed from "add routing" to "measure and pin what's already there."
- **`test/test_bridge_lss_routes.jl`** (new, 223 lines per `git show
  e3327e53 --stat`): a same-target matrix, one `@testset` per cell —
  `sd(g)` ML, `sd(g)` REML, `sd_phylo(s)` ML, `sd_phylo(s)` REML, the
  forced sparse route (`algorithm = "sparse"`) at ML and REML, missing
  responses at ML and REML, and #546's unknown-key hazard pinned in both
  formula spellings. **47/47** (`scratchpad/s6-matrix.log`, testset-by-
  testset: sd ML 5/5, sd REML 6/6, sd_phylo ML 5/5, sd_phylo REML 6/6,
  sparse forced route 10/10, missing response 11/11, #546 unknown-key
  4/4 — sums to 47).
- `test/runtests.jl` (+1) wires the new test file in.
- No `src/` change (commit message, PR body: "Test/docs only; no `src/`
  change").

Full diffstat (`git show e3327e53 --stat`, this worktree): 3 files changed,
225 insertions(+): `docs/dev-log/check-log.d/2026-09-02-563-s6-bridge-lss-routes.md`
(+1), `test/runtests.jl` (+1), `test/test_bridge_lss_routes.jl` (+223).

## 3a. Decisions and Rejected Alternatives

- **Measurement over new code.** The recon (`s6-recon.md`) found #546's
  premise — that `sd()`/`sd_phylo()` are "rejected silently or dropped" —
  false on `main`: the routing, the row-selection helper, and the
  fail-closed guard all already existed. Writing a same-target regression
  matrix to prove and pin that fidelity was chosen over implementing
  routing that was not, in fact, missing.
- **Both formula spellings tested for the unknown-key hazard, not just
  one.** The in-file comment (`test/test_bridge_lss_routes.jl:192–199`)
  explains why: a bare semicolon string routes every part positionally
  (`key === nothing` in `_bridge_parse_formula_part`) into `bf(...)`'s own
  guard (`ArgumentError("bf: unknown distributional parameter ...")`),
  while a keyed `Dict`/`NamedTuple` formula reaches
  `_bridge_formula`'s own `"unknown univariate formula part"` guard
  (`src/bridge.jl` ~line 630) — two different code paths that could each
  independently have silently dropped a part; both are exercised so
  neither hazard goes unchecked.
- **The sparse route is forced via `algorithm = "sparse"`/`algorithm in
  (:sparse, :sparse_lbfgs)`**, not exercised only at whatever tree size
  happens to trigger auto-routing — per the in-file comment
  (`test/test_bridge_lss_routes.jl:121–125`), because `_bridge_fit` has no
  dedicated `sparse` option key; the only way to force that route through
  the bridge is via the `algorithm` value it already forwards to `drm(...)`.
- **Missing responses are exercised by handing `data` with `missing`
  values into the same `drm(...)` call the bridge always makes**
  (in-file comment, `test/test_bridge_lss_routes.jl:156–159`) — there is no
  separate `response =` option on the bridge, so the test targets the
  actual mechanism (single observed-rows default) rather than a
  hypothetical dedicated switch.
- **REML-ness is pinned via `reml_loglik(direct)` equality, not a bridge
  `method`/`estimation_method` output key** — the in-file comment
  (`test/test_bridge_lss_routes.jl:75–76`): "The bridge does not surface an
  explicit method/estimation_method key" — the test asserts
  `estimation_method(direct) === :REML` on the direct side and compares
  `out["loglik"]` against `reml_loglik(direct)`, rather than asserting on a
  bridge-side method field that does not exist.
- **Definition-of-Done reports for the three bridge slices merged earlier
  the same day (#590, #593, #594) were folded into this same PR** (PR body,
  item 3) rather than as separate PRs — those three after-task files are
  the companion reports in this same worktree
  (`docs/dev-log/after-task/2026-09-02-563-bridge-base-r-names.md`,
  `...-coef-labels-echo.md`, `...-bridge-objective-at.md`).

## 4. Files Touched

Commit `e3327e53` (`git show e3327e53 --stat`, this worktree):

- `docs/dev-log/check-log.d/2026-09-02-563-s6-bridge-lss-routes.md` (+1)
- `test/runtests.jl` (+1)
- `test/test_bridge_lss_routes.jl` (+223, new file)

3 files changed, 225 insertions(+).

This report (written by Rose, not counted in the commit diffstat above):

- `docs/dev-log/after-task/2026-09-02-563-s6-bridge-lss-routes.md`

(The check-log row for this slice was already written and committed as part
of `e3327e53` itself, per the diffstat above.)

## 5. Checks Run

- **`test/test_bridge_lss_routes.jl`**, 7 testsets, **47/47**
  (`scratchpad/s6-matrix.log`):
  ```
  sd ML bridge vs direct (#563 S6)                                  | Pass 5  Total 5  | 14.4s
  sd REML bridge vs direct (#563 S6)                                | Pass 6  Total 6  | 1.7s
  sd_phylo ML bridge vs direct (#563 S6)                            | Pass 5  Total 5  | 5.8s
  sd_phylo REML bridge vs direct (#563 S6)                          | Pass 6  Total 6  | 5.4s
  sparse bridge vs direct forced route (#563 S6)                    | Pass 10 Total 10 | 1.8s
  missing response bridge vs direct (#563 S6)                       | Pass 11 Total 11 | 0.5s
  #546 unknown univariate formula part key errors loudly (#563 S6)  | Pass 4  Total 4  | 0.6s
  ```
  Sum of the Pass column: 5+6+5+6+10+11+4 = **47**, matching the Total
  column sum exactly — 47/47.
- **Comparison basis**: each bridge-vs-direct cell asserts
  `out["coefficients"] ≈ coef(direct)`, `out["loglik"] ≈
  loglik(direct)`/`reml_loglik(direct)`, and the `sd`/`sd_phylo` coefficient
  block extracted from the bridge payload against `coef(direct, :sd)` /
  `coef(direct, :sd_phylo)`, each at `atol = 1e-8`
  (`test/test_bridge_lss_routes.jl:60–63`, `:80–83`, `:97–100`, `:115–118`,
  `:139–142`, `:152–153`, `:178–179`, `:188–189`), plus `out["converged"]`
  / `is_converged(direct)` on every ML/REML cell.
- **Check-log row** (`docs/dev-log/check-log.d/2026-09-02-563-s6-bridge-lss-routes.md`,
  this worktree): "✅ green; sd()/sd_phylo() × ML/REML, forced sparse route,
  missing response — bridge vs direct `drm()` bit-identical (coef, loglik,
  sd rows, convergence); #546's unknown-key hazard pinned in both the
  string and keyed formula spellings (both throw, never drop); no `src/`
  change" — Shannon (Hopper, Boole).
- **PR body** (`gh api repos/itchyshin/DRM.jl/pulls/596 --jq .body`):
  "coefficients, log-likelihood, sd rows and convergence; **47/47**. ...
  Ledger `.unlazy/563-s6` (local run state), all gates met."

## 6. Tests of the Tests

The #546 unknown-key testset is itself evidence against a specific failure
mode (silent dropping), not a value comparison: it asserts the *type* and
*message content* of the error raised on two structurally different inputs
(a bare semicolon string vs a keyed `Dict`/`NamedTuple` formula), each
routed through a different guard in the code
(`bf`'s `ArgumentError("bf: unknown distributional parameter ...")` for the
positional path; `_bridge_formula`'s `"unknown univariate formula part"`
for the keyed path, `src/bridge.jl` ~line 630) — confirming both hazards
throw loudly rather than silently discarding a formula part, which is
exactly the risk #546 raised. Separately, every bridge-vs-direct cell
compares against `direct = drm(...)` computed independently in the same
test via the ordinary public API, not against a value hardcoded from a
single earlier run — so a regression in either the bridge's parsing/
routing or in `drm()` itself that changed the fitted numbers would show up
as a failed `≈` comparison, not merely a missing feature. See §10 for what
this comparison structure does and does not establish (the "delegates to
`drm()`" caveat).

## 7a. Issue Ledger

- **#546** — closed on the DRM.jl side by this slice. Per the commit
  message: "The bridge's Julia items in #546 (sd/sd_phylo parts,
  `_bridge_pick_sd_row`, fail-closed unknown keys) are all on `main`;
  drmTMB's routing and ledger row belong to the drmTMB lane." I.e. #546's
  premise (silent drop) was found false; what remained was measurement and
  pinning, done here; drmTMB's own routing/ledger-row half is explicitly
  out of scope and not verified by this slice (§10).
- **#527 item 3** — confirmed already present, not newly added:
  `test/test_gaussian_phylo_mean_missing_response.jl:230` already asserts
  `occursin("ROUTE-level", sprint(showerror, err))` on `main`
  (`s6-recon.md` §2). Items 1 and 2 of #527 are R-side (drmTMB), not
  DRM.jl's to close.
- **#563 slice S6** — landed on `feat/563-s6-bridge-lss`, commit
  `e3327e53`, PR #596. Merge is the maintainer's.
- **drmTMB handoff-memo items** (`s6-recon.md` §3, source:
  `origin/claude/rev-parity-drmjl-findings:docs/dev-log/2026-09-02-drmjl-lane-handoff.md`):
  items 1, 2, 4 confirmed DONE (closed as #594, #593, #590/#589
  respectively); item 3 (stale `docs/src/capabilities.md:278-281`) NOTED —
  now correct at line 287; item 5 (q4 REML SE receipt) is drmTMB-side,
  delivered on `claude/rev-parity-q4-se-receipt`, not DRM.jl's to action.
- **Codex ledger leaf G5** (coefficient-labels, `s6-recon.md` §4): G1–G5
  bounded gates met; G5 still needs its own `RESULT.md`, after-task report,
  check-log entry, and Rose/Melissa review receipts — not produced by this
  slice, flagged as a separate open item on the codex ledger, not #563 S6's
  responsibility.

## 8. Consistency Audit

- **Both variance-component route families were checked, not just the
  plain `sd(g)` case #546 named** — `sd(g)` (iid group) and `sd_phylo(s)`
  (phylogenetic) were each exercised at both ML and REML.
- **The forced-sparse route was checked as its own cell**, not assumed
  identical to the dense route by extension — `s6-recon.md` §1 confirms
  `src/gaussian_sparse_lss.jl`'s O(p) sparse routes were "already wired,"
  and this slice adds the bridge-vs-direct comparison on that specific
  route (`algorithm = "sparse"`), which had not previously been checked
  through the bridge (PR body: "Before this, only one `sd(g)` ML case was
  checked through the bridge").
- **Missing-response handling was checked as its own cell**, distinct from
  the fully-observed cells, rather than assumed to inherit correctness.
- **The recon swept beyond the named issue** (#546) to #527 item 3, the
  drmTMB handoff memo's five items, the codex ledger's G5 leaf, the
  `r-julia-bridge.md` documentation claim, and every open `r-bridge`-
  labelled issue (`s6-recon.md` §6: only #546 found, and its routing was
  already implemented) — not a narrow check of #546 alone.

## 9. What Did Not Go Smoothly

- Nothing under this slice's own scope; the recon (`s6-recon.md`) found the
  underlying routing already correct and complete, so the work was
  measurement rather than debugging a defect. The one friction point noted
  in the commit/PR text is upstream and out of scope: drmTMB's own routing
  and ledger row for `location_scale_scale` are not this repository's to
  fix or verify (§10).

## 10. Known Residuals

- **The bridge payload has no `method` key.** REML-ness is inferred
  indirectly, via `reml_loglik(direct)` equality on the Julia side rather
  than a bridge output field a caller could read directly — documented as
  a finding, not fixed here (commit message, in-file comment
  `test/test_bridge_lss_routes.jl:75–76`).
- **`re_sd`/`vc` throw on `sd()` fits by design** — `coef(fit, :sd)` is the
  accessor for the variance-component block, not `re_sd`/`vc` (commit
  message). This is existing, intentional behaviour recorded as a finding,
  not altered by this slice.
- **No dedicated `sparse`/`response` option keys exist on the bridge.**
  The sparse route is reached only by forwarding `algorithm` through to
  `drm(...)`; missing responses are reached only by passing `data`
  containing `missing` values into the same `drm(...)` call the bridge
  always makes — there is no separate switch for either on the bridge
  payload (commit message; in-file comments §3a).
- **The drmTMB-side routing/ledger row for `location_scale_scale` is not
  verified by this slice.** The commit message is explicit: "drmTMB's
  routing and ledger row belong to the drmTMB lane." This report makes no
  claim about that repository's state.
- **All bridge-vs-direct deltas were exactly 0.0** in practice, per the
  coordinator's brief for this slice — because `drm_bridge` delegates
  internally to `drm()` for the actual fit (same code path, same call),
  the comparison proves **plumbing fidelity** (the bridge parses the
  payload into the same call `drm()` would receive directly, and returns
  the same numbers back out) — it is **not an independent oracle** on
  whether those fitted numbers are themselves correct against any external
  reference (e.g. drmTMB/R). The test file's own asserted tolerance is
  `atol = 1e-8` (§5); this report does not independently re-derive a
  literal 0.0 figure from a source it read, and states the distinction
  (plumbing fidelity vs. correctness oracle) plainly rather than
  conflating the two.
- **G5 of the codex coefficient-labels ledger leaf remains open**
  (`s6-recon.md` §4): its own `RESULT.md`, after-task report, check-log
  entry, and Rose/Melissa review receipts are not produced by this slice.

## 11. Team Learning

- **Recon before code**: when an issue's premise ("X is rejected/dropped")
  can be checked directly against the current source before writing any
  fix, do that first. Here the premise was false on `main`, and the actual
  gap was regression coverage, not routing — writing routing code first
  would have been wasted or duplicative work.
- **A bridge-vs-direct comparison where the bridge delegates to the same
  underlying call proves plumbing fidelity, not correctness against an
  external oracle** — worth stating explicitly in the report whenever this
  comparison shape is used, so a reader does not mistake "bit-identical to
  direct `drm()`" for "verified correct against drmTMB/R."
- **When a hazard has two structurally different trigger paths (here, a
  positional string vs. a keyed Dict formula, each hitting a different
  guard), test both explicitly** rather than assuming a fix or an existing
  guard on one path covers the other.

## 12. Cross-Product Coverage

This slice touches the **location-scale-scale (`sd()`/`sd_phylo()`) routes
reachable through `drm_bridge`**, across ML/REML, dense/forced-sparse, and
fully-observed/missing-response axes, for the Gaussian family.

- **Covers ✓**: `sd(g)` ML/REML, `sd_phylo(s)` ML/REML, the forced sparse
  route (`algorithm = "sparse"`) at ML/REML, missing responses at ML/REML,
  and #546's unknown-key hazard in both the bare-string and keyed-formula
  spellings — all bridge-vs-direct bit-identical (47/47) for coefficients,
  log-likelihood, `sd`/`sd_phylo` coefficient blocks, and convergence.
- **Does NOT cover ✗**: **non-Gaussian LSS** — none exists to cover; #202
  (the phylogenetic location-scale model this bridges toward) is
  Gaussian-only, so there is no non-Gaussian LSS surface for this matrix to
  have omitted. **Multi-component `sd()` (lsss, #555)** — not in this
  matrix; only single-component `sd(g)`/`sd_phylo(s)` cells are exercised.
  **Bootstrap/profile through the bridge on LSS fits** — not covered; this
  slice checks point estimates, log-likelihood, and convergence only, not
  inference (SEs, confidence intervals, bootstrap or profile-likelihood
  paths) on any LSS route reached via the bridge. **drmTMB's own routing
  and ledger row for `location_scale_scale`** — explicitly out of scope,
  belongs to the drmTMB lane (§10).

## Memory receipt

No new hub `AGENTS.md` guard was added or consulted for this slice beyond
the after-task protocol (`~/shinichi-brain/protocols/after-task.md`) used
for the companion #575 and #563 reports in this session. All numbers in
this report are copied from `git show e3327e53 --stat` and its commit
message (run in this worktree), `gh api repos/itchyshin/DRM.jl/pulls/596
--jq .body`, the check-log row
(`docs/dev-log/check-log.d/2026-09-02-563-s6-bridge-lss-routes.md`),
`scratchpad/s6-matrix.log`, `scratchpad/s6-recon.md`, and direct reads of
`test/test_bridge_lss_routes.jl` (all cited inline above).
