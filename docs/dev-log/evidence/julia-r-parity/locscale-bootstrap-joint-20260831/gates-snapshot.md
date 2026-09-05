# Canonical joint bootstrap and simulation scales

OWNS: src/locscale_simulate.jl, test/test_locscale_bootstrap_simulator.jl
Root additionally owns separately leased gaussian_core, module, inference, bridge.
Mathematical contract: /private/tmp/drm-parity-20260830/locscale-bootstrap-s11/contract.md.

- [x] G0: retained numerical red and reviewed symbolic contract
  EVIDENCE: retained sampler195735Z red; independent covariance/family review in locscale-bootstrap-joint-20260831/review.md
  Manual: current marginal simulator missing for coupled fit; NB2/Gamma draws
  disagree with independent nonunit-scale references. Missing helper symbol
  alone is not a numerical red. Rose checks covariance/parameter mappings.
- [x] G1: conditional family scales
  CWD: .
  CHECK: julia --startup-file=no --project=. -e 'include("test/test_simulate_scale_conventions.jl"); println("SIMULATE_SCALE_CONVENTIONS_OK")'
  EXPECT: SIMULATE_SCALE_CONVENTIONS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=bootstrap auxiliary override is per-draw and does not mutate fit |    8      8  0.4s | SIMULATE_SCALE_CONVENTIONS_OK
- [x] G2: joint distribution and ownership
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/locscale-bootstrap-s11/run_final.py final 4
  EXPECT: 'code': 0
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=/private/tmp/drm-parity-20260830/locscale-bootstrap-s11/final-threads4-20260831T202151Z | {'command': ['julia', '--startup-file=no', '--project=/private/tmp/drm-parity-20260830/integration/DRM.jl', '/private/tmp/drm-parity-20260830/locscale
- [ ] G3: direct and bridge refits, serial/threaded
  Manual: finite B2 smoke; preserve failure statuses, estimator, trials, row/tree
  maps and packing. Stamp exact commands after prepared fixture is reviewed,
  before numerical runs. No interval coverage claim from B2.
- [ ] G4: neighbour suites, reviews and retained final-source receipts
  Manual: Rose and Melissa independently verify scope; Gamma public-scale
  normalization remains named parity debt; original programme G0-G8 stays open.

G1: scales194830Z1pass5numericalfail; expanded194953Z5pass5fail4missing-keyworderrors.
Repair195136Z14/14; existing Gaussian/Poisson neighbours195329Z32/32.
Rose reviewed generic sourceeafb80c0/test6b20ba84. Joint samplerG2-G4stillopen.
Sampler195028Z fixtureconstructorerror;195505Z7pass1incorrectAMD-assumptionfail
and1realgenericstructured-parsererror. Correctfixture before finalsamplerproof.

G3 retained refit pilot201405Z: serial/threaded both used1/2, same failed seed.
Diagnostic201529Z: valid inner state, gradient1.006e-5 above requested1e-8.
Continuation experiment201626Z: same objective, LBFGS8iterations, gradient9.95e-10.
Before implementation, bind the retained B2 refit fixture:
Planned refit command: JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --project=. -e 'include("test/test_locscale_bootstrap_refit.jl"); println("LOCSCALE_B2_REFIT_OK")'
Planned refit success marker: LOCSCALE_B2_REFIT_OK
Tree/bridge and other-family refits remain required parts of G3.
