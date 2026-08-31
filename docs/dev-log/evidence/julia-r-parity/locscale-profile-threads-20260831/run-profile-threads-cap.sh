#!/bin/sh
set -eu

threads=${1:?usage: run-profile-threads-cap.sh THREADS expected-red|pass}
mode=${2:?usage: run-profile-threads-cap.sh THREADS expected-red|pass}
case "$threads:$mode" in
  1:pass|4:pass|4:expected-red) ;;
  *) echo "invalid S11 pilot mode" >&2; exit 64 ;;
esac

run_dir=/private/tmp/drm-parity-20260830/profile-threads-s11
repo=/private/tmp/drm-parity-20260830/integration/DRM.jl
stamp=$(date -u +%Y%m%dT%H%M%SZ)
log="$run_dir/profile-threads-${threads}-${mode}-${stamp}.log"
manifest="$run_dir/profile-threads-${threads}-${mode}-${stamp}.sha256"

(cd "$repo" && shasum -a 256 src/inference.jl test/test_locscale_profile_threads.jl "$0") > "$manifest"

set +e
/usr/bin/python3 - "$repo" "$threads" "$log" <<'PY'
import os
import signal
import subprocess
import sys

repo, threads, log = sys.argv[1:]
command = [
    "julia", "--startup-file=no", "--project=.", "-e",
    'include("test/test_locscale_profile_threads.jl"); println("S11_PROFILE_THREADS_PASS")',
]
env = os.environ.copy()
env["JULIA_NUM_THREADS"] = threads
env["OPENBLAS_NUM_THREADS"] = "1"
with open(log, "w", encoding="utf-8") as stream:
    process = subprocess.Popen(
        command, cwd=repo, env=env, stdout=stream, stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    try:
        status = process.wait(timeout=180)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            status = process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            status = process.wait()
        print("S11_TIMEOUT_180S", file=stream)
        sys.exit(124)
    print(f"S11_SUBPROCESS_STATUS={status}", file=stream)
sys.exit(status)
PY
status=$?
set -e

case "$mode" in
  expected-red)
    failures=$(grep -Fc 'Test Failed at' "$log" || true)
    if [ "$status" -eq 1 ] && [ "$failures" -eq 1 ] && grep -Fq '0 errored' "$log" && grep -Fq 'threaded.threaded' "$log"; then
      echo "S11_EXPECTED_RED"
      exit 0
    fi
    echo "S11_UNEXPECTED_PILOT_STATUS=$status" >&2
    exit 1
    ;;
  pass)
    cat "$log"
    [ "$status" -eq 0 ] && grep -Fq 'S11_PROFILE_THREADS_PASS' "$log"
    ;;
esac
