#!/usr/bin/env python3
"""Validate supplied-parameter accessor evidence; never an optimizer verdict."""
import hashlib, math, sys, tomllib
from pathlib import Path

def require(ok, message):
    if not ok:
        raise ValueError(message)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def near(actual, expected, tolerance, label):
    require(isinstance(actual, list) and len(actual) == len(expected), label+": length")
    require(all(type(x) in (int, float) and math.isfinite(x) for x in actual), label+": nonfinite")
    require(max((abs(x-y) for x,y in zip(actual,expected)), default=0) <= tolerance, label+": values")

def check(data, reference, receipt, root):
    d = tomllib.loads(data.read_text()); r = tomllib.loads(reference.read_text())
    require(receipt.get("data_sha256") == digest(data), "data hash")
    require(receipt.get("reference_sha256") == digest(reference), "reference hash")
    require(receipt.get("runner_sha256") == digest(root/"tools/check_joint_imputation_reference.jl"), "runner hash")
    manifest = {p.relative_to(root/"src").as_posix(): digest(p) for p in (root/"src").rglob("*") if p.is_file()}
    require(receipt.get("source_unchanged") is True and receipt.get("source_sha256") == manifest, "source hash")
    require(receipt.get("julia_threads") == 1 and receipt.get("blas_threads") == 1, "thread budget")
    require(set(receipt.get("cases", {})) == {"gaussian", "bernoulli"}, "case denominator")
    for kind in ("gaussian", "bernoulli"):
        a = receipt["cases"][kind]; e = r[kind]
        require(len(e["original_row"]) == 160, kind+": fixture denominator")
        require(a.get("theta") == e["theta"] and a.get("covariance") == e["covariance"], kind+": supplied parameters")
        for key in ("observed", "original_row", "model_row", "source", "uncertainty_status", "se_available"):
            require(a.get(key) == e[key], kind+": "+key)
        near(a.get("mean"), e["mean"], 1e-6, kind+": mean")
        near(a.get("std_error"), e["std_error"], 1e-6, kind+": standard error")
        near(a.get("conditional_variance"), e["conditional_variance"], 1e-10, kind+": conditional variance")
        ids = [i+1 for i, x in enumerate(e["observed"]) if not x]
        require(a.get("selected_model_row") == ids, kind+": selected rows")
        require(a.get("no_se_all_missing") is True and a.get("no_se_status") == e["uncertainty_status"], kind+": se=false")
        delta = a.get("parameter_variance")
        near(delta, delta if isinstance(delta,list) else [], 0, kind+": parameter variance")
        require(len(delta) == 160, kind+": parameter variance denominator")
        for i in range(160):
            require(delta[i] >= 0, kind+": negative parameter variance")
            if e["observed"][i] or kind == "bernoulli":
                require(delta[i] == 0, kind+": spurious parameter variance")
            else:
                # Independently derived conditional-mean Jacobian; no AD or
                # native random-effect Hessian is reused in this checker.
                b0,bz,b,logs,alpha0,alphaz,logt = a["theta"]
                z = d[kind]["z"][i]; m = alpha0+alphaz*z
                if d[kind]["y_observed"][i]:
                    S=math.exp(2*logs); T=math.exp(2*logt); D=S+b*b*T
                    residual=d[kind]["y"][i]-b0-bz*z
                    u=(S*m+b*T*residual)/D; g=b*T/D; w=S/D
                    J=[-g,-g*z,T/D*(residual-2*b*u),-2*g*(residual-b*u),w,w*z,2*w*(u-m)]
                else:
                    J=[0,0,0,0,1,z,0]
                V=a["covariance"]
                expected=sum(J[j]*V[j][k]*J[k] for j in range(7) for k in range(7))
                require(abs(delta[i]-expected) <= 1e-10, kind+": analytic parameter variance")
            if e["se_available"][i]:
                require(abs(a["std_error"][i]**2-a["conditional_variance"][i]-delta[i]) <= 1e-10, kind+": variance sum")

def main():
    if len(sys.argv) != 5:
        raise SystemExit("usage: check_joint_imputation_receipt.py DATA REFERENCE RECEIPT ROOT")
    data, reference, receipt, root = map(Path,sys.argv[1:])
    check(data,reference,tomllib.loads(receipt.read_text()),root)
    print("JOINT_IMPUTATION_RECEIPT_PASS cases=2 rows=320")

if __name__ == "__main__":
    main()
