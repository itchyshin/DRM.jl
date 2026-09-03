# Session Handoff: DRM.jl overnight #563 lane, 2026-09-02 → 03 (draft — merge table to be finalised)

Meta: drafted 2026-09-02 late / 2026-09-03 early, by Rose (handover QA), Claude. Standing
approvals: [[DECISIONS#D-209|D-209]] (Shinichi, 2026-09-02, "run autonomously till then and if
you need any approvals ask me now"). This note is a DRAFT: the merge table's check-state and
merged-sha columns are placeholders for the conductor to fill once each PR's current-head checks
are read.

## 1. State of the programme (#563) at hand-off

The #563 true-parity programme (R → Julia, one-directional, D-203) ran unattended overnight under
the lane kit at `~/local-scratch/lanes/DRM.jl-overnight-20260902/LOOP/`. The programme ledger
(`.unlazy/julia-r-parity`, scope `julia-r-parity`) moved **152/43 → 163/32** met/unmet gates across
the night (S9 oracle pass: 152/43 → 160/35; S10 oracle pass: 160/35 → 161/34; S12 harness +
sweep closed further leaves to 163/32 per `checkpoint.md`'s final line — the exact intermediate
arithmetic is recorded leaf-by-leaf in issues #606/#609 and PR bodies, not re-derived here).

**Landed and verified tonight** (git log, Totoro logs, local test runs — see PR list, §2):
S7(b) sparse multi-component LSS engine complete, including the S7b.6 fix for the p^2.7 wall-time
defect (root cause: the public router densified the phylo correlation before choosing the sparse
route; fixed with a lazy-K marker; RED 25.79× ratio → GREEN 1.83× ratio; Totoro full suite passed
on the fixed head, 443 test-set summaries, `SUITE_EXIT=0`); the #573/#574 guard-vs-#461 contract
decided (D-211: guard is right, test updated); #578 closed by a RED-first test (missing-response
mask consistency in `_reml_border_blocks`); LogNormal structured markers on the mean via
Gaussian-on-log(y) delegation; S9 Experimental-labelling docs; S9/S10 receipt regeneration against
current `src/`; an S11 q4 REML vcov pinning test + `[se]` provenance note; an S12 warm-timing
harness + registry with its first sweep (all 10 registered workflows win at 1/2/4/8 threads,
smallest margin 1.3×). Codex PRs #567 and #571 merged cleanly to `origin/main` (heads `d388d690`,
`501fa666`) on Shinichi's D-209 standing merge authority — all checks green on their heads at
merge time per `checkpoint.md`.

**Measured-but-failing** (real, not defect-of-measurement, per the S9/S10 oracle runs and the
scout notes read for this handover): S9 native-uncertainty Gaussian conditional mean off by
`8.6e-4` against a `1e-6` threshold (issue #606); three S9 precision leaves (`joint-fit-parity`,
`joint-public-fit`, `r-joint-native`) carry an already-measured Bernoulli `native_theta` delta of
`1.0015e-5`, above the `4e-6` parity bar (same issue, `s9-classification.md`); S10 prediction
parity fails for the `factors` case (`PREDICTION_CONTRACT_FAIL`, issue #609); S10 varying-scale
conditional-components fit parity fails at the `newdata` extrapolation point (`1.086e-05` vs
`4e-6`, diagnosed in `scratchpad/s10-varying-scale.md` as an LBFGS-tolerance gap, not a formula
bug — same issue #609); S11 q4 REML fixed-effect Wald SE remains `wald_unavailable` (bridge
returns all-NaN; drmTMB returns finite; root cause not yet pinned — `scratchpad/s11-inference.md`
§3 step 3).

## 2. Merge table (placeholders for the conductor)

Every row below is this lane's own PR, or a sibling-lane (Codex) PR the lane was pre-authorised to
merge (D-209 §1). `<<fill>>` marks what the conductor fills in after re-reading each PR's current
head.

| # | Branch | Slice | What it is | Head sha (as read tonight) | Check state | Merged sha |
|---|---|---|---|---|---|---|
| #610 | `feat/563-s7b-lss-sparse-multi` | S7(b) | Sparse multi-component LSS engine (O(p), one phylo + nested iid components) | `8da629ef` | `<<fill>>` | `<<fill>>` |
| #574 | `codex/loconly-numerical-boundary` | A2 | Resolvable-scale guard for `location_only.jl`; #461 test updated per D-211 | `aaecac45` | `<<fill>>` | `<<fill>>` |
| #573 | `codex/julia-bridge-route-diagnostic` (stacked on #574) | A2 | Bridge route-aware convergence diagnostics; retarget to `main` after #574 merges | `04e3e5d1` | `<<fill>>` | `<<fill>>` |
| #607 | `test/578-q4-reml-missing-response` | A3/S8 | RED-first test: missing-response mask consistency in `_reml_border_blocks` (closes #578) | `55e2f803` | `<<fill>>` | `<<fill>>` |
| #608 | `feat/563-lognormal-structured-mean` | A3/S8 | LogNormal phylo/relmat structured markers on the mean, via Gaussian-on-log(y) delegation | `2c9452dc` | `<<fill>>` | `<<fill>>` |
| #605 | `docs/563-s9-experimental-labels` | A4/S9 | Label exported joint missing-predictor routes Experimental under the D-181 fence | `e976f51e` | `<<fill>>` | `<<fill>>` |
| #612 | `evidence/563-receipts-regen` | A5/S10 | Regenerate S9/S10 programme receipts against current `src/` (closes stale-baseline leaves for #606/#609) | `da54cd11` | `<<fill>>` | `<<fill>>` |
| #611 | `fix/563-s11-q4-reml-vcov` | A6/S11 | Pin q4 REML `vcov()` behaviour (native finite/PD; bridge NaN by documented default) + `[se]` provenance note | `99a03cd7` | `<<fill>>` | `<<fill>>` |
| #613 | `feat/563-s12-warm-timing-harness` | A7/S12 | Matched warm-timing harness + registry; first sweep (10/10 workflows win at 1/2/4/8 threads) | `e2a80c2c` | `<<fill>>` | `<<fill>>` |
| #567 | `codex/sigma-phylo-inference-contract` | sibling | Retain location-scale SD inference targets — **already merged** | `6d030a98` (PR head) | MERGED (`d388d690` on main) | `d388d690` |
| #571 | `codex/profile-thread-fit-budget` | sibling | Stabilize public LSS fit before threaded profiling — **already merged** | `028b7661` (PR head) | MERGED (`501fa666` on main) | `501fa666` |
| #568 | `codex/lss-sparse-capacity-guidance` | sibling | Docs: clarify sparse phylogenetic LSS capacity guidance; branch updated from main | `a2325345` | `<<fill>>` | `<<fill>>` |

Note: at read time, `gh api` reported #605/#607/#608/#610/#611/#612/#613/#574/#573/#568 all
`state: open`, `merged_at: null` — none of this lane's own PRs are merged yet; only the two Codex
sibling PRs (#567, #571) landed. Every head sha above was read fresh via `gh api
repos/itchyshin/DRM.jl/pulls` at handover time — the conductor should re-read before merging in
case a PR moved since.

## 3. Owner decisions owed

- **Non-Gaussian parity bar (~1e-5 measured vs 4e-6 bar).** Three S9 precision leaves
  (`joint-fit-parity:G1`, `joint-public-fit:G5`, `r-joint-native:G1`) all key off the same
  already-measured Bernoulli `native_theta` delta of `1.0015e-5`, roughly 2.5× the programme's
  `4e-6` tolerance. Evidence: issue #606, `scratchpad/s9-classification.md` summary ("UNSURE: 3").
  Fixing needs optimizer/tolerance engineering on the existing (not-widened) joint-fit path, not a
  pure oracle re-run; owner call needed on whether to fix, or accept/document the gap.
- **Bridge `q4_vcov` default (#611).** `src/gaussian_bivariate.jl` computes `V = q4_vcov ?
  _q4_fd_vcov(...) : fill(NaN, ...)` for the q4 REML route; the bridge currently reports
  `wald_unavailable` for this route even though `_vcov_from_hessian` never legitimately returns
  all-NaN (it degrades to `pinv` + `@warn`). Root cause not pinned — `scratchpad/s11-inference.md`
  §3 step 3 lists three candidate explanations ((a) `q4_vcov` effectively false on this path, (b)
  a separate bridge-side fence, (c) genuine FD-Hessian failure). Owner call: flip the bridge
  default, or confirm R already passes `q4_vcov = TRUE` and Julia should match.
- **S9 precision leaves** — see bullet 1 above; same evidence, listed separately here because
  the S9 classification note (`scratchpad/s9-classification.md`) frames it as a distinct
  "recommend a separate precision-focused pass" item from the general non-Gaussian bar question.
- **Fold `q4-reml`/`phylo-mean` fixtures into the `[se]`-reading Route-1 glob?** 11 of 13
  `[interval_status]`-carrying fixtures already carry an `[se]` block; `phylo-mean` and `q4-reml`
  do not. `scratchpad/s11-inference.md` §3 step 6: phylo-mean is legitimately `not_comparable`
  (both engines `wald_unavailable`) and just needs the reserved `not_comparable` key recorded;
  `q4-reml` should wait until the vcov NaN (bullet above) is resolved, else the `[se]` block would
  be empty or need immediate regeneration.
- **#573's retarget/merge.** #573 is stacked on #574's branch (`codex/loconly-numerical-boundary`);
  per `arcs.md` A2, it should retarget to `main` once #574 merges, then merge itself if green.
- **FIML #49 (deferred).** General masked/FIML likelihood for the ~12 univariate family files that
  currently do listwise deletion on missing responses (`_fit_observed_response_rows`,
  `src/gaussian_core.jl:740`). Sized **L** in `scratchpad/s8-engine-gaps.md` §1; explicitly NOT
  COVERED tonight (only the narrow #578 q4-REML-mask-consistency slice was closed).
- **Three UNSURE S8 items** (`scratchpad/s8-engine-gaps.md` §3):
  1. **q4 REML bridge "halted by design."** The scoreboard (PR #576) ties this to the #495
     interval-coverage calibration finding, but it's unclear whether "halted" means the bridge
     path was never built (admissible S8 gap) or exists but is withheld pending #495 (D-181
     coverage fence, likely not admissible). No source disambiguates; flagged for an owner call
     before sizing.
  2. **Tweedie / CumulativeLogit random effects.** DRM.jl rejects any RE for these families
     (`src/tweedie.jl:71`, `src/cumulative.jl:37`); whether drmTMB's R side actually supports RE
     for them was not verified against drmTMB's `cells.tsv` in this pass — unsized pending that
     check.
  3. (Related, same note) Univariate LogNormal structured-marker gap size (one marker vs four) —
     the R-side `scope-limited` label is a per-family rollup, not per-marker; needs the `cells.tsv`
     census before sizing precisely (the phylo/relmat *mean* marker itself was closed tonight by
     #608 — this residual is about which *other* markers, if any, remain).
- **Two stopping leaves needing a ledger-clone pull after #612.** `leaf-S10-stopping:G1` and
  `leaf-S10-stopping-negative:G1` were blocked tonight by a `cd`-to-ledger-root CHECK precondition
  until `main` carries the receipts regenerated in #612 (issue #609, "Stale evidence" list) — pull
  `main` into the programme's ledger clone (`/private/tmp/drm-parity-20260830/DRM.jl`) after #612
  merges, then re-run those two leaves.

## 4. NOT COVERED tonight (with reasons)

- **S10 varying-scale conditional-fit parity fix.** Diagnosed precisely (`scratchpad/
  s10-varying-scale.md`: an LBFGS `g_tol` tolerance gap in `_fit_ranef_gaussian_lss`, admissible
  under D-179 #1 precedent) but not implemented — sized **S**, low risk if scoped to that one
  function, but the slice ran out of night before landing it. Left as issue #609 item 2.
- **S12 full matched sweep beyond the first pass.** The harness and registry (#613) ran a 9-minute
  sweep on a contended host (all 10 workflows still won at 1/2/4/8 threads); a quiet-machine
  re-run and the "automatic thread policy" GOAL.md calls for were not built — `scratchpad/
  s12-harness.md` §3 lists five missing pieces (registered-workflow list existed only as a
  reconstruction, thread-controlled harness, automatic policy, warm/cold split discipline, a
  quiet-machine Stage-2 re-run).
- **FIML #49** — see §3 above; explicit NOT COVERED, sized L, needs its own multi-slice arc.
- **`origin/codex/sigma-phylo-inference-contract` evaluation** — `scratchpad/s11-inference.md` §4
  flags this as 78 commits behind `main`, not rebase-checked; whether it's superseded by tonight's
  #611/#567 work or still live is an open owner question, not resolved tonight.
- **Three S9 precision leaves and the general non-Gaussian parity bar** — measured, diagnosed,
  explicitly left to an owner call or a separate precision pass (§3 above), not attempted as a
  same-night fix given the optimizer-engineering scope.
- **S10 `matched-native` / other stale-receipt leaves beyond what #612 regenerated** — #612's own
  scope was the S9/S10 receipts named in #606/#609; the two `stopping*` leaves specifically need a
  ledger-clone `main` pull after #612 lands (§3 above), which is a follow-up step, not done inline.

## 5. drmTMB-side items handed over

- **`imputed()` inner-mode looseness.** `scratchpad/s9-classification.md` traces the Gaussian
  native-uncertainty mismatch (`8.6e-4` vs `1e-6`, issue #606 item 1) to a disagreement between the
  R-side oracle and the native `imputed()` conditional means — diagnosis of which side (conditional
  mean formula, REML/ML convention, or the oracle's own fit) is off was explicitly not completed;
  this may implicate drmTMB's `imputed()` inner mode, not only the Julia side.
- **`q4_vcov = TRUE` from R.** Per §3's bridge-default bullet: if the resolution is "R already
  passes `q4_vcov = TRUE` for this route," that is a drmTMB-side fact to confirm (the bridge call
  contract), not something DRM.jl can settle unilaterally. The drmTMB-side q4 SE receipt cited in
  the `biv-q4-phylo-reml` fixture note (`claude/rev-parity-q4-se-receipt@9968703`) is itself
  **local-only on the drmTMB checkout, not pushed to `origin`** (`scratchpad/s11-inference.md` §3
  item 1) — landing/pushing that receipt is a drmTMB-maintainer action DRM.jl cannot perform.

## 6. Resume block

```sh
# Worktrees under the session scratchpad (list, then reattach to the one still needed):
ls "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-DRM-jl/2b420b3d-cf11-4ac2-ab94-c3306978df50/scratchpad" | grep ^wt-

# The lane kit (GOAL/arcs/checkpoint — re-read in this order every resume):
cat ~/local-scratch/lanes/DRM.jl-overnight-20260902/LOOP/GOAL.md
cat ~/local-scratch/lanes/DRM.jl-overnight-20260902/LOOP/checkpoint.md
cat ~/local-scratch/lanes/DRM.jl-overnight-20260902/LOOP/arcs.md

# Programme ledger re-verify (scope julia-r-parity), from the ledger clone:
gate-check --root /private/tmp/drm-parity-20260830/DRM.jl --status --scope julia-r-parity

# Totoro suite runner (now logging its own trailer — earlier runs lost it to /dev/null):
ssh -o ControlPath=~/.ssh/cm-totoro -o ControlMaster=no -o BatchMode=yes totoro \
  '~/s7b_work/run_suite.sh <sha> <branch>'
```

Truth lives in (per `checkpoint.md`): worktree `.../scratchpad/wt-563-s7b2` (ledger
`.unlazy/563-s7b2`); Totoro `~/s7b_work` (suite runner + logs), `~/s7b_pilot`; programme ledger
`/private/tmp/drm-parity-20260830/DRM.jl/.unlazy/julia-r-parity`; vault D-203/D-206/D-209/D-211.

## 7. Teardown list

- **Worktrees to remove** (once each PR above is merged or abandoned): every `wt-*` directory
  under this session's scratchpad — `wt-563-s7b2`, `wt-574`, `wt-578`, `wt-563-lognormal`,
  `wt-563-s9`, `wt-563-s9-docs`, `wt-563-s9-imp`, `wt-563-s10-pred`, `wt-563-s11`, `wt-563-s11-se`,
  `wt-563-s12`, and this handover's own `wt-handover` (remove after its commit is confirmed landed
  on `main` or superseded). Run `git worktree remove <path>` from the Dropbox main checkout, then
  `git worktree prune`.
- **Branches merged** (delete remote+local once confirmed merged): `codex/sigma-phylo-inference-
  contract` (#567), `codex/profile-thread-fit-budget` (#571) — both already merged per §2; the
  remaining branches in the merge table stay until their own PR merges.
- **Lease**: this lane held no exclusive file lease beyond its own worktrees (per D-209's
  pre-authorisation, no `AGENTS.md`/ledger/push-ritual files were shared with another concurrent
  lane tonight) — release is implicit on worktree teardown; no separate lease file to clear.

## Handoff-gate note

`~/shinichi-brain/tools/handoff_gate.sh` was read before running (not executed). Its `check_ledger()`
function runs `node gate-check.mjs --root <repo> --reverify <f>` against every file under
`<repo>/.unlazy/**/gates/*.md`, invoked once per repo from `check_repo(); check_ledger()`. DRM.jl's
working trees this session carry multiple `.unlazy/*/gates/*.md` ledgers (e.g. `563-s7b2`), so
running the gate script here would itself invoke `gate-check --reverify` — exactly the
"never call ... gate-check inside a CHECK" fork-bomb pattern `GOAL.md`'s invariants warn against
(2026-09-02 lesson). **Skipped** per this task's own instruction ("ONLY if it does not itself
invoke gate-check/after-task recursion... if it does, skip and say so").

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
