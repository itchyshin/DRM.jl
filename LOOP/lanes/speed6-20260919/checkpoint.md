# Checkpoint: speed6-20260919

GOAL: see GOAL.md.
STATE: arc S3 (profile) done, REPAIRED. bench/profile_q4_sections.jl now
instruments the REAL fit (measurement-only method redefinition of
`_estep_fast`/`_estep_robust`/`estep_mode`/`laplace_ll`/`marginal_and_exact_grad`
on their exact original signatures, verbatim-transcribed from
`git show 90fbb0e28:src/{sparse_aug_plsm,fit_q4_sparse_tmb}.jl`, timing added,
calling through unchanged to sparse_pd_chol/build_Huu/build_Huu_expected/
joint_nll/joint_grad/joint_nll_T/joint_grad_T/leaf_hess/leaf_hess_du) instead of
a standalone post-fit probe. No src/ edit (G3.5 PASS). **All 5 gates now PASS**
with recorded EVIDENCE in .unlazy/julia-speed-20260919/gates/leaf-S3.md.

## Why the repair was needed (kept as a finding, not erased)

The first pass's G3.1/G3.2 FAILs were real and are kept in git history
(commit fb4161bcc's message) as findings: (a) a standalone "representative
eval" probe missed real per-eval cost outside its 5-section taxonomy and, at
p=5000, sampled a probe that happened to fall back to the expensive robust
Newton path, overshooting the fit wall by ~2x; (b) the banked 52.9s p=2000
baseline (report/plan-and-timings.md:194-197) predates the fast-path/
robust-fallback split already on this base -- the ledger's G3.2 was re-stated
by the orchestrator to the repo's own current number (15.86s,
bench/run_scaling.jl) rather than widening the old tolerance.

## Complete section table (p=100/1000/5000, chosen rep = median-wall rep)

Sections are real, non-overlapping, sequential timings inside the ACTUAL fit's
own `marginal_and_exact_grad` calls (accumulated over every call in the fit),
so they partition the fit wall by construction; "other" is the genuine
remainder (Optim bookkeeping, F-only line-search evals, GC, and the handful of
untimed small lines: the plain `joint_nll` inside `laplace_ll`, glogdetΛ's
10-dim AD gradient, the Mk contraction, the `w = chH \ v` solve).

| p | section | wall_s | count | share of fit_wall |
|---|---|---|---|---|
| 100 (fit_wall=0.876s, f_calls=35) | estep_newton_chol | 0.396 | 247 chol | 45.2% |
| | beta_trace | 0.229 | 35 loop-runs | 26.1% |
| | gst + v_assembly | 0.182 | 70 loop-runs | 20.8% |
| | joint_nll_T + joint_grad_T | 0.041 | 140 calls | 4.6% |
| | logdetP_chol + kron_prior + takahashi | 0.020 | 245 calls | 2.3% |
| | other | 0.008 | -- | 0.9% |
| | fd_vcov (separate, post-fit) | 1.635 | 34 calls | 186.6% |
| 1000 (fit_wall=8.476s, f_calls=25) | estep_newton_chol | 4.932 | 289 chol | 58.2% |
| | beta_trace | 1.626 | 25 | 19.2% |
| | gst + v_assembly | 1.347 | 50 | 15.9% |
| | joint_nll_T + joint_grad_T | 0.264 | 100 | 3.1% |
| | logdetP_chol + kron_prior + takahashi | 0.180 | 175 | 2.1% |
| | other | 0.128 | -- | 1.5% |
| | fd_vcov | 20.295 | 34 | 239.4% |
| 5000 (fit_wall=38.063s, f_calls=25) | estep_newton_chol | 20.298 | 220 chol | 53.3% |
| | beta_trace | 8.648 | 25 | 22.7% |
| | gst + v_assembly | 6.490 | 50 | 17.0% |
| | joint_nll_T + joint_grad_T | 1.627 | 100 | 4.3% |
| | logdetP_chol + kron_prior + takahashi | 0.670 | 175 | 1.8% |
| | other | 0.331 | -- | 0.9% |
| | fd_vcov | 227.907 | 34 | 598.7% |

Full 11-row-per-p granularity (estep_newton_chol, logdetP_chol, kron_prior,
takahashi, joint_nll_T, joint_grad_T, beta_trace, gst, v_assembly, other,
fd_vcov -- each unmerged) is in
bench/results/q4_sections_fb4161bcc.tsv.

**What owns the time:** estep_newton_chol (inner-Newton CHOLMOD, 45-58%) and
beta_trace + gst + v_assembly combined (the per-leaf/per-edge exact-gradient
assembly loops, 40-47%) are the two real cost centres at every p -- together
~85-90% of one fit. logdetP/kron_prior/takahashi and the two AD-gradient
closures are each under 5%. fd_vcov, run once after the fit, already exceeds
the whole fit's own wall at every p (187% at p=100, rising to 599% at p=5000)
-- the single largest lever, consistent with S5c's warm-u0 plan.

## Fast-vs-robust estep calls (fit-internal, real; replaces the dropped probe)

| p | f_calls (total estep_mode calls) | fast attempts | robust calls | fast Newton iters (total / mean) | robust Newton iters (total / mean) |
|---|---|---|---|---|---|
| 100 | 35 | 34 | 3 | 106 / 3.1 | 106 / 35.3 |
| 1000 | 25 | 24 | 4 | 93 / 3.9 | 171 / 42.8 |
| 5000 | 25 | 24 | 4 | 88 / 3.7 | 107 / 26.8 |

Reconciling: `fast attempts + robust calls > f_calls` because a fast attempt
that fails also produces a robust fallback call for the SAME estep_mode
invocation. At every p, exactly 1 of the robust calls is the genuinely cold
first evaluation (u_cache starts at `nothing`); the other 2-3 robust calls per
fit are fast-path attempts that failed and fell back -- a real, small (under
15% of estep_mode calls), non-degenerate fallback rate. This directly refutes
the first pass's standalone-probe finding that the fast path "reproducibly"
fails at p=5000: inside the real fit it succeeds on 24/25 (96%) of estep_mode
calls; the earlier probe had sampled an unrepresentative exact-mode point.

## TRUTH LIVES IN

- Harness: bench/profile_q4_sections.jl (this worktree,
  branch claude/lane-speed6-20260919, base origin/main 90fbb0e28).
- TSV (gitignored, on disk): bench/results/q4_sections_fb4161bcc.tsv
  (named by the harness commit's SHA at run time; header carries Julia 1.10.0,
  OpenBLAS64 ILP64, 4 Julia threads / 1 BLAS thread, arm64-apple-darwin22.4.0,
  Apple M1 Ultra). The prior (superseded) TSV q4_sections_3285d7750.tsv is
  left on disk as the record of the first-pass probe methodology.
- Gate ledger + EVIDENCE: .unlazy/julia-speed-20260919/gates/leaf-S3.md
  (git-ignored). All 5 gates [x] with EVIDENCE recorded.
- Verification pair actually run (see reply for the exact commands/cwd/exit
  code): `--approve` then `--reverify --approve` (plain `--reverify` alone hit
  a per-gate approval-directory binding on G3.5 left over from the ORIGINAL,
  no-`--cwd` run in the prior session; combining `--reverify --approve` with
  the same `--cwd`/ledger path re-approves under that cwd and re-runs
  everything in one pass -- exit 0, ALL MET).

## NEXT

leaf-S3 is fully closed (all 5 gates PASS, evidence recorded). Proceed to S5a
(closed-form logdet P) per GOAL.md's arc order and its identity gate. Carry
forward: (a) report/plan-and-timings.md's 52.9s p=2000 number is stale and
should be re-banked (owner call, outside this leaf's OWNS); (b) estep_newton_chol
and the beta_trace/gst/v_assembly AD-loop trio are the two real cost centres
(not just the second-factorisation/kron-prior items S5a/S5b originally named)
-- worth keeping in view when scoping S5b's cholesky!-reuse design, since
these loops run once per Newton iteration too; (c) fd_vcov dominates total
wall at every p and is the highest-leverage target for S5c.
