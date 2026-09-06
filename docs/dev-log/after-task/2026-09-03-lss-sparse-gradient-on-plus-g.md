# After-task: sparse LSS gradient O(n+G), not O(G·n) (#630, refs #627)

Date: 2026-09-03 · PR [#630](https://github.com/itchyshin/DRM.jl/pull/630) MERGED @ `301121287b98c0a1d5188de80fa265959d47f560` · branch `fix/627-profile-warm-start` · issue #627 stays OPEN

Perspectives: Rose (after-task QA, this report only — the implementation work was done by an
earlier session; this file closes the Definition-of-Done documentation debt). No subagents.

## 1. Goal

Document, for the record, a perf fix already merged: the single-component sparse LSS
gradient (`src/gaussian_sparse_lss.jl`) was O(G·n) — for each of G groups it rescanned
all n rows — instead of O(n+G) via the scatter form the multi-component route already
used. Refs #627, which had misdiagnosed the same symptom as the profile endpoint search.

## 2. Implemented

Nothing new in this PR beyond what #630 already merged. This report records it:

- `src/gaussian_sparse_lss.jl`: replaced the gather accumulation of the sd-block
  quadratic term (for each of G groups, rescan all n rows) with the scatter form,
  making the single-component sparse LSS gradient O(n + G) instead of O(G·n).
- `test/test_lss_sparse_gradient_scaling.jl` (new, 150 lines): `#627 sparse LSS
  profile endpoints are unchanged` and `#627 sparse LSS gradient cost stays linear
  in G`.
- `test/runtests.jl`: wired the new file in.

## 3a. Decisions and Rejected Alternatives

- **The PR began from a wrong diagnosis.** Issue #627 named the profile *endpoint
  search* as the cost driver, citing the code's worst-case bounds (~200 objective
  calls, up to 800 inner evaluations) and the #494 runaway comment as if those
  bounds were measurements. The brief's phase-1 requirement — measure before fixing
  — is what caught this: instrumenting one coefficient across G = 2,048 / 4,096 /
  8,192 / 16,384 tips (three seeds, two model shapes) found **14 objective calls per
  coefficient, flat in G, zero iteration-cap hits**. Warm-starting was also found to
  already exist (`_profile_endpoint_result` keeps a per-search `û`, seeded from the
  unconstrained fit, `src/inference.jl:1025`, `:1039`) — already search-local,
  already thread-safe. There was nothing to implement on the search side. Rejected:
  implementing warm-start "fix" for #627 as originally scoped — it would have been
  a no-op layered on code that already did this.
- **Root cause instead:** `nllgrad` grew 4× per doubling of G. Profiling is
  gradient-bound (~130 gradient calls against ~250 objective calls), so the
  gradient's O(G·n) behaviour, not the search, is what made whole-tree profile CIs
  impractical, and ordinary point fitting paid the same cost.
- **Scatter form chosen over rewriting the gather with early termination** — the
  multi-component route already had a correct O(n+G) scatter accumulation for the
  same quadratic term; reusing that form rather than inventing a new one kept the
  two routes structurally aligned.
- **Rewrote an intermediate version for bit-exactness.** A version that folded the
  subtraction into the scatter loop moved CI endpoints by 1.4e-12 through pure
  floating-point reassociation — under the 1e-8 tolerance bar, but avoidable, so it
  was rewritten to be bit-identical to the pre-fix output rather than merely
  tolerance-passing.
- **Rejected:** threading the per-job scratch Cholesky factor (`use_ref = false`)
  through three inference functions and both sparse fitters — reported as a known
  residual (a wrong-scope race) rather than attempted in this PR.

## 4. Files Touched

By #630 (merge commit `301121287`):
- `src/gaussian_sparse_lss.jl` (29 lines changed)
- `test/runtests.jl` (+1 line, wiring)
- `test/test_lss_sparse_gradient_scaling.jl` (new, 150 lines)

By this after-task pass (docs only, this worktree):
- `docs/dev-log/after-task/2026-09-03-lss-sparse-gradient-on-plus-g.md` (this file)
- `docs/dev-log/check-log.d/2026-09-03-lss-sparse-gradient-on-plus-g.md`

## 5. Checks Run

- `gh pr view 630 -R itchyshin/DRM.jl --json title,body,mergeCommit,state` —
  confirmed MERGED @ `301121287b98c0a1d5188de80fa265959d47f560`.
- `git show --stat 301121287` — confirmed the 3-file diff (29 / +1 / +150 lines)
  matches the PR body's description.
- `git log --oneline 301121287~5..301121287` — confirmed #630 is the direct child
  of `c8586cd88` (docs merge) and `0564c90bf` is the fix commit it merges.
- Every number in §2/§3a/the summary below is copied verbatim from the PR body
  (`gh pr view 630 ... --json body`), not recomputed in this pass.
- `Rscript ~/shinichi-brain/tools/check-after-task.R
  docs/dev-log/after-task/2026-09-03-lss-sparse-gradient-on-plus-g.md` (run
  directly on this file — result below).

Not run in this pass (docs-only lane; forbidden from touching `src/`/`test/`):
`Pkg.test()`, the benchmark scripts that produced the timing table.

## 6. Tests of the Tests

Not applicable to this pass — no code changed here. For #630 itself (as reported
in the PR, not reproduced by this pass): RED-first discipline was not the pattern
used (this was a measure-then-fix perf PR); instead the merged PR reports the
full `runtests.jl` suite at 457 testsets / 0 failures / 0 exceptions, with the new
file's two testsets (`59/59` and `5/5`) added specifically to lock in (a) endpoint
bit-identity and (b) linear-in-G gradient cost — i.e., tests that would fail again
if either the O(G·n) gather or an endpoint drift were reintroduced.

## 7a. Issue Ledger

- **#627** (profile CI impractical at whole-tree scale) — **stays OPEN**. #630
  fixes the gradient cost that made profiling gradient-bound, but does **not**
  explain the reported 2 h 02 m at N = 10,970 species: projected from the
  measured numbers here, that run should have taken roughly 31 s pre-fix / 4 s
  post-fix — the reported figure is ~236× larger than the pre-fix projection,
  and even applying #494's full 20× runaway leaves it 12–24× short. The gap is
  unexplained on synthetic fixtures (balanced ultrametric trees, well-separated
  covariates — best case for conditioning and Cholesky fill-in) versus the
  reporter's resolved empirical phylogeny with collinear quadratic terms.
- **#616** (flaky profile-endpoint test) — the PR body explicitly disclaims
  supporting any prediction about this issue: it did not reproduce locally (0/20
  before, 0/20 after, four threads) and drives a Gamma objective this change does
  not touch.

## 8. Consistency Audit

- Checked that the PR's own "not covered" language (§ below, "What this does NOT
  explain") survived into this report's §7a and §12 rather than being softened.
- Checked the merge commit's file list against the PR body's described changes —
  match (3 files, same line counts).
- Checked whether any other sparse-LSS route (multi-component, dense comparator)
  needed the same gather→scatter fix — no: the PR body states the multi-component
  route already used the scatter form, which is why it was used as the template
  here rather than invented fresh.

## 9. What Did Not Go Smoothly

- The originating issue (#627) named the wrong subsystem. Fixing it required first
  disproving the issue's own framing with a measurement, which is friction that a
  differently-scoped issue would not have caused.
- An intermediate implementation was numerically close but not bit-exact (1.4e-12
  endpoint drift from reassociation) and had to be rewritten — a reminder that
  "under tolerance" and "unchanged" are different claims, and the PR explicitly
  chose the stronger one.

## 10. Known Residuals

- **#627 remains open and ~236× short of explaining the reported runtime.** This
  PR does not close it and should not be read as having done so.
- The per-job scratch Cholesky factor (`use_ref = false`) still needs threading
  through three inference functions and both sparse fitters; a wrong scope there
  races silently rather than erroring — flagged, not fixed.
- No re-run against the reporter's actual ~10,970-species empirical phylogeny;
  everything measured here is synthetic (balanced ultrametric, well-separated
  covariates).

## 11. Team Learning

Memory receipt: read `HANDOVER.md`/`AGENTS.md` conventions (license boundary,
ML-default, `sigma` not `tau`) as the repo's LOAD-FIRST; no cross-repo scouting
needed for a docs-only after-task pass. Durable lesson for the next agent: **when
an issue cites a code's worst-case bound as though it were a measurement, treat
that as a hypothesis, not a diagnosis** — #627's biggest cost was not the
eventual fix but the time spent instrumenting to find out the named subsystem
(the endpoint search) was innocent. Golden Set: not applicable — this pass is
documentation-only, no code changed, no known-mistake class in scope.

## 12. Cross-Product Coverage

The cross-cutting change here is the sparse LSS gradient's asymptotic cost
(O(G·n) → O(n+G)), which is shared by every caller of the single-component
sparse LSS objective/gradient: point fitting, Wald SEs, and profile CIs.

**Covers:** point fit (13.2× at 16,384 tips, 27.16 s → 2.05 s), one-coefficient
profile CI (8.2× at 16,384 tips), the raw gradient call (17.4× at 16,384 tips),
and CI-endpoint correctness (0.0 relative movement across 279 compared values —
byte-identical across four fixture shapes: non-phylo `sd(g)`, sparse phylo LSS
at G = 512 and 2,048 on two seeds, a dense/GLS comparator, and a
three-observations-per-tip variant). Evaluation counts are unchanged before/after,
so the endpoint search itself is provably untouched by this change.

This slice does NOT cover: the reported 2 h 02 m whole-tree profile at
N = 10,970 species (#627 stays open, ~236× unexplained); the multi-component
sparse LSS route (already O(n+G), untouched by this PR); the dense LSS route;
REML profile costs specifically (the timing table is ML); the per-job scratch
Cholesky scope bug (`use_ref = false`, still a known residual); and #616's
flakiness (explicitly disclaimed in the PR body as unrelated).

## Rose audit (claim-vs-evidence)

| Check | Verdict |
|---|---|
| #630 MERGED @ `301121287` | **PASS** — `gh pr view` + `git show --stat` |
| Gradient 17.4×, profile 8.2×, point fit 13.2× at 16,384 tips | **PASS** — verbatim from PR body table, not recomputed |
| CI endpoints bit-identical, 0.0 movement, 279 values | **PASS** — verbatim from PR body |
| Evaluation counts unchanged (search untouched) | **PASS** — stated in PR body, consistent with the diff touching only the gradient accumulation |
| Began from a wrong diagnosis (#627 named the search) | **PASS** — PR body's own "What #627 claimed, and what was measured" section |
| Measured 14 objective calls/coefficient, flat in G, 0 cap hits | **PASS** — verbatim from PR body |
| #627 stays open; 2 h 02 m unexplained, ~236× short | **PASS** — verbatim from PR body's "What this does NOT explain" section |

**Rose verdict: PASS** — scope honest; #627 correctly left open in the ledger.

*Rose.*
