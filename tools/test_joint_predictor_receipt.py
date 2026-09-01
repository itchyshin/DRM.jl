#!/usr/bin/env python3
"""Negative controls for the joint-model acceptance checker (also run with -O)."""
import copy
from pathlib import Path
import sys
import tomllib

from check_joint_predictor_receipt import check


def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: test_joint_predictor_receipt.py REFERENCE_TOML RECEIPT_TOML JULIA_ROOT")
    reference_path, receipt_path, source_root = map(Path, sys.argv[1:])
    reference = tomllib.loads(reference_path.read_text())
    original = tomllib.loads(receipt_path.read_text())
    check(reference, original, source_root)
    failures = 0
    for damage in ("mean", "variance", "likelihood", "rows", "mask", "missing_case", "theta", "nobs", "source_hash", "both_missing", "denominator"):
        current_reference = copy.deepcopy(reference)
        receipt = copy.deepcopy(original)
        case = receipt["cases"]["gaussian"]
        if damage == "mean":
            case["conditional_mean"][4] += 0.01
        elif damage == "variance":
            case["conditional_variance"][4] += 0.01
        elif damage == "likelihood":
            case["row_loglik"][4] += 0.01
        elif damage == "rows":
            case["original_row"][0:2] = reversed(case["original_row"][0:2])
        elif damage == "mask":
            case["x_observed"][0] = not case["x_observed"][0]
        elif damage == "missing_case":
            del receipt["cases"]["bernoulli"]
        elif damage == "theta":
            case["theta"][0] += 0.01
        elif damage == "nobs":
            case["nobs"] += 1
        elif damage == "source_hash":
            key = next(iter(receipt["source_sha256"]))
            receipt["source_sha256"][key] = "0" * 64
        elif damage == "both_missing":
            # Below the numerical tolerance, but violates the exact normalizer.
            case["row_loglik"][1] = 1e-11
        elif damage == "denominator":
            expected = current_reference["gaussian"]
            for values in (expected, case):
                for key, vector in values.items():
                    if isinstance(vector, list) and len(vector) == 160:
                        vector.pop()
            expected["native_loglik"] = sum(expected["row_loglik"])
            case["nll"] = -sum(case["row_loglik"])
            case["nobs"] = sum(case["y_observed"])
        try:
            check(current_reference, receipt, source_root)
        except ValueError:
            failures += 1
        else:
            raise RuntimeError("checker accepted damaged " + damage)
    print(f"JOINT_RECEIPT_NEGATIVES_PASS={failures}")


if __name__ == "__main__":
    main()
