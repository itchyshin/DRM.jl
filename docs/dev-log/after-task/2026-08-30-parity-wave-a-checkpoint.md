# Wave A implementation checkpoint — programme incomplete

## 1. Goal

Begin the approved full Julia–R parity, performance, documentation and repository
reconciliation programme. This report checkpoints partial work; it is not closure.

## 2. Implemented

Isolated both repositories, froze source pins and recorded the approved programme in
LOOP and issue563. Added a native capability inventory and structural verifier, and
a registered-worktree census. Rewrote the R article as a general current-engine guide.
Located existing remote compute runtimes without launching remote computation.

## 3a. Decisions and Rejected Alternatives

Retain all overlapping native rows until valid workflow contracts are derived. The
structural checker cannot emit numerical parity PASS. Do not apply rejected core edits
indirectly. Do not delete dirty worktrees or stashes. Keep Mac, Totoro and DRAC timing
denominators separate; preserve the measured-pilot gate for long campaigns.

## 4. Files Touched

- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/source-pins.json`,
  `LOOP/compute-readiness.md` and the dated approved plan.
- `tools/parity_campaign.py`, `tools/tests/test_parity_campaign.py`,
  `tools/parity_worktree_census.py`.
- `docs/dev-log/evidence/julia-r-parity/capability-manifest.json`,
  `capability-manifest.md`, `worktree-census-summary.md`, `r-article-draft-review.md`.
- This report and the dated check-log entry. Ignored `.unlazy/julia-r-parity/` ledgers,
  claims and private census/provenance/log receipts; copied ignored Julia Manifest.
- S5 worker: `test/test_sparse_precision_storage.jl`, `test/runtests.jl`, pending
  `docs/dev-log/evidence/julia-r-parity/s5a.md`. These are unfinished regression work.
- R worktree: `_pkgdown.yml`, `vignettes/julia-engine.Rmd`; standalone rendered artifact
  outside the repositories under `/private/tmp/drm-parity-20260830/render/`.

## 5. Checks Run

Source main pins verified through SSH refs. Julia loaded from isolated source. Census
recollection records153worktrees,18stashes,136usable,33dirty,6missing,11brokenlink;
`verify` and actual temporary-Git `self-test` pass. Native manifest structure passes;
17-test verifier suite passes after final negative-control repairs (16.384seconds).
R article parse and render pass; `git diff --check` passed.
Original-source allocation regression is RED:35,519,760bytes at1024tips and
138,256,064bytes at2048tips exceed declared linear-storage thresholds. No fix verified.

## 6. Tests of the Tests

Rose independently reproduced empty-manifest, deleted-output/supplement and fabricated
receipt weaknesses. They were repaired with an unconditional review-required numerical
fallback. Final negative controls cover missing supplemental hashes and zero-gap fallback.
Census self-test creates real temporary Git repositories, newline paths, renames,
untracked files, missing worktree directories and foreign linkage; damaged counts,
stash failures, unknown dirty state, linkage and source IDs fail verification.

## 7a. Issue Ledger

[DRM.jl#563](https://github.com/itchyshin/DRM.jl/issues/563) remains OPEN. Existing
obligations are linked from that umbrella; none is closed by this checkpoint.

## 8. Consistency Audit

Rose reviewed the R article against actual dispatch and Julia source. The article now
distinguishes a dense-route observation safeguard from a species limit and describes
threads without promising automatic speedups. Adjacent R help still has stale halted/
deferred wording. Both dense conversions were identified. No production source modified.

## 9. What Did Not Go Smoothly

The goal launcher resolves a nonexistent wrapper path; isolated codex worktrees were
created without changing global configuration. Read-only census checks needed stronger
fixtures than the first scout supplied. The initial parity checker admitted false
success. Protected-core auto-review rejected source changes for missing trusted
owner/maintainer approval and a suspected corrupted identifier. Do not bypass that denial.

## 10. Known Residuals

G0–G8 programme gates remain open. Registered metadata does not recover unique work
or inspect every historical clone. Native rows are not yet valid workflow cases.
Scientific comparison rules, loaded-build provenance, exact seeded article fits,
whole-site rendering, live deployment, Mission Control and original-obligation recovery
remain unfinished. Active hours are not accurately instrumented; do not report forecast
hours as measured usage. No remote campaign or long-compute approval was consumed.

## 11. Team Learning

Memory receipt: routed project instructions and ask-brain orientation informed source
provenance, shared-lane ownership and compute boundaries; repository checks supplied
technical truth. Golden Set: not run; no completion claim is made. No Codex memory
files were updated. Source-derived inventories need independent negative controls:
an argparse failure or stale hash can hide an untested semantic branch.

## 12. Cross-Product Coverage

The snapshot covers native ledger and public-method enumeration, not cross-engine
execution. The documentation draft covers reader-facing wording and syntax; it does NOT
cover seeded-fit convergence, full responsive/theme checks or live deployment. Allocation
regression covers the original construction defect; it does NOT cover a repaired engine,
ML/REML inference, threaded correctness or performance wins. No programme gate is closed.
