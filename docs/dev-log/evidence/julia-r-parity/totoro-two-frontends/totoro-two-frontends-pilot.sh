#!/bin/bash
set -u
cd /home/snakagaw/drm_parity_20260830_f67eeb80
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_PKG_PRECOMPILE_AUTO=0 JULIA_PKG_OFFLINE=true
printf 'START_UTC ';date -u +%FT%TZ
hostname
sha256sum source.tar
start=$(date +%s)
timeout 300 /home/snakagaw/.juliaup/bin/julia +1.10.10 --project=. -e 'using DRM, Test, LinearAlgebra; BLAS.set_num_threads(1); @assert realpath(pathof(DRM))==joinpath(pwd(),"src","DRM.jl"); println("RUNTIME julia=",VERSION," threads=",Threads.nthreads()," blas=",BLAS.get_num_threads()," source=",pathof(DRM)); include("test/test_joint_missing_two_predictor.jl"); include("test/test_joint_missing_two_frontend.jl"); include("test/test_joint_missing_two_bridge.jl"); println("TOTORO_TWO_FRONTENDS_PASS")'
code=$?
printf 'ELAPSED_SECONDS %s\n' "$(( $(date +%s) - start ))"
printf '%s\n' "$code" > exit-status.txt
exit "$code"
