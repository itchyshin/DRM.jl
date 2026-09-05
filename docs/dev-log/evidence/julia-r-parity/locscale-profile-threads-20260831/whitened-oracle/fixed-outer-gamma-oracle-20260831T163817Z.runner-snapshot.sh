#!/bin/sh
set -u
base=/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-oracle
repo=/private/tmp/drm-parity-20260830/integration/DRM.jl
seed=${1:?newly captured production seed path required}
stamp=$(date -u +%Y%m%dT%H%M%SZ)
log="$base/fixed-outer-gamma-oracle-$stamp.log"
before="$base/fixed-outer-gamma-oracle-$stamp.before.sha256"
after="$base/fixed-outer-gamma-oracle-$stamp.after.sha256"
cmd="$base/fixed-outer-gamma-oracle-$stamp.command.txt"
pidfile="$base/fixed-outer-gamma-oracle-current.pid"
script_snapshot="$base/fixed-outer-gamma-oracle-$stamp.script-snapshot.jl"
runner_snapshot="$base/fixed-outer-gamma-oracle-$stamp.runner-snapshot.sh"
status_receipt="$base/fixed-outer-gamma-oracle-$stamp.status.json"
cp "$base/fixed_outer_gamma_oracle.jl" "$script_snapshot"
cp "$0" "$runner_snapshot"
sha256sum "$repo/src/inference.jl" "$repo/test/test_locscale_profile_threads.jl" \
  "$repo/src/locscale_kernels.jl" "$base/fixed_outer_gamma_oracle.jl" \
  /private/tmp/drm-parity-20260830/profile-threads-s11/profile-nuisance-corrected-replay-20260831T160339Z.jls "$seed" > "$before"
printf '%s\n' "julia --startup-file=no --project=$repo $base/fixed_outer_gamma_oracle.jl $seed" > "$cmd"
if python3 - "$repo" "$base" "$seed" "$log" "$pidfile" "$status_receipt" <<'PY'
import json, os, signal, subprocess, sys, time
repo, base, seed, log, pidfile, receipt = sys.argv[1:]
command = ["julia", "--startup-file=no", f"--project={repo}", f"{base}/fixed_outer_gamma_oracle.jl", seed]
started = time.monotonic()
with open(log, "wb") as out:
    proc = subprocess.Popen(command, stdout=out, stderr=subprocess.STDOUT, start_new_session=True)
    with open(pidfile, "w", encoding="utf-8") as handle:
        handle.write(f"pid={proc.pid}\nlog={log}\nseed={seed}\n")
    try:
        status = proc.wait(timeout=180)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            status = proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            status = proc.wait()
        timed_out = True
    else:
        timed_out = False
elapsed = time.monotonic() - started
with open(receipt, "w", encoding="utf-8") as handle:
    json.dump({"pid": proc.pid, "status": status, "wall_seconds": elapsed,
               "timeout_seconds": 180, "timed_out": timed_out, "log": log,
               "seed": seed}, handle, sort_keys=True)
if timed_out:
    print(f"S11_WHITE_TIMEOUT=180 status={status}")
    raise SystemExit(124)
print(f"S11_WHITE_PROCESS_PID={proc.pid}")
print(f"S11_WHITE_SUBPROCESS_STATUS={status}")
print(f"S11_WHITE_WALL_SECONDS={elapsed:.6f}")
raise SystemExit(status)
PY
then
  status=0
else
  status=$?
fi
sha256sum "$repo/src/inference.jl" "$repo/test/test_locscale_profile_threads.jl" \
  "$repo/src/locscale_kernels.jl" "$base/fixed_outer_gamma_oracle.jl" \
  /private/tmp/drm-parity-20260830/profile-threads-s11/profile-nuisance-corrected-replay-20260831T160339Z.jls "$seed" > "$after"
cat "$log"
exit "$status"
