#!/bin/bash
set -u
cd /home/snakagaw/drm_parity_integration_567fec06_001 || exit 90
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_PKG_PRECOMPILE_AUTO=0 JULIA_PKG_OFFLINE=true
start=$(date +%s)
date -u +%FT%TZ
sha256sum source.tar Manifest.toml pilot.jl pilot.sh
find src test -type f -print0 | sort -z | xargs -0 sha256sum > source-before.sha256
timeout 600 /home/snakagaw/.juliaup/bin/julia +1.10.10 --project=. pilot.jl
code=$?
find src test -type f -print0 | sort -z | xargs -0 sha256sum > source-after.sha256
cmp source-before.sha256 source-after.sha256 || code=91
printf 'ELAPSED_SECONDS %s\n' "$(( $(date +%s) - start ))"
printf '%s\n' "$code" > exit-status.txt
exit "$code"
