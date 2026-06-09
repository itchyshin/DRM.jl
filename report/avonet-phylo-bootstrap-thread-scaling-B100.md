# AVONET phylogenetic bootstrap thread scaling

Date: 2026-06-08

This report summarizes the direct DRM.jl thread-scaling smoke for the real
AVONET/Hackett Gaussian phylogenetic mean model. It is not an `engine =
"julia"` R-bridge timing table yet.

## Model and thread policy

- Data: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/AVONET3_BirdTree.csv`
- Tree: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/Stage2_Hackett_MCC_no_neg.tre`
- Tree tips: 9,993
- All-node tree states: 19,985
- Model: `log(Mass) ~ z(Hand-Wing.Index) + z(Beak.Length_Culmen) + phylo(1 | species)`, `sigma ~ 1`
- Gaussian algorithm: current `:auto` sparse EM route, `g_tol = 1e-4`
- Bootstrap size per cell: `B = 100`
- Julia: 1.10.0
- Machine core count: 20 physical/logical cores, reported as 16 performance cores and 4 efficiency cores
- Fair-threading policy: `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, and Julia threads varied

The fair-threading policy matters because this benchmark is measuring outer
bootstrap parallelism. BLAS and OpenMP are pinned to one thread so an outer
20-thread Julia loop does not accidentally multiply into 20 Julia workers times
many hidden linear-algebra or OpenMP workers.

## Results

| Julia threads | used | failed | elapsed_s | sec_per_refit | speedup_vs_1_thread | efficiency |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 100 | 0 | 178.230 | 1.782 | 1.00 | 1.00 |
| 2 | 100 | 0 | 85.916 | 0.859 | 2.07 | 1.04 |
| 4 | 100 | 0 | 45.241 | 0.452 | 3.94 | 0.99 |
| 8 | 100 | 0 | 32.042 | 0.320 | 5.56 | 0.70 |
| 16 | 100 | 0 | 27.604 | 0.276 | 6.46 | 0.40 |
| 20 | 100 | 0 | 20.291 | 0.203 | 8.78 | 0.44 |

The fastest observed setting in this B=100 smoke was 20 Julia threads. Scaling
was close to linear up to 4 threads, then flattened, but using all 20 cores was
still faster than stopping at 16 performance cores for this workload.

## Projection, not a completed run

At the 20-thread B=100 rate, a `B = 1000` bootstrap would be about 203 seconds
and a `B = 10000` bootstrap would be about 2,029 seconds, or 34 minutes. Those
are linear projections from the B=100 smoke, not completed B=1000 or B=10000
runs on 20 threads.

The completed larger run currently on disk is the four-thread `B = 1000` run:
`report/avonet-phylo-gaussian-bootstrap-B1000.md`. It used 1000/1000 refits,
failed 0, and took 442.041 seconds for the replicate phase.

## Reading

This is the first local evidence that the AVONET sparse phylogenetic bootstrap
does benefit strongly from Julia's within-process threading. The result does not
settle the R-versus-Julia bridge claim yet, because the R bridge still needs the
same sparse all-node phylogenetic route and inference plumbing before the two
engines can be timed on byte-comparable fits.

The next engineering target is still the sparse inference layer: profile CIs
and Wald SEs for this EM route need an attached objective/information
calculation. Bootstrap already has the natural parallel shape, but profile
likelihood needs the same sparse machinery exposed as an objective that
`profile_result` can call.
