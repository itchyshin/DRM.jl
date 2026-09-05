#!/bin/sh
set -u
base=/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-oracle
repo=/private/tmp/drm-parity-20260830/integration/DRM.jl
seed=${1:?newly captured production seed path required}
stamp=$(date -u +%Y%m%dT%H%M%SZ)
log="$base/directional-l21-expansion-$stamp.log"
output="$base/directional-l21-expansion-$stamp.jls"
before="$base/directional-l21-expansion-$stamp.before.sha256"
after="$base/directional-l21-expansion-$stamp.after.sha256"
pidfile="$base/directional-l21-expansion-current.pid"
script_snapshot="$base/directional-l21-expansion-$stamp.script-snapshot.jl"
runner_snapshot="$base/directional-l21-expansion-$stamp.runner-snapshot.sh"
status_receipt="$base/directional-l21-expansion-$stamp.status.json"
cp "$base/directional_l21_expansion.jl" "$script_snapshot"
cp "$0" "$runner_snapshot"
sha256sum "$repo/src/inference.jl" "$repo/test/test_locscale_profile_threads.jl" \
  "$repo/src/locscale_kernels.jl" "$base/directional_l21_expansion.jl" \
  "$base/fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl" \
  /private/tmp/drm-parity-20260830/profile-threads-s11/profile-nuisance-corrected-replay-20260831T160339Z.jls "$seed" > "$before"
if python3 - "$repo" "$base" "$seed" "$output" "$log" "$pidfile" "$status_receipt" <<'PY'
import json, os, signal, subprocess, sys, time
repo, base, seed, output, log, pidfile, receipt = sys.argv[1:]
command = ["julia", "--startup-file=no", f"--project={repo}", f"{base}/directional_l21_expansion.jl", seed, output]
started = time.monotonic()
with open(log, "wb") as out:
    proc = subprocess.Popen(command, stdout=out, stderr=subprocess.STDOUT, start_new_session=True)
    with open(pidfile, "w", encoding="utf-8") as handle:
        handle.write(f"pid={proc.pid}\nlog={log}\noutput={output}\n")
    try:
        status = proc.wait(timeout=60)
        timed_out = False
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            status = proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            status = proc.wait()
        timed_out = True
elapsed = time.monotonic() - started
with open(receipt, "w", encoding="utf-8") as handle:
    json.dump({"pid": proc.pid, "status": status, "wall_seconds": elapsed, "timeout_seconds": 60,
               "timed_out": timed_out, "log": log, "output": output, "seed": seed}, handle, sort_keys=True)
print(f"S11_WHITE_EXPANSION_PROCESS_PID={proc.pid}")
print(f"S11_WHITE_EXPANSION_STATUS={status}")
print(f"S11_WHITE_EXPANSION_WALL_SECONDS={elapsed:.6f}")
raise SystemExit(124 if timed_out else status)
PY
then
  status=0
else
  status=$?
fi
sha256sum "$repo/src/inference.jl" "$repo/test/test_locscale_profile_threads.jl" \
  "$repo/src/locscale_kernels.jl" "$base/directional_l21_expansion.jl" \
  "$base/fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl" \
  /private/tmp/drm-parity-20260830/profile-threads-s11/profile-nuisance-corrected-replay-20260831T160339Z.jls "$seed" "$output" > "$after"
cat "$log"
exit "$status"
