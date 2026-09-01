#!/usr/bin/env python3
"""Fail-closed validator for public joint-frontend fit receipts."""
import hashlib
import math
import sys
import tomllib
from pathlib import Path

CASES = ("gaussian", "bernoulli")


def require(ok, message):
    if not ok:
        raise ValueError(message)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def manifest(root):
    src = root / "src"
    return {path.relative_to(src).as_posix(): digest(path) for path in src.rglob("*") if path.is_file()}


def finite_vector(value, label, length=None):
    require(isinstance(value, list) and (length is None or len(value) == length), label + ": length")
    require(all(isinstance(x, (int, float)) and math.isfinite(x) for x in value), label + ": nonfinite")


def finite_square(value, size, label):
    require(isinstance(value, list) and len(value) == size and all(isinstance(row, list) and len(row) == size for row in value), label + ": shape")
    finite_vector([x for row in value for x in row], label)


def positive_definite(value, label):
    size = len(value)
    lower = [[0.0] * size for _ in range(size)]
    for i in range(size):
        for j in range(i + 1):
            residual = value[i][j] - sum(lower[i][k] * lower[j][k] for k in range(j))
            if i == j:
                require(residual > 0.0 and math.isfinite(residual), label + ": Hessian PD")
                lower[i][j] = math.sqrt(residual)
            else:
                lower[i][j] = residual / lower[j][j]


def logsigmoid(value):
    return -math.log1p(math.exp(-value)) if value >= 0 else value - math.log1p(math.exp(value))


def logsumexp2(left, right):
    return left + math.log1p(math.exp(right - left)) if left >= right else right + math.log1p(math.exp(left - right))


def lognormal(value, mean, sd):
    return -0.5 * math.log(2 * math.pi) - math.log(sd) - 0.5 * ((value - mean) / sd) ** 2


def gaussian_prediction(theta, covariance, case, index):
    beta0, betaz, slope, logsigma, alpha0, alphaz, logtau = theta
    z = case["z"][index]
    if case["x_observed"][index]:
        return case["x"][index], 0.0, None, "observed"
    sigma2, tau2 = math.exp(2 * logsigma), math.exp(2 * logtau)
    predictor_mean = alpha0 + alphaz * z
    if case["y_observed"][index]:
        residual = case["y"][index] - beta0 - betaz * z
        denom = sigma2 + slope * slope * tau2
        estimate = (sigma2 * predictor_mean + slope * tau2 * residual) / denom
        conditional = sigma2 * tau2 / denom
        gain, weight = slope * tau2 / denom, sigma2 / denom
        jacobian = [-gain, -gain * z, tau2 / denom * (residual - 2 * slope * estimate),
                    -2 * gain * (residual - slope * estimate), weight, weight * z,
                    2 * weight * (estimate - predictor_mean)]
    else:
        estimate, conditional = predictor_mean, tau2
        jacobian = [0.0, 0.0, 0.0, 0.0, 1.0, z, 0.0]
    parameter = sum(jacobian[i] * covariance[i][j] * jacobian[j] for i in range(7) for j in range(7))
    return estimate, conditional + parameter, math.sqrt(conditional + parameter), "conditional_mode"


def bernoulli_prediction(theta, case, index):
    beta0, betaz, slope, logsigma, alpha0, alphaz = theta
    z = case["z"][index]
    if case["x_observed"][index]:
        return case["x"][index], 0.0, None, "observed"
    eta = alpha0 + alphaz * z
    if case["y_observed"][index]:
        sigma = math.exp(logsigma)
        left = logsigmoid(-eta) + lognormal(case["y"][index], beta0 + betaz * z, sigma)
        right = logsigmoid(eta) + lognormal(case["y"][index], beta0 + betaz * z + slope, sigma)
        probability = math.exp(right - logsumexp2(left, right))
    else:
        probability = 1.0 / (1.0 + math.exp(-eta)) if eta >= 0 else math.exp(eta) / (1.0 + math.exp(eta))
    variance = probability * (1.0 - probability)
    return probability, variance, math.sqrt(variance), "conditional_probability"


def expected_row_loglik(theta, case, kind):
    beta0, betaz, slope, logsigma, alpha0, alphaz = theta[:6]
    tau = math.exp(theta[6]) if kind == "gaussian" else None
    values = []
    for x, y, z, xo, yo in zip(case["x"], case["y"], case["z"], case["x_observed"], case["y_observed"]):
        mean, sigma, eta = beta0 + betaz * z, math.exp(logsigma), alpha0 + alphaz * z
        if xo and yo:
            xterm = lognormal(x, eta, tau) if kind == "gaussian" else (logsigmoid(eta) if x == 1 else logsigmoid(-eta))
            values.append(xterm + lognormal(y, mean + slope * x, sigma))
        elif not xo and yo:
            if kind == "gaussian":
                values.append(lognormal(y, mean + slope * eta, math.hypot(sigma, slope * tau)))
            else:
                values.append(logsumexp2(logsigmoid(-eta) + lognormal(y, mean, sigma), logsigmoid(eta) + lognormal(y, mean + slope, sigma)))
        elif xo:
            values.append(lognormal(x, eta, tau) if kind == "gaussian" else (logsigmoid(eta) if x == 1 else logsigmoid(-eta)))
        else:
            values.append(0.0)
    return values


def check_table(actual, reference, theta, covariance, kind, selection, label):
    n = len(reference["original_row"])
    ids = list(range(n)) if selection == "all" else [i for i, observed in enumerate(reference["x_observed"]) if not observed]
    require(actual.get("variable") == ["x"] * len(ids), label + ": variable")
    require(actual.get("original_row") == [reference["original_row"][i] for i in ids], label + ": original rows")
    require(actual.get("model_row") == [i + 1 for i in ids], label + ": model rows")
    require(actual.get("observed") == [reference["x_observed"][i] for i in ids], label + ": observed")
    finite_vector(actual.get("estimate"), label + ": estimate", len(ids))
    finite_vector(actual.get("std_error"), label + ": standard error", len(ids))
    require(all(value >= 0.0 for value in actual["std_error"]), label + ": standard-error sign")
    availability = actual.get("std_error_available")
    require(isinstance(availability, list) and len(availability) == len(ids) and all(type(value) is bool for value in availability), label + ": availability denominator")
    for key in ("source", "uncertainty_status"):
        values = actual.get(key)
        require(isinstance(values, list) and len(values) == len(ids) and all(isinstance(value, str) for value in values), label + ": source/status")
    for out, index in enumerate(ids):
        estimate, variance, standard_error, source = (
            gaussian_prediction(theta, covariance, reference, index) if kind == "gaussian" else bernoulli_prediction(theta, reference, index)
        )
        require(abs(actual["estimate"][out] - estimate) <= 1e-6, label + ": analytic mean")
        require(actual["source"][out] == source and actual["uncertainty_status"][out] == "ok", label + ": source/status")
        if standard_error is None:
            require(actual["std_error_available"][out] is False and actual["std_error"][out] == 0.0, label + ": observed standard error")
        else:
            require(actual["std_error_available"][out] is True, label + ": missing standard-error availability")
            require(abs(actual["std_error"][out] ** 2 - variance) <= 1e-6, label + ": analytic variance")


def check_no_se(actual, all_table, label):
    require(actual.get("variable") == all_table.get("variable"), label + ": variable")
    for key in ("original_row", "model_row", "observed", "estimate", "source", "uncertainty_status"):
        require(actual.get(key) == all_table.get(key), label + ": " + key)
    estimates = actual.get("estimate")
    finite_vector(estimates, label + ": estimate")
    require(actual.get("std_error_available") == [False] * len(estimates), label + ": availability")
    require(actual.get("std_error") == [0.0] * len(estimates), label + ": standard errors")


def check(reference_path, uncertainty_path, receipt, root, native_theta=False):
    reference = tomllib.loads(reference_path.read_text())
    uncertainty = tomllib.loads(uncertainty_path.read_text())
    require(receipt.get("data_sha256") == digest(reference_path), "data hash")
    require(receipt.get("reference_sha256") == digest(reference_path), "reference hash")
    require(receipt.get("uncertainty_reference_sha256") == digest(uncertainty_path), "uncertainty reference hash")
    require(receipt.get("runner_sha256") == digest(root / "tools" / "check_joint_frontend_fit.jl"), "runner hash")
    current = manifest(root)
    require(receipt.get("source_unchanged") is True, "source unchanged")
    require(receipt.get("source_sha256_before") == current and receipt.get("source_sha256_after") == current, "source manifest")
    runtime = receipt.get("runtime", {})
    require(runtime.get("julia_threads") == 1 and runtime.get("blas_threads") == 1, "thread budget")
    require(set(receipt.get("cases", {})) == set(CASES), "case denominator")
    native_deltas = {}
    for kind in CASES:
        actual, frozen, frozen_uncertainty = receipt["cases"][kind], reference[kind], uncertainty[kind]
        p = 7 if kind == "gaussian" else 6
        require(len(frozen["original_row"]) == 160, kind + ": fixture denominator")
        require(len(frozen_uncertainty["theta"]) == p and max(abs(x - y) for x, y in zip(frozen_uncertainty["theta"], frozen["theta"])) <= 1e-12, kind + ": frozen uncertainty agreement")
        finite_vector(actual.get("theta"), kind + ": theta", p)
        finite_vector(actual.get("gradient"), kind + ": gradient", p)
        finite_square(actual.get("hessian"), p, kind + ": hessian")
        finite_square(actual.get("covariance"), p, kind + ": covariance")
        require(actual.get("predictor") == kind and actual.get("converged") is True, kind + ": route/convergence")
        require(actual.get("original_row") == frozen["original_row"], kind + ": original rows")
        require(actual.get("x_observed") == frozen["x_observed"] and actual.get("y_observed") == frozen["y_observed"], kind + ": masks")
        masks = list(zip(frozen["x_observed"], frozen["y_observed"]))
        require({pair: masks.count(pair) for pair in set(masks)} == {(True, True): 147, (True, False): 3, (False, True): 9, (False, False): 1}, kind + ": mask denominator")
        require(actual.get("nobs") == sum(frozen["y_observed"]), kind + ": nobs")
        require(max(abs(value) for value in actual["gradient"]) <= 1e-6, kind + ": gradient")
        require(abs(actual.get("nll", math.nan) + actual.get("loglik", math.nan)) <= 1e-6, kind + ": likelihood sign")
        require(max(abs(actual["hessian"][i][j] - actual["hessian"][j][i]) for i in range(p) for j in range(p)) <= 1e-10, kind + ": hessian symmetry")
        positive_definite(actual["hessian"], kind)
        require(max(abs(sum(actual["hessian"][i][k] * actual["covariance"][k][j] for k in range(p)) - (1.0 if i == j else 0.0)) for i in range(p) for j in range(p)) <= 1e-6, kind + ": H*V")
        require(actual.get("coef_mu") == actual["theta"][:3], kind + ": mu block")
        require(actual.get("coef_sigma") == actual["theta"][3:4] and actual.get("coef_mi_x") == actual["theta"][4:6], kind + ": coefficient blocks")
        if kind == "gaussian":
            require(actual.get("coef_logsd_mi_x") == actual["theta"][6:7], kind + ": log SD block")
            require(len(actual.get("sigma_mi_x", [])) == 1 and abs(actual["sigma_mi_x"][0] - math.exp(actual["theta"][6])) <= 1e-12, kind + ": natural SD")
        else:
            require(actual.get("coef_logsd_mi_x") == [] and actual.get("sigma_mi_x") == [], kind + ": Bernoulli SD")
        expected_ll = expected_row_loglik(actual["theta"], frozen, kind)
        require(abs(sum(expected_ll) - actual["loglik"]) <= 1e-6, kind + ": analytic likelihood")
        check_table(actual.get("imputed_all", {}), frozen, actual["theta"], actual["covariance"], kind, "all", kind + ": imputed all")
        check_table(actual.get("imputed_missing", {}), frozen, actual["theta"], actual["covariance"], kind, "missing", kind + ": imputed missing")
        check_no_se(actual.get("imputed_no_se", {}), actual["imputed_all"], kind + ": imputed se=false")
        require(actual.get("native_theta") == frozen["theta"], kind + ": frozen native theta")
        require(actual.get("native_uncertainty_theta") == frozen_uncertainty["theta"] and actual.get("native_uncertainty_covariance") == frozen_uncertainty["covariance"], kind + ": frozen uncertainty capture")
        delta = max(abs(x - y) for x, y in zip(actual["theta"], frozen["theta"]))
        require(abs(actual.get("native_theta_max_abs", math.nan) - delta) <= 1e-15, kind + ": native theta delta")
        native_deltas[kind] = delta
        if native_theta:
            require(delta <= 4e-6, kind + ": native theta optional gate")
    return native_deltas


def main():
    optional = "--native-theta" in sys.argv
    args = [arg for arg in sys.argv[1:] if arg != "--native-theta"]
    if len(args) != 4:
        raise SystemExit("usage: check_joint_frontend_fit_receipt.py DATA_REFERENCE UNCERTAINTY_REFERENCE RECEIPT JULIA_ROOT [--native-theta]")
    data, uncertainty, receipt_path, root = map(Path, args)
    deltas = check(data, uncertainty, tomllib.loads(receipt_path.read_text()), root, optional)
    print("JOINT_FRONTEND_RECEIPT_PASS cases=2 rows=320 native_theta_checked=" + str(optional).lower() + " deltas=" + repr(deltas))


if __name__ == "__main__":
    main()
