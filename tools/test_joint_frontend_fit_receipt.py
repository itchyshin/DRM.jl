#!/usr/bin/env python3
"""Damage controls for the public joint-frontend receipt validator."""
import copy
import sys
import tomllib
from pathlib import Path

from check_joint_frontend_fit_receipt import check


def first_available(receipt):
    return next(index for index, value in enumerate(receipt["cases"]["gaussian"]["imputed_all"]["std_error_available"]) if value)


def damage_likelihood(receipt):
    case = receipt["cases"]["gaussian"]
    case["loglik"] -= 1e-3
    case["nll"] += 1e-3


def damage_positive_definite_hessian(receipt):
    receipt["cases"]["gaussian"]["hessian"][0][0] = -1.0


def damage_available_standard_error(receipt, value):
    receipt["cases"]["gaussian"]["imputed_all"]["std_error"][first_available(receipt)] = value


def main():
    if len(sys.argv) != 5:
        raise SystemExit("usage: test_joint_frontend_fit_receipt.py DATA_REFERENCE UNCERTAINTY_REFERENCE RECEIPT JULIA_ROOT")
    data, uncertainty, receipt_path, root = map(Path, sys.argv[1:])
    good = tomllib.loads(receipt_path.read_text())
    check(data, uncertainty, good, root)
    mutations = {
        "data hash": lambda receipt: receipt.update(data_sha256="0" * 64),
        "source unchanged": lambda receipt: receipt.update(source_unchanged=False),
        "thread budget": lambda receipt: receipt["runtime"].update(blas_threads=8),
        "case denominator": lambda receipt: receipt["cases"].pop("bernoulli"),
        "gradient": lambda receipt: receipt["cases"]["gaussian"]["gradient"].__setitem__(0, 1e-3),
        "Hessian PD": damage_positive_definite_hessian,
        "H*V": lambda receipt: receipt["cases"]["gaussian"]["covariance"][0].__setitem__(0, 0.0),
        "analytic likelihood": damage_likelihood,
        "analytic mean": lambda receipt: receipt["cases"]["gaussian"]["imputed_all"]["estimate"].__setitem__(1, 999.0),
        "analytic variance": lambda receipt: damage_available_standard_error(receipt, 999.0),
        "standard-error sign": lambda receipt: damage_available_standard_error(receipt, -1.0),
        "imputed missing": lambda receipt: receipt["cases"]["gaussian"]["imputed_missing"]["model_row"].pop(),
        "imputed se=false": lambda receipt: receipt["cases"]["gaussian"]["imputed_no_se"]["std_error_available"].__setitem__(0, True),
        "source/status source": lambda receipt: receipt["cases"]["gaussian"]["imputed_all"]["source"].append("overlong"),
        "source/status status": lambda receipt: receipt["cases"]["gaussian"]["imputed_all"]["uncertainty_status"].append("overlong"),
        "nonfinite": lambda receipt: receipt["cases"]["gaussian"]["imputed_all"]["estimate"].__setitem__(0, float("nan")),
        "frozen native theta": lambda receipt: receipt["cases"]["gaussian"]["native_theta"].__setitem__(0, 999.0),
    }
    caught = 0
    for label, mutate in mutations.items():
        bad = copy.deepcopy(good)
        mutate(bad)
        try:
            check(data, uncertainty, bad, root)
        except ValueError as error:
            expected = "source/status" if label.startswith("source/status") else label
            if expected not in str(error):
                raise RuntimeError("wrong failure for " + label + ": " + str(error))
            caught += 1
        else:
            raise RuntimeError("accepted damaged " + label)
    print("JOINT_FRONTEND_RECEIPT_NEGATIVES_PASS=" + str(caught))


if __name__ == "__main__":
    main()
