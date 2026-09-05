#!/usr/bin/env python3
"""Foreground 30 s runner for the fixed-state certificate script."""
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / "diagnose.jl"
REPO = Path("/private/tmp/drm-parity-20260830/integration/DRM.jl")
NEIGHBORS = Path("/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-return-neighbors/whitened-return-neighbors-20260831T182759Z.jls")
DESIGN = Path("/private/tmp/drm-parity-20260830/profile-threads-s11/post-compensation-profile/post-compensation-profile-20260831T175800Z.jls")
CAP_SECONDS = 30
EXPECTED_NEIGHBORS_SHA = "c007a27a05121d47426b0e246b495caf3079563ec4f1c950c6d39ae344dbbd44"
EXPECTED_DESIGN_SHA = "fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> int:
    stamp = sys.argv[1] if len(sys.argv) == 2 else dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    if not stamp.endswith("Z"):
        raise SystemExit("stamp must be actual UTC ending in Z")
    base = HERE / f"whitened-return-certificate-{stamp}"
    log, status, out, snapshot = (base.with_suffix(s) for s in (".log", ".status.json", ".jls", ".script-snapshot.jl"))
    if any(p.exists() for p in (log, status, out, snapshot)):
        raise SystemExit("refusing to overwrite an existing attempted receipt")
    if sha(NEIGHBORS) != EXPECTED_NEIGHBORS_SHA or sha(DESIGN) != EXPECTED_DESIGN_SHA:
        raise SystemExit("immutable input SHA mismatch")
    snapshot.write_bytes(SCRIPT.read_bytes())
    before = {p: sha(REPO / p) for p in ("src/locscale_inner.jl", "src/locscale_grad.jl", "src/locscale_marginal.jl", "src/locscale_fit.jl", "src/locscale_infer.jl")}
    env = dict(os.environ, JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1")
    command = ["julia", "--project=/private/tmp/drm-parity-20260830/integration/DRM.jl",
               "--startup-file=no", str(SCRIPT), str(out)]
    started = time.monotonic()
    timed_out = False
    with log.open("xb") as handle:
        try:
            proc = subprocess.Popen(command, cwd=REPO, env=env, stdout=handle,
                                    stderr=subprocess.STDOUT, start_new_session=True)
            returncode = proc.wait(timeout=CAP_SECONDS)
        except subprocess.TimeoutExpired:
            timed_out, returncode = True, 124
            os.killpg(proc.pid, 9)
            proc.wait()
    after = {p: sha(REPO / p) for p in before}
    result = {"stamp": stamp, "command": command, "cwd": str(REPO), "cap_seconds": CAP_SECONDS,
              "elapsed_seconds": time.monotonic() - started, "returncode": returncode, "timed_out": timed_out,
              "threads": {"JULIA_NUM_THREADS": env["JULIA_NUM_THREADS"], "OPENBLAS_NUM_THREADS": env["OPENBLAS_NUM_THREADS"]},
              "script_snapshot": str(snapshot), "script_sha256": sha(snapshot),
              "neighbors_sha256": sha(NEIGHBORS), "design_sha256": sha(DESIGN),
              "before_hashes": before, "after_hashes": after, "source_unchanged": before == after,
              "output_exists": out.exists(), "prospective_gate": "stored only in JLS; execution status is not numerical acceptance"}
    status.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    return returncode

if __name__ == "__main__":
    raise SystemExit(main())
