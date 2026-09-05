#!/usr/bin/env python3
"""Verify joint-model values against independent references and exact source bytes.

Requires Python 3.11+ for its standard-library TOML parser.
"""
import hashlib
import math
from pathlib import Path
import sys
import tomllib


def require(ok, message):
    if not ok:
        raise ValueError(message)


def numeric_match(actual, expected, tolerance, name):
    require(len(actual) == len(expected), name + ": row count differs")
    require(all(isinstance(x, (int, float)) and math.isfinite(x) for x in actual), name + ": nonfinite value")
    require(max(abs(x-y) for x, y in zip(actual, expected)) <= tolerance, name + ": numerical disagreement")


def check(reference, receipt, source_root):
    require(set(receipt["cases"]) == {"gaussian", "bernoulli"}, "case denominator differs")
    require(receipt["runtime"]["julia_threads"] == receipt["runtime"]["blas_threads"] == 1, "resource budget differs")
    require(receipt["source_unchanged"], "source changed during run")
    sources = receipt["source_sha256"]
    paths = sorted(p.relative_to(source_root / "src").as_posix()
                   for p in (source_root / "src").rglob("*") if p.is_file())
    require(set(paths) == set(sources), "source file manifest differs")
    for name in paths:
        require(hashlib.sha256((source_root / "src" / name).read_bytes()).hexdigest() == sources[name], "source hash differs: " + name)
    for name in ("gaussian", "bernoulli"):
        actual, expected = receipt["cases"][name], reference[name]
        require(expected["original_row"] == list(range(1, 161)), name + ": frozen reference row denominator differs")
        masks = list(zip(expected["x_observed"], expected["y_observed"]))
        require({mask: masks.count(mask) for mask in set(masks)} == {
            (True, True): 147, (True, False): 3, (False, True): 9, (False, False): 1},
            name + ": frozen reference masks differ")
        require(actual["original_row"] == expected["original_row"], name + ": original rows differ")
        require(actual["x_observed"] == expected["x_observed"] and actual["y_observed"] == expected["y_observed"], name + ": masks differ")
        require(actual["status"] == expected["status"], name + ": conditional statuses differ")
        require(actual["nobs"] == sum(expected["y_observed"]), name + ": nobs differs")
        numeric_match(actual["theta"], expected["theta"], 0, name + ": fixed parameter vector")
        for field in ("row_loglik", "conditional_mean", "conditional_variance"):
            numeric_match(actual[field], expected[field], 1e-8, name + ": " + field)
        require(abs(sum(actual["row_loglik"]) - expected["native_loglik"]) <= 1e-6, name + ": native log-likelihood differs")
        require(math.isfinite(actual["nll"]) and abs(actual["nll"] + sum(actual["row_loglik"])) <= 1e-10, name + ": total objective differs")
        for i, (xo, yo) in enumerate(zip(expected["x_observed"], expected["y_observed"])):
            if not xo and not yo:
                require(actual["row_loglik"][i] == 0, name + ": both-missing normalizer differs")


def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: check_joint_predictor_receipt.py REFERENCE_TOML RECEIPT_TOML JULIA_ROOT")
    reference_path, receipt_path, source_root = map(Path, sys.argv[1:])
    reference = tomllib.loads(reference_path.read_text())
    receipt = tomllib.loads(receipt_path.read_text())
    require(receipt["reference_sha256"] == hashlib.sha256(reference_path.read_bytes()).hexdigest(), "reference hash differs")
    check(reference, receipt, source_root)
    print("JOINT_RECEIPT_PASS cases=2 rows=320 likelihoods=2 conditional_moments=640")


if __name__ == "__main__":
    main()
