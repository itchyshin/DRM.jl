# Checkpoint: speed6-20260919

GOAL: see GOAL.md.
STATE: arc S3 (profile) done. bench/profile_q4_sections.jl built and run at
p=100/1000/5000 (tsv), p=2000 (baseline), p=100 (loglik), p=100/1000 (fdvcov).
No src/ edit (G3.5 PASS). 3/5 gates PASS with recorded EVIDENCE in
.unlazy/julia-speed-20260919/gates/leaf-S3.md: G3.3 (loglik), G3.4 (fdvcov),
G3.5 (no src/ diff). 2/5 gates FAIL, reproducibly, for evidenced reasons (not a
harness bug -- see below): G3.1 (section-sum-vs-fit-wall) and G3.2 (baseline
reproduction). Both are re-confirmed across two independent runs (direct + via
`gate-check.mjs --approve` and its own re-run).

## G3.2 FAIL -- the banked 52.9s p=2000 number is STALE, not reproduced

Measured warm fit wall at p=2000: **14.7-15.9s** (my harness: 14.74s; the
repo's own unmodified `bench/run_scaling.jl` run standalone with
`DRM_QGATE_PS=2000 DRM_QGATE_SHAPES=balanced DRM_QGATE_NREP=4`: 15.863s, same
logLik -18062.99 bit-for-bit vs my harness's -18062.99, confirming the case
generator is identical). That is ~3.3-3.6x faster than the banked 52.9s in
report/plan-and-timings.md:194-197, not within the 20% tolerance.

Root cause (evidenced, not inferred): report/plan-and-timings.md's own
"OPTIMIZATION PLAN" section (right after the banked table) names the NEXT
planned step as "1. Speed recovery (fast-path + robust fallback)... Expected
~3.5x back (warm evals are the bulk of a fit)" and its caveat on the banked
table already says "robust mode-finder inflates absolute times ~3.5x". Reading
src/sparse_aug_plsm.jl on the current base (90fbb0e28) shows that exact
fast-path/robust-fallback split (`_estep_fast` / `_estep_robust` /
`estep_mode` dispatcher) IS ALREADY LANDED. 52.9 / 14.7 = 3.60, matching the
anticipated 3.5x almost exactly. **The banked baseline predates a speedup that
has since landed; it is not a regression.** report/plan-and-timings.md is
stale and should be re-banked by the maintainer -- out of this arc's OWNS
(bench/profile_q4_sections.jl, bench/results/*.tsv only), not edited here.

## G3.1 FAIL -- the 4 named sections do not sum to the fit wall

| p | fit_wall_s | estep_newton_chol | logdetP_chol | kron_prior | takahashi | section_sum_s | rel_err |
|---|---|---|---|---|---|---|---|
| 100 | 0.815 | 0.119 (14.6%) | 0.0085 (1.0%) | 0.0079 (1.0%) | 0.0047 (0.6%) | 0.140 | 82.8% under |
| 1000 | 8.444 | 0.719 (8.5%) | 0.055 (0.7%) | 0.063 (0.7%) | 0.041 (0.5%) | 0.879 | 89.6% under |
| 5000 | 39.046 | 74.534 (190.9%) | 1.434 (3.7%) | 1.274 (3.3%) | 0.166 (0.4%) | 77.407 | 98.2% over |

(fd_vcov omitted from the sum-check -- it is a separate post-fit step, not a
per-iteration fit cost; its own numbers are in the fdvcov section below.)

Two evidenced causes:
1. **The taxonomy is incomplete by construction.** The 5 named sections
   (estep_newton_chol, logdetP_chol, kron_prior, takahashi, fd_vcov) are the
   ROLE's *known-inefficiency* list, not an exhaustive partition of one
   `marginal_and_exact_grad` call. Reading fit_q4_sparse_tmb.jl:288-434 shows
   real, uncounted per-eval cost in `joint_nll_T`/`joint_grad_T` (O(n) loops
   over ALL data rows, run under 17-wide ForwardDiff.Dual arithmetic inside
   `ForwardDiff.gradient(jn_of_θ,...)` / `ForwardDiff.gradient(scalar_of_θ,...)`),
   the per-leaf β-block trace loop (:340-367, a `ForwardDiff.jacobian` call per
   leaf), the `v` assembly loop (:405-418, `leaf_hess_du` per leaf), and the
   `Gst` sparse assembly (:374-384, one pass over `nnz(Q_cond)`). None of these
   is in the named list, so at small p they are the majority of the missing
   ~85-90%.
2. **A reproducible warm-path fallback at p=5000.** At p=5000 the "warm" probe
   (estep_mode called with u0 = the fit's own fully-converged mode) does NOT
   take the cheap `_estep_fast` path -- it reports `path=robust_fallback` on
   every run (2/2 independent runs, same result), driving up
   estep_newton_chol's factorisation count to 87 (vs 43 at p=100, 18 at
   p=1000) and its wall past the whole fit's wall. This is a genuine property
   of the CURRENT engine at this p, worth flagging to S5b: if the fast path
   itself sometimes declines to fire even from an exact mode, a cholesky!
   symbolic-reuse fix on top of it inherits that same fallback risk.

Section walls/counts/bytes are real, timed calls to the unmodified
sparse_pd_chol/build_Huu/build_Huu_expected/joint_nll/joint_grad/estep_mode/
prior_precision/takahashi_selinv (see bench/profile_q4_sections.jl's own
header comment for the exact methodology and its "counting-only shadow"
caveat -- no src/ edit, no monkey-patch).

## G3.4 fdvcov cold-vs-warm (PASS, real measured calls -- no projection)

| p | n_theta | expected calls (2n_theta) | cold: 1 call wall / cold Newton iters | warm(u_hat): 1 call wall / shadow chol calls | speedup | projected total (cold / warm) |
|---|---|---|---|---|---|---|
| 100 | 17 | 34 | 0.045s / 15 iters | 0.016s / 3 | 2.78x | 1.53s / 0.55s |
| 1000 | 17 | 34 | 0.567s / 17 iters | 0.275s / 3 | 2.06x | 19.27s / 9.36s |

Sizes the S5c warm-u0 fix: at p=1000 a full `_q4_fd_vcov` call (34 cold calls)
projects to ~19s; with a warm u0 it would project to ~9.4s (~2x), consistent
with the TSV's fd_vcov row at p=1000 (19.97s, single-cold-call projection).
fd_vcov is the single largest cost at every p tested (212% of fit_wall at
p=100, 236% at p=1000, 591% at p=5000) -- the dominant target for S5c.

## TRUTH LIVES IN

- Harness: bench/profile_q4_sections.jl (this worktree,
  branch claude/lane-speed6-20260919, base origin/main 90fbb0e28).
- TSV (gitignored, on disk): bench/results/q4_sections_3285d7750.tsv
  (git SHA 3285d7750 = this checkpoint's commit's parent tree; header carries
  Julia 1.10.0, OpenBLAS64 ILP64, 4 Julia threads / 1 BLAS thread,
  arm64-apple-darwin22.4.0, Apple M1 Ultra).
- Gate ledger + EVIDENCE: .unlazy/julia-speed-20260919/gates/leaf-S3.md
  (git-ignored). G3.3/G3.4/G3.5 EVIDENCE recorded (checked [x]); G3.1/G3.2
  remain unmet/pending in the ledger (the tool does not write EVIDENCE text
  for a failing CHECK) -- their numbers live in this checkpoint and the TSV
  instead.
- Independent verification of G3.2: `bench/run_scaling.jl` (unmodified, repo's
  own script) re-run standalone with
  `DRM_QGATE_PS=2000 DRM_QGATE_SHAPES=balanced DRM_QGATE_NREP=4`; its report
  file (report/qgate-multishape-scaling.md) was restored to HEAD afterward
  (`git show HEAD:... >` the file) -- not left dirty, not committed.

## NEXT

S5a (closed-form logdet P) per GOAL.md's arc order, per the identity gate in
GOAL.md's Invariants. **Before that**, surface G3.1/G3.2 to Shinichi: (a)
report/plan-and-timings.md's 52.9s p=2000 baseline is stale and should be
re-banked (positive finding -- current engine is ~3.5x faster than banked,
already landed, not caused by this arc); (b) the leaf-S3 gate's 5-section
taxonomy does not close to 100% of fit wall by construction (real O(p) AD-loop
costs outside the named 5 sections dominate at small p) and the p=5000
warm-path fallback is worth a look before committing to the S5b cholesky!-reuse
design, since a fallback bypasses whatever reuse S5b adds to the fast path.
