# After-Task Report: keep the augmented tree precision sparse at both conversion sites (#563 S5a)

- **Date:** 2026-09-02
- **Issue:** #563 slice S5a (codex TRUE R↔Julia parity programme; approved PR-gated per vault D-203 §3a, 2026-09-02)
- **Branch:** `feat/563-s5a-sparse-precision`
- **PR:** #581 (draft)
- **Perspectives:** Shannon (Coordination), Noether (Engine), Karpinski (Allocation), Rose (Gate)

## 1. Goal

Stop `_phylo_aug_comp` (`src/gaussian_structured.jl`) and the sparse LSS
fitter's precision initialisation (`src/gaussian_sparse_lss.jl`) from
materialising a dense q×q copy of the root-conditioned augmented tree
precision `Q` before re-sparsifying it, per the codex S5a proposal
(`docs/dev-log/evidence/julia-r-parity/s5a.md` on the codex worktree
`/private/tmp/drm-parity-20260830/DRM.jl`), items 1–2 only (item 3, grouped
`d_g` accumulation, deliberately excluded — not approved).

## 2. Implemented

Two one-line replacements, identical at both call sites (`git diff origin/main
-- src/gaussian_structured.jl src/gaussian_sparse_lss.jl`, run in the
worktree):

```diff
- Qs = dropzeros!(sparse(Symmetric(Matrix(Q))))
+ Qs = dropzeros!(sparse(Symmetric(Q, :U)))
```

in `_phylo_aug_comp` (`src/gaussian_structured.jl`) and at the sparse LSS
fitter's precision initialisation (`src/gaussian_sparse_lss.jl`). `Symmetric(Q,
:U)` on the already-sparse `Q` keeps the same upper-triangle convention and
the same numbers as `Symmetric(Matrix(Q))`; only the storage path changes —
the `O(q²)` dense copy is gone.

Test-first: `test/test_sparse_precision_storage.jl` (from the codex S5a
proposal), wired into `test/runtests.jl` after `test_lss_sparse.jl` (`git
diff --stat`: `test/runtests.jl | 1 +`). It pins the exact precision and leaf
rescaling against a dense oracle (5 checks), the sparse LSS objective and
finite-difference stationarity against an independent dense covariance
objective on an unbalanced, partially-unobserved fixture (6 checks), and a
20 KiB/tip allocation ceiling at 1,024 and 2,048 tips (2 checks).

## 3a. Decisions and Rejected Alternatives

- **Only items 1–2 of the codex S5a proposal were implemented; item 3
  (grouped `d_g` accumulation in the sparse-LSS gradient) was deliberately
  excluded.** Per the commit message (`git show -s --format=%B HEAD`) and
  the PR body (`gh api repos/itchyshin/DRM.jl/pulls/581 --jq .body`): "The
  proposal's grouped d_g accumulation (item 3) is deliberately NOT included"
  — it was not part of the maintainer's approval (D-203 §3a covers only the
  two `Symmetric(Matrix(Q))` → `Symmetric(Q, :U)` replacements).
- **`Symmetric(Q, :U)` chosen over other sparsification strategies** because
  it is the minimal change that preserves the existing upper-triangle
  convention and produces numerically identical entries — the proposal
  itself specifies this exact replacement (`s5a.md` §"Proposed source-only
  patch after approval", items 1–2), and the RED→GREEN test evidence (§5)
  confirms no behavioural change beyond storage.
- **Full `Pkg.test()` was not rerun locally**; only the target test and five
  named neighbour files were rerun against the patched source, per the PR
  body: "Full suite not rerun locally (CI runs it); no other `src/` file
  changes." Recorded as a residual (§10), not silently assumed.
- **This was a protected `src/` edit gated by maintainer approval, not a
  routine change**: per vault decision D-203 §3a
  (`~/shinichi-brain/memory/DECISIONS.md:7372`), the codex S5a
  sparse-precision proposal was "PROPOSAL ONLY" (`s5a.md`, status line)
  until Shinichi's 2026-09-02 approval, "each its own PR, failing test
  first, Noether+Rose review in the PR, Shinichi merges." This slice
  follows that process: draft PR #581, test-first, merge left to the
  maintainer (§7a, §CARRIED-OVER equivalent).

## 4. Files Touched

Branch diff, `origin/main..HEAD` (source: `git diff origin/main --stat`, run
in the worktree; single commit `5325b392`):

- `src/gaussian_sparse_lss.jl` (+1/−1)
- `src/gaussian_structured.jl` (+1/−1)
- `test/runtests.jl` (+1)
- `test/test_sparse_precision_storage.jl` (+125, new file)

4 files changed, 128 insertions(+), 2 deletions(-).

This ledger (written by Rose, not counted in the branch diffstat above):

- `docs/dev-log/after-task/2026-09-02-563-s5a-sparse-precision.md`
- `docs/dev-log/check-log.d/2026-09-02-563-s5a-sparse-precision.md`

## 5. Checks Run

- **RED, unmodified source** (`scratchpad/s5a-red.log`, source-of-record
  path relative to the coordinator's scratchpad): the oracle checks passed
  even pre-fix —
  ```
  Sparse phylogenetic precision storage                | Pass 5 Total 5 | 1.2s
  Sparse LSS retains multi-alpha objective behaviour    | Pass 6 Total 6 | 7.0s
  ```
  — but the allocation ceiling failed exactly as intended, both tip counts:
  ```
  Sparse phylogenetic precision allocation ceiling: Test Failed
    Expression: _S5A_ALLOCATIONS[tips] ≤ 20000tips
     Evaluated: 35519760 ≤ 20480000        [1,024 tips]
  Sparse phylogenetic precision allocation ceiling: Test Failed
    Expression: _S5A_ALLOCATIONS[tips] ≤ 20000tips
     Evaluated: 138256064 ≤ 40960000       [2,048 tips]
  Sparse phylogenetic precision allocation ceiling | Fail 2 Total 2 | 5.2s
  ```
  `S5A_RED_EXIT=1`. Identical to the codex red log per the PR body
  ("identical to the codex red log") and to the proposal's own table
  (`s5a.md`: 1,024 tips → 35,519,760 bytes vs 20,480,000 bound; 2,048 tips →
  138,256,064 bytes vs 40,960,000 bound).
- **GREEN, patched source** (`scratchpad/s5a-green.log`):
  ```
  Sparse phylogenetic precision storage             | Pass 5 Total 5 | 0.9s
  Sparse LSS retains multi-alpha objective behaviour | Pass 6 Total 6 | 6.2s
  Sparse phylogenetic precision allocation ceiling   | Pass 2 Total 2 | 0.0s
  SPARSE_PRECISION_REGRESSIONS_PASS
  S5A_GREEN_EXIT=0
  ```
- **Neighbours on the patched source** (`scratchpad/s5a-neighbours.log`):
  `test_gaussian_structured.jl`, `test_gaussian_phylo_mean_missing_response.jl`,
  `test_parity_gaussian_phylo_mean.jl`, `test_locscale_structured.jl` each
  ended `EXIT_<file>=0` with a `Test Summary:` header and no `Fail`/`Error`/
  `LoadError` line — the log capture recorded the summary headers but not
  the pass/total data row for these four files, so their exact pass counts
  are not available from this source; only "exit 0, no failures reported"
  is claimed. `test_lss_sparse.jl` failed to load in that same run
  (`ArgumentError: Package StableRNGs not found in current path` — the test
  environment's own dependency, not reachable outside `--project=test`) and
  was rerun separately.
- **`test_lss_sparse.jl` rerun under `--project=test`**
  (`scratchpad/s5a-lss-sparse.log`), all green:
  ```
  Sparse LSS vs Dense Comparator: Scalar α (Single Predictor)          | Pass 17 Total 17 | 24.1s
  Sparse LSS vs Dense Comparator: Multi-column α (Multiple Predictors) | Pass 12 Total 12 | 24.2s
  Sparse LSS: Routing and sparse = true keyword                       | Pass 4  Total 4  | 0.4s
  Sparse LSS: stored ML gradient is safe for profiling                | Pass 13 Total 13 | 3.4s
  Sparse LSS: Large tree scaling sanity                                | Pass 5  Total 5  | 0.0s
  LSS_SPARSE_EXIT=0
  ```
- **Gate ledger** (`.unlazy/563-s5a/gates/*.md`, this worktree), all four
  leaves `[x]` with `EVIDENCE: exit=0`:
  - `leaf-red`: `grep -cE "Evaluated: [0-9]+ (<=|≤) (20480000|40960000)"` on
    the red log → EXPECT 2, EVIDENCE output=2.
  - `leaf-green`: `grep -c SPARSE_PRECISION_REGRESSIONS_PASS` on the green
    log → EXPECT 1, EVIDENCE output=1; plus a scope check that exactly the
    two `Qs = dropzeros!` lines changed in `src` (`git diff origin/main --
    src | grep -cE "^[-+] *Qs = dropzeros"` → EXPECT 4, EVIDENCE output=4,
    i.e. one `-` and one `+` line at each of the two call sites).
  - `leaf-neighbours`: no `Fail|Error During|LoadError` lines across the
    neighbour + lss-sparse logs, excluding the known StableRNGs
    load message → EXPECT 0, EVIDENCE output=0.
  - `leaf-pr`: draft PR exists — `gh api
    'repos/itchyshin/DRM.jl/pulls?head=itchyshin:feat/563-s5a-sparse-precision&state=open'`
    → EXPECT `581 draft=true`, EVIDENCE output=`581 draft=true`.

## 6. Tests of the Tests

The RED run (`scratchpad/s5a-red.log`) is the direct evidence that the
allocation ceiling actually catches the dense copy: on the unmodified
source it failed both assertions with the exact allocation figures for the
dense `Matrix(Q)` conversion — **35,519,760 bytes vs a 20,480,000-byte bound
at 1,024 tips**, and **138,256,064 bytes vs a 40,960,000-byte bound at 2,048
tips** — while the two oracle testsets (precision/leaf-rescaling vs dense
oracle, sparse-LSS objective/stationarity vs independent dense covariance
oracle) already passed 5/5 and 6/6 on the unmodified source, isolating the
allocation ceiling as the specific, sole assertion the patch needed to fix.
After the two-line patch, the same allocation testset passed 2/2
(`scratchpad/s5a-green.log`) with the oracle testsets unchanged at 5/5 and
6/6 — i.e. the fix moved only the allocation numbers, not the underlying
values, which is the claim the commit message makes ("same numbers; only
the storage path changes").

## 7a. Issue Ledger

- **#563 slice S5a** — fix; landed on `feat/563-s5a-sparse-precision`,
  draft PR #581, merge is the maintainer's (not closed by this slice; #563
  is a multi-slice programme, not resolved by S5a alone).
- No new issues were opened by this slice. The proposal's item 3 (grouped
  `d_g` accumulation) remains a **documented, deliberately unimplemented**
  part of the codex S5a proposal — not tracked as a separate GitHub issue
  in the sources read for this report; it is recorded here and in the
  commit/PR text as excluded, not forgotten.

## 8. Consistency Audit

- **Both dense-conversion call sites were checked and fixed, not just the
  one the codex proposal's allocation test targeted directly.** The
  proposal's own text (`s5a.md`) frames `_phylo_aug_comp` as "currently the
  first conversion site only," and this slice's `leaf-green` gate explicitly
  checks that exactly the two `Qs = dropzeros!` lines changed in `src`
  (`git diff origin/main -- src | grep -cE "^[-+] *Qs = dropzeros"` = 4,
  i.e. one removed/added pair at each of the two sites) — confirming the
  same-class fix was applied at both, not left partial.
- **Downstream consumers of both sites were swept**: the sparse LSS engine
  tests (#551, `test_lss_sparse.jl`) and the structured-Gaussian tests
  (`test_gaussian_structured.jl`) plus three further phylo/missing-response/
  parity/locscale neighbour files were rerun against the patched source and
  all report exit 0 with no `Fail`/`Error`/`LoadError` lines (§5).
- **Scope was audited against the approval, not just against "does it
  work."** D-203 §3a approved specifically "two identical replacements" in
  the two named files; the `leaf-green` gate's line-count check is itself a
  consistency check that nothing beyond the approved scope was touched.

## 9. What Did Not Go Smoothly

- **`test_lss_sparse.jl` initially failed to load** in the neighbour rerun
  with `ArgumentError: Package StableRNGs not found in current path` — a
  test-environment dependency issue (the file needs `--project=test`), not
  a defect in the patch. It was rerun under `--project=test`
  (`scratchpad/s5a-lss-sparse.log`) and passed cleanly (51/51 across five
  testsets, §5).
- **The neighbour-log capture recorded `Test Summary:` header lines without
  their pass/total data rows** for four of the five neighbour files
  (`test_gaussian_structured.jl`, `test_gaussian_phylo_mean_missing_response.jl`,
  `test_parity_gaussian_phylo_mean.jl`, `test_locscale_structured.jl`) — only
  `EXIT_<file>=0` and the absence of any `Fail`/`Error`/`LoadError` line are
  available from that source, not their exact pass counts (§5, §10).
- **The S5a proposal itself was blocked for a full review cycle before this
  slice could exist**: `s5a.md`'s status line records "PROPOSAL ONLY — no
  protected `src/` file was changed. The core-write tool rejected the
  earlier source patch," requiring the D-203 §3a maintainer approval
  (2026-09-02) before this branch's single commit could be written.

## 10. Known Residuals

- **Full `Pkg.test()` was NOT rerun locally for this slice.** Only the
  target test (`test_sparse_precision_storage.jl`, RED and GREEN) and five
  named neighbour files were rerun against the patched source; CI runs the
  full suite on the PR. The PR body states this explicitly: "Full suite not
  rerun locally (CI runs it); no other `src/` file changes."
- **The proposal's item 3 (grouped `d_g` accumulation in the sparse-LSS
  gradient) is deliberately excluded** — not approved under D-203 §3a, not
  implemented, not tested here.
- **No benchmark or speed claim is made.** This slice fixes an allocation
  ceiling (bytes per call, asserted by test), not a measured wall-clock
  speedup; no timing comparison is reported or implied.
- **The sparse-LSS small fixture emits a boundary-Hessian pseudo-inverse
  warning that the test does not consume**: both the RED and GREEN logs
  show `Warning: Hessian is numerically singular at the optimum — using a
  pseudo-inverse ... context = "sparse LSS phylo", flat_coordinates = [5,
  6], rcond = 3.394776990717379e-21` at `src/vcov_guard.jl:87`. Per the
  codex proposal's own text: "The test neither consumes those standard
  errors nor claims inference validity; it checks only the objective and
  its finite-difference stationarity against the independent dense
  covariance oracle." Unchanged by this slice.
- **Exact pass/total counts for four of the five neighbour files
  (`test_gaussian_structured.jl`,
  `test_gaussian_phylo_mean_missing_response.jl`,
  `test_parity_gaussian_phylo_mean.jl`, `test_locscale_structured.jl`) are
  not available from the logs read for this report** — only `EXIT=0` and
  the absence of failure/error lines. Not invented; left as a gap (§9).
- **Merge is the maintainer's**, per the PR body ("Merge is the
  maintainer's") and D-203 §3a's process ("Shinichi merges"); PR #581 is
  still a draft at report time (`leaf-pr` gate: `581 draft=true`).

## 11. Team Learning

- **A protected `src/` change approved for a narrowly-scoped proposal
  should be implemented at exactly that scope, and the scope itself should
  be machine-checked, not just described.** This slice's `leaf-green` gate
  greps the diff for the exact number of changed lines matching the
  approved pattern (`Qs = dropzeros`), turning "did we stay in scope" into
  a deterministic check rather than a claim.
- **RED-before-approval is worth preserving as its own artefact.** The
  codex proposal's RED log (`.unlazy/julia-r-parity/red/S5a-original.log`,
  referenced in `s5a.md`) and this slice's own RED log
  (`scratchpad/s5a-red.log`) report the same two allocation figures
  (35,519,760 / 138,256,064 bytes) — a reproduced-RED check that the
  patch's target defect is the same defect the original proposal measured,
  not a redefinition of the problem after the fact.
- **A test-environment-only dependency failure (missing `StableRNGs`
  outside `--project=test`) looks like a regression in a neighbour sweep
  if the run command doesn't match the file's own environment** — worth
  checking the failure message before treating a neighbour "fail" as
  evidence against the patch; here it was a harness mismatch, resolved by
  rerunning under the correct project.

## 12. Cross-Product Coverage

This slice touches one cross-cutting mechanism: the **augmented tree
precision's storage representation** (`_phylo_aug_comp` and the sparse LSS
fitter's precision initialisation), used wherever a phylogenetic group
structure needs the root-conditioned augmented precision `Q`.

- **Covers ✓**: the two call sites that build `Q` (`_phylo_aug_comp` in
  `src/gaussian_structured.jl`; the sparse LSS fitter's initialisation in
  `src/gaussian_sparse_lss.jl`) — both patched identically, both verified
  by dedicated oracle + allocation tests (5/5, 6/6, 2/2 on the patched
  source); the sparse LSS engine surface (#551, `test_lss_sparse.jl`,
  51/51 across five testsets under `--project=test`); the structured-
  Gaussian, phylo-mean-missing-response, parity-gaussian-phylo-mean, and
  locscale-structured neighbour surfaces (all exit 0, no failures, though
  without captured pass counts — see §10).
- **Does NOT cover ✗**: the proposal's item 3 (grouped `d_g` accumulation
  in the sparse-LSS gradient) — deliberately excluded, not approved; any
  other consumer of `augmented_tree_precision`/`Q` not in the five named
  neighbour files or the target test (no full-suite sweep was run — see
  §10); standard errors at the sparse-LSS fixture's boundary-Hessian
  coordinates (pre-existing pseudo-inverse warning, not addressed or
  claimed fixed by this slice); any wall-clock/speed claim (allocation
  ceiling only, no benchmark run or reported).

## Memory receipt

No new hub `AGENTS.md` guard was added or consulted for this slice. Sources
consulted: `~/shinichi-brain/memory/DECISIONS.md` (D-203, specifically §3a,
`grep -n "D-203"` then read in context around line 7372) for the approval
record, and `docs/dev-log/evidence/julia-r-parity/s5a.md` on the codex
worktree (`/private/tmp/drm-parity-20260830/DRM.jl`) for the original
proposal and its RED-on-unmodified-source receipt. No sibling-project
scouting was performed for this slice; all numbers in this report are
copied from `git log`/`git diff --stat`/`git show -s --format=%B HEAD`/`gh
api repos/itchyshin/DRM.jl/pulls/581` output captured live in this worktree,
the four `scratchpad/s5a-*.log` files, the `.unlazy/563-s5a/gates/*.md`
ledger, and `s5a.md` (all cited inline above).
