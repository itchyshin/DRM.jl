#!/usr/bin/env python3
"""Recompute bounded adapter evidence; deliberately damage it as a control."""
import argparse
import copy
import json
import math


def require(condition, message):
    if not condition:
        raise ValueError(message)


def adapter_errors(receipt):
    cases = receipt.get("cases", {})
    require(set(cases) == {"constant_scale", "varying_scale", "numeric_group"}, "case manifest mismatch")
    errors = []
    for name, case in cases.items():
        expected = {f"{where}/{dpar}/{scale}" for where in ("stored", "newdata")
                    for dpar in ("mu", "sigma") for scale in ("link", "response")}
        observations = case.get("observations", {})
        require(set(observations) == expected, "prediction manifest mismatch")
        for key, obs in observations.items():
            n = len(case["data"] if key.startswith("stored/") else case["newdata"])
            actual, oracle = obs.get("bridge", []), obs.get("dense_oracle", [])
            if len(actual) != n or len(oracle) != n:
                errors.append((name, key))
                continue
            delta = [abs(a-b) for a, b in zip(actual, oracle)]
            if not all(math.isfinite(x) for x in delta) or max(delta) >= 1e-10:
                errors.append((name, key))
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("receipt")
    args = parser.parse_args()
    with open(args.receipt, encoding="utf-8") as handle:
        receipt = json.load(handle)
    require(receipt["completed_predictions"] == 24, "prediction count mismatch")
    require(receipt["bridge_unchanged_during_run"], "bridge source changed")
    require(receipt["Julia_source_unchanged_during_run"], "Julia source changed")
    require(receipt["Julia_runtime"]["threads"] == 1, "wrong Julia thread budget")
    require(receipt["Julia_runtime"]["blas"] == 1, "wrong BLAS thread budget")
    require(not adapter_errors(receipt), "adapter predictions do not match dense oracle")
    # Never accept stored status labels in lieu of recomputing differences.
    damaged = copy.deepcopy(receipt)
    for case in damaged["cases"].values():
        for scale in ("link", "response"):
            obs = case["observations"][f"stored/mu/{scale}"]
            obs["bridge"] = [x + 0.1 for x in obs["bridge"]]
    errors = adapter_errors(damaged)
    require(len(errors) == 6 and all(key.startswith("stored/mu/") for _, key in errors), "biased control was not rejected")
    missing = copy.deepcopy(receipt)
    missing["cases"]["numeric_group"]["observations"]["stored/mu/link"]["bridge"].pop()
    require(adapter_errors(missing) == [("numeric_group", "stored/mu/link")], "missing row was not rejected")
    print("CONDITIONAL_ADAPTER_RECOMPUTED=24; DAMAGED_REJECTED=6; MISSING_ROW_REJECTED=1")
    print("Independent-fit parity is a separate gate; this checker does not close it.")


if __name__ == "__main__":
    main()
