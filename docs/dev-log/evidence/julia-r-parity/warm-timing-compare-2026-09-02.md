# warm_timing_compare output — 2026-09-02 sweep (contended Mac; see warm-workflow-registry.md)

## threads = 1
| workflow | leg | threads | R calls | R median (s) | Julia calls | Julia median (s) | ratio (R/Julia) | verdict |
|---|---|---|---|---|---|---|---|---|
| bernoulli_mixed | fit | 1 | 1 | 0.442832 | 4 | 0.0727 | 6.09x | julia faster |
| bernoulli_mixed | predict | 1 | 1078 | 0.000232 | 13131 | 1.9e-5 | 12.21x | julia faster |
| bernoulli_mixed | uncertainty | 1 | 3 | 0.097124 | 33 | 0.007606 | 12.77x | julia faster |
| biv_q4_phylo_ml | fit | 1 | 3 | 0.109602 | 12 | 0.021876 | 5.01x | julia faster |
| biv_q4_phylo_ml | predict | 1 | 1295 | 0.000181 | 16012 | 1.6e-5 | 11.31x | julia faster |
| biv_q4_phylo_ml | uncertainty | 1 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| biv_q4_phylo_reml | fit | 1 | 3 | 0.098578 | 15 | 0.01777 | 5.55x | julia faster |
| biv_q4_phylo_reml | predict | 1 | 1449 | 0.000171 | 15648 | 1.6e-5 | 10.69x | julia faster |
| biv_q4_phylo_reml | uncertainty | 1 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| gauss_lss_sd_group | fit | 1 | 1 | 0.54733 | 180 | 0.001407 | 389.0x | julia faster |
| gauss_lss_sd_group | predict | 1 | 944 | 0.000274 | 12846 | 1.9e-5 | 14.42x | julia faster |
| gauss_lss_sd_group | uncertainty | 1 | 3 | 0.100655 | 2396 | 0.000104 | 967.84x | julia faster |
| gauss_lss_sd_phylo | fit | 1 | 2 | 0.226803 | 2 | 0.175131 | 1.3x | julia faster |
| gauss_lss_sd_phylo | predict | 1 | 1016 | 0.000245 | 25038 | 1.0e-5 | 24.5x | julia faster |
| gauss_lss_sd_phylo | uncertainty | 1 | 6 | 0.047489 | 10 | 0.027466 | 1.73x | julia faster |
| gauss_mixed_phylo_mean | fit | 1 | 4 | 0.066658 | 749 | 0.000329 | 202.61x | julia faster |
| gauss_mixed_phylo_mean | predict | 1 | 1100 | 0.000221 | 29389 | 8.0e-6 | 27.63x | julia faster |
| gauss_mixed_phylo_mean | uncertainty | 1 | 20 | 0.012934 | 6270 | 4.0e-5 | 323.35x | julia faster |
| large_sparse_lss_p2000 | fit | 1 | 1 | 6.960477 | 1 | 0.398176 | 17.48x | julia faster |
| large_sparse_lss_p2000 | predict | 1 | 374 | 0.000673 | 3304 | 7.6e-5 | 8.86x | julia faster |
| large_sparse_lss_p2000 | uncertainty | 1 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| lognormal_locscale | fit | 1 | 9 | 0.029571 | 1068 | 0.000234 | 126.37x | julia faster |
| lognormal_locscale | predict | 1 | 1000 | 0.000254 | 15619 | 1.6e-5 | 15.88x | julia faster |
| lognormal_locscale | uncertainty | 1 | 31 | 0.007977 | 7055 | 3.5e-5 | 227.91x | julia faster |
| meta_analysis_meta_V | fit | 1 | 11 | 0.023931 | 1130 | 0.000222 | 107.8x | julia faster |
| meta_analysis_meta_V | predict | 1 | 972 | 0.000261 | 20443 | 1.2e-5 | 21.75x | julia faster |
| meta_analysis_meta_V | uncertainty | 1 | 54 | 0.004658 | 12653 | 2.0e-5 | 232.9x | julia faster |
| poisson_mixed | fit | 1 | 3 | 0.092528 | 55 | 0.004621 | 20.02x | julia faster |
| poisson_mixed | predict | 1 | 1145 | 0.000217 | 13292 | 1.9e-5 | 11.42x | julia faster |
| poisson_mixed | uncertainty | 1 | 16 | 0.015834 | 1019 | 0.000245 | 64.63x | julia faster |

## G5 verdict per workflow

- **bernoulli_mixed**: WIN -- Julia faster on every compared leg
- **biv_q4_phylo_ml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **biv_q4_phylo_reml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **gauss_lss_sd_group**: WIN -- Julia faster on every compared leg
- **gauss_lss_sd_phylo**: WIN -- Julia faster on every compared leg
- **gauss_mixed_phylo_mean**: WIN -- Julia faster on every compared leg
- **large_sparse_lss_p2000**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **lognormal_locscale**: WIN -- Julia faster on every compared leg
- **meta_analysis_meta_V**: WIN -- Julia faster on every compared leg
- **poisson_mixed**: WIN -- Julia faster on every compared leg

## threads = 2
| workflow | leg | threads | R calls | R median (s) | Julia calls | Julia median (s) | ratio (R/Julia) | verdict |
|---|---|---|---|---|---|---|---|---|
| bernoulli_mixed | fit | 2 | 1 | 0.452874 | 5 | 0.061584 | 7.35x | julia faster |
| bernoulli_mixed | predict | 2 | 1077 | 0.000233 | 12393 | 2.0e-5 | 11.65x | julia faster |
| bernoulli_mixed | uncertainty | 2 | 3 | 0.098051 | 34 | 0.007465 | 13.13x | julia faster |
| biv_q4_phylo_ml | fit | 2 | 3 | 0.107702 | 12 | 0.021226 | 5.07x | julia faster |
| biv_q4_phylo_ml | predict | 2 | 1372 | 0.000164 | 16354 | 1.5e-5 | 10.93x | julia faster |
| biv_q4_phylo_ml | uncertainty | 2 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| biv_q4_phylo_reml | fit | 2 | 3 | 0.091772 | 15 | 0.016738 | 5.48x | julia faster |
| biv_q4_phylo_reml | predict | 2 | 1357 | 0.000184 | 16219 | 1.5e-5 | 12.27x | julia faster |
| biv_q4_phylo_reml | uncertainty | 2 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| gauss_lss_sd_group | fit | 2 | 1 | 0.543583 | 187 | 0.001343 | 404.75x | julia faster |
| gauss_lss_sd_group | predict | 2 | 923 | 0.000268 | 13596 | 1.8e-5 | 14.89x | julia faster |
| gauss_lss_sd_group | uncertainty | 2 | 3 | 0.095766 | 2455 | 0.000102 | 938.88x | julia faster |
| gauss_lss_sd_phylo | fit | 2 | 2 | 0.228945 | 3 | 0.123305 | 1.86x | julia faster |
| gauss_lss_sd_phylo | predict | 2 | 1112 | 0.000225 | 25186 | 1.0e-5 | 22.5x | julia faster |
| gauss_lss_sd_phylo | uncertainty | 2 | 6 | 0.048196 | 10 | 0.027183 | 1.77x | julia faster |
| gauss_mixed_phylo_mean | fit | 2 | 4 | 0.066435 | 779 | 0.000322 | 206.32x | julia faster |
| gauss_mixed_phylo_mean | predict | 2 | 1170 | 0.00021 | 30623 | 8.0e-6 | 26.25x | julia faster |
| gauss_mixed_phylo_mean | uncertainty | 2 | 21 | 0.012476 | 6750 | 3.7e-5 | 337.19x | julia faster |
| large_sparse_lss_p2000 | fit | 2 | 1 | 6.935229 | 1 | 0.396708 | 17.48x | julia faster |
| large_sparse_lss_p2000 | predict | 2 | 374 | 0.000673 | 3222 | 7.8e-5 | 8.63x | julia faster |
| large_sparse_lss_p2000 | uncertainty | 2 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| lognormal_locscale | fit | 2 | 9 | 0.029114 | 1029 | 0.000243 | 119.81x | julia faster |
| lognormal_locscale | predict | 2 | 993 | 0.000254 | 15131 | 1.7e-5 | 14.94x | julia faster |
| lognormal_locscale | uncertainty | 2 | 32 | 0.0079 | 6882 | 3.6e-5 | 219.44x | julia faster |
| meta_analysis_meta_V | fit | 2 | 11 | 0.024207 | 1151 | 0.000215 | 112.59x | julia faster |
| meta_analysis_meta_V | predict | 2 | 1004 | 0.000245 | 19421 | 1.3e-5 | 18.85x | julia faster |
| meta_analysis_meta_V | uncertainty | 2 | 53 | 0.004719 | 12897 | 1.9e-5 | 248.37x | julia faster |
| poisson_mixed | fit | 2 | 3 | 0.094146 | 55 | 0.004618 | 20.39x | julia faster |
| poisson_mixed | predict | 2 | 1137 | 0.000221 | 12909 | 1.9e-5 | 11.63x | julia faster |
| poisson_mixed | uncertainty | 2 | 16 | 0.016589 | 1009 | 0.000248 | 66.89x | julia faster |

## G5 verdict per workflow

- **bernoulli_mixed**: WIN -- Julia faster on every compared leg
- **biv_q4_phylo_ml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **biv_q4_phylo_reml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **gauss_lss_sd_group**: WIN -- Julia faster on every compared leg
- **gauss_lss_sd_phylo**: WIN -- Julia faster on every compared leg
- **gauss_mixed_phylo_mean**: WIN -- Julia faster on every compared leg
- **large_sparse_lss_p2000**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **lognormal_locscale**: WIN -- Julia faster on every compared leg
- **meta_analysis_meta_V**: WIN -- Julia faster on every compared leg
- **poisson_mixed**: WIN -- Julia faster on every compared leg

## threads = 4
| workflow | leg | threads | R calls | R median (s) | Julia calls | Julia median (s) | ratio (R/Julia) | verdict |
|---|---|---|---|---|---|---|---|---|
| bernoulli_mixed | fit | 4 | 1 | 0.448459 | 5 | 0.061678 | 7.27x | julia faster |
| bernoulli_mixed | predict | 4 | 1081 | 0.000229 | 12449 | 1.9e-5 | 12.05x | julia faster |
| bernoulli_mixed | uncertainty | 4 | 3 | 0.095367 | 33 | 0.007624 | 12.51x | julia faster |
| biv_q4_phylo_ml | fit | 4 | 3 | 0.107032 | 12 | 0.021895 | 4.89x | julia faster |
| biv_q4_phylo_ml | predict | 4 | 1367 | 0.000167 | 15725 | 1.6e-5 | 10.44x | julia faster |
| biv_q4_phylo_ml | uncertainty | 4 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| biv_q4_phylo_reml | fit | 4 | 3 | 0.093658 | 16 | 0.016718 | 5.6x | julia faster |
| biv_q4_phylo_reml | predict | 4 | 1425 | 0.000176 | 15631 | 1.6e-5 | 11.0x | julia faster |
| biv_q4_phylo_reml | uncertainty | 4 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| gauss_lss_sd_group | fit | 4 | 1 | 0.533528 | 180 | 0.001368 | 390.01x | julia faster |
| gauss_lss_sd_group | predict | 4 | 1010 | 0.000245 | 13033 | 1.9e-5 | 12.89x | julia faster |
| gauss_lss_sd_group | uncertainty | 4 | 3 | 0.094145 | 2389 | 0.000103 | 914.03x | julia faster |
| gauss_lss_sd_phylo | fit | 4 | 2 | 0.23202 | 3 | 0.116846 | 1.99x | julia faster |
| gauss_lss_sd_phylo | predict | 4 | 1114 | 0.000226 | 24915 | 1.0e-5 | 22.6x | julia faster |
| gauss_lss_sd_phylo | uncertainty | 4 | 6 | 0.045943 | 10 | 0.026832 | 1.71x | julia faster |
| gauss_mixed_phylo_mean | fit | 4 | 4 | 0.064482 | 686 | 0.000371 | 173.81x | julia faster |
| gauss_mixed_phylo_mean | predict | 4 | 1130 | 0.000216 | 28941 | 9.0e-6 | 24.0x | julia faster |
| gauss_mixed_phylo_mean | uncertainty | 4 | 20 | 0.012708 | 6303 | 3.8e-5 | 334.42x | julia faster |
| large_sparse_lss_p2000 | fit | 4 | 1 | 6.845561 | 1 | 0.392941 | 17.42x | julia faster |
| large_sparse_lss_p2000 | predict | 4 | 372 | 0.00066 | 3385 | 7.4e-5 | 8.92x | julia faster |
| large_sparse_lss_p2000 | uncertainty | 4 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| lognormal_locscale | fit | 4 | 9 | 0.029833 | 1075 | 0.000232 | 128.59x | julia faster |
| lognormal_locscale | predict | 4 | 1005 | 0.000248 | 14991 | 1.7e-5 | 14.59x | julia faster |
| lognormal_locscale | uncertainty | 4 | 33 | 0.007735 | 6961 | 3.6e-5 | 214.86x | julia faster |
| meta_analysis_meta_V | fit | 4 | 11 | 0.023954 | 1144 | 0.000219 | 109.38x | julia faster |
| meta_analysis_meta_V | predict | 4 | 1017 | 0.000245 | 19848 | 1.2e-5 | 20.42x | julia faster |
| meta_analysis_meta_V | uncertainty | 4 | 53 | 0.004874 | 12656 | 2.0e-5 | 243.7x | julia faster |
| poisson_mixed | fit | 4 | 3 | 0.094302 | 56 | 0.00452 | 20.86x | julia faster |
| poisson_mixed | predict | 4 | 1092 | 0.000232 | 13562 | 1.9e-5 | 12.21x | julia faster |
| poisson_mixed | uncertainty | 4 | 16 | 0.016155 | 1007 | 0.000248 | 65.14x | julia faster |

## G5 verdict per workflow

- **bernoulli_mixed**: WIN -- Julia faster on every compared leg
- **biv_q4_phylo_ml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **biv_q4_phylo_reml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **gauss_lss_sd_group**: WIN -- Julia faster on every compared leg
- **gauss_lss_sd_phylo**: WIN -- Julia faster on every compared leg
- **gauss_mixed_phylo_mean**: WIN -- Julia faster on every compared leg
- **large_sparse_lss_p2000**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **lognormal_locscale**: WIN -- Julia faster on every compared leg
- **meta_analysis_meta_V**: WIN -- Julia faster on every compared leg
- **poisson_mixed**: WIN -- Julia faster on every compared leg

## threads = 8
| workflow | leg | threads | R calls | R median (s) | Julia calls | Julia median (s) | ratio (R/Julia) | verdict |
|---|---|---|---|---|---|---|---|---|
| bernoulli_mixed | fit | 8 | 1 | 0.444737 | 4 | 0.073056 | 6.09x | julia faster |
| bernoulli_mixed | predict | 8 | 1083 | 0.000229 | 12293 | 2.0e-5 | 11.45x | julia faster |
| bernoulli_mixed | uncertainty | 8 | 3 | 0.100016 | 33 | 0.00761 | 13.14x | julia faster |
| biv_q4_phylo_ml | fit | 8 | 3 | 0.10826 | 12 | 0.021164 | 5.12x | julia faster |
| biv_q4_phylo_ml | predict | 8 | 1382 | 0.000167 | 15660 | 1.6e-5 | 10.44x | julia faster |
| biv_q4_phylo_ml | uncertainty | 8 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| biv_q4_phylo_reml | fit | 8 | 3 | 0.095287 | 15 | 0.01676 | 5.69x | julia faster |
| biv_q4_phylo_reml | predict | 8 | 1481 | 0.000169 | 15680 | 1.6e-5 | 10.56x | julia faster |
| biv_q4_phylo_reml | uncertainty | 8 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| gauss_lss_sd_group | fit | 8 | 1 | 0.538779 | 185 | 0.001347 | 399.98x | julia faster |
| gauss_lss_sd_group | predict | 8 | 995 | 0.000254 | 13108 | 2.0e-5 | 12.7x | julia faster |
| gauss_lss_sd_group | uncertainty | 8 | 3 | 0.095068 | 2467 | 0.000101 | 941.27x | julia faster |
| gauss_lss_sd_phylo | fit | 8 | 2 | 0.234988 | 3 | 0.119358 | 1.97x | julia faster |
| gauss_lss_sd_phylo | predict | 8 | 1056 | 0.000237 | 23971 | 1.0e-5 | 23.7x | julia faster |
| gauss_lss_sd_phylo | uncertainty | 8 | 6 | 0.047248 | 10 | 0.026797 | 1.76x | julia faster |
| gauss_mixed_phylo_mean | fit | 8 | 4 | 0.062862 | 708 | 0.000347 | 181.16x | julia faster |
| gauss_mixed_phylo_mean | predict | 8 | 1105 | 0.000221 | 28645 | 9.0e-6 | 24.56x | julia faster |
| gauss_mixed_phylo_mean | uncertainty | 8 | 20 | 0.012723 | 6486 | 3.8e-5 | 334.82x | julia faster |
| large_sparse_lss_p2000 | fit | 8 | 1 | 6.879455 | 1 | 0.394386 | 17.44x | julia faster |
| large_sparse_lss_p2000 | predict | 8 | 402 | 0.000629 | 3354 | 7.4e-5 | 8.5x | julia faster |
| large_sparse_lss_p2000 | uncertainty | 8 | - | - | - | - | - | N/A (JULIA MISSING (n/a or not run)) |
| lognormal_locscale | fit | 8 | 9 | 0.029706 | 1001 | 0.000245 | 121.25x | julia faster |
| lognormal_locscale | predict | 8 | 1004 | 0.000247 | 14637 | 1.7e-5 | 14.53x | julia faster |
| lognormal_locscale | uncertainty | 8 | 33 | 0.007589 | 6718 | 3.7e-5 | 205.11x | julia faster |
| meta_analysis_meta_V | fit | 8 | 11 | 0.023827 | 1126 | 0.000219 | 108.8x | julia faster |
| meta_analysis_meta_V | predict | 8 | 995 | 0.000253 | 19889 | 1.3e-5 | 19.46x | julia faster |
| meta_analysis_meta_V | uncertainty | 8 | 54 | 0.004553 | 12732 | 1.9e-5 | 239.63x | julia faster |
| poisson_mixed | fit | 8 | 3 | 0.094434 | 56 | 0.004546 | 20.77x | julia faster |
| poisson_mixed | predict | 8 | 1113 | 0.000225 | 11551 | 2.0e-5 | 11.25x | julia faster |
| poisson_mixed | uncertainty | 8 | 16 | 0.016627 | 1005 | 0.000248 | 67.04x | julia faster |

## G5 verdict per workflow

- **bernoulli_mixed**: WIN -- Julia faster on every compared leg
- **biv_q4_phylo_ml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **biv_q4_phylo_reml**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **gauss_lss_sd_group**: WIN -- Julia faster on every compared leg
- **gauss_lss_sd_phylo**: WIN -- Julia faster on every compared leg
- **gauss_mixed_phylo_mean**: WIN -- Julia faster on every compared leg
- **large_sparse_lss_p2000**: WIN -- Julia faster on every compared leg (legs not compared: uncertainty -- see registry doc for whether n/a or not-yet-run)
- **lognormal_locscale**: WIN -- Julia faster on every compared leg
- **meta_analysis_meta_V**: WIN -- Julia faster on every compared leg
- **poisson_mixed**: WIN -- Julia faster on every compared leg

