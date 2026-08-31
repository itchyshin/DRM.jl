#!/usr/bin/env python3
"""Reproduce the historical inner-mode flag defect without a model fit.

Only the exact _ls_inner_mode function is evaluated from the retained source.
The objective callbacks below are synthetic, with exact derivatives. This is
not a Gamma/NB2 model, parameter fit, or explanation of a retained model failure.
The script prints evidence; it never writes source or output files itself.
"""
import argparse
import hashlib
from pathlib import Path
import subprocess
import time

EXPECTED_SHA256 = "7915b9cc780e723cd9928b2a71c3f22884d21df5f0b57c1ea1f0e2db334f8bcb"

PRELUDE = r'''
using LinearAlgebra
const grad_calls = Ref(0)
_ls_joint(kind,y,eta,psi,gidx,a,P,Ze,Zp) = a[1]^4/4 + sum(abs2,a)/2
function _ls_joint_grad(kind,y,eta,psi,gidx,a,P,Ze,Zp)
    grad_calls[] += 1
    return [a[1]^3+a[1], a[2]]
end
_ls_joint_hess(kind,y,eta,psi,gidx,G,a,P,Ze,Zp) = [3a[1]^2+1 0.; 0. 1.]
_ls_hess_chol(args...) = cholesky(Symmetric(_ls_joint_hess(args...)); check=false)
'''

POSTLUDE = r'''
function probe(label, initial; kwargs...)
    grad_calls[] = 0
    args = (Val(:synthetic_quartic), Float64[], Float64[], Float64[], Int[],
            1, Matrix{Float64}(I,2,2), zeros(0,2), zeros(0,2))
    a, ch, ok = _ls_inner_mode(args...; a0=[initial,0.], kwargs...)
    gradient = [a[1]^3+a[1], a[2]]
    threshold = 1e-9*(1+norm(a))
    stationary = norm(gradient) <= threshold
    println(label, " ok=", ok, " chol_ok=", issuccess(ch),
            " grad_calls=", grad_calls[], " a=", a,
            " gradnorm=", norm(gradient), " threshold=", threshold,
            " stationary=", stationary)
    return (; ok, chol_ok=issuccess(ch), stationary, grad_calls=grad_calls[])
end
println("JULIA ", VERSION)
zero_budget = probe("ZERO_BUDGET", 2.; maxiter=0)
default_budget = probe("DEFAULT_BUDGET", 1e50)
valid = probe("VALID_STATIONARY", 0.)
zero_budget.ok && zero_budget.chol_ok && !zero_budget.stationary &&
    zero_budget.grad_calls == 0 || error("zero-budget defect was not reproduced")
default_budget.ok && default_budget.chol_ok && !default_budget.stationary &&
    default_budget.grad_calls == 200 || error("default-budget defect was not reproduced")
valid.ok && valid.chol_ok && valid.stationary || error("valid control failed")
println("INNER_MODE_FLAG_DEFECT_REPRODUCED_WITH_VALID_CONTROL")
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path,
                        default=Path(__file__).with_name("source-locscale-inner.jl"))
    parser.add_argument("--julia", type=Path,
                        default=Path.home() / ".julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia")
    args = parser.parse_args()
    source_bytes = args.source.read_bytes()
    digest = hashlib.sha256(source_bytes).hexdigest()
    if digest != EXPECTED_SHA256:
        raise ValueError("source differs from the reviewed historical kernel: " + digest)
    source = source_bytes.decode()
    start = source.index("function _ls_inner_mode(")
    end = source.index("\nend\n", start) + 5
    extracted = source[start:end]
    print("SOURCE", args.source.resolve(), flush=True)
    print("SOURCE_SHA256", digest, flush=True)
    print("EXTRACTED_FUNCTION_SHA256", hashlib.sha256(extracted.encode()).hexdigest(), flush=True)
    print("JULIA_EXECUTABLE", args.julia, flush=True)
    print("SCOPE synthetic convex joint only; no response-family or model fit", flush=True)
    began = time.monotonic()
    result = subprocess.run([str(args.julia), "--startup-file=no", "-e",
                             PRELUDE + extracted + POSTLUDE],
                            capture_output=True, text=True, timeout=30)
    print(result.stdout, end="", flush=True)
    print(result.stderr, end="", flush=True)
    print("EXIT", result.returncode, "ELAPSED_SECONDS", time.monotonic()-began, flush=True)
    if hashlib.sha256(args.source.read_bytes()).hexdigest() != digest:
        raise ValueError("source changed during probe")
    print("SOURCE_UNCHANGED true", flush=True)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
