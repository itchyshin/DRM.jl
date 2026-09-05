# Generic profile nuisance status and bridge disclosure
OWNS: Terra src/inference.jl generic profile, src/visualization.jl, test/test_profile_nuisance_status.jl; root src/bridge.jl, narrow generated R wrapper, test wiring and receipts.
- [x] G1: Analytical RED and acceptance contract retained before implementation.
  EVIDENCE: CHECK-EXPECT.md; red002 behavioral plotting failures (undefined-helper errors not proof); original-nonconverged002 reproduces finite rejected40iteration result.
- [x] G2: Finite converged nuisance solves, explicit failures, plotting and exact returned endpoints pass deterministic checks.
  CHECK: JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM,Test,LinearAlgebra; BLAS.set_num_threads(1); include("test/test_profile_nuisance_status.jl"); include("test/test_profile_acceptance_oracles.jl"); include("test/test_bridge_profile_status.jl"); println("PROFILE_NUISANCE_STATUS_PASS")'
  EXPECT: PROFILE_NUISANCE_STATUS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=bridge exposes selected profile failure |   10     10  0.1s | PROFILE_NUISANCE_STATUS_PASS
- [x] G3: Existing profile, plotting and exact-target bridge checks pass with original tolerances.
  CHECK: JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM,Test,LinearAlgebra; BLAS.set_num_threads(1); include("test/test_profile_ci.jl"); include("test/test_visualization.jl"); include("test/test_bridge_profile_target.jl"); println("PROFILE_NEIGHBOURS_PASS")'
  EXPECT: PROFILE_NEIGHBOURS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=PROFILE_NEIGHBOURS_PASS | WARNING: using Distributions.Poisson in module Main conflicts with an existing identifier.
- [x] G4: Ordinary R public wrapper discloses profile failures and successful controls with retained source hashes.
  CHECK: cd /private/tmp/drm-parity-20260830/drmTMB && Rscript tools/check-julia-profile-status-receipt.R docs/dev-log/evidence/julia-r-parity/profile-nuisance-status/public-004.rds --self-test
  EXPECT: PROFILE_STATUS_SELFTEST_PASS:12 damaged receipts rejected
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=PROFILE_STATUS_RECEIPT_PASS: actual-success oracle and15 injected transport cases; current source hashes match | PROFILE_STATUS_SELFTEST_PASS:12 damaged receipts rejected
- [x] G5: Rose independent review and Melissa scope reconciliation retain specialized backends/performance/strict failures as separate open obligations.
  EVIDENCE: Rose independently approved source, checker and unchanged public004; Terra Melissa in profile-gradient-next-slice.md retains every broader obligation. No speed/coverage/specialized solver claim.
- [x] G6: Source/test/docs wiring and exact-source reports retained; original broader programme not claimed complete.
  EVIDENCE: combined002212PASS100currentinputs; docs00119examples101currentinputs; public004/checker003141currentinputs12damages; source tests wired excluding foreignS5 staging. After-task/checklog retained; all programmeG0-G8 OPEN.
