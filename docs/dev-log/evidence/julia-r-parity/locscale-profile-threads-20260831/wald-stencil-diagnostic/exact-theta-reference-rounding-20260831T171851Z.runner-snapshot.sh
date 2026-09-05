#!/bin/zsh
set -euo pipefail
ROOT=/private/tmp/drm-parity-20260830/profile-threads-s11/wald-stencil-diagnostic
REPO=/private/tmp/drm-parity-20260830/integration/DRM.jl
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
SCRIPT="$ROOT/exact_theta_reference_rounding.jl"
LOG="$ROOT/exact-theta-reference-rounding-$STAMP.log"
STATUS="$ROOT/exact-theta-reference-rounding-$STAMP.status.json"
cp "$SCRIPT" "$ROOT/exact-theta-reference-rounding-$STAMP.script-snapshot.jl"
cp "$0" "$ROOT/exact-theta-reference-rounding-$STAMP.runner-snapshot.sh"
S11_STAMP="$STAMP" python3 - "$REPO" "$SCRIPT" "$LOG" "$STATUS" <<'PY'
import json, os, pathlib, signal, subprocess, sys, time
repo, script, log, status = sys.argv[1:]
command = ["julia", "--startup-file=no", "--project=.", script]
start = time.time()
with open(log, "wb") as out:
    proc = subprocess.Popen(command, cwd=repo, env=os.environ.copy(), stdout=out,
                            stderr=subprocess.STDOUT, start_new_session=True)
    timed_out = False
    try:
        code = proc.wait(timeout=30)
    except subprocess.TimeoutExpired:
        timed_out = True; os.killpg(proc.pid, signal.SIGTERM)
        try: code = proc.wait(timeout=3)
        except subprocess.TimeoutExpired: os.killpg(proc.pid, signal.SIGKILL); code = proc.wait()
payload = {"command": command, "pid": proc.pid, "status": code, "timed_out": timed_out,
           "timeout_seconds": 30, "wall_seconds": time.time()-start, "log": log}
pathlib.Path(status).write_text(json.dumps(payload, sort_keys=True)+"\n")
print(json.dumps(payload, sort_keys=True))
PY
