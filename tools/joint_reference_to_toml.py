#!/usr/bin/env python3
"""Transport the independently generated numerical reference into Julia's stdlib TOML format."""
import hashlib
import json
from pathlib import Path
import sys


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: joint_reference_to_toml.py INPUT_JSON NEW_OUTPUT_TOML")
    source, target = map(Path, sys.argv[1:])
    if target.exists():
        raise ValueError("refusing to replace an existing fixture")
    data = json.loads(source.read_text())
    if set(data["cases"]) != {"gaussian", "bernoulli"}:
        raise ValueError("unexpected case manifest")
    lines = ["# Generated numerical data, not native package source.",
             'source_json_sha256 = "' + hashlib.sha256(source.read_bytes()).hexdigest() + '"',
             'native_receipt_sha256 = "' + data["native_receipt_sha256"] + '"']
    fields = ("original_row", "x", "y", "z", "x_observed", "y_observed", "theta", "theta_order",
              "native_loglik", "row_loglik", "conditional_mean", "conditional_variance", "status", "native_gradient_max")
    for name, case in data["cases"].items():
        n = len(case["original_row"])
        if n != 160 or case["original_row"] != list(range(1, n + 1)):
            raise ValueError("unexpected row mapping")
        for key in fields:
            if key not in ("theta", "theta_order", "native_loglik", "native_gradient_max") and len(case[key]) != n:
                raise ValueError("unexpected row length: " + key)
        masks = [(x, y) for x, y in zip(case["x_observed"], case["y_observed"])]
        if {mask: masks.count(mask) for mask in set(masks)} != {
                (True, True): 147, (True, False): 3, (False, True): 9, (False, False): 1}:
            raise ValueError("unexpected missingness masks")
        lines.append("\n[" + name + "]")
        lines.extend(key + " = " + json.dumps(case[key], allow_nan=False) for key in fields)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("\n".join(lines) + "\n")
    print("JOINT_REFERENCE_TOML_PASS cases=2 rows=320")


if __name__ == "__main__":
    main()
