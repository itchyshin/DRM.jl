#!/usr/bin/env python3
"""Exercise the acceptance checker with Python optimization enabled/disabled."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: test_conditional_receipt.py VALID_RECEIPT")
    original = json.loads(Path(sys.argv[1]).read_text())
    checker = Path(__file__).with_name("check_conditional_receipt.py")
    cases = {"valid": original}
    damaged = copy.deepcopy(original)
    damaged["cases"]["numeric_group"]["observations"]["stored/mu/link"]["bridge"][0] += 0.1
    cases["damaged"] = damaged
    missing = copy.deepcopy(original)
    missing["cases"]["numeric_group"]["observations"]["stored/mu/link"]["bridge"].pop()
    cases["missing_row"] = missing
    malformed = copy.deepcopy(original)
    del malformed["cases"]["constant_scale"]
    cases["missing_case"] = malformed
    passed = 0
    with tempfile.TemporaryDirectory(prefix="conditional-check-") as directory:
        for name, value in cases.items():
            path = Path(directory) / (name + ".json")
            path.write_text(json.dumps(value))
            for flags in ([], ["-O"]):
                result = subprocess.run([sys.executable, *flags, str(checker), str(path)],
                                        text=True, capture_output=True, timeout=10)
                expected = name == "valid"
                success_token = "CONDITIONAL_ADAPTER_RECOMPUTED=24" in result.stdout
                if (result.returncode == 0) != expected or success_token != expected:
                    raise RuntimeError(f"{name} {flags}: invalid verdict {result.returncode}\n{result.stdout}\n{result.stderr}")
                passed += 1
    print(f"CHECKER_NORMAL_AND_OPTIMIZED_PASS={passed}")


if __name__ == "__main__":
    main()
