#!/bin/bash
set -u
cd /home/snakagaw/drm_parity_integration_567fec06_001 || exit 90
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_PKG_OFFLINE=true JULIA_PKG_PRECOMPILE_AUTO=0
start=$(date +%s)
date -u +%FT%TZ
sha256sum Project.toml test/Project.toml test/Manifest.toml full-suite-pilot.jl full-suite-pilot.sh
find src test -type f -print0 | sort -z | xargs -0 sha256sum > full-suite-before.sha256
timeout -k 10 300 /home/snakagaw/.juliaup/bin/julia +1.10.10 --project=test --startup-file=no full-suite-pilot.jl
code=$?
find src test -type f -print0 | sort -z | xargs -0 sha256sum > full-suite-after.sha256
cmp full-suite-before.sha256 full-suite-after.sha256 || code=92
printf 'ELAPSED_SECONDS %s\n' "$(( $(date +%s) - start ))"
printf '%s\n' "$code" > full-suite-exit-status.txt
exit "$code"
