#!/usr/bin/env python3
"""Fail-closed validator for the two prepared joint-model fit receipts."""
import hashlib, math, sys, tomllib
from pathlib import Path
CASES=("gaussian","bernoulli")
def require(ok,msg):
    if not ok: raise ValueError(msg)
def finite(x,msg): require(isinstance(x,list) and x and all(isinstance(v,(int,float)) and math.isfinite(v) for v in x),msg)
def manifest(root):
    src=root/"src"; return {p.relative_to(src).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in src.rglob("*") if p.is_file()}
def lognormal(y,m,s): return -0.5*math.log(2*math.pi)-math.log(s)-0.5*((y-m)/s)**2
def logsigmoid(z): return -math.log1p(math.exp(-z)) if z>=0 else z-math.log1p(math.exp(z))
def logsumexp2(a,b): return a+math.log1p(math.exp(b-a)) if a>=b else b+math.log1p(math.exp(a-b))
def independent_rows(case, theta, kind):
    """Exact prepared likelihood from fixture data, not native row outputs."""
    beta0,betaz,b,delta,alpha0,alphaz=theta[:6]; tau=math.exp(theta[6]) if kind=="gaussian" else None
    out=[]
    for x,y,z,xo,yo in zip(case["x"],case["y"],case["z"],case["x_observed"],case["y_observed"]):
        a=beta0+betaz*z; sigma=math.exp(delta); eta=alpha0+alphaz*z
        if xo and yo:
            out.append((lognormal(x,eta,tau) if kind=="gaussian" else (logsigmoid(eta) if x==1 else logsigmoid(-eta)))+lognormal(y,a+b*x,sigma))
        elif not xo and yo:
            if kind=="gaussian": out.append(lognormal(y,a+b*eta,math.hypot(sigma,b*tau)))
            else: out.append(logsumexp2(logsigmoid(-eta)+lognormal(y,a,sigma),logsigmoid(eta)+lognormal(y,a+b,sigma)))
        elif xo:
            out.append(lognormal(x,eta,tau) if kind=="gaussian" else (logsigmoid(eta) if x==1 else logsigmoid(-eta)))
        else: out.append(0.0)
    return out
def check(ref,rec,root,native_parity=False):
    require(rec.get("reference_sha256")==hashlib.sha256(ref["__path__"].read_bytes()).hexdigest(),"reference hash differs")
    require(rec.get("source_unchanged") is True and rec.get("source_sha256")==manifest(root),"source manifest differs")
    runner=root/"tools"/"check_joint_predictor_fit.jl"
    require(rec.get("runner_sha256")==hashlib.sha256(runner.read_bytes()).hexdigest(),"runner hash differs")
    run=rec.get("runtime",{}); require(run.get("julia_threads")==1 and run.get("blas_threads")==1,"threads must equal one")
    require(set(rec.get("cases",{}))==set(CASES),"case denominator differs")
    for kind in CASES:
        a,e=rec["cases"][kind],ref[kind]; n=len(a.get("theta",[]))
        expected_n=7 if kind=="gaussian" else 6
        require(n==expected_n and len(a.get("gradient",[]))==expected_n,kind+": theta/gradient length differs")
        require(len(e["original_row"])==160 and a.get("original_row")==e["original_row"],kind+": row denominator differs")
        require(a.get("x_observed")==e["x_observed"] and a.get("y_observed")==e["y_observed"],kind+": observed masks differ")
        masks=list(zip(e["x_observed"],e["y_observed"]))
        require({p:masks.count(p) for p in set(masks)}=={(True,True):147,(True,False):3,(False,True):9,(False,False):1},kind+": mask denominator differs")
        require(a.get("snapshot_isolated") is True,kind+": snapshot is not isolated")
        finite(a.get("theta"),kind+": theta nonfinite"); finite(a.get("gradient"),kind+": gradient nonfinite")
        require(math.isfinite(a.get("nll",math.nan)) and max(map(abs,a["gradient"]))<=1e-6,kind+": nll/gradient fails")
        require(a.get("optimizer_status")=="converged" and a.get("covariance_status")=="observed_information_inverse" and a.get("uncertainty_status")=="not_implemented",kind+": status differs")
        require(a.get("nobs")==sum(e["y_observed"]) and a.get("all_rows")==160,kind+": row counts differ")
        H,V=a.get("hessian"),a.get("covariance"); require(isinstance(H,list) and isinstance(V,list) and len(H)==n and len(V)==n and all(isinstance(r,list) and len(r)==n for r in H+V),kind+": Hessian/covariance shape")
        finite([z for r in H+V for z in r],kind+": Hessian/covariance nonfinite")
        require(max(abs(H[i][j]-H[j][i]) for i in range(n) for j in range(n))<=1e-10,kind+": Hessian nonsymmetric")
        L=[[0.0]*n for _ in range(n)]
        for i in range(n):
            for j in range(i+1):
                q=H[i][j]-sum(L[i][k]*L[j][k] for k in range(j))
                if i==j: require(q>0 and math.isfinite(q),kind+": Hessian not PD"); L[i][j]=math.sqrt(q)
                else: L[i][j]=q/L[j][j]
        require(max(abs(sum(H[i][k]*V[k][j] for k in range(n))-(1 if i==j else 0)) for i in range(n) for j in range(n))<=1e-6,kind+": H*V differs")
        independent=independent_rows(e,a["theta"],kind)
        require(abs(sum(independent)-a["reported_loglik"])<=1e-6 and abs(a["nll"]+a["reported_loglik"])<=1e-6,kind+": independently recomputed LL differs")
        finite(a.get("row_loglik"),kind+": row_loglik nonfinite")
        require(len(a["row_loglik"])==160 and max(abs(x-y) for x,y in zip(a["row_loglik"],independent))<=1e-6,kind+": receipt row likelihood differs")
        finite(a.get("native_theta"),kind+": native theta nonfinite")
        require(a["native_theta"]==e["theta"],kind+": receipt native theta differs from fixture")
        if native_parity:
            require(max(abs(x-y) for x,y in zip(a["native_theta"],a["theta"]))<=4e-6,kind+": native theta differs")
def main():
    native="--native-parity" in sys.argv; a=[x for x in sys.argv[1:] if x!="--native-parity"]
    if len(a)!=3: raise SystemExit("usage: check_joint_predictor_fit_receipt.py REFERENCE RECEIPT JULIA_ROOT [--native-parity]")
    rp,cp,root=map(Path,a); ref=tomllib.loads(rp.read_text()); ref["__path__"]=rp; check(ref,tomllib.loads(cp.read_text()),root,native); print("JOINT_FIT_RECEIPT_PASS cases=2 rows=320 native_parity="+str(native).lower())
if __name__=="__main__": main()
