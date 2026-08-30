#!/usr/bin/env python3
"""Check component evidence fails closed, including under python -O."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: test_component_receipt.py VALID_RECEIPT")
    original = json.loads(Path(sys.argv[1]).read_text())
    checker = Path(__file__).with_name("check_component_receipt.py")
    cases = {"valid": original}
    for name in ("biased_mean", "biased_likelihood", "missing_row", "missing_case", "nonfinite", "resource_budget"):
        value = copy.deepcopy(original)
        case = value["cases"]["correlated_slope"]
        if name == "biased_mean":
            case["observations"]["stored/mu/link"]["bridge"][0] += 0.1
        elif name == "biased_likelihood":
            case["likelihood"]["Julia"] += 0.1
        elif name == "missing_row":
            case["observations"]["stored/mu/link"]["bridge"].pop()
        elif name == "missing_case":
            del value["cases"]["crossed_slope"]
        elif name == "nonfinite":
            case["observations"]["stored/mu/link"]["bridge"][0] = float("nan")
        elif name == "resource_budget":
            value["Julia_runtime"]["blas"] = 16
        cases[name] = value
    passed = 0
    with tempfile.TemporaryDirectory(prefix="component-check-") as directory:
        for name, value in cases.items():
            path = Path(directory) / (name + ".json")
            path.write_text(json.dumps(value))
            for flags in ([], ["-O"]):
                result = subprocess.run([sys.executable, *flags, str(checker), str(path)],
                                        text=True, capture_output=True, timeout=10)
                expected = name == "valid"
                success = "COMPONENT_ORACLES_RECOMPUTED=32" in result.stdout
                if (result.returncode == 0) != expected or success != expected:
                    raise RuntimeError(f"{name} {flags}: invalid verdict {result.returncode}\n{result.stdout}\n{result.stderr}")
                passed += 1
    print(f"COMPONENT_CHECKER_NORMAL_AND_OPTIMIZED_PASS={passed}")


if __name__ == "__main__":
    main()
