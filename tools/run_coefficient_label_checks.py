"""Bounded local verification; preserve the exact inputs and every failure."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("prefix", type=Path, help="New receipt path prefix (.json and .log)")
args = parser.parse_args()
prefix = args.prefix
if not prefix.is_absolute():
    prefix = root / prefix
if any(prefix.with_suffix(s).exists() for s in (".json", ".log")):
    raise RuntimeError("Receipt already exists")
paths = sorted(set([
    *root.joinpath("src").rglob("*.jl"),
    root / "Project.toml", root / "Manifest.toml",
    root / "tools/check_coefficient_labels.jl", Path(__file__).resolve(),
    root / "docs/src/r-julia-bridge.md", root / "test/runtests.jl",
    root / "docs/dev-log/evidence/julia-r-parity/coefficient-labels/native-numeric-labels.tsv",
    root / "docs/dev-log/evidence/julia-r-parity/coefficient-labels/native-nested-labels.tsv",
    root / "docs/dev-log/evidence/julia-r-parity/coefficient-labels/native-scalar-labels.tsv",
    root / "docs/dev-log/evidence/julia-r-parity/coefficient-labels/native-conditional-labels.tsv",
    *(root / "test" / name for name in (
        "test_bridge_materialization_collision.jl", "test_bridge_formula_labels.jl", "test_bridge_lss_labels.jl",
        "test_bridge.jl", "test_bridge_formula_translation.jl", "test_bridge_profile_target.jl")),
]))

def manifest():
    return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}

before = manifest()
env = dict(os.environ, JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1")
command = ["julia", "--project=.", "tools/check_coefficient_labels.jl"]
start = time.monotonic()
timed_out = False
with prefix.with_suffix(".log").open("x") as log:
    process = subprocess.Popen(command, cwd=root, env=env, stdout=log,
                               stderr=subprocess.STDOUT, start_new_session=True)
    try:
        code = process.wait(timeout=180)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(process.pid, signal.SIGTERM)
        try:
            code = process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            code = process.wait()
elapsed = time.monotonic() - start
after = manifest()
output = prefix.with_suffix(".log").read_text()
passed = (code == 0 and not timed_out and before == after
          and "COEFFICIENT_LABEL_COMBINED_PASS" in output)
receipt = dict(command=command, cwd=str(root), source_before=before, source_after=after,
               baseline_git=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
               exit=code, timed_out=timed_out, elapsed=elapsed, status="PASS" if passed else "FAIL")
prefix.with_suffix(".json").write_text(json.dumps(receipt, indent=2) + "\n")
print(output)
print(receipt["status"], "elapsed", elapsed, "exit", code, "inputs", len(before))
sys.exit(0 if passed else 1)
