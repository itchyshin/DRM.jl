# Gaussian components live pilot
OWNS: tools/parity_conditional_components.R

- [x] G1: Four additional Gaussian component cases pass32prediction outputs and dense likelihood checks
  CHECK: cd /private/tmp/drm-parity-20260830/DRM.jl && Rscript tools/parity_conditional_components.R /private/tmp/drm-parity-20260830/s10-components-candidate /private/tmp/drm-parity-20260830/DRM.jl /private/tmp/drm-parity-20260830/components-green-002.json > /private/tmp/drm-parity-20260830/components-green-002.raw.log 2>&1; run_status=$?; cat /private/tmp/drm-parity-20260830/components-green-002.raw.log; exit "$run_status"
  EXPECT: COMPONENT_ADAPTER_PASS; LIKELIHOOD_PASS; FIT_PARITY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=Julia exit. | Activating project at `/private/tmp/drm-parity-20260830/DRM.jl`

The first RI-only baseline execution is retained as components-red-001.json.
This execution tests the isolated components patch, excluding unfinished ZOB edits. Independent-fit failures remain required even when an
adapter-only oracle passes. Estimate≤2minutes including compilation.
