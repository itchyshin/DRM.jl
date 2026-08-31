#!/usr/bin/env python3
"""Damage retained outputs to establish that the public bridge oracle fails."""
import copy
import json
import math
import statistics
import sys
import tomllib
from pathlib import Path

from check_joint_bridge_public_receipt import check

if len(sys.argv) != 6:
    raise SystemExit("usage: test_joint_bridge_public_receipt.py PUBLIC_JSON REFERENCE_TOML DIRECT_TOML R_ROOT JULIA_ROOT")
receipt_path, ref_path, direct_path, rroot, jroot = map(Path, sys.argv[1:])
receipt = json.loads(receipt_path.read_text())
reference = tomllib.loads(ref_path.read_text())
direct = tomllib.loads(direct_path.read_text())
check(receipt, reference, direct, rroot, jroot)
def restore_delta_wald(receipt):
    case = receipt["cases"]["gaussian"]
    theta, cov = case["raw_theta"], case["raw_covariance"]
    estimate = math.exp(theta[-1])
    width = statistics.NormalDist().inv_cdf(.975) * estimate * math.sqrt(cov[-1][-1])
    case["wald"][-1].update(lower=estimate-width, upper=estimate+width, transformation="exp")


damages = [
    ("old delta-Wald mislabeled as log-Wald", restore_delta_wald),
    ("source", lambda x: x["source_before"].clear()),
    ("runtime", lambda x: x["runtime"].update(threads=8)),
    ("denominator", lambda x: x["cases"].pop("bernoulli")),
    ("nobs", lambda x: x["cases"]["gaussian"].update(nobs=160)),
    ("raw theta", lambda x: x["cases"]["gaussian"]["raw_theta"].__setitem__(0, 100)),
    ("public sd", lambda x: x["cases"]["gaussian"]["coefficients"].update(sigma_mi_x=100)),
    ("truncated predictor block", lambda x: x["cases"]["bernoulli"]["coefficients"]["mi_x"].pop()),
    ("public covariance", lambda x: x["cases"]["gaussian"]["public_covariance"][0].__setitem__(6, 1)),
    ("fitted mean", lambda x: x["cases"]["gaussian"]["training_mu"].__setitem__(1, 100)),
    ("row ID", lambda x: x["cases"]["gaussian"]["imputed_all"][1].update(original_row=1)),
    ("mask", lambda x: x["cases"]["gaussian"]["imputed_all"][1].update(observed=True)),
    ("conditional mean", lambda x: x["cases"]["gaussian"]["imputed_all"][1].update(estimate=100)),
    ("conditional SE", lambda x: x["cases"]["gaussian"]["imputed_all"][1].update(std_error=100)),
    ("Bernoulli source", lambda x: x["cases"]["bernoulli"]["imputed_all"][1].update(source="conditional_mode")),
    ("newdata value", lambda x: x["cases"]["bernoulli"]["newdata_mu"].__setitem__(0, 100)),
    ("summary estimate", lambda x: x["cases"]["gaussian"]["summary"][0].update(estimate=100)),
    ("Wald interval", lambda x: x["cases"]["gaussian"]["wald"][0].update(lower=100)),
    ("native likelihood", lambda x: x["cases"]["bernoulli"].update(native_loglik=100)),
    ("native operation omitted", lambda x: x["cases"]["bernoulli"].pop("native_newdata_prediction")),
    ("native failure concealed", lambda x: x["cases"]["bernoulli"].update(native_status="PASS", native_errors={k:0 for k in x["cases"]["bernoulli"]["native_errors"]})),
]
for label, mutate in damages:
    changed = copy.deepcopy(receipt)
    mutate(changed)
    try:
        check(changed, reference, direct, rroot, jroot)
    except (ValueError, KeyError, TypeError):
        continue
    raise RuntimeError("damaged fixture passed: " + label)
print(f"JOINT_PUBLIC_NEGATIVE_CONTROLS_PASS mutations={len(damages)}")
