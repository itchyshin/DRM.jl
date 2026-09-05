#!/bin/sh
set -eu

run_dir=/private/tmp/drm-parity-20260830/profile-threads-s11
repo=/private/tmp/drm-parity-20260830/integration/DRM.jl
stamp=$(date -u +%Y%m%dT%H%M%SZ)
log="$run_dir/profile-nuisance-replay-${stamp}.log"
before="$run_dir/profile-nuisance-replay-${stamp}.before.sha256"
after="$run_dir/profile-nuisance-replay-${stamp}.after.sha256"
command_receipt="$run_dir/profile-nuisance-replay-${stamp}.command.txt"
pid_receipt="$run_dir/profile-nuisance-replay-current.pid"
script="$run_dir/replay-profile-nuisance-termination.jl"

(cd "$repo" && shasum -a 256 src/inference.jl test/test_locscale_profile_threads.jl src/locscale_profile.jl src/locscale_fit.jl src/locscale_inner.jl "$script" "$0") > "$before"
printf '%s\n' "JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --project=. $script" > "$command_receipt"

set +e
/usr/bin/python3 - "$repo" "$log" "$script" "$pid_receipt" <<'PY'
import os
import signal
import subprocess
import sys
import time

repo, log, script, pid_receipt = sys.argv[1:]
env = os.environ.copy()
env["JULIA_NUM_THREADS"] = "4"
env["OPENBLAS_NUM_THREADS"] = "1"
started = time.monotonic()
with open(log, "w", encoding="utf-8") as stream:
    process = subprocess.Popen(
        ["julia", "--startup-file=no", "--project=.", script], cwd=repo, env=env,
        stdout=stream, stderr=subprocess.STDOUT, start_new_session=True,
    )
    with open(pid_receipt, "w", encoding="utf-8") as receipt:
        receipt.write(f"pid={process.pid}\nlog={log}\n")
    print(f"S11_PROCESS_PID={process.pid}", file=stream)
    try:
        status = process.wait(timeout=60)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            status = process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            status = process.wait()
        print("S11_TIMEOUT_60S", file=stream)
        status = 124
    print(f"S11_SUBPROCESS_STATUS={status}", file=stream)
    print(f"S11_REPLAY_WALL_SECONDS={time.monotonic() - started:.6f}", file=stream)
sys.exit(status)
PY
status=$?
set -e
(cd "$repo" && shasum -a 256 src/inference.jl test/test_locscale_profile_threads.jl src/locscale_profile.jl src/locscale_fit.jl src/locscale_inner.jl "$script" "$0") > "$after"
cat "$log"
exit "$status"
