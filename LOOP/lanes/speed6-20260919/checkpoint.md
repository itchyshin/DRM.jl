# Checkpoint: speed6-20260919

GOAL: see GOAL.md.
STATE: arc S5 (the three identity changes) attempted in partition order (b, c, a).
(b) cholesky! symbolic reuse -- LANDED, all its gates PASS. (c) warm u0 into
_q4_fd_vcov -- LANDED (real ~2-4x speedup measured), but its own precision
gate (G5.5, warm-vs-cold vcov) FAILS at rtol 1e-8 (measured ~3e-5) --
investigated, not resolved, recorded honestly, not fudged. (a) closed-form
logdet P -- NOT ATTEMPTED: its own pure-math identity check (G5.2, independent
of any src/ change) already fails marginally at p=100 before any
implementation exists, and the ridge-removal it would require has a
documented ~1e-8 bias that would very likely also break G5.1's rtol 1e-12 --
stopped per "if a change cannot meet its gate, stop and report the numbers"
rather than spend the two hours on a change unlikely to land clean.

## Before/after (fit wall, factorisations, fd_vcov)

Measured on this machine (Mac Studio M1 Ultra, 4 Julia threads, 1 BLAS
thread), same balanced-tree DGP (bench/profile_q4_sections.jl's `make_case`,
nrep=4) both times.

| p | fit_wall before (S3 checkpoint) | fit_wall after (b)+(c) | chol_factorizations after | fd_vcov cold->warm (p=100,1000 measured directly) |
|---|---|---|---|---|
| 100 | 0.876 s | 0.908 s | 247 (7.06/eval), 0 fallbacks | cold 1.53s / warm 0.60s projected (2.57x) |
| 1000 | 8.476 s | 8.460 s | 289 (11.56/eval), 0 fallbacks | cold 20.61s / warm 5.62s projected (3.67x) |
| 5000 | 38.063 s | 38.156 s | 220 (8.80/eval), 0 fallbacks | (not measured directly; G5.7 fd_vcov not re-run at p=5000) |

**Honest finding: change (b) does not measurably move the total fit wall**
(all three p within 1-4% -- run-to-run noise on this machine, not a
directional change). Real, measured, and unsurprising in hindsight: this
route's H_uu is TREE-STRUCTURED sparse (from the phylogeny's Q_topology), and
CHOLMOD's symbolic analysis of a tree-structured pattern is already cheap
relative to numeric factorisation -- the "avoid re-analysis" saving change (b)
targets is real (0 fallbacks confirm reuse is engaging on every one of
220-289 factorisations per fit) but small relative to the OTHER costs
(beta_trace/gst/v_assembly, ~40-47% of the fit per the leaf-S3 partition)
that change (b) never touched. **Change (c) DOES show a clear, real
speedup** (2.6-3.7x per fd_vcov call, matching the priority order's stated
"halves the 228 s vcov" expectation, if anything better than halving).

## G5.1..G5.7

- **G5.1 PASS** -- marginal NLL at fixed theta0, p=100/1000, rel error 0.0
  (exact) vs pinned origin/main baseline, both before and after (b)+(c).
- **G5.2 FAIL** -- closed-form logdetP vs factorised logdetP, 20 random
  Lambda draws, fixed Q_cond: p=100 worst rel error 1.726e-12 (ledger bound
  1e-12; p=1000 passes at 5.327e-13). Pure math, unaffected by any src/
  change -- comparing two independently-computed logdets (an ~800x800 sparse
  Cholesky vs a 4x4 closed form) is at the edge of double-precision noise for
  a problem this size. This is why change (a) was not attempted.
- **G5.3 PASS** -- inner-Newton iteration count (12) and the 12-value
  accepted ridge lambda sequence, p=100 cold start, identical to the pinned
  origin/main baseline (elementwise rtol <= 1e-10).
- **G5.4 PASS** -- p=1000 real fit: 289 CHOLMOD factorisations via the
  cholesky!-reuse path, 0 fresh-cholesky fallbacks.
- **G5.5 FAIL** -- warm-u0 vcov vs pinned cold vcov, p=100: Frobenius norm
  10.87243 (warm) vs 10.87210 (pinned cold), rel error ~3.06e-5 against the
  ledger's rtol 1e-8 bound (~3000x over). Cold path (u0=nothing, unaffected
  by change (c)) still matches the pinned baseline exactly. Investigated:
  threading a tighter fast-path convergence tolerance (fast_ftol/
  fast_stall_tol, to close the gap between the fast path's default 1e-6 and
  the robust path's 1e-8) did NOT close the gap at 1e-8 and made it WORSE at
  1e-12 (rel error grew to ~1.2e-3) -- ruling out "just a convergence-
  tolerance amplified through the 2h=2e-4 FD division" as the mechanism.
  Reverted that speculative fix rather than keep unexplained complexity.
  Root cause not found; flagged for the orchestrator (see NEXT).
- **G5.6 FAIL, but only on the two ALREADY-KNOWN findings above.** Full
  `Pkg.test()`, 23m28s wall: exactly 2 `Test Failed` in the entire ~2367-line
  log, both from test_q4_perf_identities.jl's own testset (`gate_logdet` /
  G5.2, `gate_vcov` / G5.5 -- the same numbers already reported, not new
  ones). Every OTHER test file passed, including
  test_parity_biv_q4_phylo_reml.jl (33/33) and the zero-allocation inner-loop
  gate test_qgate_alloc_inner.jl (#15, 7/7) the ledger names explicitly.
  The literal grep-for-"Testing DRModels tests passed" CHECK fails because
  Pkg.test() reports "errored during testing" once ANY testset fails, however
  small -- there is no wording that means "everything passed except these 2
  known, already-reported findings."
- **G5.7 PASS** -- Julia arm only (drmTMB is installed on this machine, but
  bench/R/head_to_head_q4_scaling.R's fixture-export/env contract was not
  verified by this leaf -- stated explicitly in the gate's own output and TSV
  header, not silently skipped). p=100 fixture logLik -256.5273 (diff 0.0173
  vs -256.51, within 0.05); p=1000/5000 fits converged; factorisations/eval
  and warm median walls recorded in
  bench/results/q4_head_to_head_9d709f008.tsv.

## A real bug caught before shipping (worth knowing across lanes)

The first cholesky!-reuse draft passed a bare (both-triangles-stored)
`SparseMatrixCSC` to `cholesky!(F, A)`. This does NOT throw and `issuccess`
reports true -- but it silently DOUBLE-COUNTS off-diagonal contributions,
measured as an exact 2.0x logdet inflation on a synthetic H_uu built via the
real `build_Huu`. Caught only because G5.5's identity test compared actual
NUMBERS (θ̂, vcov) against a pinned baseline, not just `issuccess`/fallback
counts -- the G5.4-style "fallback count must be zero" check would have
reported PASS on the wrong answer. Fixed by wrapping with `Symmetric(...)`
before `cholesky!` (matching the ORIGINAL `cholesky(Symmetric(...))`
analysis call's convention), verified exact against a fresh factorisation.
The repo's own `chol_ref` idiom (gaussian_structured.jl, gaussian_sparse_lss.jl)
passes a BARE matrix to `cholesky!` too; whether their H matrices avoid this
failure mode by construction (single-triangle-only patterns) was NOT
independently re-verified by this leaf -- worth a look, not asserted as a
bug there.

## TRUTH LIVES IN

- src/sparse_aug_plsm.jl (change (b): CholPatternCache, _add_diag,
  _chol_factorize, sparse_pd_chol/_estep_fast/_estep_robust/estep_mode
  chol_ref threading, CHOL_FACTORIZATIONS/CHOL_REUSE_FALLBACKS diagnostics).
- src/fit_q4_sparse_tmb.jl (chol_ref threaded through marginal_and_exact_grad/
  marginal_nll; fit_q4_sparse_tmb's fg! creates one CholPatternCache per fit).
- src/gaussian_bivariate.jl (change (c): u_hat computed before the vcov call;
  _q4_fd_vcov's new u0 kwarg; the sibling :structured_q4 route at line ~1114
  left untouched -- not on the profiled phylo route).
- test/test_q4_perf_identities.jl (G5.1/G5.2/G5.3/G5.5), test/runtests.jl
  (one include line).
- bench/profile_q4_sections.jl: retired the leaf-S3 monkeypatch-based section
  profile (it would have silently shadowed change (b)'s real implementation);
  --gate tsv/fdvcov now read the real CHOL_FACTORIZATIONS/CHOL_REUSE_FALLBACKS
  counters; added --gate fallback (G5.4) and --gate headtohead (G5.7).
- bench/results/q4_sections_9d709f008.tsv, bench/results/q4_head_to_head_9d709f008.tsv
  (gitignored, on disk).
- Commits (this branch, in order): 5e5d23e66 (test, step 1), 2d37376a5
  (change b), 9d709f008 (change c, with the G5.5 finding).
- Gate ledger: .unlazy/julia-speed-20260919/gates/leaf-S5.md (git-ignored).
  `gate-check.mjs --approve --root "$PWD" --cwd "$PWD" --timeout 3600` was
  launched from the worktree root; read its EVIDENCE before trusting the
  per-gate checkbox state over this checkpoint's own direct-run numbers above.

## NEXT

For the orchestrator: (1) G5.5's warm-vcov ~3e-5 discrepancy is unexplained
past "not a simple convergence-tolerance artifact" -- worth a deeper look
(candidate: does the warm-started Newton land on a measurably different u_hat
than cold, even though both individually satisfy their own convergence
criterion?) before deciding whether to accept it, dig further, or revert
change (c). (2) Change (b) landed correctly but delivered no measurable
fit-wall speedup on this tree-structured sparse pattern -- the real cost
centres per leaf-S3's own partition (beta_trace/gst/v_assembly, ~40-47% of
the fit) are untouched by any of the three S5 changes; a future arc targeting
THOSE loops (not more CHOLMOD tuning) is the higher-leverage next step if
more speed is wanted on this route. (3) report/plan-and-timings.md's stale
52.9s baseline still needs re-banking (carried over from S3, still true).
