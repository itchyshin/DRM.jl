#!/usr/bin/env python3
"""Foreground runner for the unwired private whitening focused test."""
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
REPO = Path("/private/tmp/drm-parity-20260830/integration/DRM.jl")
SOURCE = REPO / "src/locscale_whitened.jl"
TEST = REPO / "test/test_locscale_whitened.jl"
REFERENCE = Path("/private/tmp/drm-parity-20260830/profile-threads-s11/whitened-boundary-reference/reference-fixture.toml")
REFERENCE_SHA = "90469e7c304453c0e400d4c19897e263b61beb0912c0a1c5bc677b4f39fee6ad"
CAP_SECONDS = 60

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> int:
    stamp = sys.argv[1] if len(sys.argv) == 2 else dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    if not stamp.endswith("Z"):
        raise SystemExit("stamp must be actual UTC ending in Z")
    base = HERE / f"whitened-focused-{stamp}"
    log, status = base.with_suffix(".log"), base.with_suffix(".status.json")
    source_snapshot, test_snapshot = base.with_suffix(".source-snapshot.jl"), base.with_suffix(".test-snapshot.jl")
    if any(p.exists() for p in (log, status, source_snapshot, test_snapshot)):
        raise SystemExit("refusing to overwrite an existing focused-test receipt")
    if sha(REFERENCE) != REFERENCE_SHA:
        raise SystemExit("immutable boundary reference SHA mismatch")
    source_snapshot.write_bytes(SOURCE.read_bytes())
    test_snapshot.write_bytes(TEST.read_bytes())
    before = {"source": sha(SOURCE), "test": sha(TEST)}
    env = dict(os.environ, JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1")
    command = ["julia", "--project=/private/tmp/drm-parity-20260830/integration/DRM.jl", "--startup-file=no",
               "-e", 'using LinearAlgebra; @assert Threads.nthreads()==1 && BLAS.get_num_threads()==1; include("test/test_locscale_whitened.jl")']
    started, timed_out = time.monotonic(), False
    with log.open("xb") as handle:
        try:
            proc = subprocess.Popen(command, cwd=REPO, env=env, stdout=handle,
                                    stderr=subprocess.STDOUT, start_new_session=True)
            returncode = proc.wait(timeout=CAP_SECONDS)
        except subprocess.TimeoutExpired:
            timed_out, returncode = True, 124
            os.killpg(proc.pid, 9)
            proc.wait()
    after = {"source": sha(SOURCE), "test": sha(TEST)}
    receipt = {"stamp": stamp, "cwd": str(REPO), "command": command,
               "estimate_seconds": 30, "cap_seconds": CAP_SECONDS,
               "elapsed_seconds": time.monotonic() - started, "returncode": returncode,
               "timed_out": timed_out, "threads": {"JULIA_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1"},
               "reference_sha256": sha(REFERENCE), "source_snapshot": str(source_snapshot),
               "source_snapshot_sha256": sha(source_snapshot), "test_snapshot": str(test_snapshot),
               "test_snapshot_sha256": sha(test_snapshot), "before": before, "after": after,
               "unchanged": before == after,
               "scope": "private unwired whitening helper only; no legacy-routing, inference, or profile claim"}
    status.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(json.dumps(receipt, sort_keys=True))
    return returncode if before == after else 1

if __name__ == "__main__":
    raise SystemExit(main())
