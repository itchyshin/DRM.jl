#!/usr/bin/env python3
"""Recompute the registered Gaussian component oracle evidence."""
import copy
import json
import math
from pathlib import Path
import sys

CASES = {"independent_slope", "correlated_slope", "crossed_slope", "crossed_intercepts"}
KEYS = {f"{where}/{dpar}/{scale}" for where in ("stored", "newdata")
        for dpar in ("mu", "sigma") for scale in ("link", "response")}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def errors(receipt):
    require(set(receipt["cases"]) == CASES, "case manifest mismatch")
    prediction_errors, likelihood_errors, fit_errors = [], [], []
    for name, case in receipt["cases"].items():
        require(set(case["observations"]) == KEYS, "prediction manifest mismatch")
        for key, obs in case["observations"].items():
            n = len(case["data"] if key.startswith("stored/") else case["newdata"])
            vectors = [obs.get(k, []) for k in ("bridge", "dense_oracle", "native")]
            valid = all(len(v) == n and all(math.isfinite(x) for x in v) for v in vectors)
            if not valid:
                prediction_errors.append((name, key))
                fit_errors.append((name, key))
                continue
            bridge, oracle, native = vectors
            if max(abs(a-b) for a, b in zip(bridge, oracle)) >= 1e-10:
                prediction_errors.append((name, key))
            if max(abs(a-b) for a, b in zip(bridge, native)) >= 4e-6:
                fit_errors.append((name, key))
        ll = case["likelihood"]
        delta = abs(ll["dense"] - ll["Julia"])
        if not math.isfinite(delta) or delta >= 1e-8:
            likelihood_errors.append(name)
        if case["convergence"] != [0, 0]:
            fit_errors.append((name, "convergence"))
    return prediction_errors, likelihood_errors, fit_errors


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: check_component_receipt.py RECEIPT")
    receipt = json.loads(Path(sys.argv[1]).read_text())
    require(receipt["completed_predictions"] == 32, "prediction count mismatch")
    require(receipt["source_unchanged"], "source changed during run")
    require(receipt["Julia_runtime"]["threads"] == 1 and receipt["Julia_runtime"]["blas"] == 1, "wrong resource budget")
    prediction_errors, likelihood_errors, fit_errors = errors(receipt)
    require(not prediction_errors and not likelihood_errors, "numerical oracle disagreement")
    damaged = copy.deepcopy(receipt)
    for case in damaged["cases"].values():
        for scale in ("link", "response"):
            obs = case["observations"][f"stored/mu/{scale}"]
            obs["bridge"] = [x + 0.1 for x in obs["bridge"]]
    pe, _, _ = errors(damaged)
    require(len(pe) == 8, "biased conditional means not rejected")
    damaged = copy.deepcopy(receipt)
    damaged["cases"]["correlated_slope"]["likelihood"]["Julia"] += 0.1
    require(errors(damaged)[1] == ["correlated_slope"], "biased likelihood not rejected")
    damaged = copy.deepcopy(receipt)
    damaged["cases"]["crossed_slope"]["observations"]["stored/mu/link"]["bridge"].pop()
    require(errors(damaged)[0] == [("crossed_slope", "stored/mu/link")], "missing row not rejected")
    print("COMPONENT_ORACLES_RECOMPUTED=32; SHIFTED_REJECTED=8; LIKELIHOOD_REJECTED=1; MISSING_ROW_REJECTED=1")
    print("Independent-fit failures:", len(fit_errors), fit_errors)


if __name__ == "__main__":
    main()
