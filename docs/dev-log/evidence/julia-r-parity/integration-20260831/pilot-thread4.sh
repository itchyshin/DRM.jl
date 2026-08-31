#!/bin/bash
set -u
cd /home/snakagaw/drm_parity_integration_567fec06_001 || exit 90
export JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 JULIA_PKG_PRECOMPILE_AUTO=0 JULIA_PKG_OFFLINE=true
start=$(date +%s)
date -u +%FT%TZ
sha256sum pilot-thread4.jl pilot-thread4.sh Manifest.toml
sha256sum -c source-before.sha256 > thread4-source-before.log || exit 91
timeout 120 /home/snakagaw/.juliaup/bin/julia +1.10.10 --project=. pilot-thread4.jl
code=$?
sha256sum -c source-before.sha256 > thread4-source-after.log || code=92
printf 'ELAPSED_SECONDS %s\n' "$(( $(date +%s) - start ))"
printf '%s\n' "$code" > thread4-exit-status.txt
exit "$code"
