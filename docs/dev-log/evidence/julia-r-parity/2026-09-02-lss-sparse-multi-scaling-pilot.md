# S7b.5 — p = 10,000 scaling pilot, sparse multi-component LSS route

Issue #563, Phase-2 sub-slice S7b.5. Design note
`docs/src/developer-notes/lss-sparse-multi-component.md` §5 oracle 5, §6
(memory bound), §7 (estimate — "pilot on Totoro first, report the pilot's
wall time and `nnz(L)/p` before committing to the full p=10,000 fit").
D-139 pilot, not a benchmark.

## Setup

- **Host:** Totoro (`snakagaw@totoro.biology.ualberta.ca`), shared 384-core
  box, no GPU. `julia version 1.12.6`.
- **Repo:** a SEPARATE clone at `~/s7b_pilot/DRM.jl` on Totoro (kept apart
  from `~/s7b_work/DRM.jl`, whose own `run_suite.sh` test-suite run was in
  progress throughout and was never touched).
- **Head:** `07c18534` (`docs(design): API block — drop closure names, add
  _lss_multi_route`), the tip of `feat/563-s7b-lss-sparse-multi` at pilot
  time. GitHub was unreachable from Totoro (`Could not resolve host:
  github.com`), so the pilot repo was populated by `rsync`ing
  `src/`, `test/`, `Project.toml` from the local worktree at the SAME commit
  over the existing SSH `ControlMaster` socket, plus `Manifest.toml` copied
  from the already-instantiated `~/s7b_work/DRM.jl` checkout (`Project.toml`
  confirmed byte-identical between the two checkouts first). `Pkg.instantiate()`
  then ran fully offline from the shared Julia depot (`~/.julia`) — no
  network access needed, no partial/incompatible dependency resolution.
- **Thread pins:** `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1`, single Julia
  process per run, ≤ 1 core in use throughout (per D-143).
- **Script:** `tools/lss_sparse_multi_scaling_pilot.jl` (this worktree).

## Fixture

One phylogenetic `sd(species, phylogenetic) ~ 1` component on a
near-balanced tree of `p` tips (`random_balanced_tree(p; branch_length =
0.15)`), plus one iid `sd(site) ~ 1` component with `G_iid = p/10` groups —
**coarser** than the tips (10 species per site, contiguous blocks), i.e. the
router's `_lss_multi_sparse_eligible` **"small"** branch (`c.G <= 0.1 ×
phy.G`, exactly at the boundary) rather than the strict single-parent
"nested" branch S7b.1/S7b.4's own fixtures already cover at small scale.
`n = 2p` rows (two observations per tip). Phylogenetic random effects were
simulated by an O(p) top-down Brownian-motion walk over the tree's own edges
(root value 0, each edge adds an independent `N(0, branch_length)`
increment, standardised to unit tip variance via `phylo_tree_height`) —
`sigma_phy_dense`'s O(p³) dense-covariance route (used by the smaller S7b.1/
S7b.4 fixtures) is infeasible at p = 10,000. Mean model `y ~ x + (1|site) +
phylo(1|species)`, `sigma ~ 1`. Fit via `drm(...; algorithm = :sparse)`, ML
and REML, at `p ∈ {1000, 2500, 5000, 10000}`.

`nnz(L)/dim` was measured independently of the optimizer, via the S7b.1
assembler (`DRM._lss_sparse_multi_assemble`) at `θ = 0` (structural fill
only, matching `test_lss_sparse_multi_public.jl`'s own oracle-4 convention).

## Smoke (p = 1000 only, `timeout 900`)

```
p    n     G_iid  method  wall_s  converged  iterations  loglik               nnzL  dim   ratio  rss_mb   route
1000 2000  100    ML      9.219   true       -1          -2000.0738822866326  6472  2098  3.085  1313.4   sparse_multi
1000 2000  100    REML    0.973   true       -1          -2004.0591908346282  6472  2098  3.085  1313.4   sparse_multi
PILOT_OK
```

Two finite-loglik, `converged = true` lines, `nnz(L)/dim = 3.085` — inside
the smoke gate's 1.5–4 band. Full log: `s7b5-smoke.log` (local scratchpad).

## Estimate

From the smoke, ML at p=1000 (`9.2 s`, includes first-call JIT/precompile —
Julia 1.12, fresh process) plus REML (`1.0 s`, JIT already warm) ≈ `10.2 s`
combined. Assuming the design note's own O(p) claim held, the full ladder
(1000/2500/5000/10000, ML+REML each) was estimated at roughly `10.2 s ×
(1+2.5+5+10) ≈ 190 s ≈ 3 min` — well under the 30-minute D-139 line, so the
ladder was run directly with `timeout 2400` (no separate approval gate).
**This estimate turned out to be wrong** (see Verdict below) — the ladder
still finished in ≈ 7 minutes wall clock, comfortably inside the 40-minute
timeout, but the per-fit cost did NOT scale the way the estimate assumed.

## Ladder (`timeout 2400`, ran to completion)

| p | n | G_iid | method | wall (s) | converged | loglik | nnz(L) | dim | nnz(L)/dim | peak RSS (MB) | route |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1000 | 2000 | 100 | ML | 9.263 | true | −2000.0739 | 6472 | 2098 | 3.085 | 1314.4 | sparse_multi |
| 1000 | 2000 | 100 | REML | 0.971 | true | −2004.0592 | 6472 | 2098 | 3.085 | 1314.4 | sparse_multi |
| 2500 | 5000 | 250 | ML | 3.657 | true | −4981.7912 | 16211 | 5248 | 3.089 | 1774.5 | sparse_multi |
| 2500 | 5000 | 250 | REML | 3.917 | true | −4986.3792 | 16211 | 5248 | 3.089 | 1774.5 | sparse_multi |
| 5000 | 10000 | 500 | ML | 22.525 | true | −9930.9164 | 32446 | 10498 | 3.091 | 3407.6 | sparse_multi |
| 5000 | 10000 | 500 | REML | 23.323 | true | −9935.9236 | 32446 | 10498 | 3.091 | 3407.6 | sparse_multi |
| 10000 | 20000 | 1000 | ML | 165.788 | true | −19629.4315 | 64920 | 20998 | 3.092 | 7957.9 | sparse_multi |
| 10000 | 20000 | 1000 | REML | 167.017 | true | −19634.8140 | 64920 | 20998 | 3.092 | 8022.7 | sparse_multi |

All 8 fits converged with finite loglik; `_lss_multi_route` reported
`sparse_multi` in every case (never a silent dense fallback). Load average
before the ladder: `4.20, 4.05, 3.65`; after: `6.03, 5.48, 4.46` (shared
box, other users' load rose during the run — see caveat below). Raw
TSV: `docs/dev-log/evidence/julia-r-parity/2026-09-02-lss-sparse-multi-scaling-pilot.tsv`.

## `nnz(L)/dim` band

**Flat and O(p), exactly as the design note's memory bound (§6) predicts:**
`3.085 → 3.089 → 3.091 → 3.092` across a 10× range of `p` — a ~0.2% drift,
indistinguishable from noise. This confirms the assembled `H`'s Cholesky
fill stays linear in `p` on this topology through p = 10,000, including for
an iid component in the router's "small" (`G_c ≈ 0.1p`, block-contiguous)
branch, not only the strict nested branch S7b.1/S7b.4 measured at much
smaller scale (p ≤ 600).

Peak RSS also grows close to linearly: 1314 → 1775 → 3408 → 7958–8023 MB
(the ratio of RSS *increment* from p=1000's baseline, 1314 MB, to p=10000 is
≈ 6.6 MB, close to the raw p ratio of 10, allowing for the fixed ≈1.3 GB
process/package baseline).

## Wall-time-vs-p slope — **NOT linear**

This is the pilot's important negative finding. Fitting a log-log slope to
the JIT-free measurements (p=1000's first call carries Julia 1.12
precompilation overhead — its REML call, 0.97 s, and every later p's ML/REML
calls do not):

| interval | p ratio | ML time ratio | ML exponent | REML time ratio | REML exponent |
|---|---|---|---|---|---|
| 2500→5000 | 2.0× | 6.16× | **2.62** | 5.95× | **2.57** |
| 5000→10000 | 2.0× | 7.36× | **2.88** | 7.16× | **2.84** |
| 2500→10000 (overall) | 4.0× | — | **2.75** | — | **2.71** |

Wall-clock time grows roughly as `p^2.7–2.9` from p = 2500 to p = 10,000 on
this topology and hardware, **not** `O(p)`. This is despite `nnz(L)/dim`
being flat — the sparse Cholesky factor itself stays linear in fill, so the
superlinear cost is coming from somewhere else in the per-iteration path
(candidates, not diagnosed here since this pilot is `tools/`+`docs/` only,
no `src/` changes in scope: repeated O(p) component rebuilds — e.g. the
Takahashi selected-inversion in `_sparse_lss_phylo_comp` — inside the outer
optimizer loop rather than cached once; a non-sparse intermediate somewhere
in the gradient/REML backsolve path; or the outer optimizer itself needing
more Newton/quasi-Newton steps at larger `p`, which `niterations()` could
not confirm here since it reported `-1` for every LSS-route fit in this
pilot — worth checking directly in a follow-up, this pilot did not verify
Optim's own iteration count). The p=1000→2500 exponents (ML −1.01, REML
1.52) are not informative — p=1000 is the JIT-affected first call and 2500's
comparison to it is dominated by that one-off cost, not by fitting cost.

## Verdict

**`nnz(L)/dim = O(p)` holds to p = 10,000** on this topology (one
phylogenetic component + one `G_c ≈ 0.1p` iid component, router "small"
eligibility branch) — the design note's own §6 memory-bound claim is
confirmed at 16× the scale it was measured at (p=1000 vs. the note's own
p=600 ceiling), with a flat ~3.09 band, not the 91% one might see from a
mis-specified boundary case.

**Wall-clock time is NOT O(p)** at this scale on this hardware — measured
at roughly `p^2.7–2.9` from p=2500 to p=10000. The p=10,000 ML+REML pair
alone cost ≈ 333 s combined, vs. an `O(p)`-extrapolated ≈ 33 s from the
p=1000 baseline — a ~10× miss. **Do not promote an O(p) WALL-TIME claim for
this route from this pilot** (only the sparsity/memory claim is confirmed);
the discrepancy between flat fill and superlinear wall time is a concrete,
reproducible lead for whoever picks up the follow-up (the script and its
seed are checked in, so any of the 4 rows can be re-measured exactly).

**This is a pilot, not a benchmark.** Totoro is shared (384 cores, load
average 4.0–4.4 before the run from other users, rising to 4.5–6.0 during
it — this pilot itself used ≤ 1 core throughout, single-threaded); wall
times above are single-threaded wall-clock on a machine doing other work
concurrently, not a controlled/quiet-node measurement. The superlinear trend
is consistent across two independent doublings (2500→5000 and 5000→10000
land within 0.3 of each other in exponent, for both ML and REML), so it is
unlikely to be pure scheduling noise, but a repeat run at a quieter moment
would strengthen that reading.

## Cleanup

`pkill -u snakagaw -f 's7b_pilot'` run after the ladder; no process
referencing `s7b_pilot` remained (`pgrep -u snakagaw -f julia` showed only
the four processes belonging to the already-running `~/s7b_work/DRM.jl`
suite: the `timeout 5400 … Pkg.test()` wrapper and its child, plus a second
independent suite-related `julia … runtests.jl` process — all pre-existing,
none started or touched by this pilot). The `~/s7b_pilot/DRM.jl` checkout
itself was left in place (only processes were asked to be cleaned up).

## Post-fix re-measurement (S7b.6, head 86b7e3d4, Totoro, single-threaded, 2026-09-02)

The pre-fix exponent was not the engine's: profiling (p = 1000/2000/4000) showed the multi-component
router materialising the dense G×G tree correlation (`_phylo_correlation`, a cubic inverse) before it
decided the route, and the sparse branch never reads it. Fix = a `_LazyPhyloK` marker; the dense route
alone materialises it. Same ladder, same fixture, same seeds; log-likelihoods are bit-identical to the
pre-fix run (the objective is untouched), only the wasted work is gone.

| p | n | method | wall s (pre-fix 07c18534) | wall s (post-fix 86b7e3d4) | loglik identical | nnz(L)/dim | RSS MB post-fix |
|---|---|---|---|---|---|---|---|
| 1000 | 2000 | ML | 9.263 | 8.665 | yes | 3.085 | 1248.0 |
| 1000 | 2000 | REML | 0.971 | 0.764 | yes | 3.085 | 1248.0 |
| 2500 | 5000 | ML | 3.657 | 0.338 | yes | 3.089 | 1248.0 |
| 2500 | 5000 | REML | 3.917 | 0.941 | yes | 3.089 | 1248.0 |
| 5000 | 10000 | ML | 22.525 | 0.679 | yes | 3.091 | 1248.0 |
| 5000 | 10000 | REML | 23.323 | 1.548 | yes | 3.091 | 1301.3 |
| 10000 | 20000 | ML | 165.788 | 1.624 | yes | 3.092 | 1341.7 |
| 10000 | 20000 | REML | 167.017 | 2.863 | yes | 3.092 | 1350.0 |

Wall-time exponent 2500 → 10000: ML log(1.624/0.338)/log 4 ≈ 1.13; REML log(2.863/0.941)/log 4 ≈ 0.80.
Verdict: sparsity O(p) (unchanged) AND wall time O(p) to p = 10,000 on this fixture, post-fix. Memory
1.25–1.35 GB across the ladder (was 8 GB at p = 10,000). Log: `~/s7b_work/pilot-postfix-86b7e3d4.log` on
Totoro; local copy in the session scratchpad (`s7b6-pilot-postfix.log`). Totoro left with no pilot
processes. The original pre-fix table above is kept as the record of the finding.
