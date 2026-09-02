# After-Task Report: O(p) sparse exact marginal LSS engine — multi-component (#563 S7(b), Phase 2)

- **Date:** 2026-09-02
- **Issue:** #563, slice S7(b), sub-slices S7b.1–S7b.6
- **Branch:** `feat/563-s7b-lss-sparse-multi`
- **Head:** `638a2da3`
- **Perspectives:** Shannon (coordination), Noether (design/review), Curie (pilot),
  Karpinski (S7b.6 fix/perf), Rose (this report)

## 1. Goal

Extend #551's single-phylo-component O(p) sparse exact-marginal Laplace
engine to **several** `sd()` submodels in one fit (one phylogenetic
component plus nested-or-small iid components), matching what #555's dense
multi-component route already does — objective, exact gradient, REML, and a
public router — under the D-206 GO decision (restricted scope: nested /
one-phylo class only; general crossed sparse stays NO-GO).

## 2. Implemented

Six sub-slices, `git log --oneline f53e06b1..HEAD`:

- `ed45a044` **S7b.1** — sparse multi-component block assembly and
  objective: the augmented block precision `H` and RHS `b` generalise
  `gaussian_sparse_lss.jl`'s single-component machinery to a stack of
  components (one phylo `Q_phy` block plus any number of iid diagonal
  blocks), with genuine cross-component off-diagonal blocks.
- `e3e65500` **S7b.2/S7b.2b** — exact gradient of the sparse multi-component
  objective, including the cross-component selected-inverse terms
  (`Hinv[g,t]` for `g`, `t` in different components) that the
  single-component formula has no analogue for.
- `019432d3` design-note correction (§3 rows `quad_term`, `g_βσ`) made
  **during** implementation review — the note's first draft used the
  diagonal-only single-component form for `g_βσ` and the joint (not
  per-component) sum for `quad_term`; both were wrong and are documented as
  corrected, with the FD evidence, in the design note itself (§3, rows
  marked "CORRECTED 2026-09-02").
- `56f66c7f` **S7b.3** — REML for the sparse multi-component route:
  objective and exact gradient of the Patterson–Thompson correction, via the
  same per-column sparse-backsolve pattern as #551, generalised to sum
  every component's `wts` contribution into the shared RHS.
- `aafab7c4` **S7b.4** — the public route: `drm(...; algorithm = :sparse)`
  now dispatches to the sparse multi-component engine when eligible
  (`_lss_multi_route`), under the D-206 router rule — exactly one phylo
  component, every iid component nested or small (`G_c ≤ 0.1·G_phy`);
  otherwise (including an explicit sparse request) it falls back to the
  dense route with an `@info` naming the failing component, never a silent
  drop and never an unproven-fill sparse fit. `:auto` dispatches to sparse
  when eligible **and** `G_phy > 500`.
- `ba9f20c2`, `07c18534`, `bfe71145` — docs: the API block for the route's
  documented internals, de-linking `@ref`s to undocumented closure names,
  qualifying `@ref`s with the module name.
- `22e4d12d` **S7b.5** — scaling pilot on Totoro (D-139 pre-run before any
  full-scale claim): confirmed `nnz(L)/dim` stays flat (≈3.09) to p =
  10,000, but found wall time was **not** O(p) — log-log exponent ≈2.6–2.9
  from p = 2500 → 10,000 (165 s at p = 10,000, RSS 1.3 → 8.0 GB).
  `docs/dev-log/evidence/julia-r-parity/2026-09-02-lss-sparse-multi-scaling-pilot.md`
  (+ `.tsv`).
- `86b7e3d4` **S7b.6, fix** — root cause: `_drm_gaussian_lss_multi`
  (`src/gaussian_lss.jl`) unconditionally computed `_phylo_correlation(phy)`
  — a dense O(p³) inverse of the ~2p×2p augmented tree matrix — **before**
  deciding `use_sparse`; the sparse branch never reads that matrix. Fixed
  with a `_LazyPhyloK()` marker: the phylo component is built lazily and
  only the dense route materialises the real matrix
  (`_materialize_lss_comp_K`). RED-first: a new testset asserted a
  `t2000/t500 ≤ 8` wall-time-ratio budget, measured `25.79` pre-fix
  (FAILED as expected, `scratchpad/s7b6-red.log`), then `1.83` post-fix
  (GREEN, `scratchpad/s7b6-green.log`).
- `385f02cd`, `638a2da3` **post-fix Totoro re-measurement** — the same p =
  1000/2500/5000/10,000 ladder on Totoro against the fix (head `86b7e3d4`):
  ML 8.7 (JIT)/0.34/0.68/1.62 s, REML 0.76/0.94/1.55/2.86 s; exponent
  2500→10,000 ≈1.1 (ML) / 0.8 (REML); RSS 1.25–1.35 GB across the ladder
  (was 8.0 GB pre-fix at p = 10,000); every log-likelihood bit-identical to
  the pre-fix run (the objective itself is untouched by the fix).

Full diffstat, `git diff --stat f53e06b1..HEAD` (this worktree): 12 files
changed, 2488 insertions(+), 13 deletions(-).

## 3a. Decisions and Rejected Alternatives

- **Design-first, symbolic-alignment discipline, before any engine code**
  (D-206): the developer note
  `docs/src/developer-notes/lss-sparse-multi-component.md` measured the
  Cholesky fill pattern (CHOLMOD probes, §2) **before** committing to
  implement anything, and found the gradient table's first-drafted
  `g_α,c` row wrong — a diagonal-only selected-inverse formula that is
  91% off from central-FD on a 6-node adversarial toy (§3, §8 finding 4).
  The corrected formula (adding the cross-component `Hinv[g,t]` trace term)
  agrees to `3.4e-10`. This was caught by adversarial review of the design
  **before** a line of engine code, exactly the failure mode
  symbolic-alignment exists to catch.
- **Restricted scope, not a general crossed sparse route** (D-206): the
  same design note measured that two comparably-sized crossed iid
  components go near-dense (`nnz(L)/dim² ≈ 0.35` on a trivial 400×400
  system) under any elimination order — a structural graph property, not
  an implementation gap. The router (S7b.4) turns this into a mechanical
  eligibility test (`_lss_iid_nested_in`, `_LSS_SPARSE_SMALL_FRACTION =
  0.1`) rather than leaving it to a fit-time judgement call, and falls back
  to the existing dense multi-component route (`n ≤ 5000`) for genuinely
  crossed models rather than attempting an unproven-fill sparse fit.
- **D-139 pre-run before the p = 10,000 claim**: S7b.5 ran a scaling pilot
  on Totoro (≤150 cores, D-143) before committing to a full run, and its
  own honest negative finding (wall time NOT O(p), despite fill being flat)
  is what triggered S7b.6 rather than being suppressed or re-labelled as a
  measurement artefact.
- **RED-first tripwire for the S7b.6 fix**, not just a before/after number:
  a permanent regression test (`t2000/t500 ≤ 8` budget) was written to fail
  against the unfixed router (measured 25.79) before the fix landed, so a
  future regression of this specific defect (re-densifying `_phylo_correlation`
  unconditionally) is caught by CI, not only by a one-off pilot.
- **Root-cause fix, not a workaround**: rather than special-casing the
  sparse route to skip `_phylo_correlation`, the fix defers materialisation
  for *every* caller via `_LazyPhyloK()`, so the invariant ("only the route
  that needs the dense matrix pays for it") holds structurally rather than
  by an if-branch that could rot.
- **Tolerances**: the design note's own §5 records rejecting an
  initially-drafted `atol = 1e-8` dense-vs-sparse identity bound as tighter
  than #551's own shipped precedent (`atol = 1e-5`) with no measured margin
  to justify the tighter number — adopted `atol = 1e-5` / `rtol = 2e-4,
  atol = 2e-5` (coef) to match #551, not a new ad hoc bound.

## 4. Files Touched

`git diff --stat f53e06b1..HEAD` (this worktree), 12 files, 2488
insertions(+), 13 deletions(-):

- `docs/dev-log/evidence/julia-r-parity/2026-09-02-lss-sparse-multi-scaling-pilot.md` (+200)
- `docs/dev-log/evidence/julia-r-parity/2026-09-02-lss-sparse-multi-scaling-pilot.tsv` (+17)
- `docs/src/developer-notes/lss-sparse-multi-component.md` (+141/-…)
- `src/gaussian_core.jl` (+7/-…)
- `src/gaussian_lss.jl` (+175/-…)
- `src/gaussian_sparse_lss.jl` (+730, new engine code — 996 lines total in
  the file after this slice)
- `test/runtests.jl` (+4)
- `test/test_lss_sparse_multi.jl` (+189, new)
- `test/test_lss_sparse_multi_gradient.jl` (+183, new)
- `test/test_lss_sparse_multi_public.jl` (+417, new)
- `test/test_lss_sparse_multi_reml.jl` (+244, new)
- `tools/lss_sparse_multi_scaling_pilot.jl` (+194, new)

This report and its two siblings (check-log row, plan-vs-actual) are
written by Rose in this same commit, not counted in the diffstat above
(they land in the same commit as this report per the coordinator's
instruction).

## 5. Checks Run

- **`test/test_lss_sparse_multi.jl`** (S7b.1, block assembly) — 7/7
  (`Sparse multi-component LSS block assembly (#563 S7b.1)`,
  `scratchpad/s7b6-test_lss_sparse_multi.log`).
- **`test/test_lss_sparse_multi_gradient.jl`** (S7b.2/S7b.2b, exact
  gradient) — 8/8 (`scratchpad/s7b6-test_lss_sparse_multi_gradient.log`):
  FD-vs-exact relative error ≤ 1.37e-7 at the three oracle-2 points (dense
  optimum / perturbed / boundary); the diagonal-only α gradient this design
  note first drafted is pinned as 71.6× wrong on the regression fixture
  (design note §3, §8 finding 4).
- **`test/test_lss_sparse_multi_reml.jl`** (S7b.3, REML) — 25/25
  (`scratchpad/s7b6-test_lss_sparse_multi_reml.log`): REML FD-vs-exact
  relative error ≤ 1.09e-7, including a boundary point
  (`point = "boundary (iid logSD ≈ -6)"`, `max_abs_err = 7.56e-8`, `rel =
  2.56e-10`).
- **`test/test_lss_sparse_multi_public.jl`** (S7b.4 router + S7b.6 scaling
  tripwire) — 35/35 across the three S7b.4 oracle testsets (dense-vs-sparse
  identity 21/21, crossed-fixture-stays-dense 7/7, `G_phylo > 500`
  auto-dispatch 7/7) **plus** the S7b.6 wall-time testset:
  **RED** (`scratchpad/s7b6-red.log`) — `t500=0.146s, t2000=3.77s`, ratio
  `25.79`, asserted `ratio ≤ 8` → **4/5 FAILED as designed**
  (`Test Failed ... Evaluated: 25.78... <= 8`).
  **GREEN** (`scratchpad/s7b6-green.log`, post-`86b7e3d4`) —
  `t500=0.171s, t2000=0.314s`, ratio `1.83` → **5/5 PASSED**.
  Combined post-fix total for this file: 21+7+7+5 = **40/40** (§10 notes
  the RED run is evidence-of-defect, not a passing count).
- **Full local per-file sweep, post-fix (head `86b7e3d4`)**, session
  scratchpad logs, `Test Summary` lines counted directly from each file
  (30 test sets green in total across the 12 non-empty, non-`red.log`
  `s7b6-*.log` files):
  - `s7b6-green.log` — 4 test sets (the `test_lss_sparse_multi_public.jl`
    file, post-fix: 21/21, 7/7, 7/7, 5/5)
  - `s7b6-test_lss_bootstrap_contract.log` — 1 (`Gaussian LSS bootstrap
    contract`, 60/60)
  - `s7b6-test_lss_group.log` — 4 (`lss sd(group)` grammar/router/
    reduction/REML, 3/3, 4/4, 9/9, 9/9)
  - `s7b6-test_lss_missing_response.log` — 1 (`#559 Location-scale-scale
    missing response`, 57/57)
  - `s7b6-test_lss_phylo.log` — 6 (`sd_phylo` grammar/fit/reduction/
    homoscedastic-guard/bridge/threaded-inference, 11/11, 8/8, 7/7, 2/2,
    3/3, 4/4)
  - `s7b6-test_lss_reml.log` — 1 (`Location-scale-scale (lss) REML (#558)`,
    41/41)
  - `s7b6-test_lss_sparse.log` — 5 (single-component sparse LSS, #551,
    17/17, 12/12, 4/4, 13/13, 5/5)
  - `s7b6-test_lss_sparse_multi.log` — 1 (S7b.1, 7/7)
  - `s7b6-test_lss_sparse_multi_gradient.log` — 1 (S7b.2/S7b.2b, 8/8)
  - `s7b6-test_lss_sparse_multi_reml.log` — 1 (S7b.3, 25/25)
  - `s7b6-test_lss_tip_identity.log` — 1 (`Gaussian LSS phylogenetic tip
    identity`, 410/410)
  - `s7b6-test_lsss_multi.log` — 4 (dense multi-component `#555`/`#556`
    fixtures A/B + refusals, 9/9, 5/5, 6/6, 5/5)

  (The task brief for this report cited "29 test sets green"; the
  independent count from the logs, `grep -c "^Test Summary"` per file
  excluding `s7b6-red.log` and the two empty docs-build logs, is **30**.
  Reported as counted, not silently reconciled to the brief's number.)
- **Ledger** (`.unlazy/563-s7b2/gates/leaf-s7b1.md`…`leaf-s7b5.md`, this
  worktree): `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs
  --root . --status <files>` → `leaf-s7b1.md: 3 gates`, `leaf-s7b2.md: 4
  gates`, `leaf-s7b3.md: 3 gates`, `leaf-s7b4.md: 4 gates`, `leaf-s7b5.md:
  4 gates`, **`ALL MET (18 met)`**. Leaf-s7b4's own gate G4 was not
  re-verified here per this task's explicit instruction — that is the
  conductor's job after the full suite completes.
- **Totoro full test suite** (D-205, checks run on Totoro rather than
  GitHub Actions): the pre-fix head `ba9f20c2` **PASSED**
  (`SUITE_EXIT=0`, 442 test-set summaries, 35 min wall,
  `~/s7b_work/suite-ba9f20c2….log` on Totoro). The **final head
  (`86b7e3d4`, src/test tree identical to this branch's head `638a2da3`
  — only two docs-only commits sit on top of it)** was **still running at
  the time of writing**: `ssh -o ControlPath=~/.ssh/cm-totoro -o
  ControlMaster=no -o BatchMode=yes totoro 'L=$(ls
  ~/s7b_work/suite-86b7e3d4*.log); grep -c "Test Summary" $L; grep -E
  "SUITE_EXIT|Testing DRM tests passed|did not pass" $L | tail -3'` →
  65 test-set summaries so far, no `SUITE_EXIT`/pass/fail line yet, and
  `ps aux` on Totoro confirmed the `runtests.jl` process is still `Rl`
  (running). The PR body carries the final line once it completes — this
  report does not claim a result it has not yet seen.
- **Local Documenter build, head `86b7e3d4`**
  (`scratchpad/s7b6-docs-build.log`): exit 0, 0 errors. **A second build
  on this branch's actual head, `638a2da3`**
  (`scratchpad/s7b6-docs-build-2.log`) was **launched but the log file is
  0 bytes at the time of writing** — reported as pending, not claimed
  complete, per this task's own evidence note.

## 6. Tests of the Tests

- **The S7b.6 wall-time testset is itself a RED→GREEN pair against a real
  defect**, not a value comparison written after the fact: it was run
  against the unfixed router first (`ratio=25.79` vs. the asserted
  `≤ 8` budget → `Test Failed`, `scratchpad/s7b6-red.log`) and only then
  against the fix (`ratio=1.83` → pass). A regression that reintroduced
  unconditional `_phylo_correlation` materialisation would fail this test
  again, not silently pass.
- **The `g_α,c` cross-component gradient formula has its own dedicated
  adversarial regression guard** (design note §5 oracle 3): the test
  asserts the corrected analytic formula matches central-FD **and**
  asserts the diagonal-only (single-component) formula is rejected by the
  same test (`> 1e-3` away from FD) — so the specific 91%-wrong bug the
  design review caught cannot silently come back even if someone
  "simplifies" the loop back to the single-component form.
- **The router-fallback oracle (S7b.4) is a negative test**: on the
  genuinely crossed fixture, it asserts the sparse route is *not* taken
  even under an explicit `algorithm = :sparse` request, and that the dense
  route's numbers are what comes back — this would catch a regression
  where the router's eligibility test became too permissive and started
  running unproven-fill sparse fits silently.
- **Every FD-vs-exact gradient check (S7b.2, S7b.2b, S7b.3) uses
  independently-computed central finite differences**, not a value
  hardcoded from a single earlier run of the analytic code — a regression
  in the analytic formula would show up as a widened FD gap, not merely a
  missing test.

## 7a. Issue Ledger

- **#563 slice S7(b), sub-slices S7b.1–S7b.6** — landed on
  `feat/563-s7b-lss-sparse-multi`, head `638a2da3`. Merge is the
  maintainer's.
- **D-206** (GO for nested/one-phylo, NO-GO for general crossed) —
  implemented exactly as scoped; no request was made or honoured to widen
  the router past the D-206 boundary.
- **S7b.5's own finding (wall time not O(p) despite flat fill)** was
  promoted to a follow-up sub-slice (S7b.6) within the same session rather
  than left as an unactioned pilot caveat — closed by the router fix and
  the post-fix Totoro re-measurement.
- **Leaf-s7b4 gate G4** — explicitly not re-verified by this report; owned
  by the conductor after the Totoro suite (still running, §5) completes.

## 8. Consistency Audit

- **Every sub-slice's own gradient/objective claim has an independent FD
  oracle** (S7b.2's 8/8, S7b.3's 25/25) — not assumed to inherit
  correctness from S7b.1's block-assembly tests.
- **The router's two failure directions were both checked**: an eligible
  fixture must reach the sparse route and match dense (oracle 1, 21/21);
  an ineligible (crossed) fixture must *not* reach it even when explicitly
  requested (oracle 4, 7/7) — not just the affirmative case.
- **The wall-time defect found in S7b.5 was traced to its actual root
  cause** (`_phylo_correlation` materialised unconditionally in the public
  router, `src/gaussian_lss.jl`) rather than patched at the symptom
  (e.g. special-casing the sparse branch to skip a slow step) — the fix
  file list (`git show 86b7e3d4 --stat`) touches `src/gaussian_lss.jl`
  (the router) and the design note and public-route test file, **not**
  `src/gaussian_sparse_lss.jl` (the sparse engine itself, unchanged by the
  fix) — consistent with the diagnosis that the defect was outside the
  engine.
- **The design note's own §8 "Adversarial review" section was re-read
  against the shipped code**, not treated as a one-time gate: its finding
  4 (`g_α,c` diagonal-only, 91% wrong) is the same bug the S7b.2 gradient
  test now pins permanently (§6); its finding 2 (fill sensitivity to
  unbalanced groups / caterpillar trees) is carried into §7's "Limitations"
  paragraph as an open, undismissed caveat rather than silently dropped.
- **Tolerances were checked against precedent** (§3a) rather than invented
  fresh for this slice.

## 9. What Did Not Go Smoothly

- **The design note's first-drafted gradient table was wrong** (§3a, §8
  finding 4): the `g_α,c` row and, separately, the `quad_term`/`g_βσ` rows
  (§2, `019432d3`) needed correction during implementation review, not
  before. The corrections are documented in place (marked "CORRECTED
  2026-09-02") rather than silently rewritten, and both are now pinned by
  regression tests.
- **The S7b.5 pilot found a real wall-time defect the design did not
  predict.** The design note's own fill analysis (§2) was about
  `nnz(L)/p`, not wall-clock time, and nothing in the symbolic-alignment
  pass surfaced that the *router* — code outside the sparse engine
  entirely — was paying an O(p³) tax on every sparse-route call. This was
  found only by running the p = 10,000 pilot on real hardware (Totoro),
  which is exactly why D-139's pre-run-before-full-claim discipline
  applied here: the pilot's honest negative finding (§5, "wall time is
  NOT") is what triggered S7b.6, rather than the p = 10,000 claim being
  made and later found wrong in production.
- **The Totoro full-suite re-run against the final head was still in
  flight at report-writing time** (§5) — not a smooth same-session
  close-out; the PR body is the place the final line lands.

## 10. Known Residuals

- **Crossed layouts are dense-route only.** No sparse route exists or is
  claimed for two-or-more comparably-sized crossed components (design note
  §2.3 case (c), §7 GO/NO-GO); the router (S7b.4) sends them to the
  existing dense multi-component route (`n ≤ 5000`) with an informative
  `@info`, never a silent sparse attempt.
- **Many-component sparse (more than one phylogenetic component) is not
  implemented or tested.** The design note's scope (§1) is explicitly "at
  most one phylogenetic component"; the router's eligibility test enforces
  exactly one.
- **p > 10,000 is not measured.** The Totoro ladder (S7b.5 pre-fix, S7b.6
  post-fix) stops at p = 10,000; no claim is made beyond that scale.
- **The `p² .7` finding from S7b.5 was a router bug outside the new sparse
  engine, not a property of the engine itself** — stated explicitly so a
  reader does not conflate "the pilot found superlinear wall time" with
  "the sparse multi-component objective/gradient/REML machinery (S7b.1–
  S7b.3) is superlinear." `src/gaussian_sparse_lss.jl` (996 lines, the
  actual sparse machinery) is untouched by the `86b7e3d4` fix; only the
  public dispatcher (`src/gaussian_lss.jl`) changed.
- **REML-vs-R same-target receipt for the multi-component sparse route
  does not exist as a dedicated artefact.** What is proven is (a) the
  dense-vs-sparse bit-identity on the same fixture (oracle 1, both ML and
  REML, via `_fit_gaussian_lss_multi` as the comparator) and (b) FD-vs-
  exact gradient correctness (oracles 2, 3) for both ML and REML — not an
  independent R/drmTMB oracle run against this specific multi-component
  sparse route. Where an R same-target receipt exists for `sd_phylo`
  multi-component fits, it is on the pre-existing single-component or
  dense-route tests that already carried it (e.g. `test_lss_phylo.jl`'s
  "QQQ fit matches drmTMB", 8/8) — not newly extended to this slice's
  sparse multi-component code path. A dense-vs-sparse identity comparison
  proves plumbing fidelity between the two Julia routes, not correctness
  against an external oracle (same caveat as the S6 bridge slice's report,
  §10 of `2026-09-02-563-s6-bridge-lss-routes.md`).
- **The unbalanced-group-size and caterpillar-tree fill drifts noted in the
  design note's §8 adversarial review are open, not resolved** — they
  narrow but do not break the O(p) classification, and the note itself
  says what would settle them (a sweep to p = 16,000–32,000).
- **The Totoro full-suite result for the exact final head is not yet in
  hand** (§5) — the command to fetch it is given verbatim above for the
  conductor to run once it completes.
- **The second Documenter build (on head `638a2da3`) has not finished** at
  report-writing time (§5) — only the `86b7e3d4` build (exit 0, 0 errors)
  is confirmed.

## 11. Team Learning

- **A pilot's honest negative finding is the point, not a failure of the
  pilot.** S7b.5 was run specifically to check whether the flat-fill claim
  extended to wall time at p = 10,000 (D-139); it found it did not, and
  that finding — reported plainly rather than reframed — is what led
  directly to finding and fixing a real O(p³) defect (S7b.6) before it
  ever reached a user. Suppressing or downplaying "wall time is NOT O(p)"
  in the S7b.5 receipt would have cost a real defect its own discovery.
- **A RED-first regression test for a performance defect is worth the same
  discipline as one for a correctness defect.** The S7b.6 fix shipped with
  a testset that was run and shown failing against the unfixed code
  (ratio 25.79) before it was shown passing against the fix (ratio 1.83) —
  the same TDD discipline this codebase already applies to gradient
  correctness, applied here to wall-time.
- **Design-review findings should be pinned by a test that specifically
  rejects the wrong-but-plausible formula**, not just one that accepts the
  right one — the `g_α,c` oracle (§6) asserts *both* that the correct
  formula passes and that the diagonal-only formula it replaces would fail
  the same test, so a "simplification" back to the wrong formula is caught
  immediately rather than only by a future FD audit.

## 12. Cross-Product Coverage

This slice adds the **sparse multi-component location-scale-scale (LSS)
engine** — objective, exact gradient, REML, and a public router — as a
Gaussian-family capability, cutting across the ML/REML axis, the
dense/sparse route axis, and the single/multi-component axis.

- **Covers ✓**: one phylogenetic `sd()` component plus any number of
  nested-or-small (`G_c ≤ 0.1·G_phy`) iid `sd()` components; ML and REML;
  the public `drm(...; algorithm = :sparse)` route and its `:auto`
  dispatch (`G_phy > 500`); FD-vs-exact gradient correctness for the
  objective (8/8) and the REML correction (25/25) including a boundary
  point; dense-vs-sparse bit-identity on a nested fixture (21/21); router
  fallback to dense on a crossed fixture, both explicit and `:auto`
  requests (7/7); wall-time scaling to p = 10,000 on Totoro (post-fix,
  exponent ≈1.1 ML / 0.8 REML); `nnz(L)/dim` fill flat to p = 10,000.
- **Does NOT cover ✗**: **crossed layouts** — no sparse route exists; the
  dense route (`n ≤ 5000`) is the only path and is unchanged by this
  slice. **Many-component sparse** — more than one phylogenetic component
  is out of scope by design (D-206) and untested. **p > 10,000** — no
  measurement beyond the Totoro ladder's top rung. **A REML-vs-R
  same-target receipt for the multi-component sparse route specifically**
  — only dense-vs-sparse Julia-internal identity and FD-gradient
  correctness are proven for this slice's new code; the existing R
  same-target coverage for `sd_phylo` lives on pre-existing single-
  component/dense tests, not extended here. **The p^2.7 wall-time finding
  from S7b.5 was a defect in the public router (`src/gaussian_lss.jl`),
  outside the new sparse engine (`src/gaussian_sparse_lss.jl`)** — fixed
  in S7b.6, but flagged here so the finding is not misread as a property
  of the sparse machinery itself. **Non-Gaussian LSS** — none exists to
  cover; the LSS model family is Gaussian-only throughout the codebase, so
  there is no non-Gaussian surface this slice could have omitted.
  **Inference (SEs, bootstrap, profile CIs) through the sparse
  multi-component route** — not exercised by this slice's own tests beyond
  what oracle-1's dense-vs-sparse comparison implies for point estimates
  and log-likelihood; confidence-interval machinery on this specific route
  is not separately checked.

## Memory receipt

Read before writing this report: `~/shinichi-brain/protocols/after-task.md`
(the 11-section contract and its validator); one recent DRM.jl after-task
report as house shape
(`docs/dev-log/after-task/2026-09-02-563-s6-bridge-lss-routes.md`, this
worktree); the live check-log mechanism
(`docs/dev-log/check-log.md`'s own note that it is frozen history through
2026-06-02 and new entries go to `docs/dev-log/check-log.d/`, per its
README); one existing plan-vs-actual note for the six-axis shape
(`docs/dev-log/plan-actual/2026-09-02-true-parity-replan.md`). No new hub
`AGENTS.md` guard was added or consulted beyond the after-task protocol
itself. All numbers in this report are copied from `git log`/`git show`/
`git diff --stat` run in this worktree, the design note
`docs/src/developer-notes/lss-sparse-multi-component.md`, the pilot receipt
`docs/dev-log/evidence/julia-r-parity/2026-09-02-lss-sparse-multi-scaling-pilot.md`,
the session scratchpad's `s7b6-*.log` files (counted directly, §5), the
ledger gate-check run in this worktree, and a live SSH check against Totoro
via the existing `cm-totoro` ControlMaster socket (no fresh authentication
triggered) — all cited inline above.
