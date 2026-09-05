#!/usr/bin/env python3
"""Historical draft control: finite entries can still have infinite norms.

Runs only extracted inner-mode helpers with a synthetic four-dimensional
quadratic and exact derivatives. No DRM package load or response model fit.
Exit 0 means the draft defect and valid control were reproduced.
"""
import argparse
import hashlib
from pathlib import Path
import subprocess
import time

EXPECTED = "dbe3e29555704d55e4b1f71673d6b34e23fb737f1da1b7cc137088a6dc894eff"


def extract(source, name):
    start = source.index("function " + name + "(")
    end = source.index("\nend\n", start) + 5
    return source[start:end]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--julia", type=Path, default=Path.home() /
                        ".julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia")
    args = parser.parse_args()
    source_path = Path(__file__).with_name("review-draft-locscale-inner.jl")
    source_bytes = source_path.read_bytes()
    digest = hashlib.sha256(source_bytes).hexdigest()
    if digest != EXPECTED:
        raise ValueError("historical draft source hash mismatch: " + digest)
    source = source_bytes.decode()
    code = r'''
using LinearAlgebra
_ls_joint(kind,y,eta,psi,gidx,a,P,Ze,Zp) = sum(abs2,a)/2
_ls_joint_grad(kind,y,eta,psi,gidx,a,P,Ze,Zp) = copy(a)
_ls_joint_hess(kind,y,eta,psi,gidx,G,a,P,Ze,Zp) = Matrix{Float64}(I,length(a),length(a))
_ls_hess_chol(args...) = cholesky(Symmetric(_ls_joint_hess(args...)); check=false)
''' + extract(source, "_ls_inner_certificate") + extract(source, "_ls_inner_mode") + r'''
function probe(label, initial; kwargs...)
    args = (Val(:synthetic_quadratic), Float64[], Float64[], Float64[], Int[],
            2, Matrix{Float64}(I,4,4), zeros(0,2), zeros(0,2))
    a, ch, ok = _ls_inner_mode(args...; a0=fill(initial,4), kwargs...)
    gradient = copy(a)
    anorm = norm(a); gnorm = norm(gradient)
    bound = 1e-9*(1+anorm)
    big_anorm = norm(BigFloat.(a))
    big_gnorm = norm(BigFloat.(gradient))
    true_stationary = big_gnorm <= big"1e-9"*(1+big_anorm)
    println(label, " ok=", ok, " chol_ok=", issuccess(ch),
            " entries_finite=", all(isfinite,a) && all(isfinite,gradient),
            " anorm=", anorm, " gnorm=", gnorm, " bound=", bound,
            " float_comparison=", gnorm<=bound,
            " bigfloat_stationary=", true_stationary,
            " scaled_score=", Float64(big_gnorm/(1+big_anorm)))
    return (; ok, true_stationary, finite=all(isfinite,a), chol_ok=issuccess(ch))
end
println("JULIA ",VERSION)
zero_budget = probe("ZERO_BUDGET",1e308; maxiter=0)
early = probe("EARLY_RETURN",1e308; maxiter=1)
valid = probe("VALID_STATIONARY",0.; maxiter=0)
for result in (zero_budget,early)
    result.ok && result.chol_ok && result.finite && !result.true_stationary ||
        error("expected norm-overflow false-success was not reproduced")
end
valid.ok && valid.chol_ok && valid.true_stationary || error("valid control failed")
println("INNER_NORM_OVERFLOW_DEFECT_REPRODUCED_WITH_VALID_CONTROL")
'''
    print("SOURCE", source_path.resolve(), flush=True)
    print("SOURCE_SHA256", digest, flush=True)
    print("JULIA_EXECUTABLE", args.julia, flush=True)
    print("SCOPE synthetic quadratic; draft snapshot, not current source certification", flush=True)
    start = time.monotonic()
    result = subprocess.run([str(args.julia), "--startup-file=no", "-e", code],
                            capture_output=True, text=True, timeout=30)
    print(result.stdout, end="", flush=True)
    print(result.stderr, end="", flush=True)
    print("EXIT", result.returncode, "ELAPSED_SECONDS", time.monotonic()-start, flush=True)
    if hashlib.sha256(source_path.read_bytes()).hexdigest() != digest:
        raise ValueError("snapshot changed during replay")
    print("SNAPSHOT_UNCHANGED true", flush=True)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
