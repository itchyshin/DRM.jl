# After-task: AVONET phylo Gaussian B=1000 bootstrap

Date: 2026-06-08

## Summary

Ran the larger repeated-refit benchmark requested for the real AVONET/Hackett
Gaussian phylogenetic mean model. This is direct DRM.jl evidence, not an R
bridge claim.

## Result

Command:

```sh
julia --project=. --threads=4 bench/avonet_phylo_gaussian_algorithms.jl \
  --g-tols=1e-4 --bootstrap-B=1000 --bootstrap-mode=threaded \
  --out=report/avonet-phylo-gaussian-bootstrap-B1000.md
```

Model:

- 9,993 Hackett tree tips;
- 19,985 all-node states;
- `log(Mass) ~ z(Hand-Wing.Index) + z(Beak.Length_Culmen) + phylo(1 | species)`;
- `sigma ~ 1`;
- current `algorithm = :auto` sparse EM route with `g_tol = 1e-4`;
- four Julia threads, BLAS pinned to one thread.

Bootstrap result:

| B | mode | workers | used | failed | elapsed_s | sec_per_refit |
|---:|---|---:|---:|---:|---:|---:|
| 1000 | threaded | 4 | 1000 | 0 | 442.041 | 0.442 |

At this observed rate, `B = 10000` would take about 4,420 seconds, or roughly
74 minutes, on the same four-thread local setup.

## Profile Status

The existing threaded profile machinery remains available for fitted objectives;
`bench/profile_inference_quick.jl` was rerun and regenerated
`report/inference-profile-quick.md`.

For this exact AVONET sparse EM route, profile CIs are still not available
because the fit has no attached `nll` closure. The next implementation slice is
a sparse objective/gradient or information layer for Gaussian phylo EM fits, so
`profile_result(fit; parm = :resd, threads = true)` has something to profile.
