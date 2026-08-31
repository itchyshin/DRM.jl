# Bounded package continuation — 31 August 2026

The earlier full-suite pilot stopped after 301 seconds (exit 124) while running
`test_location_only_reml_mme.jl`. It did not pass the full suite.

## Completed files

| File | Passing assertions | Elapsed time | Outcome |
|---|---:|---:|---|
| `test_location_only_reml_mme.jl` | 602 (209 + 144 + 249) | 20 s wall | Complete; exit 0 |
| `test_profile_sigma_a.jl` | 20 | 102.3 s test time | Complete |
| `test_bootstrap_sigma_a.jl` | 36 | 12.0 s test time | Complete |
| `test_reml_sigma_phylo.jl` | 12 | 103.4 s test time | Complete |

All four files ran unchanged on Totoro, Julia 1.10.10, with one Julia thread and
one BLAS thread. The 326 expected Julia source/test hashes matched; before/after
manifests were identical. Numerical source matches the integration checkout at
5e9d5883. These 670 assertions include internal status/schema contracts; they are
not 670 independent statistical scenarios or evidence of calibrated coverage.

## Incomplete group and continuation

The four-file group comprised profile, bootstrap, sigma-phylo REML and Newton
sigma-phylo REML tests. It reached its 300-second cap (exit 124). The first three
files emitted completion markers. The Newton file reported 34 passing assertions
in seven testsets, then stopped in the testset beginning at line 231. There was
no completion marker for that file or the group. Those 34 assertions do not
complete the fifth file.

The next run isolates the entire original Newton file, with a fresh estimate and
cap. Completed files are not rerun merely because the later file timed out.
The original failed/capped receipts remain here even if the isolated run passes.

## Timing and interpretation

The q4 profile test calls the public profile function for four among-group axes
(sd_mu1, sd_mu2, sd_sigma1, sd_sigma2), at level 0.90. Defaults include
n_newton = 40, g_tol = 1e-3 and max_bisect = 14. An unconstrained refit precedes
constrained endpoint searches, with warm starts, conditional cold retries and
upper-bracket expansion. This describes requested work, not a measured cost
breakdown. These intervals differ from Ayumi's Gaussian LSS mu:temp_z target.
Test timings include compilation and setup; they are not warm benchmarks.

The first launch observation timed out after 15 seconds because the background
command retained a connection descriptor. The same job completed after 20 seconds;
its terminal output was collected without launching a duplicate.

All programme G0–G8 gates remain open. These checks do not replace the full suite,
R/direct-Julia/bridge parity, Ayumi's canonical-tree workflow, interval coverage,
or the registered warm-workflow performance denominator. No DRAC job or long
campaign was launched.
