#!/usr/bin/env python3
import os
import pathlib
import subprocess
import sys

if len(sys.argv) != 2 or sys.argv[1] not in {"1", "4"}:
    raise SystemExit("usage: run.py {1|4}")

base = pathlib.Path(__file__).resolve().parent
env = os.environ.copy()
env["JULIA_NUM_THREADS"] = sys.argv[1]
env["OPENBLAS_NUM_THREADS"] = "1"
command = ["Rscript", "--vanilla", str(base / "actual-r-animal-spatial.R")]
try:
    completed = subprocess.run(command, cwd=base, env=env, text=True, capture_output=True, timeout=120)
except subprocess.TimeoutExpired as error:
    sys.stdout.write(error.stdout or "")
    sys.stderr.write(error.stderr or "")
    raise SystemExit("TIMEOUT_AFTER_120_SECONDS")
sys.stdout.write(completed.stdout)
sys.stderr.write(completed.stderr)
raise SystemExit(completed.returncode)
