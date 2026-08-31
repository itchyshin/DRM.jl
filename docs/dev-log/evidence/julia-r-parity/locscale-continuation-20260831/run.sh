#!/usr/bin/env bash
set -u
cd /home/snakagaw/drm_parity_blas_c0675b16_001 || exit 2
out=locscale-core-pilot-001
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_PKG_OFFLINE=true JULIA_PKG_PRECOMPILE_AUTO=0
start=$(date +%s)
date -u +%FT%TZ
sha256sum Project.toml test/Project.toml test/Manifest.toml "$out/run.jl" "$out/run.sh"
sha256sum -c "$out/expected.sha256" > "$out/provenance.log" 2>&1 || { echo 97 > "$out/exit-status.txt"; exit 97; }
find src test -type f -name '*.jl' -print0 | sort -z | xargs -0 sha256sum > "$out/before.sha256"
timeout -k 10 300 /home/snakagaw/.juliaup/bin/julia +1.10.10 --project=test --startup-file=no "$out/run.jl"
rc=$?
find src test -type f -name '*.jl' -print0 | sort -z | xargs -0 sha256sum > "$out/after.sha256"
cmp "$out/before.sha256" "$out/after.sha256" || rc=98
end=$(date +%s)
echo "ELAPSED_SECONDS $((end-start))"
echo "$rc" > "$out/exit-status.txt"
exit "$rc"
